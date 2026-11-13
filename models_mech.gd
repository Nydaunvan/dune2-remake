class_name ModelsMech
## Mechas : unités marcheuses (jambes) propres à chaque faction.
##   leg = "biped"   : bipède blindé (Solis : élancé, genoux en arrière ; Kharn : massif ; Conclave : obsidienne)
##   leg = "quad"    : quadrupède blindé (Solis : sentinelle élancée à pattes de cerf ; Kharn : mastodonte à piliers)
##   leg = "crystal" : marcheur de cristal à pattes de prisme (Conclave)
##   leg = "spider"  : arachnide à six pattes (Vael)
## Les paramètres viennent de ModelsExt.STYLES (k = "mech"). Le modèle est cuit en sprites comme les chars :
## la marche est animée à l'écran (balancement, voir unit.gd) et laisse des empreintes (TrackLayer).

const GLOWS := ModelsExt.GLOWS


static func build(r: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	var g := Node3D.new()
	var s := float(p.get("s", 1.0))
	g.scale = Vector3(s, s, s)
	r.add_child(g)
	var col := Models.OBSIDIAN if p.get("obs", false) else body
	match String(p.get("leg", "biped")):
		"biped": _biped(g, col, hi, acc, p)
		"quad": _quad(g, col, hi, acc, p)
		"crystal": _crystal_walker(g, col, hi, acc, p)
		"spider": _spider(g, col, hi, acc, p)


## Bouches de tir (x avant, y hauteur, z côté), mises à l'échelle du modèle.
static func muzzles(p: Dictionary) -> Array:
	var s := float(p.get("s", 1.0))
	var out: Array = []
	for m in _muzzles_raw(p):
		out.append((m as Vector3) * s)
	return out


static func _glow(p: Dictionary) -> Color:
	return GLOWS.get(String(p.get("gc", "blue")), GLOWS["blue"])


## Membre : boîte allongée entre deux points (genoux, coudes, pattes).
static func _limb(parent: Node3D, a: Vector3, b: Vector3, thick: float, col: Color, emit := 0.0, wide := -1.0) -> void:
	var d := b - a
	if d.length() < 0.01:
		return
	var dir := d.normalized()
	var up := Vector3.UP if absf(dir.y) < 0.98 else Vector3.RIGHT
	var m := Models._box(parent, Vector3(thick if wide < 0.0 else wide, thick, d.length()), Vector3.ZERO, col, Vector3.ZERO, emit)
	m.transform = Transform3D(Basis.looking_at(dir, up), (a + b) * 0.5)


# --- Bipèdes ------------------------------------------------------------------------------------

static func _dims(p: Dictionary) -> Dictionary:
	var lh := float(p.get("lh", 15.0))
	var tw := float(p.get("tw", 18.0))
	var th := float(p.get("th", 12.0))
	return {"lh": lh, "lz": float(p.get("lz", 7.0)), "tl": float(p.get("tl", 14.0)), "th": th, "tw": tw,
			"ty": lh + 4.0 + th * 0.5, "shy": lh + 2.0 + th, "sz": tw * 0.5 + 4.5, "hx": float(p.get("hx", 9.0))}


static func _muzzles_raw(p: Dictionary) -> Array:
	var d := _dims(p)
	match String(p.get("leg", "biped")):
		"crystal":
			if p.get("mk", "") == "geode":
				return [Vector3(24.0, 17.0, 0.0)]
			return [Vector3(8.0, 52.0, 0.0), Vector3(-2.0, 48.0, 6.0)]
		"quad":
			var qb := float(p.get("bl", 26.0))
			var qy := float(p.get("h", 20.0)) + float(p.get("bh", 9.0))
			if p.get("wp", "plasma") == "rockets":
				return [Vector3(qb * 0.3 + 9.0, qy + 7.5, qb * 0.33), Vector3(qb * 0.3 + 9.0, qy + 7.5, -qb * 0.33)]
			return [Vector3(qb * 0.1 + float(p.get("cl", 24.0)) + 3.0, qy + 7.0, 0.0)]
		"spider":
			var bl := float(p.get("bl", 10.0))
			return [Vector3(10.0 + bl + 1.5, float(p.get("h", 12.0)) + 7.5, 0.0)]
	var hy: float = d["shy"] - 7.0
	match String(p.get("wp", "laser")):
		"rockets":
			return [Vector3(14.0, d["shy"] + 6.0, d["sz"] + 1.0), Vector3(14.0, d["shy"] + 6.0, -d["sz"] - 1.0)]
		"fists":
			return [Vector3(d["hx"] + 8.0, hy, d["sz"]), Vector3(d["hx"] + 8.0, hy, -d["sz"])]
		"plasma":
			return [Vector3(d["tl"] * 0.2 + float(p.get("bl", 24.0)) + 3.0, d["shy"] + 4.0, d["sz"] - 1.0)]
		"mg":
			return [Vector3(d["hx"] + float(p.get("bl", 12.0)) + 1.0, hy, d["sz"])]
	return [Vector3(d["hx"] + float(p.get("bl", 14.0)) + 1.0, hy, d["sz"])]


static func _biped(g: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	Models._seen["legs_biped"] = true
	var d := _dims(p)
	var gc := _glow(p)
	var lh: float = d["lh"]
	var lz: float = d["lz"]
	var tl: float = d["tl"]
	var th: float = d["th"]
	var tw: float = d["tw"]
	var shy: float = d["shy"]
	var sz: float = d["sz"]
	var lt := float(p.get("lt", 5.0))
	var kn := float(p.get("kn", 1.0)) # +1 : genou vers l'avant, -1 : vers l'arrière (jambe d'oiseau)
	var fl := float(p.get("fl", 13.0))
	var ex: Array = p.get("x", [])
	# Jambes : pied, tibia, genou, cuisse
	for sd in [-1.0, 1.0]:
		var z: float = lz * sd
		Models._box(g, Vector3(fl, 3.0, lt + 3.0), Vector3(fl * 0.2, 1.5, z), Models.DARK)
		Models._box(g, Vector3(fl * 0.45, 2.0, lt + 1.0), Vector3(fl * 0.55, 3.6, z), body.darkened(0.1), Vector3(0, 0, -0.25))
		var ankle := Vector3(-1.0 * kn, 4.0, z)
		var knee := Vector3(4.0 * kn, lh * 0.52, z)
		var hip := Vector3(0.0, lh, z)
		_limb(g, ankle, knee, lt, body.darkened(0.15))
		_limb(g, knee, hip, lt + 1.5, body)
		Models._ball(g, lt * 0.62, knee, Models.METAL)
		Models._box(g, Vector3(lt + 2.0, 2.0, lt + 3.0), Vector3(knee.x + 0.5 * kn, knee.y + 0.5, z), hi)
		if "plates" in ex:
			Models._box(g, Vector3(lt + 3.0, lh * 0.35, 1.4), Vector3(knee.x * 0.6, lh * 0.7, z + sd * (lt * 0.5 + 0.6)), Models.METAL)
	# Bassin et torse
	Models._box(g, Vector3(tl * 0.8, 4.0, lz * 2.0 + 5.0), Vector3(0, lh + 2.0, 0), Models.DARK)
	var ty: float = d["ty"]
	Models._box(g, Vector3(tl, th, tw), Vector3(0, ty, 0), body)
	Models._box(g, Vector3(tl * 0.4, th * 0.85, tw * 0.9), Vector3(tl * 0.5, ty + 0.5, 0), hi, Vector3(0, 0, -0.35))
	Models._box(g, Vector3(1.2, 1.8, tw * 0.55), Vector3(tl * 0.5 + 2.2, ty + 1.0, 0), gc, Vector3(0, 0, -0.35), 1.6)
	# Tête
	var hy := lh + 4.0 + th + 2.6
	if p.get("hd", "visor") == "dome":
		Models._ball(g, 4.6, Vector3(tl * 0.25, hy, 0), hi)
		Models._box(g, Vector3(1.2, 1.6, 5.0), Vector3(tl * 0.25 + 4.0, hy + 0.3, 0), gc, Vector3.ZERO, 2.0)
	else:
		Models._box(g, Vector3(7.0, 5.0, 8.0), Vector3(tl * 0.3, hy, 0), hi)
		Models._box(g, Vector3(1.2, 1.8, 6.0), Vector3(tl * 0.3 + 3.8, hy + 0.2, 0), gc, Vector3.ZERO, 2.0)
	if "crown" in ex:
		for k in 3:
			Models._crystal(g, 9.0 + k * 1.5, 2.2, Vector3(tl * 0.3 - 2.0 - k * 1.5, hy + 5.0, (k - 1) * 3.2), GLOWS["violet"], 0.25 * (k - 1), 0.0, 1.6)
	# Épaules et bras
	for sd in [-1.0, 1.0]:
		Models._box(g, Vector3(7.0, 5.0, 7.0), Vector3(0, shy + 1.0, sz * sd), hi)
		if "crystals" in ex:
			Models._crystal(g, 11.0, 2.6, Vector3(-2.0, shy + 8.0, sz * sd), GLOWS["violet"], 0.25 * sd, 0.0, 1.5)
	_arms(g, body, hi, gc, p, d)
	# Dos
	if "stacks" in ex:
		for sd in [-1.0, 1.0]:
			Models._cyl(g, 1.8, 1.8, 9.0, Vector3(-tl * 0.5 - 1.0, shy + 3.0, sd * tw * 0.28), Models.DARK, 6)
			Models._ball(g, 1.5, Vector3(-tl * 0.5 - 1.0, shy + 8.5, sd * tw * 0.28), GLOWS["orange"], 1.6)
	if "pack" in ex:
		Models._box(g, Vector3(6.0, th * 0.9, tw * 0.6), Vector3(-tl * 0.5 - 2.0, ty + 1.0, 0), Models.METAL)
		for sd in [-1.0, 1.0]:
			Models._cyl(g, 2.0, 2.0, 2.0, Vector3(-tl * 0.5 - 5.5, ty + 1.0, sd * 4.0), gc, 6, Vector3(0, 0, PI / 2.0), 1.8)
	if "antenna" in ex:
		Models._box(g, Vector3(0.9, 11.0, 0.9), Vector3(-tl * 0.3, shy + 7.0, -tw * 0.3), Models.DARK)
		Models._ball(g, 1.4, Vector3(-tl * 0.3, shy + 13.0, -tw * 0.3), gc, 2.0)
	if "cracks" in ex:
		for k in 3:
			Models._box(g, Vector3(0.8, th * 0.7, 0.8), Vector3(tl * 0.5 + 1.0, ty, (k - 1) * 4.5), GLOWS["violet"], Vector3(0, 0, -0.35 + 0.1 * (k - 1)), 2.0)


static func _arms(g: Node3D, body: Color, hi: Color, gc: Color, p: Dictionary, d: Dictionary) -> void:
	var shy: float = d["shy"]
	var sz: float = d["sz"]
	var hx: float = d["hx"]
	var tl: float = d["tl"]
	var lt := float(p.get("lt", 5.0))
	var hand_y := shy - 7.0
	var wp := String(p.get("wp", "laser"))
	for sd in [-1.0, 1.0]:
		var sh := Vector3(0, shy - 1.0, sz * sd)
		var el := Vector3(hx * 0.3 - 2.0, shy - 6.0, (sz + 1.5) * sd)
		var hand := Vector3(hx, hand_y, sz * sd)
		var at: float = lt * (1.2 if wp == "fists" else 0.9)
		_limb(g, sh, el, at, body)
		_limb(g, el, hand, at * 0.9, body.darkened(0.15))
		Models._ball(g, at * 0.55, el, Models.METAL)
		var gun_side: bool = sd > 0.0
		match wp:
			"fists":
				Models._box(g, Vector3(8.0, 8.0, 8.0), hand + Vector3(3.0, 0, 0), Models.METAL)
				Models._box(g, Vector3(2.0, 6.0, 6.0), hand + Vector3(7.5, 0, 0), hi)
				for k in 3:
					Models._box(g, Vector3(1.4, 1.4, 1.4), hand + Vector3(8.8, 1.8 - k * 1.8, 0), Models.DARK)
			"laser":
				if gun_side:
					Models._barrel(g, hand.x, hand.y, hand.z, float(p.get("bl", 14.0)), 1.3, Models.DARK)
					Models._box(g, Vector3(6.0, 4.0, 4.0), hand + Vector3(1.0, 0, 0), Models.METAL)
				else:
					Models._cyl(g, 9.0, 9.0, 1.6, hand + Vector3(5.0, 3.0, 0), hi, 10, Vector3(0, 0, PI / 2.0))
					Models._cyl(g, 7.0, 7.0, 2.0, hand + Vector3(5.6, 3.0, 0), gc, 10, Vector3(0, 0, PI / 2.0), 1.1)
			"plasma":
				if gun_side:
					Models._box(g, Vector3(8.0, 5.0, 5.0), hand + Vector3(1.0, 0, 0), Models.METAL)
					Models._barrel(g, tl * 0.2, shy + 4.0, sz * sd - 1.0, float(p.get("bl", 24.0)), 1.8, Models.DARK)
					Models._ball(g, 2.6, Vector3(tl * 0.2 + float(p.get("bl", 24.0)) - 1.0, shy + 4.0, sz * sd - 1.0), gc, 1.8)
				else:
					Models._box(g, Vector3(7.0, 6.0, 4.0), hand + Vector3(2.0, 1.0, 0), Models.DARK)
					Models._ball(g, 2.2, hand + Vector3(5.5, 1.0, 0), gc, 1.8)
			"mg":
				if gun_side:
					Models._box(g, Vector3(7.0, 5.0, 6.0), hand + Vector3(1.5, 0, 0), Models.METAL)
					for k in 3:
						Models._barrel(g, hand.x + 4.0, hand.y + (k - 1) * 1.8, hand.z, float(p.get("bl", 12.0)) - 3.0, 0.9, Models.DARK)
				else:
					Models._box(g, Vector3(3.0, 16.0, 11.0), hand + Vector3(5.0, 1.0, 0), Models.METAL)
					Models._box(g, Vector3(1.2, 12.0, 8.0), hand + Vector3(6.8, 1.0, 0), hi)
					Models._box(g, Vector3(1.4, 3.0, 8.0), hand + Vector3(7.2, 5.0, 0), gc, Vector3.ZERO, 1.2)
			"rockets":
				Models._box(g, Vector3(14.0, 8.0, 8.0), Vector3(5.0, shy + 5.5, sz * sd + sd * 1.0), Models.DARK)
				Models._box(g, Vector3(2.0, 8.4, 8.4), Vector3(12.2, shy + 5.5, sz * sd + sd * 1.0), Models.METAL)
				for k in 3:
					Models._cyl(g, 1.3, 1.3, 2.4, Vector3(12.8, shy + 7.3 - k * 1.8, sz * sd + sd * 1.0 + (k - 1) * 1.6), GLOWS["orange"], 6, Vector3(0, 0, PI / 2.0), 1.4)
				Models._box(g, Vector3(5.0, 4.0, 5.0), hand + Vector3(2.0, 0, 0), Models.METAL)


# --- Marcheurs de cristal ---------------------------------------------------------------------

static func _crystal_walker(g: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	var gc := _glow(p)
	if String(p.get("mk", "")) == "geode":
		Models._seen["legs_crystal"] = true
		# Géode : coque d'obsidienne ouverte sur un coeur de cristaux, portée par quatre pointes
		var h := 13.0
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var top := Vector3(sx * 7.0, h, sz * 7.0)
				var knee := Vector3(sx * 13.0, h + 3.0, sz * 12.0)
				var foot := Vector3(sx * 15.0, 0.0, sz * 15.0)
				_limb(g, top, knee, 3.2, Models.OBSIDIAN)
				_limb(g, knee, foot, 2.6, Models.OBSIDIAN.lightened(0.08))
				Models._crystal(g, 5.0, 2.2, foot + Vector3(0, 2.0, 0), gc, 0.0, 0.0, 1.4)
		Models._cyl(g, 9.0, 12.0, 6.0, Vector3(0, h + 3.0, 0), Models.OBSIDIAN, 8)
		Models._cyl(g, 10.5, 9.5, 2.0, Vector3(0, h + 7.0, 0), body, 8)
		Models._cyl(g, 7.5, 7.5, 1.4, Vector3(0, h + 8.0, 0), gc, 8, Vector3.ZERO, 1.6)
		for k in 7:
			var a := TAU * k / 7.0
			var rr := 3.0 + (k % 3) * 1.4
			Models._crystal(g, 9.0 + (k % 3) * 3.0, 2.4, Vector3(cos(a) * rr - 2.0, h + 13.0, sin(a) * rr), gc, cos(a) * 0.35, sin(a) * 0.35, 1.7)
		Models._crystal(g, 16.0, 3.0, Vector3(14.0, h + 4.0, 0), gc, -PI / 2.0, 0.0, 1.8)
		Models._crystal(g, 11.0, 2.2, Vector3(11.0, h + 8.0, 4.0), gc, -PI / 2.0 + 0.2, 0.0, 1.4)
		Models._crystal(g, 11.0, 2.2, Vector3(11.0, h + 8.0, -4.0), gc, -PI / 2.0 - 0.2, 0.0, 1.4)
		return
	# Stèle : obélisque sur deux piliers, anneaux flottants et aiguilles tournées vers le ciel
	Models._seen["legs_crystal"] = true
	for sd in [-1.0, 1.0]:
		var z: float = 6.0 * sd
		Models._box(g, Vector3(10.0, 2.5, 8.0), Vector3(1.0, 1.25, z), Models.OBSIDIAN)
		_limb(g, Vector3(1.0, 2.5, z), Vector3(-3.0, 15.0, z), 4.0, Models.OBSIDIAN.lightened(0.06))
		_limb(g, Vector3(-3.0, 15.0, z), Vector3(0.0, 27.0, z * 0.7), 4.6, Models.OBSIDIAN)
		Models._crystal(g, 7.0, 2.4, Vector3(5.0, 8.0, z), gc, -0.3, 0.0, 1.2)
	Models._box(g, Vector3(14.0, 4.0, 15.0), Vector3(0, 27.0, 0), Models.OBSIDIAN)
	Models._cyl(g, 4.0, 7.5, 18.0, Vector3(0, 38.0, 0), body, 4, Vector3(0, 0.78, 0))
	Models._cyl(g, 1.8, 1.8, 12.0, Vector3(0, 38.0, 0), gc, 4, Vector3(0, 0.78, 0), 1.7)
	for k in 2:
		Models._cyl(g, 9.5 - k * 1.5, 9.5 - k * 1.5, 1.2, Vector3(0, 33.0 + k * 8.0, 0), hi, 10, Vector3.ZERO, 0.4)
	Models._crystal(g, 12.0, 2.8, Vector3(0, 52.0, 0), gc, 0.0, 0.0, 2.0)
	for sd in [-1.0, 1.0]:
		Models._crystal(g, 15.0, 2.2, Vector3(1.0, 49.0, 5.0 * sd), gc, 0.25 * sd + 0.1, 0.0, 1.6)
		Models._crystal(g, 10.0, 2.0, Vector3(-4.0, 44.0, 7.0 * sd), gc, 0.4 * sd, 0.0, 1.3)


# --- Quadrupèdes ----------------------------------------------------------------------------------

static func _quad(g: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	Models._seen["legs_quad"] = true
	var h := float(p.get("h", 20.0))
	var bw := float(p.get("bw", 14.0))
	var bl := float(p.get("bl", 26.0))
	var bh := float(p.get("bh", 9.0))
	var lt := float(p.get("lt", 4.0))
	var gc := _glow(p)
	var ex: Array = p.get("x", [])
	var heavy: bool = p.get("wp", "plasma") == "rockets"
	# Quatre pattes : hanches, genou, pied (pattes avant : genou en avant ; arrière : jarret en arrière)
	for fx in [1.0, -1.0]:
		for sd in [-1.0, 1.0]:
			var x: float = bl * 0.36 * fx
			var z: float = (bw * 0.5 + (1.0 if heavy else 0.5)) * sd
			var hip := Vector3(x, h, z)
			var knee := Vector3(x + (3.0 if heavy else 5.0) * fx, h * 0.5, z + sd * 1.2)
			var foot := Vector3(x - (1.0 if heavy else 2.0) * fx, 3.0, z + sd * 0.4)
			_limb(g, hip, knee, lt + 1.2, body)
			_limb(g, knee, foot, lt, body.darkened(0.15))
			Models._ball(g, lt * 0.7, knee, Models.METAL)
			Models._box(g, Vector3(lt + 5.0, 3.0, lt + 4.0), Vector3(foot.x + 1.0 * fx, 1.5, foot.z), Models.DARK)
			if heavy:
				Models._box(g, Vector3(lt + 3.0, h * 0.35, 1.4), Vector3(x + 1.0 * fx, h * 0.72, z + sd * (lt * 0.5 + 1.0)), Models.METAL)
	# Châssis et dessus
	var by := h + bh * 0.5
	Models._box(g, Vector3(bl, bh, bw), Vector3(0, by, 0), body)
	Models._box(g, Vector3(bl * 0.55, bh * 0.7, bw * 0.92), Vector3(bl * 0.2, by + bh * 0.5, 0), hi, Vector3(0, 0, -0.12))
	Models._box(g, Vector3(bl * 0.7, 1.4, 1.2), Vector3(0, by + 1.0, bw * 0.5 + 0.2), gc, Vector3.ZERO, 1.4)
	Models._box(g, Vector3(bl * 0.7, 1.4, 1.2), Vector3(0, by + 1.0, -bw * 0.5 - 0.2), gc, Vector3.ZERO, 1.4)
	# Tête / museau à l'avant
	var hx := bl * 0.5
	if heavy:
		Models._box(g, Vector3(10.0, bh + 3.0, bw * 0.8), Vector3(hx + 3.0, by + 0.5, 0), hi)
		Models._box(g, Vector3(1.2, 2.0, bw * 0.55), Vector3(hx + 8.2, by + 2.0, 0), gc, Vector3.ZERO, 2.0)
		for sd in [-1.0, 1.0]:
			_limb(g, Vector3(hx + 6.0, by - 2.0, bw * 0.3 * sd), Vector3(hx + 15.0, by - 8.0, bw * 0.34 * sd), 2.6, Models.METAL)
	else:
		Models._ball(g, 5.0, Vector3(hx + 3.0, by + 2.0, 0), hi)
		Models._box(g, Vector3(1.2, 2.0, 6.0), Vector3(hx + 7.4, by + 2.4, 0), gc, Vector3.ZERO, 2.2)
		Models._box(g, Vector3(0.9, 9.0, 0.9), Vector3(hx - 1.0, by + 7.0, -bw * 0.3), Models.DARK)
		Models._ball(g, 1.4, Vector3(hx - 1.0, by + 12.0, -bw * 0.3), gc, 2.0)
	# Armement
	var top := h + bh
	if heavy:
		for sd in [-1.0, 1.0]:
			var z: float = bw * 0.33 * sd
			Models._box(g, Vector3(16.0, 9.0, 8.0), Vector3(bl * 0.3, top + 5.0, z), Models.DARK)
			Models._box(g, Vector3(2.0, 9.4, 8.4), Vector3(bl * 0.3 + 8.2, top + 5.0, z), Models.METAL)
			for k in 3:
				Models._cyl(g, 1.4, 1.4, 2.4, Vector3(bl * 0.3 + 9.0, top + 7.2 - k * 2.0, z + (k - 1) * 1.8), GLOWS["orange"], 6, Vector3(0, 0, PI / 2.0), 1.4)
		if "stacks" in ex:
			for sd in [-1.0, 1.0]:
				Models._cyl(g, 2.0, 2.0, 10.0, Vector3(-bl * 0.4, top + 5.0, sd * bw * 0.25), Models.DARK, 6)
				Models._ball(g, 1.6, Vector3(-bl * 0.4, top + 10.5, sd * bw * 0.25), GLOWS["orange"], 1.6)
	else:
		var cl := float(p.get("cl", 24.0))
		Models._box(g, Vector3(12.0, 7.0, 8.0), Vector3(bl * 0.05, top + 4.0, 0), Models.METAL)
		Models._barrel(g, bl * 0.1, top + 7.0, 0.0, cl, 2.0, Models.DARK)
		Models._ball(g, 2.8, Vector3(bl * 0.1 + cl - 1.0, top + 7.0, 0.0), gc, 1.8)
		if "pack" in ex:
			Models._box(g, Vector3(7.0, bh * 0.9, bw * 0.7), Vector3(-bl * 0.4, top + 3.0, 0), Models.METAL)
			for sd in [-1.0, 1.0]:
				Models._cyl(g, 2.2, 2.2, 2.0, Vector3(-bl * 0.4 - 4.0, top + 3.0, sd * 4.0), gc, 6, Vector3(0, 0, PI / 2.0), 1.8)
	if "plates" in ex:
		for sd in [-1.0, 1.0]:
			Models._box(g, Vector3(bl * 0.5, bh * 0.6, 1.4), Vector3(-bl * 0.1, by, (bw * 0.5 + 0.8) * sd), Models.METAL)


# --- Arachnides -----------------------------------------------------------------------------------

static func _spider(g: Node3D, body: Color, hi: Color, acc: Color, p: Dictionary) -> void:
	Models._seen["legs_spider"] = true
	var h := float(p.get("h", 12.0))
	var gc := _glow(p)
	var lt := float(p.get("lt", 2.4))
	var bw := float(p.get("bw", 10.0))
	var bl := float(p.get("bl", 10.0))
	# Six pattes : chaque patte = attache, genou haut, pied au sol
	var rows := [[8.0, 14.0, 12.0, 22.0], [1.0, 6.0, 15.0, 8.0], [-6.0, -12.0, 13.0, -18.0]]
	for row in rows:
		for sd in [-1.0, 1.0]:
			var ax: float = row[0]
			var a := Vector3(ax, h - 1.0, bw * 0.4 * sd)
			var knee := Vector3(ax + row[1] * 0.35, h + 6.0, (bw * 0.4 + row[2] * 0.55) * sd)
			var foot := Vector3(ax + row[3] * 0.55, 0.0, (bw * 0.4 + row[2]) * sd)
			_limb(g, a, knee, lt * 1.15, body.darkened(0.12))
			_limb(g, knee, foot, lt * 0.9, body.darkened(0.25))
			Models._ball(g, lt * 0.8, knee, Models.METAL)
			Models._box(g, Vector3(2.4, 1.2, 2.4), foot + Vector3(0, 0.6, 0), Models.DARK)
	# Corps : céphalothorax, abdomen, yeux
	Models._box(g, Vector3(bl + 6.0, 6.0, bw), Vector3(5.0, h + 1.0, 0), body)
	Models._box(g, Vector3(bl * 0.5, 4.0, bw * 0.75), Vector3(9.0, h + 5.0, 0), hi, Vector3(0, 0, -0.2))
	Models._ball(g, float(p.get("ab", 7.5)), Vector3(-9.0, h + 2.0, 0), body.darkened(0.08))
	Models._ball(g, float(p.get("ab", 7.5)) * 0.7, Vector3(-13.0, h + 5.0, 0), hi.darkened(0.15))
	for sd in [-1.0, 1.0]:
		Models._ball(g, 1.3, Vector3(13.5, h + 5.5, 2.0 * sd), gc, 2.2)
		Models._ball(g, 0.9, Vector3(14.0, h + 3.8, 3.4 * sd), gc, 2.0)
	# Rayures ocre sur l'abdomen
	for k in 3:
		Models._box(g, Vector3(1.6, 1.0, bw * 0.75), Vector3(-6.0 - k * 3.6, h + 7.6 - k * 0.6, 0), GLOWS["gold"], Vector3.ZERO, 0.7)
	# Chélicères
	var big: bool = p.get("fangs", false)
	for sd in [-1.0, 1.0]:
		var base := Vector3(14.5, h, 2.6 * sd)
		var tip := Vector3(base.x + (7.0 if big else 4.5), h - (6.0 if big else 3.5), 2.0 * sd)
		_limb(g, base, tip, 2.4 if big else 1.6, Models.METAL)
		if big:
			Models._ball(g, 1.8, tip, gc, 2.0)
	# Arme : jet d'acide dorsal (canon sur le dos)
	var barrel_l := float(p.get("bl", 10.0))
	Models._box(g, Vector3(8.0, 4.0, 5.0), Vector3(8.0, h + 7.5, 0), Models.DARK)
	Models._barrel(g, 10.0, h + 7.5, 0.0, barrel_l, 1.4 if big else 1.0, Models.DARK)
	if big:
		for sd in [-1.0, 1.0]:
			Models._ball(g, 3.2, Vector3(-8.0, h + 7.0, 5.5 * sd), gc, 1.5)
