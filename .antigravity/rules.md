# Workspace Guidelines & Workflow

## 1. Kommunikation
* **Sprache:** In diesem Workspace wird **ausschließlich Deutsch** gesprochen. Das gilt für Chat-Antworten, Erklärungen und Commit-Messages.

## 2. Qualitätssicherung (The Analyze Loop)
Nach jeder Code-Änderung ist folgender Ablauf **zwingend**:
1.  Führe `flutter analyze` im Terminal aus.
2.  **Falls Fehler oder Warnungen auftreten:**
    * Analysiere die Fehler.
    * Korrigiere den Code.
    * Führe erneut `flutter analyze` aus.
3.  Dieser Loop muss so lange wiederholt werden, bis `flutter analyze` **keine Fehler** mehr meldet ("exit code 0").
4.  Erst wenn der Code sauber ist, darfst du zum nächsten Schritt (Datenbank/Restart) übergehen.

## 3. Datenbank-Workflow (Konditional)
**WENN** die Änderungen die Datenbank betreffen (z.B. Schema, Models, Drift/Hive/SQLite Änderungen):
1.  Stelle sicher, dass Schritt 2 (Analyze) erfolgreich abgeschlossen ist.
2.  Führe das Init-Script aus: `./db_scripts/full/001_init_schema.sql`
3.  Führe direkt danach das Seed-Script aus: `./db_scripts/full/aibrewgenius_seed.sql`

## 4. Abschluss (Restart)
Sobald Code und Datenbank-Status validiert sind:
1.  Stoppe die aktuell laufende Instanz der App (SIGTERM/Stop).
2.  Starte die App frisch neu (z.B. via `flutter run`).