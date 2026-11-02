/* Animations Glance — GSAP (core + ScrollTrigger), sobres : transform et opacité uniquement.
   Progressive enhancement : sans JS, sans GSAP ou en « mouvement réduit », la page reste entièrement
   visible (la classe .js pré-masque l'entrée du hero, on la retire). */
(function () {
  var root = document.documentElement;
  var reveal = function () { root.classList.remove('js'); };

  if (!window.gsap || !window.ScrollTrigger) { reveal(); return; }
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) { reveal(); return; }

  gsap.registerPlugin(ScrollTrigger);
  var qa = function (s) { return Array.prototype.slice.call(document.querySelectorAll(s)); };

  // Hero : le texte arrive en cascade, la courbe de la marque se dessine derrière le téléphone.
  var tl = gsap.timeline({ defaults: { ease: 'power3.out' }, onComplete: reveal });
  tl.fromTo('.hero .texte [data-entree]', { y: 26, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.7, stagger: 0.09 }, 0.05);
  tl.fromTo('.hero .telephone', { y: 60, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 1, ease: 'power2.out' }, 0.2);

  var courbe = document.querySelector('.hero .courbe path');
  if (courbe && courbe.getTotalLength) {
    var len = courbe.getTotalLength();
    gsap.set(courbe, { strokeDasharray: len, strokeDashoffset: len });
    gsap.to(courbe, { strokeDashoffset: 0, duration: 2, ease: 'power2.inOut', delay: 0.3 });
  }

  // Chaque scène se pose quand elle entre dans l'écran.
  qa('.scene img').forEach(function (img) {
    gsap.from(img, {
      y: 48, autoAlpha: 0, duration: 0.9, ease: 'power2.out',
      scrollTrigger: { trigger: img, start: 'top 88%', once: true }
    });
  });
})();
