/* Converter page — time input → conversion + shareable link */

(function () {
  const STORAGE_KEY = 'universalClockTz';

  const inputEl    = document.getElementById('time-input');
  const errorEl    = document.getElementById('parse-error');
  const resultBox  = document.getElementById('result-box');
  const origTime   = document.getElementById('orig-time');
  const origZone   = document.getElementById('orig-zone');
  const origOffset = document.getElementById('orig-offset');
  const convTime   = document.getElementById('conv-time');
  const convZone   = document.getElementById('conv-zone');
  const convOffset = document.getElementById('conv-offset');
  const noTzMsg    = document.getElementById('no-tz-msg');
  const shareUrl   = document.getElementById('share-url');
  const copyBtn    = document.getElementById('copy-btn');

  let lastResult = null;

  function getUserTz() {
    return localStorage.getItem(STORAGE_KEY) || null;
  }

  function showError(msg) {
    errorEl.textContent = msg;
    errorEl.className = 'alert show error';
    resultBox.classList.remove('show');
    lastResult = null;
  }

  function clearError() {
    errorEl.classList.remove('show');
  }

  function renderResult(data) {
    lastResult = data;
    clearError();
    resultBox.classList.add('show');

    origTime.textContent   = data.original.time;
    origZone.textContent   = data.original.zone;
    origOffset.textContent = data.original.utcOffset;

    const userTz = getUserTz();

    if (data.converted) {
      convTime.textContent   = data.converted.time;
      convZone.textContent   = data.converted.zone;
      convOffset.textContent = data.converted.utcOffset;
      noTzMsg.style.display  = 'none';
      convTime.style.display = convZone.style.display = convOffset.style.display = '';
      buildShareLink(data.original.isoString, data.original.zone);
    } else if (!userTz) {
      convTime.style.display = convZone.style.display = convOffset.style.display = 'none';
      noTzMsg.style.display = '';
      buildShareLink(data.original.isoString, data.original.zone);
    }
  }

  function buildShareLink(isoString, sourceZone) {
    const url = new URL(window.location.origin + '/share');
    url.searchParams.set('t', isoString);
    url.searchParams.set('tz', sourceZone);
    shareUrl.value = url.toString();
  }

  async function doConvert(raw) {
    if (!raw.trim()) {
      clearError();
      resultBox.classList.remove('show');
      return;
    }

    const userTz = getUserTz();
    const body = { timeString: raw };
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

  // Debounced input handler
  let debounce;
  inputEl.addEventListener('input', () => {
    clearTimeout(debounce);
    debounce = setTimeout(() => doConvert(inputEl.value), 350);
  });

  // Copy share link
  copyBtn.addEventListener('click', () => {
    if (!shareUrl.value) return;
    navigator.clipboard.writeText(shareUrl.value).then(() => {
      copyBtn.textContent = 'Copied!';
      setTimeout(() => (copyBtn.textContent = 'Copy link'), 2000);
    });
  });

  // ── Handle ?t= and ?tz= params (shareable link) ───────────────────────────
  function parseShareParams() {
    const params = new URLSearchParams(window.location.search);
    const t  = params.get('t');
    const tz = params.get('tz');

    if (!t) return;

    const userTz = getUserTz();
    const url = `/api/convert?t=${encodeURIComponent(t)}${userTz ? '&tz=' + encodeURIComponent(userTz) : ''}`;

    fetch(url)
      .then(r => r.json())
      .then(data => {
        if (!data.ok) {
          showError(data.error || 'Could not decode shared link.');
          return;
        }
        // Pre-fill the input with a friendly representation
        if (tz) inputEl.value = `(shared time from ${tz})`;
        renderResult(data);
      })
      .catch(() => showError('Failed to load shared time.'));
  }

  parseShareParams();
})();
