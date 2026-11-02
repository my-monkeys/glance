// Génère lib/l10n/display_names.dart : noms de pays et de langues (CLDR, via
// Intl.DisplayNames de Node) pour chaque langue de l'app.
//
//   node tool/gen_display_names.mjs
//
// Pour ajouter une langue : l'ajouter à LOCALES (même étiquette que le fichier
// ARB : `pt-BR` pour app_pt_BR.arb) et relancer.
import { writeFileSync } from 'node:fs';

const LOCALES = ['fr', 'en', 'de', 'es', 'pt-BR', 'zh-Hans'];

// Codes ISO 639-1 (+ les étiquettes de l'app, qui portent région ou script).
const ISO_639_1 =
  'aa ab af ak am an ar as av ay az ba be bg bh bi bm bn bo br bs ca ce ch co cr cs cu cv cy da de dv dz ee el en eo es et eu fa ff fi fj fo fr fy ga gd gl gn gu gv ha he hi ho hr ht hu hy hz ia id ie ig ii ik io is it iu ja jv ka kg ki kj kk kl km kn ko kr ks ku kv kw ky la lb lg li ln lo lt lu lv mg mh mi mk ml mn mr ms mt my na nb nd ne ng nl nn no nr nv ny oc oj om or os pa pi pl ps pt qu rm rn ro ru rw sa sc sd se sg si sk sl sm sn so sq sr ss st su sv sw ta te tg th ti tk tl tn to tr ts tt tw ty ug uk ur uz ve vi vo wa wo xh yi yo za zh zu'.split(
    ' ',
  );
const LANGUAGE_CODES = [...new Set([...ISO_639_1, ...LOCALES])];

// Codes régionaux ISO 3166-1 alpha-2 attribués.
const REGION_CODES = [];
for (let a = 65; a <= 90; a++) {
  for (let b = 65; b <= 90; b++) {
    const code = String.fromCharCode(a, b);
    const name = new Intl.DisplayNames(['en'], { type: 'region', fallback: 'none' }).of(code);
    if (name) REGION_CODES.push(code);
  }
}

const quote = (s) => `'${s.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('$', '\\$')}'`;

function table(type, codes, locale) {
  const dn = new Intl.DisplayNames([locale], { type, fallback: 'none' });
  const rows = [];
  for (const code of codes) {
    const name = dn.of(code);
    // Un code inconnu de CLDR renvoie le code lui-même : on l'écarte.
    if (name && name !== code) rows.push(`    ${quote(code)}: ${quote(name)},`);
  }
  return `  ${quote(locale)}: {\n${rows.join('\n')}\n  },`;
}

const out = `// GÉNÉRÉ par tool/gen_display_names.mjs — ne pas éditer à la main.
// Source : CLDR (Intl.DisplayNames de Node). Clé = étiquette de la langue de l'app.

/// Nom d'un pays (code ISO 3166-1) dans chaque langue.
const Map<String, Map<String, String>> kRegionNames = {
${LOCALES.map((l) => table('region', REGION_CODES, l)).join('\n')}
};

/// Nom d'une langue (code ISO 639-1, ou étiquette de l'app) dans chaque langue.
const Map<String, Map<String, String>> kLanguageNames = {
${LOCALES.map((l) => table('language', LANGUAGE_CODES, l)).join('\n')}
};
`;
writeFileSync(new URL('../lib/l10n/display_names.dart', import.meta.url), out);
console.log(`${REGION_CODES.length} régions, ${LANGUAGE_CODES.length} langues, ${LOCALES.length} locales`);
