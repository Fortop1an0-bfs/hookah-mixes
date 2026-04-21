from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
import asyncpg
import os
import datetime

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "database": os.getenv("DB_NAME", "hookah_db"),
    "user": os.getenv("DB_USER", "hookah"),
    "password": os.getenv("DB_PASS", "hookah123"),
}

BOWL_DEFAULT_GRAMS = {"убивашка": 20, "фанел": 15}
STOCK_LOW_THRESHOLD = 10  # <10г → "заканчивается", <=0 → "закончился"

pool = None


@app.on_event("startup")
async def startup():
    global pool
    pool = await asyncpg.create_pool(**DB_CONFIG, min_size=2, max_size=10)


@app.on_event("shutdown")
async def shutdown():
    if pool:
        await pool.close()


@app.get("/", response_class=HTMLResponse)
async def index():
    with open("templates/index.html", "r", encoding="utf-8") as f:
        return f.read()


@app.get("/api/mixes")
async def get_mixes():
    async with pool.acquire() as conn:
        mixes = await conn.fetch("""
            SELECT m.id, m.name, m.category, m.description,
                   m.recommended_bowl, m.bowl_note, m.strength, m.coal_tip, m.pack_method,
                   COALESCE(
                       (SELECT ROUND(AVG(r.rating)::numeric, 1) FROM web_reviews r WHERE r.mix_id = m.id), 0
                   ) as avg_rating,
                   (SELECT COUNT(*) FROM web_reviews r WHERE r.mix_id = m.id) as review_count
            FROM web_mixes m ORDER BY m.category, m.id
        """)
        result = []
        for m in mixes:
            items = await conn.fetch("""
                SELECT tobacco_name, brand, pack_grams, percentage
                FROM web_mix_items WHERE mix_id = $1 ORDER BY sort_order
            """, m["id"])
            result.append({
                "id": m["id"],
                "name": m["name"],
                "category": m["category"],
                "description": m["description"],
                "recommended_bowl": m["recommended_bowl"],
                "bowl_note": m["bowl_note"],
                "strength": m["strength"],
                "coal_tip": m["coal_tip"],
                "pack_method": m["pack_method"],
                "avg_rating": float(m["avg_rating"]),
                "review_count": m["review_count"],
                "items": [dict(i) for i in items]
            })
        return result


@app.get("/api/calendar")
async def get_calendar():
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT r.id, r.smoked_at::text as smoked_at, r.bowl_type, r.rating, r.comment,
                   m.id as mix_id, m.name, m.category, m.strength, m.description
            FROM web_reviews r
            JOIN web_mixes m ON m.id = r.mix_id
            WHERE r.smoked_at IS NOT NULL
            ORDER BY r.smoked_at DESC
        """)
        return [dict(r) for r in rows]


@app.get("/api/reviews/{mix_id}")
async def get_reviews(mix_id: int):
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT id, bowl_type, rating, comment, grams,
                   TO_CHAR(smoked_at, 'DD.MM.YYYY') as smoked_at,
                   TO_CHAR(created_at, 'DD.MM.YYYY HH24:MI') as date
            FROM web_reviews WHERE mix_id = $1 ORDER BY created_at DESC
        """, mix_id)
        return [dict(r) for r in rows]


@app.post("/api/reviews")
async def add_review(request: Request):
    data = await request.json()
    mix_id = data.get("mix_id")
    bowl_type = data.get("bowl_type")
    rating = data.get("rating")
    comment = data.get("comment", "")
    smoked_at_raw = data.get("smoked_at") or None
    grams_raw = data.get("grams")

    if smoked_at_raw:
        try:
            smoked_at = datetime.date.fromisoformat(smoked_at_raw)
        except (ValueError, TypeError):
            smoked_at = None
    else:
        smoked_at = None

    if not all([mix_id, bowl_type, rating]):
        return JSONResponse({"error": "Заполни все поля"}, status_code=400)
    if rating < 1 or rating > 5:
        return JSONResponse({"error": "Рейтинг от 1 до 5"}, status_code=400)

    try:
        grams = int(grams_raw) if grams_raw is not None and grams_raw != "" else BOWL_DEFAULT_GRAMS.get(bowl_type, 18)
    except (TypeError, ValueError):
        grams = BOWL_DEFAULT_GRAMS.get(bowl_type, 18)

    async with pool.acquire() as conn:
        await conn.execute("""
            INSERT INTO web_reviews (mix_id, bowl_type, rating, comment, smoked_at, grams)
            VALUES ($1, $2, $3, $4, $5::date, $6)
        """, mix_id, bowl_type, rating, comment, smoked_at, grams)
    return {"ok": True}


# ───── RANDOM ROLL HISTORY ─────

@app.post("/api/random/roll")
async def save_random_roll(request: Request):
    data = await request.json()
    mix_id = data.get("mix_id")
    if not mix_id:
        return JSONResponse({"error": "mix_id required"}, status_code=400)
    async with pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO web_random_history (mix_id) VALUES ($1)", mix_id
        )
    return {"ok": True}


@app.get("/api/random/history")
async def get_random_history(limit: int = 20):
    limit = max(1, min(int(limit), 200))
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT h.id, h.mix_id, m.name, m.category, m.strength,
                   TO_CHAR(h.rolled_at, 'DD.MM HH24:MI') as rolled_at
            FROM web_random_history h
            JOIN web_mixes m ON m.id = h.mix_id
            ORDER BY h.rolled_at DESC
            LIMIT $1
        """, limit)
        return [dict(r) for r in rows]


@app.delete("/api/random/history")
async def clear_random_history():
    async with pool.acquire() as conn:
        await conn.execute("DELETE FROM web_random_history")
    return {"ok": True}


# ───── USAGE / STOCK ─────

async def _fetch_usage(conn):
    """Returns list of {brand, tobacco_name, grams_used} — сколько потрачено по отзывам."""
    rows = await conn.fetch("""
        SELECT i.brand, i.tobacco_name,
               COALESCE(SUM(r.grams * i.percentage / 100.0), 0) AS grams_used
        FROM web_reviews r
        JOIN web_mix_items i ON i.mix_id = r.mix_id
        GROUP BY i.brand, i.tobacco_name
    """)
    return [{"brand": r["brand"],
             "tobacco_name": r["tobacco_name"],
             "grams_used": float(r["grams_used"])} for r in rows]


@app.get("/api/usage")
async def get_usage():
    async with pool.acquire() as conn:
        usage = await _fetch_usage(conn)
        usage.sort(key=lambda x: x["grams_used"], reverse=True)
        total = sum(x["grams_used"] for x in usage)
        by_brand = {}
        for u in usage:
            by_brand[u["brand"]] = by_brand.get(u["brand"], 0) + u["grams_used"]
        return {
            "total_grams": round(total, 1),
            "by_brand": [{"brand": b, "grams": round(g, 1)}
                         for b, g in sorted(by_brand.items(), key=lambda x: -x[1])],
            "by_tobacco": [{**u, "grams_used": round(u["grams_used"], 1)} for u in usage],
        }


@app.get("/api/stock")
async def get_stock():
    """Остатки с авто-расчётом: left = total - used. Статус: ok / low / empty."""
    async with pool.acquire() as conn:
        stock_rows = await conn.fetch("""
            SELECT brand, tobacco_name, grams_total, notes,
                   TO_CHAR(updated_at, 'DD.MM.YYYY HH24:MI') as updated_at
            FROM web_tobacco_stock
        """)
        usage = {(u["brand"], u["tobacco_name"]): u["grams_used"]
                 for u in await _fetch_usage(conn)}
        result = []
        for s in stock_rows:
            key = (s["brand"], s["tobacco_name"])
            total = s["grams_total"] or 0
            used = round(usage.get(key, 0), 1)
            left = round(total - used, 1)
            if total <= 0:
                status = "unknown"
            elif left <= 0:
                status = "empty"
            elif left < STOCK_LOW_THRESHOLD:
                status = "low"
            else:
                status = "ok"
            result.append({
                "brand": s["brand"],
                "tobacco_name": s["tobacco_name"],
                "grams_total": total,
                "grams_used": used,
                "grams_left": left,
                "status": status,
                "notes": s["notes"],
                "updated_at": s["updated_at"],
            })
        result.sort(key=lambda x: (x["status"] != "empty",
                                   x["status"] != "low",
                                   x["brand"], x["tobacco_name"]))
        return result


@app.post("/api/stock")
async def update_stock(request: Request):
    """Создать/обновить запись о запасе. Body: {brand, tobacco_name, grams_total, notes?}"""
    data = await request.json()
    brand = (data.get("brand") or "").strip()
    tobacco_name = (data.get("tobacco_name") or "").strip()
    if not brand or not tobacco_name:
        return JSONResponse({"error": "brand и tobacco_name обязательны"}, status_code=400)
    try:
        grams_total = int(data.get("grams_total", 0))
    except (TypeError, ValueError):
        return JSONResponse({"error": "grams_total должно быть числом"}, status_code=400)
    if grams_total < 0:
        return JSONResponse({"error": "grams_total не может быть отрицательным"}, status_code=400)
    notes = data.get("notes")
    async with pool.acquire() as conn:
        await conn.execute("""
            INSERT INTO web_tobacco_stock (brand, tobacco_name, grams_total, notes, updated_at)
            VALUES ($1, $2, $3, $4, NOW())
            ON CONFLICT (brand, tobacco_name)
            DO UPDATE SET grams_total = EXCLUDED.grams_total,
                          notes = EXCLUDED.notes,
                          updated_at = NOW()
        """, brand, tobacco_name, grams_total, notes)
    return {"ok": True}
