-- Phase 2b: Profiles table
-- Extends auth.users with role enum and journalist fields.
-- No foreign keys into other Part 2 tables.
-- Depends on: set_updated_at() function (defined in 0001_articles.sql).

CREATE TYPE user_role AS ENUM (
  'contributor',
  'journalist',
  'editor',
  'super_admin'
);

CREATE TABLE profiles (
  id         uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username   text NOT NULL UNIQUE CHECK (username ~ '^[a-z0-9_]{3,30}$'),
  full_name  text NOT NULL CHECK (char_length(full_name) BETWEEN 2 AND 100),
  avatar_url text,
  bio        text CHECK (char_length(bio) <= 1000),
  beat       text,
  role       user_role NOT NULL DEFAULT 'contributor',
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_username ON profiles(username);

CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Auto-create a profile row on every new auth.users signup.
-- role is ALWAYS hardcoded to 'contributor' regardless of any
-- client-supplied metadata. This is the ONLY code path that
-- creates a profile, per Section G.
-- SECURITY DEFINER is required because the Supabase Auth internal
-- signup process does not have direct INSERT rights on public.profiles
-- under RLS — the function runs as its owner (a superuser) to bypass RLS.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, role)
  VALUES (
    NEW.id,
    'user_' || substr(NEW.id::text, 1, 8),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    'contributor'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- Zero policies added here — deny-by-default until Phase 2h.
