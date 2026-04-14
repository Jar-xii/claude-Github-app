/* Settings page — timezone picker backed by localStorage */

(function () {
  const STORAGE_KEY = 'universalClockTz';

  const searchEl    = document.getElementById('tz-search');
  const selectEl    = document.getElementById('tz-select');
  const previewEl   = document.getElementById('tz-preview');
  const saveBtn     = document.getElementById('save-btn');
  const clearBtn    = document.getElementById('clear-btn');
  const alertEl     = document.getElementById('alert');
  const currentCard = document.getElementById('current-card');
  const currentTzEl = document.getElementById('current-tz');
  const resultsEl   = document.getElementById('search-results');

  let aliases      = {};
  let selectedZone = localStorage.getItem(STORAGE_KEY) || '';

  // ── Grouped IANA zones for the <select> ──────────────────────────────────────
  const GROUPED_ZONES = {
    'UTC': ['UTC'],
    'United Kingdom & Ireland': ['Europe/London', 'Europe/Dublin'],
    'Europe': [
      'Europe/Lisbon', 'Europe/Paris', 'Europe/Berlin', 'Europe/Amsterdam',
      'Europe/Brussels', 'Europe/Madrid', 'Europe/Rome', 'Europe/Zurich',
      'Europe/Vienna', 'Europe/Prague', 'Europe/Warsaw', 'Europe/Stockholm',
      'Europe/Oslo', 'Europe/Copenhagen', 'Europe/Helsinki', 'Europe/Athens',
      'Europe/Bucharest', 'Europe/Kyiv', 'Europe/Istanbul', 'Europe/Moscow',
    ],
    'North America': [
      'America/New_York', 'America/Chicago', 'America/Denver', 'America/Phoenix',
      'America/Los_Angeles', 'America/Anchorage', 'Pacific/Honolulu',
      'America/Halifax', 'America/Toronto', 'America/Vancouver',
    ],
    'Middle East': [
      'Asia/Dubai', 'Asia/Riyadh', 'Asia/Jerusalem', 'Asia/Tehran',
      'Asia/Kuwait', 'Asia/Qatar', 'Asia/Baghdad', 'Asia/Beirut', 'Asia/Amman',
    ],
    'Africa': [
      'Africa/Cairo', 'Africa/Johannesburg', 'Africa/Nairobi', 'Africa/Lagos',
      'Africa/Accra', 'Africa/Casablanca', 'Africa/Addis_Ababa',
    ],
    'Asia': [
      'Asia/Kolkata', 'Asia/Karachi', 'Asia/Dhaka', 'Asia/Colombo',
      'Asia/Kathmandu', 'Asia/Bangkok', 'Asia/Jakarta', 'Asia/Singapore',
      'Asia/Manila', 'Asia/Kuala_Lumpur', 'Asia/Ho_Chi_Minh',
      'Asia/Shanghai', 'Asia/Hong_Kong', 'Asia/Taipei', 'Asia/Seoul', 'Asia/Tokyo',
    ],
    'Australia & Pacific': [
      'Australia/Perth', 'Australia/Darwin', 'Australia/Adelaide',
      'Australia/Brisbane', 'Australia/Sydney', 'Australia/Melbourne',
      'Pacific/Auckland', 'Pacific/Fiji',
    ],
    'South America': [
      'America/Sao_Paulo', 'America/Argentina/Buenos_Aires', 'America/Bogota',
      'America/Lima', 'America/Santiago', 'America/Caracas',
    ],
    'Mexico & Central America': [
      'America/Mexico_City', 'America/Monterrey', 'America/Tijuana',
      'America/Cancun', 'America/Havana', 'America/Jamaica',
    ],
  };

  // Populate <select> — replaceAll underscores for legible labels
  for (const [group, zones] of Object.entries(GROUPED_ZONES)) {
    const optgroup = document.createElement('optgroup');
    optgroup.label = group;
    for (const zone of zones) {
      const opt = document.createElement('option');
      opt.value = zone;
      opt.textContent = zone.replaceAll('_', ' ');
      optgroup.appendChild(opt);
    }
    selectEl.appendChild(optgroup);
  }

  // Pre-select the saved zone (if it exists in the list)
  if (selectedZone) selectEl.value = selectedZone;

  // Load alias map for live search
  fetch('/api/aliases')
    .then(r => r.json())
    .then(data => { aliases = data.aliases || {}; })
    .catch(() => { /* non-critical, search will just stay empty */ });

  // ── Current timezone display ─────────────────────────────────────────────────
  function refreshCurrentDisplay() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      currentCard.style.display = 'block';
      try {
        const now = new Date();
        const timeStr = new Intl.DateTimeFormat('en-GB', {
          timeZone: saved, hour: '2-digit', minute: '2-digit',
          hour12: true, weekday: 'short', month: 'short', day: 'numeric',
        }).format(now).toUpperCase();
        const offsetParts = new Intl.DateTimeFormat('en-GB', {
          timeZone: saved, timeZoneName: 'shortOffset',
          hour: '2-digit', minute: '2-digit',
        }).formatToParts(now);
        const offset = (offsetParts.find(p => p.type === 'timeZoneName') || {}).value || '';
        currentTzEl.textContent = `${saved} (${offset}) — Currently: ${timeStr}`;
      } catch {
        currentTzEl.textContent = `${saved} — (invalid timezone)`;
      }
    } else {
      currentCard.style.display = 'none';
    }
  }

  refreshCurrentDisplay();

  // ── Zone preview ─────────────────────────────────────────────────────────────
  function previewZone(zone) {
    if (!zone) { previewEl.textContent = ''; return; }
    try {
      const now = new Date();
      const parts = new Intl.DateTimeFormat('en-GB', {
        timeZone: zone, hour: '2-digit', minute: '2-digit',
        hour12: true, timeZoneName: 'shortOffset',
      }).formatToParts(now);
      const time   = parts.filter(p => ['hour','literal','minute','dayPeriod'].includes(p.type)).map(p => p.value).join('').toUpperCase();
      const offset = (parts.find(p => p.type === 'timeZoneName') || {}).value || '';
      previewEl.textContent = `Currently ${time} (${offset}) in ${zone}`;
    } catch {
      previewEl.textContent = 'Invalid timezone';
    }
  }

  // Show preview for already-saved zone
  if (selectedZone) previewZone(selectedZone);

  // ── Search ────────────────────────────────────────────────────────────────────
  let searchTimer;
  searchEl.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      const q = searchEl.value.trim().toUpperCase();
      resultsEl.innerHTML = '';

      if (!q) return;

      const matches = Object.entries(aliases)
        .filter(([alias]) => alias.startsWith(q))
        .slice(0, 8);

      if (matches.length === 0) {
        resultsEl.innerHTML =
          '<span style="font-size:.8rem;color:var(--muted)">No alias found — try the dropdown below</span>';
        return;
      }

      for (const [alias, zone] of matches) {
        const btn = document.createElement('button');
        btn.className = 'secondary';
        btn.style.cssText = 'font-size:.8rem;padding:.3rem .7rem;margin:.2rem .2rem 0 0';
        btn.textContent = `${alias} → ${zone}`;
        btn.addEventListener('click', () => {
          selectedZone = zone;
          selectEl.value = zone;   // also highlight in dropdown (may be absent — that's fine)
          searchEl.value = alias;
          resultsEl.innerHTML = '';
          previewZone(zone);
        });
        resultsEl.appendChild(btn);
      }
    }, 200);
  });

  // ── Dropdown ──────────────────────────────────────────────────────────────────
  selectEl.addEventListener('change', () => {
    selectedZone = selectEl.value;
    previewZone(selectedZone);
  });

  // ── Alert helper ──────────────────────────────────────────────────────────────
  function showAlert(msg, type) {
    alertEl.textContent = msg;
    alertEl.className = `alert show ${type}`;
    setTimeout(() => alertEl.classList.remove('show'), 4000);
  }

  // ── Save ──────────────────────────────────────────────────────────────────────
  saveBtn.addEventListener('click', () => {
    const zone = selectedZone || selectEl.value;
    if (!zone) {
      showAlert('Please choose a timezone first.', 'error');
      return;
    }
    localStorage.setItem(STORAGE_KEY, zone);
    showAlert(`Timezone saved: ${zone}`, 'success');
    refreshCurrentDisplay();
  });

  // ── Clear ─────────────────────────────────────────────────────────────────────
  clearBtn.addEventListener('click', () => {
    localStorage.removeItem(STORAGE_KEY);
    selectedZone = '';
    selectEl.value = '';
    searchEl.value = '';
    previewEl.textContent = '';
    resultsEl.innerHTML = '';
    showAlert('Timezone cleared.', 'success');
    refreshCurrentDisplay();
  });
})();
