class_name ModelsConclave
## Conclave Obsidien : 16 bâtiments et 19 unités en modèles 3D importés (pack « Conclave_Obsidien_36_Batiments_Unites »).
## Convention du pack : Y vertical, avant du modèle = -Z, mètres. Bâtiments : 2 m par case (16 px/m), façade tournée vers
## le joueur (+Z). Unités : avant ramené sur +X, 12 px/m au sol, 10 px/m en l'air. Les tables ci-dessous sont relevées sur
## les nœuds TurretYaw / Muzzle / Rotor des fichiers glTF (outil tools/_dump_kharn.gd PACK=conclave), déjà converties dans le repère du jeu.
## Les têtes de tourelle (TurretYaw) sont cuites à part pour pouvoir tourner indépendamment du reste.

const PX_BUILDING := 16.0
const PX_GROUND := 12.0
const PX_AIR := 10.0
const AIR_UNITS := ["scintille", "passeur", "eclipse", "aurore"]

const BUILDINGS := {"chantier": "noyau_cristallin", "centrale": "cuve_d_energie_vive", "raffinerie": "alambic_de_cristal", "fonderie": "creuset_d_obsidienne", "usine": "matrice_de_cristal", "tourelle": "sentinelle_de_cristal", "silo": "urne_d_epice", "silo_minerai": "geode_de_stockage", "radar": "il_de_cristal", "reparation": "bassin_de_regeneration", "reacteur": "cur_de_cristal", "batterie": "batterie_d_eclats", "aerodrome": "plateforme_d_envol", "tour_prisme": "tour_prisme", "serre": "serre_cristalline", "nova_cristal": "nova_de_cristal"}

const UNITS := {"recolteur": "collecteur_flottant", "mineur": "foreur_de_cristal", "mcv": "germe_de_base", "ombre": "ombre", "prisme": "prisme", "obelisque": "obelisque", "tesson": "tesson", "fracasseur": "fracasseur", "monolithe": "monolithe", "veilleur": "veilleur", "aiguille": "aiguille", "quartz": "quartz", "geode": "geode", "stele": "stele", "cariatide": "cariatide", "scintille": "scintille", "passeur": "passeur", "eclipse": "eclipse", "aurore": "aurore"}

const KIND := {"recolteur": "hover", "mineur": "hover", "mcv": "hover", "ombre": "hover", "prisme": "hover", "obelisque": "hover", "tesson": "hover", "fracasseur": "hover", "monolithe": "hover", "veilleur": "hover", "aiguille": "hover", "quartz": "hover"}

## Pivot de tourelle des unités (repère du jeu : avant +X, 1 unité = 1 px)
const PIVOTS := {
	"prisme": Vector3(0, 10.92, 0),
	"obelisque": Vector3(0, 10.08, 0),
	"tesson": Vector3(0, 10.08, 0),
	"fracasseur": Vector3(-2.52, 10.92, 0),
	"monolithe": Vector3(0, 11.52, 0),
	"aiguille": Vector3(0, 10.08, 0),
	"quartz": Vector3(0, 10.8, 0),
	"geode": Vector3(0, 24.84, 0),
	"scintille": Vector3(1.5, 8.8, 0),
	"eclipse": Vector3(1.5, 8.8, 0),
	"aurore": Vector3(0, 8.8, -7.8),
}

## Bouches de tir des unités, tourelle au repos (repère du jeu)
const MUZZLES := {
	"prisme": [Vector3(13.68, 12.72, 0)],
	"obelisque": [Vector3(16.26, 26.26, 0)],
	"tesson": [Vector3(10.32, 10.92, 0)],
	"fracasseur": [Vector3(13.68, 12.72, 0)],
	"monolithe": [Vector3(18.96, 15.36, 0)],
	"aiguille": [Vector3(15.05, 25.15, 0)],
	"quartz": [Vector3(7.62, 19.55, 0)],
	"geode": [Vector3(12.48, 26.16, 0)],
	"stele": [Vector3(12, 15.48, 9)],
	"cariatide": [Vector3(15.24, 18.72, 9)],
	"scintille": [Vector3(11.4, 8.9, 0)],
	"eclipse": [Vector3(11.4, 8.9, 0)],
	"aurore": [Vector3(12.1, 9, -7.8), Vector3(12.1, 9, 7.8)],
}

## Bouches de tir des têtes de tourelle des bâtiments (x avant, y hauteur, z côté ; axe de la tourelle à l'origine)
const HEAD_MUZZLES := {
	"tourelle_tete": [Vector3(23.04, 19.2, 0)],
	"batterie_tete": [Vector3(16.16, 19.68, 10.08), Vector3(24.9, 19.68, -5.04), Vector3(7.42, 19.68, -5.04)],
	"tour_prisme_tete": [Vector3(13.44, 32.48, 0)],
}

## Rotors du Faucheur (dessinés par l'unité)
const ROTORS := {"recolteur": [{"hub": Vector3(4.2, 9.24, 0), "r": 7.62, "n": 3, "w": 14.0, "h": true}], "veilleur": [{"hub": Vector3(-0.96, 12.72, 0), "r": 8.58, "n": 3, "w": 14.0, "h": true}]}
## Pistes de dépôt (mesurées sur les modèles, en px depuis le centre du bâtiment ; voir RAMPS_SOLIS dans models.gd).
## x : centre de la piste, nose : z du bord où le nez du véhicule s'arrête (la façade / la trémie), z0 : z du centre d'un
## véhicule qui attend devant la façade, w : largeur de la piste. "pc" : z du centre du véhicule à l'arrêt (réparation).
## Les pistes sont plus courtes qu'un véhicule : il s'y insère par l'avant, le reste du châssis dépasse devant le bâtiment.
const RAMPS := {
	"raffinerie": {"x": 24.0, "nose": 3.5, "z0": 46.0, "w": 19.0},
	"fonderie": {"x": 0.0, "nose": 5.8, "z0": 46.0, "w": 21.0},
	"reparation": {"x": 0.0, "nose": 0.0, "pc": 2.0, "z0": 46.0, "w": 24.0},
}

## Portes de production (les unités en sortent) ; "pad" : piste d'envol des appareils.
const DOORS := {
	"usine": {"x": 0.0, "z": 22.0, "y": 6.0, "w": 36.0},
	"aerodrome": {"pad": Vector3(0, 5, 0)},
}


static var _scenes := {}
static var _yaw_re: RegEx


static func _path(stem: String) -> String:
	return "res://assets/conclave/models/conclave_%s.gltf" % stem


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
		var row := int(nm.substr(5, 1))
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
