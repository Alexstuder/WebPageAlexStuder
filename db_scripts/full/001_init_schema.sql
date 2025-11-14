-- DANGER: this drops the entire schema including data
DROP SCHEMA IF EXISTS aibrewgenius CASCADE;

CREATE SCHEMA aibrewgenius;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

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

CREATE TABLE aibrewgenius.water_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  ph DOUBLE PRECISION,
  calcium_ppm DOUBLE PRECISION DEFAULT 0,
  magnesium_ppm DOUBLE PRECISION DEFAULT 0,
  sodium_ppm DOUBLE PRECISION DEFAULT 0,
  chloride_ppm DOUBLE PRECISION DEFAULT 0,
  sulfate_ppm DOUBLE PRECISION DEFAULT 0,
  bicarbonate_ppm DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE aibrewgenius.brew_kettles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  model TEXT,
  volume_liters DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE aibrewgenius.fermenters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  type TEXT,
  volume_liters DOUBLE PRECISION,
  has_heating BOOLEAN NOT NULL DEFAULT FALSE,
  has_cooling BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE aibrewgenius.yeast_bank_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  strain TEXT NOT NULL,
  style TEXT,
  attenuation_min DOUBLE PRECISION,
  attenuation_max DOUBLE PRECISION,
  temperature_min DOUBLE PRECISION,
  temperature_max DOUBLE PRECISION,
  url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE aibrewgenius.malt_depots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE aibrewgenius.fermenter_controllers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  username TEXT,
  api_key TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE OR REPLACE FUNCTION aibrewgenius.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER water_profiles_set_updated_at
BEFORE UPDATE ON aibrewgenius.water_profiles
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE TRIGGER brew_kettles_set_updated_at
BEFORE UPDATE ON aibrewgenius.brew_kettles
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE TRIGGER fermenters_set_updated_at
BEFORE UPDATE ON aibrewgenius.fermenters
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE TRIGGER yeast_bank_entries_set_updated_at
BEFORE UPDATE ON aibrewgenius.yeast_bank_entries
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE TRIGGER malt_depots_set_updated_at
BEFORE UPDATE ON aibrewgenius.malt_depots
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE TRIGGER fermenter_controllers_set_updated_at
BEFORE UPDATE ON aibrewgenius.fermenter_controllers
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

GRANT USAGE ON SCHEMA aibrewgenius TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA aibrewgenius TO anon;

-- Enable RLS and allow anon writes (adjust as needed)
ALTER TABLE aibrewgenius.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.water_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.brew_kettles ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.fermenters ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.yeast_bank_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.malt_depots ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.fermenter_controllers ENABLE ROW LEVEL SECURITY;

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

CREATE POLICY water_profiles_select
  ON aibrewgenius.water_profiles
  FOR SELECT
  TO anon
  USING (TRUE);

CREATE POLICY water_profiles_insert
  ON aibrewgenius.water_profiles
  FOR INSERT
  TO anon
  WITH CHECK (TRUE);

CREATE POLICY water_profiles_update
  ON aibrewgenius.water_profiles
  FOR UPDATE
  TO anon
  USING (TRUE)
  WITH CHECK (TRUE);

CREATE POLICY water_profiles_delete
  ON aibrewgenius.water_profiles
  FOR DELETE
  TO anon
  USING (TRUE);

CREATE POLICY brew_kettles_select
  ON aibrewgenius.brew_kettles
  FOR SELECT
  TO anon
  USING (TRUE);

CREATE POLICY brew_kettles_insert
  ON aibrewgenius.brew_kettles
  FOR INSERT
  TO anon
  WITH CHECK (TRUE);

CREATE POLICY brew_kettles_update
  ON aibrewgenius.brew_kettles
  FOR UPDATE
  TO anon
  USING (TRUE)
  WITH CHECK (TRUE);

CREATE POLICY brew_kettles_delete
  ON aibrewgenius.brew_kettles
  FOR DELETE
  TO anon
  USING (TRUE);

CREATE POLICY fermenters_select
  ON aibrewgenius.fermenters
  FOR SELECT
  TO anon
  USING (TRUE);

CREATE POLICY fermenters_insert
  ON aibrewgenius.fermenters
  FOR INSERT
  TO anon
  WITH CHECK (TRUE);

CREATE POLICY fermenters_update
  ON aibrewgenius.fermenters
  FOR UPDATE
  TO anon
  USING (TRUE)
  WITH CHECK (TRUE);

CREATE POLICY fermenters_delete
  ON aibrewgenius.fermenters
  FOR DELETE
  TO anon
  USING (TRUE);

CREATE POLICY yeast_bank_entries_select
  ON aibrewgenius.yeast_bank_entries
  FOR SELECT
  TO anon
  USING (TRUE);

CREATE POLICY yeast_bank_entries_insert
  ON aibrewgenius.yeast_bank_entries
  FOR INSERT
  TO anon
  WITH CHECK (TRUE);

CREATE POLICY yeast_bank_entries_update
  ON aibrewgenius.yeast_bank_entries
  FOR UPDATE
  TO anon
  USING (TRUE)
  WITH CHECK (TRUE);

CREATE POLICY yeast_bank_entries_delete
  ON aibrewgenius.yeast_bank_entries
  FOR DELETE
  TO anon
  USING (TRUE);

CREATE POLICY malt_depots_select
  ON aibrewgenius.malt_depots
  FOR SELECT
  TO anon
  USING (TRUE);

CREATE POLICY malt_depots_insert
  ON aibrewgenius.malt_depots
  FOR INSERT
  TO anon
  WITH CHECK (TRUE);

CREATE POLICY malt_depots_update
  ON aibrewgenius.malt_depots
  FOR UPDATE
  TO anon
  USING (TRUE)
  WITH CHECK (TRUE);

CREATE POLICY malt_depots_delete
  ON aibrewgenius.malt_depots
  FOR DELETE
  TO anon
  USING (TRUE);

CREATE POLICY fermenter_controllers_select
  ON aibrewgenius.fermenter_controllers
  FOR SELECT
  TO anon
  USING (TRUE);

CREATE POLICY fermenter_controllers_insert
  ON aibrewgenius.fermenter_controllers
  FOR INSERT
  TO anon
  WITH CHECK (TRUE);

CREATE POLICY fermenter_controllers_update
  ON aibrewgenius.fermenter_controllers
  FOR UPDATE
  TO anon
  USING (TRUE)
  WITH CHECK (TRUE);

CREATE POLICY fermenter_controllers_delete
  ON aibrewgenius.fermenter_controllers
  FOR DELETE
  TO anon
  USING (TRUE);
