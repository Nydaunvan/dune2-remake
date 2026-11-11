class_name Models
## Modèles 3D low-poly construits par le code (primitives facettées).
## Repère : +X = avant du véhicule, +Y = haut, sol à y = 0. Unité = 1 pixel du monde 2D.
## Les bâtiments sont centrés sur leur emprise.

const DARK := Color(0.13, 0.14, 0.18)
const METAL := Color(0.42, 0.45, 0.52)
const LIGHT := Color(0.74, 0.77, 0.84)
const GLOW_ORANGE := Color(1.0, 0.45, 0.12)
const GLOW_BLUE := Color(0.25, 0.8, 1.0)
const GLOW_GREEN := Color(0.35, 1.0, 0.5)
const GLOW_MAGENTA := Color(1.0, 0.3, 0.9)


static func build(id: String, accent: Color) -> Node3D:
	var r := Node3D.new()
	var body := accent.darkened(0.3)
	var hi := accent.lightened(0.25)
	match id:
		"recolteur": _harvester(r, body, hi, accent)
		"mineur": _miner(r, body, hi, accent)
		"mcv": _mcv(r, body, hi, accent)
		"convoi": _convoi(r, body, hi, accent)
		"sentinelle": _sentinelle(r, body, hi, accent)
		"egide": _egide(r, body, hi, accent)
		"resonateur": _resonateur(r, body, hi, accent)
		"belier": _belier(r, body, hi, accent)
		"brute": _brute(r, body, hi, accent)
		"salve": _salve(r, body, hi, accent)
		"faucon": _faucon(r, body, hi, accent)
		"vipere": _vipere(r, body, hi, accent)
		"mirage": _mirage(r, body, hi, accent)
		"chantier": _chantier(r, accent)
		"centrale": _centrale(r, accent)
		"raffinerie": _raffinerie(r, accent)
		"fonderie": _fonderie(r, accent)
		"usine": _usine(r, accent)
		"tourelle": _tourelle_base(r, accent)
		"tourelle_tete": _tourelle_tete(r, accent)
		"libellule": _fighter(r, body, hi, accent, 0)
		"aigrette": _fighter(r, body, hi, accent, 1)
		"guepe": _fighter(r, body, hi, accent, 2)
		"faucheur": _copter(r, body, hi, accent)
		"marteau": _bomber(r, body, hi, accent, false)
		"frelon": _bomber(r, body, hi, accent, true)
		"nacelle": _carrier(r, body, hi, accent, 1.0)
		"pelican": _carrier(r, body, hi, accent, 0.9)
		"mule": _carrier(r, body, hi, accent, 1.3)
		"aerodrome": _aerodrome(r, accent)
		"mur": _mur(r, accent, false)
		"mur_acier": _mur(r, accent, true)
		"silo": _silo(r, accent)
		"radar": _radar(r, accent)
		"reparation": _reparation(r, accent)
		"reacteur": _reacteur(r, accent)
		"relais_solaire": _relais(r, accent)
		"marche": _marche(r, accent)
		"batterie", "tour_sonique", "bunker", "tour_acide": _tour_base(r, accent, id)
		"batterie_tete", "tour_sonique_tete", "bunker_tete", "tour_acide_tete": _tour_tete(r, accent, id)
		_: _box(r, Vector3(20, 10, 20), Vector3(0, 5, 0), accent)
	return r


# --- Primitives ---------------------------------------------------------------

static func _mat(col: Color, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.5
	m.metallic = 0.3
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit * 0.5
	return m


## Maillage à facettes : une normale par triangle (look low-poly net).
static func _faceted(mesh: Mesh) -> ArrayMesh:
	var a := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var idx = a[Mesh.ARRAY_INDEX]
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var n_tri: int = (idx.size() if idx != null else v.size()) / 3
	for t in n_tri:
		var i0: int = idx[t * 3] if idx != null else t * 3
		var i1: int = idx[t * 3 + 1] if idx != null else t * 3 + 1
		var i2: int = idx[t * 3 + 2] if idx != null else t * 3 + 2
		var p0 := v[i0]
		var p1 := v[i1]
		var p2 := v[i2]
		var n := (p1 - p0).cross(p2 - p0)
		if n.length() < 0.0001:
			continue
		n = n.normalized()
		if n.dot((p0 + p1 + p2) / 3.0) < 0.0: # formes centrées : la normale sort du centre
			n = -n
		out_v.append_array([p0, p1, p2])
		out_n.append_array([n, n, n])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = out_v
	arr[Mesh.ARRAY_NORMAL] = out_n
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


static func _place(parent: Node3D, mesh: Mesh, pos: Vector3, col: Color, rot: Vector3, emit: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _faceted(mesh)
	mi.material_override = _mat(col, emit)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _box(parent: Node3D, size: Vector3, pos: Vector3, col: Color, rot := Vector3.ZERO, emit := 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _place(parent, m, pos, col, rot, emit)


## Cylindre / cône (r_top = 0). Axe Y par défaut ; tourner de (PI/2,0,0) pour l'axe Z, (0,0,PI/2) pour l'axe X.
static func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, col: Color,
		sides := 8, rot := Vector3.ZERO, emit := 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	return _place(parent, m, pos, col, rot, emit)


static func _ball(parent: Node3D, r: float, pos: Vector3, col: Color, emit := 0.0) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 8
	m.rings = 4
	return _place(parent, m, pos, col, Vector3.ZERO, emit)


## Chenilles : deux blocs + galets aux extrémités.
static func _tracks(parent: Node3D, length: float, spread: float, width: float, h: float) -> void:
	for s in [-1.0, 1.0]:
		_box(parent, Vector3(length, h, width), Vector3(0, h / 2.0, spread * s), DARK)
		for e in [-1.0, 1.0]:
			_cyl(parent, h / 2.0, h / 2.0, width, Vector3(length / 2.0 * e, h / 2.0, spread * s), METAL, 8, Vector3(PI / 2.0, 0, 0))
		_box(parent, Vector3(length * 0.8, 1.0, width + 0.8), Vector3(0, h + 0.5, spread * s), METAL)


static func _wheels(parent: Node3D, xs: Array, spread: float, r: float, width: float) -> void:
	for x in xs:
		for s in [-1.0, 1.0]:
			_cyl(parent, r, r, width, Vector3(float(x), r, spread * s), DARK, 8, Vector3(PI / 2.0, 0, 0))
			_cyl(parent, r * 0.45, r * 0.45, width + 0.6, Vector3(float(x), r, spread * s), METAL, 6, Vector3(PI / 2.0, 0, 0))


static func _barrel(parent: Node3D, x: float, y: float, z: float, length: float, r: float, col := DARK) -> void:
	_cyl(parent, r, r, length, Vector3(x + length / 2.0, y, z), col, 6, Vector3(0, 0, PI / 2.0))
	_cyl(parent, r * 1.5, r * 1.5, 2.0, Vector3(x + length, y, z), METAL, 6, Vector3(0, 0, PI / 2.0))


# --- Unités -------------------------------------------------------------------

static func _harvester(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_tracks(r, 36.0, 10.5, 7.0, 7.0)
	_box(r, Vector3(34, 7, 18), Vector3(-2, 10, 0), body)
	_box(r, Vector3(20, 10, 15), Vector3(-6, 17, 0), METAL) # cuve
	_box(r, Vector3(16, 1.2, 11), Vector3(-6, 22.4, 0), GLOW_ORANGE, Vector3.ZERO, 1.4) # épice
	_box(r, Vector3(8, 6, 14), Vector3(9, 14, 0), hi) # cabine
	_box(r, Vector3(1.2, 3, 11), Vector3(13.4, 15, 0), GLOW_BLUE, Vector3.ZERO, 1.2)
	_cyl(r, 5, 5, 20, Vector3(19, 5, 0), DARK, 8, Vector3(PI / 2.0, 0, 0)) # tambour
	for i in 5:
		_box(r, Vector3(3, 3, 2), Vector3(19, 5, -8 + i * 4.0), acc.lightened(0.3))


static func _mcv(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_tracks(r, 44.0, 13.0, 8.0, 8.0)
	_box(r, Vector3(46, 8, 24), Vector3(-1, 12, 0), body)
	_box(r, Vector3(26, 14, 22), Vector3(-6, 23, 0), METAL)            # module de chantier
	_box(r, Vector3(24, 2, 20), Vector3(-6, 30.5, 0), acc.lightened(0.1))
	_box(r, Vector3(4, 12, 3), Vector3(-6, 36, -7), hi)                  # mât / grue
	_box(r, Vector3(16, 2.5, 3), Vector3(2, 42, -7), hi, Vector3(0, 0, -0.25))
	_box(r, Vector3(1.5, 6, 1.5), Vector3(10, 38, -7), DARK)
	_box(r, Vector3(12, 9, 18), Vector3(15, 20, 0), hi)                  # cabine
	_box(r, Vector3(1.2, 4, 14), Vector3(21.2, 21, 0), GLOW_BLUE, Vector3.ZERO, 1.2)
	_box(r, Vector3(26, 1.4, 3), Vector3(-6, 24, 11.6), GLOW_ORANGE, Vector3.ZERO, 1.0)   # bandes de sécurité
	_box(r, Vector3(26, 1.4, 3), Vector3(-6, 24, -11.6), GLOW_ORANGE, Vector3.ZERO, 1.0)
	_ball(r, 2.2, Vector3(-14, 33, 6), GLOW_ORANGE, 1.6)                 # gyrophare


static func _convoi(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_tracks(r, 38.0, 11.0, 7.0, 7.0)
	_box(r, Vector3(38, 6, 18), Vector3(-1, 10, 0), body)
	_box(r, Vector3(22, 12, 17), Vector3(-6, 19, 0), METAL)             # conteneur
	_box(r, Vector3(22, 1.2, 17.4), Vector3(-6, 25.4, 0), GLOW_ORANGE, Vector3.ZERO, 1.2)
	_box(r, Vector3(1.6, 12, 17.4), Vector3(-10, 19, 0), acc.lightened(0.2))
	_box(r, Vector3(1.6, 12, 17.4), Vector3(-1, 19, 0), acc.lightened(0.2))
	_box(r, Vector3(9, 8, 15), Vector3(13, 15, 0), hi)
	_box(r, Vector3(1.2, 3, 11), Vector3(17.6, 16, 0), GLOW_BLUE, Vector3.ZERO, 1.2)


static func _miner(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_tracks(r, 32.0, 9.5, 6.0, 6.0)
	_box(r, Vector3(30, 7, 16), Vector3(-2, 9, 0), body)
	_box(r, Vector3(14, 9, 13), Vector3(-7, 16, 0), METAL)
	_box(r, Vector3(10, 1.2, 9), Vector3(-7, 20.6, 0), GLOW_BLUE, Vector3.ZERO, 1.2)
	_box(r, Vector3(8, 6, 12), Vector3(7, 13, 0), hi)
	_cyl(r, 0.5, 7, 16, Vector3(21, 9, 0), Color(0.6, 0.64, 0.72), 6, Vector3(0, 0, -PI / 2.0))
	_cyl(r, 7.5, 7.5, 3, Vector3(12, 9, 0), DARK, 8, Vector3(0, 0, PI / 2.0))


static func _sentinelle(r: Node3D, body: Color, hi: Color, _acc: Color) -> void:
	_wheels(r, [-9, 9], 8.0, 4.5, 4.0)
	_box(r, Vector3(26, 4, 11), Vector3(0, 7.5, 0), body)
	_box(r, Vector3(10, 4, 9), Vector3(-4, 11, 0), hi)
	_box(r, Vector3(7, 3, 7), Vector3(5, 10, 0), METAL, Vector3(0, 0, -0.35))
	_barrel(r, 4, 14, 0, 12, 1.0)
	_ball(r, 2.5, Vector3(2, 13, 0), hi)
	_box(r, Vector3(1, 1.5, 6), Vector3(13.2, 8, 0), GLOW_BLUE, Vector3.ZERO, 1.5)


static func _egide(r: Node3D, body: Color, hi: Color, _acc: Color) -> void:
	_tracks(r, 32.0, 9.0, 6.0, 7.0)
	_box(r, Vector3(30, 6, 15), Vector3(0, 10, 0), body)
	_box(r, Vector3(9, 3.5, 15), Vector3(14, 9, 0), body.lightened(0.1), Vector3(0, 0, -0.5))
	_box(r, Vector3(15, 6, 13), Vector3(-1, 16, 0), hi)
	_cyl(r, 3.5, 4.5, 3, Vector3(-3, 20.5, 0), METAL, 8)
	_barrel(r, 6, 16.5, 0, 17, 1.7)
	_box(r, Vector3(1, 1.5, 4), Vector3(15, 11, 4), GLOW_BLUE, Vector3.ZERO, 1.4)
	_box(r, Vector3(1, 1.5, 4), Vector3(15, 11, -4), GLOW_BLUE, Vector3.ZERO, 1.4)


static func _resonateur(r: Node3D, body: Color, hi: Color, _acc: Color) -> void:
	_tracks(r, 30.0, 8.5, 6.0, 6.0)
	_box(r, Vector3(28, 6, 13), Vector3(-1, 9, 0), body)
	_box(r, Vector3(8, 5, 11), Vector3(-8, 14, 0), METAL)
	# antenne parabolique inclinée vers l'avant
	_cyl(r, 11, 3, 5, Vector3(6, 20, 0), hi, 10, Vector3(0, 0, PI / 2.0 - 0.45))
	_cyl(r, 8, 8, 0.8, Vector3(9.2, 21.8, 0), GLOW_BLUE, 10, Vector3(0, 0, PI / 2.0 - 0.45), 1.8)
	_ball(r, 2.2, Vector3(12, 23.5, 0), GLOW_BLUE, 2.5)
	_cyl(r, 2, 3, 8, Vector3(2, 15, 0), METAL, 6)


static func _belier(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_wheels(r, [-9, 8], 9.5, 5.5, 5.0)
	_box(r, Vector3(27, 5, 12), Vector3(0, 8, 0), body)
	_box(r, Vector3(9, 5, 10), Vector3(-5, 13, 0), hi)
	# arceau de sécurité + bélier avant
	for z in [-5.0, 5.0]:
		_box(r, Vector3(1.4, 1.4, 1.4), Vector3(-10, 17, z), METAL)
		_box(r, Vector3(14, 1.2, 1.2), Vector3(-3, 17, z), METAL)
	_box(r, Vector3(5, 8, 14), Vector3(15, 8, 0), acc.lightened(0.15), Vector3(0, 0, 0.0))
	_box(r, Vector3(3, 3, 3), Vector3(18.5, 8, -4), DARK)
	_box(r, Vector3(3, 3, 3), Vector3(18.5, 8, 4), DARK)
	_barrel(r, 2, 15.5, 0, 9, 1.0)


static func _brute(r: Node3D, body: Color, hi: Color, _acc: Color) -> void:
	_tracks(r, 38.0, 12.0, 9.0, 9.0)
	_box(r, Vector3(36, 8, 22), Vector3(0, 13, 0), body)
	_box(r, Vector3(12, 4, 22), Vector3(19, 11, 0), body.lightened(0.1), Vector3(0, 0, -0.55))
	_box(r, Vector3(20, 8, 17), Vector3(-2, 21, 0), hi)
	_box(r, Vector3(6, 3, 19), Vector3(-9, 26, 0), METAL)
	_cyl(r, 4.5, 5.5, 3, Vector3(-4, 26.5, 0), METAL, 8)
	_barrel(r, 8, 22, 0, 22, 2.6)
	for z in [-9.0, 9.0]:
		_box(r, Vector3(16, 6, 1.5), Vector3(-2, 21, z * 1.0), METAL)


static func _salve(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_wheels(r, [-11, 0, 11], 9.0, 5.0, 5.0)
	_box(r, Vector3(36, 5, 14), Vector3(0, 8.5, 0), body)
	_box(r, Vector3(10, 7, 13), Vector3(13, 13, 0), hi) # cabine
	_box(r, Vector3(1, 3, 10), Vector3(18.2, 14, 0), GLOW_BLUE, Vector3.ZERO, 1.2)
	# bloc de roquettes incliné
	var pod := Node3D.new()
	pod.position = Vector3(-6, 14, 0)
	pod.rotation = Vector3(0, 0, 0.5)
	r.add_child(pod)
	_box(pod, Vector3(22, 10, 15), Vector3.ZERO, METAL)
	for iy in 2:
		for iz in 3:
			_cyl(pod, 2.0, 2.0, 2.0, Vector3(11.5, -2.5 + iy * 5.0, -4.5 + iz * 4.5), acc.lightened(0.2), 6, Vector3(0, 0, PI / 2.0))
			_cyl(pod, 1.2, 1.2, 0.6, Vector3(12.2, -2.5 + iy * 5.0, -4.5 + iz * 4.5), GLOW_ORANGE, 6, Vector3(0, 0, PI / 2.0), 1.6)


static func _faucon(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_cyl(r, 5, 6, 3, Vector3(-10, 5, 7), DARK, 8)
	_cyl(r, 5, 6, 3, Vector3(-10, 5, -7), DARK, 8)
	_box(r, Vector3(26, 4, 8), Vector3(0, 8, 0), body)
	_box(r, Vector3(14, 3, 6), Vector3(7, 7, 0), hi, Vector3(0, 0, -0.3))
	_box(r, Vector3(8, 3.5, 5), Vector3(-3, 11.5, 0), METAL)
	_ball(r, 3.2, Vector3(-2, 13.5, 0), GLOW_GREEN, 0.6)
	for s in [-1.0, 1.0]:
		_box(r, Vector3(12, 1.0, 9), Vector3(-9, 7, 9.5 * s), acc, Vector3(0.0, 0.5 * s, 0.0))
		_box(r, Vector3(7, 0.8, 1.2), Vector3(5, 8, 3.5 * s), GLOW_GREEN, Vector3.ZERO, 1.6)
	_barrel(r, 8, 9.5, 0, 8, 0.8)


static func _vipere(r: Node3D, body: Color, hi: Color, _acc: Color) -> void:
	_tracks(r, 30.0, 8.5, 5.5, 6.0)
	_box(r, Vector3(28, 4.5, 13), Vector3(0, 8.5, 0), body)
	_box(r, Vector3(10, 3, 13), Vector3(14, 8, 0), body.lightened(0.1), Vector3(0, 0, -0.55))
	for z in [-4.5, 4.5]:
		_cyl(r, 4, 4, 14, Vector3(-4, 14, z), Color(0.12, 0.35, 0.18), 8, Vector3(0, 0, PI / 2.0))
		_cyl(r, 3.0, 3.0, 12, Vector3(-4, 14, z), GLOW_GREEN, 8, Vector3(0, 0, PI / 2.0), 1.1)
	_box(r, Vector3(8, 4, 7), Vector3(6, 13, 0), hi)
	_cyl(r, 1.2, 2.2, 14, Vector3(15, 14, 0), METAL, 6, Vector3(0, 0, PI / 2.0 - 0.1))
	_ball(r, 1.6, Vector3(22, 14.5, 0), GLOW_GREEN, 2.0)


static func _mirage(r: Node3D, body: Color, hi: Color, _acc: Color) -> void:
	_cyl(r, 11, 9, 4, Vector3(0, 7, 0), body, 10)          # coque aérodynamique
	_cyl(r, 12, 12, 1.0, Vector3(0, 6, 0), METAL, 10)
	_cyl(r, 8, 6, 5, Vector3(-1, 11.5, 0), hi, 10)
	_ball(r, 4.0, Vector3(5, 14, 0), GLOW_MAGENTA, 2.2)       # lentille de contrôle
	_cyl(r, 11.5, 11.5, 0.8, Vector3(0, 4.5, 0), GLOW_MAGENTA, 10, Vector3.ZERO, 1.6) # anneau de sustentation
	_box(r, Vector3(10, 1.2, 1.6), Vector3(9, 8, 0), METAL)
	_box(r, Vector3(3, 1.2, 14), Vector3(-9, 9, 0), METAL)


# --- Bâtiments (centrés sur l'emprise) ----------------------------------------

static func _slab(r: Node3D, w: float, d: float, acc: Color) -> void:
	_box(r, Vector3(w - 4, 3, d - 4), Vector3(0, 1.5, 0), Color(0.3, 0.32, 0.38))
	_box(r, Vector3(w - 4, 0.6, 3), Vector3(0, 3.2, d / 2.0 - 5), acc, Vector3.ZERO, 0.8)
	_box(r, Vector3(w - 4, 0.6, 3), Vector3(0, 3.2, -d / 2.0 + 5), acc, Vector3.ZERO, 0.8)


static func _chantier(r: Node3D, acc: Color) -> void:
	_slab(r, 96, 96, acc)
	_box(r, Vector3(54, 14, 54), Vector3(0, 10, 0), METAL)
	_box(r, Vector3(46, 4, 46), Vector3(0, 19, 0), LIGHT)
	_cyl(r, 13, 16, 22, Vector3(0, 32, 0), LIGHT, 8)
	_cyl(r, 14, 14, 2.5, Vector3(0, 44, 0), acc, 8, Vector3.ZERO, 1.0)
	_cyl(r, 5, 5, 8, Vector3(0, 50, 0), DARK, 6)
	_ball(r, 3.0, Vector3(0, 56, 0), GLOW_BLUE, 2.5)
	_box(r, Vector3(46, 3, 5), Vector3(-6, 30, 26), METAL, Vector3(0, 0.3, 0))  # bras de grue
	for p in [Vector3(-38, 0, -38), Vector3(38, 0, -38), Vector3(-38, 0, 38), Vector3(38, 0, 38)]:
		_cyl(r, 3, 4, 14, p + Vector3(0, 9, 0), METAL, 6)
		_ball(r, 2.4, p + Vector3(0, 17, 0), acc.lightened(0.3), 1.8)


static func _centrale(r: Node3D, acc: Color) -> void:
	_slab(r, 64, 64, acc)
	for x in [-15.0, 15.0]:
		_cyl(r, 11, 12, 20, Vector3(x, 13, -2), METAL, 8)
		_cyl(r, 6, 6, 22, Vector3(x, 14, -2), GLOW_BLUE, 8, Vector3.ZERO, 1.6)
		_cyl(r, 12.5, 12.5, 2.0, Vector3(x, 24, -2), acc, 8)
	_box(r, Vector3(40, 5, 8), Vector3(0, 7, 20), DARK)
	_box(r, Vector3(30, 1.0, 4), Vector3(0, 9.8, 20), acc, Vector3.ZERO, 1.2)
	_cyl(r, 1.8, 1.8, 30, Vector3(0, 12, -2), DARK, 6, Vector3(0, 0, PI / 2.0))


static func _raffinerie(r: Node3D, acc: Color) -> void:
	_slab(r, 96, 64, acc)
	_cyl(r, 15, 16, 24, Vector3(-26, 15, -4), LIGHT, 8)
	_cyl(r, 0.5, 15.5, 8, Vector3(-26, 31, -4), METAL, 8)
	_cyl(r, 16.5, 16.5, 2.0, Vector3(-26, 18, -4), acc, 8)
	_box(r, Vector3(34, 15, 30), Vector3(18, 10.5, -4), METAL)
	_box(r, Vector3(26, 1.5, 22), Vector3(18, 18.5, -4), GLOW_ORANGE, Vector3.ZERO, 1.3)
	_cyl(r, 3, 3, 40, Vector3(-4, 16, 6), DARK, 6, Vector3(0, 0, PI / 2.0))
	_box(r, Vector3(26, 2, 14), Vector3(-20, 3.5, 22), Color(0.2, 0.2, 0.24)) # quai
	for i in 4:
		_box(r, Vector3(3, 0.5, 14), Vector3(-30 + i * 6.0, 4.8, 22), acc, Vector3.ZERO, 0.7)


static func _fonderie(r: Node3D, acc: Color) -> void:
	_slab(r, 96, 64, acc)
	_box(r, Vector3(50, 18, 42), Vector3(-14, 12, -3), Color(0.24, 0.26, 0.32))
	_box(r, Vector3(50, 3, 42), Vector3(-14, 22.5, -3), METAL)
	for x in [16.0, 30.0]:
		_cyl(r, 4, 5.5, 34, Vector3(x, 20, -14), METAL, 6)
		_cyl(r, 4.5, 4.5, 2.0, Vector3(x, 37, -14), GLOW_ORANGE, 6, Vector3.ZERO, 1.8)
	_box(r, Vector3(30, 5, 3), Vector3(-14, 11, 19), GLOW_ORANGE, Vector3.ZERO, 2.2) # gueulard
	_box(r, Vector3(20, 3, 12), Vector3(26, 5, 14), DARK)
	_box(r, Vector3(18, 1.0, 6), Vector3(26, 7, 14), GLOW_BLUE, Vector3.ZERO, 1.2)


static func _usine(r: Node3D, acc: Color) -> void:
	_slab(r, 96, 64, acc)
	_box(r, Vector3(84, 15, 46), Vector3(0, 10.5, -4), Color(0.34, 0.36, 0.44))
	for i in 6:
		_box(r, Vector3(5, 2.5, 48), Vector3(-34 + i * 13.5, 19.5, -4), METAL)
	_box(r, Vector3(30, 11, 3), Vector3(-14, 8.5, 20), DARK)       # grande porte
	_box(r, Vector3(30, 1.2, 3.5), Vector3(-14, 14.8, 20), acc, Vector3.ZERO, 1.2)
	_cyl(r, 4, 5, 24, Vector3(32, 24, -18), METAL, 6)
	_cyl(r, 4.5, 4.5, 1.6, Vector3(32, 36.6, -18), GLOW_ORANGE, 6, Vector3.ZERO, 1.2)
	_box(r, Vector3(14, 6, 10), Vector3(30, 20, 8), METAL)


static func _tourelle_base(r: Node3D, acc: Color) -> void:
	_cyl(r, 27, 29, 4, Vector3(0, 2, 0), Color(0.3, 0.32, 0.38), 8)
	_cyl(r, 20, 22, 6, Vector3(0, 7, 0), METAL, 8)
	_cyl(r, 23, 23, 1.4, Vector3(0, 6.2, 0), acc, 8, Vector3.ZERO, 1.0)
	for a in 4:
		var d := Vector3.RIGHT.rotated(Vector3.UP, a * PI / 2.0 + PI / 4.0) * 24.0
		_box(r, Vector3(7, 5, 7), d + Vector3(0, 5, 0), DARK, Vector3(0, -a * PI / 2.0 - PI / 4.0, 0))


## Tête de la tourelle (tourne avec la visée).
static func _tourelle_tete(r: Node3D, acc: Color) -> void:
	_cyl(r, 13, 15, 8, Vector3(0, 15, 0), LIGHT, 8)
	_box(r, Vector3(14, 6, 18), Vector3(-2, 21, 0), acc.darkened(0.2))
	for z in [-4.0, 4.0]:
		_barrel(r, 8, 22, z, 22, 1.8)
	_ball(r, 3.0, Vector3(-4, 26, 0), GLOW_ORANGE, 2.0)


# --- Bâtiments débloqués par la campagne ---------------------------------------

static func _mur(r: Node3D, acc: Color, steel: bool) -> void:
	var col := Color(0.5, 0.52, 0.6) if steel else Color(0.46, 0.4, 0.34)
	_box(r, Vector3(30, 14 if steel else 11, 30), Vector3(0, 7, 0), col)
	_box(r, Vector3(32, 2, 32), Vector3(0, 15 if steel else 12, 0), METAL)
	_box(r, Vector3(32, 1.0, 4), Vector3(0, 6, 15), acc, Vector3.ZERO, 0.8)


static func _silo(r: Node3D, acc: Color) -> void:
	_slab(r, 64, 64, acc)
	for x in [-14.0, 14.0]:
		_cyl(r, 11, 11, 26, Vector3(x, 16, 0), LIGHT, 8)
		_cyl(r, 1.0, 11.5, 7, Vector3(x, 33, 0), METAL, 8)
		_cyl(r, 11.5, 11.5, 1.6, Vector3(x, 20, 0), acc, 8, Vector3.ZERO, 0.9)
	_box(r, Vector3(14, 4, 30), Vector3(0, 6, 0), DARK)


static func _radar(r: Node3D, acc: Color) -> void:
	_slab(r, 64, 64, acc)
	_box(r, Vector3(26, 12, 26), Vector3(0, 9, 0), METAL)
	_cyl(r, 3, 4, 16, Vector3(0, 22, 0), DARK, 6)
	_cyl(r, 20, 4, 3, Vector3(0, 34, 0), LIGHT, 10, Vector3(0.5, 0.0, 0.0))
	_ball(r, 2.6, Vector3(0, 38, 7), GLOW_GREEN, 2.5)


static func _reparation(r: Node3D, acc: Color) -> void:
	_slab(r, 96, 64, acc)
	for x in [-34.0, 34.0]:
		_box(r, Vector3(8, 26, 8), Vector3(x, 15, 0), METAL)
	_box(r, Vector3(76, 6, 10), Vector3(0, 30, 0), LIGHT)
	_box(r, Vector3(70, 1.2, 4), Vector3(0, 33.2, 0), GLOW_GREEN, Vector3.ZERO, 1.6)
	_box(r, Vector3(60, 2, 36), Vector3(0, 4, 4), Color(0.2, 0.22, 0.26))
	_box(r, Vector3(14, 8, 6), Vector3(0, 22, -3), acc.darkened(0.2))


static func _reacteur(r: Node3D, acc: Color) -> void:
	_slab(r, 64, 64, acc)
	_cyl(r, 20, 22, 20, Vector3(0, 13, 0), METAL, 10)
	_cyl(r, 14, 14, 26, Vector3(0, 17, 0), GLOW_BLUE, 10, Vector3.ZERO, 1.8)
	_cyl(r, 21, 21, 2.0, Vector3(0, 24, 0), acc, 10, Vector3.ZERO, 1.0)
	_cyl(r, 6, 8, 8, Vector3(0, 33, 0), DARK, 8)
	for a in 4:
		var d := Vector3.RIGHT.rotated(Vector3.UP, a * PI / 2.0) * 25.0
		_cyl(r, 2, 2.5, 18, d + Vector3(0, 11, 0), DARK, 6)


static func _relais(r: Node3D, acc: Color) -> void:
	_slab(r, 64, 64, acc)
	_cyl(r, 3, 4, 20, Vector3(0, 12, 0), METAL, 6)
	_box(r, Vector3(42, 2, 30), Vector3(0, 28, 0), Color(0.12, 0.2, 0.45), Vector3(0.45, 0, 0), 0.9)
	_box(r, Vector3(44, 1.4, 2), Vector3(0, 29, 0), acc, Vector3(0.45, 0, 0), 1.0)
	_ball(r, 3.0, Vector3(0, 36, 0), GLOW_ORANGE, 2.2)


static func _marche(r: Node3D, acc: Color) -> void:
	_slab(r, 96, 64, acc)
	_box(r, Vector3(70, 14, 40), Vector3(0, 10, -4), Color(0.28, 0.24, 0.3))
	_box(r, Vector3(76, 3, 46), Vector3(0, 18.5, -4), acc.darkened(0.2))
	for x in [-24.0, 0.0, 24.0]:
		_box(r, Vector3(14, 8, 3), Vector3(x, 9, 17), DARK)
		_box(r, Vector3(14, 1.2, 3.5), Vector3(x, 14, 17), GLOW_MAGENTA, Vector3.ZERO, 1.4)
	_ball(r, 3.0, Vector3(0, 24, -4), GLOW_MAGENTA, 2.0)


static func _tour_base(r: Node3D, acc: Color, id: String) -> void:
	_slab(r, 64, 64, acc)
	if id == "bunker":
		_box(r, Vector3(50, 16, 50), Vector3(0, 11, 0), Color(0.36, 0.37, 0.42))
		_box(r, Vector3(54, 3, 54), Vector3(0, 20, 0), METAL)
		return
	_cyl(r, 20, 23, 8, Vector3(0, 7, 0), METAL, 8)
	_cyl(r, 24, 24, 1.4, Vector3(0, 9, 0), acc, 8, Vector3.ZERO, 1.0)
	for a in 4:
		var d := Vector3.RIGHT.rotated(Vector3.UP, a * PI / 2.0 + PI / 4.0) * 26.0
		_box(r, Vector3(7, 6, 7), d + Vector3(0, 6, 0), DARK)


static func _tour_head_y(id: String) -> float:
	return 22.0 if id == "bunker_tete" else 12.0


static func _tour_tete(r: Node3D, acc: Color, id: String) -> void:
	var y := _tour_head_y(id)
	match id:
		"batterie_tete":
			_box(r, Vector3(26, 8, 26), Vector3(0, y + 4, 0), LIGHT)
			for z in [-7.0, 0.0, 7.0]:
				for yy in [0.0, 8.0]:
					_barrel(r, 10, y + 6 + yy, z, 26, 2.2, DARK)
			_ball(r, 3.0, Vector3(-8, y + 12, 0), GLOW_ORANGE, 2.0)
		"tour_sonique_tete":
			_cyl(r, 8, 11, 22, Vector3(0, y + 11, 0), LIGHT, 8)
			_cyl(r, 16, 5, 10, Vector3(8, y + 22, 0), acc, 10, Vector3(0, 0, -PI / 2.0 + 0.3), 0.8)
			_ball(r, 4.0, Vector3(14, y + 22, 0), GLOW_BLUE, 2.8)
		"bunker_tete":
			_box(r, Vector3(26, 10, 26), Vector3(0, y + 5, 0), acc.darkened(0.2))
			_barrel(r, 12, y + 6, 0, 30, 3.2, DARK)
			_ball(r, 3.0, Vector3(-6, y + 12, 0), GLOW_ORANGE, 2.0)
		_:
			_cyl(r, 11, 13, 10, Vector3(0, y + 5, 0), LIGHT, 8)
			_barrel(r, 8, y + 8, 0, 26, 2.8, DARK)
			_cyl(r, 5, 5, 6, Vector3(10, y + 10, 0), GLOW_GREEN, 6, Vector3.ZERO, 1.8)


# --- Unités volantes -----------------------------------------------------------

static func _fighter(r: Node3D, body: Color, hi: Color, acc: Color, v: int) -> void:
	var l := 30.0 if v != 2 else 34.0
	_box(r, Vector3(l, 5, 7), Vector3(0, 12, 0), body)
	_box(r, Vector3(10, 4, 6), Vector3(l / 2.0 - 2, 11.5, 0), hi, Vector3(0, 0, -0.35))     # nez
	_box(r, Vector3(8, 3.5, 5), Vector3(2, 15, 0), METAL)                                   # cockpit
	_box(r, Vector3(1, 2.5, 4), Vector3(6, 15.2, 0), GLOW_BLUE, Vector3.ZERO, 1.4)
	if v == 1:
		_cyl(r, 11, 11, 1.6, Vector3(-3, 13, 0), acc, 10, Vector3.ZERO, 0.9)                 # anneau sonique
		_box(r, Vector3(10, 1.4, 32), Vector3(-3, 12, 0), hi)
	else:
		_box(r, Vector3(9, 1.4, 38 if v == 0 else 30), Vector3(-3, 12, 0), hi, Vector3(0, -0.0, 0))
		_box(r, Vector3(5, 1.2, 16), Vector3(-l / 2.0 + 2, 12.5, 0), body)
	_box(r, Vector3(7, 7, 1.2), Vector3(-l / 2.0 + 2, 15, 0), acc, Vector3.ZERO, 0.6)       # dérive
	_box(r, Vector3(3, 3, 3.5), Vector3(-l / 2.0 - 1, 12, 0), GLOW_ORANGE, Vector3.ZERO, 2.2) # réacteur
	_barrel(r, l / 2.0 - 2, 10, 5, 8, 0.9)
	_barrel(r, l / 2.0 - 2, 10, -5, 8, 0.9)


static func _copter(r: Node3D, body: Color, hi: Color, acc: Color) -> void:
	_box(r, Vector3(24, 9, 11), Vector3(0, 12, 0), body)
	_box(r, Vector3(9, 6, 9), Vector3(11, 12, 0), hi, Vector3(0, 0, -0.3))
	_box(r, Vector3(7, 4, 7), Vector3(10, 16, 0), GLOW_BLUE, Vector3.ZERO, 0.8)
	_box(r, Vector3(26, 2.4, 2.6), Vector3(-22, 13, 0), METAL)                              # queue
	_box(r, Vector3(1.5, 8, 5), Vector3(-34, 16, 0), acc, Vector3.ZERO, 0.6)
	_cyl(r, 1.6, 1.6, 4, Vector3(-1, 19, 0), DARK, 6)
	for a in 2:
		_box(r, Vector3(46, 0.7, 2.4), Vector3(-1, 21.5, 0), LIGHT, Vector3(0, a * PI / 2.0 + 0.5, 0))
	for s in [-1.0, 1.0]:
		_box(r, Vector3(10, 3, 3), Vector3(2, 9, 9 * s), DARK)                              # nacelles roquettes
		_cyl(r, 1.2, 1.2, 9, Vector3(8, 9, 9 * s), METAL, 6, Vector3(0, 0, PI / 2.0))


static func _bomber(r: Node3D, body: Color, hi: Color, acc: Color, acid: bool) -> void:
	_box(r, Vector3(32, 7, 12), Vector3(0, 12, 0), body)
	_box(r, Vector3(10, 5, 10), Vector3(17, 11, 0), hi, Vector3(0, 0, -0.3))
	_box(r, Vector3(8, 4, 7), Vector3(5, 16.5, 0), METAL)
	_box(r, Vector3(14, 1.6, 52), Vector3(-2, 12, 0), hi)                                   # ailes
	_box(r, Vector3(8, 1.4, 22), Vector3(-15, 12.5, 0), body)
	_box(r, Vector3(7, 8, 1.4), Vector3(-15, 17, 0), acc, Vector3.ZERO, 0.6)
	var glow := GLOW_GREEN if acid else GLOW_ORANGE
	for z in [-9.0, 9.0]:
		_cyl(r, 3.4, 3.4, 12, Vector3(-4, 9, z), DARK, 8, Vector3(0, 0, PI / 2.0))
		_ball(r, 2.4, Vector3(-11, 9, z), glow, 2.0)
	_box(r, Vector3(12, 3, 7), Vector3(0, 7.5, 0), DARK)                                    # soute
	_ball(r, 2.6, Vector3(3, 7, 0), glow, 1.8)


static func _carrier(r: Node3D, body: Color, hi: Color, acc: Color, k: float) -> void:
	_box(r, Vector3(38 * k, 10 * k, 15 * k), Vector3(0, 12, 0), body)
	_box(r, Vector3(10 * k, 7 * k, 12 * k), Vector3(21 * k, 12, 0), hi, Vector3(0, 0, -0.35))
	_box(r, Vector3(6, 3.5, 9 * k), Vector3(16 * k, 16 * k + 1, 0), GLOW_BLUE, Vector3.ZERO, 0.8)
	_box(r, Vector3(30 * k, 2.2, 7 * k), Vector3(-2, 17 * k + 2, 0), METAL)                  # soute dessus
	_box(r, Vector3(14 * k, 1.5, 44 * k), Vector3(1, 12, 0), hi)                           # ailes
	for z in [-1.0, 1.0]:
		_cyl(r, 5 * k, 5 * k, 3, Vector3(2, 14, 22 * k * z), DARK, 10)                      # rotors
		_cyl(r, 8 * k, 8 * k, 0.6, Vector3(2, 16, 22 * k * z), LIGHT, 10)
	_box(r, Vector3(1.4, 7, 7), Vector3(-19 * k, 17, 0), acc, Vector3.ZERO, 0.6)
	_box(r, Vector3(24 * k, 1.0, 1.2), Vector3(-4, 7, 7 * k), acc, Vector3.ZERO, 0.8)


static func _aerodrome(r: Node3D, acc: Color) -> void:
	_slab(r, 96, 64, acc)
	_box(r, Vector3(42, 16, 30), Vector3(-22, 11, -6), Color(0.34, 0.36, 0.44))              # hangar
	_box(r, Vector3(44, 3, 32), Vector3(-22, 20.5, -6), METAL, Vector3(0, 0, 0.0))
	_box(r, Vector3(30, 9, 3), Vector3(-22, 7.5, 10), DARK)
	_box(r, Vector3(30, 1.2, 3.5), Vector3(-22, 12.5, 10), acc, Vector3.ZERO, 1.2)
	_cyl(r, 17, 17, 1.2, Vector3(24, 4, 8), Color(0.22, 0.24, 0.3), 12)                      # piste
	_cyl(r, 11, 11, 0.8, Vector3(24, 5, 8), acc, 12, Vector3.ZERO, 0.9)
	_cyl(r, 7, 7, 0.8, Vector3(24, 5.6, 8), DARK, 12)
	_cyl(r, 1.5, 1.5, 26, Vector3(30, 16, -18), DARK, 6)
	_ball(r, 3, Vector3(30, 30, -18), GLOW_ORANGE, 2.2)
