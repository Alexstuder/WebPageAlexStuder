-- Normalized AI Recipe Tables (V2)
CREATE TABLE IF NOT EXISTS aibrewgenius.ai_generated_recipes_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_profile_id TEXT NOT NULL REFERENCES aibrewgenius.user_profiles(id) ON DELETE CASCADE,
  
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
CREATE TABLE IF NOT EXISTS aibrewgenius.ai_recipe_malts_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes_v2(id) ON DELETE CASCADE,
  name TEXT,
  amount_kg DOUBLE PRECISION,
  crush_gap_mm DOUBLE PRECISION
);

-- 3. Hops (1:N)
CREATE TABLE IF NOT EXISTS aibrewgenius.ai_recipe_hops_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes_v2(id) ON DELETE CASCADE,
  name TEXT,
  alpha_acid DOUBLE PRECISION,
  amount_g DOUBLE PRECISION,
  use_type TEXT,
  time_min INT
);

-- 4. Special Ingredients (1:N)
CREATE TABLE IF NOT EXISTS aibrewgenius.ai_recipe_specials_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes_v2(id) ON DELETE CASCADE,
  name TEXT,
  amount TEXT,
  unit TEXT,
  detail TEXT
);

-- 5. Fining Agents (1:N)
CREATE TABLE IF NOT EXISTS aibrewgenius.ai_recipe_finings_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes_v2(id) ON DELETE CASCADE,
  name TEXT,
  amount TEXT,
  phase TEXT,
  purpose TEXT,
  detail TEXT,
  procurement_needed BOOLEAN
);

-- 6. Mash Steps (1:N)
CREATE TABLE IF NOT EXISTS aibrewgenius.ai_recipe_mash_steps_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes_v2(id) ON DELETE CASCADE,
  stage TEXT,
  temp_c DOUBLE PRECISION,
  duration_min INT,
  step_order INT
);

-- 7. Fermentation Steps (1:N)
CREATE TABLE IF NOT EXISTS aibrewgenius.ai_recipe_fermentation_steps_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID NOT NULL REFERENCES aibrewgenius.ai_generated_recipes_v2(id) ON DELETE CASCADE,
  phase TEXT,
  temp_c DOUBLE PRECISION,
  days INT,
  pressure_bar DOUBLE PRECISION,
  pressure_note TEXT,
  note TEXT,
  step_order INT
);

-- Triggers 
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'ai_generated_recipes_v2_set_updated_at') THEN
    CREATE TRIGGER ai_generated_recipes_v2_set_updated_at BEFORE UPDATE ON aibrewgenius.ai_generated_recipes_v2 FOR EACH ROW EXECUTE FUNCTION aibrewgenius.set_updated_at();
  END IF;
END
$$;

-- RLS & Grants
ALTER TABLE aibrewgenius.ai_generated_recipes_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_malts_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_hops_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_specials_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_finings_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_mash_steps_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE aibrewgenius.ai_recipe_fermentation_steps_v2 ENABLE ROW LEVEL SECURITY;

-- Grants
GRANT ALL ON TABLE aibrewgenius.ai_generated_recipes_v2 TO anon, authenticated, service_role;
GRANT ALL ON TABLE aibrewgenius.ai_recipe_malts_v2 TO anon, authenticated, service_role;
GRANT ALL ON TABLE aibrewgenius.ai_recipe_hops_v2 TO anon, authenticated, service_role;
GRANT ALL ON TABLE aibrewgenius.ai_recipe_specials_v2 TO anon, authenticated, service_role;
GRANT ALL ON TABLE aibrewgenius.ai_recipe_finings_v2 TO anon, authenticated, service_role;
GRANT ALL ON TABLE aibrewgenius.ai_recipe_mash_steps_v2 TO anon, authenticated, service_role;
GRANT ALL ON TABLE aibrewgenius.ai_recipe_fermentation_steps_v2 TO anon, authenticated, service_role;

-- Policies
CREATE POLICY "Allow full access recipes v2" ON aibrewgenius.ai_generated_recipes_v2 FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access malts v2" ON aibrewgenius.ai_recipe_malts_v2 FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access hops v2" ON aibrewgenius.ai_recipe_hops_v2 FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access specials v2" ON aibrewgenius.ai_recipe_specials_v2 FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access finings v2" ON aibrewgenius.ai_recipe_finings_v2 FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access mash v2" ON aibrewgenius.ai_recipe_mash_steps_v2 FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access ferm v2" ON aibrewgenius.ai_recipe_fermentation_steps_v2 FOR ALL TO anon USING (true) WITH CHECK (true);

-- VIEW for easy JSON retrieval (Reconstructs the AiRecipe structure)
CREATE OR REPLACE VIEW aibrewgenius.ai_generated_recipes_view_v2 AS
SELECT 
  r.id,
  r.user_profile_id,
  r.basis_bier,
  r.bier_typ,
  r.created_at,
  r.stammwuerze_sg,
  r.restextrakt_sg,
  r.alkoholgehalt,
  (
    SELECT jsonb_build_object(
      'basis_bier', r.basis_bier,
      'bier_typ', r.bier_typ,
      'stammwuerze_sg', r.stammwuerze_sg,
      'restextrakt_sg', r.restextrakt_sg,
      'alkoholgehalt_vol_prozent', r.alkoholgehalt,
      'Notizen', r.notizen,
      'Zutaten', jsonb_build_object(
        'Original_Malz', COALESCE((SELECT jsonb_agg(jsonb_build_object('Name', m.name, 'Menge_kg', m.amount_kg, 'Optimales_Schrot_Spaltmass_mm', m.crush_gap_mm)) FROM aibrewgenius.ai_recipe_malts_v2 m WHERE m.recipe_id = r.id), '[]'::jsonb),
        'Original_Hopfen', COALESCE((SELECT jsonb_agg(jsonb_build_object('Sortenname', h.name, 'Alpha_Saeure', h.alpha_acid, 'Menge_g', h.amount_g, 'Einsatz', h.use_type, 'Zeit_min', h.time_min)) FROM aibrewgenius.ai_recipe_hops_v2 h WHERE h.recipe_id = r.id), '[]'::jsonb),
        'Original_Hefe', jsonb_build_object('Name', r.yeast_name, 'Typ', r.yeast_type, 'Menge_Packungen_oder_ml', r.yeast_amount, 'Beschaffung_Notwendig', r.yeast_procurement_needed),
        'Wasserprofil_Zielwerte', jsonb_build_object('Kalzium_Ca_mg_L', r.water_ca, 'Magnesium_Mg_mg_L', r.water_mg, 'Natrium_Na_mg_L', r.water_na, 'Chlorid_Cl_mg_L', r.water_cl, 'Sulfat_SO4_mg_L', r.water_so4, 'Hydrogencarbonat_HCO3_mg_L', r.water_hco3, 'Salzzugabe_Zeitpunkt', r.water_salt_timing),
        'Spezialzutaten', COALESCE((SELECT jsonb_agg(jsonb_build_object('Name', s.name, 'Menge', s.amount, 'Einheit', s.unit, 'Anwendung_Detail', s.detail)) FROM aibrewgenius.ai_recipe_specials_v2 s WHERE s.recipe_id = r.id), '[]'::jsonb),
        'Klaer_und_Schonungsmittel', COALESCE((SELECT jsonb_agg(jsonb_build_object('Name', f.name, 'Menge', f.amount, 'Phase', f.phase, 'Zweck', f.purpose, 'Anwendung_Detail', f.detail, 'Beschaffung_Notwendig', f.procurement_needed)) FROM aibrewgenius.ai_recipe_finings_v2 f WHERE f.recipe_id = r.id), '[]'::jsonb)
      ),
      'Prozessdaten', jsonb_build_object(
        'Maischeplan', jsonb_build_object('Hauptguss_L', r.mash_water_l, 'Einmaischtemperatur_C', r.mash_in_temp_c, 'Rasten', COALESCE((SELECT jsonb_agg(jsonb_build_object('Stufe', ms.stage, 'Temperatur_C', ms.temp_c, 'Dauer_min', ms.duration_min)) FROM aibrewgenius.ai_recipe_mash_steps_v2 ms WHERE ms.recipe_id = r.id ORDER BY ms.step_order), '[]'::jsonb)),
        'Laeuterungsplan', jsonb_build_object('Nachgusswasser_Menge_L', r.lauter_sparge_water_l, 'Ziel_pH_vor_Laeutern', r.lauter_target_ph),
        'Kochplan', jsonb_build_object('Pfannevoll_Tatsaechlich_L', r.boil_pre_vol_l, 'Gesamte_Kochdauer_min', r.boil_duration_min),
        'Gaerungsplan', jsonb_build_object('Hefe_Anstelltemperatur_C', r.fermentation_pitch_temp_c, 'Gaerverlauf', COALESCE((SELECT jsonb_agg(jsonb_build_object('Phase', fs.phase, 'Temperatur_C', fs.temp_c, 'Dauer_Tage', fs.days, 'Druck_bar', fs.pressure_bar, 'Druck_Begruendung', fs.pressure_note, 'Hinweis', fs.note)) FROM aibrewgenius.ai_recipe_fermentation_steps_v2 fs WHERE fs.recipe_id = r.id ORDER BY fs.step_order), '[]'::jsonb)),
        'Abfuell_und_Lagerungsplan', jsonb_build_object('Abfuellung_Typ', r.packaging_type, 'Karbonisierung_Ziel_CO2_g_L', r.packaging_co2_target, 'Keg_Druck_bar', r.packaging_keg_pressure, 'Keg_Karbonisierung_Temp_C', r.packaging_keg_temp, 'Flaschen_Zucker_g_pro_L', r.packaging_bottle_sugar, 'Flaschen_Karbonisierung_Temp_C', r.packaging_bottle_temp, 'Lagerung_Temperatur_C', r.packaging_storage_temp, 'Lagerung_Dauer_Wochen', r.packaging_storage_weeks, 'Reifungshinweis', r.packaging_maturation_note, 'Empfohlenes_Ausschankgas', r.packaging_serving_gas, 'Karbonisierungsdauer_Tage', r.packaging_carb_days)
      )
    )
  ) as recipe_data_reconstructed
FROM aibrewgenius.ai_generated_recipes_v2 r;

GRANT SELECT ON aibrewgenius.ai_generated_recipes_view_v2 TO anon, authenticated, service_role;
