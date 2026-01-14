# Upgrade Workflow
- Wenn ich "Upgrade" sage, führe folgende Schritte aus:
  1. Aktualisiere die Supabase CLI via brew: `brew upgrade supabase/tap/supabase`.
  2. Aktualisiere das Flutter SDK: `flutter upgrade`.
  3. Aktualisiere die Projekt-Abhängigkeiten: `cd flutter_brew_assistent && flutter pub upgrade`.
  4. Starte die lokale Supabase-Instanz neu, um Image-Updates zu laden: `supabase stop` gefolgt von `supabase start`.
  5. Führe danach den kompletten "Deployment Workflow" (siehe oben) aus, um die Änderungen zu validieren und auf den VPS zu bringen.