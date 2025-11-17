--
-- PostgreSQL database dump
--

\restrict I8KvlhlARAdaVyRQGjLN8mpES3010sJX7C0g6vXe45OrJxorfflxpHQl0pe0NxH

-- Dumped from database version 15.8
-- Dumped by pg_dump version 18.0

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
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.user_profiles (id, name, avatar_url, kettle_brand, kettle_type, default_batch_liters, fermenter_brand, fermenter_type, controller, controller_user, controller_api_key, yeast_entries, malt_depot) FROM stdin;
self_hosted_profile	Alex				\N			Kein Controller	\N	\N	[]	[]
\.


--
-- Data for Name: brew_kettles; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.brew_kettles (id, user_profile_id, brand, model, is_default, volume_liters, notes, created_at, updated_at) FROM stdin;
04914a2f-0b73-40a5-80e0-37515c190478	self_hosted_profile	Brewtools	B40	t	40	\N	2025-11-17 15:32:03.603097+00	2025-11-17 15:32:03.603097+00
\.


--
-- Data for Name: fermenter_controllers; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.fermenter_controllers (id, user_profile_id, name, is_default, username, api_key, notes, created_at, updated_at) FROM stdin;
5b64757d-38d6-4c03-b24f-47bd39393d45	self_hosted_profile	R.A.P.T Temperature Controller	t	\N	\N	\N	2025-11-17 15:32:40.520411+00	2025-11-17 15:32:40.520411+00
\.


--
-- Data for Name: fermenters; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.fermenters (id, user_profile_id, brand, type, is_default, volume_liters, has_heating, has_cooling, has_dry_hopping_port, notes, created_at, updated_at) FROM stdin;
f6eeafc0-1870-4af2-a3d3-2d5f58f2efe9	self_hosted_profile	Brewtools	F40	t	40	t	t	t	\N	2025-11-17 15:32:21.090852+00	2025-11-17 15:32:21.090852+00
\.


--
-- Data for Name: fining_agents; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.fining_agents (user_profile_id, irish_moss, whirlfloc, gelatin, biersol, polyclar, isinglass, bentonite, egg_whites, activated_carbon, extras, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: malt_depots; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.malt_depots (id, user_profile_id, name, url, notes, created_at, updated_at) FROM stdin;
4968ee3d-4e2a-4111-8bc9-d8fd4e6bb2bb	self_hosted_profile	Brau und Rauch	https://www.brauundrauchshop.ch/	\N	2025-11-17 15:34:31.558272+00	2025-11-17 15:34:31.558272+00
26f4033f-38e1-4612-b2e2-4ea23afa9166	self_hosted_profile	SIOS	https://www.sios.ch/	\N	2025-11-17 15:34:47.859686+00	2025-11-17 15:34:47.859686+00
\.


--
-- Data for Name: packaging_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.packaging_profiles (id, user_profile_id, name, bottle_enabled, bottle_carbonation_temp_c, bottle_storage_temp_c, keg_enabled, keg_carbonation_temp_c, keg_storage_temp_c, keg_volume_l, is_default, created_at, updated_at) FROM stdin;
735a5dab-c206-40d0-9e68-8994464437b3	self_hosted_profile	Schtudi Bräu 1	t	14	14	t	6	14	17	t	2025-11-17 15:33:07.100159+00	2025-11-17 15:33:07.100159+00
7aadf939-8864-400b-96a2-aaddce8587f8	self_hosted_profile	Schtudi Bräu Flaschen	t	14	14	f	\N	\N	\N	f	2025-11-17 15:33:20.693999+00	2025-11-17 15:33:20.693999+00
12691a84-c14e-4add-ac1c-04884ab72519	self_hosted_profile	Studi Bräu Kegs	f	\N	\N	t	6	14	17	f	2025-11-17 15:33:40.702743+00	2025-11-17 15:33:40.702743+00
\.


--
-- Data for Name: water_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.water_profiles (id, user_profile_id, name, is_default, ph, calcium_ppm, magnesium_ppm, sodium_ppm, chloride_ppm, sulfate_ppm, bicarbonate_ppm, created_at, updated_at) FROM stdin;
48214d15-db2b-4ae4-9019-b9bf5ab2239e	self_hosted_profile	Glattfelden	t	7.55	85.8	19.75	13.8	24.7	27.95	17	2025-11-17 15:31:26.129882+00	2025-11-17 15:31:26.129882+00
c3761291-29b3-4f6c-a603-b7f9b92b9ac4	self_hosted_profile	Destiliertes Wasser	f	7.2	0	0	0	0	0	0	2025-11-17 15:31:42.10922+00	2025-11-17 15:31:42.10922+00
\.


--
-- Data for Name: yeast_bank_entries; Type: TABLE DATA; Schema: aibrewgenius; Owner: -
--

COPY aibrewgenius.yeast_bank_entries (id, user_profile_id, brand, strain, style, attenuation_min, attenuation_max, temperature_min, temperature_max, url, notes, created_at, updated_at) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

\unrestrict I8KvlhlARAdaVyRQGjLN8mpES3010sJX7C0g6vXe45OrJxorfflxpHQl0pe0NxH

