#!/usr/bin/env python3
"""Importe un kit HUD « ORIGINAL » (zip) vers res://assets/ui/<faction>/.
Usage : python3 tools/import_kit.py kit.zip solis
- recadre chaque PNG sur sa zone opaque ;
- mesure la zone intérieure sombre des panneaux (là où le contenu dynamique est dessiné) ;
- écrit skin.json : { inner: {nom: [x, y, w, h] en fractions}, size: {nom: [w, h]} }."""
import sys, zipfile, io, os, json, re
import numpy as np
from PIL import Image, ImageFilter

PANELS = ["panneau_objectifs", "panneau_journal", "panneau_selection", "panneau_selection_compact", "panneau_construction",
          "panneau_construction_compact", "entete_faction", "radar", "cadre_portrait", "vignette_normal", "vignette_verrouillee",
          "compteur_ressource", "barre_ressources", "bouton_normal", "onglet_actif", "onglet_inactif", "panneau_alerte",
          "slot_production", "badge_quantite", "progression_fond"]


def largest_rect(mask):
    h, w = mask.shape
    heights = np.zeros(w, dtype=int)
    best = (0, 0, 0, 0, 0)
    for y in range(h):
        heights = np.where(mask[y], heights + 1, 0)
        stack = []
        for x in range(w + 1):
            cur = heights[x] if x < w else 0
            start = x
            while stack and stack[-1][1] >= cur:
                sx, sh = stack.pop()
                area = sh * (x - sx)
                if area > best[0]:
                    best = (area, sx, y - sh + 1, x - sx, sh)
                start = sx
            stack.append((start, cur))
    return best


def expand(mask, rect):
    """Agrandit le rectangle tant que la ligne/colonne ajoutée est à 90 % dans le masque."""
    h, w = mask.shape
    x, y, rw, rh = rect
    ok = True
    while ok:
        ok = False
        if x > 0 and mask[y:y + rh, x - 1].mean() > 0.9:
            x -= 1; rw += 1; ok = True
        if x + rw < w and mask[y:y + rh, x + rw].mean() > 0.9:
            rw += 1; ok = True
        if y > 0 and mask[y - 1, x:x + rw].mean() > 0.9:
            y -= 1; rh += 1; ok = True
        if y + rh < h and mask[y + rh, x:x + rw].mean() > 0.9:
            rh += 1; ok = True
    return x, y, rw, rh


SHAPES = {}
MANUAL_F = {"solis": {"vignette_normal": [0.15, 0.28, 0.70, 0.44]},
            "kharn": {"vignette_normal": [0.27, 0.185, 0.56, 0.54], "entete_faction": [0.2, 0.28, 0.6, 0.4]},
            "vael": {"vignette_normal": [0.13, 0.245, 0.66, 0.53], "entete_faction": [0.25, 0.55, 0.5, 0.22]},
            "conclave": {"vignette_normal": [0.225, 0.32, 0.655, 0.50], "entete_faction": [0.2, 0.6, 0.6, 0.22]}}
MANUAL = {
    "barre_ressources": [0.07, 0.45, 0.86, 0.38], "compteur_ressource": [0.42, 0.45, 0.50, 0.40],
    "bouton_normal": [0.12, 0.2, 0.76, 0.58], "entete_faction": [0.12, 0.62, 0.76, 0.22],
    "vignette_normal": [0.1, 0.3, 0.8, 0.5], "onglet_actif": [0.1, 0.45, 0.8, 0.42],
    "onglet_inactif": [0.1, 0.45, 0.8, 0.42], "slot_production": [0.2, 0.35, 0.6, 0.58],
    "panneau_alerte": [0.1, 0.5, 0.8, 0.38], "progression_fond": [0.04, 0.3, 0.92, 0.42],
}
CIRCLES = ["radar", "cadre_portrait"]


def inner_rect(im, name):
    s = 4
    small = im.convert("RGBA").resize((max(8, im.width // s), max(8, im.height // s)), Image.BILINEAR)
    b = np.asarray(small).astype(float)
    lum = 0.3 * b[..., 0] + 0.59 * b[..., 1] + 0.11 * b[..., 2]
    gy, gx = np.gradient(lum)
    grad = np.hypot(gx, gy)
    mask = (b[..., 3] > 240) & (lum < 85) & (grad < 12)
    m = Image.fromarray((mask * 255).astype("uint8")).filter(ImageFilter.MinFilter(3))
    mask = np.asarray(m) > 128
    area, x, y, w, h = largest_rect(mask)
    sh, sw = mask.shape
    if area < 20:
        return [0.1, 0.1, 0.8, 0.8]
    if name in CIRCLES:
        # disque : boîte englobante de la zone sombre connexe au centre du plus grand rectangle
        from collections import deque
        seen = np.zeros_like(mask)
        q = deque([(y + h // 2, x + w // 2)])
        seen[y + h // 2, x + w // 2] = True
        x0, y0, x1, y1 = sw, sh, 0, 0
        while q:
            cy, cx = q.popleft()
            x0, y0, x1, y1 = min(x0, cx), min(y0, cy), max(x1, cx), max(y1, cy)
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < sh and 0 <= nx < sw and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
        r = min(x1 - x0, y1 - y0) / 2.0 * 0.97
        fill = seen.sum() / float(max(1, (x1 - x0 + 1) * (y1 - y0 + 1)))
        SHAPES[name] = "square" if fill > 0.88 else "circle"
        if SHAPES[name] == "square":
            return [round(x0 / sw, 4), round(y0 / sh, 4), round((x1 - x0 + 1) / sw, 4), round((y1 - y0 + 1) / sh, 4)]
        return [round((cx - r) / sw, 4), round((cy - r) / sh, 4), round(2 * r / sw, 4), round(2 * r / sh, 4)]
    x, y, w, h = expand(mask, (x, y, w, h))
    pad = 0.012
    return [round(x / sw + pad, 4), round(y / sh + pad, 4), round(w / sw - 2 * pad, 4), round(h / sh - 2 * pad, 4)]


def hole_rect(im, inner):
    """Emplacement de portrait intégré au panneau de sélection (zone sombre dans le tiers gauche)."""
    s = 4
    small = im.convert("RGBA").resize((max(8, im.width // s), max(8, im.height // s)), Image.BILINEAR)
    b = np.asarray(small).astype(float)
    lum = 0.3 * b[..., 0] + 0.59 * b[..., 1] + 0.11 * b[..., 2]
    gy, gx = np.gradient(lum)
    mask = (b[..., 3] > 240) & (lum < 85) & (np.hypot(gx, gy) < 12)
    sh, sw = mask.shape
    mask[:, int(sw * (inner[0] - 0.02)):] = False
    mask = np.asarray(Image.fromarray((mask * 255).astype("uint8")).filter(ImageFilter.MinFilter(3))) > 128
    area, x, y, w, h = largest_rect(mask)
    if area < 20:
        return [0.03, 0.2, 0.12, 0.6]
    x, y, w, h = expand(mask, (x, y, w, h))
    return [round(x / sw, 4), round(y / sh, 4), round(w / sw, 4), round(h / sh, 4)]


def main():
    zip_path, fid = sys.argv[1], sys.argv[2]
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "ui", fid)
    if os.path.isdir(out):
        for f in os.listdir(out):
            os.remove(os.path.join(out, f))
    os.makedirs(out, exist_ok=True)
    z = zipfile.ZipFile(zip_path)
    skin = {"inner": {}, "size": {}}
    for n in z.namelist():
        m = re.match(r"(?:.*/)?PNG/(.+)\.png$", n)
        if not m:
            continue
        name = m.group(1)
        im = Image.open(io.BytesIO(z.read(n))).convert("RGBA")
        bbox = im.getchannel("A").point(lambda v: 255 if v > 10 else 0).getbbox()
        if bbox:
            im = im.crop(bbox)
        im.save(os.path.join(out, name + ".png"), optimize=True)
        skin["size"][name] = [im.width, im.height]
        if name in PANELS:
            r = MANUAL_F.get(fid, {}).get(name) or MANUAL.get(name) or inner_rect(im, name)
            skin["inner"][name] = r
            if name == "panneau_selection":
                skin["inner"]["selection_portrait"] = hole_rect(im, r)
    skin["shape"] = SHAPES
    json.dump(skin, open(os.path.join(out, "skin.json"), "w"))
    print("ok", fid, len(skin["size"]))


if __name__ == "__main__" and not (len(sys.argv) > 3 and sys.argv[3] == "compact"):
    main()


# --- Kit « HUD COMPACT » (cadres simples, un PNG par composant) -------------------------------
COMPACT_MAP = {
    "01_barre_ressources": ["barre_ressources"], "02_panneau_objectifs": ["panneau_objectifs"],
    "03_journal": ["panneau_journal"], "04_colonne_construction": ["panneau_construction", "panneau_construction_compact"],
    "05_fiche_selection": ["panneau_selection", "panneau_selection_compact"], "06_radar": ["radar"],
    "07_carte_batiment": ["vignette_normal", "vignette_verrouillee"], "08_cadre_portrait": ["cadre_portrait"],
    "09_onglet_normal": ["onglet_inactif"], "10_onglet_actif": ["onglet_actif"], "11_bouton_normal": ["bouton_normal"],
    "12_bouton_survol": ["bouton_actif", "bouton_presse"], "14_jauge_vide": ["progression_fond"],
    "15_jauge_pleine": ["progression_remplissage"], "16_embleme": ["embleme"], "17_alerte": ["panneau_alerte"],
    "18_file_production": ["slot_production"], "19_puce_information": ["entete_faction"],
}


def import_compact(zip_path, fid):
    """Remplace les cadres d'une faction par ceux d'un kit compact ; garde les icônes existantes."""
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "ui", fid)
    sk = json.load(open(os.path.join(out, "skin.json")))
    z = zipfile.ZipFile(zip_path)
    for n in z.namelist():
        m = re.match(r"(?:.*/)?PNG_2K/(.+)\.png$", n)
        if not m or m.group(1) not in COMPACT_MAP:
            continue
        im = Image.open(io.BytesIO(z.read(n))).convert("RGBA")
        bbox = im.getchannel("A").point(lambda v: 255 if v > 10 else 0).getbbox()
        if bbox:
            im = im.crop(bbox)
        im.thumbnail((1400, 1400), Image.LANCZOS)
        for name in COMPACT_MAP[m.group(1)]:
            im.save(os.path.join(out, name + ".png"), optimize=True)
            sk["size"][name] = [im.width, im.height]
            if name in PANELS:
                r = inner_rect(im, name)
                sk["inner"][name] = r
                if name == "panneau_selection":
                    sk["inner"]["selection_portrait"] = hole_rect(im, r)
                print(name, r)
    sk["shape"].update(SHAPES)
    json.dump(sk, open(os.path.join(out, "skin.json"), "w"))


if __name__ == "__main__" and len(sys.argv) > 3 and sys.argv[3] == "compact":
    import_compact(sys.argv[1], sys.argv[2])
