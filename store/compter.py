#!/usr/bin/env python3
"""Compte les caractères des textes des fiches et les compare aux limites des stores.

    python3 -I store/compter.py

Lit les blocs (citations `> …` et blocs de code) qui suivent chaque titre en gras de
`fiches/app-store.md` et `fiches/google-play.md`, et sort en code 1 si un texte dépasse sa limite.
Pour les mots-clés App Store, vérifie aussi qu'aucun mot n'est répété.
"""
import re
import sys
from pathlib import Path

ICI = Path(__file__).parent
LIMITE = re.compile(r"^\*\*(.+?)\*\*\s*\[(\d+)\]")


def textes(chemin):
    lignes = chemin.read_text(encoding="utf-8").splitlines()
    section, i = "", 0
    while i < len(lignes):
        ligne = lignes[i]
        if ligne.startswith("## "):
            section = ligne[3:].strip()
        m = LIMITE.match(ligne)
        if m:
            nom, limite = m.group(1), int(m.group(2))
            j = i + 1
            while j < len(lignes) and not lignes[j].strip():
                j += 1
            if j < len(lignes) and lignes[j].startswith("```"):
                k = j + 1
                while not lignes[k].startswith("```"):
                    k += 1
                texte = "\n".join(lignes[j + 1:k])
            elif j < len(lignes) and lignes[j].startswith(">"):
                texte = lignes[j].lstrip("> ").strip()
            else:
                texte = None
            if texte is not None:
                yield section or "Général", nom, limite, texte
        i += 1


def main():
    trop = False
    for fichier in ("fiches/app-store.md", "fiches/google-play.md"):
        print(f"\n{fichier}")
        for section, nom, limite, texte in textes(ICI / fichier):
            n = len(texte)
            ok = n <= limite
            trop |= not ok
            print(f"  {'ok ' if ok else 'TROP'} {n:5d}/{limite:<5d} {section} — {nom}")
            if nom.lower().startswith(("mots-clés", "keywords")):
                mots = texte.split(",")
                doublons = {m for m in mots if mots.count(m) > 1}
                if doublons or " " in texte:
                    trop = True
                    print(f"  ERREUR mots-clés : doublons {sorted(doublons)} ou espaces")
    sys.exit(1 if trop else 0)


if __name__ == "__main__":
    main()
