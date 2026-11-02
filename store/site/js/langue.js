/* Langue du site : redirection vers la langue choisie, sélecteur, et bulle qui propose la langue du
   navigateur. Chargé dans le <head> : la redirection part avant le premier rendu.
   Ajouter une langue = une entrée dans LANGUES (et dans CODE_PAGE si le code <html lang> diffère du dossier). */
(function () {
  var LANGUES = {
    fr: { url: '/', tip: 'Ce site est aussi disponible en français.', go: 'Passer en français', close: 'Fermer' },
    en: { url: '/en/', tip: 'This site is also available in English.', go: 'Switch to English', close: 'Close' },
    de: { url: '/de/', tip: 'Diese Website gibt es auch auf Deutsch.', go: 'Auf Deutsch wechseln', close: 'Schließen' },
    es: { url: '/es/', tip: 'Este sitio también está disponible en español.', go: 'Cambiar a español', close: 'Cerrar' },
    pt: { url: '/pt/', tip: 'Este site também está disponível em português.', go: 'Mudar para português', close: 'Fechar' },
    zh: { url: '/zh/', tip: '本站也提供简体中文版。', go: '切换到简体中文', close: '关闭' }
  };
  var CODE_PAGE = { 'pt-BR': 'pt', 'zh-Hans': 'zh' };
  var page = CODE_PAGE[document.documentElement.lang] || document.documentElement.lang;

  function lire(cle) { try { return localStorage.getItem(cle); } catch (e) { return null; } }
  function ecrire(cle, valeur) { try { localStorage.setItem(cle, valeur); } catch (e) {} }

  var choisie = lire('glance-lang');
  if (choisie && LANGUES[choisie] && choisie !== page) { location.replace(LANGUES[choisie].url); return; }

  // La première langue préférée que le site propose ; le chinois traditionnel n'existe pas encore.
  function langueDuNavigateur() {
    var prefs = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || ''];
    for (var i = 0; i < prefs.length; i++) {
      var p = String(prefs[i]).toLowerCase(), code = p.slice(0, 2);
      if (code === 'zh' && /hant|-tw|-hk|-mo/.test(p)) continue;
      if (LANGUES[code]) return code;
    }
    return 'en';
  }

  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest && e.target.closest('[data-lang]');
    if (a) ecrire('glance-lang', a.getAttribute('data-lang'));
    var menu = document.querySelector('.langues[open]');
    if (menu && !menu.contains(e.target)) menu.removeAttribute('open');
  });
  document.addEventListener('keydown', function (e) {
    var menu = document.querySelector('.langues[open]');
    if (e.key === 'Escape' && menu) { menu.removeAttribute('open'); menu.querySelector('summary').focus(); }
  });

  function proposer() {
    var nav = document.querySelector('.haut nav'), bouton = document.querySelector('.langues summary');
    if (!nav || lire('glance-lang') || lire('glance-lang-tip')) return;
    var cible = langueDuNavigateur();
    if (cible === page) return;
    var l = LANGUES[cible];
    var tip = document.createElement('div');
    tip.className = 'lang-tip';
    tip.setAttribute('role', 'status');
    tip.innerHTML = '<p></p><a class="go" data-lang="' + cible + '"></a><button type="button" class="x"></button>';
    tip.querySelector('p').textContent = l.tip;
    var go = tip.querySelector('.go');
    go.textContent = l.go; go.href = l.url; go.lang = cible === 'pt' ? 'pt-BR' : cible === 'zh' ? 'zh-Hans' : cible;
    tip.lang = go.lang;
    var x = tip.querySelector('.x');
    x.textContent = '✕'; x.setAttribute('aria-label', l.close);
    x.addEventListener('click', function () { tip.remove(); ecrire('glance-lang-tip', '1'); });
    nav.appendChild(tip);
    // Sur mobile la bulle est fixée pleine largeur : sa flèche est replacée sous le sélecteur.
    function placer() {
      var b = bouton.getBoundingClientRect();
      tip.style.setProperty('--tip-top', Math.round(b.bottom + 10) + 'px');
      tip.style.setProperty('--tip-arrow', Math.round(b.left + b.width / 2 - tip.getBoundingClientRect().left) + 'px');
    }
    placer();
    addEventListener('resize', placer);
  }
  document.addEventListener('DOMContentLoaded', proposer);
})();
