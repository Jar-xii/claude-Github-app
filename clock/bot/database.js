'use strict';

const path = require('path');
const fs = require('fs');

let db = null;

/**
 * Returns the SQLite database instance, initialising it on first call.
 * Creates the data directory and applies the schema if needed.
 * Enables WAL mode so the web server and bot can run concurrently.
 *
 * @returns {import('better-sqlite3').Database}
 */
function getDb() {
  if (db) return db;

  const Database = require('better-sqlite3');
  const dbPath = process.env.DB_PATH
    ? path.resolve(process.cwd(), process.env.DB_PATH)
    : path.resolve(__dirname, '../data/timezones.db');

  // Ensure the directory exists
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });

  db = new Database(dbPath);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');

  // Apply schema
  const schemaPath = path.resolve(__dirname, '../db/schema.sql');
  const schema = fs.readFileSync(schemaPath, 'utf8');
  db.exec(schema);

  return db;
}

/**
 * Get a user's stored timezone.
 * @param {string} userId
 * @param {'discord'|'web'} platform
 * @returns {{ iana_zone: string, display_name: string|null } | null}
 */
function getTimezone(userId, platform) {
  const row = getDb()
    .prepare('SELECT iana_zone, display_name FROM user_timezones WHERE user_id = ? AND platform = ?')
    .get(userId, platform);
  return row || null;
}

/**
 * Set (upsert) a user's timezone.
 * @param {string} userId
 * @param {'discord'|'web'} platform
 * @param {string} ianaZone
 * @param {string|null} [displayName]
 */
function setTimezone(userId, platform, ianaZone, displayName = null) {
  getDb()
    .prepare(`
      INSERT INTO user_timezones (user_id, platform, iana_zone, display_name, updated_at)
      VALUES (?, ?, ?, ?, unixepoch())
      ON CONFLICT(user_id, platform) DO UPDATE SET
        iana_zone    = excluded.iana_zone,
        display_name = excluded.display_name,
        updated_at   = unixepoch()
    `)
    .run(userId, platform, ianaZone, displayName);
}

/**
 * Get all registered timezones for a platform.
 * @param {'discord'|'web'} platform
 * @returns {Array<{ user_id: string, iana_zone: string, display_name: string|null }>}
 */
function getAllTimezones(platform) {
  return getDb()
    .prepare('SELECT user_id, iana_zone, display_name FROM user_timezones WHERE platform = ? ORDER BY display_name, user_id')
    .all(platform);
}

/**
 * Remove a user's timezone entry.
 * @param {string} userId
 * @param {'discord'|'web'} platform
 */
function deleteTimezone(userId, platform) {
  getDb()
    .prepare('DELETE FROM user_timezones WHERE user_id = ? AND platform = ?')
    .run(userId, platform);
}

module.exports = { getDb, getTimezone, setTimezone, getAllTimezones, deleteTimezone };
