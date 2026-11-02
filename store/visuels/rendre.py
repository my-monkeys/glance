#!/usr/bin/env python3
"""Rend les visuels des stores depuis les gabarits HTML, dans chaque langue de textes/, aux tailles
exactes des stores.

    python3 -I store/visuels/rendre.py                 # tout
    python3 -I store/visuels/rendre.py 4-entonnoir     # un gabarit seulement (tous formats)
    python3 -I store/visuels/rendre.py --langue fr     # une seule langue
    python3 -I store/visuels/rendre.py --site          # les scènes du site, seules (WebP)

Prérequis : Playwright pour Python et Google Chrome (`channel="chrome"`), Pillow. Un petit serveur
HTTP sert la racine du dépôt : les gabarits lisent les polices (`assets/fonts/`) et l'icône
(`store/icon_master.svg`) par leur chemin.

Sortie dans store/visuels/ :
  app-store/iphone-6.9/<langue>/<n>-<nom>.png   1320 × 2868
  app-store/ipad-13/<langue>/<n>-<nom>.png      2064 × 2752
  google-play/telephone/<langue>/<n>-<nom>.png  1080 × 1920
  google-play/presentation-<langue>.png         1024 × 500
  planche.png                                   la planche de contrôle
Avec --site, uniquement les scènes du site (sans l'en-tête marque + titre), dans store/site/img/scenes/ :
  <langue>/<n>-<nom>.webp   scènes 2 à 8, 1320 px de large, hauteur naturelle, < 150 Ko
  1-accueil.webp            le téléphone du visuel 1, commun à toutes les langues (la capture ne change pas)
Tout en PNG RGB 8 bits, sans canal alpha (Apple le refuse).
"""
import argparse
import functools
import http.server
import tempfile
import threading
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from playwright.sync_api import sync_playwright

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
URL_GABARITS = "store/visuels/gabarits"

# Dans l'ordre de la galerie : le premier vend l'appli à lui seul.
VISUELS = ["1-accueil", "2-sites", "3-evenements", "4-entonnoir", "5-retention",
           "6-prevision", "7-direct", "8-appareils"]
FORMATS = {
    "iphone": ("app-store/iphone-6.9", 1320, 2868),
    "ipad": ("app-store/ipad-13", 2064, 2752),
    "play": ("google-play/telephone", 1080, 1920),
}
PRESENTATION = (1024, 500)
SITE = ICI.parent / "site/img/scenes"
SITE_LARGEUR = 1320
SITE_POIDS_MAX = 150_000


def langues():
    """Les langues disponibles : un fichier textes/<langue>.json chacune, fr et en en tête."""
    toutes = sorted(p.stem for p in (ICI / "textes").glob("*.json"))
    return sorted(toutes, key=lambda l: (("fr", "en").index(l) if l in ("fr", "en") else 9, l))


class Silencieux(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def serveur():
    gestion = functools.partial(Silencieux, directory=str(RACINE))
    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), gestion)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def capturer(page, url, largeur, hauteur, sortie):
    page.set_viewport_size({"width": largeur, "height": hauteur})
    page.goto(url)
    page.wait_for_function("window.PRET || window.ERREUR", timeout=30000)
    erreur = page.evaluate("window.ERREUR")
    if erreur:
        raise RuntimeError(f"{url} : {erreur}")
    for probleme in page.evaluate("window.PROBLEMES || []"):
        print(f"  ATTENTION {sortie.name} : {probleme}")
    sortie.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".png") as brut:
        page.screenshot(path=brut.name, animations="disabled")
        enregistrer_rgb(Image.open(brut.name), sortie, (largeur, hauteur))


def enregistrer_rgb(image, sortie, taille):
    if image.size != taille:
        raise RuntimeError(f"{sortie.name} : {image.size} au lieu de {taille}")
    fond = Image.new("RGB", image.size, (255, 255, 255))
    rgba = image.convert("RGBA")
    fond.paste(rgba, mask=rgba.split()[3])
    fond.save(sortie, optimize=True)


def capturer_site(page, url, sortie):
    """La scène seule, à sa hauteur naturelle, en WebP. Le visuel 1 garde un fond transparent."""
    page.set_viewport_size({"width": SITE_LARGEUR, "height": 2400})
    page.goto(url)
    page.wait_for_function("window.PRET || window.ERREUR", timeout=30000)
    erreur = page.evaluate("window.ERREUR")
    if erreur:
        raise RuntimeError(f"{url} : {erreur}")
    sortie.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".png") as brut:
        page.locator("body").screenshot(path=brut.name, animations="disabled", omit_background=True)
        image = Image.open(brut.name)
        enregistrer_webp(image if sortie.name.startswith("1-") else image.convert("RGB"), sortie)


def enregistrer_webp(image, sortie):
    """La meilleure qualité qui tient sous SITE_POIDS_MAX."""
    for qualite in range(88, 40, -4):
        image.save(sortie, quality=qualite, method=6)
        if sortie.stat().st_size <= SITE_POIDS_MAX:
            return
    raise RuntimeError(f"{sortie.name} : {sortie.stat().st_size} octets, plus que {SITE_POIDS_MAX}")


def planche(liste_langues):
    """Tous les visuels : une rangée par format et par langue, plus l'image de présentation."""
    hauteur_vignette = 560
    marge, titre = 24, 64
    police = ImageFont.truetype(str(RACINE / "assets/fonts/Fredoka.ttf"), 40)
    rangees = []
    for langue in liste_langues:
        for dossier, _, _ in FORMATS.values():
            fichiers = [ICI / dossier / langue / f"{v}.png" for v in VISUELS]
            rangees.append((f"{dossier.upper()} - {langue.upper()}", fichiers, hauteur_vignette))
        rangees.append((f"GOOGLE-PLAY/PRESENTATION - {langue.upper()}",
                        [ICI / f"google-play/presentation-{langue}.png"], hauteur_vignette // 2))
    vignettes = []
    for nom, fichiers, haut in rangees:
        images = []
        for f in fichiers:
            im = Image.open(f).convert("RGB")
            images.append(im.resize((round(im.width * haut / im.height), haut), Image.LANCZOS))
        vignettes.append((nom, images))
    largeur = max(sum(i.width for i in ims) + marge * (len(ims) + 1) for _, ims in vignettes)
    hauteur = sum(titre + ims[0].height + marge for _, ims in vignettes) + marge
    feuille = Image.new("RGB", (largeur, hauteur), (232, 224, 207))
    d = ImageDraw.Draw(feuille)
    y = marge
    for nom, images in vignettes:
        d.text((marge, y + 8), nom, font=police, fill=(33, 30, 25))
        x = marge
        for im in images:
            feuille.paste(im, (x, y + titre))
            x += im.width + marge
        y += titre + images[0].height + marge
    feuille.save(ICI / "planche.png", optimize=True)


def rendre_site(page, base, filtre, liste_langues):
    for visuel in VISUELS:
        if filtre and visuel not in filtre:
            continue
        # Le téléphone du visuel 1 ne porte aucun texte : une seule image pour toutes les langues.
        for langue in liste_langues[:1] if visuel == VISUELS[0] else liste_langues:
            sortie = SITE / ("" if visuel == VISUELS[0] else langue) / f"{visuel}.webp"
            capturer_site(page, f"{base}/{visuel}.html?lang={langue}&format=site", sortie)
            print(sortie.relative_to(SITE.parent.parent), sortie.stat().st_size // 1024, "Ko")


def main():
    analyse = argparse.ArgumentParser()
    analyse.add_argument("gabarits", nargs="*")
    analyse.add_argument("--langue", action="append")
    analyse.add_argument("--site", action="store_true", help="rendre les scènes du site au lieu des visuels des stores")
    args = analyse.parse_args()
    filtre = args.gabarits
    liste_langues = args.langue or langues()
    httpd = serveur()
    base = f"http://127.0.0.1:{httpd.server_port}/{URL_GABARITS}"
    with sync_playwright() as p:
        navigateur = p.chromium.launch(channel="chrome")
        page = navigateur.new_page(device_scale_factor=1)
        if args.site:
            rendre_site(page, base, filtre, liste_langues)
            navigateur.close()
            httpd.shutdown()
            return
        for visuel in VISUELS:
            if filtre and visuel not in filtre:
                continue
            for langue in liste_langues:
                for cle, (dossier, w, h) in FORMATS.items():
                    sortie = ICI / dossier / langue / f"{visuel}.png"
                    capturer(page, f"{base}/{visuel}.html?lang={langue}&format={cle}", w, h, sortie)
                    print(sortie.relative_to(ICI))
        if not filtre or "presentation" in filtre:
            for langue in liste_langues:
                sortie = ICI / f"google-play/presentation-{langue}.png"
                capturer(page, f"{base}/presentation.html?lang={langue}&format=presentation", *PRESENTATION, sortie)
                print(sortie.relative_to(ICI))
        navigateur.close()
    httpd.shutdown()
    if not filtre and not args.langue:
        planche(liste_langues)
        print("planche.png")


if __name__ == "__main__":
    main()
