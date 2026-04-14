/* Converter page — time input → conversion + shareable link */

(function () {
  const STORAGE_KEY = 'universalClockTz';

  const inputEl    = document.getElementById('time-input');
  const errorEl    = document.getElementById('parse-error');
  const resultBox  = document.getElementById('result-box');
  const origLabel  = document.getElementById('orig-label');
  const origTime   = document.getElementById('orig-time');
  const origZone   = document.getElementById('orig-zone');
  const origOffset = document.getElementById('orig-offset');
  const convTime   = document.getElementById('conv-time');
  const convZone   = document.getElementById('conv-zone');
  const convOffset = document.getElementById('conv-offset');
  const noTzMsg    = document.getElementById('no-tz-msg');
  const shareUrl   = document.getElementById('share-url');
  const copyBtn    = document.getElementById('copy-btn');

  function getUserTz() {
    return localStorage.getItem(STORAGE_KEY) || null;
  }

  // ── Error / clear helpers ─────────────────────────────────────────────────────

  function showError(msg) {
    errorEl.textContent = msg;
    errorEl.className = 'alert show error';
    resultBox.classList.remove('show');
  }

  function clearError() {
    errorEl.classList.remove('show');
  }

  // ── Render result ─────────────────────────────────────────────────────────────

  function renderResult(data, sourceLabel) {
    clearError();
    resultBox.classList.add('show');

    // Source time
    origLabel.textContent  = sourceLabel || 'Original time';
    origTime.textContent   = data.original.time;
    origZone.textContent   = data.original.zone;
    origOffset.textContent = data.original.utcOffset;

    // Converted time (recipient)
    if (data.converted) {
      convTime.textContent    = data.converted.time;
      convZone.textContent    = data.converted.zone;
      convOffset.textContent  = data.converted.utcOffset;
      convTime.style.display  = '';
      convZone.style.display  = '';
      convOffset.style.display = '';
      noTzMsg.style.display   = 'none';
    } else {
      convTime.style.display   = 'none';
      convZone.style.display   = 'none';
      convOffset.style.display = 'none';
      noTzMsg.style.display    = '';
    }

    // Build share link from the ISO string produced by the server
    const url = new URL(window.location.origin + '/share');
    url.searchParams.set('t',  data.original.isoString);
    url.searchParams.set('tz', data.original.zone);
    shareUrl.value = url.toString();
  }

  // ── Convert via text input ────────────────────────────────────────────────────

  async function doConvert(raw) {
    if (!raw.trim()) {
      clearError();
      resultBox.classList.remove('show');
      return;
    }

    const body = { timeString: raw };
    const userTz = getUserTz();
    if (userTz) body.targetZone = userTz;

    try {
      const resp = await fetch('/api/convert', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const data = await resp.json();

      if (!data.ok) {
        showError(data.error || 'Could not parse time.');
        return;
      }

      renderResult(data);
    } catch {
      showError('Network error — is the server running?');
    }
  }

  // Debounced input (350 ms)
  let debounceTimer;
  inputEl.addEventListener('input', () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => doConvert(inputEl.value), 350);
  });

  // ── Re-convert when timezone changes in another tab ───────────────────────────
  window.addEventListener('storage', e => {
    if (e.key === STORAGE_KEY && inputEl.value.trim()) {
      doConvert(inputEl.value);
    }
  });

  // ── Copy share link ────────────────────────────────────────────────────────────
  copyBtn.addEventListener('click', () => {
    const link = shareUrl.value;
    if (!link) return;
    navigator.clipboard.writeText(link).then(() => {
      copyBtn.textContent = 'Copied!';
      setTimeout(() => (copyBtn.textContent = 'Copy link'), 2000);
    }).catch(() => {
      // Fallback for browsers without clipboard API
      shareUrl.select();
      document.execCommand('copy');
      copyBtn.textContent = 'Copied!';
      setTimeout(() => (copyBtn.textContent = 'Copy link'), 2000);
    });
  });

  // ── Handle ?t= / ?tz= params on page load (shareable link) ───────────────────
  function loadShareParams() {
    const params = new URLSearchParams(window.location.search);
    const t      = params.get('t');   // ISO timestamp from the sender
    const tzFrom = params.get('tz');  // source timezone (for display)

    if (!t) return;

    const userTz  = getUserTz();
    const apiUrl  = '/api/convert?t=' + encodeURIComponent(t) +
                    (userTz ? '&tz=' + encodeURIComponent(userTz) : '');

    fetch(apiUrl)
      .then(r => r.json())
      .then(data => {
        if (!data.ok) {
          showError(data.error || 'Could not decode shared link.');
          return;
        }
        // Label the source box with the original sender's timezone
        const label = tzFrom ? `Shared from ${tzFrom}` : 'Shared time';
        inputEl.value = tzFrom
          ? `(time shared from ${tzFrom})`
          : '(shared time)';
        renderResult(data, label);
      })
      .catch(() => showError('Failed to load shared time.'));
  }

  loadShareParams();
})();
