--
-- PostgreSQL database dump
--

\restrict CzqWooNn4vC2XbRJEwOfeC5C2dObIxdV9r11hHtzwf63CxBm1GSwq0D7y69aJ7q

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
-- Data for Name: tenants; Type: TABLE DATA; Schema: _realtime; Owner: supabase_admin
--

COPY _realtime.tenants (id, name, external_id, jwt_secret, max_concurrent_users, inserted_at, updated_at, max_events_per_second, postgres_cdc_default, max_bytes_per_second, max_channels_per_client, max_joins_per_second, suspend, jwt_jwks, notify_private_alpha, private_only, migrations_ran, broadcast_adapter, max_presence_events_per_second, max_payload_size_in_kb) FROM stdin;
9943cbe6-4a48-46c5-a015-256fd8e13492	realtime-dev	realtime-dev	iNjicxc4+llvc9wovDvqymwfnj9teWMlyOIbJ8Fh6j2WNU8CIJ2ZgjR6MUIKqSmeDmvpsKLsZ9jgXJmQPpwL8w==	200	2025-11-16 06:38:30	2025-11-16 06:38:30	100	postgres_cdc_rls	100000	100	100	f	{"keys": [{"k": "c3VwZXItc2VjcmV0LWp3dC10b2tlbi13aXRoLWF0LWxlYXN0LTMyLWNoYXJhY3RlcnMtbG9uZw", "kty": "oct"}]}	f	f	65	gen_rpc	1000	3000
\.


--
-- Data for Name: extensions; Type: TABLE DATA; Schema: _realtime; Owner: supabase_admin
--

COPY _realtime.extensions (id, type, settings, tenant_external_id, inserted_at, updated_at) FROM stdin;
eb51dff4-ae60-4db3-ab8b-79b631818c49	postgres_cdc_rls	{"region": "us-east-1", "db_host": "+5JkR7EPoJsAtjz+cdk/ZGMDh4Ck8PWqtZx+VnDSocE=", "db_name": "sWBpZNdjggEPTQVlI52Zfw==", "db_port": "+enMDFi1J/3IrrquHHwUmA==", "db_user": "uxbEq/zz8DXVD53TOI1zmw==", "slot_name": "supabase_realtime_replication_slot", "db_password": "sWBpZNdjggEPTQVlI52Zfw==", "publication": "supabase_realtime", "ssl_enforced": false, "poll_interval_ms": 100, "poll_max_changes": 100, "poll_max_record_bytes": 1048576}	realtime-dev	2025-11-16 06:38:30	2025-11-16 06:38:30
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: _realtime; Owner: supabase_admin
--

COPY _realtime.schema_migrations (version, inserted_at) FROM stdin;
20210706140551	2025-11-12 18:58:10
20220329161857	2025-11-12 18:58:10
20220410212326	2025-11-12 18:58:10
20220506102948	2025-11-12 18:58:10
20220527210857	2025-11-12 18:58:10
20220815211129	2025-11-12 18:58:10
20220815215024	2025-11-12 18:58:10
20220818141501	2025-11-12 18:58:10
20221018173709	2025-11-12 18:58:10
20221102172703	2025-11-12 18:58:10
20221223010058	2025-11-12 18:58:10
20230110180046	2025-11-12 18:58:10
20230810220907	2025-11-12 18:58:10
20230810220924	2025-11-12 18:58:10
20231024094642	2025-11-12 18:58:10
20240306114423	2025-11-12 18:58:10
20240418082835	2025-11-12 18:58:10
20240625211759	2025-11-12 18:58:10
20240704172020	2025-11-12 18:58:10
20240902173232	2025-11-12 18:58:10
20241106103258	2025-11-12 18:58:10
20250424203323	2025-11-12 18:58:10
20250613072131	2025-11-12 18:58:10
20250711044927	2025-11-12 18:58:10
20250811121559	2025-11-12 18:58:10
20250926223044	2025-11-12 18:58:10
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.user_profiles (id, name, avatar_url, kettle_brand, kettle_type, default_batch_liters, fermenter_brand, fermenter_type, controller, controller_user, controller_api_key, yeast_entries, malt_depot) FROM stdin;
self_hosted_profile	Alex				\N			Kein Controller	\N	\N	[]	[]
\.


--
-- Data for Name: brew_kettles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.brew_kettles (id, user_profile_id, brand, model, is_default, volume_liters, notes, created_at, updated_at) FROM stdin;
04914a2f-0b73-40a5-80e0-37515c190478	self_hosted_profile	Brewtools	B40	t	40	\N	2025-11-17 15:32:03.603097+00	2025-11-17 15:32:03.603097+00
\.


--
-- Data for Name: fermenter_controllers; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.fermenter_controllers (id, user_profile_id, name, is_default, username, api_key, notes, created_at, updated_at) FROM stdin;
5b64757d-38d6-4c03-b24f-47bd39393d45	self_hosted_profile	R.A.P.T Temperature Controller	t	\N	\N	\N	2025-11-17 15:32:40.520411+00	2025-11-17 15:32:40.520411+00
\.


--
-- Data for Name: fermenters; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.fermenters (id, user_profile_id, brand, type, is_default, volume_liters, has_heating, has_cooling, has_dry_hopping_port, notes, created_at, updated_at) FROM stdin;
f6eeafc0-1870-4af2-a3d3-2d5f58f2efe9	self_hosted_profile	Brewtools	F40	t	40	t	t	t	\N	2025-11-17 15:32:21.090852+00	2025-11-17 15:32:21.090852+00
\.


--
-- Data for Name: fining_agents; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.fining_agents (user_profile_id, irish_moss, whirlfloc, gelatin, biersol, polyclar, isinglass, bentonite, egg_whites, activated_carbon, extras, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: malt_depots; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.malt_depots (id, user_profile_id, name, url, notes, created_at, updated_at) FROM stdin;
4968ee3d-4e2a-4111-8bc9-d8fd4e6bb2bb	self_hosted_profile	Brau und Rauch	https://www.brauundrauchshop.ch/	\N	2025-11-17 15:34:31.558272+00	2025-11-17 15:34:31.558272+00
26f4033f-38e1-4612-b2e2-4ea23afa9166	self_hosted_profile	SIOS	https://www.sios.ch/	\N	2025-11-17 15:34:47.859686+00	2025-11-17 15:34:47.859686+00
\.


--
-- Data for Name: packaging_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.packaging_profiles (id, user_profile_id, name, bottle_enabled, bottle_carbonation_temp_c, bottle_storage_temp_c, keg_enabled, keg_carbonation_temp_c, keg_storage_temp_c, keg_volume_l, is_default, created_at, updated_at) FROM stdin;
735a5dab-c206-40d0-9e68-8994464437b3	self_hosted_profile	Schtudi Bräu 1	t	14	14	t	6	14	17	t	2025-11-17 15:33:07.100159+00	2025-11-17 15:33:07.100159+00
7aadf939-8864-400b-96a2-aaddce8587f8	self_hosted_profile	Schtudi Bräu Flaschen	t	14	14	f	\N	\N	\N	f	2025-11-17 15:33:20.693999+00	2025-11-17 15:33:20.693999+00
12691a84-c14e-4add-ac1c-04884ab72519	self_hosted_profile	Studi Bräu Kegs	f	\N	\N	t	6	14	17	f	2025-11-17 15:33:40.702743+00	2025-11-17 15:33:40.702743+00
\.


--
-- Data for Name: water_profiles; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.water_profiles (id, user_profile_id, name, is_default, ph, calcium_ppm, magnesium_ppm, sodium_ppm, chloride_ppm, sulfate_ppm, bicarbonate_ppm, created_at, updated_at) FROM stdin;
48214d15-db2b-4ae4-9019-b9bf5ab2239e	self_hosted_profile	Glattfelden	t	7.55	85.8	19.75	13.8	24.7	27.95	17	2025-11-17 15:31:26.129882+00	2025-11-17 15:31:26.129882+00
c3761291-29b3-4f6c-a603-b7f9b92b9ac4	self_hosted_profile	Destiliertes Wasser	f	7.2	0	0	0	0	0	0	2025-11-17 15:31:42.10922+00	2025-11-17 15:31:42.10922+00
\.


--
-- Data for Name: yeast_bank_entries; Type: TABLE DATA; Schema: aibrewgenius; Owner: supabase_admin
--

COPY aibrewgenius.yeast_bank_entries (id, user_profile_id, brand, strain, style, attenuation_min, attenuation_max, temperature_min, temperature_max, url, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
00000000-0000-0000-0000-000000000000	ba088797-da85-42c0-ab74-c6435cb48fa3	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"alex@alexstuder.ch","user_id":"5e009cf6-42cd-47ce-bc59-78f1ca81c27e","user_phone":""}}	2025-11-17 16:15:23.951485+00	
00000000-0000-0000-0000-000000000000	eb2b0e63-8d2e-4c91-91b8-7075cf4cf220	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"alex@alexstuder.ch","user_id":"5e009cf6-42cd-47ce-bc59-78f1ca81c27e","user_phone":""}}	2025-11-17 16:16:26.821646+00	
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: service; Type: TABLE DATA; Schema: content; Owner: postgres
--

COPY content.service (id, name, created_at, updated_at, deleted_at) FROM stdin;
c22c86c3-530f-4933-8a63-39bfaa433256	AUTH	2025-11-12 18:58:13.827594+00	2025-11-12 18:58:13.827594+00	\N
85038001-0707-4c84-9b24-db8f630d8c15	REALTIME	2025-11-12 18:58:13.827594+00	2025-11-12 18:58:13.827594+00	\N
5b4a3173-98f9-4954-ba16-10bbacaa0122	STORAGE	2025-11-12 18:58:13.827594+00	2025-11-12 18:58:13.827594+00	\N
\.


--
-- Data for Name: error; Type: TABLE DATA; Schema: content; Owner: postgres
--

COPY content.error (code, service, http_status_code, message, created_at, updated_at, deleted_at, metadata, id) FROM stdin;
test_code	c22c86c3-530f-4933-8a63-39bfaa433256	500	This is a test error message	2025-11-12 18:58:13.854753+00	2025-11-12 18:58:13.854753+00	\N	\N	af5c38f7-81eb-490a-b966-5952dd1e68cf
test_code2	c22c86c3-530f-4933-8a63-39bfaa433256	429	Too many requests	2025-11-12 18:58:13.854753+00	2025-11-12 18:58:13.854753+00	\N	\N	86e3f6ba-1108-46c2-99d8-25d44190ed75
test_code3	85038001-0707-4c84-9b24-db8f630d8c15	500	A realtime error message	2025-11-12 18:58:13.854753+00	2025-11-12 18:58:13.854753+00	\N	\N	fd4fd375-37fd-4c1c-a596-5e0a609ee619
\.


--
-- Data for Name: feedback; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.feedback (id, date_created, vote, page, metadata) FROM stdin;
\.


--
-- Data for Name: last_changed; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.last_changed (id, checksum, parent_page, heading, last_updated, last_checked) FROM stdin;
\.


--
-- Data for Name: launch_weeks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.launch_weeks (id, created_at, start_date, end_date) FROM stdin;
lw12	2025-11-12 18:58:13.805351+00	\N	\N
lw14	2025-11-12 18:58:13.854753+00	\N	\N
\.


--
-- Data for Name: meetups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meetups (id, created_at, launch_week, title, country, start_at, link, display_info, is_live, is_published, timezone, city) FROM stdin;
361a841b-2d6a-40f3-a136-19652c505f4a	2025-11-12 18:58:13.854753+00	lw12	New York	USA	2025-11-12 18:58:13.854753+00	\N	\N	f	t	\N	\N
31e88f20-fd85-4a7e-ba5a-732f1be50faf	2025-11-12 18:58:13.854753+00	lw12	London	UK	2025-11-12 18:58:13.854753+00	\N	\N	f	t	\N	\N
425edd1c-3697-4449-bebb-50337e1364b9	2025-11-12 18:58:13.854753+00	lw12	Singapore	Singapore	2025-11-12 18:58:13.854753+00	\N	\N	f	t	\N	\N
\.


--
-- Data for Name: page; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.page (id, path, checksum, meta, type, source, version, last_refresh, content) FROM stdin;
\.


--
-- Data for Name: page_nimbus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.page_nimbus (id, path, checksum, meta, type, source, content, version, last_refresh) FROM stdin;
\.


--
-- Data for Name: page_section; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.page_section (id, page_id, content, token_count, embedding, slug, heading, rag_ignore) FROM stdin;
\.


--
-- Data for Name: page_section_nimbus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.page_section_nimbus (id, page_id, content, token_count, embedding, slug, heading, rag_ignore) FROM stdin;
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tickets (id, created_at, launch_week, user_id, email, name, username, referred_by, shared_on_twitter, shared_on_linkedin, game_won_at, ticket_number, metadata, role, company, location) FROM stdin;
\.


--
-- Data for Name: troubleshooting_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.troubleshooting_entries (id, title, topics, keywords, api, errors, github_url, date_created, date_updated, github_id, checksum) FROM stdin;
\.


--
-- Data for Name: validation_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.validation_history (id, tag, created_at) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_13; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_13 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_14; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_14 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_15; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_15 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_16; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_16 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_17; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_17 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_18; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_18 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_19; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_19 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2025-11-12 18:58:11
20211116045059	2025-11-12 18:58:11
20211116050929	2025-11-12 18:58:11
20211116051442	2025-11-12 18:58:11
20211116212300	2025-11-12 18:58:11
20211116213355	2025-11-12 18:58:11
20211116213934	2025-11-12 18:58:11
20211116214523	2025-11-12 18:58:11
20211122062447	2025-11-12 18:58:11
20211124070109	2025-11-12 18:58:11
20211202204204	2025-11-12 18:58:11
20211202204605	2025-11-12 18:58:11
20211210212804	2025-11-12 18:58:11
20211228014915	2025-11-12 18:58:11
20220107221237	2025-11-12 18:58:11
20220228202821	2025-11-12 18:58:11
20220312004840	2025-11-12 18:58:11
20220603231003	2025-11-12 18:58:11
20220603232444	2025-11-12 18:58:11
20220615214548	2025-11-12 18:58:11
20220712093339	2025-11-12 18:58:11
20220908172859	2025-11-12 18:58:11
20220916233421	2025-11-12 18:58:11
20230119133233	2025-11-12 18:58:11
20230128025114	2025-11-12 18:58:11
20230128025212	2025-11-12 18:58:11
20230227211149	2025-11-12 18:58:11
20230228184745	2025-11-12 18:58:11
20230308225145	2025-11-12 18:58:11
20230328144023	2025-11-12 18:58:11
20231018144023	2025-11-12 18:58:11
20231204144023	2025-11-12 18:58:11
20231204144024	2025-11-12 18:58:11
20231204144025	2025-11-12 18:58:11
20240108234812	2025-11-12 18:58:11
20240109165339	2025-11-12 18:58:11
20240227174441	2025-11-12 18:58:11
20240311171622	2025-11-12 18:58:11
20240321100241	2025-11-12 18:58:11
20240401105812	2025-11-12 18:58:11
20240418121054	2025-11-12 18:58:11
20240523004032	2025-11-12 18:58:11
20240618124746	2025-11-12 18:58:11
20240801235015	2025-11-12 18:58:11
20240805133720	2025-11-12 18:58:11
20240827160934	2025-11-12 18:58:11
20240919163303	2025-11-12 18:58:11
20240919163305	2025-11-12 18:58:11
20241019105805	2025-11-12 18:58:11
20241030150047	2025-11-12 18:58:11
20241108114728	2025-11-12 18:58:11
20241121104152	2025-11-12 18:58:11
20241130184212	2025-11-12 18:58:11
20241220035512	2025-11-12 18:58:11
20241220123912	2025-11-12 18:58:11
20241224161212	2025-11-12 18:58:11
20250107150512	2025-11-12 18:58:11
20250110162412	2025-11-12 18:58:11
20250123174212	2025-11-12 18:58:11
20250128220012	2025-11-12 18:58:11
20250506224012	2025-11-12 18:58:11
20250523164012	2025-11-12 18:58:11
20250714121412	2025-11-12 18:58:11
20250905041441	2025-11-12 18:58:11
20251103001201	2025-11-12 18:58:11
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
fonts	fonts	\N	2025-11-12 18:58:25.335714+00	2025-11-12 18:58:25.335714+00	t	f	52428800	\N	\N	STANDARD
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets_analytics (id, type, format, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets_vectors (id, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: iceberg_namespaces; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.iceberg_namespaces (id, bucket_id, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: iceberg_tables; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.iceberg_tables (id, namespace_id, bucket_id, name, location, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2025-11-12 18:58:13.243713
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2025-11-12 18:58:13.245303
2	storage-schema	5c7968fd083fcea04050c1b7f6253c9771b99011	2025-11-12 18:58:13.24594
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2025-11-12 18:58:13.249366
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2025-11-12 18:58:13.252736
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2025-11-12 18:58:13.253161
6	change-column-name-in-get-size	f93f62afdf6613ee5e7e815b30d02dc990201044	2025-11-12 18:58:13.25393
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2025-11-12 18:58:13.25462
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2025-11-12 18:58:13.255032
9	fix-search-function	3a0af29f42e35a4d101c259ed955b67e1bee6825	2025-11-12 18:58:13.255409
10	search-files-search-function	68dc14822daad0ffac3746a502234f486182ef6e	2025-11-12 18:58:13.256033
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2025-11-12 18:58:13.256688
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2025-11-12 18:58:13.257428
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2025-11-12 18:58:13.257828
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2025-11-12 18:58:13.258247
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2025-11-12 18:58:13.264912
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2025-11-12 18:58:13.265433
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2025-11-12 18:58:13.265776
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2025-11-12 18:58:13.266253
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2025-11-12 18:58:13.266935
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2025-11-12 18:58:13.267374
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2025-11-12 18:58:13.268429
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2025-11-12 18:58:13.272116
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2025-11-12 18:58:13.274872
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2025-11-12 18:58:13.275564
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2025-11-12 18:58:13.276146
26	objects-prefixes	ef3f7871121cdc47a65308e6702519e853422ae2	2025-11-12 18:58:13.276605
27	search-v2	33b8f2a7ae53105f028e13e9fcda9dc4f356b4a2	2025-11-12 18:58:13.280042
28	object-bucket-name-sorting	ba85ec41b62c6a30a3f136788227ee47f311c436	2025-11-12 18:58:13.281411
29	create-prefixes	a7b1a22c0dc3ab630e3055bfec7ce7d2045c5b7b	2025-11-12 18:58:13.282192
30	update-object-levels	6c6f6cc9430d570f26284a24cf7b210599032db7	2025-11-12 18:58:13.282745
31	objects-level-index	33f1fef7ec7fea08bb892222f4f0f5d79bab5eb8	2025-11-12 18:58:13.283642
32	backward-compatible-index-on-objects	2d51eeb437a96868b36fcdfb1ddefdf13bef1647	2025-11-12 18:58:13.284656
33	backward-compatible-index-on-prefixes	fe473390e1b8c407434c0e470655945b110507bf	2025-11-12 18:58:13.285597
34	optimize-search-function-v1	82b0e469a00e8ebce495e29bfa70a0797f7ebd2c	2025-11-12 18:58:13.285775
35	add-insert-trigger-prefixes	63bb9fd05deb3dc5e9fa66c83e82b152f0caf589	2025-11-12 18:58:13.286873
36	optimise-existing-functions	81cf92eb0c36612865a18016a38496c530443899	2025-11-12 18:58:13.287187
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2025-11-12 18:58:13.288822
38	iceberg-catalog-flag-on-buckets	19a8bd89d5dfa69af7f222a46c726b7c41e462c5	2025-11-12 18:58:13.289361
39	add-search-v2-sort-support	39cf7d1e6bf515f4b02e41237aba845a7b492853	2025-11-12 18:58:13.294384
40	fix-prefix-race-conditions-optimized	fd02297e1c67df25a9fc110bf8c8a9af7fb06d1f	2025-11-12 18:58:13.295171
41	add-object-level-update-trigger	44c22478bf01744b2129efc480cd2edc9a7d60e9	2025-11-12 18:58:13.297067
42	rollback-prefix-triggers	f2ab4f526ab7f979541082992593938c05ee4b47	2025-11-12 18:58:13.297846
43	fix-object-level	ab837ad8f1c7d00cc0b7310e989a23388ff29fc6	2025-11-12 18:58:13.298574
44	vector-bucket-type	99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3	2025-11-12 18:58:13.299014
45	vector-buckets	049e27196d77a7cb76497a85afae669d8b230953	2025-11-12 18:58:13.299468
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata, level) FROM stdin;
ee13bc38-d3de-4511-9cad-989b40c6787d	fonts	SourceCodePro-Regular.ttf	\N	2025-11-12 18:58:25.357327+00	2025-11-12 18:58:25.357327+00	2025-11-12 18:58:25.357327+00	{"eTag": "\\"925930bbc3df5c91c1dbcbd9ea80b7f9\\"", "size": 190248, "mimetype": "font/ttf", "cacheControl": "max-age=3600", "lastModified": "2025-11-12T18:58:25.352Z", "contentLength": 190248, "httpStatusCode": 200}	1084731f-1efa-46a3-aefe-df425af68079	\N	{}	1
9df2bfa9-8f66-470b-8f3f-5e57918d4cd7	fonts	CircularStd-Book.otf	\N	2025-11-12 18:58:25.359666+00	2025-11-12 18:58:25.359666+00	2025-11-12 18:58:25.359666+00	{"eTag": "\\"6365c40aa59d462f1cc52ccce9635cb4\\"", "size": 68940, "mimetype": "font/otf", "cacheControl": "max-age=3600", "lastModified": "2025-11-12T18:58:25.355Z", "contentLength": 68940, "httpStatusCode": 200}	5d6b9815-3b8f-4d49-9b99-af3939994d23	\N	{}	1
\.


--
-- Data for Name: prefixes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.prefixes (bucket_id, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.vector_indexes (id, name, bucket_id, data_type, dimension, distance_metric, metadata_configuration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: hooks; Type: TABLE DATA; Schema: supabase_functions; Owner: supabase_functions_admin
--

COPY supabase_functions.hooks (id, hook_table_id, hook_name, created_at, request_id) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: supabase_functions; Owner: supabase_functions_admin
--

COPY supabase_functions.migrations (version, inserted_at) FROM stdin;
initial	2025-11-12 18:58:00.943009+00
20210809183423_update_grants	2025-11-12 18:58:00.943009+00
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: supabase_migrations; Owner: postgres
--

COPY supabase_migrations.schema_migrations (version, statements, name) FROM stdin;
20230126220613	{"create extension if not exists vector with schema public","create table \\"public\\".\\"page\\" (\n  id bigserial primary key,\n  path text not null unique,\n  checksum text,\n  meta jsonb\n)","create table \\"public\\".\\"page_section\\" (\n  id bigserial primary key,\n  page_id bigint not null references public.page on delete cascade,\n  content text,\n  token_count int,\n  embedding vector(1536)\n)"}	doc_embeddings
20230128004504	{"create or replace function match_page_sections(embedding vector(1536), match_threshold float, match_count int, min_content_length int)\nreturns table (path text, content text, similarity float)\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select\n    page.path,\n    page_section.content,\n    (page_section.embedding <#> embedding) * -1 as similarity\n  from page_section\n  join page\n    on page_section.page_id = page.id\n\n  -- We only care about sections that have a useful amount of content\n  where length(page_section.content) >= min_content_length\n\n  -- The dot product is negative because of a Postgres limitation, so we negate it\n  and (page_section.embedding <#> embedding) * -1 > match_threshold\n\n  -- OpenAI embeddings are normalized to length 1, so\n  -- cosine similarity and dot product will produce the same results.\n  -- Using dot product which can be computed slightly faster.\n  --\n  -- For the different syntaxes, see https://github.com/pgvector/pgvector\n  order by page_section.embedding <#> embedding\n  \n  limit match_count;\nend;\n$$"}	embedding_similarity_search
20230216195821	{"alter table \\"public\\".\\"page\\"\nadd parent_page_id bigint references public.page"}	page_hierarchy
20230216232739	{"alter table \\"public\\".\\"page_section\\"\nadd column slug text,\nadd column heading text"}	page_section_heading_slug
20230217032716	{"drop function match_page_sections","create or replace function match_page_sections(embedding vector(1536), match_threshold float, match_count int, min_content_length int)\nreturns table (id bigint, page_id bigint, slug text, heading text, content text, similarity float)\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select\n    page_section.id,\n    page_section.page_id,\n    page_section.slug,\n    page_section.heading,\n    page_section.content,\n    (page_section.embedding <#> embedding) * -1 as similarity\n  from page_section\n\n  -- We only care about sections that have a useful amount of content\n  where length(page_section.content) >= min_content_length\n\n  -- The dot product is negative because of a Postgres limitation, so we negate it\n  and (page_section.embedding <#> embedding) * -1 > match_threshold\n\n  -- OpenAI embeddings are normalized to length 1, so\n  -- cosine similarity and dot product will produce the same results.\n  -- Using dot product which can be computed slightly faster.\n  --\n  -- For the different syntaxes, see https://github.com/pgvector/pgvector\n  order by page_section.embedding <#> embedding\n  \n  limit match_count;\nend;\n$$","create or replace function get_page_parents(page_id bigint)\nreturns table (id bigint, parent_page_id bigint, path text, meta jsonb)\nlanguage sql\nas $$\n  with recursive chain as (\n    select *\n    from page \n    where id = page_id\n\n    union all\n\n    select child.*\n      from page as child\n      join chain on chain.parent_page_id = child.id \n  )\n  select id, parent_page_id, path, meta\n  from chain;\n$$"}	page_hierarchy_function
20230228205709	{"alter table \\"public\\".\\"page\\"\nadd column type text,\nadd column source text"}	page_source
20230403222943	{"-- Return a setof page_section so that we can use PostgREST resource embeddings (joins with other tables)\ncreate or replace function match_page_sections_v2(embedding vector(1536), match_threshold float, min_content_length int)\nreturns setof page_section\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select *\n  from page_section\n\n  -- We only care about sections that have a useful amount of content\n  where length(page_section.content) >= min_content_length\n\n  -- The dot product is negative because of a Postgres limitation, so we negate it\n  and (page_section.embedding <#> embedding) * -1 > match_threshold\n\n  -- OpenAI embeddings are normalized to length 1, so\n  -- cosine similarity and dot product will produce the same results.\n  -- Using dot product which can be computed slightly faster.\n  --\n  -- For the different syntaxes, see https://github.com/pgvector/pgvector\n  order by page_section.embedding <#> embedding;\nend;\n$$"}	reusable_match_function
20230421193603	{"alter table \\"public\\".\\"page\\"\nadd \\"version\\" uuid,\nadd \\"last_refresh\\" timestamptz"}	page_version
20231115053211	{"alter table \\"public\\".\\"page\\" enable row level security","alter table \\"public\\".\\"page_section\\" enable row level security","create policy \\"Enable read access for anon and authenticated\\"\non \\"public\\".\\"page\\"\nas permissive\nfor select\nto anon, authenticated\nusing (true)","create policy \\"Enable read access for anon and authenticated\\"\non \\"public\\".\\"page_section\\"\nas permissive\nfor select\nto anon, authenticated\nusing (true)"}	remote_schema
20231121164837	{"alter table page_section\nadd column fts_tokens tsvector generated always as (to_tsvector('english', content)) stored","create index fts_search_index on page_section using gin(fts_tokens)","create or replace function docs_search_fts(query text)\nreturns table (\n\tid int8,\n\tpath text,\n\ttype text,\n\ttitle text,\n\tsubtitle text,\n\tdescription text,\n\theadings text[],\n\tslugs text[]\n)\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n\treturn query\n\twith match as (\n\t\tselect *\n\t\tfrom page_section\n\t\twhere fts_tokens @@ websearch_to_tsquery(query)\n\t\tlimit 10\n\t)\n\tselect\n\t\tpage.id,\n\t\tpage.path,\n\t\tpage.type,\n\t\tpage.meta ->> 'title' as title,\n\t\tpage.meta ->> 'subtitle' as title,\n\t\tpage.meta ->> 'description' as description,\n\t\tarray_agg(match.heading) as headings,\n\t\tarray_agg(match.slug) as slugs\n\tfrom page\n\tjoin match on match.page_id = page.id\n\tgroup by page.id;\nend;\n$$","create or replace function docs_search_embeddings(\n\tembedding vector(1536),\n\tmatch_threshold float\n)\nreturns table (\n\tid int8,\n\tpath text,\n\ttype text,\n\ttitle text,\n\tsubtitle text,\n\tdescription text,\n\theadings text[],\n\tslugs text[]\n)\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n\treturn query\n\twith match as(\n\t\tselect *\n\t\tfrom page_section\n\t\t-- The dot product is negative because of a Postgres limitation, so we negate it\n\t\twhere (page_section.embedding <#> embedding) * -1 > match_threshold\t\n\t\t-- OpenAI embeddings are normalized to length 1, so\n\t\t-- cosine similarity and dot product will produce the same results.\n\t\t-- Using dot product which can be computed slightly faster.\n\t\t--\n\t\t-- For the different syntaxes, see https://github.com/pgvector/pgvector\n\t\torder by page_section.embedding <#> embedding\n\t\tlimit 10\n\t)\n\tselect\n\t\tpage.id,\n\t\tpage.path,\n\t\tpage.type,\n\t\tpage.meta ->> 'title' as title,\n\t\tpage.meta ->> 'subtitle' as title,\n\t\tpage.meta ->> 'description' as description,\n\t\tarray_agg(match.heading) as headings,\n\t\tarray_agg(match.slug) as slugs\n\tfrom page\n\tjoin match on match.page_id = page.id\n\tgroup by page.id;\nend;\n$$"}	modify_search_functions
20240722100743	{"create table \\"public\\".\\"active_pgbouncer_projects\\" (\n    \\"id\\" bigint generated by default as identity not null,\n    \\"project_ref\\" text\n)","alter table \\"public\\".\\"active_pgbouncer_projects\\" enable row level security","create table \\"public\\".\\"vercel_project_connections_without_supavisor\\" (\n    \\"id\\" bigint generated by default as identity not null,\n    \\"project_ref\\" text not null\n)","alter table \\"public\\".\\"vercel_project_connections_without_supavisor\\" enable row level security","CREATE UNIQUE INDEX active_pgbouncer_projects_pkey ON public.active_pgbouncer_projects USING btree (id)","CREATE UNIQUE INDEX vercel_project_connections_without_supavisor_pkey ON public.vercel_project_connections_without_supavisor USING btree (id)","alter table \\"public\\".\\"active_pgbouncer_projects\\" add constraint \\"active_pgbouncer_projects_pkey\\" PRIMARY KEY using index \\"active_pgbouncer_projects_pkey\\"","alter table \\"public\\".\\"vercel_project_connections_without_supavisor\\" add constraint \\"vercel_project_connections_without_supavisor_pkey\\" PRIMARY KEY using index \\"vercel_project_connections_without_supavisor_pkey\\"","grant delete on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"anon\\"","grant insert on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"anon\\"","grant references on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"anon\\"","grant select on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"anon\\"","grant trigger on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"anon\\"","grant truncate on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"anon\\"","grant update on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"anon\\"","grant delete on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"authenticated\\"","grant insert on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"authenticated\\"","grant references on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"authenticated\\"","grant select on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"authenticated\\"","grant trigger on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"authenticated\\"","grant truncate on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"authenticated\\"","grant update on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"authenticated\\"","grant delete on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"service_role\\"","grant insert on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"service_role\\"","grant references on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"service_role\\"","grant select on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"service_role\\"","grant trigger on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"service_role\\"","grant truncate on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"service_role\\"","grant update on table \\"public\\".\\"active_pgbouncer_projects\\" to \\"service_role\\"","grant delete on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"anon\\"","grant insert on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"anon\\"","grant references on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"anon\\"","grant select on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"anon\\"","grant trigger on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"anon\\"","grant truncate on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"anon\\"","grant update on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"anon\\"","grant delete on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"authenticated\\"","grant insert on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"authenticated\\"","grant references on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"authenticated\\"","grant select on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"authenticated\\"","grant trigger on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"authenticated\\"","grant truncate on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"authenticated\\"","grant update on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"authenticated\\"","grant delete on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"service_role\\"","grant insert on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"service_role\\"","grant references on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"service_role\\"","grant select on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"service_role\\"","grant trigger on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"service_role\\"","grant truncate on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"service_role\\"","grant update on table \\"public\\".\\"vercel_project_connections_without_supavisor\\" to \\"service_role\\""}	remote_schema
20231127222412	{"-- remove unused column\n\nalter table page\ndrop column parent_page_id","-- move indexed content for fts search from page_section to page\n-- this should allow better rankings as it gives a better overview of\n-- search term frequency on that page\n\ndrop index fts_search_index","alter table page_section\ndrop column fts_tokens","alter table page\nadd column content text","alter table page\nadd column fts_tokens tsvector generated always as (to_tsvector('english', content)) stored","create index fts_search_index_page on page using gin(fts_tokens)","-- also search against the page title if it exists, to give more\n-- intuitive search rankings\n\nalter table page\n\nadd column title_tokens tsvector generated always as (to_tsvector('english', coalesce(meta ->> 'title', ''))) stored","create index fts_search_index_title on page using gin(title_tokens)","-- rank search by best match (title matches tend to rank better than content matches\n-- due to underlying ts_rank algorithm\n\ndrop function docs_search_fts","create or replace function docs_search_fts(query text)\nreturns table (\n\tid int8,\n\tpath text,\n\ttype text,\n\ttitle text,\n\tsubtitle text,\n\tdescription text\n)\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n\treturn query\n\tselect\n\t  page.id,\n\t  page.path,\n\t  page.type,\n\t  page.meta ->> 'title' as title,\n\t  page.meta ->> 'subtitle' as subtitle,\n\t  page.meta ->> 'description' as description\n\tfrom page\n\twhere title_tokens @@ websearch_to_tsquery(query) or fts_tokens @@ websearch_to_tsquery(query)\n\torder by greatest(\n\t\t-- Title is more important than body, so use 10 as the weighting factor\n\t\t-- Cut off at max rank of 1\n\t\tleast(10 * ts_rank(title_tokens, websearch_to_tsquery(query)), 1),\n\t\tts_rank(fts_tokens, websearch_to_tsquery(query))\n\t  ) desc\n\tlimit 10;\nend;\n$$"}	search_full_text_for_fts
20240123195252	{"alter table page_section\nadd column rag_ignore boolean\ndefault false"}	add_rag_ignore_column
20240129101115	{"create\nor replace function ipv6_active_status (project_ref text) returns table (pgbouncer_active boolean, vercel_active boolean) as $$\ndeclare\n  pgbouncer_active boolean;\n  vercel_active boolean;\nbegin\n  select exists (\n    select 1 \n    from active_pgbouncer_projects ap\n    where ap.project_ref = $1\n  ) into pgbouncer_active;\n\n  select exists (\n    select 1\n    from vercel_project_connections_without_supavisor vp\n    where vp.project_ref = $1\n  ) into vercel_active;\n\n  return query select pgbouncer_active, vercel_active;\nend;\n$$ language plpgsql security definer"}	add_ipv6_active_status_rpc
20240208001120	{"create type feedback_vote as enum (\n\t'yes',\n\t'no'\n)","create table feedback (\n\tid bigint primary key generated always as identity,\n\tdate_created date not null default current_date,\n\tvote feedback_vote not null,\n\tpage text not null\n)","alter table feedback enable row level security","create policy \\"Anyone can insert feedback\\"\non feedback\nas permissive for insert\nto public\nwith check (true)"}	add_feedback_table
20240306233728	{"create schema if not exists metrics","create view metrics.feedback_response_aggregate\nas select\n  count(*) filter (where vote = 'yes') as yes,\n  count(*) filter (where vote = 'no') as no\nfrom feedback"}	create_feedback_view
20240403133820	{"alter table public.feedback\nadd column metadata jsonb"}	track_feedback_query_params
20240604035404	{"create table last_changed (\n\tid bigint primary key generated always as identity,\n\tchecksum text not null,\n\tparent_page text not null,\n\theading text not null,\n\tlast_updated timestamp with time zone default now() not null,\n\tlast_checked timestamp with time zone default now() not null,\n\tunique (parent_page, heading)\n)","comment on table last_changed is\n'Records when page sections from docs content were last edited.'","comment on column last_changed.checksum is\n'Checksum of most recent section contents.'","comment on column last_changed.parent_page is\n'Path of the page containing this section.'","comment on column last_changed.last_updated is\n'When the content was last edited.'","comment on column last_changed.last_checked is\n'When the content was last checked. Used to identify and delete obsolete sections.'","alter table last_changed enable row level security","revoke all on last_changed from anon","revoke all on last_changed from authenticated","create index idx_last_changed_parent_page_btree\non last_changed (parent_page)"}	last_changed
20240605171314	{"create or replace function update_last_changed_checksum(\n  new_parent_page text,\n  new_heading text,\n  new_checksum text,\n  git_update_time timestamp with time zone,\n  check_time timestamp with time zone  \n)\nreturns timestamp with time zone\nlanguage plpgsql\nas $$\ndeclare\n  existing_id bigint;\n  previous_checksum text;\n  updated_check_time timestamp with time zone;\nbegin\n  select id, checksum into existing_id, previous_checksum\n    from public.last_changed\n    where\n      parent_page = new_parent_page\n      and heading = new_heading\n  ;\n\n  if existing_id is not null\n    and previous_checksum is not null\n    and previous_checksum = new_checksum\n\n    then\n      update public.last_changed set\n        last_checked = check_time\n        where\n\t\t  last_changed.id = existing_id\n\t\t  and last_changed.last_checked < check_time\n\t\treturning last_checked into updated_check_time\n      ;\n\n    else\n      insert into public.last_changed (\n        parent_page,\n        heading,\n        checksum,\n        last_updated,\n        last_checked\n      ) values (\n        new_parent_page,\n        new_heading,\n        new_checksum,\n        git_update_time,\n        check_time\n      )\n      on conflict\n\t    on constraint last_changed_parent_page_heading_key\n        do update set\n          checksum = new_checksum,\n          last_updated = git_update_time,\n          last_checked = check_time\n        where\n          last_changed.id = existing_id\n\t\t  and last_changed.last_checked < check_time\n\t  returning last_checked into updated_check_time\n      ;\n\n  end if;\n\n  return updated_check_time;\nend;\n$$","revoke all on function public.update_last_changed_checksum\nfrom public, anon, authenticated","create or replace function cleanup_last_changed_pages()\nreturns integer\nlanguage plpgsql\nas $$\ndeclare\n  newest_check_time timestamp with time zone;\n  number_deleted integer;\nbegin\n  select last_checked into newest_check_time\n    from public.last_changed\n    order by last_checked desc\n    limit 1\n  ;\n\n  with deleted as (\n    delete from public.last_changed\n    where last_checked <> newest_check_time\n    returning id\n  )\n  select count(*)\n  from deleted\n  into number_deleted;\n\n  return number_deleted;\nend;\n$$","revoke all on function public.cleanup_last_changed_pages\nfrom public, anon, authenticated"}	last_changed_update
20240626184716	{"alter function public.update_last_changed_checksum\nset search_path = ''","alter function public.cleanup_last_changed_pages\nset search_path = ''","-- Return a setof page_section so that we can use PostgREST resource embeddings (joins with other tables)\ncreate or replace function match_page_sections_v2(\n  embedding vector(1536),\n  match_threshold float,\n  min_content_length int\n)\nreturns setof page_section\nlanguage plpgsql\nset search_path = ''\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select *\n  from public.page_section\n\n  -- We only care about sections that have a useful amount of content\n  where length(page_section.content) >= min_content_length\n\n  -- The dot product is negative because of a Postgres limitation, so we negate it\n  and (page_section.embedding operator(public.<#>) embedding) * -1 > match_threshold\n\n  -- OpenAI embeddings are normalized to length 1, so\n  -- cosine similarity and dot product will produce the same results.\n  -- Using dot product which can be computed slightly faster.\n  --\n  -- For the different syntaxes, see https://github.com/pgvector/pgvector\n  order by page_section.embedding operator(public.<#>) embedding;\nend;\n$$","create or replace function ipv6_active_status (\n  project_ref text\n)\nreturns table (\n  pgbouncer_active boolean,\n  vercel_active boolean\n)\nset search_path = '' \nas $$\ndeclare\n  pgbouncer_active boolean;\n  vercel_active boolean;\nbegin\n  select exists (\n    select 1 \n    from public.active_pgbouncer_projects ap\n    where ap.project_ref = $1\n  ) into pgbouncer_active;\n\n  select exists (\n    select 1\n    from public.vercel_project_connections_without_supavisor vp\n    where vp.project_ref = $1\n  ) into vercel_active;\n\n  return query select pgbouncer_active, vercel_active;\nend;\n$$ language plpgsql security definer","create or replace function docs_search_embeddings(\n  embedding vector(1536),\n  match_threshold float\n)\nreturns table (\n  id int8,\n  path text,\n  type text,\n  title text,\n  subtitle text,\n  description text,\n  headings text[],\n  slugs text[]\n)\nlanguage plpgsql\nset search_path = ''\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  with match as(\n\tselect *\n\tfrom public.page_section\n\t-- The dot product is negative because of a Postgres limitation, so we negate it\n\twhere (page_section.embedding operator(public.<#>) embedding) * -1 > match_threshold\t\n\t-- OpenAI embeddings are normalized to length 1, so\n\t-- cosine similarity and dot product will produce the same results.\n\t-- Using dot product which can be computed slightly faster.\n\t--\n\t-- For the different syntaxes, see https://github.com/pgvector/pgvector\n\torder by page_section.embedding operator(public.<#>) embedding\n\tlimit 10\n  )\n  select\n\tpage.id,\n\tpage.path,\n\tpage.type,\n\tpage.meta ->> 'title' as title,\n\tpage.meta ->> 'subtitle' as title,\n\tpage.meta ->> 'description' as description,\n\tarray_agg(match.heading) as headings,\n\tarray_agg(match.slug) as slugs\n  from public.page\n  join match on match.page_id = page.id\n  group by page.id;\nend;\n$$","create or replace function docs_search_fts(query text)\nreturns table (\n  id int8,\n  path text,\n  type text,\n  title text,\n  subtitle text,\n  description text\n)\nlanguage plpgsql\nset search_path = ''\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select\n\tpage.id,\n\tpage.path,\n\tpage.type,\n\tpage.meta ->> 'title' as title,\n\tpage.meta ->> 'subtitle' as subtitle,\n\tpage.meta ->> 'description' as description\n  from public.page\n  where title_tokens @@ websearch_to_tsquery(query) or fts_tokens @@ websearch_to_tsquery(query)\n  order by greatest(\n\t  -- Title is more important than body, so use 10 as the weighting factor\n\t  -- Cut off at max rank of 1\n\t  least(10 * ts_rank(title_tokens, websearch_to_tsquery(query)), 1),\n\t  ts_rank(fts_tokens, websearch_to_tsquery(query))\n  ) desc\n  limit 10;\nend;\n$$","drop function public.match_page_sections","drop function public.get_page_parents"}	misc_database_fixes
20240723131601	{"alter table \\"public\\".\\"active_pgbouncer_projects\\" drop constraint \\"active_pgbouncer_projects_pkey\\"","alter table \\"public\\".\\"vercel_project_connections_without_supavisor\\" drop constraint \\"vercel_project_connections_without_supavisor_pkey\\"","drop index if exists \\"public\\".\\"active_pgbouncer_projects_pkey\\"","drop index if exists \\"public\\".\\"vercel_project_connections_without_supavisor_pkey\\"","drop table \\"public\\".\\"active_pgbouncer_projects\\"","drop table \\"public\\".\\"vercel_project_connections_without_supavisor\\""}	drop_unused_tables
20240723155310	{"create extension if not exists \\"uuid-ossp\\"","create table public.launch_weeks (\n  id text not null primary key, -- 'lw12', 'lw13', etc\n  created_at timestamp with time zone not null default timezone ('utc'::text, now()),\n  start_date timestamp with time zone null,\n  end_date timestamp with time zone null\n)","alter table public.launch_weeks enable row level security","create policy \\"Allow public read access\\"\non \\"public\\".\\"launch_weeks\\"\nas PERMISSIVE\nfor select\nusing ( true )","insert into public.launch_weeks (id) values ('lw12')","create table\n  public.tickets (\n    id uuid not null default uuid_generate_v4(),\n    created_at timestamp with time zone not null default timezone('utc'::text, now()),\n    launch_week text not null references public.launch_weeks (id),\n    user_id uuid not null references auth.users (id),\n    email text null,\n    name text null,\n    username text null,\n    referred_by text null,\n    shared_on_twitter timestamp with time zone null,\n    shared_on_linkedin timestamp with time zone null,\n    game_won_at timestamp with time zone null,\n    ticket_number bigint generated by default as identity,\n    metadata jsonb null,\n    role text null,\n    company text null,\n    location text null,\n    constraint tickets_pkey primary key (id),\n    constraint tickets_email_key unique (email, launch_week),\n    constraint tickets_ticket_number_key unique (ticket_number, launch_week),\n    constraint tickets_username_key unique (username, launch_week),\n    constraint public_tickets_id_fkey foreign key (user_id) references auth.users (id)\n  )","alter table public.tickets enable row level security","alter publication supabase_realtime add table public.tickets","GRANT UPDATE (role) ON TABLE public.tickets TO authenticated","GRANT UPDATE (company) ON TABLE public.tickets TO authenticated","GRANT UPDATE (location) ON TABLE public.tickets TO authenticated","create policy \\"Allow user to select own ticket\\"\non public.tickets\nas PERMISSIVE\nfor SELECT\nto authenticated\nusing (user_id = auth.uid())","create policy \\"Allow authenticated user to update its own ticket\\"\non public.tickets\nas permissive\nfor update\nto authenticated\nusing (user_id = auth.uid())\nwith check (user_id = auth.uid())","create policy \\"Allow insert for authenticated users only\\"\non public.tickets\nas permissive\nfor insert\nto authenticated\nwith check (user_id = auth.uid())","-- public view without sensible data\ncreate or replace view\n  public.tickets_view with (security_invoker=on) as\nwith\n  lw12_referrals as (\n    select\n      tickets_1.referred_by,\n      count(*) as referrals\n    from\n      tickets tickets_1\n    where\n      tickets_1.referred_by is not null\n    group by\n      tickets_1.referred_by\n  )\nselect\n  tickets.id,\n  tickets.name,\n  tickets.username,\n  tickets.ticket_number,\n  tickets.created_at,\n  tickets.launch_week,\n  tickets.shared_on_twitter,\n  tickets.shared_on_linkedin,\n  tickets.metadata,\n  tickets.role,\n  tickets.company,\n  tickets.location,\n  case\n    when lw12_referrals.referrals is null then 0::bigint\n    else lw12_referrals.referrals\n  end as referrals,\n  case\n    when tickets.shared_on_twitter is not null\n    and tickets.shared_on_linkedin is not null then true\n    else false\n  end as platinum,\n  case\n    when tickets.game_won_at is not null then true\n    else false\n  end as secret\nfrom\n  tickets\n  left join lw12_referrals on tickets.username = lw12_referrals.referred_by","-- Create meetups table\ncreate table\n  public.meetups (\n    id uuid not null default uuid_generate_v4(),\n    created_at timestamp with time zone not null default now(),\n    launch_week text not null references public.launch_weeks (id),\n    title text null,\n    country text null,\n    start_at timestamp with time zone null,\n    link text null,\n    display_info text null,\n    is_live boolean not null default false,\n    is_published boolean not null default false,\n    constraint meetups_pkey primary key (id)\n  )","alter table public.meetups enable row level security","alter publication supabase_realtime add table public.meetups","create policy \\"Allow anybody to select all meetups\\"\non public.meetups\nas permissive\nfor select\nusing (true)"}	add_lw12_ticketing_schema
20240911215059	{"create table troubleshooting_entries (\n    id uuid primary key default gen_random_uuid(),\n    title text not null,\n    topics text[] not null,\n    keywords text[],\n    api jsonb,\n    errors jsonb[],\n    github_url text not null,\n    date_created timestamptz not null default now(),\n    date_updated timestamptz not null default now()\n)","alter table troubleshooting_entries enable row level security","create or replace function update_troubleshooting_entry_date_updated() returns trigger as $$\nbegin\n    new.date_updated = now();\n    return new;\nend;\n$$ language plpgsql","create trigger update_troubleshooting_entry_date_updated_trigger before update on troubleshooting_entries for each row\nexecute function update_troubleshooting_entry_date_updated()"}	troubleshooting_entries
20240918220938	{"create table validation_history (\n  id bigint generated always as identity primary key,\n  tag text not null,\n  created_at timestamp with time zone not null default now()\n)","create index validation_history_tag_created_at_idx on validation_history (tag, created_at desc)","alter table validation_history enable row level security","create or replace function get_last_revalidation_for_tags(tags text[])\nreturns table (\n  tag text,\n  created_at timestamp with time zone\n)\nlanguage sql\nas $$\n  select\n    tag,\n    max(created_at) as created_at\n  from validation_history\n  where tag = any(tags)\n  group by tag;\n$$"}	validation_history
20241002215612	{"alter table troubleshooting_entries\nadd column github_id text not null","alter table troubleshooting_entries\nadd column checksum text not null","create index idx_troubleshooting_checksum\non troubleshooting_entries (checksum)","create extension pg_jsonschema","alter table troubleshooting_entries\nadd constraint troubleshooting_api_check\ncheck (\n    api is null or\n    jsonb_matches_schema(\n        schema := '{\n            \\"type\\": \\"object\\",\n            \\"properties\\": {\n                \\"sdk\\": {\n                    \\"type\\": \\"array\\",\n                    \\"items\\": { \\"type\\": \\"string\\" }\n                },\n                \\"management_api\\": {\n                    \\"type\\": \\"array\\",\n                    \\"items\\": { \\"type\\": \\"string\\" }\n                },\n                \\"cli\\": {\n                    \\"type\\": \\"array\\",\n                    \\"items\\": { \\"type\\": \\"string\\" }\n                }\n            },\n            \\"additionalProperties\\": false\n        }',\n        instance := api\n    )\n)","create or replace function validate_troubleshooting_errors(errors jsonb[])\nreturns boolean as $$\ndeclare\n    error jsonb;\nbegin\n    if errors is null then\n        return true;\n    end if;\n\n    foreach error in array errors\n    loop\n        if not jsonb_matches_schema(\n            schema := '{\n                \\"type\\": \\"object\\",\n                \\"properties\\": {\n                    \\"http_status_code\\": { \\"type\\": \\"number\\" },\n                    \\"code\\": { \\"type\\": \\"string\\" },\n                    \\"message\\": { \\"type\\": \\"string\\" }\n                },\n                \\"additionalProperties\\": false\n            }',\n            instance := error\n        ) then\n            return false;\n        end if;\n    end loop;\n\n    return true;\nend;\n$$ language plpgsql","alter table troubleshooting_entries\nadd constraint troubleshooting_errors_check\ncheck (\n    validate_troubleshooting_errors(errors)\n)"}	troubleshooting_validation
20241121205753	{"alter table public.meetups\nadd column timezone text","alter table public.meetups\nadd column city text"}	add_meetups_columns
20241127183137	{"comment on column meetups.timezone is 'Needs to be in America/Los_Angeles format.'"}	comment_meetup_timezone
20250423133137	{"create or replace function match_embedding(\n  embedding vector(1536),\n  match_threshold float default 0.78,\n  max_results int default 30\n)\nreturns setof page_section\nlanguage plpgsql\nset search_path = ''\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select *\n  from public.page_section\n  where (page_section.embedding operator(public.<#>) embedding) <= -match_threshold\n  order by page_section.embedding operator(public.<#>) embedding\n  limit max_results;\nend;\n$$","create or replace function get_full_content_url(\n  type text,\n  path text,\n  slug text\n)\nreturns text\nlanguage sql\nset search_path = ''\nas $$\n  select case\n    when type = 'github-discussions'\n      then path\n    when type = 'partner-integration'\n      then concat('https://supabase.com', path)\n    else\n      concat(\n        'https://supabase.com/docs',\n        path,\n        case\n          when slug is null\n            then ''\n          else\n            concat('#', slug)\n        end\n      )\n  end;\n$$","create or replace function search_content(\n  embedding vector(1536),\n  include_full_content boolean default false,\n  match_threshold float default 0.78,\n  max_result int default 30\n)\nreturns table (\n  id bigint,\n  page_title text,\n  type text,\n  href text,\n  content text,\n  subsections json[]\n)\nlanguage sql\nset search_path = ''\nas $$\n  with matched_section as (\n    select\n      *,\n      row_number() over () as ranking\n    from public.match_embedding(\n      embedding,\n      match_threshold,\n      max_result\n    )\n  )\n  select\n    page.id,\n    meta ->> 'title' as page_title,\n    type,\n    public.get_full_content_url(type, path, null) as href,\n    case\n      when include_full_content\n        then page.content\n      else\n        null\n    end as content,\n    array_agg(\n      json_build_object(\n        'title', heading,\n        'href', public.get_full_content_url(type, path, slug),\n        'content', matched_section.content\n      )\n    )\n  from matched_section\n  join public.page on matched_section.page_id = page.id\n  group by page.id\n  order by min(ranking);\n$$"}	improve_vector_search
20250430202653	{"-- Alter the search_content function to also return the page metadata\n\ndrop function search_content","create or replace function search_content(\n  embedding vector(1536),\n  include_full_content boolean default false,\n  match_threshold float default 0.78,\n  max_result int default 30\n)\nreturns table (\n  id bigint,\n  page_title text,\n  type text,\n  href text,\n  content text,\n  metadata json,\n  subsections json[]\n)\nlanguage sql\nset search_path = ''\nas $$\n  with matched_section as (\n    select\n      *,\n      row_number() over () as ranking\n    from public.match_embedding(\n      embedding,\n      match_threshold,\n      max_result\n    )\n  )\n  select\n    page.id,\n    meta ->> 'title' as page_title,\n    type,\n    public.get_full_content_url(type, path, null) as href,\n    case\n      when include_full_content\n        then page.content\n      else\n        null\n    end as content,\n    meta as metadata,\n    array_agg(\n      json_build_object(\n        'title', heading,\n        'href', public.get_full_content_url(type, path, slug),\n        'content', matched_section.content\n      )\n    )\n  from matched_section\n  join public.page on matched_section.page_id = page.id\n  group by page.id\n  order by min(ranking);\n$$"}	return_meta_vector_search
20250521181337	{"create schema if not exists utils","grant usage on schema utils to anon","grant usage on schema utils to authenticated","alter default privileges in schema utils\nrevoke execute on functions from anon","alter default privileges in schema utils\nrevoke execute on functions from authenticated","create or replace function utils.update_timestamp()\nreturns trigger\nset search_path = ''\nlanguage plpgsql\nas $$\nbegin\n    new.updated_at = now();\n    return new;\nend;\n$$","grant execute on function utils.update_timestamp() to anon","grant execute on function utils.update_timestamp() to authenticated","-- Create a new schema to keep things organized since we'll be adding a lot of\n-- content tables\ncreate schema if not exists content","grant usage on schema content to anon","grant usage on schema content to authenticated","create table if not exists content.service (\n    id uuid primary key default gen_random_uuid(),\n    name text not null unique,\n    created_at timestamptz default now(),\n    updated_at timestamptz default now(),\n    deleted_at timestamptz default null\n)","create or replace trigger sync_updated_at_content_service\nbefore update on content.service\nfor each row\nexecute function utils.update_timestamp()","create or replace rule soft_delete_content_service as\non delete to content.service\ndo instead (\n    update content.service\n    set deleted_at = now()\n    where id = old.id\n)","alter table content.service\nenable row level security","create index if not exists idx_content_service_id_nondeleted_only\non content.service (id)\nwhere deleted_at is null","create index if not exists idx_content_service_name_nondeleted_only\non content.service (name)\nwhere deleted_at is null","insert into content.service (name) values\n    ('AUTH'),\n    ('REALTIME'),\n    ('STORAGE')","create table if not exists content.error (\n    code text not null,\n    service uuid not null references content.service (id) on delete restrict,\n    http_status_code smallint,\n    message text,\n    created_at timestamptz default now(),\n    updated_at timestamptz default now(),\n    deleted_at timestamptz default null,\n    primary key (service, code)\n)","create or replace trigger sync_updated_at_content_error\nbefore update on content.error\nfor each row\nexecute function utils.update_timestamp()","create or replace rule soft_delete_content_error as\non delete to content.error\ndo instead (\n    update content.error\n    set deleted_at = now()\n    where code = old.code and service = old.service\n)","alter table content.error\nenable row level security","create index if not exists idx_content_error_service_code_nondeleted_only\non content.error (service, code)\nwhere deleted_at is null","grant select (\n    id,\n    name,\n    deleted_at\n) on content.service to anon","grant select (\n    id,\n    name,\n    deleted_at\n) on content.service to authenticated","grant select (\n    code,\n    service,\n    http_status_code,\n    message,\n    deleted_at\n) on content.error to anon","grant select (\n    code,\n    service,\n    http_status_code,\n    message,\n    deleted_at\n) on content.error to authenticated","create policy content_service_anon_select_all\non content.service\nfor select\nto anon\nusing (deleted_at is null)","create policy content_service_authenticated_select_all\non content.service\nfor select\nto authenticated\nusing (deleted_at is null)","create policy content_error_anon_select_all\non content.error\nfor select\nto anon\nusing (deleted_at is null)","create policy content_error_authenticated_select_all\non content.error\nfor select\nto authenticated\nusing (deleted_at is null)"}	error_code_table
20250521194255	{"alter default privileges in schema content\nrevoke execute on functions from anon","alter default privileges in schema content\nrevoke execute on functions from authenticated","create function content.update_error_code(\n    code text,\n    service text,\n    http_status_code smallint default null,\n    message text default null\n)\nreturns boolean\nset search_path = ''\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\ndeclare\n    service_id uuid;\n    result boolean;\nbegin\n    insert into content.service (name)\n    values (service)\n    on conflict (name) do nothing;\n\n    select id into service_id\n    from content.service\n    where name = service;\n\n    insert into content.error (service, code, http_status_code, message)\n    values (service_id, code, http_status_code, message)\n    on conflict on constraint error_pkey do\n        update set\n            http_status_code = excluded.http_status_code,\n            message = excluded.message\n        where\n            error.service = service_id\n            and error.code = code\n            and (\n                error.http_status_code is distinct from excluded.http_status_code\n                or error.message is distinct from excluded.message\n            )\n        returning true into result;\n\n    return coalesce(result, false);\nend;\n$$"}	error_code_update_functions
20250522171141	{"create or replace function content.delete_error_codes_except(\n    skip_codes jsonb\n)\nreturns void\nset search_path = ''\nlanguage sql\nas $$\n    delete from content.error\n    where not exists (\n        select 1\n        from jsonb_array_elements(skip_codes) skipped\n        join content.service on service.name = (skipped ->> 'service')\n        where service.id = error.service\n        and error.code = (skipped ->> 'error_code')\n    );\n$$"}	error_code_delete_function
20250527221007	{"-- service_role needs access to content tables to run sync scripts\ngrant usage on schema content to service_role","grant all on table content.service to service_role","grant all on table content.error to service_role"}	service_role_grants_error_tables
20250529214621	{"alter table content.error\nadd column metadata jsonb","alter table content.error\nadd constraint constraint_content_error_metadata_schema check (\n    jsonb_matches_schema(\n        '{\n            \\"type\\": \\"object\\",\n            \\"properties\\": {\n                \\"references\\": {\n                    \\"type\\": \\"array\\",\n                    \\"items\\": {\n                        \\"type\\": \\"object\\",\n                        \\"properties\\": {\n                            \\"href\\": {\n                                \\"type\\": \\"string\\"\n                            },\n                            \\"description\\": {\n                                \\"type\\": \\"string\\"\n                            }\n                        },\n                        \\"required\\": [\\"href\\", \\"description\\"]\n                    }\n                }\n            }\n        }',\n        metadata\n    )\n)","drop function content.update_error_code","-- Recreate function also taking a metadata field\n-- See comments for what is new\ncreate function content.update_error_code(\n    code text,\n    service text,\n    http_status_code smallint default null,\n    message text default null,\n    -- Only new parameter\n    metadata jsonb default null\n)\nreturns boolean\nset search_path = ''\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\ndeclare\n    service_id uuid;\n    result boolean;\nbegin\n    insert into content.service (name)\n    values (service)\n    on conflict (name) do nothing;\n\n    select id into service_id\n    from content.service\n    where name = service;\n\n    insert into content.error (\n        service,\n        code,\n        http_status_code,\n        message,\n        -- Added metadata here\n        metadata\n    )\n    -- Added metadata here\n    values (service_id, code, http_status_code, message, metadata)\n    on conflict on constraint error_pkey do\n        update set\n            http_status_code = excluded.http_status_code,\n            message = excluded.message,\n            -- Added metadata here\n            metadata = excluded.metadata\n        where\n            error.service = service_id\n            and error.code = code\n            and (\n                error.http_status_code is distinct from excluded.http_status_code\n                or error.message is distinct from excluded.message\n                -- Added metadata here\n                or error.metadata is distinct from excluded.metadata\n            )\n        returning true into result;\n\n    return coalesce(result, false);\nend;\n$$"}	store_error_metadata
20250529220759	{"drop function content.delete_error_codes_except(jsonb)","-- Recreating function to return the number of rows deleted\ncreate or replace function content.delete_error_codes_except(\n    skip_codes jsonb\n)\nreturns integer\nset search_path = ''\nlanguage sql\nas $$\n    with updated as (\n        update content.error\n        set deleted_at = now()\n        where\n            deleted_at is null\n            and not exists (\n                select 1\n                from jsonb_array_elements(skip_codes) skipped\n                join content.service on service.name = (skipped ->> 'service')\n                where service.id = error.service\n                and error.code = (skipped ->> 'error_code')\n            )\n        returning *\n    )\n    select count(*) from updated;\n$$"}	error_code_delete_return_value
20250605201937	{"-- Add an ID column on the error table. It has a composite primary key but\n-- needs an ID column to be able to use it as a foreign key.\nalter table content.error\nadd column id uuid unique not null default gen_random_uuid()","grant select (id)\non content.error\nto anon","grant select (id)\non content.error\nto authenticated"}	error_codes_table_ids
20250714120000	{"-- Hybrid search: combines FTS and vector search using reciprocal rank fusion (RRF)\ncreate or replace function search_content_hybrid(\n  query_text text,\n  query_embedding vector(1536),\n  max_result int default 30,\n  full_text_weight float default 1,\n  semantic_weight float default 1,\n  rrf_k int default 50,\n  match_threshold float default 0.78,\n  include_full_content boolean default false\n)\nreturns table (\n  id bigint,\n  page_title text,\n  type text,\n  href text,\n  content text,\n  metadata json,\n  subsections json[]\n)\nlanguage sql\nset search_path = ''\nas $$\nwith full_text as (\n  select\n    id,\n    row_number() over(order by greatest(\n      least(10 * ts_rank(title_tokens, websearch_to_tsquery(query_text)), 1),\n      ts_rank(fts_tokens, websearch_to_tsquery(query_text))\n    ) desc) as rank_ix\n  from public.page\n  where title_tokens @@ websearch_to_tsquery(query_text) or fts_tokens @@ websearch_to_tsquery(query_text)\n  order by rank_ix\n  limit least(max_result, 30) * 2\n),\nsemantic as (\n  select\n    page_id as id,\n    row_number() over () as rank_ix\n  from public.match_embedding(query_embedding, match_threshold, max_result * 2)\n),\nrrf as (\n  select\n    coalesce(full_text.id, semantic.id) as id,\n    coalesce(1.0 / (rrf_k + full_text.rank_ix), 0.0) * full_text_weight +\n    coalesce(1.0 / (rrf_k + semantic.rank_ix), 0.0) * semantic_weight as rrf_score\n  from full_text\n  full outer join semantic on full_text.id = semantic.id\n)\nselect\n  page.id,\n  page.meta ->> 'title' as page_title,\n  page.type,\n  public.get_full_content_url(page.type, page.path, null) as href,\n  case when include_full_content then page.content else null end as content,\n  page.meta as metadata,\n  array_agg(json_build_object(\n    'title', page_section.heading,\n    'href', public.get_full_content_url(page.type, page.path, page_section.slug),\n    'content', page_section.content\n  )) as subsections\nfrom rrf\njoin public.page on page.id = rrf.id\nleft join public.page_section on page_section.page_id = page.id\nwhere rrf.rrf_score > 0\ngroup by page.id\norder by max(rrf.rrf_score) desc\nlimit max_result;\n$$"}	hybrid_search
20250910155912	{"-- Create nimbus tables for feature-flag-filtered search\n-- These tables mirror the structure of page and page_section but contain only content\n-- that should be visible when all feature flags are disabled\n\ncreate table \\"public\\".\\"page_nimbus\\" (\n  id bigint primary key generated always as identity,\n  path text not null unique,\n  checksum text,\n  meta jsonb,\n  type text,\n  source text,\n  content text,\n  version uuid,\n  last_refresh timestamptz,\n  fts_tokens tsvector generated always as (to_tsvector('english', content)) stored,\n  title_tokens tsvector generated always as (to_tsvector('english', coalesce(meta ->> 'title', ''))) stored\n)","alter table \\"public\\".\\"page_nimbus\\"\nenable row level security","create policy \\"anon can read page_nimbus\\"\non public.page_nimbus\nfor select\nto anon\nusing (true)","create policy \\"authenticated can read page_nimbus\\"\non public.page_nimbus\nfor select\nto authenticated\nusing (true)","create table \\"public\\".\\"page_section_nimbus\\" (\n  id bigint primary key generated always as identity,\n  page_id bigint not null references public.page_nimbus (id) on delete cascade,\n  content text,\n  token_count int,\n  embedding vector(1536),\n  slug text,\n  heading text,\n  rag_ignore boolean default false\n)","alter table \\"public\\".\\"page_section_nimbus\\"\nenable row level security","create policy \\"anon can read page_section_nimbus\\"\non public.page_section_nimbus\nfor select\nto anon\nusing (true)","create policy \\"authenticated can read page_section_nimbus\\"\non public.page_section_nimbus\nfor select\nto authenticated\nusing (true)","-- Create indexes for nimbus tables (matching the regular tables)\ncreate index fts_search_index_content_nimbus\non page_nimbus\nusing gin(fts_tokens)","create index fts_search_index_title_nimbus\non page_nimbus\nusing gin(title_tokens)","-- Create search function for nimbus tables (FTS search)\ncreate or replace function docs_search_fts_nimbus(query text)\nreturns table (\n\tid bigint,\n\tpath text,\n\ttype text,\n\ttitle text,\n\tsubtitle text,\n\tdescription text\n)\nset search_path = ''\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n\treturn query\n\tselect\n\t  page_nimbus.id,\n\t  page_nimbus.path,\n\t  page_nimbus.type,\n\t  page_nimbus.meta ->> 'title' as title,\n\t  page_nimbus.meta ->> 'subtitle' as subtitle,\n\t  page_nimbus.meta ->> 'description' as description\n\tfrom public.page_nimbus\n\twhere title_tokens @@ websearch_to_tsquery(query) or fts_tokens @@ websearch_to_tsquery(query)\n\torder by greatest(\n\t\t-- Title is more important than body, so use 10 as the weighting factor\n\t\t-- Cut off at max rank of 1\n\t\tleast(10 * ts_rank(title_tokens, websearch_to_tsquery(query)), 1),\n\t\tts_rank(fts_tokens, websearch_to_tsquery(query))\n\t  ) desc\n\tlimit 10;\nend;\n$$","-- Create embedding matching function for nimbus tables\ncreate or replace function match_embedding_nimbus(\n  embedding vector(1536),\n  match_threshold float default 0.78,\n  max_results int default 30\n)\nreturns setof public.page_section_nimbus\nset search_path = ''\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select *\n  from public.page_section_nimbus\n  where (page_section_nimbus.embedding operator(public.<#>) embedding) <= -match_threshold\n  order by page_section_nimbus.embedding operator(public.<#>) embedding\n  limit max_results;\nend;\n$$","-- Create hybrid search function for nimbus tables\ncreate or replace function search_content_hybrid_nimbus(\n  query_text text,\n  query_embedding vector(1536),\n  max_result int default 30,\n  full_text_weight float default 1,\n  semantic_weight float default 1,\n  rrf_k int default 50,\n  match_threshold float default 0.78,\n  include_full_content boolean default false\n)\nreturns table (\n  id bigint,\n  page_title text,\n  type text,\n  href text,\n  content text,\n  metadata json,\n  subsections json[]\n)\nlanguage sql\nset search_path = ''\nas $$\nwith full_text as (\n  select\n    id,\n    row_number() over(order by greatest(\n      least(10 * ts_rank(title_tokens, websearch_to_tsquery(query_text)), 1),\n      ts_rank(fts_tokens, websearch_to_tsquery(query_text))\n    ) desc) as rank_ix\n  from public.page_nimbus\n  where title_tokens @@ websearch_to_tsquery(query_text) or fts_tokens @@ websearch_to_tsquery(query_text)\n  order by rank_ix\n  limit least(max_result, 30) * 2\n),\nsemantic as (\n  select\n    page_id as id,\n    row_number() over () as rank_ix\n  from public.match_embedding_nimbus(query_embedding, match_threshold, max_result * 2)\n),\nrrf as (\n  select\n    coalesce(full_text.id, semantic.id) as id,\n    coalesce(1.0 / (rrf_k + full_text.rank_ix), 0.0) * full_text_weight +\n    coalesce(1.0 / (rrf_k + semantic.rank_ix), 0.0) * semantic_weight as rrf_score\n  from full_text\n  full outer join semantic on full_text.id = semantic.id\n)\nselect\n  page_nimbus.id,\n  page_nimbus.meta ->> 'title' as page_title,\n  page_nimbus.type,\n  public.get_full_content_url(page_nimbus.type, page_nimbus.path, null) as href,\n  case when include_full_content then page_nimbus.content else null end as content,\n  page_nimbus.meta as metadata,\n  array_agg(json_build_object(\n    'title', page_section_nimbus.heading,\n    'href', public.get_full_content_url(page_nimbus.type, page_nimbus.path, page_section_nimbus.slug),\n    'content', page_section_nimbus.content\n  )) as subsections\nfrom rrf\njoin public.page_nimbus on page_nimbus.id = rrf.id\nleft join public.page_section_nimbus on page_section_nimbus.page_id = page_nimbus.id\nwhere rrf.rrf_score > 0\ngroup by page_nimbus.id\norder by max(rrf.rrf_score) desc\nlimit max_result;\n$$","create or replace function match_page_sections_v2_nimbus(\n  embedding vector(1536),\n  match_threshold float,\n  min_content_length int\n)\nreturns setof page_section_nimbus\nset search_path = ''\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  select *\n  from public.page_section_nimbus\n\n  -- We only care about sections that have a useful amount of content\n  where length(page_section_nimbus.content) >= min_content_length\n\n  -- The dot product is negative because of a Postgres limitation, so we negate it\n  and (page_section_nimbus.embedding operator(public.<#>) embedding) * -1 > match_threshold\n\n  -- OpenAI embeddings are normalized to length 1, so\n  -- cosine similarity and dot product will produce the same results.\n  -- Using dot product which can be computed slightly faster.\n  --\n  -- For the different syntaxes, see https://github.com/pgvector/pgvector\n  order by page_section_nimbus.embedding operator(public.<#>) embedding;\nend;\n$$","create or replace function docs_search_embeddings_nimbus(\n  embedding vector(1536),\n  match_threshold float\n)\nreturns table (\n  id bigint,\n  path text,\n  type text,\n  title text,\n  subtitle text,\n  description text,\n  headings text[],\n  slugs text[]\n)\nset search_path = ''\nlanguage plpgsql\nas $$\n#variable_conflict use_variable\nbegin\n  return query\n  with match as(\n\tselect *\n\tfrom public.page_section_nimbus\n\t-- The dot product is negative because of a Postgres limitation, so we negate it\n\twhere (page_section_nimbus.embedding operator(public.<#>) embedding) * -1 > match_threshold\t\n\t-- OpenAI embeddings are normalized to length 1, so\n\t-- cosine similarity and dot product will produce the same results.\n\t-- Using dot product which can be computed slightly faster.\n\t--\n\t-- For the different syntaxes, see https://github.com/pgvector/pgvector\n\torder by page_section_nimbus.embedding operator(public.<#>) embedding\n\tlimit 10\n  )\n  select\n\tpage_nimbus.id,\n\tpage_nimbus.path,\n\tpage_nimbus.type,\n\tpage_nimbus.meta ->> 'title' as title,\n\tpage_nimbus.meta ->> 'subtitle' as title,\n\tpage_nimbus.meta ->> 'description' as description,\n\tarray_agg(match.heading) as headings,\n\tarray_agg(match.slug) as slugs\n  from public.page_nimbus\n  join match on match.page_id = page_nimbus.id\n  group by page_nimbus.id;\nend;\n$$","create or replace function search_content_nimbus(\n  embedding vector(1536),\n  include_full_content boolean default false,\n  match_threshold float default 0.78,\n  max_result int default 30\n)\nreturns table (\n  id bigint,\n  page_title text,\n  type text,\n  href text,\n  content text,\n  metadata json,\n  subsections json[]\n)\nset search_path = ''\nlanguage sql\nas $$\n  with matched_section as (\n    select\n      *,\n      row_number() over () as ranking\n    from public.match_embedding_nimbus(\n      embedding,\n      match_threshold,\n      max_result\n    )\n  )\n  select\n    page_nimbus.id,\n    meta ->> 'title' as page_title,\n    type,\n    public.get_full_content_url(type, path, null) as href,\n    case\n      when include_full_content\n        then page_nimbus.content\n      else\n        null\n    end as content,\n    meta as metadata,\n    array_agg(\n      json_build_object(\n        'title', heading,\n        'href', public.get_full_content_url(type, path, slug),\n        'content', matched_section.content\n      )\n    )\n  from matched_section\n  join public.page_nimbus on matched_section.page_id = page_nimbus.id\n  group by page_nimbus.id\n  order by min(ranking);\n$$"}	create_nimbus_search_tables
20251023193135	{"-- Give anon and authenticated read access to the troubleshooting entries table\n-- Allows troubleshooting entries to be generated in local dev\n\ncreate policy anon_read_troubleshooting_entries\non public.troubleshooting_entries\nfor select\nto anon\nusing (true)","create policy authenticated_read_troubleshooting_entries\non public.troubleshooting_entries\nfor select\nto authenticated\nusing (true)"}	anon_read_access_troubleshooting
\.


--
-- Data for Name: seed_files; Type: TABLE DATA; Schema: supabase_migrations; Owner: postgres
--

COPY supabase_migrations.seed_files (path, hash) FROM stdin;
supabase/seed.sql	aa44f8e64af9d47a05e1f18fcb47fee8019bc2917022a33c7b6c520e337cbe77
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: supabase_admin
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 1, false);


--
-- Name: feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.feedback_id_seq', 1, false);


--
-- Name: last_changed_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.last_changed_id_seq', 1, false);


--
-- Name: page_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.page_id_seq', 1, false);


--
-- Name: page_nimbus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.page_nimbus_id_seq', 1, false);


--
-- Name: page_section_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.page_section_id_seq', 1, false);


--
-- Name: page_section_nimbus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.page_section_nimbus_id_seq', 1, false);


--
-- Name: tickets_ticket_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tickets_ticket_number_seq', 1, false);


--
-- Name: validation_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.validation_history_id_seq', 1, false);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: supabase_admin
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: hooks_id_seq; Type: SEQUENCE SET; Schema: supabase_functions; Owner: supabase_functions_admin
--

SELECT pg_catalog.setval('supabase_functions.hooks_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

\unrestrict CzqWooNn4vC2XbRJEwOfeC5C2dObIxdV9r11hHtzwf63CxBm1GSwq0D7y69aJ7q

