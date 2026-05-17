// EMS theme pre-paint bootstrap. Loaded synchronously in <head> so the chosen
// theme is set on <html> BEFORE first paint, avoiding a flash of light content.
// Persistence and toggle behavior live in app.js.
(function () {
  try {
    var t = localStorage.getItem('ems.theme');
    if (t === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
    } else if (!t && window.matchMedia &&
               window.matchMedia('(prefers-color-scheme: dark)').matches) {
      document.documentElement.setAttribute('data-theme', 'dark');
    }
  } catch (e) { /* localStorage unavailable, fall back to light */ }
})();
