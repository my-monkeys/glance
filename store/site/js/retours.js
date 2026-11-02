/* Bouton de retours : même appel que l'ancien site (POST git.my-monkey.fr/api/feedback). */
(function () {
  var fab = document.querySelector('.fab'), ov = document.querySelector('.fbk-ov');
  if (!fab || !ov) return;
  var form = ov.querySelector('[data-f="form"]'), done = ov.querySelector('[data-f="done"]'),
      ta = ov.querySelector('textarea'), em = ov.querySelector('input'), err = ov.querySelector('.err'),
      send = ov.querySelector('[data-f="send"]');
  function show() { ov.hidden = false; form.hidden = false; done.hidden = true; err.hidden = true; setTimeout(function () { ta.focus(); }, 60); }
  function hide() { ov.hidden = true; fab.focus(); }
  fab.addEventListener('click', show);
  ov.addEventListener('click', function (e) { if (e.target === ov) hide(); });
  ov.querySelector('[data-f="cancel"]').addEventListener('click', hide);
  ov.querySelector('[data-f="close"]').addEventListener('click', hide);
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !ov.hidden) hide(); });
  send.addEventListener('click', function () {
    var msg = ta.value.trim();
    if (msg.length < 2) { ta.focus(); return; }
    send.disabled = true; err.hidden = true;
    fetch('https://git.my-monkey.fr/api/feedback', {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ product: 'glance', message: msg, email: em.value.trim() || undefined, context: 'site · ' + document.documentElement.lang })
    })
      .then(function (r) { if (!r.ok) throw 0; form.hidden = true; done.hidden = false; ta.value = ''; em.value = ''; })
      .catch(function () { err.hidden = false; })
      .finally(function () { send.disabled = false; });
  });
})();
