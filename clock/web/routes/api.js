'use strict';

const { Router }   = require('express');
const { z }        = require('zod');
const { DateTime, IANAZone } = require('luxon');
const { ALIASES }  = require('../../shared/timezoneAliases');
const { parseTimeInput, convertTo, formatForDisplay, formatUtcOffset } = require('../../shared/timeParser');
const { getTimezone, setTimezone } = require('../../bot/database');

const router = Router();

// ── Zod schemas ───────────────────────────────────────────────────────────────

const ianaZoneStr = z
  .string()
  .min(1)
  .refine(tz => IANAZone.isValidZone(tz), { message: 'Invalid IANA timezone name' });

const setTimezoneSchema = z.object({
  userId:   z.string().min(1).max(64).default('local'),
  platform: z.enum(['discord', 'web']).default('web'),
  ianaZone: ianaZoneStr,
});

const convertBodySchema = z.object({
  timeString: z.string().min(1, 'timeString is required'),
  targetZone: ianaZoneStr.optional(),
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function buildConvertResponse(parsedResult, targetZone) {
  const { luxonDateTime, ianaZone } = parsedResult;
  const targetDt = targetZone ? convertTo(parsedResult, targetZone) : null;

  return {
    original: {
      time:      formatForDisplay(luxonDateTime, true),
      zone:      ianaZone,
      utcOffset: formatUtcOffset(luxonDateTime),
      isoString: luxonDateTime.toISO(),
    },
    converted: targetDt
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

// GET /api/aliases — full alias map (used by frontend autocomplete)
router.get('/aliases', (_req, res) => {
  res.json({ aliases: ALIASES });
});

// POST /api/timezone — save a user's timezone preference
router.post('/timezone', (req, res) => {
  const parsed = setTimezoneSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: parsed.error.issues[0].message });
  }
  const { userId, platform, ianaZone } = parsed.data;
  setTimezone(userId, platform, ianaZone);
  res.json({ ok: true, ianaZone });
});

// GET /api/timezone/:userId — retrieve a stored timezone
router.get('/timezone/:userId', (req, res) => {
  const { userId } = req.params;
  const platform = req.query.platform || 'web';
  const row = getTimezone(userId, platform);
  if (!row) return res.status(404).json({ ok: false, error: 'No timezone set for this user' });
  res.json({ ok: true, ianaZone: row.iana_zone });
});

// POST /api/convert — parse a time string and optionally convert to a target zone
router.post('/convert', (req, res) => {
  const parsed = convertBodySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: parsed.error.issues[0].message });
  }

  const { timeString, targetZone } = parsed.data;
  const result = parseTimeInput(timeString);

  if (!result.ok) {
    return res.status(400).json({ ok: false, error: result.error });
  }

  res.json({ ok: true, ...buildConvertResponse(result.result, targetZone) });
});

// GET /api/convert — decode a shareable link
// Query params:
//   ?t=<iso8601>          ISO timestamp produced by luxon (always has offset)
//   ?tz=<ianaZone>        Optional target timezone for the recipient
router.get('/convert', (req, res) => {
  const { t, tz } = req.query;

  if (!t) {
    return res.status(400).json({ ok: false, error: 'Missing required query param: t' });
  }

  // Parse the ISO string. luxon fromISO on a string with offset always produces a
  // fixed-offset zone, which is what we want for share links.
  const dt = DateTime.fromISO(t, { setZone: true });

  if (!dt.isValid) {
    return res.status(400).json({ ok: false, error: `Invalid timestamp: ${dt.invalidReason}` });
  }

  // Validate target timezone if provided
  if (tz && !IANAZone.isValidZone(tz)) {
    return res.status(400).json({ ok: false, error: `Invalid target timezone: ${tz}` });
  }

  const targetDt = tz ? dt.setZone(tz) : null;

  res.json({
    ok: true,
    original: {
      time:      formatForDisplay(dt, true),
      zone:      dt.zoneName,
      utcOffset: formatUtcOffset(dt),
      isoString: dt.toISO(),
    },
    converted: targetDt
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
