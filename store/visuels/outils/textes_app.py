#!/usr/bin/env python3
"""Copie dans textes/<langue>.json, sous la clé `app`, les textes de l'appli que le visuel 1 dessine
(écran d'accueil) : ils viennent de lib/l10n/app_<code>.arb, avec les mêmes clés que l'appli.

    python3 -I store/visuels/outils/textes_app.py

À relancer après chaque traduction de l'appli : le visuel 1 suit ses libellés. Un placeholder ICU
simple (`{count} live`) est gardé tel quel, le gabarit le remplace. Une clé absente d'un .arb, ou un
pluriel/sélecteur ICU, fait échouer le script plutôt que d'écrire un texte faux.
"""
import json
from pathlib import Path

ICI = Path(__file__).resolve().parent.parent
ARB = ICI.parents[1] / "lib/l10n"
# langue des visuels -> code du fichier .arb
LANGUES = {"fr": "fr", "en": "en", "de": "de", "es": "es", "pt-BR": "pt", "zh-Hans": "zh"}
CLES = [
    "homeTitleDefault", "homeTotalVisitorsAll", "homeVsPrevious", "homeLiveCount",
    "periodToday", "period24h", "period7d", "period30d", "periodThisMonth", "period12m",
    "periodThisYear", "periodAllTime", "periodCustom",
    "commonVisitors", "commonPageviews",
    "tabSites", "tabDirect", "tabSettings",
]


def main():
    for langue, code in LANGUES.items():
        arb = json.loads((ARB / f"app_{code}.arb").read_text(encoding="utf-8"))
        app = {}
        for cle in CLES:
            if cle not in arb:
                raise SystemExit(f"{cle} manque dans app_{code}.arb")
            if ", plural," in arb[cle] or ", select," in arb[cle]:
                raise SystemExit(f"{cle} ({code}) : pluriel ou sélecteur ICU, non géré")
            app[cle] = arb[cle]
        chemin = ICI / "textes" / f"{langue}.json"
        textes = json.loads(chemin.read_text(encoding="utf-8"))
        textes["app"] = app
        chemin.write_text(json.dumps(textes, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(langue, "<-", f"app_{code}.arb")


if __name__ == "__main__":
    main()
