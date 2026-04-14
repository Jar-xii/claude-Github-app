'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const path = require('path');

// Use a temporary in-memory DB for tests
process.env.DB_PATH = ':memory:';
process.env.PORT = '0'; // random port

let server;
let baseUrl;

before(async () => {
  // Import app after setting env vars
  const app = require('../web/server');
  await new Promise(resolve => {
    server = app.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://localhost:${port}`;
      resolve();
    });
  });
});

after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
});

// ── HTTP helpers ──────────────────────────────────────────────────────────────

function get(path) {
  return new Promise((resolve, reject) => {
    http.get(`${baseUrl}${path}`, res => {
      let body = '';
      res.on('data', d => body += d);
      res.on('end', () => {
        resolve({ status: res.statusCode, body: JSON.parse(body) });
      });
    }).on('error', reject);
  });
}

function post(path, data) {
  return new Promise((resolve, reject) => {
    const json = JSON.stringify(data);
    const req = http.request(`${baseUrl}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(json) },
    }, res => {
      let body = '';
      res.on('data', d => body += d);
      res.on('end', () => {
        resolve({ status: res.statusCode, body: JSON.parse(body) });
      });
    });
    req.on('error', reject);
    req.write(json);
    req.end();
  });
}

// ── Tests ─────────────────────────────────────────────────────────────────────

test('GET /api/health returns ok', async () => {
  const { status, body } = await get('/api/health');
  assert.equal(status, 200);
  assert.equal(body.ok, true);
  assert.ok(typeof body.ts === 'number');
});

test('GET /api/aliases returns alias map with expected keys', async () => {
  const { status, body } = await get('/api/aliases');
  assert.equal(status, 200);
  assert.ok(typeof body.aliases === 'object');
  assert.ok('UK' in body.aliases);
  assert.ok('EST' in body.aliases);
  assert.ok('TOKYO' in body.aliases);
});

test('POST /api/convert with "8pm UK" returns correct conversion', async () => {
  const { status, body } = await post('/api/convert', { timeString: '8pm UK' });
  assert.equal(status, 200);
  assert.equal(body.ok, true);
  assert.ok(body.original);
  assert.equal(body.original.zone, 'Europe/London');
  assert.ok(body.original.time.includes('8:00 PM') || body.original.time.includes('8:00 pm'));
  assert.ok(typeof body.original.isoString === 'string');
});

test('POST /api/convert with targetZone returns converted time', async () => {
  const { status, body } = await post('/api/convert', {
    timeString: '12:00 UTC',
    targetZone: 'UTC',
  });
  assert.equal(status, 200);
  assert.equal(body.ok, true);
  assert.ok(body.converted);
  assert.equal(body.converted.zone, 'UTC');
});

test('POST /api/convert with garbage input returns 400', async () => {
  const { status, body } = await post('/api/convert', { timeString: 'notaTime FAKEZONE' });
  assert.equal(status, 400);
  assert.equal(body.ok, false);
  assert.ok(typeof body.error === 'string');
});

test('POST /api/convert with missing timeString returns 400', async () => {
  const { status, body } = await post('/api/convert', {});
  assert.equal(status, 400);
  assert.equal(body.ok, false);
});

test('POST /api/timezone saves and GET retrieves it', async () => {
  const saveResp = await post('/api/timezone', {
    userId: 'testuser1',
    platform: 'web',
    ianaZone: 'Europe/London',
  });
  assert.equal(saveResp.status, 200);
  assert.equal(saveResp.body.ok, true);

  const getResp = await get('/api/timezone/testuser1?platform=web');
  assert.equal(getResp.status, 200);
  assert.equal(getResp.body.ianaZone, 'Europe/London');
});

test('POST /api/timezone with invalid IANA zone returns 400', async () => {
  const { status, body } = await post('/api/timezone', {
    userId: 'testuser2',
    platform: 'web',
    ianaZone: 'NotA/Zone',
  });
  assert.equal(status, 400);
  assert.equal(body.ok, false);
});

test('GET /api/timezone for unknown user returns 404', async () => {
  const { status, body } = await get('/api/timezone/nobody-xyz?platform=web');
  assert.equal(status, 404);
  assert.equal(body.ok, false);
});

test('GET /api/convert with valid ISO timestamp returns ok', async () => {
  const iso = encodeURIComponent(new Date().toISOString());
  const { status, body } = await get(`/api/convert?t=${iso}`);
  assert.equal(status, 200);
  assert.equal(body.ok, true);
  assert.ok(body.original);
});

test('GET /api/convert with invalid ISO returns 400', async () => {
  const { status, body } = await get('/api/convert?t=notaniso');
  assert.equal(status, 400);
  assert.equal(body.ok, false);
});
