#!/usr/bin/env python3
import base64, pathlib

SS = pathlib.Path("/private/tmp/claude-501/-Users-maxim-Documents-my-monkey/799e2fd3-1fb3-46c4-8cb1-d4f99d7e27ec/scratchpad")
OUT = SS / "shots"
OUT.mkdir(exist_ok=True)

# (fichier capture, slug, kicker, ligne 1, ligne 2 (accent))
SLIDES = [
    ("s_list.png",   "01-apercu",     "VUE D'ENSEMBLE",  "Tous vos sites,",     "d'un coup d'œil"),
    ("s_events.png", "02-events",     "ÉVÉNEMENTS",      "Vos événements,",     "une couleur chacun"),
    ("s_detail.png", "03-detail",     "DÉTAIL PAR SITE",  "Chaque site,",        "dans le détail"),
    ("s_grid.png",   "04-grille",     "AFFICHAGE",       "Liste ou grille,",    "comme vous voulez"),
    ("s_direct.png", "05-direct",     "TEMPS RÉEL",       "Le trafic,",          "en temps réel"),
]

TPL = """<!doctype html><html lang=fr><head><meta charset=utf-8>
<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=JetBrains+Mono:wght@500&display=swap" rel=stylesheet>
<style>
  :root{{--bg:#f7f5f1;--fg:#211e19;--fg2:#8c857a;--accent:#3b7a5a;--stage:#e7efe9;--line:rgba(30,25,15,.08)}}
  *{{margin:0;padding:0;box-sizing:border-box}}
  html,body{{width:1290px;height:2796px;overflow:hidden}}
  body{{background:var(--bg);font-family:'Fredoka',sans-serif;position:relative}}
  /* motif sparkline très discret, écho de l'icône */
  .motif{{position:absolute;inset:0;z-index:0}}
  .cap{{position:absolute;left:0;right:0;top:170px;text-align:center;z-index:2;padding:0 90px}}
  .kick{{font-family:'JetBrains Mono',monospace;font-weight:500;font-size:31px;letter-spacing:6px;color:var(--accent);text-transform:uppercase}}
  h1{{font-weight:600;font-size:104px;line-height:1.03;letter-spacing:-1.5px;color:var(--fg);margin-top:26px}}
  h1 .acc{{color:var(--accent)}}
  .stage{{position:absolute;left:50%;top:1690px;transform:translate(-50%,-50%);
          width:1090px;height:1160px;background:var(--stage);border-radius:150px;z-index:1}}
  .phone-wrap{{position:absolute;left:50%;top:735px;transform:translateX(-50%);z-index:3}}
  .phone{{width:900px;background:#0f0e0b;border-radius:94px;padding:18px;
          box-shadow:0 60px 120px rgba(28,40,32,.28),0 12px 30px rgba(28,40,32,.18),
                     inset 0 0 0 2px rgba(255,255,255,.06)}}
  .screen{{border-radius:78px;overflow:hidden;display:block;line-height:0}}
  .screen img{{width:100%;display:block}}
</style></head><body>
  <svg class=motif viewBox="0 0 1290 2796" preserveAspectRatio="none">
    <path d="M-40 2560 C 220 2560 330 2360 520 2360 C 690 2360 700 2470 900 2470 C 1120 2470 1180 2250 1360 2250"
          fill=none stroke="{accent}" stroke-width=10 stroke-linecap=round opacity=".07"/>
  </svg>
  <div class=stage></div>
  <div class=cap>
    <div class=kick>{kick}</div>
    <h1>{l1}<br><span class=acc>{l2}</span></h1>
  </div>
  <div class=phone-wrap><div class=phone><div class=screen>
    <img src="data:image/png;base64,{b64}">
  </div></div></div>
</body></html>"""

for fn, slug, kick, l1, l2 in SLIDES:
    b64 = base64.b64encode((SS / fn).read_bytes()).decode()
    html = TPL.format(accent="#3b7a5a", kick=kick, l1=l1, l2=l2, b64=b64)
    (OUT / f"{slug}.html").write_text(html, encoding="utf-8")
    print(slug)
print("OK", OUT)
