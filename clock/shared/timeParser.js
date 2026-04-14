'use strict';

const { DateTime } = require('luxon');
const { resolveAlias } = require('./timezoneAliases');

/**
 * Parses a free-form time string like "8pm UK", "20:00 BST", "3:30pm Eastern",
 * "1430 PST", "noon UTC", "midnight GMT".
 *
 * @param {string} raw - User-provided time string
 * @returns {{ ok: true, result: ParsedTime } | { ok: false, error: string }}
 *
 * @typedef {Object} ParsedTime
 * @property {string} originalInput
 * @property {number} hours   - 0-23
 * @property {number} minutes - 0-59
 * @property {string} ianaZone
 * @property {string} aliasUsed   - the raw timezone token the user typed
 * @property {DateTime} luxonDateTime
 */
function parseTimeInput(raw) {
  if (!raw || typeof raw !== 'string' || raw.trim().length === 0) {
    return { ok: false, error: 'Input is empty.' };
  }

  const input = raw.trim();
  const upper = input.toUpperCase();

  // ── Step 1: Extract timezone token ──────────────────────────────────────
  // Strategy: try progressively shorter trailing multi-word phrases, then single words.
  // This handles aliases like "NEW YORK", "LOS ANGELES", "HONG KONG", "NEW ZEALAND".
  // We keep two word arrays: upper (for alias matching) and original (for IANA passthrough).
  const words = upper.split(/\s+/);
  const wordsOrig = input.split(/\s+/);
  let ianaZone = null;
  let aliasUsed = null;
  let tzWordCount = 0;

  // Try 3-word suffix, then 2-word, then 1-word
  for (let len = Math.min(3, words.length - 1); len >= 1; len--) {
    const candidate     = words.slice(-len).join(' ');         // uppercase for alias lookup
    const candidateOrig = wordsOrig.slice(-len).join(' ');     // original case for IANA passthrough
    const resolved = resolveAlias(candidate, candidateOrig);
    if (resolved) {
      ianaZone = resolved;
      aliasUsed = candidate;
      tzWordCount = len;
      break;
    }
  }

  if (!ianaZone) {
    const lastWord = words[words.length - 1];
    return {
      ok: false,
      error: `Unknown timezone: "${lastWord}". Use an alias like UK, EST, Tokyo, or an IANA name like Europe/London.`,
    };
  }

  // Remaining words (everything except the timezone tokens)
  const timePart = words.slice(0, words.length - tzWordCount).join(' ').trim();

  if (!timePart) {
    return { ok: false, error: 'No time value found before the timezone.' };
  }

  // ── Step 2: Parse the time value ─────────────────────────────────────────
  let hours = null;
  let minutes = 0;

  // Named times
  if (timePart === 'NOON' || timePart === 'MIDDAY') {
    hours = 12;
    minutes = 0;
  } else if (timePart === 'MIDNIGHT') {
    hours = 0;
    minutes = 0;
  } else {
    // Pattern A: HH:MM with optional AM/PM  e.g. "3:30 PM", "15:30", "3:30PM"
    const patternA = /^(\d{1,2}):(\d{2})\s*(AM|PM)?$/.exec(timePart);
    if (patternA) {
      let h = parseInt(patternA[1], 10);
      const m = parseInt(patternA[2], 10);
      const meridiem = patternA[3];

      if (meridiem === 'AM') {
        if (h === 12) h = 0;
      } else if (meridiem === 'PM') {
        if (h !== 12) h += 12;
      }

      if (m < 0 || m > 59) {
        return { ok: false, error: `Invalid minutes: ${patternA[2]}` };
      }
      hours = h;
      minutes = m;
    }

    // Pattern B: H AM/PM (mandatory meridiem, no colon)  e.g. "8PM", "8 PM"
    if (hours === null) {
      const patternB = /^(\d{1,2})\s*(AM|PM)$/.exec(timePart);
      if (patternB) {
        let h = parseInt(patternB[1], 10);
        const meridiem = patternB[2];

        if (meridiem === 'AM') {
          if (h === 12) h = 0;
        } else {
          if (h !== 12) h += 12;
        }

        hours = h;
        minutes = 0;
      }
    }

    // Pattern C: Military time  e.g. "1430", "0800"
    if (hours === null) {
      const patternC = /^(\d{4})$/.exec(timePart);
      if (patternC) {
        const h = parseInt(patternC[1].slice(0, 2), 10);
        const m = parseInt(patternC[1].slice(2), 10);

        if (h > 23) return { ok: false, error: `Invalid hour in military time: ${timePart}` };
        if (m > 59) return { ok: false, error: `Invalid minutes in military time: ${timePart}` };

        hours = h;
        minutes = m;
      }
    }

    // Pattern D: Plain hour 0-23 with no meridiem (24-hour single number)
    if (hours === null) {
      const patternD = /^(\d{1,2})$/.exec(timePart);
      if (patternD) {
        const h = parseInt(patternD[1], 10);
        if (h > 23) return { ok: false, error: `Hour ${h} is out of range (0-23). Did you mean ${h % 12 || 12}PM?` };
        hours = h;
        minutes = 0;
      }
    }
  }

  if (hours === null) {
    return { ok: false, error: `Could not parse time value: "${timePart}". Try formats like "8pm", "20:00", "3:30pm", "1430".` };
  }

  if (hours < 0 || hours > 23) {
    return { ok: false, error: `Hour ${hours} is out of range (0-23).` };
  }

  // ── Step 3: Build luxon DateTime ─────────────────────────────────────────
  // Use today's date in the source timezone so "8pm Tokyo" means tonight in Tokyo.
  const nowInZone = DateTime.now().setZone(ianaZone);
  const dt = DateTime.fromObject(
    { year: nowInZone.year, month: nowInZone.month, day: nowInZone.day, hour: hours, minute: minutes, second: 0 },
    { zone: ianaZone }
  );

  if (!dt.isValid) {
    return { ok: false, error: `Could not construct a valid date: ${dt.invalidReason}` };
  }

  return {
    ok: true,
    result: {
      originalInput: raw,
      hours,
      minutes,
      ianaZone,
      aliasUsed,
      luxonDateTime: dt,
    },
  };
}

/**
 * Convert a parsed time to a target IANA timezone.
 * @param {ParsedTime} parsedTime
 * @param {string} targetIanaZone
 * @returns {DateTime}
 */
function convertTo(parsedTime, targetIanaZone) {
  return parsedTime.luxonDateTime.setZone(targetIanaZone);
}

/**
 * Format a luxon DateTime for human display.
 * @param {DateTime} dt
 * @param {boolean} [includeDate=false] - Include day/date in output
 * @returns {string} e.g. "8:00 PM" or "8:00 PM (Mon 14 Apr)"
 */
function formatForDisplay(dt, includeDate = false) {
  const time = dt.toFormat('h:mm a');
  if (!includeDate) return time;

  const date = dt.toFormat('ccc d MMM');
  return `${time} (${date})`;
}

/**
 * Format UTC offset for display e.g. "UTC+1", "UTC-5", "UTC+5:30"
 * @param {DateTime} dt
 * @returns {string}
 */
function formatUtcOffset(dt) {
  const offset = dt.offset; // minutes
  if (offset === 0) return 'UTC+0';
  const sign = offset > 0 ? '+' : '-';
  const abs = Math.abs(offset);
  const h = Math.floor(abs / 60);
  const m = abs % 60;
  return m > 0 ? `UTC${sign}${h}:${String(m).padStart(2, '0')}` : `UTC${sign}${h}`;
}

module.exports = { parseTimeInput, convertTo, formatForDisplay, formatUtcOffset };
