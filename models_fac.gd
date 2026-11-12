class_name ModelsFac
## Variantes par faction des bâtiments et engins communs (Kharn, Vael, Conclave ; Solis garde
## les modèles de base de Models). Mêmes emprises, mêmes portes et mêmes points d'animation que
## les modèles de base : seuls le style et la silhouette changent.
##   Kharn    : acier sombre, blindages inclinés, cheminées, lueurs rouges
##   Vael     : bâches et tentes sable, dômes, auvents et mâts, lueurs vertes/or
##   Conclave : obsidienne et cristaux, formes effilées, lueurs violettes

const STEEL := Color(0.30, 0.30, 0.34)
const STEEL_L := Color(0.46, 0.46, 0.5)
const RUST := Color(0.42, 0.2, 0.15)
const SAND := Color(0.62, 0.5, 0.32)
const CANVAS := Color(0.82, 0.72, 0.52)
const CLOTH := Color(0.22, 0.45, 0.3)
const OBS := Color(0.16, 0.12, 0.24)
const OBS_L := Color(0.32, 0.24, 0.5)
const GLOW_RED := Color(1.0, 0.25, 0.2)
const GLOW_GOLD := Color(1.0, 0.8, 0.3)

const BUILDINGS := ["chantier", "centrale", "raffinerie", "fonderie", "usine", "tourelle", "tourelle_tete", "silo",
		"silo_minerai", "radar", "radar_tete", "reparation", "reacteur", "batterie", "batterie_tete", "aerodrome"]
const UNITS := ["recolteur", "mineur", "mcv", "convoi"]


static func has(id: String, f: String) -> bool:
	return f in ["kharn", "vael", "conclave"] and (id in BUILDINGS or id in UNITS)


## Construit la variante ; false si cet identifiant n'en a pas.
static func build(r: Node3D, id: String, f: String, acc: Color) -> bool:
	if not has(id, f):
		return false
	var body := acc.darkened(0.3)
	var hi := acc.lightened(0.25)
	match id:
		"chantier": _chantier(r, f, acc)
		"centrale": _centrale(r, f, acc)
		"raffinerie": _raffinerie(r, f, acc)
		"fonderie": _fonderie(r, f, acc)
		"usine": _usine(r, f, acc)
		"tourelle": _tourelle(r, f, acc)
		"tourelle_tete": _tourelle_tete(r, f, acc)
		"silo": _silo(r, f, acc)
		"silo_minerai": _silo_minerai(r, f, acc)
		"radar": _radar(r, f, acc)
		"radar_tete": _radar_tete(r, f, acc)
		"reparation": _reparation(r, f, acc)
		"reacteur": _reacteur(r, f, acc)
		"batterie": _batterie(r, f, acc)
		"batterie_tete": _batterie_tete(r, f, acc)
		"aerodrome": _aerodrome(r, f, acc)
		"recolteur": _recolteur(r, f, body, hi, acc)
		"mineur": _mineur(r, f, body, hi, acc)
		"mcv": _mcv(r, f, body, hi, acc)
		"convoi": _convoi(r, f, body, hi, acc)
	return true


# --- Aides ------------------------------------------------------------------------------

static func _plate(r: Node3D, f: String, w: float, d: float, acc: Color) -> void:
	match f:
		"kharn":
			Models._box(r, Vector3(w - 2, 4, d - 2), Vector3(0, 2, 0), Color(0.2, 0.2, 0.23))
			for s in [-1.0, 1.0]:
				Models._box(r, Vector3(w - 2, 0.8, 4), Vector3(0, 4.3, s * (d / 2.0 - 5)), GLOW_RED, Vector3.ZERO, 0.7)
		"vael":
			Models._box(r, Vector3(w - 4, 2, d - 4), Vector3(0, 1, 0), Color(0.55, 0.45, 0.3))
			for i in 4:
				Models._box(r, Vector3(6, 0.5, d - 12), Vector3(-w / 2.0 + 12 + i * (w - 24) / 3.0, 2.3, 0), CLOTH)
		_:
			Models._cyl(r, minf(w, d) / 2.0 + 2, minf(w, d) / 2.0 + 6, 3, Vector3(0, 1.5, 0), OBS, 6)
			Models._cyl(r, minf(w, d) / 2.0 - 2, minf(w, d) / 2.0 - 2, 0.8, Vector3(0, 3.2, 0), acc.darkened(0.35), 6, Vector3.ZERO, 0.3)


static func _spikes(r: Node3D, y: float, rad: float, n: int, h: float, col: Color, glow := 0.0) -> void:
	for i in n:
		var a := TAU * i / float(n)
		Models._cyl(r, 0.2, 2.2, h, Vector3(cos(a) * rad, y + h / 2.0, sin(a) * rad), col, 4, Vector3.ZERO, glow)


# --- Bâtiments --------------------------------------------------------------------------

static func _chantier(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 96, 96, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(64, 18, 60), Vector3(0, 13, 0), STEEL)
			Models._box(r, Vector3(50, 8, 46), Vector3(0, 26, 0), STEEL_L, Vector3(0, PI / 4.0, 0))
			Models._box(r, Vector3(20, 22, 20), Vector3(-14, 41, -8), RUST)
			for x in [-30.0, 30.0]:
				Models._cyl(r, 4, 5, 34, Vector3(x, 21, -30), STEEL, 6)
				Models._cyl(r, 5, 5, 1.6, Vector3(x, 38.5, -30), GLOW_RED, 6, Vector3.ZERO, 1.8)
			Models._box(r, Vector3(40, 3, 6), Vector3(10, 32, 28), STEEL_L, Vector3(0, -0.25, 0))
			Models._ball(r, 3.0, Vector3(-14, 54, -8), GLOW_RED, 2.5)
			_spikes(r, 7, 42, 8, 8, STEEL_L)
		"vael":
			Models._box(r, Vector3(58, 12, 58), Vector3(0, 8, 0), SAND)
			Models._cyl(r, 0.5, 30, 22, Vector3(0, 25, 0), CANVAS, 8)
			Models._cyl(r, 31, 31, 1.6, Vector3(0, 14.5, 0), CLOTH, 8)
			Models._cyl(r, 1.5, 1.5, 26, Vector3(0, 48, 0), SAND.darkened(0.3), 6)
			Models._box(r, Vector3(14, 6, 1), Vector3(7, 58, 0), GLOW_GOLD, Vector3(0, 0, 0.0), 1.0)
			for p in [Vector3(-40, 0, -40), Vector3(40, 0, -40), Vector3(-40, 0, 40), Vector3(40, 0, 40)]:
				Models._cyl(r, 1.6, 1.6, 22, p + Vector3(0, 11, 0), SAND.darkened(0.3), 6)
				Models._ball(r, 2.6, p + Vector3(0, 23, 0), GLOW_GOLD, 1.8)
			Models._box(r, Vector3(30, 1.2, 8), Vector3(0, 11, 34), CLOTH, Vector3(0.35, 0, 0))
		_:
			Models._cyl(r, 24, 32, 12, Vector3(0, 9, 0), OBS, 6)
			Models._cyl(r, 14, 22, 18, Vector3(0, 24, 0), OBS_L, 6)
			Models._crystal(r, 40, 12, Vector3(0, 52, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.4)
			for a in 6:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 6.0) * 36.0
				Models._crystal(r, 22 + (a % 2) * 8, 6, d + Vector3(0, 12, 0), Models.GLOW_VIOLET, 0.15, 0.0, 1.1)
			Models._cyl(r, 30, 30, 1.0, Vector3(0, 15.2, 0), acc, 6, Vector3.ZERO, 1.0)


static func _centrale(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 64, 64, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(50, 16, 36), Vector3(0, 10, 4), STEEL)
			for x in [-15.0, 15.0]:
				Models._cyl(r, 5, 7, 24, Vector3(x, 22, -2), STEEL_L, 6)
				Models._cyl(r, 6, 6, 3, Vector3(x, 24, -2), GLOW_RED, 6, Vector3.ZERO, 1.8)
			Models._box(r, Vector3(40, 4, 8), Vector3(0, 7, 22), Color(0.14, 0.14, 0.17))
			_spikes(r, 18, 22, 6, 6, RUST)
		"vael":
			Models._cyl(r, 22, 24, 12, Vector3(0, 8, 0), SAND, 10)
			for x in [-15.0, 15.0]:
				Models._ball(r, 11, Vector3(x, 20, -2), CANVAS, 0.0)
				Models._ball(r, 6, Vector3(x, 25, -2), Models.GLOW_GREEN, 1.8)
			Models._box(r, Vector3(40, 5, 8), Vector3(0, 7, 21), Color(0.2, 0.2, 0.16))
			Models._cyl(r, 1.0, 1.0, 34, Vector3(0, 18, -2), SAND.darkened(0.3), 6, Vector3(0, 0, PI / 2.0))
		_:
			Models._cyl(r, 18, 24, 8, Vector3(0, 7, 0), OBS, 6)
			for x in [-15.0, 15.0]:
				Models._crystal(r, 28, 9, Vector3(x, 22, -2), Models.GLOW_VIOLET, 0.0, 0.0, 1.5)
			Models._cyl(r, 10, 14, 2, Vector3(0, 12, -2), acc, 6, Vector3.ZERO, 1.0)
			Models._box(r, Vector3(30, 1.0, 4), Vector3(0, 9.8, 20), acc, Vector3.ZERO, 1.2)


static func _door(r: Node3D, x: float, z: float, y: float, w: float, h: float, col: Color, trim: Color) -> void:
	Models._box(r, Vector3(w, h, 3), Vector3(x, y, z), col)
	Models._box(r, Vector3(w + 2, 1.2, 3.5), Vector3(x, y + h / 2.0 + 0.6, z), trim, Vector3.ZERO, 1.2)


static func _raffinerie(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 96, 64, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(40, 22, 34), Vector3(-22, 15, -6), STEEL)
			Models._box(r, Vector3(30, 8, 26), Vector3(-22, 30, -6), STEEL_L, Vector3(0, PI / 4.0, 0))
			Models._cyl(r, 5, 6, 40, Vector3(-36, 24, -20), STEEL_L, 6)
			Models._cyl(r, 5.5, 5.5, 1.6, Vector3(-36, 44.5, -20), GLOW_RED, 6, Vector3.ZERO, 1.8)
			Models._box(r, Vector3(26, 14, 28), Vector3(24, 11, -4), RUST)
			Models._box(r, Vector3(20, 1.5, 20), Vector3(24, 18.5, -4), GLOW_ORANGE_(), Vector3.ZERO, 1.3)
			_door(r, -20, 23, 6, 24, 8, Color(0.12, 0.12, 0.15), GLOW_RED)
		"vael":
			Models._cyl(r, 13, 15, 22, Vector3(-26, 13, -6), SAND, 10)
			Models._ball(r, 14, Vector3(-26, 26, -6), CANVAS, 0.0)
			Models._cyl(r, 16, 16, 1.6, Vector3(-26, 18, -6), CLOTH, 10)
			Models._box(r, Vector3(32, 12, 28), Vector3(20, 9, -6), SAND)
			Models._box(r, Vector3(36, 1.6, 12), Vector3(20, 17, 10), CLOTH, Vector3(0.3, 0, 0))
			Models._cyl(r, 2, 2, 36, Vector3(-4, 12, 4), SAND.darkened(0.3), 6, Vector3(0, 0, PI / 2.0))
			Models._box(r, Vector3(20, 1.2, 16), Vector3(20, 15.5, -6), GLOW_GOLD, Vector3.ZERO, 1.2)
			_door(r, -20, 23, 5, 24, 8, Color(0.2, 0.17, 0.12), GLOW_GOLD)
		_:
			Models._cyl(r, 14, 20, 16, Vector3(-24, 11, -6), OBS, 6)
			Models._crystal(r, 30, 10, Vector3(-24, 30, -6), Models.GLOW_VIOLET, 0.0, 0.0, 1.3)
			Models._cyl(r, 16, 16, 1.4, Vector3(-24, 15, -6), acc, 6, Vector3.ZERO, 1.0)
			Models._cyl(r, 12, 18, 12, Vector3(24, 9, -6), OBS_L, 6)
			Models._cyl(r, 8, 8, 1.4, Vector3(24, 15.5, -6), Models.GLOW_VIOLET, 6, Vector3.ZERO, 1.4)
			_door(r, -20, 23, 5, 24, 8, Color(0.1, 0.08, 0.16), Models.GLOW_VIOLET)


static func GLOW_ORANGE_() -> Color:
	return Models.GLOW_ORANGE


static func _fonderie(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 96, 64, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(56, 24, 44), Vector3(-10, 16, -4), STEEL)
			Models._box(r, Vector3(56, 4, 44), Vector3(-10, 30, -4), RUST)
			for x in [18.0, 32.0, 40.0]:
				Models._cyl(r, 4, 6, 40 - (x - 18.0) * 0.5, Vector3(x, 22, -16), STEEL_L, 6)
				Models._cyl(r, 4.5, 4.5, 1.8, Vector3(x, 42 - (x - 18.0) * 0.5, -16), GLOW_RED, 6, Vector3.ZERO, 2.0)
			Models._box(r, Vector3(30, 6, 3), Vector3(-14, 11, 19), GLOW_RED, Vector3.ZERO, 2.2)
			Models._box(r, Vector3(20, 3, 12), Vector3(30, 5, 14), Color(0.14, 0.14, 0.17))
		"vael":
			Models._cyl(r, 24, 26, 14, Vector3(-14, 9, -4), SAND, 10)
			Models._cyl(r, 0.5, 24, 12, Vector3(-14, 22, -4), CANVAS, 10)
			Models._cyl(r, 5, 6, 30, Vector3(24, 17, -14), SAND.darkened(0.2), 8)
			Models._cyl(r, 6.5, 6.5, 2, Vector3(24, 32.5, -14), GLOW_GOLD, 8, Vector3.ZERO, 1.8)
			Models._box(r, Vector3(30, 5, 3), Vector3(-14, 11, 19), GLOW_GOLD, Vector3.ZERO, 2.0)
			Models._box(r, Vector3(24, 1.2, 10), Vector3(30, 9, 14), CLOTH, Vector3(0.3, 0, 0))
		_:
			Models._cyl(r, 16, 24, 20, Vector3(-14, 13, -3), OBS, 6)
			Models._crystal(r, 26, 9, Vector3(-14, 36, -3), Models.GLOW_VIOLET, 0.0, 0.0, 1.6)
			for x in [22.0, 34.0]:
				Models._crystal(r, 26, 7, Vector3(x, 15, -14), Models.GLOW_VIOLET, 0.1, 0.0, 1.2)
			Models._box(r, Vector3(30, 5, 3), Vector3(-14, 11, 19), Models.GLOW_VIOLET, Vector3.ZERO, 2.2)
			Models._cyl(r, 8, 10, 4, Vector3(30, 4, 14), OBS_L, 6)


static func _usine(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 96, 64, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(86, 20, 48), Vector3(0, 12, -4), STEEL)
			Models._box(r, Vector3(86, 4, 52), Vector3(0, 24, -4), RUST, Vector3(0.0, 0.0, 0.0))
			for i in 5:
				Models._box(r, Vector3(4, 8, 4), Vector3(-34 + i * 17.0, 29, -4), STEEL_L)
			_door(r, -14, 21.5, 8.5, 30, 11, Color(0.1, 0.1, 0.13), GLOW_RED)
			Models._cyl(r, 5, 6, 30, Vector3(34, 27, -20), STEEL_L, 6)
			Models._cyl(r, 5.5, 5.5, 1.8, Vector3(34, 42.5, -20), GLOW_RED, 6, Vector3.ZERO, 1.6)
		"vael":
			Models._box(r, Vector3(80, 14, 44), Vector3(0, 9, -4), SAND)
			Models._cyl(r, 22, 24, 80, Vector3(0, 9, -4), SAND, 3, Vector3(0, 0, PI / 2.0))
			Models._box(r, Vector3(82, 1.6, 22), Vector3(0, 20, 8), CLOTH, Vector3(0.28, 0, 0))
			_door(r, -14, 21.5, 7.5, 30, 10, Color(0.2, 0.16, 0.1), GLOW_GOLD)
			Models._cyl(r, 1.2, 1.2, 26, Vector3(36, 22, -18), SAND.darkened(0.3), 6)
			Models._box(r, Vector3(12, 1.2, 8), Vector3(36, 36, -18), CLOTH, Vector3(0, 0.6, 0.1))
		_:
			Models._cyl(r, 30, 40, 18, Vector3(0, 11, -4), OBS, 6, Vector3(0, PI / 6.0, 0))
			Models._cyl(r, 22, 30, 10, Vector3(0, 25, -4), OBS_L, 6, Vector3(0, PI / 6.0, 0))
			Models._crystal(r, 20, 7, Vector3(0, 40, -4), Models.GLOW_VIOLET, 0.0, 0.0, 1.4)
			_door(r, -14, 21.5, 8.5, 30, 11, Color(0.08, 0.06, 0.14), Models.GLOW_VIOLET)
			Models._crystal(r, 22, 6, Vector3(34, 14, -18), Models.GLOW_VIOLET, 0.12, 0.0, 1.2)


static func _tourelle(r: Node3D, f: String, acc: Color) -> void:
	match f:
		"kharn":
			Models._box(r, Vector3(56, 6, 56), Vector3(0, 3, 0), Color(0.2, 0.2, 0.23))
			Models._box(r, Vector3(42, 8, 42), Vector3(0, 10, 0), STEEL, Vector3(0, PI / 4.0, 0))
			Models._box(r, Vector3(46, 1.4, 46), Vector3(0, 14.5, 0), GLOW_RED, Vector3(0, PI / 4.0, 0), 0.9)
		"vael":
			Models._cyl(r, 26, 28, 4, Vector3(0, 2, 0), Color(0.5, 0.4, 0.28), 10)
			Models._cyl(r, 18, 22, 7, Vector3(0, 7, 0), SAND, 10)
			Models._cyl(r, 23, 23, 1.2, Vector3(0, 6.2, 0), GLOW_GOLD, 10, Vector3.ZERO, 0.9)
			for a in 5:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 5.0) * 24.0
				Models._cyl(r, 1.2, 1.2, 12, d + Vector3(0, 6, 0), SAND.darkened(0.3), 6)
		_:
			Models._cyl(r, 22, 28, 5, Vector3(0, 2.5, 0), OBS, 6)
			Models._cyl(r, 16, 20, 6, Vector3(0, 8, 0), OBS_L, 6)
			Models._cyl(r, 24, 24, 1.2, Vector3(0, 6.2, 0), acc, 6, Vector3.ZERO, 1.0)
			for a in 3:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 3.0) * 24.0
				Models._crystal(r, 12, 3.5, d + Vector3(0, 8, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.2)


static func _tourelle_tete(r: Node3D, f: String, acc: Color) -> void:
	# Mêmes bouches de tir que la tourelle de base : (31, 22, ±4)
	match f:
		"kharn":
			Models._box(r, Vector3(20, 8, 20), Vector3(-1, 18, 0), STEEL_L)
			Models._box(r, Vector3(14, 6, 18), Vector3(-4, 24, 0), RUST)
			for z in [-4.0, 4.0]:
				Models._barrel(r, 8, 22, z, 22, 2.4, Models.DARK)
			Models._ball(r, 3.0, Vector3(-6, 28, 0), GLOW_RED, 2.2)
		"vael":
			Models._ball(r, 10, Vector3(0, 17, 0), SAND, 0.0)
			Models._box(r, Vector3(10, 5, 16), Vector3(0, 24, 0), CLOTH)
			for z in [-4.0, 4.0]:
				Models._barrel(r, 8, 22, z, 22, 1.4, Models.DARK)
			Models._ball(r, 2.6, Vector3(-4, 28, 0), GLOW_GOLD, 2.0)
		_:
			Models._cyl(r, 9, 12, 7, Vector3(0, 15, 0), OBS_L, 6)
			Models._crystal(r, 12, 5, Vector3(-2, 26, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.5)
			for z in [-4.0, 4.0]:
				Models._barrel(r, 8, 22, z, 22, 1.6, OBS)
			Models._ball(r, 2.6, Vector3(4, 22, 0), Models.GLOW_VIOLET, 2.2)


static func _silo(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 64, 64, acc)
	match f:
		"kharn":
			for x in [-14.0, 14.0]:
				Models._box(r, Vector3(22, 28, 24), Vector3(x, 16, 0), STEEL)
				Models._box(r, Vector3(24, 4, 26), Vector3(x, 31, 0), RUST)
				Models._box(r, Vector3(22.4, 1.6, 24.4), Vector3(x, 20, 0), GLOW_RED, Vector3.ZERO, 0.9)
			Models._box(r, Vector3(14, 4, 30), Vector3(0, 6, 0), Models.DARK)
		"vael":
			for x in [-14.0, 14.0]:
				Models._cyl(r, 10, 12, 16, Vector3(x, 10, 0), SAND, 10)
				Models._ball(r, 11, Vector3(x, 22, 0), CANVAS, 0.0)
				Models._cyl(r, 12.5, 12.5, 1.6, Vector3(x, 14, 0), GLOW_GOLD, 10, Vector3.ZERO, 0.9)
			Models._box(r, Vector3(14, 3, 30), Vector3(0, 5, 0), CLOTH)
		_:
			for x in [-14.0, 14.0]:
				Models._cyl(r, 3, 11, 30, Vector3(x, 17, 0), OBS_L, 6)
				Models._crystal(r, 12, 5, Vector3(x, 38, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.4)
				Models._cyl(r, 9, 9, 1.4, Vector3(x, 20, 0), acc, 6, Vector3.ZERO, 0.9)
			Models._box(r, Vector3(14, 3, 30), Vector3(0, 5, 0), OBS)


static func _silo_minerai(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 64, 64, acc)
	match f:
		"kharn":
			Models._cyl(r, 10, 22, 26, Vector3(0, 16, 0), STEEL, 4, Vector3(0, PI / 4.0, 0))
			Models._box(r, Vector3(36, 3, 36), Vector3(0, 30, 0), RUST)
			Models._box(r, Vector3(30, 2.0, 30), Vector3(0, 18, 0), GLOW_RED, Vector3(0, PI / 4.0, 0), 1.0)
			Models._box(r, Vector3(14, 8, 6), Vector3(0, 6, 18), Models.DARK)
		"vael":
			Models._cyl(r, 14, 17, 20, Vector3(0, 12, 0), SAND, 8)
			Models._cyl(r, 18, 18, 2, Vector3(0, 23, 0), CLOTH, 8)
			Models._ball(r, 12, Vector3(0, 28, 0), CANVAS, 0.0)
			Models._cyl(r, 17.5, 17.5, 2.0, Vector3(0, 16, 0), GLOW_GOLD, 8, Vector3.ZERO, 1.1)
			Models._box(r, Vector3(14, 8, 6), Vector3(0, 6, 18), Color(0.2, 0.16, 0.1))
		_:
			Models._cyl(r, 8, 17, 22, Vector3(0, 14, 0), OBS_L, 6)
			for a in 3:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 3.0 + 0.5) * 12.0
				Models._crystal(r, 18, 5, d + Vector3(0, 34, 0), Models.GLOW_VIOLET, 0.1, 0.0, 1.3)
			Models._cyl(r, 15, 15, 1.6, Vector3(0, 18, 0), acc, 6, Vector3.ZERO, 1.1)
			Models._box(r, Vector3(14, 8, 6), Vector3(0, 6, 18), OBS)


static func _radar(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 64, 64, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(34, 14, 30), Vector3(0, 10, 0), STEEL)
			Models._box(r, Vector3(22, 6, 22), Vector3(0, 20, 0), STEEL_L, Vector3(0, PI / 4.0, 0))
			Models._cyl(r, 3, 4, 8, Vector3(0, 26, 0), Models.DARK, 6)
			Models._cyl(r, 6, 6, 2.0, Vector3(0, 30.5, 0), GLOW_RED, 8, Vector3.ZERO, 0.8)
		"vael":
			Models._cyl(r, 13, 15, 12, Vector3(0, 8, 0), SAND, 8)
			Models._cyl(r, 1.6, 2.4, 20, Vector3(0, 22, 0), SAND.darkened(0.3), 6)
			Models._cyl(r, 6, 6, 2.0, Vector3(0, 30.5, 0), GLOW_GOLD, 8, Vector3.ZERO, 0.8)
			Models._box(r, Vector3(26, 1.2, 10), Vector3(0, 14, 14), CLOTH, Vector3(0.35, 0, 0))
		_:
			Models._cyl(r, 6, 14, 18, Vector3(0, 11, 0), OBS_L, 6)
			Models._crystal(r, 14, 4, Vector3(0, 27, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.0)
			Models._cyl(r, 6, 6, 2.0, Vector3(0, 30.5, 0), acc, 6, Vector3.ZERO, 0.8)


static func _radar_tete(r: Node3D, f: String, _acc: Color) -> void:
	match f:
		"kharn":
			Models._box(r, Vector3(26, 3, 12), Vector3(0, 34, 0), STEEL_L, Vector3(0.5, 0.0, 0.0))
			Models._box(r, Vector3(2, 2, 14), Vector3(0, 38, 8), Models.DARK, Vector3(0.5, 0.0, 0.0))
			Models._ball(r, 2.6, Vector3(0, 40, 14), GLOW_RED, 2.5)
		"vael":
			Models._cyl(r, 22, 3, 3.5, Vector3(0, 34, 0), CANVAS, 12, Vector3(0.5, 0.0, 0.0))
			Models._cyl(r, 1.0, 1.0, 16, Vector3(0, 40, 6), SAND.darkened(0.3), 6, Vector3(0.9, 0.0, 0.0))
			Models._ball(r, 2.6, Vector3(0, 40, 14), GLOW_GOLD, 2.5)
		_:
			Models._crystal(r, 24, 6, Vector3(0, 40, 0), Models.GLOW_VIOLET, 0.5, 0.0, 1.4)
			Models._box(r, Vector3(2, 2, 14), Vector3(0, 38, 8), OBS, Vector3(0.5, 0.0, 0.0))
			Models._ball(r, 2.6, Vector3(0, 40, 14), Models.GLOW_VIOLET, 2.5)


static func _reparation(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 96, 64, acc)
	match f:
		"kharn":
			for x in [-36.0, 36.0]:
				Models._box(r, Vector3(10, 28, 10), Vector3(x, 16, 0), STEEL)
			Models._box(r, Vector3(82, 8, 12), Vector3(0, 31, 0), RUST)
			Models._box(r, Vector3(76, 1.4, 5), Vector3(0, 35.4, 0), GLOW_RED, Vector3.ZERO, 1.6)
			Models._box(r, Vector3(60, 2, 36), Vector3(0, 4.5, 4), Color(0.14, 0.14, 0.17))
			Models._box(r, Vector3(16, 8, 6), Vector3(0, 22, -3), STEEL_L)
		"vael":
			for x in [-36.0, 36.0]:
				Models._cyl(r, 1.8, 1.8, 30, Vector3(x, 15, 0), SAND.darkened(0.3), 6)
			Models._box(r, Vector3(84, 1.8, 40), Vector3(0, 30, 2), CLOTH, Vector3(0.12, 0, 0))
			Models._box(r, Vector3(70, 1.2, 4), Vector3(0, 28.5, 18), GLOW_GOLD, Vector3.ZERO, 1.4)
			Models._box(r, Vector3(60, 2, 34), Vector3(0, 4, 4), Color(0.45, 0.36, 0.24))
			Models._ball(r, 5, Vector3(0, 16, -8), Models.GLOW_GREEN, 1.4)
		_:
			for x in [-34.0, 34.0]:
				Models._crystal(r, 34, 8, Vector3(x, 18, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.3)
			Models._box(r, Vector3(70, 3, 8), Vector3(0, 32, 0), OBS_L)
			Models._box(r, Vector3(66, 1.2, 4), Vector3(0, 34, 0), Models.GLOW_VIOLET, Vector3.ZERO, 1.6)
			Models._cyl(r, 24, 28, 2, Vector3(0, 4, 4), OBS, 6)


static func _reacteur(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 64, 64, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(42, 22, 42), Vector3(0, 14, 0), STEEL)
			Models._box(r, Vector3(30, 28, 30), Vector3(0, 17, 0), GLOW_RED, Vector3(0, PI / 4.0, 0), 1.6)
			Models._box(r, Vector3(46, 3, 46), Vector3(0, 26, 0), RUST)
			Models._cyl(r, 6, 8, 8, Vector3(0, 33, 0), Models.DARK, 8)
			_spikes(r, 4, 27, 4, 14, STEEL_L)
		"vael":
			Models._cyl(r, 20, 22, 14, Vector3(0, 10, 0), SAND, 10)
			Models._ball(r, 15, Vector3(0, 24, 0), Models.GLOW_GREEN, 1.8)
			Models._cyl(r, 21, 21, 2.0, Vector3(0, 18, 0), CLOTH, 10)
			Models._cyl(r, 6, 8, 8, Vector3(0, 36, 0), SAND.darkened(0.3), 8)
			for a in 3:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 3.0) * 26.0
				Models._cyl(r, 1.4, 1.8, 20, d + Vector3(0, 12, 0), SAND.darkened(0.3), 6)
		_:
			Models._cyl(r, 16, 24, 10, Vector3(0, 8, 0), OBS, 6)
			Models._crystal(r, 36, 14, Vector3(0, 30, 0), Models.GLOW_VIOLET, 0.0, 0.0, 2.0)
			for a in 6:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 6.0) * 24.0
				Models._crystal(r, 16, 4, d + Vector3(0, 14, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.2)
			Models._cyl(r, 22, 22, 1.4, Vector3(0, 13.5, 0), acc, 6, Vector3.ZERO, 1.0)


static func _batterie(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 64, 64, acc)
	match f:
		"kharn":
			Models._box(r, Vector3(46, 10, 46), Vector3(0, 9, 0), STEEL)
			Models._box(r, Vector3(50, 3, 50), Vector3(0, 15.5, 0), RUST)
			_spikes(r, 17, 24, 6, 6, STEEL_L)
		"vael":
			Models._cyl(r, 22, 26, 10, Vector3(0, 8, 0), SAND, 10)
			Models._cyl(r, 24, 24, 1.4, Vector3(0, 13, 0), GLOW_GOLD, 10, Vector3.ZERO, 0.9)
			for a in 6:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 6.0) * 27.0
				Models._cyl(r, 1.2, 1.2, 10, d + Vector3(0, 8, 0), SAND.darkened(0.3), 6)
		_:
			Models._cyl(r, 20, 26, 8, Vector3(0, 7, 0), OBS, 6)
			Models._cyl(r, 24, 24, 1.4, Vector3(0, 11.5, 0), acc, 6, Vector3.ZERO, 1.0)
			for a in 3:
				var d := Vector3.RIGHT.rotated(Vector3.UP, a * TAU / 3.0 + 0.5) * 24.0
				Models._crystal(r, 14, 4, d + Vector3(0, 11, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.2)


static func _batterie_tete(r: Node3D, f: String, _acc: Color) -> void:
	# Mêmes bouches que la batterie de base : (37, 22, -7 / 0 / 7)
	match f:
		"kharn":
			Models._box(r, Vector3(26, 10, 28), Vector3(0, 17, 0), STEEL_L)
			for z in [-7.0, 0.0, 7.0]:
				Models._barrel(r, 10, 22, z, 27, 2.6, Models.DARK)
			Models._box(r, Vector3(10, 4, 20), Vector3(-6, 24, 0), RUST)
			Models._ball(r, 3.0, Vector3(-8, 28, 0), GLOW_RED, 2.0)
		"vael":
			Models._cyl(r, 11, 13, 9, Vector3(0, 16, 0), SAND, 10)
			for z in [-7.0, 0.0, 7.0]:
				Models._barrel(r, 10, 22, z, 27, 1.6, Models.DARK)
			Models._box(r, Vector3(16, 1.4, 22), Vector3(-2, 27, 0), CLOTH)
			Models._ball(r, 2.6, Vector3(-8, 26, 0), GLOW_GOLD, 2.0)
		_:
			Models._cyl(r, 10, 14, 8, Vector3(0, 16, 0), OBS_L, 6)
			for z in [-7.0, 0.0, 7.0]:
				Models._barrel(r, 10, 22, z, 27, 1.8, OBS)
			Models._crystal(r, 14, 5, Vector3(-6, 28, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.5)


static func _aerodrome(r: Node3D, f: String, acc: Color) -> void:
	_plate(r, f, 96, 64, acc)
	# Piste d'envol au même endroit que le modèle de base : (24, 5, 8)
	Models._cyl(r, 17, 17, 1.2, Vector3(24, 4, 8), Color(0.18, 0.18, 0.22) if f != "vael" else Color(0.5, 0.42, 0.3), 12)
	var g := GLOW_RED if f == "kharn" else (GLOW_GOLD if f == "vael" else Models.GLOW_VIOLET)
	Models._cyl(r, 11, 11, 0.8, Vector3(24, 5, 8), g, 12, Vector3.ZERO, 0.9)
	Models._cyl(r, 7, 7, 0.8, Vector3(24, 5.6, 8), Models.DARK, 12)
	match f:
		"kharn":
			Models._box(r, Vector3(44, 20, 32), Vector3(-22, 13, -6), STEEL)
			Models._box(r, Vector3(46, 4, 34), Vector3(-22, 25, -6), RUST)
			Models._box(r, Vector3(30, 10, 3), Vector3(-22, 8, 10), Models.DARK)
			Models._box(r, Vector3(30, 1.2, 3.5), Vector3(-22, 13.6, 10), GLOW_RED, Vector3.ZERO, 1.2)
			Models._cyl(r, 2, 2, 26, Vector3(30, 16, -18), STEEL_L, 6)
			Models._ball(r, 3, Vector3(30, 30, -18), GLOW_RED, 2.2)
		"vael":
			Models._cyl(r, 17, 19, 12, Vector3(-22, 9, -6), SAND, 3, Vector3(0, 0, PI / 2.0))
			Models._box(r, Vector3(42, 12, 30), Vector3(-22, 8, -6), SAND)
			Models._box(r, Vector3(44, 1.6, 22), Vector3(-22, 17, 8), CLOTH, Vector3(0.28, 0, 0))
			Models._box(r, Vector3(30, 9, 3), Vector3(-22, 7, 10), Color(0.2, 0.16, 0.1))
			Models._cyl(r, 1.2, 1.2, 28, Vector3(30, 14, -18), SAND.darkened(0.3), 6)
			Models._box(r, Vector3(10, 1.2, 14), Vector3(34, 26, -18), CLOTH, Vector3(0, 0, 0.5))
		_:
			Models._cyl(r, 14, 22, 20, Vector3(-22, 12, -6), OBS, 6)
			Models._crystal(r, 22, 7, Vector3(-22, 32, -6), Models.GLOW_VIOLET, 0.0, 0.0, 1.3)
			Models._box(r, Vector3(30, 8, 3), Vector3(-22, 7, 12), OBS_L)
			Models._box(r, Vector3(30, 1.2, 3.5), Vector3(-22, 12, 12), Models.GLOW_VIOLET, Vector3.ZERO, 1.2)
			Models._crystal(r, 26, 5, Vector3(30, 16, -18), Models.GLOW_VIOLET, 0.0, 0.0, 1.2)


# --- Engins communs ---------------------------------------------------------------------

static func _hover_pads(r: Node3D, xs: Array, z: float, col: Color, glow: Color) -> void:
	for x in xs:
		for s in [-1.0, 1.0]:
			Models._cyl(r, 5, 6, 2.5, Vector3(float(x), 1.5, z * s), col, 6)
			Models._cyl(r, 4, 4, 0.8, Vector3(float(x), 0.6, z * s), glow, 6, Vector3.ZERO, 1.6)


static func _recolteur(r: Node3D, f: String, body: Color, hi: Color, acc: Color) -> void:
	match f:
		"kharn":
			Models._tracks(r, 38.0, 11.0, 8.0, 8.0)
			Models._box(r, Vector3(36, 8, 20), Vector3(-2, 11, 0), STEEL)
			Models._box(r, Vector3(24, 12, 17), Vector3(-7, 20, 0), RUST)
			Models._box(r, Vector3(20, 1.4, 12), Vector3(-7, 26.6, 0), Models.GLOW_ORANGE, Vector3.ZERO, 1.4)
			Models._box(r, Vector3(9, 7, 14), Vector3(11, 16, 0), hi)
			Models._box(r, Vector3(1.2, 3, 11), Vector3(15.6, 17, 0), GLOW_RED, Vector3.ZERO, 1.2)
			for z in [-7.0, 0.0, 7.0]:
				Models._cyl(r, 0.5, 4, 12, Vector3(23, 6, z), STEEL_L, 6, Vector3(0, 0, -PI / 2.0))
		"vael":
			Models._wheels(r, [-12.0, 0.0, 12.0], 10.0, 5.0, 4.0)
			Models._box(r, Vector3(34, 6, 16), Vector3(-2, 10, 0), SAND)
			Models._cyl(r, 9, 10, 14, Vector3(-7, 19, 0), CANVAS, 8)
			Models._box(r, Vector3(14, 1.2, 10), Vector3(-7, 26.4, 0), Models.GLOW_ORANGE, Vector3.ZERO, 1.4)
			Models._box(r, Vector3(7, 5, 12), Vector3(10, 14, 0), hi)
			Models._cyl(r, 5, 7, 4, Vector3(19, 5, 0), STEEL_L, 8, Vector3(PI / 2.0, 0, 0))
			Models._box(r, Vector3(1.2, 3, 9), Vector3(13.7, 15, 0), GLOW_GOLD, Vector3.ZERO, 1.2)
		_:
			_hover_pads(r, [-10.0, 10.0], 10.0, OBS, Models.GLOW_VIOLET)
			Models._box(r, Vector3(34, 5, 18), Vector3(-2, 8, 0), OBS_L)
			Models._cyl(r, 6, 10, 18, Vector3(-6, 19, 0), OBS, 6)
			Models._crystal(r, 12, 6, Vector3(-6, 33, 0), Models.GLOW_ORANGE, 0.0, 0.0, 1.4)
			Models._box(r, Vector3(8, 5, 12), Vector3(10, 13, 0), hi)
			Models._cyl(r, 1.0, 5, 12, Vector3(21, 7, 0), OBS_L, 6, Vector3(0, 0, -PI / 2.0))


static func _mineur(r: Node3D, f: String, body: Color, hi: Color, acc: Color) -> void:
	match f:
		"kharn":
			Models._tracks(r, 34.0, 10.0, 7.0, 7.0)
			Models._box(r, Vector3(32, 8, 17), Vector3(-2, 10, 0), STEEL)
			Models._box(r, Vector3(16, 10, 14), Vector3(-7, 19, 0), RUST)
			Models._box(r, Vector3(8, 6, 12), Vector3(8, 14, 0), hi)
			Models._cyl(r, 0.5, 8, 14, Vector3(23, 10, 0), STEEL_L, 4, Vector3(0, 0, -PI / 2.0))
			Models._box(r, Vector3(12, 1.2, 10), Vector3(-7, 24.6, 0), GLOW_RED, Vector3.ZERO, 1.2)
		"vael":
			Models._wheels(r, [-10.0, 10.0], 9.0, 5.0, 4.0)
			Models._box(r, Vector3(28, 6, 15), Vector3(-2, 9, 0), SAND)
			Models._cyl(r, 7, 8, 10, Vector3(-6, 16, 0), CANVAS, 8)
			Models._box(r, Vector3(7, 5, 11), Vector3(8, 12, 0), hi)
			Models._cyl(r, 0.5, 5, 16, Vector3(20, 8, 0), STEEL_L, 6, Vector3(0, 0, -PI / 2.0))
			Models._ball(r, 2.4, Vector3(-6, 23, 0), GLOW_GOLD, 1.6)
		_:
			_hover_pads(r, [-8.0, 8.0], 8.0, OBS, Models.GLOW_VIOLET)
			Models._box(r, Vector3(26, 5, 14), Vector3(-2, 8, 0), OBS_L)
			Models._cyl(r, 5, 8, 10, Vector3(-6, 15, 0), OBS, 6)
			Models._box(r, Vector3(7, 5, 10), Vector3(8, 12, 0), hi)
			Models._crystal(r, 20, 5, Vector3(22, 9, 0), Models.GLOW_VIOLET, 1.2, 0.0, 1.4)


static func _mcv(r: Node3D, f: String, body: Color, hi: Color, acc: Color) -> void:
	match f:
		"kharn":
			Models._tracks(r, 46.0, 13.0, 9.0, 9.0)
			Models._box(r, Vector3(48, 10, 26), Vector3(-1, 14, 0), STEEL)
			Models._box(r, Vector3(30, 16, 24), Vector3(-6, 27, 0), RUST)
			Models._box(r, Vector3(32, 3, 26), Vector3(-6, 36.5, 0), STEEL_L)
			Models._box(r, Vector3(6, 14, 6), Vector3(-10, 45, 0), STEEL)
			Models._box(r, Vector3(20, 3, 5), Vector3(2, 52, 0), STEEL_L, Vector3(0, 0, -0.2))
			Models._box(r, Vector3(12, 9, 20), Vector3(16, 22, 0), hi)
			Models._box(r, Vector3(1.2, 4, 15), Vector3(22.2, 23, 0), GLOW_RED, Vector3.ZERO, 1.2)
			Models._ball(r, 2.4, Vector3(-16, 39, 8), GLOW_RED, 1.8)
		"vael":
			Models._wheels(r, [-16.0, 0.0, 16.0], 13.0, 6.0, 5.0)
			Models._box(r, Vector3(46, 7, 22), Vector3(-1, 11, 0), SAND)
			Models._cyl(r, 11, 14, 16, Vector3(-6, 22, 0), CANVAS, 8)
			Models._ball(r, 11, Vector3(-6, 33, 0), CANVAS, 0.0)
			Models._cyl(r, 1.2, 1.2, 14, Vector3(-6, 46, 0), SAND.darkened(0.3), 6)
			Models._box(r, Vector3(8, 1.2, 4), Vector3(-2, 52, 0), GLOW_GOLD, Vector3.ZERO, 1.0)
			Models._box(r, Vector3(10, 8, 16), Vector3(16, 18, 0), hi)
			Models._box(r, Vector3(1.2, 3, 12), Vector3(21.2, 19, 0), GLOW_GOLD, Vector3.ZERO, 1.2)
		_:
			_hover_pads(r, [-14.0, 0.0, 14.0], 12.0, OBS, Models.GLOW_VIOLET)
			Models._box(r, Vector3(44, 6, 22), Vector3(-1, 9, 0), OBS_L)
			Models._cyl(r, 8, 14, 22, Vector3(-6, 23, 0), OBS, 6)
			Models._crystal(r, 22, 9, Vector3(-6, 45, 0), Models.GLOW_VIOLET, 0.0, 0.0, 1.5)
			Models._box(r, Vector3(10, 8, 16), Vector3(15, 17, 0), hi)
			Models._box(r, Vector3(1.2, 3, 12), Vector3(20.2, 18, 0), Models.GLOW_VIOLET, Vector3.ZERO, 1.2)


static func _convoi(r: Node3D, f: String, body: Color, hi: Color, acc: Color) -> void:
	match f:
		"kharn":
			Models._tracks(r, 40.0, 11.0, 8.0, 8.0)
			Models._box(r, Vector3(40, 8, 19), Vector3(-1, 12, 0), STEEL)
			Models._box(r, Vector3(24, 14, 18), Vector3(-6, 23, 0), RUST)
			Models._box(r, Vector3(24, 1.4, 18.4), Vector3(-6, 30.4, 0), Models.GLOW_ORANGE, Vector3.ZERO, 1.2)
			Models._box(r, Vector3(9, 8, 15), Vector3(14, 17, 0), hi)
			Models._box(r, Vector3(1.2, 3, 11), Vector3(18.6, 18, 0), GLOW_RED, Vector3.ZERO, 1.2)
		"vael":
			Models._wheels(r, [-13.0, 0.0, 13.0], 9.5, 5.0, 4.0)
			Models._box(r, Vector3(38, 5, 17), Vector3(-1, 9, 0), SAND)
			Models._cyl(r, 8, 9, 22, Vector3(-6, 20, 0), CANVAS, 3, Vector3(0, 0, PI / 2.0))
			Models._box(r, Vector3(24, 1.4, 18), Vector3(-6, 28, 0), CLOTH)
			Models._box(r, Vector3(8, 7, 14), Vector3(14, 14, 0), hi)
			Models._box(r, Vector3(1.2, 3, 10), Vector3(18.1, 15, 0), GLOW_GOLD, Vector3.ZERO, 1.2)
		_:
			_hover_pads(r, [-12.0, 12.0], 9.0, OBS, Models.GLOW_VIOLET)
			Models._box(r, Vector3(38, 5, 17), Vector3(-1, 8, 0), OBS_L)
			Models._cyl(r, 8, 11, 16, Vector3(-6, 18, 0), OBS, 6)
			Models._crystal(r, 14, 6, Vector3(-6, 33, 0), Models.GLOW_ORANGE, 0.0, 0.0, 1.4)
			Models._box(r, Vector3(8, 6, 13), Vector3(13, 12, 0), hi)
