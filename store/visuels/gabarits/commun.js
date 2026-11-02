// Ce que partagent les gabarits : format et langue lus dans l'adresse, unité --u, textes par langue
// (textes/<langue>.json), nombres localisés, graphiques SVG lissés, icônes. Le script de rendu
// attend `window.PRET` avant la capture.
//   <gabarit>.html?lang=fr|en|…&format=iphone|ipad|play|presentation

const PARAMS = new URLSearchParams(location.search);
const LANGUE = PARAMS.get("lang") || "fr";
const FORMAT = PARAMS.get("format") || "iphone";
const LOCALE = { fr: "fr-FR", en: "en-US", de: "de-DE", es: "es-ES", "pt-BR": "pt-BR", "zh-Hans": "zh-CN" }[LANGUE] || LANGUE;

let U = 1; // 1 u = 1 px sur l'iPhone 6,9" (1320 × 2868)
let TEXTES = {};
let PAGE = "";

// La hauteur de référence (2 400 u) borne l'unité des formats moins hauts que l'iPhone : sans elle
// le titre de l'iPad (2 064 px de large) mangerait la moitié de l'image.
function poserUnite() {
  U = FORMAT === "presentation" ? innerWidth / 1024
    : FORMAT === "site" ? innerWidth / 1320
    : Math.min(innerWidth / 1320, innerHeight / 2400);
  const racine = document.documentElement;
  racine.style.setProperty("--u", `${U}px`);
  racine.classList.add(`f-${FORMAT}`, `l-${LANGUE}`);
  racine.lang = LANGUE;
}

const ICONES = {
  lock: '<rect x="4" y="11" width="16" height="10" rx="2.5"/><path d="M8 11V7.5a4 4 0 0 1 8 0V11"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  search: '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>',
};
const icone = (nom) => `<span class="icone"><svg viewBox="0 0 24 24">${ICONES[nom]}</svg></span>`;

// Nombres : espace insécable ordinaire (les polices n'ont pas toutes l'espace fine).
const nettoyer = (s) => s.replace(/[  ]/g, " ");
const nb = (n, d = 0) => nettoyer(new Intl.NumberFormat(LOCALE, { minimumFractionDigits: d, maximumFractionDigits: d }).format(n));
const pct = (x, d = 0) => nb(x, d) + (LANGUE === "fr" ? " %" : "%");
const signe = (x, d = 0) => (x >= 0 ? "▲ " : "▼ ") + pct(Math.abs(x), d);

function T(cle) {
  const t = TEXTES[PAGE]?.[cle] ?? TEXTES.commun?.[cle];
  if (t === undefined) throw new Error(`texte manquant : ${PAGE}.${cle} (${LANGUE})`);
  return t;
}

function poserTextes() {
  for (const el of document.querySelectorAll("[data-t]")) el.innerHTML = T(el.dataset.t);
  for (const el of document.querySelectorAll("[data-icone]")) el.innerHTML = icone(el.dataset.icone);
}

// La marque : l'icône de l'appli et « Glance », toujours au même endroit.
function poserMarque() {
  const marque = document.querySelector(".marque");
  if (marque) marque.innerHTML = `<img src="/store/icon_master.svg" alt="">${T("marque")}`;
}

// La courbe de l'icône, en très grand et très pâle derrière la scène.
function poserMotif() {
  const W = innerWidth, H = innerHeight, k = W * 1.5 / 1024;
  const d = "M150 705 C 268 705 330 440 452 440 C 548 440 556 600 662 600 C 772 600 800 340 892 340";
  document.body.insertAdjacentHTML("afterbegin",
    `<svg class="motif" width="${W}" height="${H}"><path d="${d}" transform="translate(${-W * .3} ${H * .5}) scale(${k})" stroke-width="70"/></svg>`);
}

// ——— Données d'exemple : déterministes, donc rejouables ———

function hasard(graine) {
  let a = graine >>> 0;
  return () => {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Une série lisse : base + onde + pente + un peu de bruit.
function serie(n, { base = 100, amp = 30, f = 1.5, phase = 0, pente = 0, bruit = 6, graine = 1 } = {}) {
  const r = hasard(graine);
  return Array.from({ length: n }, (_, i) => {
    const x = i / (n - 1);
    return Math.max(0, base + amp * Math.sin((x * f + phase) * Math.PI * 2) + pente * x + (r() - .5) * 2 * bruit);
  });
}

// ——— Graphiques SVG, à la manière de glance_chart.dart ———

// Courbe monotone (pas de dépassement) en cubiques de Bézier, comme `isCurved` de fl_chart.
function lisser(p) {
  const n = p.length;
  if (n < 2) return `M${p[0][0]} ${p[0][1]}`;
  const d = [], m = [];
  for (let i = 0; i < n - 1; i++) d[i] = (p[i + 1][1] - p[i][1]) / (p[i + 1][0] - p[i][0]);
  m[0] = d[0]; m[n - 1] = d[n - 2];
  for (let i = 1; i < n - 1; i++) m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
  for (let i = 0; i < n - 1; i++) {
    if (d[i] === 0) { m[i] = m[i + 1] = 0; continue; }
    const a = m[i] / d[i], b = m[i + 1] / d[i], s = a * a + b * b;
    if (s > 9) { const t = 3 / Math.sqrt(s); m[i] = t * a * d[i]; m[i + 1] = t * b * d[i]; }
  }
  let chemin = `M${p[0][0].toFixed(1)} ${p[0][1].toFixed(1)}`;
  for (let i = 0; i < n - 1; i++) {
    const h = p[i + 1][0] - p[i][0];
    chemin += `C${(p[i][0] + h / 3).toFixed(1)} ${(p[i][1] + m[i] * h / 3).toFixed(1)} ${(p[i + 1][0] - h / 3).toFixed(1)} ${(p[i + 1][1] - m[i + 1] * h / 3).toFixed(1)} ${p[i + 1][0].toFixed(1)} ${p[i + 1][1].toFixed(1)}`;
  }
  return chemin;
}

let compteurDegrade = 0;

// el : un .graphe dimensionné par la mise en page. Les valeurs null sont des trous (une prévision
// commence là où l'observé s'arrête).
//   series : [{ v, couleur, aire, pointille, epaisseur, opacite, point }]
//   max, ticks : échelle ; xlabels : [[indice, texte]] ; gauche : gouttière de l'axe Y, en u ;
//   police : corps des étiquettes d'axe, en u.
function graphe(el, { series, max, ticks = [], xlabels = [], gauche = 0, bas = 0, haut = 14, droite = 10, police = 29 }) {
  const w = el.clientWidth, h = el.clientHeight;
  const x0 = gauche * U, x1 = w - droite * U, y0 = haut * U, y1 = h - bas * U;
  const n = Math.max(...series.map((s) => s.v.length));
  const X = (i) => x0 + (x1 - x0) * i / (n - 1);
  const Y = (v) => y1 - (y1 - y0) * v / max;
  let svg = "";
  for (const t of ticks) {
    svg += `<line x1="${x0}" x2="${x1}" y1="${Y(t)}" y2="${Y(t)}" style="stroke:var(--line)" stroke-width="${2 * U}"/>`;
    if (gauche) svg += `<text x="0" y="${Y(t) + police * .31 * U}" font-family="JetBrains Mono" font-size="${police * U}" style="fill:var(--fg3)">${nb(t)}</text>`;
  }
  for (const [i, texte] of xlabels) {
    const ancre = i === 0 ? "start" : i === n - 1 ? "end" : "middle";
    svg += `<text x="${X(i)}" y="${h - 2 * U}" text-anchor="${ancre}" font-family="JetBrains Mono" font-size="${police * U}" style="fill:var(--fg3)">${texte}</text>`;
  }
  let defs = "";
  for (const s of series) {
    const pts = s.v.map((v, i) => (v == null ? null : [X(i), Y(v)])).filter(Boolean);
    if (pts.length < 2) continue;
    const ligne = lisser(pts);
    if (s.aire) {
      const id = `g${++compteurDegrade}`;
      defs += `<linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${s.couleur}" stop-opacity=".30"/><stop offset="1" stop-color="${s.couleur}" stop-opacity="0"/></linearGradient>`;
      svg += `<path d="${ligne}L${pts.at(-1)[0]} ${y1}L${pts[0][0]} ${y1}Z" fill="url(#${id})"/>`;
    }
    const dash = s.pointille ? ` stroke-dasharray="${0.01} ${(s.epaisseur || 7) * 2 * U}"` : "";
    svg += `<path d="${ligne}" fill="none" stroke="${s.couleur}" stroke-width="${(s.epaisseur || 7) * U}" stroke-linecap="round" stroke-linejoin="round" opacity="${s.opacite ?? 1}"${dash}/>`;
    if (s.point) {
      const [px, py] = pts.at(-1);
      svg += `<circle cx="${px}" cy="${py}" r="${s.point * U}" fill="${s.couleur}" style="stroke:var(--surface)" stroke-width="${4 * U}"/>`;
    }
  }
  el.innerHTML = `<svg viewBox="0 0 ${w} ${h}" width="${w}" height="${h}"><defs>${defs}</defs>${svg}</svg>`;
  return { X, Y, x0, x1, y0, y1, w, h };
}

// Une petite courbe sans axes (cartes de sites, widgets).
function spark(el, v, couleur = "#3B7A5A", opts = {}) {
  const [min, max] = opts.plage || [Math.min(...v), Math.max(...v)];
  const marge = (max - min) * .12 || 1;
  const vv = v.map((x) => x - min + marge);
  return graphe(el, { series: [{ v: vv, couleur, aire: opts.aire, epaisseur: opts.epaisseur || 6 }], max: max - min + 2 * marge, haut: 4, droite: 4 });
}

async function imagesChargees() {
  await Promise.all([...document.images].map((img) => img.complete ? img.decode().catch(() => {}) : new Promise((ok, ko) => {
    img.onload = ok; img.onerror = () => ko(new Error(`image introuvable : ${img.src}`));
  })));
}

// Un contrôle de mise en page : rien ne déborde de l'image, aucun texte n'est coupé.
function verifierDebordement() {
  const problemes = [];
  if (FORMAT === "site") return problemes; // la scène a sa hauteur naturelle : rien ne peut déborder de l'image
  const bas = innerHeight - 30 * U;
  for (const el of document.querySelectorAll(".scene > *")) {
    const r = el.getBoundingClientRect();
    if (el.classList.contains("coupe-bas")) continue;
    if (r.bottom > bas + 1) problemes.push(`${el.className} dépasse en bas (${Math.round(r.bottom)} > ${Math.round(bas)})`);
    if (r.right > innerWidth - 20 * U + 1) problemes.push(`${el.className} dépasse à droite`);
  }
  for (const el of document.querySelectorAll("[data-t], .carte *")) {
    if (el.children.length === 0 && el.textContent.trim() && el.scrollWidth > el.clientWidth + 2 && el.clientWidth > 0) problemes.push(`texte coupé : ${el.className || el.dataset.t}`);
  }
  for (const el of document.querySelectorAll(".carte")) {
    if (el.scrollHeight > el.clientHeight + 2) problemes.push(`carte trop pleine : ${el.className}`);
  }
  return problemes;
}

// Monte le gabarit : unité, textes, puis ce que le gabarit dessine lui-même, et signale la fin.
async function monter(page, dessiner = async () => {}) {
  PAGE = page;
  poserUnite();
  try {
    TEXTES = await (await fetch(`/store/visuels/textes/${LANGUE}.json`)).json();
    poserMarque();
    poserTextes();
    poserMotif();
    await document.fonts.ready;
    await dessiner();
    await imagesChargees();
    window.PROBLEMES = verifierDebordement();
    window.PRET = true;
  } catch (erreur) {
    window.ERREUR = String(erreur.stack || erreur);
  }
}
