#!/usr/bin/env python3
"""Importe un pack HUD de faction (zip) vers res://assets/ui/<faction>/.
Usage : python3 tools/import_hud.py pack.zip solis
Les PNG sont réduits de moitié (réf. 2560x1440 -> 1280) et renommés sans le préfixe numérique."""
import sys, zipfile, json, re, io, os
from PIL import Image
zip_path, fid = sys.argv[1], sys.argv[2]
out = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", fid)
os.makedirs(out, exist_ok=True)
z = zipfile.ZipFile(zip_path)
for n in z.namelist():
    m = re.match(r"PNG/\d+_(.+)\.png$", n)
    if m:
        im = Image.open(io.BytesIO(z.read(n))).convert("RGBA")
        im = im.resize((max(1, im.width // 2), max(1, im.height // 2)), Image.LANCZOS)
        im.save(os.path.join(out, m.group(1) + ".png"), optimize=True)
    elif n == "manifest.json":
        man = json.loads(z.read(n))
        json.dump({"accent": man.get("accent"), "faction": man.get("faction")}, open(os.path.join(out, "skin.json"), "w"))
print("ok", out)
