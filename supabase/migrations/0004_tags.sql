-- Phase 2d: Tags + Article Tags (many-to-many)
-- Depends on: articles (2a).

CREATE TABLE tags (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  slug        text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  usage_count integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_tags_usage_count ON tags(usage_count DESC);
CREATE INDEX idx_tags_slug ON tags(slug);

CREATE TABLE article_tags (
  article_id  uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  tag_id      uuid NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (article_id, tag_id)
);

-- Maintains tags.usage_count as a denormalized counter.
-- Uses GREATEST(..., 0) to floor at zero under edge-case concurrent deletes.
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tags SET usage_count = GREATEST(usage_count - 1, 0) WHERE id = OLD.tag_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER article_tags_usage_count
  AFTER INSERT OR DELETE ON article_tags
  FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();

ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_tags ENABLE ROW LEVEL SECURITY;
-- Zero policies on either table — deny-by-default until Phase 2i.
