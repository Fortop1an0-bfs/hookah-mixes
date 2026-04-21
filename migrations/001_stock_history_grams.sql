-- Migration 001: tobacco stock, random-roll history, per-review grams
-- Safe to run multiple times.

-- 1) Add `grams` to web_reviews (how much tobacco was actually packed for this bowl).
ALTER TABLE web_reviews ADD COLUMN IF NOT EXISTS grams INTEGER;

-- Backfill existing rows from bowl_type (убивашка=20, фанел=15).
UPDATE web_reviews
SET grams = CASE bowl_type WHEN 'убивашка' THEN 20 WHEN 'фанел' THEN 15 ELSE 18 END
WHERE grams IS NULL;

-- 2) Random-roll history.
CREATE TABLE IF NOT EXISTS web_random_history (
    id SERIAL PRIMARY KEY,
    mix_id INTEGER REFERENCES web_mixes(id) ON DELETE CASCADE,
    rolled_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_web_random_history_rolled_at
    ON web_random_history (rolled_at DESC);

-- 3) Tobacco stock.
-- grams_total = сколько всего куплено (user-managed).
-- grams_used  = сколько потрачено (считается в рантайме по отзывам).
CREATE TABLE IF NOT EXISTS web_tobacco_stock (
    id SERIAL PRIMARY KEY,
    brand VARCHAR(50) NOT NULL,
    tobacco_name VARCHAR(100) NOT NULL,
    grams_total INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (brand, tobacco_name)
);

-- Seed stock rows from web_mix_items (one pack per distinct tobacco),
-- using the max pack_grams seen. pack_grams = 0 means "домашний" — seeds 0.
INSERT INTO web_tobacco_stock (brand, tobacco_name, grams_total)
SELECT brand, tobacco_name, MAX(pack_grams)
FROM web_mix_items
GROUP BY brand, tobacco_name
ON CONFLICT (brand, tobacco_name) DO NOTHING;
