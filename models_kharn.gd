class_name ModelsKharn
## Légion Kharn : 18 bâtiments et 19 unités en modèles 3D importés (pack « Kharn_37_Batiments_Unites »).
## Convention du pack : Y vertical, avant du modèle = -Z, mètres. Bâtiments : 2 m par case (16 px/m), façade tournée vers
## le joueur (+Z). Unités : avant ramené sur +X, 12 px/m au sol, 10 px/m en l'air. Les tables ci-dessous sont relevées sur
## les nœuds TurretYaw / Muzzle / Rotor des fichiers glTF (outil tools/_dump_kharn.gd), déjà converties dans le repère du jeu.
## Les têtes de tourelle (TurretYaw) sont cuites à part pour pouvoir tourner indépendamment du reste.

const PX_BUILDING := 16.0
const PX_GROUND := 12.0
const PX_AIR := 10.0
const AIR_UNITS := ["aigle", "faucheur", "mule", "forteresse_vol"]

const BUILDINGS := {"chantier": "forteresse_de_commandement", "centrale": "chaudiere_de_guerre", "raffinerie": "raffinerie_lourde", "fonderie": "haut_fourneau", "usine": "arsenal", "tourelle": "casemate", "silo": "silo_blinde", "silo_minerai": "soute_a_minerai", "radar": "poste_d_ecoute", "reparation": "garage_de_campagne", "reacteur": "reacteur_lourd", "batterie": "batterie_de_roquettes", "aerodrome": "piste_de_guerre", "bunker": "bunker", "batterie_mortiers": "batterie_de_mortiers", "fonderie_lourde": "fonderie_lourde", "marteau_guerre": "marteau_de_guerre"}

const UNITS := {"recolteur": "recolteur_blinde", "mineur": "mineur_lourd", "mcv": "engin_de_siege", "rodeur": "rodeur", "belier": "belier", "demolisseur": "demolisseur", "brasier": "brasier", "depanneuse": "depanneuse", "salve": "salve", "cogneur": "cogneur", "gladiateur": "gladiateur", "brute": "brute", "obusier": "obusier", "titan": "titan", "mastodonte": "mastodonte", "aigle": "aigle", "faucheur": "faucheur", "mule": "mule", "forteresse_vol": "forteresse_volante"}

const KIND := {"recolteur": "tracks", "mineur": "tracks", "mcv": "tracks", "rodeur": "wheels", "belier": "wheels", "demolisseur": "tracks", "brasier": "tracks", "depanneuse": "tracks", "salve": "tracks", "brute": "tracks", "obusier": "tracks", "titan": "tracks"}

## Pivot de tourelle des unités (repère du jeu : avant +X, 1 unité = 1 px)
const PIVOTS := {
	"mcv": Vector3(0, 13.44, 0),
	"rodeur": Vector3(0, 12, 0),
	"belier": Vector3(0, 12, 0),
	"demolisseur": Vector3(0, 15, 0),
	"brasier": Vector3(0, 14.16, 0),
	"salve": Vector3(0, 14.04, 0),
	"gladiateur": Vector3(3.48, 17.76, 10.32),
	"brute": Vector3(0, 15, 0),
	"obusier": Vector3(0, 14.76, 0),
	"titan": Vector3(0, 16.68, 0),
	"mastodonte": Vector3(0, 28.68, 0),
	"aigle": Vector3(4, 6.9, 0),
	"forteresse_vol": Vector3(4, 6.9, 0),
}

## Bouches de tir des unités, tourelle au repos (repère du jeu)
const MUZZLES := {
	"mcv": [Vector3(21.36, 15.36, 0)],
	"rodeur": [Vector3(12, 12.96, 0)],
	"belier": [Vector3(12, 12.96, 0)],
	"demolisseur": [Vector3(14.04, 18.24, 0)],
	"brasier": [Vector3(15.36, 15.36, 0)],
	"salve": [Vector3(11.76, 17.04, 0)],
	"gladiateur": [Vector3(15.36, 17.76, 10.32)],
	"brute": [Vector3(20.88, 18.6, 0)],
	"obusier": [Vector3(19.72, 28.07, 0)],
	"titan": [Vector3(24.24, 21.12, -4.8), Vector3(24.24, 21.12, 4.8)],
	"mastodonte": [Vector3(11.76, 31.68, -6.6), Vector3(11.76, 31.68, 6.6)],
	"aigle": [Vector3(11, 6.9, 0)],
	"faucheur": [Vector3(9.5, 8.9, -8.2), Vector3(9.5, 8.9, 8.2)],
	"forteresse_vol": [Vector3(11, 6.9, 0)],
}

## Bouches de tir des têtes de tourelle des bâtiments (x avant, y hauteur, z côté ; axe de la tourelle à l'origine)
const HEAD_MUZZLES := {
	"tourelle_tete": [Vector3(25.92, 24.8, 0)],
	"batterie_tete": [Vector3(17.6, 22.88, -8.8), Vector3(17.6, 22.88, 8.8)],
	"bunker_tete": [Vector3(19.52, 27.68, 0)],
	"batterie_mortiers_tete": [Vector3(23.1, 33.04, -7.52), Vector3(23.1, 33.04, 7.52)],
	"marteau_guerre_tete": [Vector3(34.48, 41.12, 0)],
}

## Rotors du Faucheur (dessinés par l'unité)
const ROTORS := {"faucheur": [{"hub": Vector3(-1, 16.5, 0), "r": 20.2, "n": 2, "w": 34.0, "h": true}, {"hub": Vector3(-19.1, 12.9, 0), "r": 4.6, "n": 2, "w": 48.0, "h": false}]}
## Pistes de dépôt (mesurées sur les modèles, en px depuis le centre du bâtiment ; voir RAMPS_SOLIS dans models.gd).
## x : centre de la piste, nose : z du bord où le nez du véhicule s'arrête (la façade / la trémie), z0 : z du centre d'un
## véhicule qui attend devant la façade, w : largeur de la piste. "pc" : z du centre du véhicule à l'arrêt (réparation).
## Les pistes sont plus courtes qu'un véhicule : il s'y insère par l'avant, le reste du châssis dépasse devant le bâtiment.
const RAMPS := {
	"raffinerie": {"x": 16.4, "nose": 15.6, "z0": 46.0, "w": 22.7},
	"fonderie": {"x": 13.6, "nose": 10.0, "z0": 46.0, "w": 17.8},
	"reparation": {"x": 0.0, "nose": 0.0, "pc": 8.0, "z0": 46.0, "w": 19.0},
}

## Portes de production (les unités en sortent) ; "pad" : piste d'envol des appareils.
const DOORS := {
	"usine": {"x": 0.0, "z": 19.0, "y": 8.0, "w": 40.0},
	"aerodrome": {"pad": Vector3(0, 5, 10)},
}


static var _scenes := {}
static var _yaw_re: RegEx


static func _path(stem: String) -> String:
	return "res://assets/kharn/models/kharn_%s.gltf" % stem


## Vrai si ce bâtiment (ou sa tête `<id>_tete`) est un modèle importé de la Légion Kharn.
static func has_building(id: String) -> bool:
	var base := id.trim_suffix("_tete")
	return BUILDINGS.has(base) and ResourceLoader.exists(_path(BUILDINGS[base]))


static func has_unit(id: String) -> bool:
	var base := id.trim_suffix("_tete")
	return UNITS.has(base) and ResourceLoader.exists(_path(UNITS[base]))


static func _scene(stem: String) -> PackedScene:
	var ps: PackedScene = _scenes.get(stem)
	if ps == null:
		ps = load(_path(stem))
		_scenes[stem] = ps
	return ps


## Premier nœud « TurretYaw » (TurretYaw, TurretYaw_004 ... mais pas leurs _Geometry).
static func _yaw(inst: Node3D) -> Node3D:
	if _yaw_re == null:
		_yaw_re = RegEx.create_from_string("^TurretYaw(_\\d+)?$")
	for n in inst.find_children("TurretYaw*", "Node3D", true, false):
		if _yaw_re.search(String(n.name)) != null:
			return n as Node3D
	return null


## Construit le modèle importé de `id` dans `r`. Faux si `id` n'est pas un modèle Kharn.
static func build(r: Node3D, id: String) -> bool:
	if has_building(id):
		return _build_building(r, id)
	if has_unit(id):
		return _build_unit(r, id)
	return false


static func _build_building(r: Node3D, id: String) -> bool:
	var head := id.ends_with("_tete")
	var base := id.trim_suffix("_tete")
	var inst := _scene(BUILDINGS[base]).instantiate() as Node3D
	var yaw := _yaw(inst)
	var g := Node3D.new()
	if head:
		if yaw == null:
			inst.free()
			g.free()
			return false
		g.transform = Transform3D(Basis(Vector3.UP, -PI / 2.0).scaled(Vector3.ONE * PX_BUILDING), Vector3.ZERO)
		Models._only_branch(inst, yaw)
		var piv := Models._xf_in(inst, yaw).origin
		g.position = -(g.transform.basis * Vector3(piv.x, 0.0, piv.z))
	else:
		g.transform = Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * PX_BUILDING), Vector3.ZERO)
		if yaw != null:
			yaw.visible = false
	g.add_child(inst)
	r.add_child(g)
	return true


static func _px(id: String) -> float:
	return PX_AIR if AIR_UNITS.has(id) else PX_GROUND


## Instance d'une unité mise au repère du jeu. `turret_only` : on ne garde que la tourelle, son axe ramené sur l'origine.
static func _unit_instance(id: String, turret_only: bool) -> Node3D:
	var g := Node3D.new()
	g.transform = Transform3D(Basis(Vector3.UP, -PI / 2.0).scaled(Vector3.ONE * _px(id)), Vector3.ZERO)
	var inst := _scene(UNITS[id]).instantiate() as Node3D
	g.add_child(inst)
	var yaw := _yaw(inst)
	if turret_only:
		Models._only_branch(inst, yaw)
		g.position = -PIVOTS[id]
	else:
		if yaw != null:
			yaw.visible = false
		# les rotors sont dessinés par l'unité (animés) : on les retire du sprite
		for n in inst.find_children("*Rotor*", "Node3D", true, false):
			(n as Node3D).visible = false
		if Models.walk_phase >= 0.0:
			_pose_legs(inst, Models.walk_phase)
	return g


static func _build_unit(r: Node3D, id: String) -> bool:
	var kind: String = KIND.get(id, "")
	if kind != "":
		Models._seen[kind] = true
	r.add_child(_unit_instance(id, false))
	if PIVOTS.has(id):
		var t := Models._tur(r, PIVOTS[id])
		t.add_child(_unit_instance(id, true))
	return true


## Cycle de marche des mechas : hanches, genoux et pieds sont des pivots rigides (rotation autour de l'axe latéral X).
## Bipède : jambe gauche et droite en opposition ; quadrupède : paires diagonales.
static func _pose_legs(inst: Node3D, phase: float) -> void:
	var a := phase * TAU
	for n in inst.find_children("Hip_*", "Node3D", true, false):
		var nm := String(n.name)
		if nm.ends_with("_Geometry"):
			continue
		var left := nm.begins_with("Hip_L")
		var row := 1 if nm.substr(5, 1) == "1" else 0
		var opp := (0 if left else 1) + row
		var ph := a + (PI if opp % 2 == 1 else 0.0)
		var hip := (n as Node3D)
		hip.rotation.x = 0.5 * sin(ph)
		var knee := hip.find_child("Knee_*", false, false) as Node3D
		var knee_r := 0.0
		if knee != null:
			knee_r = 0.7 * maxf(0.0, -cos(ph))
			knee.rotation.x = -knee_r
			var foot := knee.find_child("Foot_*", false, false) as Node3D
			if foot != null:
				foot.rotation.x = -(hip.rotation.x - knee_r)
