#!/usr/bin/env python3
"""Génère les slides marketing Play Store (1080x1920) : 1 cover + 5 slides app."""
import base64, pathlib
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent
ASSETS = ROOT.parent / "assets"
STORE = ROOT.parent.parent            # glance/store
OUT_HTML = ROOT / "html"; OUT_HTML.mkdir(exist_ok=True)

def b64(p): return base64.b64encode(pathlib.Path(p).read_bytes()).decode()

# Recadre les captures paddées (1200x2400, barres crème 60px) -> 1080x2400 pur
def crop_shot(name):
    im = Image.open(ASSETS / name).convert("RGB")
    w, h = im.size
    if w == 1200:
        im = im.crop((60, 0, 1140, h))
    return im

CAPS = {
    "list":   "screenshot-1-list.png",
    "grid":   "screenshot-2-grid.png",
    "detail": "screenshot-3-detail.png",
    "events": "screenshot-4-events.png",
    "live":   "screenshot-5-live.png",
}
cap_b64 = {}
for k, fn in CAPS.items():
    im = crop_shot(fn)
    tmp = ROOT / f"_cap_{k}.png"; im.save(tmp)
    cap_b64[k] = base64.b64encode(tmp.read_bytes()).decode()

icon_b64 = b64(STORE / "icon_master_1024.png")

HEAD = """<meta charset=utf-8>
<link rel=preconnect href=https://fonts.googleapis.com>
<link rel=preconnect href=https://fonts.gstatic.com crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600;700&family=JetBrains+Mono:wght@500;600&display=swap" rel=stylesheet>
<style>
 :root{--bg:#f4f1ec;--fg:#211e19;--fg2:#8c857a;--accent:#3b7a5a;--accent-soft:#e7efe9;--line:rgba(30,25,15,.08)}
 *{margin:0;padding:0;box-sizing:border-box}
 html,body{width:1080px;height:1920px;overflow:hidden}
 body{background:var(--bg);font-family:'Fredoka',sans-serif;position:relative;-webkit-font-smoothing:antialiased}
 .motif{position:absolute;inset:0;z-index:0}
 .wrap{position:absolute;inset:0;z-index:2;display:flex;flex-direction:column}
 .kick{font-family:'JetBrains Mono',monospace;font-weight:600;font-size:30px;letter-spacing:7px;color:var(--accent);text-transform:uppercase}
 .brand-foot{position:absolute;left:0;right:0;bottom:70px;text-align:center;z-index:3;
   font-family:'JetBrains Mono',monospace;font-size:26px;letter-spacing:4px;color:#b4ada1}
</style>"""

def motif():
    return ("<svg class=motif viewBox='0 0 1080 1920' preserveAspectRatio=none>"
            "<path d='M-40 1980 C 200 1980 300 1720 500 1720 C 690 1720 700 1840 900 1840 C 1120 1840 1180 1600 1400 1600' "
            "fill=none stroke='#3b7a5a' stroke-width=9 stroke-linecap=round opacity=.06/>"
            "<path d='M-40 1700 C 220 1700 300 1500 520 1500 C 700 1500 720 1600 920 1600 C 1120 1600 1180 1420 1360 1420' "
            "fill=none stroke='#3b7a5a' stroke-width=7 stroke-linecap=round opacity=.05/></svg>")

def cover():
    chips = "".join(
        f"<div class=chip><span class=e>{e}</span>{t}</div>"
        for e, t in [("⚡","Temps réel"),("📊","Multi-sites"),("🔒","Sans tracking"),("📱","Widgets")])
    return f"""<!doctype html><html><head>{HEAD}<style>
 .cover{{align-items:center;justify-content:center;text-align:center;padding:0 90px}}
 .icon{{width:230px;height:230px;border-radius:56px;box-shadow:0 40px 80px rgba(28,40,32,.20),0 8px 22px rgba(28,40,32,.12);margin-bottom:66px}}
 .word{{font-weight:700;font-size:184px;line-height:.9;letter-spacing:-4px;color:var(--fg)}}
 .sub{{font-weight:500;font-size:56px;line-height:1.25;color:var(--fg2);margin-top:44px;max-width:820px}}
 .sub b{{color:var(--accent);font-weight:600}}
 .chips{{display:flex;flex-wrap:wrap;gap:22px;justify-content:center;margin-top:80px;max-width:840px}}
 .chip{{display:flex;align-items:center;gap:16px;background:#fff;border:1.5px solid var(--line);
   border-radius:999px;padding:22px 38px;font-weight:500;font-size:40px;color:var(--fg);
   box-shadow:0 6px 18px rgba(28,40,32,.05)}}
 .chip .e{{font-size:42px;line-height:1}}
</style></head><body>{motif()}
 <div class="wrap cover">
   <img class=icon src="data:image/png;base64,{icon_b64}">
   <div class=word>Glance</div>
   <div class=sub>Vos analytics <b>Umami</b> &amp; <b>Plausible</b>,<br>d'un coup d'œil.</div>
   <div class=chips>{chips}</div>
 </div>
 <div class=brand-foot>UN PROJET MY-MONKEY 🍌</div>
</body></html>"""

def app_slide(cap, kick, l1, l2, sub):
    return f"""<!doctype html><html><head>{HEAD}<style>
 .head{{padding:150px 90px 0;flex:0 0 auto}}
 h1{{font-weight:600;font-size:98px;line-height:1.02;letter-spacing:-2px;color:var(--fg);margin-top:30px}}
 h1 .acc{{color:var(--accent)}}
 .sub{{font-weight:400;font-size:44px;line-height:1.3;color:var(--fg2);margin-top:34px;max-width:840px}}
 .stage{{position:absolute;left:50%;top:1300px;transform:translate(-50%,-50%);
   width:1180px;height:1180px;border-radius:50%;background:var(--accent-soft);z-index:1;opacity:.75}}
 .phone-wrap{{position:absolute;left:50%;top:800px;transform:translateX(-50%);z-index:2}}
 .phone{{width:560px;background:#0f0e0b;border-radius:66px;padding:15px;
   box-shadow:0 55px 110px rgba(28,40,32,.26),0 14px 34px rgba(28,40,32,.16),inset 0 0 0 2px rgba(255,255,255,.06)}}
 .screen{{border-radius:52px;overflow:hidden;display:block;line-height:0}}
 .screen img{{width:100%;display:block}}
</style></head><body>{motif()}
 <div class=stage></div>
 <div class="wrap"><div class=head>
   <div class=kick>{kick}</div>
   <h1>{l1}<br><span class=acc>{l2}</span></h1>
   <div class=sub>{sub}</div>
 </div></div>
 <div class=phone-wrap><div class=phone><div class=screen>
   <img src="data:image/png;base64,{cap}">
 </div></div></div>
</body></html>"""

SLIDES = [
    ("01-cover", cover()),
    ("02-apercu",  app_slide(cap_b64["list"],   "Vue d'ensemble", "Tous vos sites,", "d'un coup d'œil",
                             "Visiteurs, pages vues, sources — l'essentiel, tout de suite.")),
    ("03-direct",  app_slide(cap_b64["live"],   "Temps réel", "Le trafic,", "en direct",
                             "Qui est là, maintenant, sur chacun de vos sites.")),
    ("04-detail",  app_slide(cap_b64["detail"], "Détail par site", "Chaque site,", "dans le détail",
                             "Courbes lissées, pages, sources, pays, durée, rebond.")),
    ("05-events",  app_slide(cap_b64["events"], "Événements", "Vos événements,", "une couleur chacun",
                             "Suivez vos conversions, filtrables d'un simple tap.")),
    ("06-prive",   app_slide(cap_b64["grid"],   "Soigné & privé", "Liste ou grille,", "zéro tracking",
                             "Glance parle à VOS serveurs. Jamais à un tiers.")),
]
for name, html in SLIDES:
    (OUT_HTML / f"{name}.html").write_text(html, encoding="utf-8")
    print(name)
print("HTML OK ->", OUT_HTML)
