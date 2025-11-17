-- Seed data for the aibrewgenius schema.
-- Run this after 001_init_schema.sql to restore local defaults.

INSERT INTO aibrewgenius.user_profiles (
  id,
  name,
  avatar_url,
  kettle_brand,
  kettle_type,
  default_batch_liters,
  fermenter_brand,
  fermenter_type,
  controller,
  controller_user,
  controller_api_key,
  yeast_entries,
  malt_depot
) VALUES (
  'self_hosted_profile',
  'Alex',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  'Kein Controller',
  NULL,
  NULL,
  '[]',
  '[]'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO aibrewgenius.brew_kettles (
  id,
  user_profile_id,
  brand,
  model,
  is_default,
  volume_liters,
  notes,
  created_at,
  updated_at
) VALUES (
  '04914a2f-0b73-40a5-80e0-37515c190478',
  'self_hosted_profile',
  'Brewtools',
  'B40',
  TRUE,
  40,
  NULL,
  '2025-11-17 15:32:03.603097+00',
  '2025-11-17 15:32:03.603097+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO aibrewgenius.fermenter_controllers (
  id,
  user_profile_id,
  name,
  is_default,
  username,
  api_key,
  notes,
  created_at,
  updated_at
) VALUES (
  '5b64757d-38d6-4c03-b24f-47bd39393d45',
  'self_hosted_profile',
  'R.A.P.T Temperature Controller',
  TRUE,
  NULL,
  NULL,
  NULL,
  '2025-11-17 15:32:40.520411+00',
  '2025-11-17 15:32:40.520411+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO aibrewgenius.fermenters (
  id,
  user_profile_id,
  brand,
  type,
  is_default,
  volume_liters,
  has_heating,
  has_cooling,
  has_dry_hopping_port,
  notes,
  created_at,
  updated_at
) VALUES (
  'f6eeafc0-1870-4af2-a3d3-2d5f58f2efe9',
  'self_hosted_profile',
  'Brewtools',
  'F40',
  TRUE,
  40,
  TRUE,
  TRUE,
  TRUE,
  NULL,
  '2025-11-17 15:32:21.090852+00',
  '2025-11-17 15:32:21.090852+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO aibrewgenius.malt_depots (
  id,
  user_profile_id,
  name,
  url,
  notes,
  created_at,
  updated_at
) VALUES
  (
    '4968ee3d-4e2a-4111-8bc9-d8fd4e6bb2bb',
    'self_hosted_profile',
    'Brau und Rauch',
    'https://www.brauundrauchshop.ch/',
    NULL,
    '2025-11-17 15:34:31.558272+00',
    '2025-11-17 15:34:31.558272+00'
  ),
  (
    '26f4033f-38e1-4612-b2e2-4ea23afa9166',
    'self_hosted_profile',
    'SIOS',
    'https://www.sios.ch/',
    NULL,
    '2025-11-17 15:34:47.859686+00',
    '2025-11-17 15:34:47.859686+00'
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO aibrewgenius.packaging_profiles (
  id,
  user_profile_id,
  name,
  bottle_enabled,
  bottle_carbonation_temp_c,
  bottle_storage_temp_c,
  keg_enabled,
  keg_carbonation_temp_c,
  keg_storage_temp_c,
  keg_volume_l,
  is_default,
  created_at,
  updated_at
) VALUES
  (
    '735a5dab-c206-40d0-9e68-8994464437b3',
    'self_hosted_profile',
    'Schtudi Bräu 1',
    TRUE,
    14,
    14,
    TRUE,
    6,
    14,
    17,
    TRUE,
    '2025-11-17 15:33:07.100159+00',
    '2025-11-17 15:33:07.100159+00'
  ),
  (
    '7aadf939-8864-400b-96a2-aaddce8587f8',
    'self_hosted_profile',
    'Schtudi Bräu Flaschen',
    TRUE,
    14,
    14,
    FALSE,
    NULL,
    NULL,
    NULL,
    FALSE,
    '2025-11-17 15:33:20.693999+00',
    '2025-11-17 15:33:20.693999+00'
  ),
  (
    '12691a84-c14e-4add-ac1c-04884ab72519',
    'self_hosted_profile',
    'Studi Bräu Kegs',
    FALSE,
    NULL,
    NULL,
    TRUE,
    6,
    14,
    17,
    FALSE,
    '2025-11-17 15:33:40.702743+00',
    '2025-11-17 15:33:40.702743+00'
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO aibrewgenius.water_profiles (
  id,
  user_profile_id,
  name,
  is_default,
  ph,
  calcium_ppm,
  magnesium_ppm,
  sodium_ppm,
  chloride_ppm,
  sulfate_ppm,
  bicarbonate_ppm,
  created_at,
  updated_at
) VALUES
  (
    '48214d15-db2b-4ae4-9019-b9bf5ab2239e',
    'self_hosted_profile',
    'Glattfelden',
    TRUE,
    7.55,
    85.8,
    19.75,
    13.8,
    24.7,
    27.95,
    17,
    '2025-11-17 15:31:26.129882+00',
    '2025-11-17 15:31:26.129882+00'
  ),
  (
    'c3761291-29b3-4f6c-a603-b7f9b92b9ac4',
    'self_hosted_profile',
    'Destiliertes Wasser',
    FALSE,
    7.2,
    0,
    0,
    0,
    0,
    0,
    0,
    '2025-11-17 15:31:42.10922+00',
    '2025-11-17 15:31:42.10922+00'
  )
ON CONFLICT (id) DO NOTHING;
