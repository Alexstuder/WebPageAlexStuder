-- DANGER: this drops the entire schema including data
DROP SCHEMA IF EXISTS aibrewgenius CASCADE;

CREATE SCHEMA aibrewgenius;

CREATE TABLE aibrewgenius.user_profiles (
  id TEXT PRIMARY KEY,
  name TEXT,
  avatar_url TEXT,
  kettle_brand TEXT,
  kettle_type TEXT,
  default_batch_liters DOUBLE PRECISION,
  fermenter_brand TEXT,
  fermenter_type TEXT,
  controller TEXT,
  controller_user TEXT,
  controller_api_key TEXT,
  yeast_entries JSONB NOT NULL DEFAULT '[]'::jsonb,
  malt_depot JSONB NOT NULL DEFAULT '[]'::jsonb
);

GRANT USAGE ON SCHEMA aibrewgenius TO anon;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA aibrewgenius TO anon;

-- Enable RLS and allow anon writes (adjust as needed)
ALTER TABLE aibrewgenius.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_profiles_select_anon
  ON aibrewgenius.user_profiles
  FOR SELECT
  TO anon
  USING (TRUE);

CREATE POLICY user_profiles_insert_anon
  ON aibrewgenius.user_profiles
  FOR INSERT
  TO anon
  WITH CHECK (TRUE);

CREATE POLICY user_profiles_update_anon
  ON aibrewgenius.user_profiles
  FOR UPDATE
  TO anon
  USING (TRUE)
  WITH CHECK (TRUE);
