--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.user_profiles (id, name, avatar_url, kettle_brand, kettle_type, default_batch_liters, fermenter_brand, fermenter_type, controller, controller_user, controller_api_key, rapt_user_id, rapt_api_key, brewfather_user_id, brewfather_api_key, yeast_entries, malt_depot, brewfather_sync_enabled) VALUES ('self_hosted_profile', 'Alex', 'http://127.0.0.1:54321/storage/v1/object/public/avatars/avatar_1765959633911.jpg', '', '', NULL, '', '', 'Kein Controller', NULL, NULL, 'alex@alexstuder.ch', 'w16MHN1jSVhB', 'UGOVrmU16ieMftasdOX7ECNZNFO2', 'QjxYzTVsV3MMroLtV1bhK0Pcr6LjHvVRp3P1wzc3omNoa8dcF9lGLFY4ewAkI10H', '[]', '[]', true);


--
-- Data for Name: brew_kettles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.brew_kettles (id, user_profile_id, brand, model, is_default, volume_liters, has_condenser_hat, notes, created_at, updated_at) VALUES ('04914a2f-0b73-40a5-80e0-37515c190478', 'self_hosted_profile', 'Brewtools', 'B40', true, 40, true, NULL, '2025-11-17 15:32:03.603097+00', '2025-11-17 15:32:03.603097+00');


--
-- Data for Name: fermenter_controllers; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.fermenter_controllers (id, user_profile_id, name, is_default, username, api_key, notes, created_at, updated_at) VALUES ('5b64757d-38d6-4c03-b24f-47bd39393d45', 'self_hosted_profile', 'R.A.P.T Temperature Controller', true, NULL, NULL, NULL, '2025-11-17 15:32:40.520411+00', '2025-11-17 15:32:40.520411+00');


--
-- Data for Name: fermenters; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.fermenters (id, user_profile_id, brand, type, is_default, volume_liters, has_heating, has_cooling, has_dry_hopping_port, notes, created_at, updated_at) VALUES ('f6eeafc0-1870-4af2-a3d3-2d5f58f2efe9', 'self_hosted_profile', 'Brewtools', 'F40', true, 40, true, true, true, NULL, '2025-11-17 15:32:21.090852+00', '2025-11-17 15:32:21.090852+00');


--
-- Data for Name: fining_agents; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.fining_agents (user_profile_id, irish_moss, whirlfloc, gelatin, biersol, polyclar, isinglass, bentonite, egg_whites, activated_carbon, extras, created_at, updated_at) VALUES ('self_hosted_profile', false, true, false, true, false, false, false, false, false, '[]', '2025-11-17 15:35:00+00', '2025-11-17 15:35:00+00');


--
-- Data for Name: malt_depots; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.malt_depots (id, user_profile_id, name, url, notes, created_at, updated_at) VALUES ('4968ee3d-4e2a-4111-8bc9-d8fd4e6bb2bb', 'self_hosted_profile', 'Brau und Rauch', 'https://www.brauundrauchshop.ch/', NULL, '2025-11-17 15:34:31.558272+00', '2025-11-17 15:34:31.558272+00');
INSERT INTO aibrewgenius.malt_depots (id, user_profile_id, name, url, notes, created_at, updated_at) VALUES ('26f4033f-38e1-4612-b2e2-4ea23afa9166', 'self_hosted_profile', 'SIOS', 'https://www.sios.ch/', NULL, '2025-11-17 15:34:47.859686+00', '2025-11-17 15:34:47.859686+00');


--
-- Data for Name: packaging_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.packaging_profiles (id, user_profile_id, name, target_volume, bottle_enabled, bottle_carbonation_temp_c, bottle_storage_temp_c, keg_enabled, keg_carbonation_temp_c, keg_storage_temp_c, keg_volume_l, has_co2, has_nitro, is_default, created_at, updated_at) VALUES ('735a5dab-c206-40d0-9e68-8994464437b3', 'self_hosted_profile', 'Schtudi Bräu 1', 23, true, 23, 14, true, 14, 14, 17, true, true, true, '2025-11-17 15:33:07.100159+00', '2025-11-17 15:33:07.100159+00');
INSERT INTO aibrewgenius.packaging_profiles (id, user_profile_id, name, target_volume, bottle_enabled, bottle_carbonation_temp_c, bottle_storage_temp_c, keg_enabled, keg_carbonation_temp_c, keg_storage_temp_c, keg_volume_l, has_co2, has_nitro, is_default, created_at, updated_at) VALUES ('7aadf939-8864-400b-96a2-aaddce8587f8', 'self_hosted_profile', 'Schtudi Bräu Flaschen', NULL, true, 14, 14, false, NULL, NULL, NULL, true, false, false, '2025-11-17 15:33:20.693999+00', '2025-11-17 15:33:20.693999+00');
INSERT INTO aibrewgenius.packaging_profiles (id, user_profile_id, name, target_volume, bottle_enabled, bottle_carbonation_temp_c, bottle_storage_temp_c, keg_enabled, keg_carbonation_temp_c, keg_storage_temp_c, keg_volume_l, has_co2, has_nitro, is_default, created_at, updated_at) VALUES ('12691a84-c14e-4add-ac1c-04884ab72519', 'self_hosted_profile', 'Studi Bräu Kegs', NULL, false, NULL, NULL, true, 6, 14, 17, false, true, false, '2025-11-17 15:33:40.702743+00', '2025-11-17 15:33:40.702743+00');


--
-- Data for Name: water_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.water_profiles (id, user_profile_id, name, is_default, ph, calcium_ppm, magnesium_ppm, sodium_ppm, chloride_ppm, sulfate_ppm, bicarbonate_ppm, created_at, updated_at) VALUES ('48214d15-db2b-4ae4-9019-b9bf5ab2239e', 'self_hosted_profile', 'Glattfelden', true, 7.55, 85.8, 19.75, 13.8, 24.7, 27.95, 17, '2025-11-17 15:31:26.129882+00', '2025-11-17 15:31:26.129882+00');
INSERT INTO aibrewgenius.water_profiles (id, user_profile_id, name, is_default, ph, calcium_ppm, magnesium_ppm, sodium_ppm, chloride_ppm, sulfate_ppm, bicarbonate_ppm, created_at, updated_at) VALUES ('c3761291-29b3-4f6c-a603-b7f9b92b9ac4', 'self_hosted_profile', 'Destiliertes Wasser', false, 7.2, 0, 0, 0, 0, 0, 0, '2025-11-17 15:31:42.10922+00', '2025-11-17 15:31:42.10922+00');


--
-- Data for Name: yeast_bank_entries; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

INSERT INTO aibrewgenius.yeast_bank_entries (id, user_profile_id, brand, strain, style, attenuation_min, attenuation_max, temperature_min, temperature_max, url, notes, created_at, updated_at, brewfather_id, product_id, form, inventory, unit) VALUES ('0aa08817-d2b1-4219-8ff1-d113ad315ee5', 'self_hosted_profile', 'WYEAST LABS', '1084 Irish Ale', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-12-16 23:15:32.481+00', '2025-12-16 23:15:32.481+00', NULL, NULL, NULL, NULL, NULL);
INSERT INTO aibrewgenius.yeast_bank_entries (id, user_profile_id, brand, strain, style, attenuation_min, attenuation_max, temperature_min, temperature_max, url, notes, created_at, updated_at, brewfather_id, product_id, form, inventory, unit) VALUES ('a975c716-d891-460f-8f41-18bb7489e748', 'self_hosted_profile', 'Wyeast Labs', 'Weihenstephan Weizen', 'Wheat', 77, 77, 17.8, 23.9, NULL, '', '2025-12-16 22:48:29.698244+00', '2025-12-17 08:20:16.850169+00', 'default-73f938', '3068', 'Liquid', 1, 'pkg');
INSERT INTO aibrewgenius.yeast_bank_entries (id, user_profile_id, brand, strain, style, attenuation_min, attenuation_max, temperature_min, temperature_max, url, notes, created_at, updated_at, brewfather_id, product_id, form, inventory, unit) VALUES ('47eb502c-1019-4d1e-822f-406c8c8143f4', 'self_hosted_profile', 'Wyeast Labs', 'Bavarian Lager', 'Lager', 77, 77, 7.8, 14.4, 'https://wyeastlab.com/product/bavarian-lager/', '', '2025-12-16 22:48:29.708472+00', '2025-12-17 08:20:16.882129+00', 'default-77d700', '2206', 'Liquid', 1, 'pkg');


--
-- PostgreSQL database dump complete
--


