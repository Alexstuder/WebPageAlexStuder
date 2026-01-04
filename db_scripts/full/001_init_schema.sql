-- DANGER: this drops the entire schema including data
DROP SCHEMA IF EXISTS aibrewgenius CASCADE;
CREATE SCHEMA aibrewgenius;
GRANT USAGE ON SCHEMA aibrewgenius TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA aibrewgenius GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA aibrewgenius GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE TABLE aibrewgenius.user_profiles (
  id TEXT PRIMARY KEY,
  name TEXT,
  avatar_blob TEXT,
  default_batch_liters DOUBLE PRECISION,
  rapt_user_id TEXT,
  rapt_api_key TEXT,
  brewfather_user_id TEXT,
  brewfather_api_key TEXT,
  brewfather_sync_enabled BOOLEAN NOT NULL DEFAULT FALSE
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
  post_boil_loss_liters DOUBLE PRECISION DEFAULT 0,
  boil_off_percentage DOUBLE PRECISION DEFAULT 0,
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
  can_pressurize BOOLEAN NOT NULL DEFAULT FALSE,
  fermentation_loss_liters DOUBLE PRECISION NOT NULL DEFAULT 0,
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
  zucht_generationen JSONB DEFAULT '[]'::jsonb,
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
  analysis_data JSONB,
  rapt_data JSONB,
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
  USING ( bucket_id = 'avatars' );-- Create table for storing AI generated recipes (Normalized in PUBLIC schema)
CREATE TABLE public.ai_generated_recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL, 
  
  -- Core Info
  basis_bier TEXT,
  bier_typ TEXT,
  stammwuerze_sg DOUBLE PRECISION,
  restextrakt_sg DOUBLE PRECISION,
  alkoholgehalt DOUBLE PRECISION,
  notizen TEXT[],
  
  -- Ingredients: Yeast (1:1)
  yeast_name TEXT,
  yeast_type TEXT,
  yeast_amount TEXT,
  yeast_procurement_needed BOOLEAN,

  -- Ingredients: Water Targets (1:1)
  water_ca INT,
  water_mg INT,
  water_na INT,
  water_cl INT,
  water_so4 INT,
  water_hco3 INT,
  water_salt_timing TEXT,

  -- Process: Mash (1:1)
  mash_water_l DOUBLE PRECISION,
  mash_in_temp_c DOUBLE PRECISION,

  -- Process: Lauter (1:1)
  lauter_sparge_water_l DOUBLE PRECISION,
  lauter_target_ph TEXT,

  -- Process: Boil (1:1)
  boil_pre_vol_l DOUBLE PRECISION,
  boil_duration_min INT,

  -- Process: Fermentation (1:1)
  fermentation_pitch_temp_c DOUBLE PRECISION,

  -- Process: Packaging (1:1)
  packaging_type TEXT,
  packaging_co2_target DOUBLE PRECISION,
  packaging_keg_pressure DOUBLE PRECISION,
  packaging_keg_temp DOUBLE PRECISION,
  packaging_bottle_sugar DOUBLE PRECISION,
  packaging_bottle_temp DOUBLE PRECISION,
  packaging_storage_temp DOUBLE PRECISION,
  packaging_storage_weeks INT,
  packaging_maturation_note TEXT,
  packaging_serving_gas TEXT,
  packaging_carb_days INT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Malts (1:N)
CREATE TABLE public.ai_recipe_malts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES public.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  amount_kg DOUBLE PRECISION,
  crush_gap_mm DOUBLE PRECISION
);

-- 3. Hops (1:N)
CREATE TABLE public.ai_recipe_hops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES public.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  alpha_acid DOUBLE PRECISION,
  amount_g DOUBLE PRECISION,
  use_type TEXT,
  time_min INT
);

-- 4. Special Ingredients (1:N)
CREATE TABLE public.ai_recipe_specials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES public.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  amount TEXT,
  unit TEXT,
  detail TEXT
);

-- 5. Fining Agents (1:N)
CREATE TABLE public.ai_recipe_finings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES public.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  amount TEXT,
  phase TEXT,
  purpose TEXT,
  detail TEXT,
  procurement_needed BOOLEAN
);

-- 6. Mash Steps (1:N)
CREATE TABLE public.ai_recipe_mash_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES public.ai_generated_recipes(id) ON DELETE CASCADE,
  stage TEXT,
  temp_c DOUBLE PRECISION,
  duration_min INT,
  step_order INT
);

-- 7. Fermentation Steps (1:N)
CREATE TABLE public.ai_recipe_fermentation_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES public.ai_generated_recipes(id) ON DELETE CASCADE,
  phase TEXT,
  temp_c DOUBLE PRECISION,
  days INT,
  pressure_bar DOUBLE PRECISION,
  pressure_note TEXT,
  note TEXT,
  step_order INT
);

-- RLS
ALTER TABLE public.ai_generated_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recipe_malts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recipe_hops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recipe_specials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recipe_finings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recipe_mash_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recipe_fermentation_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access recipes" ON public.ai_generated_recipes FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access malts" ON public.ai_recipe_malts FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access hops" ON public.ai_recipe_hops FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access specials" ON public.ai_recipe_specials FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access finings" ON public.ai_recipe_finings FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access mash" ON public.ai_recipe_mash_steps FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access ferm" ON public.ai_recipe_fermentation_steps FOR ALL TO anon USING (true) WITH CHECK (true);

GRANT ALL ON TABLE public.ai_generated_recipes TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.ai_recipe_malts TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.ai_recipe_hops TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.ai_recipe_specials TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.ai_recipe_finings TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.ai_recipe_mash_steps TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.ai_recipe_fermentation_steps TO anon, authenticated, service_role;

-- VIEW for easy JSON retrieval (Reconstructs the AiRecipe structure)
CREATE OR REPLACE VIEW public.ai_generated_recipes_view AS
SELECT 
  r.id,
  r.user_profile_id,
  r.basis_bier,
  r.bier_typ,
  r.created_at,
  r.stammwuerze_sg,
  r.restextrakt_sg,
  r.alkoholgehalt,
  jsonb_build_object(
      'basis_bier', r.basis_bier,
      'bier_typ', r.bier_typ,
      'stammwuerze_sg', r.stammwuerze_sg,
      'restextrakt_sg', r.restextrakt_sg,
      'alkoholgehalt_vol_prozent', r.alkoholgehalt,
      'Notizen', r.notizen,
      'Zutaten', jsonb_build_object(
        'Original_Malz', COALESCE((SELECT jsonb_agg(jsonb_build_object('Name', m.name, 'Menge_kg', m.amount_kg, 'Optimales_Schrot_Spaltmass_mm', m.crush_gap_mm)) FROM public.ai_recipe_malts m WHERE m.recipe_id = r.id), '[]'::jsonb),
        'Original_Hopfen', COALESCE((SELECT jsonb_agg(jsonb_build_object('Sortenname', h.name, 'Alpha_Saeure', h.alpha_acid, 'Menge_g', h.amount_g, 'Einsatz', h.use_type, 'Zeit_min', h.time_min)) FROM public.ai_recipe_hops h WHERE h.recipe_id = r.id), '[]'::jsonb),
        'Original_Hefe', jsonb_build_object('Name', r.yeast_name, 'Typ', r.yeast_type, 'Menge_Packungen_oder_ml', r.yeast_amount, 'Beschaffung_Notwendig', r.yeast_procurement_needed),
        'Wasserprofil_Zielwerte', jsonb_build_object('Kalzium_Ca_mg_L', r.water_ca, 'Magnesium_Mg_mg_L', r.water_mg, 'Natrium_Na_mg_L', r.water_na, 'Chlorid_Cl_mg_L', r.water_cl, 'Sulfat_SO4_mg_L', r.water_so4, 'Hydrogencarbonat_HCO3_mg_L', r.water_hco3, 'Salzzugabe_Zeitpunkt', r.water_salt_timing),
        'Spezialzutaten', COALESCE((SELECT jsonb_agg(jsonb_build_object('Name', s.name, 'Menge', s.amount, 'Einheit', s.unit, 'Anwendung_Detail', s.detail)) FROM public.ai_recipe_specials s WHERE s.recipe_id = r.id), '[]'::jsonb),
        'Klaer_und_Schonungsmittel', COALESCE((SELECT jsonb_agg(jsonb_build_object('Name', f.name, 'Menge', f.amount, 'Phase', f.phase, 'Zweck', f.purpose, 'Anwendung_Detail', f.detail, 'Beschaffung_Notwendig', f.procurement_needed)) FROM public.ai_recipe_finings f WHERE f.recipe_id = r.id), '[]'::jsonb)
      ),
      'Prozessdaten', jsonb_build_object(
        'Maischeplan', jsonb_build_object('Hauptguss_L', r.mash_water_l, 'Einmaischtemperatur_C', r.mash_in_temp_c, 'Rasten', COALESCE((SELECT jsonb_agg(jsonb_build_object('Stufe', ms.stage, 'Temperatur_C', ms.temp_c, 'Dauer_min', ms.duration_min) ORDER BY ms.step_order) FROM public.ai_recipe_mash_steps ms WHERE ms.recipe_id = r.id), '[]'::jsonb)),
        'Laeuterungsplan', jsonb_build_object('Nachgusswasser_Menge_L', r.lauter_sparge_water_l, 'Ziel_pH_vor_Laeutern', r.lauter_target_ph),
        'Kochplan', jsonb_build_object('Pfannevoll_Tatsaechlich_L', r.boil_pre_vol_l, 'Gesamte_Kochdauer_min', r.boil_duration_min),
        'Gaerungsplan', jsonb_build_object('Hefe_Anstelltemperatur_C', r.fermentation_pitch_temp_c, 'Gaerverlauf', COALESCE((SELECT jsonb_agg(jsonb_build_object('Phase', fs.phase, 'Temperatur_C', fs.temp_c, 'Dauer_Tage', fs.days, 'Druck_bar', fs.pressure_bar, 'Druck_Begruendung', fs.pressure_note, 'Hinweis', fs.note) ORDER BY fs.step_order) FROM public.ai_recipe_fermentation_steps fs WHERE fs.recipe_id = r.id), '[]'::jsonb)),
        'Abfuell_und_Lagerungsplan', jsonb_build_object('Abfuellung_Typ', r.packaging_type, 'Karbonisierung_Ziel_CO2_g_L', r.packaging_co2_target, 'Keg_Druck_bar', r.packaging_keg_pressure, 'Keg_Karbonisierung_Temp_C', r.packaging_keg_temp, 'Flaschen_Zucker_g_pro_L', r.packaging_bottle_sugar, 'Flaschen_Karbonisierung_Temp_C', r.packaging_bottle_temp, 'Lagerung_Temperatur_C', r.packaging_storage_temp, 'Lagerung_Dauer_Wochen', r.packaging_storage_weeks, 'Reifungshinweis', r.packaging_maturation_note, 'Empfohlenes_Ausschankgas', r.packaging_serving_gas, 'Karbonisierungsdauer_Tage', r.packaging_carb_days)
      )
  ) as recipe_data
FROM public.ai_generated_recipes r;

GRANT SELECT ON public.ai_generated_recipes_view TO anon, authenticated, service_role;

