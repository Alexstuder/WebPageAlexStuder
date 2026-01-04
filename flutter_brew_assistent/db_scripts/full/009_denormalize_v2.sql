
-- 1. Try to drop the legacy table (as requested)
DROP TABLE IF EXISTS aibrewgenius.ai_generated_recipes CASCADE;

-- 2. Drop the normalized sub-tables (we are denormalizing lists back into main)
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_malts CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_hops CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_specials CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_finings CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_mash_steps CASCADE;
DROP TABLE IF EXISTS aibrewgenius.ai_recipe_fermentation_steps CASCADE;

-- 3. Add JSONB columns to V2 table for storing lists
ALTER TABLE aibrewgenius.ai_generated_recipes_v2
  ADD COLUMN IF NOT EXISTS malts JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS hops JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS specials JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS finings JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS mash_steps JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS fermentation_steps JSONB DEFAULT '[]'::jsonb;
