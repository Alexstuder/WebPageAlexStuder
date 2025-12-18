-- DANGER: this drops the entire schema including data
DROP SCHEMA IF EXISTS aibrewgenius CASCADE;
CREATE SCHEMA aibrewgenius;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE TABLE aibrewgenius.user_profiles (
  id TEXT PRIMARY KEY,
  name TEXT,
  avatar_blob TEXT,
  kettle_brand TEXT,
  kettle_type TEXT,
  default_batch_liters DOUBLE PRECISION,
  fermenter_brand TEXT,
  fermenter_type TEXT,
  controller TEXT,
  controller_user TEXT,
  controller_api_key TEXT,
  rapt_user_id TEXT,
  rapt_api_key TEXT,
  brewfather_user_id TEXT,
  brewfather_api_key TEXT,
  brewfather_sync_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  yeast_entries JSONB NOT NULL DEFAULT '[]'::jsonb,
  malt_depot JSONB NOT NULL DEFAULT '[]'::jsonb
);
CREATE TABLE aibrewgenius.water_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
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
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  volume_liters DOUBLE PRECISION,
  has_condenser_hat BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);
CREATE TABLE aibrewgenius.fermenters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  type TEXT,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  volume_liters DOUBLE PRECISION,
  has_heating BOOLEAN NOT NULL DEFAULT FALSE,
  has_cooling BOOLEAN NOT NULL DEFAULT FALSE,
  has_dry_hopping_port BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);
CREATE TABLE aibrewgenius.packaging_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  target_volume DOUBLE PRECISION,
  bottle_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  bottle_carbonation_temp_c DOUBLE PRECISION,
  bottle_storage_temp_c DOUBLE PRECISION,
  keg_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  keg_carbonation_temp_c DOUBLE PRECISION,
  keg_storage_temp_c DOUBLE PRECISION,
  keg_volume_l DOUBLE PRECISION,
  has_co2 BOOLEAN NOT NULL DEFAULT TRUE,
  has_nitro BOOLEAN NOT NULL DEFAULT FALSE,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);
CREATE TABLE aibrewgenius.fining_agents (
  user_profile_id TEXT PRIMARY KEY REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  irish_moss BOOLEAN NOT NULL DEFAULT FALSE,
  whirlfloc BOOLEAN NOT NULL DEFAULT FALSE,
  gelatin BOOLEAN NOT NULL DEFAULT FALSE,
  biersol BOOLEAN NOT NULL DEFAULT FALSE,
  polyclar BOOLEAN NOT NULL DEFAULT FALSE,
  isinglass BOOLEAN NOT NULL DEFAULT FALSE,
  bentonite BOOLEAN NOT NULL DEFAULT FALSE,
  egg_whites BOOLEAN NOT NULL DEFAULT FALSE,
  activated_carbon BOOLEAN NOT NULL DEFAULT FALSE,
  extras JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);
CREATE TABLE aibrewgenius.yeast_bank_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brewfather_id TEXT,
  brand TEXT NOT NULL,
  strain TEXT NOT NULL,
  product_id TEXT,
  form TEXT,
  inventory DOUBLE PRECISION,
  unit TEXT,
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
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  username TEXT,
  api_key TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);
CREATE UNIQUE INDEX water_profiles_default_unique
  ON aibrewgenius.water_profiles(user_profile_id)
  WHERE is_default;
CREATE UNIQUE INDEX brew_kettles_default_unique
  ON aibrewgenius.brew_kettles(user_profile_id)
  WHERE is_default;
CREATE UNIQUE INDEX fermenters_default_unique
  ON aibrewgenius.fermenters(user_profile_id)
  WHERE is_default;
CREATE UNIQUE INDEX packaging_profiles_default_unique
  ON aibrewgenius.packaging_profiles(user_profile_id)
  WHERE is_default;
CREATE UNIQUE INDEX fermenter_controllers_default_unique
  ON aibrewgenius.fermenter_controllers(user_profile_id)
  WHERE is_default;
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
CREATE TRIGGER packaging_profiles_set_updated_at
BEFORE UPDATE ON aibrewgenius.packaging_profiles
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
CREATE TRIGGER fining_agents_set_updated_at
BEFORE UPDATE ON aibrewgenius.fining_agents
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();
GRANT USAGE ON SCHEMA aibrewgenius TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA aibrewgenius TO anon;
-- Enable RLS and allow anon writes (adjust as needed)
ALTER TABLE aibrewgenius.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.water_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.brew_kettles ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.fermenters ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.packaging_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.yeast_bank_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.malt_depots ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.fermenter_controllers ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.fining_agents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow full access" ON aibrewgenius.user_profiles FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access" ON aibrewgenius.water_profiles FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access" ON aibrewgenius.brew_kettles FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access" ON aibrewgenius.fermenters FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access" ON aibrewgenius.packaging_profiles FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access" ON aibrewgenius.yeast_bank_entries FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access" ON aibrewgenius.malt_depots FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access" ON aibrewgenius.fermenter_controllers FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE TABLE aibrewgenius.fermentables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brewfather_id TEXT,
  name TEXT NOT NULL,
  supplier TEXT,
  amount DOUBLE PRECISION,
  unit TEXT,
  type TEXT,
  potential DOUBLE PRECISION,
  yield DOUBLE PRECISION,
  attenuation DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TRIGGER fermentables_set_updated_at
BEFORE UPDATE ON aibrewgenius.fermentables
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE UNIQUE INDEX fermentables_user_brewfather_unique
  ON aibrewgenius.fermentables(user_profile_id, brewfather_id);

ALTER TABLE aibrewgenius.fermentables ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow full access" ON aibrewgenius.fermentables FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE TABLE aibrewgenius.hops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brewfather_id TEXT,
  name TEXT NOT NULL,
  alpha DOUBLE PRECISION,
  origin TEXT,
  year TEXT,
  amount DOUBLE PRECISION,
  unit TEXT,
  type TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TRIGGER hops_set_updated_at
BEFORE UPDATE ON aibrewgenius.hops
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE UNIQUE INDEX hops_user_brewfather_unique
  ON aibrewgenius.hops(user_profile_id, brewfather_id);

ALTER TABLE aibrewgenius.hops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow full access" ON aibrewgenius.hops FOR ALL TO anon USING (true) WITH CHECK (true);

GRANT ALL ON TABLE aibrewgenius.hops TO anon, authenticated, service_role;

CREATE TABLE aibrewgenius.miscs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brewfather_id TEXT,
  name TEXT NOT NULL,
  amount DOUBLE PRECISION,
  unit TEXT,
  type TEXT,
  "use" TEXT,
  time DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TRIGGER miscs_set_updated_at
BEFORE UPDATE ON aibrewgenius.miscs
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE UNIQUE INDEX miscs_user_brewfather_unique
  ON aibrewgenius.miscs(user_profile_id, brewfather_id);

ALTER TABLE aibrewgenius.miscs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow full access" ON aibrewgenius.miscs FOR ALL TO anon USING (true) WITH CHECK (true);

GRANT ALL ON TABLE aibrewgenius.miscs TO anon, authenticated, service_role;

CREATE TABLE aibrewgenius.recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brewfather_id TEXT,
  name TEXT NOT NULL,
  style TEXT,
  abv DOUBLE PRECISION,
  ibu DOUBLE PRECISION,
  color DOUBLE PRECISION,
  data JSONB,
  image BYTEA,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TRIGGER recipes_set_updated_at
BEFORE UPDATE ON aibrewgenius.recipes
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE UNIQUE INDEX recipes_user_brewfather_unique
  ON aibrewgenius.recipes(user_profile_id, brewfather_id);

ALTER TABLE aibrewgenius.recipes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow full access" ON aibrewgenius.recipes FOR ALL TO anon USING (true) WITH CHECK (true);
GRANT ALL ON TABLE aibrewgenius.recipes TO anon, authenticated, service_role;

CREATE TABLE aibrewgenius.batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  brewfather_id TEXT,
  name TEXT NOT NULL,
  batch_no INTEGER,
  status TEXT,
  brew_date BIGINT,
  recipe_name TEXT,
  data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TRIGGER batches_set_updated_at
BEFORE UPDATE ON aibrewgenius.batches
FOR EACH ROW
EXECUTE FUNCTION aibrewgenius.set_updated_at();

CREATE UNIQUE INDEX batches_user_brewfather_unique
  ON aibrewgenius.batches(user_profile_id, brewfather_id);

ALTER TABLE aibrewgenius.batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow full access" ON aibrewgenius.batches FOR ALL TO anon USING (true) WITH CHECK (true);
GRANT ALL ON TABLE aibrewgenius.batches TO anon, authenticated, service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON aibrewgenius.fermentables TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON aibrewgenius.fermentables TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON aibrewgenius.fermentables TO service_role;

CREATE POLICY "Allow full access" ON aibrewgenius.fining_agents FOR ALL TO anon USING (true) WITH CHECK (true);

-- Storage bucket configuration for Avatars
-- Requires storage schema (Supabase)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for storage.objects
DROP POLICY IF EXISTS "Avatar images are publicly accessible." ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible."
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'avatars' );

DROP POLICY IF EXISTS "Anyone can upload an avatar." ON storage.objects;
CREATE POLICY "Anyone can upload an avatar."
  ON storage.objects FOR INSERT
  WITH CHECK ( bucket_id = 'avatars' );

DROP POLICY IF EXISTS "Anyone can update an avatar." ON storage.objects;
CREATE POLICY "Anyone can update an avatar."
  ON storage.objects FOR UPDATE
  USING ( bucket_id = 'avatars' );