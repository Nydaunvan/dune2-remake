class_name ModelsExt
## Modèles 3D paramétrés des unités et bâtiments ajoutés par faction.
## Chaque identifiant a une entrée dans STYLES : "k" (famille) + paramètres de forme.
## Models.build() s'en sert pour tout identifiant qu'il ne connaît pas.
##
## Unités au sol  : k = "tank"
## Unités aériennes : k = "jet" | "bomber" | "copter" | "drone"
## Bâtiments       : k = "hall" | "dome" | "pylon" | "gen" | "farm" | "hangar" | "tower" | "wall" | "citadel"

const GLOWS := {
	"orange": Color(1.0, 0.45, 0.12), "blue": Color(0.25, 0.8, 1.0), "green": Color(0.35, 1.0, 0.5),
	"magenta": Color(1.0, 0.3, 0.9), "violet": Color(0.72, 0.42, 1.0), "red": Color(1.0, 0.25, 0.2),
	"gold": Color(1.0, 0.8, 0.3), "white": Color(0.95, 0.97, 1.0),
}
const DARK := Color(0.13, 0.14, 0.18)
const METAL := Color(0.42, 0.45, 0.52)
const LIGHT := Color(0.74, 0.77, 0.84)
const OBSIDIAN := Color(0.16, 0.12, 0.24)

## --- Styles : Solis -------------------------------------------------------------------------
const STYLES := {
	# Unités au sol
	"pisteur": {"k": "tank", "w": true, "l": 22, "sp": 7.5, "hl": 24, "hh": 4, "hw": 10, "tsx": 7, "tsy": 4, "tsz": 7,
			"bn": 1, "bl": 9, "br": 0.9, "x": ["dish", "antenna"], "gc": "blue"},
	"brise_mur": {"k": "tank", "l": 32, "sp": 9, "hl": 30, "hh": 7, "hw": 16, "tsx": 10, "tsy": 5, "tsz": 12, "bn": 0,
			"x": ["bigdish", "skirts"], "gc": "blue"},
	"citadelle": {"k": "tank", "l": 38, "sp": 11, "tw": 8, "th": 9, "hl": 36, "hh": 8, "hw": 20, "tsx": 18, "tsy": 8, "tsz": 17,
			"bn": 2, "bl": 22, "br": 2.0, "bz": 4.5, "x": ["skirts", "armor", "stacks"], "gc": "blue"},
	"technicien": {"k": "tank", "l": 30, "sp": 8.5, "hl": 28, "hh": 6, "hw": 14, "tsx": 12, "tsy": 8, "tsz": 12, "bn": 0,
			"x": ["cross", "antenna", "dome"], "gc": "green"},
	"cirrus": {"k": "tank", "l": 34, "sp": 9.5, "hl": 32, "hh": 6, "hw": 16, "tsx": 14, "tsy": 5, "tsz": 14, "bn": 0,
			"x": ["rack", "dish"], "gc": "blue"},
	"diapason": {"k": "tank", "l": 34, "sp": 9, "hl": 32, "hh": 7, "hw": 16, "tsx": 14, "tsy": 4, "tsz": 13, "bn": 0,
			"x": ["mortar", "skirts", "dish"], "gc": "blue"},
	# Unités aériennes
	"foudre": {"k": "copter", "bl": 28, "bw": 12, "rr": 22, "rn": 4, "pods": 2, "gc": "red", "gun": true},
	"vigie": {"k": "drone", "s": 1.0, "gc": "blue"},
	# Bâtiments Solis
	"atelier_solis": {"k": "hall", "sz": Vector2(96, 64), "h": 18, "gc": "blue", "chim": true},
	"clinique_solis": {"k": "dome", "sz": Vector2(64, 64), "gc": "green"},
	"tour_laser": {"k": "tower", "bn": 1, "bl": 24, "br": 1.3, "hx": 20, "hh": 8, "gc": "red", "x": ["coil"]},
	"mortier_lourd": {"k": "tower", "base": "block", "hy": 22, "hcyl": true, "bn": 1, "bl": 15, "br": 3.6, "hx": 24, "hh": 8, "gc": "orange"},
	"pylone_egide": {"k": "pylon", "sz": Vector2(64, 64), "n": 3, "h": 22, "gc": "blue"},
	"comptoir_solis": {"k": "hall", "sz": Vector2(96, 64), "h": 14, "gc": "gold"},
	"cellule_fusion": {"k": "gen", "sz": Vector2(64, 64), "h": 22, "gc": "blue"},
	"hangar_solis": {"k": "hangar", "sz": Vector2(96, 64), "h": 18, "gc": "blue"},
	"observatoire": {"k": "dome", "sz": Vector2(64, 64), "gc": "white"},
	"canon_solaire": {"k": "tower", "base": "super", "sz": Vector2(96, 96), "hy": 28, "hx": 30, "hh": 12, "bn": 1, "bl": 34, "br": 4.0, "gc": "gold", "x": ["coil"]},
	# Mechas (marcheurs) : Solis
	"phalange": {"k": "mech", "leg": "biped", "kn": -1.0, "lt": 3.8, "lh": 16, "lz": 6, "tl": 11, "th": 11, "tw": 15, "hx": 9, "wp": "laser", "bl": 14,
			"hd": "dome", "x": ["antenna"], "gc": "blue"},
	"archonte": {"k": "mech", "leg": "quad", "h": 22, "bw": 13, "bl": 26, "bh": 8, "lt": 3.2, "wp": "plasma", "cl": 26,
			"x": ["pack"], "gc": "blue", "s": 1.05},
	# Mechas Kharn
	"cogneur": {"k": "mech", "leg": "biped", "kn": 1.0, "lt": 6.5, "lh": 13, "lz": 8, "tl": 16, "th": 14, "tw": 22, "hx": 9, "wp": "fists", "fl": 14,
			"x": ["plates", "stacks"], "gc": "orange", "s": 1.0},
	"gladiateur": {"k": "mech", "leg": "biped", "kn": 1.0, "lt": 5.0, "lh": 15, "lz": 7, "tl": 13, "th": 12, "tw": 18, "hx": 9, "wp": "mg", "bl": 12,
			"x": ["plates", "antenna"], "gc": "red"},
	"mastodonte": {"k": "mech", "leg": "quad", "h": 15, "bw": 24, "bl": 32, "bh": 13, "lt": 6.5, "wp": "rockets",
			"x": ["stacks", "plates"], "gc": "orange", "s": 1.12},
	# Mechas Conclave
	"geode": {"k": "mech", "leg": "crystal", "mk": "geode", "gc": "violet"},
	"stele": {"k": "mech", "leg": "crystal", "mk": "stele", "gc": "violet", "s": 0.82},
	"cariatide": {"k": "mech", "leg": "biped", "obs": true, "kn": 1.0, "lt": 7.5, "lh": 17, "lz": 9, "tl": 17, "th": 16, "tw": 24, "hx": 9, "wp": "fists",
			"x": ["crystals", "crown", "cracks", "plates"], "gc": "violet", "s": 1.12},
	# Mechas Vael
	"tarentule": {"k": "mech", "leg": "spider", "h": 12, "bw": 9, "bl": 8, "ab": 6.5, "lt": 2.0, "gc": "green", "s": 0.95},
	"mygale": {"k": "mech", "leg": "spider", "h": 15, "bw": 12, "bl": 14, "ab": 8.5, "lt": 3.0, "fangs": true, "gc": "green", "s": 1.08},
	# Unités et bâtiments du Conclave
	"tesson": {"k": "tank", "w": true, "l": 24, "sp": 8, "hl": 24, "hh": 4, "hw": 10, "tsx": 7, "tsy": 4, "tsz": 7, "bn": 1, "bl": 9, "br": 0.9, "x": ["crystals"], "gc": "violet"},
	"fracasseur": {"k": "tank", "l": 32, "sp": 9, "hl": 30, "hh": 7, "hw": 16, "tsx": 8, "tsy": 5, "tsz": 12, "bn": 0, "x": ["ram", "crystals"], "gc": "violet"},
	"monolithe": {"k": "tank", "l": 40, "sp": 12, "tw": 8, "th": 9, "hl": 38, "hh": 9, "hw": 22, "tsx": 18, "tsy": 8, "tsz": 18, "bn": 2, "bl": 22, "br": 2.0, "bz": 5, "x": ["skirts", "armor", "crystals"], "gc": "violet"},
	"veilleur": {"k": "tank", "w": true, "l": 28, "sp": 9, "hl": 28, "hh": 6, "hw": 13, "tsx": 10, "tsy": 8, "tsz": 11, "bn": 0, "x": ["cross", "crystals"], "gc": "green"},
	"aiguille": {"k": "tank", "l": 32, "sp": 9, "hl": 30, "hh": 6, "hw": 15, "tsx": 12, "tsy": 5, "tsz": 13, "bn": 3, "bl": 14, "br": 1.0, "bz": 4, "x": ["crystals", "dish"], "gc": "violet"},
	"quartz": {"k": "tank", "l": 34, "sp": 9.5, "hl": 32, "hh": 7, "hw": 16, "tsx": 14, "tsy": 4, "tsz": 13, "bn": 0, "x": ["mortar", "crystals"], "gc": "violet"},
	"scintille": {"k": "jet", "l": 32, "span": 28, "ww": 8, "eng": 1, "tail": "twin", "gc": "violet", "bn": 2},
	"aurore": {"k": "copter", "bl": 26, "bw": 12, "rr": 23, "rn": 3, "pods": 2, "gc": "violet", "gun": true},
	"sanctuaire": {"k": "hall", "sz": Vector2(96, 64), "h": 18, "gc": "violet"},
	"source_vive": {"k": "dome", "sz": Vector2(64, 64), "gc": "violet"},
	"tour_geode": {"k": "tower", "base": "crystal", "hcyl": true, "hx": 24, "hh": 10, "bn": 2, "bl": 18, "br": 2.0, "bz": 7, "gc": "violet", "x": ["crystal"]},
	"tour_aiguille": {"k": "tower", "base": "crystal", "hx": 20, "hh": 8, "bn": 3, "bl": 16, "br": 1.0, "bz": 5, "gc": "violet", "x": ["crystal"]},
	"cairn_cristal": {"k": "pylon", "sz": Vector2(64, 64), "n": 3, "h": 18, "gc": "violet"},
	"filon_vivant": {"k": "farm", "sz": Vector2(96, 64), "n": 3, "h": 20, "gc": "violet"},
	"reliquaire": {"k": "gen", "sz": Vector2(64, 64), "h": 20, "gc": "violet"},
	"hangar_conclave": {"k": "hangar", "sz": Vector2(96, 64), "h": 16, "gc": "violet"},
	"nova_cristal": {"k": "tower", "base": "super", "sz": Vector2(96, 96), "hy": 28, "hx": 30, "hh": 12, "bn": 1, "bl": 30, "br": 4.0, "gc": "violet", "x": ["crystal"]},
	# Unités et bâtiments Vael
	"rat_sable": {"k": "tank", "w": true, "l": 22, "sp": 7.5, "hl": 22, "hh": 4, "hw": 9, "tsx": 7, "tsy": 4, "tsz": 7, "bn": 1, "bl": 9, "br": 0.9, "x": ["antenna"], "gc": "green"},
	"saboteur": {"k": "tank", "w": true, "l": 28, "sp": 8.5, "hl": 28, "hh": 6, "hw": 13, "tsx": 10, "tsy": 5, "tsz": 10, "bn": 1, "bl": 10, "br": 1.8, "x": ["tank", "ram"], "gc": "green"},
	"scorpion": {"k": "tank", "l": 36, "sp": 10, "hl": 34, "hh": 7, "hw": 17, "tsx": 14, "tsy": 6, "tsz": 13, "bn": 1, "bl": 20, "br": 1.8, "x": ["tank", "skirts", "crystals"], "gc": "green"},
	"guerisseur": {"k": "tank", "w": true, "l": 28, "sp": 9, "hl": 28, "hh": 7, "hw": 14, "tsx": 12, "tsy": 8, "tsz": 12, "bn": 0, "x": ["cross", "dome"], "gc": "green"},
	"harpon": {"k": "tank", "w": true, "l": 32, "sp": 9, "hl": 32, "hh": 6, "hw": 15, "tsx": 14, "tsy": 5, "tsz": 14, "bn": 0, "x": ["rack"], "gc": "green"},
	"cracheur": {"k": "tank", "l": 34, "sp": 9.5, "hl": 32, "hh": 7, "hw": 16, "tsx": 14, "tsy": 4, "tsz": 13, "bn": 0, "x": ["mortar", "tank"], "gc": "green"},
	"cigale": {"k": "drone", "s": 0.9, "gc": "green"},
	"milan": {"k": "jet", "l": 30, "span": 36, "ww": 8, "eng": 1, "tail": "twin", "gc": "green", "bn": 2},
	"cobra": {"k": "copter", "bl": 26, "bw": 11, "rr": 24, "rn": 3, "pods": 2, "gc": "green", "gun": true},
	"bureau_vael": {"k": "hall", "sz": Vector2(96, 64), "h": 16, "gc": "gold"},
	"apothicaire": {"k": "dome", "sz": Vector2(64, 64), "gc": "green"},
	"tour_toxine": {"k": "tower", "hcyl": true, "hx": 22, "hh": 9, "bn": 1, "bl": 20, "br": 2.4, "gc": "green"},
	"lanceur_spores": {"k": "tower", "base": "block", "hy": 22, "hcyl": true, "bl": 14, "br": 3.2, "bn": 1, "hx": 24, "hh": 8, "gc": "green"},
	"nid_guepes": {"k": "tower", "hx": 22, "hh": 8, "bn": 2, "bl": 18, "br": 1.1, "bz": 6, "gc": "gold"},
	"caravanserail": {"k": "farm", "sz": Vector2(96, 64), "n": 3, "h": 18, "gc": "gold"},
	"generateur_vael": {"k": "gen", "sz": Vector2(64, 64), "h": 20, "gc": "green"},
	"hangar_vael": {"k": "hangar", "sz": Vector2(96, 64), "h": 16, "gc": "gold"},
	"pluie_acide": {"k": "tower", "base": "super", "sz": Vector2(96, 96), "hy": 28, "hx": 30, "hh": 12, "bn": 1, "bl": 34, "br": 4.0, "gc": "green", "x": ["coil"]},
	# Unités et bâtiments Kharn
	"rodeur": {"k": "tank", "w": true, "l": 24, "sp": 8, "hl": 24, "hh": 5, "hw": 11, "tsx": 8, "tsy": 4, "tsz": 8, "bn": 2, "bl": 8, "br": 0.9, "bz": 3, "gc": "orange"},
	"demolisseur": {"k": "tank", "l": 36, "sp": 10, "tw": 8, "th": 8, "hl": 34, "hh": 8, "hw": 18, "tsx": 8, "tsy": 5, "tsz": 14, "bn": 0, "x": ["ram", "skirts"], "gc": "orange"},
	"titan": {"k": "tank", "l": 44, "sp": 13, "tw": 9, "th": 10, "hl": 42, "hh": 10, "hw": 24, "tsx": 22, "tsy": 9, "tsz": 20, "bn": 2, "bl": 26, "br": 2.4, "bz": 6, "x": ["skirts", "armor", "stacks"], "gc": "orange"},
	"brasier": {"k": "tank", "l": 32, "sp": 9, "hl": 30, "hh": 6, "hw": 15, "tsx": 12, "tsy": 6, "tsz": 12, "bn": 1, "bl": 12, "br": 2.2, "x": ["tank", "stacks"], "gc": "orange"},
	"obusier": {"k": "tank", "l": 38, "sp": 11, "hl": 36, "hh": 8, "hw": 18, "tsx": 14, "tsy": 5, "tsz": 14, "bn": 0, "x": ["mortar", "skirts", "stacks"], "gc": "orange"},
	"depanneuse": {"k": "tank", "l": 34, "sp": 10, "hl": 32, "hh": 7, "hw": 17, "tsx": 12, "tsy": 8, "tsz": 13, "bn": 0, "x": ["cross", "ram", "antenna"], "gc": "green"},
	"aigle": {"k": "jet", "l": 36, "span": 30, "ww": 10, "eng": 2, "tail": "single", "gc": "red", "bn": 2},
	"forteresse_vol": {"k": "bomber", "l": 44, "span": 66, "ww": 18, "eng": 4, "gc": "red"},
	"forge_kharn": {"k": "hall", "sz": Vector2(96, 64), "h": 20, "gc": "orange", "chim": true},
	"atelier_kharn": {"k": "hall", "sz": Vector2(96, 64), "h": 14, "gc": "green"},
	"canon_lourd": {"k": "tower", "base": "block", "hy": 22, "hx": 26, "hh": 10, "bn": 2, "bl": 22, "br": 2.6, "bz": 8, "gc": "orange"},
	"batterie_mortiers": {"k": "tower", "base": "block", "hy": 22, "hcyl": true, "bl": 16, "br": 3.8, "bn": 2, "bz": 9, "hx": 28, "hh": 8, "gc": "orange"},
	"site_missiles": {"k": "tower", "hx": 26, "hh": 10, "bn": 3, "bl": 14, "br": 1.6, "bz": 7, "gc": "red"},
	"turbine_kharn": {"k": "gen", "sz": Vector2(64, 64), "h": 20, "gc": "orange"},
	"fonderie_lourde": {"k": "farm", "sz": Vector2(96, 64), "n": 3, "h": 22, "gc": "orange"},
	"hangar_kharn": {"k": "hangar", "sz": Vector2(96, 64), "h": 18, "gc": "orange"},
	"marteau_guerre": {"k": "tower", "base": "super", "sz": Vector2(96, 96), "hy": 28, "hx": 32, "hh": 14, "bn": 2, "bl": 36, "br": 4.4, "bz": 12, "gc": "red"},
}

## Rotors animés des hélicoptères du style (rr = rayon, rn = pales).
static func rotors(id: String) -> Array:
	var p: Dictionary = STYLES.get(id, {})
	if p.get("k", "") != "copter":
		return []
	var rr := float(p.get("rr", 22))
	return [{"hub": Vector3(-1, 21.5, 0), "r": rr, "n": int(p.get("rn", 2)), "w": 34.0, "h": true},
			{"hub": Vector3(-float(p.get("bl", 24)) - 10.0, 16, 3.5), "r": 6.5, "n": 2, "w": 48.0, "h": false}]


static func has(id: String) -> bool:
	return STYLES.has(id)


## Bouches de tir (x avant, y hauteur, z côté) déduites du style.
static func muzzles(id: String) -> Array:
	var p: Dictionary = STYLES.get(id, {})
	var out: Array = []
	match String(p.get("k", "")):
		"mech":
			return ModelsMech.muzzles(p)
		"tank":
			var th := float(p.get("th", 7))
			var hh := float(p.get("hh", 6))
			var tsy := float(p.get("tsy", 6))
			var tx := float(p.get("tx", -1))
			var tsx := float(p.get("tsx", 14))
			var n := int(p.get("bn", 1))
			if "mortar" in p.get("x", []):
				return [Vector3(tx + tsx * 0.5 + 12.0, th + hh + tsy + 9.0, 0)]
			if n == 0:
				return [Vector3(tx + tsx * 0.5 + 6.0, th + hh + tsy * 0.5 + 4.0, 0)]
			var bl := float(p.get("bl", 17))
			var bz := float(p.get("bz", 4.0))
			for i in n:
				out.append(Vector3(tx + tsx * 0.5 - 2.0 + bl + 1.0, th + hh + tsy * 0.5 + 1.0, (i - (n - 1) * 0.5) * bz))
		"jet":
			var l := float(p.get("l", 30))
			var n := int(p.get("bn", 2))
			for i in n:
				out.append(Vector3(l * 0.5 + 6.0, 10, (i - (n - 1) * 0.5) * 10.0))
		"copter":
			out = [Vector3(13, 9, 9), Vector3(13, 9, -9)]
		"bomber":
			out = [Vector3(3, 7, 0)]
		"drone":
			out = [Vector3(10, 11, 0)]
		"tower":
			var hy := float(p.get("hy", 12))
			var bl := float(p.get("bl", 16))
			var n := int(p.get("bn", 1))
			var tsx := float(p.get("hx", 22)) * 0.5
			for i in n:
				out.append(Vector3(tsx - 2.0 + bl + 1.0, hy + float(p.get("hh", 8)) * 0.5 + 6.0, (i - (n - 1) * 0.5) * float(p.get("bz", 6.0))))
	if out.is_empty():
		out = [Vector3(12, 12, 0)]
	return out


## Construit le modèle `id` (ou sa tête de tourelle `<id>_tete`) dans r. Renvoie false si inconnu.
static func build(r: Node3D, id: String, body: Color, hi: Color, acc: Color) -> bool:
	var head := id.ends_with("_tete")
	var key := id.trim_suffix("_tete")
	if not STYLES.has(key):
		return false
	var p: Dictionary = STYLES[key]
	match String(p["k"]):
		"tank": _tank(r, body, hi, acc, p)
		"jet": _jet(r, body, hi, acc, p)
		"bomber": _bomber(r, body, hi, acc, p)
		"copter": _copter(r, body, hi, acc, p)
		"drone": _drone(r, body, hi, acc, p)
		"mech": ModelsMech.build(r, body, hi, acc, p)
		"tower":
			if head:
				_tower_head(r, acc, p)
			else:
				_tower_base(r, acc, p)
		_:
			if head:
				return false
			_building(r, acc, p)
	return true


static func _g(p: Dictionary) -> Color:
	return GLOWS.get(String(p.get("gc", "blue")), GLOWS["blue"])


# --- Unités au sol ------------------------------------------------------------------------------

static func _tank(r: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	var l := float(p.get("l", 32))
	var sp := float(p.get("sp", 9))
	var th := float(p.get("th", 7))
	var hl := float(p.get("hl", 30))
	var hh := float(p.get("hh", 6))
	var hw := float(p.get("hw", 15))
	var tx := float(p.get("tx", -1))
	var tsx := float(p.get("tsx", 14))
	var tsy := float(p.get("tsy", 6))
	var tsz := float(p.get("tsz", 13))
	var gc := _g(p)
	if p.get("w", false):
		Models._wheels(r, [-l * 0.4, l * 0.4], sp, 4.5, 4.0)
		th = 4.0
	else:
		Models._tracks(r, l, sp, float(p.get("tw", 6)), th)
	Models._box(r, Vector3(hl, hh, hw), Vector3(0, th + hh * 0.5, 0), body)
	Models._box(r, Vector3(hl * 0.3, hh * 0.6, hw), Vector3(hl * 0.5, th + hh * 0.4, 0), body.lightened(0.1), Vector3(0, 0, -0.5))
	var ty := th + hh + tsy * 0.5
	if p.get("cyl", false):
		Models._cyl(r, tsx * 0.5, tsx * 0.6, tsy, Vector3(tx, ty, 0), hi, 8)
	else:
		Models._box(r, Vector3(tsx, tsy, tsz), Vector3(tx, ty, 0), hi)
	Models._box(r, Vector3(1, 1.5, hw * 0.6), Vector3(hl * 0.5 + 1.0, th + hh * 0.5, 0), gc, Vector3.ZERO, 1.4)
	var ex: Array = p.get("x", [])
	var n := int(p.get("bn", 1))
	var bl := float(p.get("bl", 17))
	var br := float(p.get("br", 1.5))
	var bz := float(p.get("bz", 4.0))
	for i in n:
		Models._barrel(r, tx + tsx * 0.5 - 2.0, ty + 1.0, (i - (n - 1) * 0.5) * bz, bl, br)
	if "mortar" in ex:
		Models._cyl(r, 2.6, 3.4, 16, Vector3(tx + tsx * 0.5 + 2.0, ty + 8.0, 0), DARK, 8, Vector3(0, 0, -0.9))
		Models._cyl(r, 3.8, 3.8, 2.0, Vector3(tx + tsx * 0.5 + 9.0, ty + 14.0, 0), METAL, 8, Vector3(0, 0, -0.9))
	if "skirts" in ex:
		for s in [-1.0, 1.0]:
			Models._box(r, Vector3(hl * 0.8, hh * 0.9, 1.4), Vector3(-1, th + hh * 0.5, s * (hw * 0.5 + 1.2)), METAL)
	if "armor" in ex:
		Models._box(r, Vector3(tsx + 4, 2.2, tsz + 3), Vector3(tx, ty + tsy * 0.5 + 1.0, 0), METAL)
		Models._box(r, Vector3(4, tsy * 0.9, tsz + 3), Vector3(tx + tsx * 0.5 + 1.5, ty, 0), body.lightened(0.15), Vector3(0, 0, -0.4))
	if "stacks" in ex:
		for s in [-1.0, 1.0]:
			Models._cyl(r, 1.6, 1.6, 7, Vector3(-hl * 0.4, th + hh + 3.0, s * hw * 0.3), DARK, 6)
	if "dish" in ex:
		Models._cyl(r, 5.5, 1.0, 2.0, Vector3(tx - tsx * 0.4, ty + tsy * 0.5 + 6.0, 4), LIGHT, 8, Vector3(0.9, 0, 0))
		Models._box(r, Vector3(1.2, 6, 1.2), Vector3(tx - tsx * 0.4, ty + tsy * 0.5 + 2.5, 4), DARK)
	if "bigdish" in ex:
		Models._cyl(r, 9, 2.0, 3.0, Vector3(tx + tsx * 0.5 + 1.0, ty + 3.0, 0), LIGHT, 10, Vector3(0, 0, -1.1))
		Models._ball(r, 2.4, Vector3(tx + tsx * 0.5 + 5.0, ty + 4.0, 0), gc, 2.0)
	if "dome" in ex:
		Models._ball(r, tsx * 0.35, Vector3(tx, ty + tsy * 0.5 + 2.0, 0), gc, 1.0)
	if "cross" in ex:
		Models._box(r, Vector3(9, 1.2, 3), Vector3(-hl * 0.15, th + hh + 0.9, 0), GLOWS["green"], Vector3.ZERO, 1.6)
		Models._box(r, Vector3(3, 1.2, 9), Vector3(-hl * 0.15, th + hh + 0.9, 0), GLOWS["green"], Vector3.ZERO, 1.6)
	if "antenna" in ex:
		Models._box(r, Vector3(1, 12, 1), Vector3(-hl * 0.45, th + hh + 6.0, -hw * 0.3), DARK)
		Models._ball(r, 1.5, Vector3(-hl * 0.45, th + hh + 12.5, -hw * 0.3), gc, 2.0)
	if "rack" in ex:
		for s in [-1.0, 1.0]:
			Models._box(r, Vector3(14, 4, 4.5), Vector3(tx + 2, ty + tsy * 0.5 + 3.0, s * 4.5), DARK, Vector3(0, 0, -0.55))
			for k in 3:
				Models._cyl(r, 1.0, 1.0, 4, Vector3(tx + 7 + k * 0.0, ty + tsy * 0.5 + 6.5 + k * 1.2, s * 4.5), GLOWS["orange"], 6, Vector3(0, 0, PI / 2.0 - 0.55), 1.2)
	if "pods" in ex:
		for s in [-1.0, 1.0]:
			Models._box(r, Vector3(9, 4, 4), Vector3(tx, ty, s * (tsz * 0.5 + 2.5)), DARK)
	if "ram" in ex:
		Models._box(r, Vector3(6, hh * 1.1, hw + 4), Vector3(hl * 0.5 + 3.0, th + hh * 0.5, 0), METAL, Vector3(0, 0, -0.25))
		for s in [-1.0, 0.0, 1.0]:
			Models._cyl(r, 0.2, 1.6, 6, Vector3(hl * 0.5 + 8.0, th + hh * 0.5, s * hw * 0.3), LIGHT, 5, Vector3(0, 0, -PI / 2.0))
	if "tank" in ex:
		Models._cyl(r, 4, 4, 14, Vector3(-hl * 0.3, th + hh + 4.0, 0), METAL, 8, Vector3(PI / 2.0, 0, 0))
		Models._ball(r, 2.0, Vector3(-hl * 0.3, th + hh + 9.0, 0), GLOWS["orange"], 1.6)
	if "crystals" in ex:
		for k in 3:
			Models._crystal(r, 9 + k * 2, 2.6, Vector3(-hl * 0.3 - k * 3.0, th + hh + 5.0, (k - 1) * 4.0), GLOWS["violet"], 0.2 * (k - 1), 0.0, 1.5)


# --- Unités aériennes ---------------------------------------------------------------------------

static func _jet(r: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	var l := float(p.get("l", 32))
	var span := float(p.get("span", 30))
	var ww := float(p.get("ww", 9))
	var gc := _g(p)
	Models._box(r, Vector3(l, 5, 7), Vector3(0, 12, 0), body)
	Models._box(r, Vector3(10, 4, 6), Vector3(l * 0.5 - 2, 11.5, 0), hi, Vector3(0, 0, -0.35))
	Models._box(r, Vector3(8, 3.5, 5), Vector3(2, 15, 0), METAL)
	Models._box(r, Vector3(1, 2.5, 4), Vector3(6, 15.2, 0), gc, Vector3.ZERO, 1.4)
	Models._box(r, Vector3(ww, 1.4, span), Vector3(-3, 12, 0), hi)
	Models._box(r, Vector3(5, 1.2, span * 0.45), Vector3(-l * 0.5 + 2, 12.5, 0), body)
	if p.get("tail", "") == "twin":
		for s in [-1.0, 1.0]:
			Models._box(r, Vector3(6, 7, 1.2), Vector3(-l * 0.5 + 2, 15, 3.5 * s), acc, Vector3(0.3 * s, 0, 0), 0.6)
	else:
		Models._box(r, Vector3(7, 7, 1.2), Vector3(-l * 0.5 + 2, 15, 0), acc, Vector3.ZERO, 0.6)
	var eng := int(p.get("eng", 1))
	for i in eng:
		var z := (i - (eng - 1) * 0.5) * 4.5
		Models._box(r, Vector3(3, 3, 3.5), Vector3(-l * 0.5 - 1, 12, z), GLOWS["orange"], Vector3.ZERO, 2.2)
	var n := int(p.get("bn", 2))
	for i in n:
		Models._barrel(r, l * 0.5 - 2, 10, (i - (n - 1) * 0.5) * 10.0, 8, 0.9)


static func _bomber(r: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	var l := float(p.get("l", 34))
	var span := float(p.get("span", 52))
	var ww := float(p.get("ww", 14))
	var gc := _g(p)
	Models._box(r, Vector3(l, 7, 12), Vector3(0, 12, 0), body)
	Models._box(r, Vector3(10, 5, 10), Vector3(l * 0.5 + 1, 11, 0), hi, Vector3(0, 0, -0.3))
	Models._box(r, Vector3(8, 4, 7), Vector3(5, 16.5, 0), METAL)
	Models._box(r, Vector3(ww, 1.6, span), Vector3(-2, 12, 0), hi)
	Models._box(r, Vector3(8, 1.4, span * 0.42), Vector3(-l * 0.45, 12.5, 0), body)
	Models._box(r, Vector3(7, 8, 1.4), Vector3(-l * 0.45, 17, 0), acc, Vector3.ZERO, 0.6)
	var eng := int(p.get("eng", 2))
	for i in eng:
		var z := (i - (eng - 1) * 0.5) * (span / maxf(eng, 1.0)) * 0.8
		Models._cyl(r, 3.2, 3.2, 11, Vector3(-4, 9, z), DARK, 8, Vector3(0, 0, PI / 2.0))
		Models._ball(r, 2.2, Vector3(-10, 9, z), gc, 2.0)
	Models._box(r, Vector3(12, 3, 7), Vector3(0, 7.5, 0), DARK)
	Models._ball(r, 2.6, Vector3(3, 7, 0), gc, 1.8)


static func _copter(r: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	var bl := float(p.get("bl", 24))
	var bw := float(p.get("bw", 11))
	var gc := _g(p)
	Models._box(r, Vector3(bl, 9, bw), Vector3(0, 12, 0), body)
	Models._box(r, Vector3(9, 6, bw - 2), Vector3(bl * 0.5 - 1, 12, 0), hi, Vector3(0, 0, -0.3))
	Models._box(r, Vector3(7, 4, bw - 4), Vector3(bl * 0.5 - 2, 16, 0), gc, Vector3.ZERO, 0.8)
	Models._box(r, Vector3(bl + 2, 2.4, 2.6), Vector3(-bl * 0.9, 13, 0), METAL)
	Models._box(r, Vector3(1.5, 8, 5), Vector3(-bl - 10, 16, 0), acc, Vector3.ZERO, 0.6)
	Models._cyl(r, 1.6, 1.6, 4, Vector3(-1, 19, 0), DARK, 6)
	var pods := int(p.get("pods", 2))
	for i in pods:
		var s := -1.0 if i % 2 == 0 else 1.0
		var lev := float(i / 2)
		Models._box(r, Vector3(10, 3, 3), Vector3(2, 9 - lev * 3, (bw * 0.5 + 3.5 + lev * 3.0) * s), DARK)
		Models._cyl(r, 1.2, 1.2, 9, Vector3(8, 9 - lev * 3, (bw * 0.5 + 3.5 + lev * 3.0) * s), METAL, 6, Vector3(0, 0, PI / 2.0))
	if p.get("gun", false):
		Models._cyl(r, 1.4, 1.4, 12, Vector3(bl * 0.5 + 9, 8, 0), DARK, 6, Vector3(0, 0, PI / 2.0))


static func _drone(r: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	var s := float(p.get("s", 1.0))
	var gc := _g(p)
	Models._cyl(r, 6 * s, 8 * s, 4, Vector3(0, 12, 0), body, 6)
	Models._ball(r, 4 * s, Vector3(0, 15, 0), gc, 1.8)
	for a in 3:
		var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 3.0 + 0.5)
		Models._box(r, Vector3(14 * s, 1.2, 2.2), d * 10 * s + Vector3(0, 12, 0), hi, Vector3(0, -(a * TAU / 3.0 + 0.5), 0))
		Models._cyl(r, 3.2 * s, 3.2 * s, 0.8, d * 17 * s + Vector3(0, 13, 0), acc, 8, Vector3.ZERO, 0.5)
	Models._barrel(r, 4 * s, 11, 0, 6, 0.8)


# --- Bâtiments ----------------------------------------------------------------------------------

static func _tower_base(r: Node3D, acc: Color, p: Dictionary) -> void:
	var sz: Vector2 = p.get("sz", Vector2(64, 64))
	Models._slab(r, sz.x, sz.y, acc)
	var hv: String = p.get("base", "round")
	if hv == "super":
		Models._box(r, Vector3(sz.x - 14, 14, sz.y - 14), Vector3(0, 10, 0), Color(0.34, 0.36, 0.42))
		Models._box(r, Vector3(sz.x - 22, 6, sz.y - 22), Vector3(0, 20, 0), METAL)
		for x in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				Models._cyl(r, 5, 7, 22, Vector3(x * (sz.x * 0.5 - 14), 14, z * (sz.y * 0.5 - 14)), DARK, 8)
				Models._ball(r, 3.0, Vector3(x * (sz.x * 0.5 - 14), 27, z * (sz.y * 0.5 - 14)), _g(p), 2.0)
		return
	if hv == "block":
		Models._box(r, Vector3(50, 16, 50), Vector3(0, 11, 0), Color(0.36, 0.37, 0.42))
		Models._box(r, Vector3(54, 3, 54), Vector3(0, 20, 0), METAL)
		return
	if hv == "crystal":
		Models._cyl(r, 20, 23, 8, Vector3(0, 7, 0), OBSIDIAN, 6)
		Models._cyl(r, 24, 24, 1.4, Vector3(0, 9, 0), acc, 6, Vector3.ZERO, 1.0)
		return
	Models._cyl(r, 20, 23, 8, Vector3(0, 7, 0), METAL, 8)
	Models._cyl(r, 24, 24, 1.4, Vector3(0, 9, 0), acc, 8, Vector3.ZERO, 1.0)
	for a in 4:
		var d := Vector3.RIGHT.rotated(Vector3.UP, a * PI / 2.0 + PI / 4.0) * 26.0
		Models._box(r, Vector3(7, 6, 7), d + Vector3(0, 6, 0), DARK)


static func _tower_head(r: Node3D, acc: Color, p: Dictionary) -> void:
	var y := float(p.get("hy", 12))
	var hx := float(p.get("hx", 22))
	var hh := float(p.get("hh", 8))
	var gc := _g(p)
	var n := int(p.get("bn", 1))
	var bl := float(p.get("bl", 16))
	var br := float(p.get("br", 2.0))
	var bz := float(p.get("bz", 6.0))
	if p.get("hcyl", false):
		Models._cyl(r, hx * 0.5, hx * 0.5, hh, Vector3(0, y + hh * 0.5, 0), LIGHT, 8)
	else:
		Models._box(r, Vector3(hx, hh, hx), Vector3(0, y + hh * 0.5, 0), LIGHT)
	for i in n:
		Models._barrel(r, hx * 0.5 - 2.0, y + hh * 0.5 + 6.0 - 6.0 + 6.0, (i - (n - 1) * 0.5) * bz, bl, br, DARK)
	Models._ball(r, 3.0, Vector3(-hx * 0.3, y + hh + 3.0, 0), gc, 2.2)
	for k in p.get("x", []):
		if k == "dish":
			Models._cyl(r, 8, 1.5, 2, Vector3(-4, y + hh + 8.0, 0), LIGHT, 10, Vector3(0.7, 0, 0))
		elif k == "crystal":
			Models._crystal(r, 16, 4, Vector3(-2, y + hh + 8.0, 0), GLOWS["violet"], 0.0, 0.0, 1.4)
		elif k == "coil":
			for q in 3:
				Models._cyl(r, 5 - q, 5.5 - q, 2.4, Vector3(-3, y + hh + 2.0 + q * 3.0, 0), METAL, 8, Vector3.ZERO, 0.5 + q * 0.3)


static func _slab_w(r: Node3D, p: Dictionary, acc: Color) -> void:
	var s: Vector2 = p.get("sz", Vector2(64, 64))
	Models._slab(r, s.x, s.y, acc)


static func _building(r: Node3D, acc: Color, p: Dictionary) -> void:
	var s: Vector2 = p.get("sz", Vector2(64, 64))
	var gc := _g(p)
	var h := float(p.get("h", 16))
	Models._slab(r, s.x, s.y, acc)
	match String(p["k"]):
		"hall":
			Models._box(r, Vector3(s.x - 18, h, s.y - 20), Vector3(0, h * 0.5 + 3, 0), METAL)
			Models._box(r, Vector3(s.x - 14, 3, s.y - 16), Vector3(0, h + 4.5, 0), LIGHT)
			Models._box(r, Vector3(s.x * 0.35, 1.4, 4), Vector3(0, h + 6.4, 0), gc, Vector3.ZERO, 1.4)
			Models._box(r, Vector3(14, 8, 3), Vector3(0, 7, s.y * 0.5 - 8), DARK)
			if p.get("mast", true):
				Models._box(r, Vector3(2, 18, 2), Vector3(-s.x * 0.3, h + 14, -s.y * 0.2), DARK)
				Models._ball(r, 2.2, Vector3(-s.x * 0.3, h + 23, -s.y * 0.2), gc, 2.0)
			if p.get("chim", false):
				Models._cyl(r, 3, 4, 14, Vector3(s.x * 0.28, h + 11, -s.y * 0.15), DARK, 8)
		"dome":
			Models._cyl(r, s.x * 0.36, s.x * 0.42, 8, Vector3(0, 7, 0), METAL, 10)
			Models._ball(r, s.x * 0.32, Vector3(0, 12, 0), LIGHT, 0.1)
			Models._cyl(r, s.x * 0.4, s.x * 0.4, 1.6, Vector3(0, 12, 0), gc, 12, Vector3.ZERO, 1.2)
			Models._ball(r, 4, Vector3(0, 12 + s.x * 0.34, 0), gc, 2.0)
		"pylon":
			var n := int(p.get("n", 3))
			for i in n:
				var x := (i - (n - 1) * 0.5) * (s.x - 20) / maxf(n - 1, 1)
				Models._box(r, Vector3(8, h, 8), Vector3(x, h * 0.5 + 3, 0), METAL)
				Models._cyl(r, 1.0, 5, 8, Vector3(x, h + 7, 0), gc, 6, Vector3.ZERO, 1.2)
				Models._ball(r, 3, Vector3(x, h + 13, 0), gc, 2.4)
			Models._box(r, Vector3(s.x - 14, 3, 6), Vector3(0, 6, 0), DARK)
		"gen":
			for x in [-s.x * 0.22, s.x * 0.22]:
				Models._cyl(r, 11, 12, h, Vector3(x, h * 0.5 + 3, 0), METAL, 10)
				Models._cyl(r, 12, 12, 1.6, Vector3(x, h * 0.6, 0), gc, 10, Vector3.ZERO, 1.2)
				Models._ball(r, 5, Vector3(x, h + 8, 0), gc, 2.0)
			Models._box(r, Vector3(s.x - 20, 6, 12), Vector3(0, 6, s.y * 0.2), DARK)
		"farm":
			var n := int(p.get("n", 3))
			for i in n:
				var x := (i - (n - 1) * 0.5) * (s.x - 16) / maxf(n, 1.0)
				Models._cyl(r, 8, 9, h, Vector3(x, h * 0.5 + 3, 0), LIGHT, 8)
				Models._cyl(r, 9, 9, 1.4, Vector3(x, h * 0.7, 0), gc, 8, Vector3.ZERO, 1.2)
				Models._cyl(r, 2, 8, 6, Vector3(x, h + 6, 0), METAL, 8)
			Models._box(r, Vector3(s.x - 14, 4, 8), Vector3(0, 5, s.y * 0.28), DARK)
		"hangar":
			Models._box(r, Vector3(s.x - 14, h, s.y - 16), Vector3(0, h * 0.5 + 3, 0), METAL)
			Models._cyl(r, (s.y - 16) * 0.5, (s.y - 16) * 0.5, s.x - 14, Vector3(0, h + 3, 0), LIGHT, 10, Vector3(0, 0, PI / 2.0))
			Models._box(r, Vector3(s.x * 0.4, h * 0.7, 2), Vector3(0, h * 0.4 + 3, s.y * 0.5 - 7), DARK)
			Models._box(r, Vector3(s.x * 0.5, 1.2, 1.2), Vector3(0, h * 0.8 + 3, s.y * 0.5 - 6), gc, Vector3.ZERO, 1.6)
		"wall":
			Models._box(r, Vector3(s.x - 8, h, 12), Vector3(0, h * 0.5 + 3, 0), METAL)
		"citadel":
			Models._box(r, Vector3(s.x - 12, h, s.y - 12), Vector3(0, h * 0.5 + 3, 0), Color(0.34, 0.36, 0.42))
			for x in [-1.0, 1.0]:
				for z in [-1.0, 1.0]:
					Models._cyl(r, 6, 8, h + 8, Vector3(x * (s.x * 0.5 - 12), (h + 8) * 0.5 + 3, z * (s.y * 0.5 - 12)), METAL, 8)
					Models._ball(r, 3.4, Vector3(x * (s.x * 0.5 - 12), h + 14, z * (s.y * 0.5 - 12)), gc, 2.0)
			Models._box(r, Vector3(s.x * 0.5, 8, s.y * 0.5), Vector3(0, h + 7, 0), LIGHT)
			Models._ball(r, 6, Vector3(0, h + 15, 0), gc, 2.4)
		_:
			Models._box(r, Vector3(20, 10, 20), Vector3(0, 5, 0), acc)
