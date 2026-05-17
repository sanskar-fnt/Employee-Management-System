(function () {
  'use strict';

  /* ── Sidebar toggle ─────────────────────────────────────────── */
  function initSidebar() {
    var layout = document.querySelector('.app-layout');
    var toggle = document.querySelector('[data-sb-toggle]');
    if (!layout) return;
    if (localStorage.getItem('ems-sb') === '1') layout.classList.add('sb-collapsed');
    if (toggle) {
      toggle.addEventListener('click', function () {
        var collapsed = layout.classList.toggle('sb-collapsed');
        localStorage.setItem('ems-sb', collapsed ? '1' : '0');
      });
    }
  }

  /* ── Topbar scroll shadow ───────────────────────────────────── */
  function initTopbar() {
    var tb = document.querySelector('.topbar');
    if (!tb) return;
    function tick() { tb.classList.toggle('scrolled', window.scrollY > 2); }
    window.addEventListener('scroll', tick, { passive: true });
    tick();
  }

  /* ── Dropdowns ──────────────────────────────────────────────── */
  function initDropdowns() {
    document.querySelectorAll('[data-dropdown]').forEach(function (trigger) {
      var popup = trigger.nextElementSibling;
      if (!popup || !popup.classList.contains('dd-popup')) return;
      trigger.addEventListener('click', function (e) {
        e.stopPropagation();
        var open = popup.classList.toggle('open');
        document.querySelectorAll('.dd-popup.open').forEach(function (p) {
          if (p !== popup) p.classList.remove('open');
        });
        if (!open) return;
      });
    });
    document.addEventListener('click', function () {
      document.querySelectorAll('.dd-popup.open').forEach(function (p) {
        p.classList.remove('open');
      });
    });
  }

  /* ── Toast system ───────────────────────────────────────────── */
  function initToasts() {
    var alerts = document.querySelectorAll('.page-alert[data-toast]');
    if (!alerts.length) return;
    var root = document.getElementById('toast-root');
    if (!root) {
      root = document.createElement('div');
      root.id = 'toast-root';
      document.body.appendChild(root);
    }
    alerts.forEach(function (el) {
      var kind = el.getAttribute('data-toast') || 'info';
      var msg  = el.textContent.trim();
      el.style.display = 'none';
      var t = document.createElement('div');
      t.className = 'toast toast-' + kind;
      t.innerHTML =
        '<span class="toast-msg">' + escHtml(msg) + '</span>' +
        '<button class="toast-close" aria-label="Dismiss">' +
          '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>' +
        '</button>';
      root.appendChild(t);
      var timer = setTimeout(function () { dismiss(t); }, 5000);
      t.querySelector('.toast-close').addEventListener('click', function () {
        clearTimeout(timer);
        dismiss(t);
      });
    });
  }

  function dismiss(el) {
    el.classList.add('toast-out');
    el.addEventListener('animationend', function () { el.remove(); }, { once: true });
  }

  function escHtml(s) {
    return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }

  /* ── Filter chips ───────────────────────────────────────────── */
  function initChips() {
    document.querySelectorAll('.chip[data-select]').forEach(function (chip) {
      chip.addEventListener('click', function () {
        var selectId = chip.getAttribute('data-select');
        var val      = chip.getAttribute('data-value') || '';
        var sel      = document.getElementById(selectId);
        if (!sel) return;
        sel.value = val;
        sel.dispatchEvent(new Event('change'));
        document.querySelectorAll('.chip[data-select="' + selectId + '"]')
          .forEach(function (c) { c.classList.remove('active'); });
        chip.classList.add('active');
      });
    });
  }

  /* ── Inline edit rows ───────────────────────────────────────── */
  function initInlineEdit() {
    document.querySelectorAll('[data-edit-row]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var row = btn.closest('tr');
        if (!row) return;
        row.querySelectorAll('.input-inline').forEach(function (inp) {
          inp.removeAttribute('readonly');
        });
        row.querySelectorAll('[data-edit-row]').forEach(function (b) { b.style.display = 'none'; });
        var saveBtn = row.querySelector('[data-save-row]');
        if (saveBtn) saveBtn.style.display = '';
      });
    });
    /* Also handle the btn-edit-emp pattern */
    document.querySelectorAll('.btn-edit-emp').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-id');
        var fields = document.querySelectorAll('[data-emp="' + id + '"]');
        var isReadOnly = fields.length > 0 && fields[0].hasAttribute('readonly');
        fields.forEach(function (f) {
          if (isReadOnly) f.removeAttribute('readonly');
          else f.setAttribute('readonly', 'readonly');
        });
        btn.textContent = isReadOnly ? 'Cancel' : 'Edit';
      });
    });
  }

  /* ── Modals ─────────────────────────────────────────────────── */
  function initModals() {
    document.querySelectorAll('[data-modal-open]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-modal-open');
        var m  = document.getElementById(id);
        if (m) m.classList.add('open');
      });
    });
    document.querySelectorAll('[data-modal-close]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var m = btn.closest('.modal-bd');
        if (m) m.classList.remove('open');
      });
    });
    document.querySelectorAll('.modal-bd').forEach(function (m) {
      m.addEventListener('click', function (e) {
        if (e.target === m) m.classList.remove('open');
      });
    });
  }

  /* ── Live clock ─────────────────────────────────────────────── */
  function initClock() {
    var clockEl = document.getElementById('liveClock');
    var dateEl  = document.getElementById('liveDate');
    if (!clockEl) return;
    var days   = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    function tick() {
      var now = new Date();
      var h = now.getHours(), m = now.getMinutes(), s = now.getSeconds();
      var ampm = h >= 12 ? 'PM' : 'AM';
      h = h % 12 || 12;
      clockEl.textContent =
        pad(h) + ':' + pad(m) + ':' + pad(s) + ' ' + ampm;
      if (dateEl) {
        dateEl.textContent =
          days[now.getDay()] + ', ' +
          months[now.getMonth()] + ' ' +
          now.getDate() + ', ' +
          now.getFullYear();
      }
    }
    function pad(n) { return n < 10 ? '0' + n : '' + n; }
    tick();
    setInterval(tick, 1000);
  }

  /* ── Submit button loading state ────────────────────────────── */
  function initFormLoading() {
    document.querySelectorAll('form').forEach(function (form) {
      form.addEventListener('submit', function () {
        var btn = form.querySelector('[type="submit"]');
        if (btn && !btn.dataset.noLoad) {
          btn.disabled = true;
          btn.style.opacity = '0.7';
        }
      });
    });
  }

  /* ── Attendance rate bar ────────────────────────────────────── */
  function initRateBar() {
    document.querySelectorAll('.rate-bar-fill[data-pct]').forEach(function (fill) {
      var pct = parseInt(fill.getAttribute('data-pct'), 10) || 0;
      fill.style.width = Math.min(100, Math.max(0, pct)) + '%';
    });
  }

  function initNotifications() {
    var KEY = 'ems.dismissedNotifications';
    var dismissed = {};
    try { dismissed = JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { dismissed = {}; }

    document.querySelectorAll('.noti-item[data-noti-id]').forEach(function (el) {
      var id = el.getAttribute('data-noti-id');
      if (id && dismissed[id]) { el.style.display = 'none'; }
    });
    document.querySelectorAll('.noti-dismiss[data-noti-id]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-noti-id');
        if (!id) return;
        dismissed[id] = Date.now();
        try { localStorage.setItem(KEY, JSON.stringify(dismissed)); } catch (e) {}
        var item = btn.closest('.noti-item');
        if (item) item.style.display = 'none';
      });
    });
  }

  /* ── Theme system (light / dark) ─────────────────────────────
   * Persistence: localStorage["ems.theme"] = "light" | "dark"
   * Activation:  document.documentElement.dataset.theme = chosen value
   * Toggle:      injected into the topbar — clicking flips and stores. */
  var THEME_KEY = 'ems.theme';

  function getStoredTheme() {
    try { return localStorage.getItem(THEME_KEY); } catch (e) { return null; }
  }
  function applyTheme(theme) {
    var t = theme === 'dark' ? 'dark' : 'light';
    if (t === 'dark') document.documentElement.setAttribute('data-theme', 'dark');
    else              document.documentElement.removeAttribute('data-theme');
    var btn = document.querySelector('.theme-toggle');
    if (btn) {
      btn.setAttribute('aria-label', t === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
      btn.setAttribute('title',      t === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
    }
  }
  function setTheme(theme) {
    try { localStorage.setItem(THEME_KEY, theme); } catch (e) {}
    applyTheme(theme);
  }
  // Boot-time apply (runs as soon as app.js parses — before DOMContentLoaded)
  (function bootTheme() {
    var stored = getStoredTheme();
    if (stored === 'dark' || stored === 'light') {
      applyTheme(stored);
    } else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      applyTheme('dark');
    }
  })();

  function buildThemeToggle() {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'theme-toggle';
    btn.setAttribute('aria-label', 'Toggle theme');
    btn.innerHTML =
      '<svg class="icon-moon" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>' +
      '<svg class="icon-sun"  width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><line x1="12" y1="2" x2="12" y2="5"/><line x1="12" y1="19" x2="12" y2="22"/><line x1="2" y1="12" x2="5" y2="12"/><line x1="19" y1="12" x2="22" y2="12"/><line x1="4.93" y1="4.93" x2="7.05" y2="7.05"/><line x1="16.95" y1="16.95" x2="19.07" y2="19.07"/><line x1="4.93" y1="19.07" x2="7.05" y2="16.95"/><line x1="16.95" y1="7.05" x2="19.07" y2="4.93"/></svg>';
    btn.addEventListener('click', function () {
      var current = document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
      setTheme(current === 'dark' ? 'light' : 'dark');
    });
    return btn;
  }

  function initTheme() {
    if (document.querySelector('.theme-toggle')) return;
    // Find the topbar's right-side container — supports both topbar variants used in the codebase.
    var host = document.querySelector('.tb-right') || document.querySelector('.topbar-right');
    var btn = buildThemeToggle();
    if (host) {
      host.insertBefore(btn, host.firstChild);
    } else {
      // Pages without a topbar (login, error) get a floating toggle so the system is truly global.
      btn.classList.add('theme-toggle-floating');
      document.body.appendChild(btn);
    }
    applyTheme(document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light');
  }

  /* ── Boot ───────────────────────────────────────────────────── */
  /* ── Admin notification bell (popover, badge, mark-read, clear-all) ──
   * Hooks the topbar bell button (.ic-btn[aria-label="Notifications"]):
   *   1. Wraps it so the badge can sit absolutely.
   *   2. Adds a popover element next to it.
   *   3. Polls /admin/notifications and updates the badge + popover content.
   *   4. POSTs mark_read / mark_all_read / clear_all with the CSRF token. */
  function initAdminBell() {
    var bell = document.querySelector('.ic-btn[aria-label="Notifications"]');
    if (!bell) return;

    // Wrap the bell so badge + popover anchor to it.
    var wrap = document.createElement('div');
    wrap.className = 'bell-wrap';
    bell.parentNode.insertBefore(wrap, bell);
    wrap.appendChild(bell);

    var badge = document.createElement('span');
    badge.className = 'bell-badge';
    badge.style.display = 'none';
    wrap.appendChild(badge);

    var pop = document.createElement('div');
    pop.className = 'bell-pop';
    pop.innerHTML =
      '<div class="bell-pop-hd">' +
        '<span class="bell-pop-title">Notifications</span>' +
        '<div class="bell-pop-actions">' +
          '<button type="button" class="bell-pop-link" data-bell-mark-all>Mark all read</button>' +
          '<button type="button" class="bell-pop-link" data-bell-clear>Clear all</button>' +
        '</div>' +
      '</div>' +
      '<div class="bell-pop-body" data-bell-body>' +
        '<div class="bell-empty">Loading…</div>' +
      '</div>';
    wrap.appendChild(pop);

    var ctx = (function () {
      var meta = document.querySelector('meta[name="ctx"]');
      if (meta) return meta.getAttribute('content') || '';
      var path = location.pathname || '';
      var i = path.indexOf('/', 1);
      return i > 0 ? path.substring(0, i) : '';
    })();
    var endpoint = ctx + '/admin/notifications';

    function getCsrf() {
      var m = document.cookie.match(/(?:^|;\s*)XSRF-TOKEN=([^;]+)/);
      return m ? decodeURIComponent(m[1]) : '';
    }
    function relTime(iso) {
      if (!iso) return '';
      var t = new Date(iso.replace(' ', 'T')); var diff = (Date.now() - t.getTime()) / 60000;
      if (isNaN(diff)) return iso;
      if (diff < 1)  return 'just now';
      if (diff < 60) return Math.floor(diff) + 'm ago';
      if (diff < 1440) return Math.floor(diff / 60) + 'h ago';
      return Math.floor(diff / 1440) + 'd ago';
    }
    function escHtml2(s) {
      if (s == null) return '';
      return ('' + s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }
    function severityClass(sev) {
      sev = (sev || '').toLowerCase();
      if (sev === 'err' || sev === 'error' || sev === 'danger') return 'tone-err';
      if (sev === 'warn' || sev === 'warning')                  return 'tone-warn';
      if (sev === 'ok'   || sev === 'success')                  return 'tone-ok';
      return 'tone-info';
    }
    function setBadge(n) {
      if (!n || n <= 0) { badge.style.display = 'none'; return; }
      badge.textContent = n > 99 ? '99+' : ('' + n);
      badge.style.display = '';
    }
    function render(items) {
      var body = pop.querySelector('[data-bell-body]');
      if (!items || items.length === 0) {
        body.innerHTML = '<div class="bell-empty">You’re all caught up.</div>';
        return;
      }
      var html = '';
      items.forEach(function (a) {
        var href = a.href ? (ctx + '/' + a.href.replace(/^\//, '')) : 'javascript:void(0)';
        html += '<a class="bell-item ' + (a.unread ? 'unread' : '') + '" data-id="' + a.id + '" href="' + href + '">' +
                '<div class="bell-icon-dot ' + severityClass(a.severity) + '">' +
                  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2z"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>' +
                '</div>' +
                '<div>' +
                  '<div class="bell-item-title">' + escHtml2(a.title) + '</div>' +
                  '<div class="bell-item-msg">'   + escHtml2(a.message) + '</div>' +
                  '<div class="bell-item-time">'  + escHtml2(relTime(a.createdAt)) + '</div>' +
                '</div>' +
              '</a>';
      });
      body.innerHTML = html;
    }

    function load() {
      fetch(endpoint, { credentials: 'same-origin' })
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (data) {
          if (!data || !data.ok) return;
          setBadge(data.unreadCount || 0);
          render(data.items || []);
        })
        .catch(function () { /* silent */ });
    }

    function postAction(action, extra) {
      var body = 'action=' + encodeURIComponent(action) + '&csrfToken=' + encodeURIComponent(getCsrf());
      if (extra) body += '&' + extra;
      return fetch(endpoint, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body
      }).then(function (r) { return r.ok ? r.json() : null; })
        .then(function (data) {
          if (!data || !data.ok) return;
          setBadge(data.unreadCount || 0);
          render(data.items || []);
        });
    }

    // Open / close
    bell.addEventListener('click', function (e) {
      e.stopPropagation();
      pop.classList.toggle('open');
    });
    document.addEventListener('click', function (e) {
      if (!pop.contains(e.target) && e.target !== bell && !bell.contains(e.target)) {
        pop.classList.remove('open');
      }
    });

    // Item click → mark read (intercept before navigation if href is empty/anchor only)
    pop.addEventListener('click', function (e) {
      var item = e.target.closest('.bell-item');
      if (item) {
        var id = item.getAttribute('data-id');
        if (id) postAction('mark_read', 'id=' + encodeURIComponent(id));
      }
    });

    pop.querySelector('[data-bell-mark-all]').addEventListener('click', function (e) {
      e.preventDefault(); postAction('mark_all_read');
    });
    pop.querySelector('[data-bell-clear]').addEventListener('click', function (e) {
      e.preventDefault();
      if (confirm('Clear all notifications?')) postAction('clear_all');
    });

    load();
    setInterval(load, 60000); // refresh every minute
  }

  document.addEventListener('DOMContentLoaded', function () {
    initSidebar();
    initTopbar();
    initDropdowns();
    initToasts();
    initChips();
    initInlineEdit();
    initModals();
    initClock();
    initRateBar();
    initFormLoading();
    initNotifications();
    initTheme();
    initAdminBell();
  });
})();
