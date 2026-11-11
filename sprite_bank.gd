class_name SpriteBank
extends Node
## Cuit les modèles 3D (Models) en images 2D : pour chaque modèle, un rendu par
## angle (unités) ou un seul rendu (bâtiments), éclairé en Forward+ avec ombres.
## Projection « oblique » : caméra inclinée de TILT, puis image étirée de 1/cos(TILT)
## pour que l'emprise au sol reste alignée sur la grille tout en montrant les flancs.

const TILT := deg_to_rad(30.0)
const SS := 2.0           # pixels de texture par pixel du monde
const ANGLES := 16
const UNIT_FRAME := Vector2(104, 104)
const UNIT_EXTRA := 44.0
const BUILDING_MARGIN := 44.0
const BUILDING_EXTRA := 70.0

signal finished

var game
var ready_all := false
var total := 0
var done := 0
var _tex := {}   # clé -> Array[Texture2D]
var _size := {}  # clé -> taille de dessin dans le monde (Vector2)
var _vp: SubViewport
var _cam: Camera3D
var _holder: Node3D
var _jobs: Array = []


func setup(p_game, faction_ids: Array) -> void:
	game = p_game
	_make_viewport()
	for f in faction_ids:
		var accent: Color = GameData.FACTIONS[f]["color"]
		var ids: Array = ["recolteur", "mineur", "mcv", "convoi"] + GameData.FACTIONS[f]["units"] + GameData.FACTIONS[f]["air"]
		for id in ids:
			_jobs.append({"key": "%s|%s" % [id, f], "id": id, "accent": accent, "angles": ANGLES,
					"frame": UNIT_FRAME, "extra": UNIT_EXTRA})
		var bids: Array = ["chantier", "centrale", "raffinerie", "fonderie", "usine", "tourelle"]
		for id in GameData.buildings_for(f):
			if not bids.has(id):
				bids.append(id)
		for id in bids:
			var cs: Vector2i = GameData.def(id)["size"]
			var fr := Vector2(cs * 32) + Vector2(BUILDING_MARGIN, BUILDING_MARGIN)
			_jobs.append({"key": "%s|%s" % [id, f], "id": id, "accent": accent, "angles": 1,
					"frame": fr, "extra": BUILDING_EXTRA})
			if id != "tourelle" and GameData.def(id).has("weapon"):
				_jobs.append({"key": "%s_tete|%s" % [id, f], "id": "%s_tete" % id, "accent": accent,
						"angles": ANGLES, "frame": Vector2(96, 96), "extra": 60.0})
		_jobs.append({"key": "tourelle_tete|%s" % f, "id": "tourelle_tete", "accent": accent, "angles": ANGLES,
				"frame": Vector2(96, 96), "extra": 60.0})
	_bake_all()


func has(key: String) -> bool:
	return _tex.has(key)


func frame(key: String, angle := 0.0):
	var arr: Array = _tex.get(key, [])
	if arr.is_empty():
		return null
	if arr.size() == 1:
		return arr[0]
	var i := int(round(wrapf(angle, 0.0, TAU) / TAU * arr.size())) % arr.size()
	return arr[i]


func frame_index(key: String, angle: float) -> int:
	var arr: Array = _tex.get(key, [])
	if arr.size() <= 1:
		return 0
	return int(round(wrapf(angle, 0.0, TAU) / TAU * arr.size())) % arr.size()


func draw_size(key: String) -> Vector2:
	return _size.get(key, Vector2.ZERO)


func _make_viewport() -> void:
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vp.size = Vector2i(256, 256)
	add_child(_vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.72)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)

	# Soleil venant du haut-droite : les ombres tombent vers le bas-gauche, comme le terrain
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.35
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 700.0
	_vp.add_child(sun)
	sun.look_at_from_position(Vector3(120, 170, -70), Vector3.ZERO, Vector3.UP)

	_holder = Node3D.new()
	_vp.add_child(_holder)

	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_cam.near = 1.0
	_cam.far = 1500.0
	_vp.add_child(_cam)
	_cam.look_at_from_position(Vector3(0, cos(TILT), sin(TILT)) * 600.0, Vector3.ZERO, Vector3.UP)
	_cam.current = true


func _bake_all() -> void:
	for job in _jobs:
		total += int(job["angles"])
	for job in _jobs:
		await _bake(job)
		done += int(job["angles"])
	ready_all = true
	finished.emit()


func _bake(job: Dictionary) -> void:
	var frame_px: Vector2 = job["frame"]
	var view_h: float = frame_px.y * cos(TILT) + float(job["extra"])
	_vp.size = Vector2i(int(ceil(frame_px.x * SS)), int(ceil(view_h * SS)))
	_cam.size = view_h
	var model := Models.build(job["id"], job["accent"])
	_holder.add_child(model)
	var out: Array = []
	for i in int(job["angles"]):
		# Angle 2D (sens horaire à l'écran) -> rotation autour de Y : signe inversé
		model.rotation.y = -TAU * i / float(job["angles"])
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		out.append(ImageTexture.create_from_image(img))
	_holder.remove_child(model)
	model.queue_free()
	_tex[job["key"]] = out
	_size[job["key"]] = Vector2(frame_px.x, view_h / cos(TILT))
