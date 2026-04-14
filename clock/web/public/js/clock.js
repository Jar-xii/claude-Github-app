/* Live clock — reads timezone from localStorage and updates every second */

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
      if (elTime)   elTime.textContent  = '--:-- --';
      if (elDate)   elDate.textContent  = '';
      if (elZone)   elZone.textContent  = 'No timezone set';
      if (elOffset) elOffset.textContent = '';
      return;
    }

    if (elBanner) elBanner.style.display = 'none';

    try {
      const now = new Date();

      const timeStr = new Intl.DateTimeFormat('en-GB', {
        timeZone: tz,
        hour: '2-digit', minute: '2-digit', second: '2-digit',
        hour12: true,
      }).format(now).toUpperCase();

      const dateStr = new Intl.DateTimeFormat('en-GB', {
        timeZone: tz,
        weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
      }).format(now);

      const offsetParts = new Intl.DateTimeFormat('en-GB', {
        timeZone: tz,
        timeZoneName: 'shortOffset',
        hour: '2-digit', minute: '2-digit',
      }).formatToParts(now);
      const offsetStr = (offsetParts.find(p => p.type === 'timeZoneName') || {}).value || '';

      if (elTime)   elTime.textContent   = timeStr;
      if (elDate)   elDate.textContent   = dateStr;
      if (elZone)   elZone.textContent   = tz;
      if (elOffset) elOffset.textContent = offsetStr;

    } catch {
      // Invalid timezone stored — clear it and prompt the user to fix it
      localStorage.removeItem(STORAGE_KEY);
      if (elTime) {
        elTime.innerHTML = 'Invalid timezone — <a href="/settings" style="color:inherit">fix in Settings</a>';
      }
      if (elDate)   elDate.textContent   = '';
      if (elZone)   elZone.textContent   = '';
      if (elOffset) elOffset.textContent = '';
    }
  }

  tick();
  setInterval(tick, 1000);

  // React if another tab changes the timezone in localStorage
  window.addEventListener('storage', e => {
    if (e.key === STORAGE_KEY) tick();
  });
})();
