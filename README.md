Projektstruktur (empfohlen)

/
├─ index.html
├─ css/
│  └─ styles.css
├─ js/
│  └─ app.js
├─ assets/
│  ├─ images/        (Bilder)
│  └─ fonts/         (falls lokal benötigt)
├─ flutter_brew_assistent/   (Flutter-Web-App "AiBrewGenius")
├─ rapt.html                 (RAPT API Explorer)
└─ proxy/                    (Node Proxy für OpenAI)

Kurzanleitung (Landing Page):
- Öffne index.html im Browser (lokal per Dateipfad oder lokalem Server).
- Styles liegen in css/styles.css, Skripte in js/app.js.
- Lege Bilder in assets/images/ ab und referenziere sie z.B. mit "assets/images/meinbild.jpg".

## Flutter + Proxy Setup

1. Proxy konfigurieren:
   - Kopiere `proxy/.env.example` nach `proxy/.env` und trage deinen `OPENAI_API_KEY` ein.
   - Optional: setze `CORS_ORIGIN` auf die URL, von der die Flutter-Web-App auf den Proxy zugreifen soll.
2. Proxy starten:
   ```bash
   cd proxy
   npm start   # nutzt node server.js
   ```
3. Flutter-Web-App konfigurieren:
- In `flutter_brew_assistent/.env` die Proxy-URL setzen, z.B. `PROXY_URL=http://localhost:3000/api/brew`.
4. Flutter lokal starten:
   ```bash
   cd flutter_brew_assistent
   flutter run -d chrome
   ```
5. Für Produktions-Deploy den Proxy auf dem Server laufen lassen und `PROXY_URL` auf die öffentliche AiBrewGenius-Proxy-URL setzen. Wenn du den Web-Build manuell erstellst, nutze `flutter build web --wasm --base-href /brew_app/`, damit alle Assets unter dem Unterpfad gefunden werden.

## Deployment via GitHub Actions

- Secrets benötigt:
  - `SSH_HOST`, `SSH_USER`, `SSH_KEY`, `SSH_PORT` (wie bisher)
  - `DEPLOY_PATH` (Root-Verzeichnis auf dem Server)
  - `OPENAI_API_KEY` (wird in `proxy/.env` geschrieben)
  - `PROXY_URL` (für Prod jetzt `https://alexstuder.run.place/api/brew`, landet in `flutter_brew_assistent/.env`)
  - `RAPT_API_KEY` & `RAPT_USERNAME` (für den RAPT Explorer; nur serverseitig genutzt)
- Öffentliche AiBrewGenius-Web-App: `https://alexstuder.run.place/brew_app/`
- RAPT API Explorer lokal via `rapt.html` oder live über deine Domain.
  - Enthält einen integrierten Token-Generator (`https://id.rapt.io/connect/token`), der deinen Benutzer/API-Key nutzt und den erhaltenen JWT automatisch als Bearer-Token einträgt.
  - Ruft automatisch `GetProfiles`, `GetHydrometers`, `GetTelemetry` ab und zeigt Token + Messwerte tabellarisch an.
- Öffentliche URL der Web-App: `https://alexstuder.run.place/brew_app/` (Landing-Page-Links zeigen dorthin).
  - Optional `CORS_ORIGIN` (bei Bedarf auf `https://alexstuder.run.place` setzen)
- Workflow-Schritte:
  1. Flutter `.env` mit `PROXY_URL` erzeugen, Build erstellen und nach `${DEPLOY_PATH}` hochladen.
     - Da die Web-App unter `/brew_app/` ausgeliefert wird, verwendet der Workflow automatisch `flutter build web --wasm --base-href /brew_app/`.
  2. Proxy-Verzeichnis nach `${DEPLOY_PATH}/proxy` syncen.
  3. Per SSH eine `.env` im Proxy-Ordner schreiben (`OPENAI_API_KEY` + optional `CORS_ORIGIN`).
- Auf dem Server muss ein Node-Prozess (z.B. systemd/pm2) `node proxy/server.js` im `proxy`-Ordner starten bzw. nach jedem Deploy neu starten. Der Workflow erzeugt nur Dateien; das Starten/Neustarten des Dienstes muss serverseitig konfiguriert sein.
