-- Hookah Mixes Database Schema
CREATE TABLE IF NOT EXISTS web_mixes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    recommended_bowl VARCHAR(20) DEFAULT 'убивашка',
    bowl_note TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS web_mix_items (
    id SERIAL PRIMARY KEY,
    mix_id INTEGER REFERENCES web_mixes(id) ON DELETE CASCADE,
    tobacco_name VARCHAR(100) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    pack_grams INTEGER NOT NULL,
    percentage INTEGER NOT NULL,
    sort_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS web_reviews (
    id SERIAL PRIMARY KEY,
    mix_id INTEGER REFERENCES web_mixes(id) ON DELETE CASCADE,
    bowl_type VARCHAR(20) NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    smoked_at DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert mixes
INSERT INTO web_mixes (name, category, description, recommended_bowl, bowl_note) VALUES
('Ягодный лимонад', 'Ягодные', 'Кисло-сладкий, освежающий, для всех', 'убивашка', 'Виноград от DS жаростойкий — кладём наверх. Плотная забивка в касание.'),
('Лесная поляна', 'Ягодные', 'Насыщенный ягодный, чуть терпкий', 'убивашка', 'DS Вайлдберри крепкий — наверх. DINO даст мятную жвачку на выдохе.'),
('Ягодный сорбет', 'Ягодные', 'Сладкий, грейпфрутовый, лёгкий холодок', 'фанел', 'Лёгкий микс, на фанеле раскроется мягче. Воздушная забивка с отступом.'),
('Тропический бум', 'Тропические', 'Манго + маракуйя + ананас, взрывной', 'убивашка', 'Фолинг Стар — жаростойкий, наверх. Яркий тропический удар.'),
('Бали бриз', 'Тропические', 'Дыня-манго смузи, мягкий и сладкий', 'фанел', 'Мягкий микс — на фанеле будет бархатный дым. Не перегревай!'),
('Ананасовый панч', 'Тропические', 'Кисло-тропический, ананас в центре', 'убивашка', 'Двойной ананас (MH + BB) — кислинка зашкаливает. Убивашка раскроет крепость.'),
('Виноградный огурец', 'Свежие', 'Необычный, свежий, летний', 'фанел', 'Деликатный вкус огурца лучше на фанеле — не перегреется.'),
('Зелёный фреш', 'Свежие', 'Киви + алоэ + лимон, бодрящий', 'фанел', 'MustHave не жаростойкий — фанел бережнее. Воздушная забивка.'),
('Вишнёвая кола', 'Газировки', 'Классика, газировка с вишней', 'убивашка', 'DS + Хулиган HARD — оба крепкие. Убивашка раскроет на полную.'),
('Виноградный лимонад', 'Газировки', 'Сладкая газировка с виноградом', 'убивашка', 'DS Грэйп Кор как основа — нужен хороший прогрев на убивашке.'),
('Манговый чизкейк', 'Десертные', 'Сладкий, сливочный, с экзотикой', 'фанел', 'Десертные вкусы нежные — фанел сохранит сливочность. Не перегревай!'),
('Клубничный десерт', 'Десертные', 'Клубника + банан + черника, нежный', 'фанел', 'Три MustHave — не жаростойкие. Фанел с отступом, 2 угля.'),
('Апельсиновый шок', 'Цитрусовые', 'Яркий цитрус, бодрящий', 'убивашка', 'BB крепкий и жаростойкий. Убивашка вытянет максимум цитруса.'),
('Грейп + яблоко', 'Цитрусовые', 'Кисло-сладкий, с гранатом', 'фанел', 'Boo (яблоко-гранат) деликатный — фанел раскроет без горечи.'),
('Торпедо микс', 'Дынно-арбузные', 'Летний, арбуз + дыня + ягоды', 'убивашка', 'DS Торпедо жаростойкий — забивай плотно, он любит жар.'),
('Дынный тропик', 'Дынно-арбузные', 'Дыня-манго + ананас, пляжный вайб', 'фанел', 'Микс из разных крепостей — фанел сбалансирует. MH вниз, DS наверх.');

-- Insert mix items
-- 1. Ягодный лимонад
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(1, 'Грэйп Кор', 'Darkside', 30, 35, 1),
(1, 'Pinkman', 'MustHave', 25, 30, 2),
(1, 'Lemon Shock', 'Black Burn', 25, 20, 3),
(1, 'Supernova', 'Darkside', 0, 15, 4);

-- 2. Лесная поляна
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(2, 'Вайлдберри', 'Darkside', 30, 40, 1),
(2, 'Black Currant', 'MustHave', 25, 25, 2),
(2, 'Cranberry Shock', 'Black Burn', 25, 20, 3),
(2, 'DINO', 'Хулиган', 25, 15, 4);

-- 3. Ягодный сорбет
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(3, 'Ice Baby', 'Black Burn', 25, 40, 1),
(3, 'Blueberry', 'MustHave', 25, 30, 2),
(3, 'Клубничный сорбет', 'MustHave', 25, 20, 3),
(3, 'Supernova', 'Darkside', 0, 10, 4);

-- 4. Тропический бум
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(4, 'Фолинг Стар', 'Darkside', 30, 40, 1),
(4, 'Pineapple Rings', 'MustHave', 25, 25, 2),
(4, 'На чиле', 'Black Burn', 25, 20, 3),
(4, 'Supernova', 'Darkside', 0, 15, 4);

-- 5. Бали бриз
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(5, 'HARD Bali', 'Хулиган', 25, 45, 1),
(5, 'Jungle Mix', 'Spectrum', 25, 30, 2),
(5, 'Ananas Shock', 'Black Burn', 25, 15, 3),
(5, 'Supernova', 'Darkside', 0, 10, 4);

-- 6. Ананасовый панч
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(6, 'Pineapple Rings', 'MustHave', 25, 35, 1),
(6, 'Ananas Shock', 'Black Burn', 25, 25, 2),
(6, 'CHO', 'Хулиган', 25, 25, 3),
(6, 'Supernova', 'Darkside', 0, 15, 4);

-- 7. Виноградный огурец
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(7, 'HARD SILA', 'Хулиган', 25, 40, 1),
(7, 'Grape Soda', 'Spectrum', 25, 30, 2),
(7, 'Lemon Shock', 'Black Burn', 25, 15, 3),
(7, 'Supernova', 'Darkside', 0, 15, 4);

-- 8. Зелёный фреш
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(8, 'Kiwi Smoothie', 'MustHave', 25, 40, 1),
(8, 'Alova', 'MustHave', 25, 25, 2),
(8, 'Old', 'Хулиган', 25, 25, 3),
(8, 'Supernova', 'Darkside', 0, 10, 4);

-- 9. Вишнёвая кола
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(9, 'HARD Young B', 'Хулиган', 25, 40, 1),
(9, 'Черри Рокс', 'Darkside', 30, 35, 2),
(9, 'Lemon Shock', 'Black Burn', 25, 15, 3),
(9, 'Supernova', 'Darkside', 0, 10, 4);

-- 10. Виноградный лимонад
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(10, 'Грэйп Кор', 'Darkside', 30, 40, 1),
(10, 'Grape Soda', 'Spectrum', 25, 25, 2),
(10, 'Old', 'Хулиган', 25, 20, 3),
(10, 'Supernova', 'Darkside', 0, 15, 4);

-- 11. Манговый чизкейк
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(11, 'Lova Lova', 'Хулиган', 25, 40, 1),
(11, 'Cheesecake', 'Black Burn', 25, 30, 2),
(11, 'Banana Mama', 'MustHave', 25, 20, 3),
(11, 'Supernova', 'Darkside', 0, 10, 4);

-- 12. Клубничный десерт
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(12, 'Клубничный сорбет', 'MustHave', 25, 35, 1),
(12, 'Banana Mama', 'MustHave', 25, 30, 2),
(12, 'Blueberry', 'MustHave', 25, 20, 3),
(12, 'DINO', 'Хулиган', 25, 15, 4);

-- 13. Апельсиновый шок
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(13, 'CHO', 'Хулиган', 25, 40, 1),
(13, 'Red Orange', 'Black Burn', 25, 30, 2),
(13, 'Lemon Shock', 'Black Burn', 25, 15, 3),
(13, 'Supernova', 'Darkside', 0, 15, 4);

-- 14. Грейп + яблоко
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(14, 'Boo', 'Хулиган', 25, 40, 1),
(14, 'Pinkman', 'MustHave', 25, 30, 2),
(14, 'Black Currant', 'MustHave', 25, 20, 3),
(14, 'Supernova', 'Darkside', 0, 10, 4);

-- 15. Торпедо микс
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(15, 'Торпедо', 'Darkside', 30, 45, 1),
(15, 'Ice Baby', 'Black Burn', 25, 25, 2),
(15, 'Cranberry Shock', 'Black Burn', 25, 15, 3),
(15, 'Supernova', 'Darkside', 0, 15, 4);

-- 16. Дынный тропик
INSERT INTO web_mix_items (mix_id, tobacco_name, brand, pack_grams, percentage, sort_order) VALUES
(16, 'Торпедо', 'Darkside', 30, 40, 1),
(16, 'HARD Bali', 'Хулиган', 25, 30, 2),
(16, 'Pineapple Rings', 'MustHave', 25, 20, 3),
(16, 'Supernova', 'Darkside', 0, 10, 4);
