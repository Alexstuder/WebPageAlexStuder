const http = require('http');
const { URL } = require('url');
const fs = require('fs');
const path = require('path');

const BASE_PATH = __dirname;
const LOCAL_ENV = process.env.PROXY_ENV ?? path.join(BASE_PATH, '.env');

loadEnvFile(LOCAL_ENV);

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const PORT = Number(process.env.PORT ?? 3000);
const ALLOWED_ORIGIN = process.env.CORS_ORIGIN ?? '*';

if (!OPENAI_API_KEY) {
  console.error('OPENAI_API_KEY is not set. Provide it via environment variable or proxy/.env file.');
  process.exit(1);
}

const server = http.createServer(async (req, res) => {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === '/api/brew' && req.method === 'POST') {
    await handleBrewRequest(req, res);
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(PORT, () => {
  console.log(`Proxy listening on http://localhost:${PORT}`);
});

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

async function handleBrewRequest(req, res) {
  try {
    const body = await readBody(req);
    const data = JSON.parse(body || '{}');
    const prompt = typeof data.prompt === 'string' ? data.prompt.trim() : '';

    if (!prompt) {
      respondJson(res, 400, { error: 'Prompt is required.' });
      return;
    }

    const openAiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'Du bist ein erfahrener Braumeister. Erstelle strukturierte Bierrezepte mit Zutatenliste, Brauschritten und optionalen Varianten.',
          },
          {
            role: 'user',
            content: `Erstelle ein Bier-Rezept basierend auf: ${prompt}`,
          },
        ],
        temperature: 0.7,
      }),
    });

    const payload = await openAiResponse.json();

    if (!openAiResponse.ok) {
      respondJson(res, openAiResponse.status, payload);
      return;
    }

    const content = payload?.choices?.[0]?.message?.content;

    if (!content || typeof content !== 'string') {
      respondJson(res, 502, { error: 'Antwort von OpenAI unvollständig.' });
      return;
    }

    respondJson(res, 200, { result: content.trim() });
  } catch (error) {
    console.error('Proxy error:', error);
    respondJson(res, 500, { error: 'Interner Proxy-Fehler.' });
  }
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => {
      data += chunk;
      if (data.length > 1e6) {
        req.socket.destroy();
        reject(new Error('Request body too large'));
      }
    });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

function respondJson(res, statusCode, payload) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(payload));
}

function loadEnvFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    content
      .split('\n')
      .map(line => line.trim())
      .filter(line => line && !line.startsWith('#'))
      .forEach(line => {
        const idx = line.indexOf('=');
        if (idx === -1) return;
        const key = line.slice(0, idx).trim();
        const value = line.slice(idx + 1).trim();
        if (!process.env[key]) {
          process.env[key] = value;
        }
      });
  } catch (error) {
    if (process.env.NODE_ENV !== 'production') {
      console.warn(`No env file loaded at ${filePath}`);
    }
  }
}
