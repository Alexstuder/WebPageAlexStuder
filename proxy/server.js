const http = require('http');
const { URL } = require('url');
const fs = require('fs');
const path = require('path');

const BASE_PATH = __dirname;
const LOCAL_ENV = process.env.PROXY_ENV ?? path.join(BASE_PATH, '.env');

loadEnvFile(LOCAL_ENV);

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const RAPT_USERNAME = process.env.RAPT_USERNAME;
const RAPT_API_KEY = process.env.RAPT_API_KEY;
const RAPT_TOKEN_ENDPOINT = process.env.RAPT_TOKEN_ENDPOINT ?? 'https://id.rapt.io/connect/token';
const RAPT_API_BASE = process.env.RAPT_API_BASE ?? 'https://api.rapt.io';
const RAPT_PROFILE_ENDPOINT = process.env.RAPT_PROFILE_ENDPOINT ?? '/api/Profiles/GetProfiles';
const RAPT_HYDR_ENDPOINT = process.env.RAPT_HYDR_ENDPOINT ?? '/api/Hydrometers/GetHydrometers';
const RAPT_TELEMETRY_ENDPOINT = process.env.RAPT_TELEMETRY_ENDPOINT ?? '/api/Hydrometers/GetTelemetry';
const PORT = Number(process.env.PORT ?? 3000);
const CACHE_INTERVAL_MS = Number(process.env.RAPT_CACHE_INTERVAL_MS ?? 60 * 60 * 1000);
const ALLOWED_ORIGIN = process.env.CORS_ORIGIN ?? '*';

if (!OPENAI_API_KEY) {
  console.error('OPENAI_API_KEY is not set. Provide it via environment variable or proxy/.env file.');
  process.exit(1);
}

let telemetryCache = null;
let telemetryCacheTimestamp = 0;
let telemetryCachePromise = null;

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
  if (url.pathname === '/api/rapt/token' && req.method === 'POST') {
    await handleRaptTokenRequest(res);
    return;
  }
  if (url.pathname === '/api/rapt/profiles' && req.method === 'GET') {
    await handleRaptProfilesRequest(res);
    return;
  }
  if (url.pathname === '/api/rapt/telemetry' && req.method === 'GET') {
    await handleRaptTelemetryRequest(req, res);
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(PORT, () => {
  console.log(`Proxy listening on http://localhost:${PORT}`);
  ensureTelemetryCache(true).catch(err => {
    console.error('Initial telemetry preload failed:', err.message || err);
  });
  setInterval(() => {
    ensureTelemetryCache(true).catch(err => {
      console.error('Scheduled telemetry refresh failed:', err.message || err);
    });
  }, CACHE_INTERVAL_MS);
});

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

async function handleBrewRequest(req, res) {
  try {
    const body = await readBody(req);
    const data = JSON.parse(body || '{}');
    const prompt = typeof data.prompt === 'string' ? data.prompt.trim() : '';
    const rawImage = data && typeof data === 'object' ? data.image : null;
    const imageBase64 =
      rawImage && typeof rawImage === 'object' && typeof rawImage.data === 'string'
        ? rawImage.data
        : null;
    const imageMime =
      rawImage && typeof rawImage === 'object' && typeof rawImage.mime_type === 'string'
        ? rawImage.mime_type
        : null;

    if (!prompt) {
      respondJson(res, 400, { error: 'Prompt is required.' });
      return;
    }

    const userContent = [
      {
        type: 'input_text',
        text: prompt,
      },
    ];

    if (imageBase64 && imageMime) {
      userContent.push({
        type: 'input_image',
        image_url: `data:${imageMime};base64,${imageBase64}`,
      });
    }

    const openAiResponse = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || 'gpt-5.1',
        input: [
          {
            role: 'system',
            content: [
              {
                type: 'input_text',
                text: 'Du bist ein erfahrener Braumeister. Erstelle strukturierte Bierrezepte mit Zutatenliste, Brauschritten und optionalen Varianten. Wenn der Nutzer ein Foto mitsendet, nutze die visuellen Hinweise aus dem Bild für deine Empfehlung.',
              },
            ],
          },
          {
            role: 'user',
            content: userContent,
          },
        ],
        temperature: 0.7,
      }),
    });

    const payload = await openAiResponse.json();

    if (!openAiResponse.ok) {
      console.error('OpenAI API error:', openAiResponse.status, payload);
      respondJson(res, openAiResponse.status, {
        error: payload?.error?.message || payload?.error || 'OpenAI API request failed.',
        details: payload,
      });
      return;
    }

    const content = extractResponseText(payload);

    if (!content) {
      respondJson(res, 502, { error: 'Antwort von OpenAI unvollständig.', payload });
      return;
    }

    respondJson(res, 200, { result: content.trim() });
  } catch (error) {
    console.error('Proxy error:', error);
    respondJson(res, 500, { error: 'Interner Proxy-Fehler.' });
  }
}

function extractResponseText(payload) {
  if (!payload || typeof payload !== 'object') return '';
  const textParts = [];
  const outputs = Array.isArray(payload.output) ? payload.output : [];
  outputs.forEach(item => {
    if (!item) return;
    if (item.type === 'message' && Array.isArray(item.content)) {
      item.content.forEach(block => {
        if (block?.type === 'output_text' && typeof block.text === 'string') {
          textParts.push(block.text);
        }
      });
    } else if (typeof item.text === 'string') {
      textParts.push(item.text);
    }
  });
  if (textParts.length === 0) {
    const fallback = payload.output_text;
    if (typeof fallback === 'string') {
      textParts.push(fallback);
    } else if (Array.isArray(fallback)) {
      fallback.forEach(entry => {
        if (typeof entry === 'string') {
          textParts.push(entry);
        }
      });
    }
  }
  return textParts.join('\n').trim();
}

async function handleRaptTokenRequest(res) {
  if (!RAPT_USERNAME || !RAPT_API_KEY) {
    respondJson(res, 500, { error: 'RAPT credentials not configured.' });
    return;
  }
  try {
    const tokenData = await requestRaptToken();
    respondJson(res, 200, tokenData);
  } catch (error) {
    console.error('RAPT token error:', error);
    const status = error.statusCode ?? 500;
    respondJson(res, status, { error: error.message ?? 'RAPT token request failed.' });
  }
}

async function handleRaptProfilesRequest(res) {
  if (!RAPT_USERNAME || !RAPT_API_KEY) {
    respondJson(res, 500, { error: 'RAPT credentials not configured.' });
    return;
  }
  try {
    const token = await requestRaptToken();
    if (!token?.access_token) {
      respondJson(res, 502, { error: 'Token response invalid.' });
      return;
    }
    const base = RAPT_API_BASE.replace(/\/$/, '');
    const apiResponse = await fetch(`${base}${RAPT_PROFILE_ENDPOINT}`, {
      headers: {
        'Authorization': `Bearer ${token.access_token}`,
        'Accept': 'application/json',
      },
    });
    const payload = await apiResponse.json().catch(() => ({}));
    if (!apiResponse.ok) {
      respondJson(res, apiResponse.status, payload);
      return;
    }
    respondJson(res, 200, payload);
  } catch (error) {
    console.error('RAPT devices error:', error);
    const status = error.statusCode ?? 500;
    respondJson(res, status, { error: error.message ?? 'RAPT devices request failed.' });
  }
}

async function handleRaptTelemetryRequest(req, res) {
  if (!RAPT_USERNAME || !RAPT_API_KEY) {
    respondJson(res, 500, { error: 'RAPT credentials not configured.' });
    return;
  }
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const forceReload = ['1', 'true'].includes((url.searchParams.get('reload') || '').toLowerCase());
    const data = await ensureTelemetryCache(forceReload);
    respondJson(res, 200, data);
  } catch (error) {
    console.error('RAPT telemetry error:', error);
    const status = error.statusCode ?? 500;
    respondJson(res, status, { error: error.message ?? 'RAPT telemetry request failed.' });
  }
}

async function requestRaptToken() {
  const body = new URLSearchParams({
    client_id: 'rapt-user',
    grant_type: 'password',
    username: RAPT_USERNAME,
    password: RAPT_API_KEY,
  });

  const response = await fetch(RAPT_TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(data.error_description || data.error || 'Failed to fetch RAPT token.');
    error.statusCode = response.status;
    throw error;
  }
  return data;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', chunk => {
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString()));
    req.on('error', reject);
  });
}

function respondJson(res, statusCode, payload) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(payload));
}

async function ensureTelemetryCache(force = false) {
  const cacheAge = Date.now() - telemetryCacheTimestamp;
  if (force || !telemetryCache) {
    if (!telemetryCachePromise) {
      telemetryCachePromise = refreshTelemetryCache().finally(() => {
        telemetryCachePromise = null;
      });
    }
    return telemetryCachePromise;
  }
  if (cacheAge > CACHE_INTERVAL_MS) {
    refreshTelemetryCache().catch(err => {
      console.error('Background telemetry refresh failed:', err.message || err);
    });
  }
  return telemetryCache;
}

async function refreshTelemetryCache() {
  if (!RAPT_USERNAME || !RAPT_API_KEY) {
    throw new Error('RAPT credentials not configured.');
  }

  const token = await requestRaptToken();
  if (!token?.access_token) {
    const err = new Error('Token response invalid.');
    err.statusCode = 502;
    throw err;
  }

  const base = RAPT_API_BASE.replace(/\/$/, '');
  const hydromRes = await fetch(`${base}${RAPT_HYDR_ENDPOINT}`, {
    headers: {
      'Authorization': `Bearer ${token.access_token}`,
      'Accept': 'application/json',
    },
  });
  const hydromData = await hydromRes.json().catch(() => []);
  if (!hydromRes.ok) {
    const err = new Error('Hydrometer response invalid.');
    err.statusCode = hydromRes.status;
    err.details = hydromData;
    throw err;
  }

  const hydrometers = Array.isArray(hydromData) ? hydromData : [];
  const nowIso = new Date().toISOString();
  const rows = [];
  let firstProfileName = null;

  for (const hydrometer of hydrometers) {
    const hydrometerId =
      hydrometer?.hydrometerId ||
      hydrometer?.HydrometerId ||
      hydrometer?.id ||
      hydrometer?.Id;
    const startDate =
      hydrometer?.activeProfileSession?.startDate ||
      hydrometer?.activeProfileSession?.StartDate;
    const profileName = hydrometer?.activeProfileSession?.name || null;

    if (!hydrometerId) {
      rows.push({
        hydrometerId: '(unbekannt)',
        error: 'Hydrometer ohne gültige ID im Response.',
      });
      continue;
    }

    if (!startDate) {
      rows.push({
        hydrometerId,
        error: 'Kein Startdatum in activeProfileSession gefunden.',
      });
      continue;
    }

    if (!firstProfileName && profileName) {
      firstProfileName = profileName;
    }

    const telemetryUrl = new URL(`${base}${RAPT_TELEMETRY_ENDPOINT}`);
    telemetryUrl.searchParams.set('hydrometerId', hydrometerId);
    telemetryUrl.searchParams.set('startDate', startDate);
    telemetryUrl.searchParams.set('endDate', nowIso);

    const teleRes = await fetch(telemetryUrl, {
      headers: {
        'Authorization': `Bearer ${token.access_token}`,
        'Accept': 'application/json',
      },
    });
    const teleData = await teleRes.json().catch(() => []);
    if (!teleRes.ok) {
      rows.push({
        hydrometerId,
        error: teleData,
      });
      continue;
    }

    const entries = Array.isArray(teleData) ? teleData : [teleData];
    for (const entry of entries) {
        rows.push({
          hydrometerId,
          startDate: entry?.startDate || entry?.StartDate || startDate || null,
          createdOn: entry?.createdOn || entry?.CreatedOn || null,
          temperature: entry?.temperature ?? entry?.Temperature ?? null,
          gravity: entry?.gravity ?? entry?.Gravity ?? null,
          gravityVelocity: entry?.gravityVelocity ?? entry?.GravityVelocity ?? null,
          battery: entry?.battery ?? entry?.Battery ?? null,
          macAddress: entry?.macAddress || entry?.MacAddress || null,
          profileName,
        });
    }
  }

  rows.sort((a, b) => {
    const da = new Date(a.startDate || 0).getTime();
    const db = new Date(b.startDate || 0).getTime();
    return da - db;
  });

  const firstStart = rows[0]?.startDate || null;
  telemetryCache = {
    rows,
    generatedAt: nowIso,
    startDate: firstStart,
    endDate: nowIso,
    profileName: firstProfileName,
  };
  telemetryCacheTimestamp = Date.now();
  return telemetryCache;
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
