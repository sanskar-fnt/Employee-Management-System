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

  /* ── Boot ───────────────────────────────────────────────────── */
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
  });
})();
