
ALTER TABLE aibrewgenius.ai_generated_recipes
  ADD COLUMN IF NOT EXISTS basis_bier TEXT,
  ADD COLUMN IF NOT EXISTS bier_typ TEXT,
  ADD COLUMN IF NOT EXISTS stammwuerze_sg DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS restextrakt_sg DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS alkoholgehalt DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS notizen TEXT[],
  ADD COLUMN IF NOT EXISTS generated_image TEXT,
  
  -- Ingredients: Yeast
  ADD COLUMN IF NOT EXISTS yeast_name TEXT,
  ADD COLUMN IF NOT EXISTS yeast_type TEXT,
  ADD COLUMN IF NOT EXISTS yeast_amount TEXT,
  ADD COLUMN IF NOT EXISTS yeast_procurement_needed BOOLEAN,

  -- Ingredients: Water
  ADD COLUMN IF NOT EXISTS water_ca INT,
  ADD COLUMN IF NOT EXISTS water_mg INT,
  ADD COLUMN IF NOT EXISTS water_na INT,
  ADD COLUMN IF NOT EXISTS water_cl INT,
  ADD COLUMN IF NOT EXISTS water_so4 INT,
  ADD COLUMN IF NOT EXISTS water_hco3 INT,
  ADD COLUMN IF NOT EXISTS water_salt_timing TEXT,

  -- Process: Mash
  ADD COLUMN IF NOT EXISTS mash_water_l DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS mash_in_temp_c DOUBLE PRECISION,

  -- Process: Lauter
  ADD COLUMN IF NOT EXISTS lauter_sparge_water_l DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS lauter_target_ph TEXT,

  -- Process: Boil
  ADD COLUMN IF NOT EXISTS boil_pre_vol_l DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS boil_duration_min INT,

  -- Process: Fermentation
  ADD COLUMN IF NOT EXISTS fermentation_pitch_temp_c DOUBLE PRECISION,

  -- Process: Packaging
  ADD COLUMN IF NOT EXISTS packaging_type TEXT,
  ADD COLUMN IF NOT EXISTS packaging_co2_target DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS packaging_keg_pressure DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS packaging_keg_temp DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS packaging_bottle_sugar DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS packaging_bottle_temp DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS packaging_storage_temp DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS packaging_storage_weeks INT,
  ADD COLUMN IF NOT EXISTS packaging_maturation_note TEXT,
  ADD COLUMN IF NOT EXISTS packaging_serving_gas TEXT,
  ADD COLUMN IF NOT EXISTS packaging_carb_days INT;
