'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { resolveAlias, searchAliases, ALIASES } = require('../shared/timezoneAliases');

test('resolves UK to Europe/London', () => {
  assert.equal(resolveAlias('UK'), 'Europe/London');
});

test('is case-insensitive', () => {
  assert.equal(resolveAlias('uk'),   'Europe/London');
  assert.equal(resolveAlias('Uk'),   'Europe/London');
  assert.equal(resolveAlias('TOKYO'), 'Asia/Tokyo');
  assert.equal(resolveAlias('tokyo'), 'Asia/Tokyo');
});

test('handles leading/trailing whitespace', () => {
  assert.equal(resolveAlias('  UK  '), 'Europe/London');
});

test('resolves BST to Europe/London (geographic zone for correct DST)', () => {
  assert.equal(resolveAlias('BST'), 'Europe/London');
});

test('resolves EST to America/New_York', () => {
  assert.equal(resolveAlias('EST'), 'America/New_York');
});

test('resolves PST to America/Los_Angeles', () => {
  assert.equal(resolveAlias('PST'), 'America/Los_Angeles');
});

test('resolves IST to Asia/Kolkata (documented ambiguity)', () => {
  assert.equal(resolveAlias('IST'), 'Asia/Kolkata');
});

test('resolves CST to America/Chicago (not China)', () => {
  assert.equal(resolveAlias('CST'), 'America/Chicago');
});

test('resolves CHINA to Asia/Shanghai (explicit alias)', () => {
  assert.equal(resolveAlias('CHINA'), 'Asia/Shanghai');
});

test('resolves AST to Asia/Dubai (documented ambiguity)', () => {
  assert.equal(resolveAlias('AST'), 'Asia/Dubai');
});

test('resolves HALIFAX to America/Halifax (explicit Atlantic alias)', () => {
  assert.equal(resolveAlias('HALIFAX'), 'America/Halifax');
});

test('resolves UTC to UTC', () => {
  assert.equal(resolveAlias('UTC'), 'UTC');
});

test('resolves GMT to UTC', () => {
  assert.equal(resolveAlias('GMT'), 'UTC');
});

test('resolves TOKYO to Asia/Tokyo', () => {
  assert.equal(resolveAlias('TOKYO'), 'Asia/Tokyo');
});

test('resolves JST to Asia/Tokyo', () => {
  assert.equal(resolveAlias('JST'), 'Asia/Tokyo');
});

test('resolves SYDNEY to Australia/Sydney', () => {
  assert.equal(resolveAlias('SYDNEY'), 'Australia/Sydney');
});

test('accepts direct IANA zone names as passthrough', () => {
  assert.equal(resolveAlias('Europe/London'),           'Europe/London');
  assert.equal(resolveAlias('America/New_York'),        'America/New_York');
  assert.equal(resolveAlias('Asia/Tokyo'),              'Asia/Tokyo');
  assert.equal(resolveAlias('Australia/Sydney'),        'Australia/Sydney');
  assert.equal(resolveAlias('America/Argentina/Buenos_Aires'), 'America/Argentina/Buenos_Aires');
});

test('returns null for unknown aliases', () => {
  assert.equal(resolveAlias('FAKEPLACE'), null);
  assert.equal(resolveAlias('XYZ123'),    null);
  assert.equal(resolveAlias(''),          null);
  assert.equal(resolveAlias(null),        null);
});

test('searchAliases returns matches for prefix', () => {
  const results = searchAliases('TO');
  assert.ok(results.some(r => r.alias === 'TOKYO'));
});

test('searchAliases returns up to 25 results', () => {
  const results = searchAliases('');
  assert.ok(results.length <= 25);
});

test('searchAliases returns empty array for non-matching prefix', () => {
  const results = searchAliases('ZZZZZ');
  assert.equal(results.length, 0);
});

test('ALIASES object is exported and contains expected keys', () => {
  assert.ok(typeof ALIASES === 'object');
  assert.ok('UK' in ALIASES);
  assert.ok('EST' in ALIASES);
  assert.ok('TOKYO' in ALIASES);
});
