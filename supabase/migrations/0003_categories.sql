-- Phase 2c: Categories + Subcategories
-- Self-referencing for subcategories, seeded with 9 top-level categories.
-- No foreign keys into other Part 2 tables.

CREATE TABLE categories (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name      text NOT NULL,
  slug      text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  parent_id uuid REFERENCES categories(id),
  position  smallint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT no_self_parent CHECK (id != parent_id)
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_position ON categories(position);

-- 9 top-level categories per Section D of the constitution.
-- Order is contractual: Phase 6a homepage and 4e category-select depend on this sequence.
-- Subcategories are NOT seeded here — added post-launch via Super Admin dashboard (5i).
INSERT INTO categories (name, slug, position) VALUES
  ('রাজনীতি',   'rajniti',    1),
  ('অর্থনীতি',   'arthaniti',  2),
  ('আন্তর্জাতিক', 'antorjatik',  3),
  ('খেলাধুলা',   'kheladhula',  4),
  ('প্রযুক্তি',   'projukti',   5),
  ('বিনোদন',    'binodhan',   6),
  ('শিক্ষা',    'shikkha',    7),
  ('স্বাস্থ্য',   'swasthya',  8),
  ('চট্টগ্রাম',   'chittagong',  9);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
-- Zero policies added here — deny-by-default until Phase 2i.
