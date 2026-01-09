#!/usr/bin/env bash
set -euo pipefail

echo "🔄 Exporting local Supabase database to seed file..."

# Configuration
CONTAINER_NAME="supabase_db_local"
DB_USER="postgres"
DB_NAME="postgres"
SCHEMA="aibrewgenius"
OUTPUT_FILE="db_scripts/full/aibrewgenius_seed.sql"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "❌ Error: Container '${CONTAINER_NAME}' is not running!"
  echo "   Please start Supabase with: supabase start"
  exit 1
fi

# Get the database password from container environment
echo "📦 Getting database password from container..."
DB_PASS=$(docker exec $CONTAINER_NAME printenv POSTGRES_PASSWORD)

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Export only the data (INSERT statements) from the aibrewgenius schema
echo "📥 Exporting data from schema '${SCHEMA}'..."
docker exec -e PGPASSWORD=$DB_PASS $CONTAINER_NAME \
  pg_dump -U $DB_USER -d $DB_NAME \
  --schema=$SCHEMA \
  --data-only \
  --inserts \
  --no-owner \
  --no-privileges \
  --no-tablespaces \
  --disable-triggers \
  > "$OUTPUT_FILE"

# Add header comment to the file
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" <<'EOF'
--
-- PostgreSQL database dump
--

\restrict GOy8HFpGeU667goeoghfnO5qPoVAGs8wrGQeXXPB2XUnuDOcjBo7RaxriHXAN75

-- Dumped from database version 17.6
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

EOF

cat "$OUTPUT_FILE" >> "$TEMP_FILE"
mv "$TEMP_FILE" "$OUTPUT_FILE"

# Show file size and line count
FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")

echo ""
echo "✅ Export completed successfully!"
echo "   📄 File: $OUTPUT_FILE"
echo "   📊 Size: $FILE_SIZE"
echo "   📝 Lines: $LINE_COUNT"
echo ""
echo "🚀 Next steps:"
echo "   1. Review the exported file"
echo "   2. git add $OUTPUT_FILE"
echo "   3. git commit -m 'Update seed data from local DB'"
echo "   4. git push origin main"
echo ""
echo "⚠️  The GitHub workflow will automatically detect changes in db_scripts/"
echo "    and update the VPS database on the next push!"
