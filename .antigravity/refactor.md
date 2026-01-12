# Refactor Workflow

Auslöser:
- Wird das Kommando „Refactor“ ausgesprochen, startet dieser Workflow vollständig und deterministisch.

1. Statische Analyse (Baseline)
- Führe `flutter analyze` aus.
- Behebe alle Fehler und Warnings iterativ.
- Abbruchbedingung: `flutter analyze` liefert ein vollständig fehlerfreies Ergebnis.

2. Test-Baseline (Absicherung vor Refactoring)
- Nach erfolgreichem `flutter analyze` werden neue Tests erstellt.
- Ziel der Tests:
  - Abbildung des aktuellen Ist-Verhaltens
  - Absicherung kritischer Use-Cases, Logikpfade und Zustände
- Tests müssen reproduzierbar und deterministisch sein.
- Führe alle Tests aus und stelle sicher:
  - Alle Tests bestehen fehlerfrei
  - Testergebnisse gelten als funktionale Referenz (Baseline)

3. Versionskontrolle
- Erstelle einen neuen Git-Branch nach folgendem Schema:
  refactoring-YYYY-MM-DD
- Der Branch wird ausschließlich für diesen Refactoring-Durchlauf verwendet.

4. Systematische Codeanalyse
- Analysiere den gesamten Codebestand auf:
  - Performance
  - Speicher- und Ressourcenverbrauch
  - Lesbarkeit
  - Wartbarkeit
  - Architektur- und Layer-Trennung
- Randbedingungen:
  - Keine funktionalen Änderungen
  - Zielannahme: ~5000 registrierte Nutzer, ~300 gleichzeitige Sessions
  - Fokus auf Stabilität, Skalierbarkeit und saubere Zustandsverwaltung

5. Priorisierung
- Identifiziere alle möglichen Optimierungs- und Refactoring-Maßnahmen.
- Bewerte jede Maßnahme nach:
  - Flutter Best Practices
  - Klarheit und Einfachheit
  - Langfristiger Wartbarkeit
- Wähle stets die fachlich sauberste und idiomatischste Flutter-Lösung.

6. Umsetzung
- Implementiere die Maßnahmen sequenziell.
- Jede logisch abgeschlossene Änderung erhält:
  - einen eigenen Commit
  - minimale, klar abgegrenzte Diff-Größe
- Keine Commits mit vermischten oder voneinander abhängigen Änderungen.

7. Validierung nach Refactoring
- Führe erneut `flutter analyze` aus.
- Führe den vollständigen Test-Suite-Durchlauf aus.
- Erwartung:
  - Alle Tests bestehen
  - Testergebnisse sind identisch zur Baseline
- Abweichungen gelten als funktionale Änderung und sind nicht zulässig.

8. Commit-Richtlinie
- Jeder Commit erhält eine präzise, KI-generierte Commit-Message.
- Format:
  - Imperativ
  - Kurzbeschreibung im Titel
  - Optionaler Body mit technischer Begründung
- Keine Sammel- oder „Cleanup“-Commits.

9. Abschlusszustand
- Code ist analysiert, optimiert und refaktoriert.
- Funktionalität unverändert und testverifiziert.
- Analyse-Status: fehlerfrei.
- Git-Historie: nachvollziehbar, linear, wartbar.

