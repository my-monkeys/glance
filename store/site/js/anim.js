/* Animations Glance — GSAP (core + ScrollTrigger).
   Progressive enhancement : sans JS / sans GSAP / en « mouvement réduit »,
   la page reste entièrement visible (la classe .js pré-masque, on la retire). */
(function () {
  var root = document.documentElement;
  var reveal = function () { root.classList.remove('js'); };

  if (!window.gsap || !window.ScrollTrigger) { reveal(); return; }
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) { reveal(); return; }

  gsap.registerPlugin(ScrollTrigger);

  var q = function (s, c) { return (c || document).querySelector(s); };
  var qa = function (s, c) { return Array.prototype.slice.call((c || document).querySelectorAll(s)); };

  // --- Hero : entrée en cascade -------------------------------------------
  var heroCol = q('.hero2 > div:first-child');
  var phoneWrap = q('.hero2 > div:last-child');
  var phone = q('.hero2 .shot');
  var halo = q('.hero2 .halo');

  if (phoneWrap) gsap.set(phoneWrap, { perspective: 1400 });

  var tl = gsap.timeline({ defaults: { ease: 'power3.out' } });

  if (halo) {
    tl.fromTo(halo, { autoAlpha: 0, scale: 0.6 }, { autoAlpha: 1, scale: 1, duration: 1.3, ease: 'power2.out' }, 0);
  }
  if (heroCol) {
    tl.fromTo(heroCol.children,
      { y: 28, autoAlpha: 0 },
      { y: 0, autoAlpha: 1, duration: 0.72, stagger: 0.09 }, 0.05);
  }
  if (phone) {
    // Entrée : le téléphone arrive légèrement tourné/incliné puis se pose.
    tl.fromTo(phone,
      { autoAlpha: 0, y: 46, rotationZ: -11, rotationY: 20, scale: 0.9, transformOrigin: '50% 60%' },
      { autoAlpha: 1, y: 0, rotationZ: -3, rotationY: 0, scale: 1, duration: 1.15, ease: 'power3.out',
        onComplete: floatPhone },
      0.15);
  }

  // --- Téléphone « vivant » : flottement + micro-inclinaison en boucle -----
  function floatPhone() {
    if (!phone) return;
    gsap.to(phone, {
      y: '-=15', rotationZ: -5,
      duration: 3.4, ease: 'sine.inOut', repeat: -1, yoyo: true
    });

    // Parallaxe douce à la souris (pointeur fin uniquement).
    if (!phoneWrap || !matchMedia('(hover: hover) and (pointer: fine)').matches) return;
    var setRY = gsap.quickTo(phone, 'rotationY', { duration: 0.6, ease: 'power2.out' });
    var setRX = gsap.quickTo(phone, 'rotationX', { duration: 0.6, ease: 'power2.out' });
    var host = q('.hero2');
    host.addEventListener('mousemove', function (e) {
      var r = host.getBoundingClientRect();
      var px = (e.clientX - r.left) / r.width - 0.5;   // -0.5 .. 0.5
      var py = (e.clientY - r.top) / r.height - 0.5;
      setRY(px * 12);
      setRX(-py * 8);
    });
    host.addEventListener('mouseleave', function () { setRY(0); setRX(0); });
  }

  // --- Nav : ombre au défilement ------------------------------------------
  var nav = q('.nav');
  if (nav) {
    ScrollTrigger.create({
      start: 'top -10', end: 99999,
      onUpdate: function (self) {
        nav.style.boxShadow = self.progress > 0 || self.scroll() > 10
          ? '0 6px 22px rgba(30,25,15,.07)' : 'none';
      }
    });
    // simple : ombre dès qu'on scrolle
    var onScroll = function () {
      nav.style.boxShadow = window.scrollY > 8 ? '0 6px 22px rgba(30,25,15,.07)' : 'none';
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  // --- Révélations au scroll (sous la ligne de flottaison) -----------------
  function revealBlock(el, vars) {
    if (!el) return;
    gsap.from(el, Object.assign({
      y: 30, autoAlpha: 0, duration: 0.7, ease: 'power2.out',
      scrollTrigger: { trigger: el, start: 'top 86%' }
    }, vars || {}));
  }

  // En-têtes de section + blocs pleins
  revealBlock(q('#feat > div:first-child'));
  revealBlock(q('#desk .featx:first-child'));
  revealBlock(q('#desk .featx:last-child'), { y: 40 });
  revealBlock(q('.mslider') && q('.mslider').previousElementSibling);
  revealBlock(q('.mslider'));
  revealBlock(q('#priv .card'));
  revealBlock(q('#os .priv'));
  revealBlock(q('#install .card'));
  revealBlock(q('.footer'));

  // Cartes du bento : apparition en cascade quand la grille entre en vue
  var cards = qa('#feat .bc');
  if (cards.length) {
    ScrollTrigger.batch(cards, {
      start: 'top 88%',
      onEnter: function (els) {
        gsap.from(els, { y: 34, autoAlpha: 0, duration: 0.6, ease: 'power2.out', stagger: 0.08, overwrite: true });
      }
    });
  }

  // Tracé de la courbe du bento (dessin de la ligne au scroll)
  var line = q('#feat .bc svg path[stroke="#3B7A5A"][fill="none"]');
  if (line && line.getTotalLength) {
    var len = line.getTotalLength();
    gsap.set(line, { strokeDasharray: len, strokeDashoffset: len });
    gsap.to(line, {
      strokeDashoffset: 0, duration: 1.4, ease: 'power2.inOut',
      scrollTrigger: { trigger: line, start: 'top 82%' }
    });
  }

  ScrollTrigger.refresh();
})();
