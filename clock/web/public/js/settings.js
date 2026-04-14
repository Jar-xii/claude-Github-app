/* Settings page — timezone picker backed by localStorage */

(function () {
  const STORAGE_KEY = 'universalClockTz';

  const searchEl      = document.getElementById('tz-search');
  const selectEl      = document.getElementById('tz-select');
  const previewEl     = document.getElementById('tz-preview');
  const saveBtn       = document.getElementById('save-btn');
  const clearBtn      = document.getElementById('clear-btn');
  const alertEl       = document.getElementById('alert');
  const currentCard   = document.getElementById('current-card');
  const currentTzEl   = document.getElementById('current-tz');
  const resultsEl     = document.getElementById('search-results');

  let aliases = {};
  let selectedZone = '';

  // ── IANA zones grouped for the <select> ────────────────────────────────────
  const GROUPED_ZONES = {
    'UTC': ['UTC'],
    'United Kingdom & Ireland': ['Europe/London', 'Europe/Dublin'],
    'Europe': [
      'Europe/Paris', 'Europe/Berlin', 'Europe/Amsterdam', 'Europe/Brussels',
      'Europe/Madrid', 'Europe/Rome', 'Europe/Zurich', 'Europe/Vienna',
      'Europe/Prague', 'Europe/Warsaw', 'Europe/Stockholm', 'Europe/Oslo',
      'Europe/Copenhagen', 'Europe/Helsinki', 'Europe/Athens', 'Europe/Lisbon',
      'Europe/Bucharest', 'Europe/Moscow', 'Europe/Istanbul', 'Europe/Kyiv',
    ],
    'North America': [
      'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
      'America/Phoenix', 'America/Anchorage', 'Pacific/Honolulu',
      'America/Toronto', 'America/Vancouver', 'America/Halifax',
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
      'Asia/Tokyo', 'Asia/Seoul', 'Asia/Shanghai', 'Asia/Hong_Kong', 'Asia/Taipei',
    ],
    'Australia & Pacific': [
      'Australia/Sydney', 'Australia/Melbourne', 'Australia/Brisbane',
      'Australia/Perth', 'Australia/Adelaide', 'Australia/Darwin',
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

  // Populate <select>
  for (const [group, zones] of Object.entries(GROUPED_ZONES)) {
    const optgroup = document.createElement('optgroup');
    optgroup.label = group;
    for (const zone of zones) {
      const opt = document.createElement('option');
      opt.value = zone;
      opt.textContent = zone.replace('_', ' ');
      optgroup.appendChild(opt);
    }
    selectEl.appendChild(optgroup);
  }

  // Load alias map for search
  fetch('/api/aliases')
    .then(r => r.json())
    .then(data => { aliases = data.aliases || {}; })
    .catch(() => {});

  // Show current timezone
  function refreshCurrentDisplay() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      currentCard.style.display = 'block';
      const now = new Date();
      const formatter = new Intl.DateTimeFormat('en-GB', {
        timeZone: saved, hour: '2-digit', minute: '2-digit', second: '2-digit',
        hour12: true, weekday: 'short', month: 'short', day: 'numeric',
      });
      currentTzEl.textContent = `${saved} — Currently: ${formatter.format(now).toUpperCase()}`;
    } else {
      currentCard.style.display = 'none';
    }
  }

  refreshCurrentDisplay();

  // Preview helper
  function previewZone(zone) {
    if (!zone) { previewEl.textContent = ''; return; }
    try {
      const now = new Date();
      const fmt = new Intl.DateTimeFormat('en-GB', {
        timeZone: zone, hour: '2-digit', minute: '2-digit',
        hour12: true, timeZoneName: 'shortOffset',
      });
      previewEl.textContent = `Currently ${fmt.format(now).toUpperCase()} in ${zone}`;
    } catch {
      previewEl.textContent = 'Invalid timezone';
    }
  }

  // Search input
  let searchDebounce;
  searchEl.addEventListener('input', () => {
    clearTimeout(searchDebounce);
    searchDebounce = setTimeout(() => {
      const q = searchEl.value.trim().toUpperCase();
      resultsEl.innerHTML = '';
      if (!q) return;

      const matches = Object.entries(aliases)
        .filter(([alias]) => alias.startsWith(q))
        .slice(0, 8);

      if (matches.length === 0) {
        resultsEl.innerHTML = '<span style="font-size:.8rem;color:var(--muted)">No alias found — try a full IANA name in the list below</span>';
        return;
      }

      matches.forEach(([alias, zone]) => {
        const btn = document.createElement('button');
        btn.className = 'secondary';
        btn.style.cssText = 'font-size:.8rem;padding:.3rem .7rem;margin:.2rem .2rem 0 0';
        btn.textContent = `${alias} → ${zone}`;
        btn.addEventListener('click', () => {
          selectedZone = zone;
          selectEl.value = zone;
          searchEl.value = alias;
          resultsEl.innerHTML = '';
          previewZone(zone);
        });
        resultsEl.appendChild(btn);
      });
    }, 200);
  });

  // Select change
  selectEl.addEventListener('change', () => {
    selectedZone = selectEl.value;
    previewZone(selectedZone);
  });

  // Alert helper
  function showAlert(msg, type) {
    alertEl.textContent = msg;
    alertEl.className = `alert show ${type}`;
    setTimeout(() => alertEl.classList.remove('show'), 4000);
  }

  // Save
  saveBtn.addEventListener('click', () => {
    const zone = selectedZone || selectEl.value;
    if (!zone) {
      showAlert('Please select or search for a timezone first.', 'error');
      return;
    }
    localStorage.setItem(STORAGE_KEY, zone);
    showAlert(`Timezone saved: ${zone}`, 'success');
    refreshCurrentDisplay();
  });

  // Clear
  clearBtn.addEventListener('click', () => {
    localStorage.removeItem(STORAGE_KEY);
    selectEl.value = '';
    searchEl.value = '';
    selectedZone = '';
    previewEl.textContent = '';
    resultsEl.innerHTML = '';
    showAlert('Timezone cleared.', 'success');
    refreshCurrentDisplay();
  });
})();
