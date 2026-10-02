/* Palawan Van Transport & Travel Services — site behaviour (no dependencies) */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------- Header: scrolled state + mobile menu ---------- */
  var header = document.querySelector('[data-header]');
  var toggle = document.querySelector('[data-nav-toggle]');
  var nav = document.getElementById('site-nav');

  function onScroll() {
    if (header) header.classList.toggle('is-scrolled', window.scrollY > 8);
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  function setMenu(open, returnFocus) {
    toggle.setAttribute('aria-expanded', String(open));
    nav.classList.toggle('is-open', open);
    document.body.classList.toggle('nav-open', open);
    if (open) {
      var first = nav.querySelector('a');
      if (first) first.focus();
    } else if (returnFocus) {
      toggle.focus();
    }
  }

  if (toggle && nav) {
    toggle.addEventListener('click', function () {
      setMenu(toggle.getAttribute('aria-expanded') !== 'true', false);
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') setMenu(false, true);
    });
    nav.addEventListener('click', function (e) {
      if (e.target.closest('a')) setMenu(false, false);
    });
    // keep focus inside the open menu (menu + toggle button)
    document.addEventListener('focusin', function (e) {
      if (toggle.getAttribute('aria-expanded') === 'true' && !nav.contains(e.target) && e.target !== toggle) {
        var first = nav.querySelector('a');
        if (first) first.focus();
      }
    });
    window.matchMedia('(min-width: 64rem)').addEventListener('change', function (mq) {
      if (mq.matches) setMenu(false, false);
    });
  }

  /* ---------- Reveal on scroll ---------- */
  var revealEls = document.querySelectorAll('[data-reveal]');
  if (!reduceMotion && 'IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          io.unobserve(entry.target);
        }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    revealEls.forEach(function (el) { io.observe(el); });
  } else {
    revealEls.forEach(function (el) { el.classList.add('is-visible'); });
  }

  /* ---------- Mobile bar: hide near the footer / on the request form ---------- */
  var bar = document.querySelector('[data-mobile-bar]');
  var footer = document.querySelector('.site-footer');
  var request = document.getElementById('request');
  if (bar && 'IntersectionObserver' in window) {
    var hiders = new Set();
    var barIO = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) hiders.add(e.target); else hiders.delete(e.target); });
      bar.classList.toggle('is-hidden', hiders.size > 0);
    });
    if (footer) barIO.observe(footer);
    if (request) barIO.observe(request);
  }

  /* ---------- Transfer options: tabs on small screens ---------- */
  document.querySelectorAll('[data-tabs]').forEach(function (wrap) {
    var list = wrap.querySelector('[data-tablist]');
    var tabs = Array.prototype.slice.call(wrap.querySelectorAll('[data-tab]'));
    var panels = Array.prototype.slice.call(wrap.querySelectorAll('[data-panel]'));
    var mq = window.matchMedia('(max-width: 59.99rem)');
    var current = 0;

    function select(i, focus) {
      current = i;
      tabs.forEach(function (t, n) {
        t.setAttribute('aria-selected', String(n === i));
        t.tabIndex = n === i ? 0 : -1;
      });
      panels.forEach(function (p, n) { p.hidden = mq.matches && n !== i; });
      if (focus) tabs[i].focus();
    }

    function apply() {
      var on = mq.matches;
      list.hidden = !on;
      wrap.classList.toggle('is-tabbed', on);
      if (on) {
        list.setAttribute('role', 'tablist');
        list.setAttribute('aria-label', 'Transfer options');
        tabs.forEach(function (t, n) {
          t.setAttribute('role', 'tab');
          t.id = 'tab-' + panels[n].id;
          t.setAttribute('aria-controls', panels[n].id);
          panels[n].setAttribute('role', 'tabpanel');
          panels[n].setAttribute('aria-labelledby', t.id);
        });
      } else {
        panels.forEach(function (p) { p.removeAttribute('role'); p.removeAttribute('aria-labelledby'); });
      }
      select(current, false);
    }

    tabs.forEach(function (t, n) {
      t.addEventListener('click', function () { select(n, false); });
      t.addEventListener('keydown', function (e) {
        var k = e.key, next = null;
        if (k === 'ArrowRight') next = (current + 1) % tabs.length;
        if (k === 'ArrowLeft') next = (current - 1 + tabs.length) % tabs.length;
        if (k === 'Home') next = 0;
        if (k === 'End') next = tabs.length - 1;
        if (next !== null) { e.preventDefault(); select(next, true); }
      });
    });
    mq.addEventListener('change', apply);
    apply();
  });

  /* ---------- Gallery lightbox ---------- */
  var gallery = document.querySelector('[data-gallery]');
  var box = document.querySelector('[data-lightbox]');
  if (gallery && box && typeof box.showModal === 'function') {
    var items = Array.prototype.slice.call(gallery.querySelectorAll('.gallery__item'));
    var img = box.querySelector('[data-lightbox-img]');
    var caption = box.querySelector('[data-lightbox-caption]');
    var index = 0, opener = null;

    function show(i) {
      index = (i + items.length) % items.length;
      var it = items[index];
      img.src = it.getAttribute('data-full');
      img.alt = it.getAttribute('data-alt');
      caption.textContent = it.getAttribute('data-alt') + '  (' + (index + 1) + ' / ' + items.length + ')';
    }
    items.forEach(function (it, i) {
      it.addEventListener('click', function () {
        opener = it;
        show(i);
        box.showModal();
        box.querySelector('[data-lightbox-close]').focus();
      });
    });
    box.querySelector('[data-lightbox-close]').addEventListener('click', function () { box.close(); });
    box.querySelector('[data-lightbox-prev]').addEventListener('click', function () { show(index - 1); });
    box.querySelector('[data-lightbox-next]').addEventListener('click', function () { show(index + 1); });
    box.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowRight') show(index + 1);
      if (e.key === 'ArrowLeft') show(index - 1);
    });
    box.addEventListener('click', function (e) { if (e.target === box) box.close(); });
    box.addEventListener('close', function () { if (opener) opener.focus(); });
  } else if (gallery) {
    // No <dialog> support: open the larger image directly
    gallery.querySelectorAll('.gallery__item').forEach(function (it) {
      it.addEventListener('click', function () { window.open(it.getAttribute('data-full'), '_blank', 'noopener'); });
    });
  }

  /* ---------- Travel request form ---------- */
  var form = document.getElementById('travel-form');
  if (!form) return;

  var errorBox = form.querySelector('[data-form-error]');
  var result = document.querySelector('[data-form-result]');
  var success = document.querySelector('[data-form-success]');
  var endpoint = form.getAttribute('data-endpoint');

  // Earliest travel date = today (local time)
  var dateInput = form.elements.date;
  var now = new Date();
  dateInput.min = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 10);

  // Prefill from links such as ?from=Puerto%20Princesa&to=El%20Nido or ?service=airport
  var params = new URLSearchParams(window.location.search);
  var serviceMap = {
    airport: 'Airport or hotel pickup', resort: 'Resort transfer', tour: 'Palawan tour',
    rental: 'Car or motorcycle rental', assistance: 'Travel assistance'
  };
  if (params.get('from')) form.elements.pickup.value = params.get('from');
  if (params.get('to')) form.elements.destination.value = params.get('to');
  if (serviceMap[params.get('service')]) form.elements.service.value = serviceMap[params.get('service')];
  if (params.get('service') === 'airport') form.elements.pickup.value = form.elements.pickup.value || 'Puerto Princesa International Airport';
  if (params.get('vehicle')) form.elements.message.value = 'I would like to ask about ' + params.get('vehicle') + ' rental.';
  var typeParam = (params.get('type') || '').toLowerCase();
  if (typeParam === 'private' || typeParam === 'shared') {
    form.querySelector('input[name="type"][value="' + typeParam.charAt(0).toUpperCase() + typeParam.slice(1) + '"]').checked = true;
  }

  function fieldMessage(el) {
    if (el.validity.valueMissing) return 'Please fill in this field.';
    if (el.validity.typeMismatch && el.type === 'email') return 'Please enter a valid email address.';
    if (el.validity.rangeUnderflow && el.type === 'date') return 'Please choose today or a later date.';
    if (el.validity.rangeUnderflow || el.validity.rangeOverflow) return 'Please enter a number between ' + el.min + ' and ' + el.max + '.';
    if (el.validity.badInput) return 'Please check this value.';
    return '';
  }

  function setError(el, msg) {
    var id = el.id + '-error';
    var existing = document.getElementById(id);
    var describedby = (el.getAttribute('aria-describedby') || '').split(' ').filter(function (x) { return x && x !== id; });
    if (msg) {
      if (!existing) {
        existing = document.createElement('p');
        existing.className = 'field__error';
        existing.id = id;
        el.insertAdjacentElement('afterend', existing);
      }
      existing.textContent = msg;
      el.setAttribute('aria-invalid', 'true');
      describedby.push(id);
    } else {
      if (existing) existing.remove();
      el.removeAttribute('aria-invalid');
    }
    if (describedby.length) el.setAttribute('aria-describedby', describedby.join(' '));
    else el.removeAttribute('aria-describedby');
  }

  var fields = Array.prototype.slice.call(form.querySelectorAll('input:not([type="radio"]), select, textarea'));
  fields.forEach(function (el) {
    el.addEventListener('blur', function () { if (el.getAttribute('aria-invalid')) setError(el, fieldMessage(el)); });
    el.addEventListener('input', function () { if (el.getAttribute('aria-invalid')) setError(el, fieldMessage(el)); });
  });

  function buildMessage(d) {
    var lines = [
      'Hi Palawan Van Transport & Travel Services! I would like to check availability.',
      '',
      'Name: ' + d.name,
      'Mobile / WhatsApp: ' + d.phone
    ];
    if (d.email) lines.push('Email: ' + d.email);
    lines.push(
      'Service: ' + d.service,
      'Travel date: ' + d.date,
      'Pickup: ' + d.pickup,
      'Destination: ' + d.destination,
      'Passengers: ' + d.passengers,
      'Transfer type: ' + d.type
    );
    if (d.flight) lines.push('Flight / arrival: ' + d.flight);
    if (d.luggage) lines.push('Luggage: ' + d.luggage);
    if (d.message) lines.push('', d.message);
    return lines.join('\n');
  }

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    var firstInvalid = null;
    fields.forEach(function (el) {
      var msg = fieldMessage(el);
      setError(el, msg);
      if (msg && !firstInvalid) firstInvalid = el;
    });
    errorBox.hidden = !firstInvalid;
    if (firstInvalid) { firstInvalid.focus(); return; }

    var data = {};
    new FormData(form).forEach(function (v, k) { data[k] = String(v).trim(); });
    var text = buildMessage(data);

    // If a form service endpoint is configured (e.g. Formspree), submit there.
    if (endpoint) {
      var btn = form.querySelector('button[type="submit"]');
      btn.disabled = true;
      fetch(endpoint, { method: 'POST', headers: { 'Accept': 'application/json' }, body: new FormData(form) })
        .then(function (r) { if (!r.ok) throw new Error(r.status); form.hidden = true; success.hidden = false; success.focus(); })
        .catch(function () { showHandoff(text, data); })
        .then(function () { btn.disabled = false; });
      return;
    }
    showHandoff(text, data);
  });

  // No backend connected: hand the request to WhatsApp or email, pre-filled, so nothing is silently lost.
  function showHandoff(text, data) {
    var wa = form.getAttribute('data-whatsapp');
    var mail = form.getAttribute('data-email');
    result.querySelector('[data-send="whatsapp"]').href = 'https://wa.me/' + wa + '?text=' + encodeURIComponent(text);
    result.querySelector('[data-send="email"]').href = 'mailto:' + mail +
      '?subject=' + encodeURIComponent('Travel request: ' + data.pickup + ' to ' + data.destination + ' (' + data.date + ')') +
      '&body=' + encodeURIComponent(text);
    form.hidden = true;
    result.hidden = false;
    result.focus();
  }

  result.querySelector('[data-form-edit]').addEventListener('click', function () {
    result.hidden = true;
    form.hidden = false;
    form.elements.name.focus();
  });
})();
