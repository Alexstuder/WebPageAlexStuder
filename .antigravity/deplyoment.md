# Deployment Workflow
- Wenn ich "Deploy" sage, führe zuerst flutter analyze durch und korrigiere den Code solange, bis dieser fehlerfrei ist.
- Führe danach den DB-Seed-Export aus: ersetze die daten ./db_scripts/full/aibrewgenius_seed.sql
- Committe danach alle Änderungen mit einer KI-generierten Nachricht.
- Pushe erst nach erfolgreichem Commit.