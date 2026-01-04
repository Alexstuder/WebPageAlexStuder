
-- Versuche, Rechte auf das Schema zu geben
GRANT USAGE, CREATE ON SCHEMA aibrewgenius TO postgres;
GRANT USAGE, CREATE ON SCHEMA aibrewgenius TO anon;
GRANT USAGE, CREATE ON SCHEMA aibrewgenius TO authenticated;
GRANT USAGE, CREATE ON SCHEMA aibrewgenius TO service_role;

-- Falls das klappt, versuche ich erneut die Tabellen dort anzulegen.
