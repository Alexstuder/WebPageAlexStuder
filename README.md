Projektstruktur (empfohlen)

/
├─ index.html
├─ css/
│  └─ styles.css
├─ js/
│  └─ app.js
├─ WegPages/
│  ├─ bier/
│  │  └─ index.html
│  ├─ brew_app/
│  │  └─ index.html
│  ├─ quiz/
│  │  └─ index.html
│  ├─ rapt/
│  │  ├─ index.html
│  │  ├─ table/
│  │  │  └─ index.html
│  │  └─ token/
│  │     └─ index.html
│  ├─ sudoku/
│  │  └─ index.html
│  └─ todo/
│     └─ index.html
├─ assets/
│  ├─ images/        (Bilder)
│  └─ fonts/         (falls lokal benötigt)
├─ flutter_brew_assistent/   (Flutter-Web-App "AiBrewGenius")
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

### RAPT Seiten lokal testen

1. Proxy vorbereiten und starten:
   ```bash
   npm run proxy:dev
   ```
   Der Root-Befehl startet intern `scripts/dev-proxy.sh`, installiert fehlende Dependencies automatisch und fährt anschließend den Server hoch (Standard: `http://localhost:3000`, Endpunkte `/api/rapt/*`). Alternativ: `npm run proxy:watch`, um direkt `nodemon` im `proxy`-Ordner zu nutzen, falls alles bereits installiert ist.
2. Öffne `WegPages/rapt/`, `WegPages/rapt/table/` oder `WegPages/rapt/token/` (Dateipfad oder beliebiger lokaler Webserver). Die Seiten erkennen automatisch, dass sie lokal laufen, und rufen die API über `http://localhost:3000` auf. Dadurch verschwindet das 404 aus rein statischen Servern wie `python -m http.server`.
3. Falls du einen anderen Proxy-Port oder eine externe URL nutzen willst, setze einmalig im Browser die Basis per Konsole:
   ```js
   localStorage.setItem('API_BASE_URL', 'http://dein-host:4000');
   ```
   oder hänge während der Sitzung `window.API_BASE_URL='https://example.com';` vor den Seitenaufruf. Entferne den Eintrag mit `localStorage.removeItem('API_BASE_URL')`, um wieder die automatische Erkennung zu verwenden.

## Deployment via GitHub Actions

- Secrets benötigt:
  - `SSH_HOST`, `SSH_USER`, `SSH_KEY`, `SSH_PORT` (wie bisher)
  - `DEPLOY_PATH` (Root-Verzeichnis auf dem Server)
  - `OPENAI_API_KEY` (wird in `proxy/.env` geschrieben)
  - `PROXY_URL` (für Prod jetzt `https://alexstuder.run.place/api/brew`, landet in `flutter_brew_assistent/.env`)
  - `RAPT_API_KEY` & `RAPT_USERNAME` (für den RAPT Explorer; nur serverseitig genutzt)
- Öffentliche AiBrewGenius-Web-App: `https://alexstuder.run.place/brew_app/`
- RAPT API Explorer lokal via `WegPages/rapt/` oder live über deine Domain.
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
