'use strict';

const { Router } = require('express');
const { z } = require('zod');
const { IANAZone } = require('luxon');
const { ALIASES } = require('../../shared/timezoneAliases');
const { parseTimeInput, convertTo, formatForDisplay, formatUtcOffset } = require('../../shared/timeParser');
const { getTimezone, setTimezone, getAllTimezones } = require('../../bot/database');

const router = Router();

// ── Zod schemas ───────────────────────────────────────────────────────────────

const ianaZoneString = z
  .string()
  .min(1)
  .refine(tz => IANAZone.isValidZone(tz), { message: 'Invalid IANA timezone' });

const setTimezoneSchema = z.object({
  userId:   z.string().min(1).max(64).default('local'),
  platform: z.enum(['discord', 'web']).default('web'),
  ianaZone: ianaZoneString,
});

const convertSchema = z.object({
  timeString: z.string().min(1),
  targetZone: ianaZoneString.optional(),
});

// ── Helper ────────────────────────────────────────────────────────────────────

function buildConvertResponse(parsedResult, targetZone) {
  const { luxonDateTime, ianaZone, originalInput } = parsedResult;
  const targetDt = targetZone ? convertTo(parsedResult, targetZone) : luxonDateTime;

  return {
    original: {
      time:      formatForDisplay(luxonDateTime, true),
      zone:      ianaZone,
      utcOffset: formatUtcOffset(luxonDateTime),
      isoString: luxonDateTime.toISO(),
    },
    converted: targetZone
      ? {
          time:      formatForDisplay(targetDt, true),
          zone:      targetZone,
          utcOffset: formatUtcOffset(targetDt),
          isoString: targetDt.toISO(),
        }
      : null,
  };
}

// ── Routes ────────────────────────────────────────────────────────────────────

// GET /api/health
router.get('/health', (_req, res) => {
  res.json({ ok: true, ts: Date.now() });
});

// GET /api/aliases — full alias map for frontend autocomplete
router.get('/aliases', (_req, res) => {
  res.json({ aliases: ALIASES });
});

// POST /api/timezone — save user's timezone
router.post('/timezone', (req, res) => {
  const result = setTimezoneSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ ok: false, error: result.error.issues[0].message });
  }

  const { userId, platform, ianaZone } = result.data;
  setTimezone(userId, platform, ianaZone);
  res.json({ ok: true, ianaZone });
});

// GET /api/timezone/:userId — get a user's stored timezone
router.get('/timezone/:userId', (req, res) => {
  const { userId } = req.params;
  const platform = req.query.platform || 'web';
  const row = getTimezone(userId, platform);

  if (!row) return res.status(404).json({ ok: false, error: 'No timezone set' });
  res.json({ ok: true, ianaZone: row.iana_zone });
});

// POST /api/convert — convert a time string
router.post('/convert', (req, res) => {
  const result = convertSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ ok: false, error: result.error.issues[0].message });
  }

  const { timeString, targetZone } = result.data;
  const parsed = parseTimeInput(timeString);

  if (!parsed.ok) {
    return res.status(400).json({ ok: false, error: parsed.error });
  }

  res.json({ ok: true, ...buildConvertResponse(parsed.result, targetZone) });
});

// GET /api/convert — convert via query params (for shareable links)
// ?t=<iso8601>&tz=<targetIanaZone>
router.get('/convert', (req, res) => {
  const { t, tz } = req.query;

  if (!t) {
    return res.status(400).json({ ok: false, error: 'Missing ?t= ISO timestamp parameter' });
  }

  const { DateTime } = require('luxon');
  const dt = DateTime.fromISO(t);

  if (!dt.isValid) {
    return res.status(400).json({ ok: false, error: `Invalid ISO timestamp: ${dt.invalidReason}` });
  }

  if (tz && !IANAZone.isValidZone(tz)) {
    return res.status(400).json({ ok: false, error: `Invalid target timezone: ${tz}` });
  }

  const targetDt = tz ? dt.setZone(tz) : dt;

  res.json({
    ok: true,
    original: {
      time:      formatForDisplay(dt, true),
      zone:      dt.zoneName,
      utcOffset: formatUtcOffset(dt),
      isoString: dt.toISO(),
    },
    converted: tz
      ? {
          time:      formatForDisplay(targetDt, true),
          zone:      tz,
          utcOffset: formatUtcOffset(targetDt),
          isoString: targetDt.toISO(),
        }
      : null,
  });
});

module.exports = router;
