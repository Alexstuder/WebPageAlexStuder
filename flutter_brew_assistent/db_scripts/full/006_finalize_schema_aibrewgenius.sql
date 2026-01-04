
-- Clean up public tables
DROP TABLE IF EXISTS public.ai_recipe_malts CASCADE;
DROP TABLE IF EXISTS public.ai_recipe_hops CASCADE;
DROP TABLE IF EXISTS public.ai_recipe_specials CASCADE;
DROP TABLE IF EXISTS public.ai_recipe_finings CASCADE;
DROP TABLE IF EXISTS public.ai_recipe_mash_steps CASCADE;
DROP TABLE IF EXISTS public.ai_recipe_fermentation_steps CASCADE;
DROP TABLE IF EXISTS public.ai_generated_recipes CASCADE;

-- Clean up aibrewgenius tables if they exist (start fresh normalisation)
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_malts CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_hops CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_specials CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_finings CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_mash_steps CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_fermentation_steps CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_generated_recipes CASCADE;

-- 1. Main Recipe Table (aibrewgenius)
CREATE TABLE aibrewgenius.ai_generated_recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL, 
  basis_bier TEXT,
  bier_typ TEXT,
  stammwuerze_sg DOUBLE PRECISION,
  restextrakt_sg DOUBLE PRECISION,
  alkoholgehalt DOUBLE PRECISION,
  notizen TEXT[],
  generated_image TEXT,
  
  -- Ingredients: Yeast
  yeast_name TEXT,
  yeast_type TEXT,
  yeast_amount TEXT,
  yeast_procurement_needed BOOLEAN,

  -- Ingredients: Water
  water_ca INT,
  water_mg INT,
  water_na INT,
  water_cl INT,
  water_so4 INT,
  water_hco3 INT,
  water_salt_timing TEXT,

  -- Process: Mash
  mash_water_l DOUBLE PRECISION,
  mash_in_temp_c DOUBLE PRECISION,

  -- Process: Lauter
  lauter_sparge_water_l DOUBLE PRECISION,
  lauter_target_ph TEXT,

  -- Process: Boil
  boil_pre_vol_l DOUBLE PRECISION,
  boil_duration_min INT,

  -- Process: Fermentation
  fermentation_pitch_temp_c DOUBLE PRECISION,

  -- Process: Packaging
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

-- 2. Malts
CREATE TABLE aibrewgenius.ai_recipe_malts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  amount_kg DOUBLE PRECISION,
  crush_gap_mm DOUBLE PRECISION
);

-- 3. Hops
CREATE TABLE aibrewgenius.ai_recipe_hops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  alpha_acid DOUBLE PRECISION,
  amount_g DOUBLE PRECISION,
  use_type TEXT,
  time_min INT
);

-- 4. Specials
CREATE TABLE aibrewgenius.ai_recipe_specials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  amount TEXT,
  unit TEXT,
  detail TEXT
);

-- 5. Finings
CREATE TABLE aibrewgenius.ai_recipe_finings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes(id) ON DELETE CASCADE,
  name TEXT,
  amount TEXT,
  phase TEXT,
  purpose TEXT,
  detail TEXT,
  procurement_needed BOOLEAN
);

-- 6. Mash Steps
CREATE TABLE aibrewgenius.ai_recipe_mash_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes(id) ON DELETE CASCADE,
  stage TEXT,
  temp_c DOUBLE PRECISION,
  duration_min INT,
  step_order INT
);

-- 7. Fermentation Steps
CREATE TABLE aibrewgenius.ai_recipe_fermentation_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes(id) ON DELETE CASCADE,
  phase TEXT,
  temp_c DOUBLE PRECISION,
  days INT,
  pressure_bar DOUBLE PRECISION,
  pressure_note TEXT,
  note TEXT,
  step_order INT
);

-- RLS & Permissions
ALTER TABLE aibrewgenius.ai_generated_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_malts ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_hops ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_specials ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_finings ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_mash_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_fermentation_steps ENABLE ROW LEVEL SECURITY;

GRANT ALL ON ALL TABLES IN SCHEMA aibrewgenius TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA aibrewgenius TO anon, authenticated, service_role;

CREATE POLICY "Allow full access recipes" ON aibrewgenius.ai_generated_recipes FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access malts" ON aibrewgenius.ai_recipe_malts FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access hops" ON aibrewgenius.ai_recipe_hops FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access specials" ON aibrewgenius.ai_recipe_specials FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access finings" ON aibrewgenius.ai_recipe_finings FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access mash" ON aibrewgenius.ai_recipe_mash_steps FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access ferm" ON aibrewgenius.ai_recipe_fermentation_steps FOR ALL TO anon USING (true) WITH CHECK (true);
