-- Phase 2e: Media table
-- Stores metadata for all uploaded images (article images, reused for avatars).
-- Depends on: profiles (2b).
-- Supabase Storage bucket 'article-images' must be created manually
-- in the Supabase dashboard before Phase 4d's upload pipeline writes files.

CREATE TABLE media (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  uploader_id         uuid NOT NULL REFERENCES profiles(id),
  storage_path        text NOT NULL UNIQUE,
  mime_type           text NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
  width               integer NOT NULL CHECK (width > 0),
  height              integer NOT NULL CHECK (height > 0),
  size_bytes          integer NOT NULL CHECK (size_bytes > 0 AND size_bytes <= 52428800),
  original_size_bytes integer CHECK (original_size_bytes > 0),
  alt_text            text NOT NULL CHECK (char_length(alt_text) BETWEEN 5 AND 250),
  exif_data           jsonb,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_media_uploader ON media(uploader_id);

ALTER TABLE media ENABLE ROW LEVEL SECURITY;
-- Zero policies added here — deny-by-default until Phase 2i.
