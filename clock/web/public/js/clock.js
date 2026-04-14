/* Live clock — reads timezone from localStorage */

(function () {
  const STORAGE_KEY = 'universalClockTz';

  const elTime   = document.getElementById('clock-time');
  const elDate   = document.getElementById('clock-date');
  const elZone   = document.getElementById('clock-zone');
  const elOffset = document.getElementById('clock-offset');
  const elBanner = document.getElementById('no-tz-banner');

  function getUserTz() {
    return localStorage.getItem(STORAGE_KEY) || null;
  }

  function tick() {
    const tz = getUserTz();
    if (!tz) {
      if (elBanner) elBanner.style.display = 'block';
      if (elTime) elTime.textContent = '--:-- --';
      if (elDate) elDate.textContent = '';
      if (elZone) elZone.textContent = 'No timezone set';
      if (elOffset) elOffset.textContent = '';
      return;
    }

    if (elBanner) elBanner.style.display = 'none';

    try {
      const now = new Date();
      const formatter = new Intl.DateTimeFormat('en-GB', {
        timeZone: tz,
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true,
      });

      const dateFormatter = new Intl.DateTimeFormat('en-GB', {
        timeZone: tz,
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });

      const offsetFormatter = new Intl.DateTimeFormat('en-GB', {
        timeZone: tz,
        timeZoneName: 'shortOffset',
        hour: '2-digit',
        minute: '2-digit',
      });

      if (elTime)   elTime.textContent   = formatter.format(now).toUpperCase();
      if (elDate)   elDate.textContent   = dateFormatter.format(now);
      if (elZone)   elZone.textContent   = tz;

      // Extract offset from formatted string
      const parts = offsetFormatter.formatToParts(now);
      const offsetPart = parts.find(p => p.type === 'timeZoneName');
      if (elOffset) elOffset.textContent = offsetPart ? offsetPart.value : '';
    } catch (e) {
      // Invalid timezone stored — clear it
      localStorage.removeItem(STORAGE_KEY);
      if (elTime) elTime.textContent = 'Invalid timezone';
    }
  }

  tick();
  setInterval(tick, 1000);
})();
