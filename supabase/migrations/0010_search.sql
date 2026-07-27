-- Phase 2j: Full-Text Search
-- Depends on: articles (2a), articles RLS (2g).
--
-- Uses 'simple' text search configuration (no language-specific stemming)
-- because Postgres has no native Bangla dictionary. Combined with unaccent
-- for Latin-script text in mixed-language articles. This is token-based
-- matching, not stem-aware — see ADR 0021.

CREATE EXTENSION IF NOT EXISTS unaccent;

-- Generated STORED column: Postgres maintains it automatically on every
-- INSERT/UPDATE to title or excerpt. No trigger needed.
ALTER TABLE articles ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', unaccent(coalesce(title, ''))), 'A') ||
    setweight(to_tsvector('simple', unaccent(coalesce(excerpt, ''))), 'B')
  ) STORED;

CREATE INDEX idx_articles_search_vector ON articles USING GIN (search_vector);

-- SECURITY INVOKER (default) — runs under the calling user's RLS context.
-- The explicit status = 'published' filter is defense-in-depth alongside RLS.
-- Uses websearch_to_tsquery for user-friendly search syntax (spaces = AND,
-- quoted phrases, -word to exclude).
CREATE OR REPLACE FUNCTION search_articles(
  search_query text,
  category_filter uuid DEFAULT NULL,
  date_from timestamptz DEFAULT NULL,
  date_to timestamptz DEFAULT NULL,
  page_limit int DEFAULT 20,
  page_offset int DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  title text,
  excerpt text,
  slug text,
  category_id uuid,
  published_at timestamptz,
  rank real
)
LANGUAGE sql STABLE AS $$
  SELECT
    a.id, a.title, a.excerpt, a.slug, a.category_id, a.published_at,
    ts_rank(a.search_vector, websearch_to_tsquery('simple', unaccent(search_query))) AS rank
  FROM articles a
  WHERE a.status = 'published'
    AND a.search_vector @@ websearch_to_tsquery('simple', unaccent(search_query))
    AND (category_filter IS NULL OR a.category_id = category_filter)
    AND (date_from IS NULL OR a.published_at >= date_from)
    AND (date_to IS NULL OR a.published_at <= date_to)
  ORDER BY rank DESC, a.published_at DESC
  LIMIT page_limit OFFSET page_offset;
$$;
