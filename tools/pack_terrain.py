"""Prépare les textures photo du terrain : 1024 px, albédo+AO (RGBA) et normale GL+hauteur (RGB).
Usage : python3 tools/pack_terrain.py <dossier contenant les 6 dossiers *_Photorealiste_2K>"""
import glob, os, sys
import numpy as np
from PIL import Image

SRC = sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "terrain")
NAMES = {"01_Sable_fin": "sand_fine", "02_Sable_croute": "sand_crust", "03_Roche_stratifiee": "rock_strata",
         "04_Roche_sombre": "rock_dark", "05_Epice": "spice", "06_Minerai": "ore"}
S = 1024


def find(folder, kind):
    for f in glob.glob(os.path.join(SRC, folder + "_Photorealiste_2K", folder + "_" + kind + ".*")):
        return Image.open(f)


for folder, name in NAMES.items():
    col = find(folder, "BaseColor").convert("RGB").resize((S, S), Image.LANCZOS)
    ao = find(folder, "AO").convert("L").resize((S, S), Image.LANCZOS)
    nrm = find(folder, "NormalGL").convert("RGB").resize((S, S), Image.LANCZOS)
    hgt = find(folder, "Height").convert("L").resize((S, S), Image.LANCZOS)
    a = np.dstack([np.asarray(col), np.asarray(ao)])
    Image.fromarray(a, "RGBA").save(os.path.join(OUT, name + "_a.png"), optimize=True)
    n = np.asarray(nrm).copy()
    n[..., 2] = np.asarray(hgt)  # le bleu de la normale se reconstruit : on y range la hauteur
    Image.fromarray(n, "RGB").save(os.path.join(OUT, name + "_n.png"), optimize=True)
    print(name, "ok")
