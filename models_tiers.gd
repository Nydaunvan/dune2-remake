class_name ModelsTiers
## Paliers d'évolution visuels des bâtiments : le niveau 2 ajoute des modules (cuves, blindages, mâts, portiques),
## le niveau 3 une version « élite » plus haute, avec lueurs. Ajouts posés autour du modèle de base (mêmes emprises).



static func apply(r: Node3D, id: String, acc: Color, lv: int) -> void:
	match id:
		"centrale": _centrale(r, acc, lv)
		"raffinerie": _raffinerie(r, acc, lv)
		"fonderie": _fonderie(r, acc, lv)
		"usine": _usine(r, acc, lv)
		"tourelle": _tourelle(r, acc, lv)
		"radar": _radar(r, acc, lv)
		"chantier": _chantier(r, acc, lv)
		"reparation": _reparation(r, acc, lv)


## Têtes cuites à part (tourelle) : blindage puis bobines.
static func head(r: Node3D, id: String, acc: Color, lv: int) -> void:
	if id != "tourelle_tete":
		return
	for z in [-9.0, 9.0]:
		Models._box(r, Vector3(14, 7, 3), Vector3(14, 22, z), Models.METAL)
	Models._box(r, Vector3(12, 2, 22), Vector3(-2, 25.5, 0), acc.darkened(0.1))
	if lv >= 3:
		for z in [-4.0, 4.0]:
			for x in [16.0, 24.0]:
				Models._cyl(r, 2.8, 2.8, 2.4, Vector3(x, 22, z), acc, 10, Vector3(0, 0, PI / 2.0), 1.8)
		Models._ball(r, 4.4, Vector3(-4, 28, 0), Models.GLOW_ORANGE, 3.0)
		Models._box(r, Vector3(6, 3, 6), Vector3(-10, 25, 0), Models.DARK)


## Anneau lumineux creux (segments) : les cylindres pleins masqueraient ce qu'ils entourent.
static func _ring(r: Node3D, c: Vector3, rad: float, col: Color, emit: float, n := 14) -> void:
	for i in n:
		var a := TAU * i / n
		Models._box(r, Vector3(rad * TAU / n * 0.8, 1.2, 1.6), c + Vector3(cos(a), 0, sin(a)) * rad, col, Vector3(0, -a + PI / 2.0, 0), emit)


static func _frame(r: Node3D, c: Vector3, w: float, d: float, col: Color, emit: float) -> void:
	for sz in [-1.0, 1.0]:
		Models._box(r, Vector3(w, 1.2, 1.6), c + Vector3(0, 0, sz * d / 2.0), col, Vector3.ZERO, emit)
	for sx in [-1.0, 1.0]:
		Models._box(r, Vector3(1.6, 1.2, d), c + Vector3(sx * w / 2.0, 0, 0), col, Vector3.ZERO, emit)


static func _corner_plates(r: Node3D, hx: float, hz: float, acc: Color) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Models._box(r, Vector3(9, 5, 9), Vector3(sx * hx, 5.5, sz * hz), Models.DARK)
			Models._box(r, Vector3(9.4, 0.8, 9.4), Vector3(sx * hx, 8.2, sz * hz), acc, Vector3.ZERO, 0.9)


static func _centrale(r: Node3D, acc: Color, lv: int) -> void:
	for x in [-26.0, 26.0]:
		Models._round(r, 5.5, 14, Vector3(x, 10, -22), Models.METAL)
		Models._round(r, 3.0, 16, Vector3(x, 11, -22), Models.GLOW_BLUE, Vector3.ZERO, 1.6)
	Models._box(r, Vector3(40, 6, 4), Vector3(0, 6, -27), Models.DARK)
	_corner_plates(r, 27.0, 27.0, acc)
	if lv >= 3:
		Models._cyl(r, 3, 3.5, 40, Vector3(0, 22, -24), Models.METAL, 10)
		Models._ball(r, 4.6, Vector3(0, 44, -24), Models.GLOW_BLUE, 3.0)
		for x in [-15.0, 15.0]:
			_ring(r, Vector3(x, 27, -2), 14.0, acc, 1.8)


static func _raffinerie(r: Node3D, acc: Color, lv: int) -> void:
	Models._round(r, 7, 18, Vector3(42, 12, -24), Models.LIGHT)
	Models._cyl(r, 7.6, 7.6, 1.6, Vector3(42, 14, -24), acc, 16, Vector3.ZERO, 1.0)
	for sx in [-1.0, 1.0]: # balises de la rampe
		Models._ball(r, 2.0, Vector3(-20.0 + sx * 14.0, 9.0, 33), Models.GLOW_ORANGE, 2.2)
	for x in [-33.0, -7.0]: # portique au-dessus de la trémie
		Models._box(r, Vector3(3, 22, 3), Vector3(x, 14, -6), Models.METAL)
	Models._box(r, Vector3(30, 3, 4), Vector3(-20, 25.5, -6), Models.LIGHT)
	_corner_plates(r, 40.0, -27.0, acc)
	if lv >= 3:
		Models._cyl(r, 2.4, 3.2, 46, Vector3(42, 23, -2), Models.METAL, 8)
		Models._ball(r, 4.5, Vector3(42, 48, -2), Models.GLOW_ORANGE, 3.0)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				Models._box(r, Vector3(2, 10, 2), Vector3(22.0 + sx * 14.0, 25, -8.0 + sz * 11.0), Models.METAL)
		_frame(r, Vector3(22, 30.5, -8), 30.0, 24.0, acc, 1.4)


static func _fonderie(r: Node3D, acc: Color, lv: int) -> void:
	Models._round(r, 4.6, 40, Vector3(32, 22, -20), Models.METAL)
	Models._cyl(r, 5.2, 5.2, 2.0, Vector3(32, 43, -20), Models.GLOW_ORANGE, 12, Vector3.ZERO, 1.8)
	for x in [14.0, 42.0]: # portique de la rampe
		Models._box(r, Vector3(3, 22, 3), Vector3(x, 14, 4), Models.METAL)
	Models._box(r, Vector3(32, 3, 4), Vector3(28, 25.5, 4), Models.LIGHT)
	_corner_plates(r, -40.0, 27.0, acc)
	if lv >= 3:
		Models._cyl(r, 12, 15, 22, Vector3(-18, 36, -8), Models.METAL, 20)
		_ring(r, Vector3(-18, 47.5, -8), 11.0, Models.GLOW_ORANGE, 2.0, 16)
		Models._box(r, Vector3(18, 1.2, 14), Vector3(-40, 3.6, 14), Models.GLOW_ORANGE, Vector3.ZERO, 1.8)


static func _usine(r: Node3D, acc: Color, lv: int) -> void:
	Models._box(r, Vector3(60, 8, 30), Vector3(0, 23, -4), Models.METAL)
	for i in 4:
		Models._box(r, Vector3(6, 3, 6), Vector3(-22 + i * 14.0, 28.5, -4), Models.DARK)
	for sx in [-1.0, 1.0]:
		Models._box(r, Vector3(12, 12, 14), Vector3(sx * 40.0, 9, 22), Models.METAL)
		Models._box(r, Vector3(12.4, 1.0, 14.4), Vector3(sx * 40.0, 15.4, 22), acc, Vector3.ZERO, 1.0)
	if lv >= 3:
		Models._box(r, Vector3(12, 32, 12), Vector3(-34, 30, -18), Models.LIGHT)
		Models._box(r, Vector3(12.6, 2, 12.6), Vector3(-34, 40, -18), acc, Vector3.ZERO, 1.4)
		Models._cyl(r, 1.2, 1.4, 20, Vector3(-34, 56, -18), Models.DARK, 6)
		Models._ball(r, 3.0, Vector3(-34, 67, -18), Models.GLOW_BLUE, 3.0)
		Models._box(r, Vector3(30, 11, 3), Vector3(26, 8.5, 20), Models.DARK)       # seconde porte
		Models._box(r, Vector3(30, 1.2, 3.5), Vector3(26, 14.8, 20), acc, Vector3.ZERO, 1.4)


static func _tourelle(r: Node3D, acc: Color, lv: int) -> void:
	Models._cyl(r, 31, 31, 2.0, Vector3(0, 3.5, 0), acc, 24, Vector3.ZERO, 1.0)
	for a in 4:
		var d := Vector3.RIGHT.rotated(Vector3.UP, a * PI / 2.0) * 28.0
		Models._box(r, Vector3(8, 9, 14), d + Vector3(0, 7, 0), Models.METAL, Vector3(0, -a * PI / 2.0, 0))
	if lv >= 3:
		for a in 4:
			var d := Vector3.RIGHT.rotated(Vector3.UP, a * PI / 2.0 + PI / 4.0) * 30.0
			Models._cyl(r, 2.2, 2.8, 20, d + Vector3(0, 12, 0), Models.METAL, 8)
			Models._ball(r, 3.0, d + Vector3(0, 24, 0), Models.GLOW_BLUE, 2.6)
		_ring(r, Vector3(0, 6.0, 0), 33.0, Models.GLOW_BLUE, 1.3, 24)


static func _radar(r: Node3D, acc: Color, lv: int) -> void:
	for x in [-24.0, 24.0]:
		Models._cyl(r, 1.4, 1.8, 26, Vector3(x, 16, -22), Models.DARK, 6)
		Models._ball(r, 2.2, Vector3(x, 30, -22), acc, 1.8)
	Models._box(r, Vector3(16, 8, 12), Vector3(0, 7, 22), Models.METAL)
	_corner_plates(r, 27.0, 27.0, acc)
	if lv >= 3:
		_ring(r, Vector3(0, 4, 0), 24.0, Models.GLOW_GREEN, 1.3, 20)
		Models._cyl(r, 2.0, 2.4, 40, Vector3(0, 22, 0), Models.DARK, 8)
		Models._cyl(r, 9, 9, 2.0, Vector3(0, 41, 0), acc, 14, Vector3.ZERO, 1.4)


static func _chantier(r: Node3D, acc: Color, lv: int) -> void:
	Models._box(r, Vector3(46, 3, 5), Vector3(6, 30, -26), Models.METAL, Vector3(0, -0.3, 0))
	for sx in [-1.0, 1.0]:
		Models._box(r, Vector3(14, 12, 30), Vector3(sx * 38.0, 9, 0), Models.METAL)
		Models._box(r, Vector3(14.4, 1.0, 30.4), Vector3(sx * 38.0, 15.4, 0), acc, Vector3.ZERO, 1.0)
	if lv >= 3:
		Models._cyl(r, 2.4, 3.0, 36, Vector3(0, 74, 0), Models.METAL, 8)
		Models._ball(r, 4.0, Vector3(0, 94, 0), Models.GLOW_BLUE, 3.0)
		_ring(r, Vector3(0, 50, 0), 21.0, acc, 1.5, 18)


static func _reparation(r: Node3D, acc: Color, lv: int) -> void:
	for sx in [-1.0, 1.0]:
		Models._box(r, Vector3(12, 10, 10), Vector3(sx * 40.0, 8, -22), Models.METAL)
		Models._box(r, Vector3(12.4, 1.0, 10.4), Vector3(sx * 40.0, 13.4, -22), acc, Vector3.ZERO, 1.0)
		Models._box(r, Vector3(2, 1.4, 26), Vector3(sx * 20.0, 5.0, 8.0), Models.METAL)
	if lv >= 3:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				Models._cyl(r, 1.8, 2.4, 18, Vector3(sx * 42.0, 12, sz * 10.0 + 6.0), Models.METAL, 8)
				Models._ball(r, 3.0, Vector3(sx * 42.0, 23, sz * 10.0 + 6.0), Models.GLOW_GREEN, 2.6)
		Models._box(r, Vector3(60, 1.0, 3), Vector3(0, 37.4, -6), Models.GLOW_GREEN, Vector3.ZERO, 1.8)
