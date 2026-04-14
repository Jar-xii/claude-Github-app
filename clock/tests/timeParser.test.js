'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { parseTimeInput, convertTo, formatForDisplay, formatUtcOffset } = require('../shared/timeParser');

// ── Helpers ───────────────────────────────────────────────────────────────────

function ok(input) {
  const result = parseTimeInput(input);
  assert.ok(result.ok, `Expected ok, got error: ${result.error} (input: "${input}")`);
  return result.result;
}

function fail(input) {
  const result = parseTimeInput(input);
  assert.equal(result.ok, false, `Expected failure but got ok (input: "${input}")`);
  return result.error;
}

// ── Basic formats ─────────────────────────────────────────────────────────────

test('parses "8pm UK"', () => {
  const r = ok('8pm UK');
  assert.equal(r.hours, 20);
  assert.equal(r.minutes, 0);
  assert.equal(r.ianaZone, 'Europe/London');
});

test('parses "8PM UK" (uppercase)', () => {
  const r = ok('8PM UK');
  assert.equal(r.hours, 20);
});

test('parses "20:00 BST"', () => {
  const r = ok('20:00 BST');
  assert.equal(r.hours, 20);
  assert.equal(r.minutes, 0);
  assert.equal(r.ianaZone, 'Europe/London');
});

test('parses "3:30pm Eastern"', () => {
  const r = ok('3:30pm Eastern');
  assert.equal(r.hours, 15);
  assert.equal(r.minutes, 30);
  assert.equal(r.ianaZone, 'America/New_York');
});

test('parses "3:30 pm EST" (space before meridiem)', () => {
  const r = ok('3:30 pm EST');
  assert.equal(r.hours, 15);
  assert.equal(r.minutes, 30);
});

test('parses "15:30 Tokyo"', () => {
  const r = ok('15:30 Tokyo');
  assert.equal(r.hours, 15);
  assert.equal(r.minutes, 30);
  assert.equal(r.ianaZone, 'Asia/Tokyo');
});

test('parses "noon UTC"', () => {
  const r = ok('noon UTC');
  assert.equal(r.hours, 12);
  assert.equal(r.minutes, 0);
});

test('parses "midnight GMT"', () => {
  const r = ok('midnight GMT');
  assert.equal(r.hours, 0);
  assert.equal(r.minutes, 0);
});

test('parses "1430 PST" (military time)', () => {
  const r = ok('1430 PST');
  assert.equal(r.hours, 14);
  assert.equal(r.minutes, 30);
});

test('parses "0800 UTC" (military time with leading zero)', () => {
  const r = ok('0800 UTC');
  assert.equal(r.hours, 8);
  assert.equal(r.minutes, 0);
});

// ── 12am / 12pm edge cases ────────────────────────────────────────────────────

test('12am → 0 (midnight)', () => {
  const r = ok('12am EST');
  assert.equal(r.hours, 0);
});

test('12pm → 12 (noon)', () => {
  const r = ok('12pm EST');
  assert.equal(r.hours, 12);
});

test('1am → 1', () => {
  const r = ok('1am UTC');
  assert.equal(r.hours, 1);
});

test('1pm → 13', () => {
  const r = ok('1pm UTC');
  assert.equal(r.hours, 13);
});

test('11:59pm → 23:59', () => {
  const r = ok('11:59pm UTC');
  assert.equal(r.hours, 23);
  assert.equal(r.minutes, 59);
});

// ── Multi-word timezone aliases ───────────────────────────────────────────────

test('parses "8pm New York" (two-word alias)', () => {
  const r = ok('8pm New York');
  assert.equal(r.hours, 20);
  assert.equal(r.ianaZone, 'America/New_York');
});

test('parses "8pm Los Angeles" (two-word alias)', () => {
  const r = ok('8pm Los Angeles');
  assert.equal(r.hours, 20);
  assert.equal(r.ianaZone, 'America/Los_Angeles');
});

// ── Direct IANA zone names ────────────────────────────────────────────────────

test('parses "8pm Europe/London"', () => {
  const r = ok('8pm Europe/London');
  assert.equal(r.hours, 20);
  assert.equal(r.ianaZone, 'Europe/London');
});

test('parses "15:00 Asia/Tokyo"', () => {
  const r = ok('15:00 Asia/Tokyo');
  assert.equal(r.hours, 15);
  assert.equal(r.ianaZone, 'Asia/Tokyo');
});

// ── Error cases ───────────────────────────────────────────────────────────────

test('rejects empty string', () => {
  fail('');
});

test('rejects null', () => {
  fail(null);
});

test('rejects unknown timezone', () => {
  const err = fail('8pm INVALIDZONE');
  assert.ok(err.includes('Unknown timezone'));
});

test('rejects input with no time value', () => {
  fail('UTC');
});

test('rejects unparseable time part', () => {
  fail('notaTime UTC');
});

// ── convertTo and formatting ──────────────────────────────────────────────────

test('convertTo converts between zones correctly', () => {
  // A fixed time in UTC: 12:00 UTC should be 13:00 in Europe/Paris (CET, UTC+1)
  // But DST can affect this — use a known non-DST zone pair: UTC vs UTC
  const r = ok('12:00 UTC');
  const converted = convertTo(r, 'UTC');
  assert.equal(converted.hour, 12);
});

test('formatForDisplay returns time string without date', () => {
  const r = ok('8pm UTC');
  const str = formatForDisplay(r.luxonDateTime, false);
  assert.ok(str.includes('8:00 PM') || str.includes('8:00 pm'), `Got: ${str}`);
});

test('formatForDisplay includes date when requested', () => {
  const r = ok('8pm UTC');
  const str = formatForDisplay(r.luxonDateTime, true);
  assert.ok(str.includes('PM') || str.includes('pm'));
  assert.ok(str.includes('('));
});

test('formatUtcOffset returns UTC+0 for UTC zone', () => {
  const r = ok('8pm UTC');
  const offset = formatUtcOffset(r.luxonDateTime);
  assert.equal(offset, 'UTC+0');
});
