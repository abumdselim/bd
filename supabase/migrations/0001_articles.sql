-- Phase 2a: Articles table
-- Depends on: profiles (2b), categories (2c), media (2e) existing with id uuid PK
-- Migration file numbering is conceptual (phase order); actual deploy order
-- interleaves per 2b/2c/2e migration filenames so FK targets exist first.

CREATE TYPE article_status AS ENUM (
  'draft',
  'pending',
  'published',
  'rejected',
  'scheduled'
);

CREATE TABLE articles (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title               text NOT NULL CHECK (char_length(title) BETWEEN 10 AND 200),
  slug                text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' AND char_length(slug) <= 80),
  excerpt             text NOT NULL CHECK (char_length(excerpt) <= 160),
  body                jsonb NOT NULL,
  cover_image_id      uuid REFERENCES media(id),
  category_id         uuid NOT NULL REFERENCES categories(id),
  subcategory_id      uuid REFERENCES categories(id),
  author_id           uuid NOT NULL REFERENCES profiles(id),
  status              article_status NOT NULL DEFAULT 'draft',
  breaking            boolean NOT NULL DEFAULT false,
  breaking_ticker     text CHECK (char_length(breaking_ticker) <= 100),
  breaking_priority   smallint CHECK (breaking_priority BETWEEN 1 AND 3),
  breaking_expires_at timestamptz,
  sponsored           boolean NOT NULL DEFAULT false,
  premium             boolean NOT NULL DEFAULT false,
  seo_title           text CHECK (char_length(seo_title) <= 60),
  seo_description     text CHECK (char_length(seo_description) <= 155),
  reviewed_by         uuid REFERENCES profiles(id),
  rejection_reason    text CHECK (char_length(rejection_reason) >= 20),
  submitted_at        timestamptz,
  scheduled_for       timestamptz,
  published_at        timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT breaking_requires_ticker CHECK (NOT breaking OR breaking_ticker IS NOT NULL),
  CONSTRAINT rejected_requires_reason CHECK (status != 'rejected' OR rejection_reason IS NOT NULL),
  CONSTRAINT scheduled_requires_time CHECK (status != 'scheduled' OR scheduled_for IS NOT NULL)
);

CREATE INDEX idx_articles_status ON articles(status);
CREATE INDEX idx_articles_category ON articles(category_id);
CREATE INDEX idx_articles_author ON articles(author_id);
CREATE INDEX idx_articles_published_at ON articles(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_articles_slug ON articles(slug);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER articles_set_updated_at
  BEFORE UPDATE ON articles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
-- Zero policies — deny-by-default until Phase 2g.