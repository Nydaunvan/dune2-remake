class_name SpriteBank
extends Node
## Cuit les modèles 3D (Models) en images 2D : pour chaque modèle, un rendu par
## angle (unités) ou un seul rendu (bâtiments), éclairé en Forward+ avec ombres.
## Projection « oblique » : caméra inclinée de TILT, puis image étirée de 1/cos(TILT)
## pour que l'emprise au sol reste alignée sur la grille tout en montrant les flancs.

const TILT := deg_to_rad(30.0)
var ss := 2.0             # pixels de texture par pixel du monde : bâtiments et par défaut
var ss_unit := 2.0        # véhicules et tourelles (2 = standard ; 4 = ultra HD)
var ss_mech := 2.0        # mécas (9 jeux d'images chacun) : un peu moins, pour la mémoire (2 = standard ; 3 = HD)
var ss_building := 2.0    # bâtiments (3 = HD)
var hd_units := false     # coques HD (shader de tôle, détails de surface) pour les véhicules et leurs tourelles
const ANGLES := 16
const UNIT_FRAME := Vector2(104, 104)
const UNIT_EXTRA := 44.0
## Bâtiments à paliers visuels (niveaux 2 et 3 cuits à part).
const TIERED := ["chantier", "centrale", "raffinerie", "fonderie", "usine", "tourelle", "radar", "reparation"]
const BUILDING_MARGIN := 44.0
const BUILDING_EXTRA := 70.0

signal finished
signal core_ready      # le nécessaire pour démarrer (camp du joueur) est cuit : la partie peut commencer
signal batch_done      # un lot de modèles vient d'être terminé : les dessins peuvent être rafraîchis

var game
var ready_all := false
var core_ok := false      # vrai dès que les modèles indispensables au départ sont prêts
var core_total := 0
var core_done := 0
const LANES := 4          # viseurs de cuisson en parallèle pendant le chargement
const CORE_UNITS := ["mcv", "recolteur", "mineur", "convoi"]
const CORE_BUILDINGS := ["chantier", "centrale", "raffinerie", "fonderie", "usine", "tourelle"]
var total := 0
var done := 0
var _tex := {}   # clé -> Array[Texture2D]
var _used := {}  # clé -> Array[Rect2] zone opaque de chaque image
var _size := {}  # clé -> taille de dessin dans le monde (Vector2)
var _off := {}   # clé -> Array[Vector2] : position (pixels de texture) de l'image rognée dans l'image complète
var _full := {}  # clé -> taille (pixels) de l'image complète, avant rognage
var _vp: SubViewport
var _cam: Camera3D
var _holder: Node3D
var _jobs: Array = []
var _fac_order: Array = []
var _lanes: Array = []      # {vp, cam, holder} : chaque voie cuit ses images indépendamment
var _next_job := 0
var _active := 0


func setup(p_game, faction_ids: Array) -> void:
	game = p_game
	_fac_order = faction_ids.duplicate()
	_make_viewport()
	for f in faction_ids:
		var first: bool = faction_ids.find(f) == 0 # le camp du joueur est cuit en premier
		var accent: Color = GameData.FACTIONS[f]["color"]
		var ids: Array = ["recolteur", "mineur", "mcv", "convoi"] + GameData.FACTIONS[f]["units"] + GameData.FACTIONS[f]["air"]
		for id in ids:
			var is_mech: bool = ModelsExt.STYLES.get(id, {}).get("k", "") == "mech"
			var uss := ss_mech if is_mech else ss_unit
			_jobs.append({"key": "%s|%s" % [id, f], "id": id, "accent": accent, "faction": f, "angles": ANGLES,
					"frame": UNIT_FRAME, "extra": UNIT_EXTRA, "ss": uss, "crop": true, "hd": true})
			# Tourelle indépendante : cuite à part, centrée sur son pivot, 16 angles
			if Models.has_turret(id, f):
				_jobs.append({"key": "%s_tete|%s" % [id, f], "id": "%s_tete" % id, "accent": accent, "faction": f, "angles": ANGLES,
						"frame": Vector2(96, 96), "extra": 44.0, "ss": ss_unit, "crop": true, "hd": true})
			# Mechas : images de marche (pattes qui bougent), une par phase du cycle
			if is_mech:
				for k in Models.WALK_FRAMES:
					_jobs.append({"key": "%s|%s|w%d" % [id, f, k], "id": id, "accent": accent, "faction": f, "angles": ANGLES,
							"frame": UNIT_FRAME, "extra": UNIT_EXTRA, "phase": float(k) / Models.WALK_FRAMES, "ss": uss, "crop": true, "hd": true})
		var bids: Array = ["chantier", "centrale", "raffinerie", "fonderie", "usine", "tourelle"]
		for id in GameData.buildings_for(f):
			if not bids.has(id):
				bids.append(id)
		for id in bids:
			if GameData.def(id).get("wall", false):
				continue
			var cs: Vector2i = GameData.def(id)["size"]
			var fr := Vector2(cs * 32) + Vector2(BUILDING_MARGIN, BUILDING_MARGIN)
			_jobs.append({"key": "%s|%s" % [id, f], "id": id, "accent": accent, "faction": f, "angles": 1,
					"frame": fr, "extra": BUILDING_EXTRA, "ss": ss_building, "hd": true})
			if TIERED.has(id) and not Models.imp_glb(id, f): # paliers d'évolution : un modèle différent aux niveaux 2 et 3
				for lv in [2, 3]:
					_jobs.append({"key": "%s|%s|L%d" % [id, f, lv], "id": id, "accent": accent, "faction": f, "angles": 1,
							"frame": fr, "extra": BUILDING_EXTRA, "ss": ss_building, "hd": true, "tier": lv})
			if id == "radar":
				_jobs.append({"key": "radar_tete|%s" % f, "id": "radar_tete", "accent": accent, "faction": f,
						"angles": 32, "frame": Vector2(96, 96), "extra": 60.0})
			if id == "tourelle" and not Models.imp_glb(id, f):
				for lv in [2, 3]:
					_jobs.append({"key": "tourelle_tete|%s|L%d" % [f, lv], "id": "tourelle_tete", "accent": accent, "faction": f, "angles": ANGLES,
							"frame": Vector2(96, 96), "extra": 60.0, "tier": lv})
			if id != "tourelle" and GameData.def(id).has("weapon"):
				_jobs.append({"key": "%s_tete|%s" % [id, f], "id": "%s_tete" % id, "accent": accent, "faction": f,
						"angles": ANGLES, "frame": Vector2(96, 96), "extra": 60.0})
		_jobs.append({"key": "tourelle_tete|%s" % f, "id": "tourelle_tete", "accent": accent, "faction": f, "angles": ANGLES,
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


## Zone réellement dessinée (pixels de texture) d'une image : sert à cadrer les icônes.
func used_rect(key: String, angle := 0.0) -> Rect2:
	var arr: Array = _used.get(key, [])
	if arr.is_empty():
		return Rect2()
	return arr[frame_index(key, angle)]


## Zone réellement occupée par le modèle, en coordonnées de dessin (centre de l'unité = origine).
func visual_box(key: String, angle := 0.0) -> Rect2:
	var arr: Array = _tex.get(key, [])
	var ur: Rect2 = used_rect(key, angle)
	if arr.is_empty() or ur.size == Vector2.ZERO:
		return Rect2()
	var fsz: Vector2 = _full.get(key, arr[0].get_size())
	var dsz: Vector2 = _size.get(key, fsz)
	var k := dsz / fsz
	var off: Vector2 = _off_of(key, angle)
	return Rect2((off + ur.position) * k - dsz / 2.0, ur.size * k)


## Rectangle de dessin (coordonnées de dessin, centre = origine) de l'image `frame(key, angle)` : les images des
## véhicules sont rognées à leur zone utile, donc l'image n'occupe qu'une partie du cadre complet.
func draw_rect(key: String, angle := 0.0) -> Rect2:
	var arr: Array = _tex.get(key, [])
	if arr.is_empty():
		return Rect2()
	var tex: Texture2D = arr[frame_index(key, angle)]
	var fsz: Vector2 = _full.get(key, tex.get_size())
	var dsz: Vector2 = _size.get(key, fsz)
	var k := dsz / fsz
	return Rect2(_off_of(key, angle) * k - dsz / 2.0, tex.get_size() * k)


## Centre du modèle (origine du dessin) en pixels de l'image `frame(key, angle)` (rognée ou non).
func centre_px(key: String, angle := 0.0) -> Vector2:
	var arr: Array = _tex.get(key, [])
	if arr.is_empty():
		return Vector2.ZERO
	var tex: Texture2D = arr[frame_index(key, angle)]
	var fsz: Vector2 = _full.get(key, tex.get_size())
	return fsz * 0.5 - _off_of(key, angle)


## Pixels de texture par unité de dessin, selon chaque axe (l'axe vertical est comprimé par la projection oblique).
func px_scale(key: String) -> Vector2:
	var arr: Array = _tex.get(key, [])
	if arr.is_empty():
		return Vector2.ONE
	var fsz: Vector2 = _full.get(key, arr[0].get_size())
	return fsz / _size.get(key, fsz)


func _off_of(key: String, angle: float) -> Vector2:
	var offs: Array = _off.get(key, [])
	if offs.is_empty():
		return Vector2.ZERO
	return offs[frame_index(key, angle)]


## Angle exact de l'image choisie pour `angle` (écart résiduel = angle - snap_angle).
func snap_angle(key: String, angle: float) -> float:
	var arr: Array = _tex.get(key, [])
	if arr.size() <= 1:
		return angle
	return float(frame_index(key, angle)) * TAU / arr.size()


func frame_index(key: String, angle: float) -> int:
	var arr: Array = _tex.get(key, [])
	if arr.size() <= 1:
		return 0
	return int(round(wrapf(angle, 0.0, TAU) / TAU * arr.size())) % arr.size()


func draw_size(key: String) -> Vector2:
	return _size.get(key, Vector2.ZERO)


func _make_viewport() -> void:
	var lane := _make_lane()
	_vp = lane["vp"]
	_cam = lane["cam"]
	_holder = lane["holder"]
	_lanes = [lane]


## Une voie de cuisson : sous-fenêtre 3D propre (monde, soleil, caméra orthographique inclinée).
func _make_lane() -> Dictionary:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.size = Vector2i(256, 256)
	add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.72)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	# Soleil venant du haut-droite : les ombres tombent vers le bas-gauche, comme le terrain
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.35
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 700.0
	vp.add_child(sun)
	sun.look_at_from_position(Vector3(120, 170, -70), Vector3.ZERO, Vector3.UP)

	var holder := Node3D.new()
	vp.add_child(holder)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 1.0
	cam.far = 1500.0
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, cos(TILT), sin(TILT)) * 600.0, Vector3.ZERO, Vector3.UP)
	cam.current = true
	return {"vp": vp, "cam": cam, "holder": holder}


## Ordre de cuisson : 0 = indispensable au départ (camp du joueur), 1 = reste du camp du joueur, 2 = ses paliers et animations,
## 3-4 = camps adverses (cachés par le brouillard au début).
func _prio(job: Dictionary) -> int:
	var fi: int = _fac_order.find(job["faction"])
	var extra: bool = job.has("tier") or job.has("phase")
	var base := String(job["id"]).trim_suffix("_tete")
	if fi <= 0:
		if not extra and (base in CORE_UNITS or base in CORE_BUILDINGS):
			return 0
		return 2 if extra else 1
	return 4 if extra else 3


func _bake_all() -> void:
	for k in _jobs.size():
		_jobs[k]["prio"] = _prio(_jobs[k])
		_jobs[k]["ord"] = k
	_jobs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["prio"] < b["prio"] or (a["prio"] == b["prio"] and a["ord"] < b["ord"]))
	for job in _jobs:
		total += int(job["angles"])
		if job["prio"] == 0:
			core_total += int(job["angles"])
	_core_left = 0
	for job in _jobs:
		if job["prio"] == 0:
			_core_left += 1
	if _core_left == 0:
		core_ok = true
		core_ready.emit()
	_cache_prepare()
	_t0 = Time.get_ticks_msec()
	_hits = 0
	# plusieurs voies en parallèle : chacune attend sa propre image, les rendus se font dans la même trame
	while _lanes.size() < LANES:
		_lanes.append(_make_lane())
	_active = _lanes.size()
	for i in _lanes.size():
		_worker(i)


var _core_left := 0
var _t0 := 0
var _hits := 0


func _worker(idx: int) -> void:
	var lane: Dictionary = _lanes[idx]
	var quick := 0
	while true:
		if idx > 0 and core_ok:
			break # le nécessaire est prêt : on laisse le jeu tourner, une seule voie finit le reste en douceur
		if _next_job >= _jobs.size():
			break
		var job: Dictionary = _jobs[_next_job]
		_next_job += 1
		var n := int(job["angles"])
		if _cache_load(job):
			_hits += 1
			quick += 1
			if quick % 6 == 0:
				await get_tree().process_frame # laisse l'écran de chargement respirer
		else:
			await _bake(job, lane)
			_cache_save(job)
		done += n
		if job["prio"] == 0:
			core_done += n
			_core_left -= 1
			if _core_left == 0:
				core_ok = true
				core_ready.emit()
				batch_done.emit()
		elif _next_job < _jobs.size() and _jobs[_next_job]["prio"] != job["prio"]:
			batch_done.emit()
	_active -= 1
	if _active == 0:
		# la voie 0 reste en place ; les voies supplémentaires sont libérées
		while _lanes.size() > 1:
			var l: Dictionary = _lanes.pop_back()
			(l["vp"] as SubViewport).queue_free()
		print("SpriteBank : %d/%d jeux d'images lus du cache, %.1f s" % [_hits, _jobs.size(), (Time.get_ticks_msec() - _t0) / 1000.0])
		ready_all = true
		finished.emit()
		batch_done.emit()


# --- Cache disque : les images cuites sont gardées entre deux parties -------------------------------------------------
# Une cuisson complète prend de longues secondes ; relue du disque (données brutes compressées zstd, mipmaps comprises),
# elle est quasi instantanée. Le cache est invalidé dès que le code des modèles, les shaders, la version ou les réglages changent.

const CACHE_FILES := ["models.gd", "models_kharn.gd", "models_ext.gd", "models_fac.gd", "models_mech.gd", "models_tiers.gd", "sprite_bank.gd",
		"game_data.gd", "shaders/hull.gdshader"]
var _cache_dir := ""
var _cache_sig := ""


func _cache_prepare() -> void:
	_cache_dir = ""
	var sig: String = ChangelogData.current() + "|" + String(Engine.get_version_info().get("string", ""))
	for f in CACHE_FILES:
		sig += "|" + FileAccess.get_md5("res://" + f)
	sig += "|%s|%s|%s|%s|%s" % [hd_units, ss, ss_unit, ss_mech, ss_building]
	_cache_sig = sig.md5_text().substr(0, 12)
	var root := "user://sprite_cache"
	var da := DirAccess.open("user://")
	if da == null:
		return
	if not da.dir_exists("sprite_cache"):
		da.make_dir("sprite_cache")
	var rd := DirAccess.open(root)
	if rd == null:
		return
	# on supprime les caches des anciennes versions
	for d in rd.get_directories():
		if d != _cache_sig:
			var old := DirAccess.open("%s/%s" % [root, d])
			if old != null:
				for f in old.get_files():
					old.remove(f)
			rd.remove(d)
	if not rd.dir_exists(_cache_sig):
		rd.make_dir(_cache_sig)
	_cache_dir = "%s/%s" % [root, _cache_sig]


func _cache_path(job: Dictionary) -> String:
	return "%s/%s.bin" % [_cache_dir, String(job["key"]).replace("|", "_")]


func _cache_save(job: Dictionary) -> void:
	if _cache_dir == "" or not _tex.has(job["key"]):
		return
	var imgs: Array = []
	for t in _tex[job["key"]]:
		var im: Image = (t as ImageTexture).get_image()
		var raw := im.get_data()
		imgs.append({"w": im.get_width(), "h": im.get_height(), "f": int(im.get_format()), "m": im.has_mipmaps(),
				"n": raw.size(), "d": raw.compress(FileAccess.COMPRESSION_ZSTD)})
	var f := FileAccess.open(_cache_path(job), FileAccess.WRITE)
	if f == null:
		return
	f.store_var({"imgs": imgs, "used": _used[job["key"]], "off": _off[job["key"]], "full": _full[job["key"]], "size": _size[job["key"]]})
	f.close()


func _cache_load(job: Dictionary) -> bool:
	if _cache_dir == "" or not FileAccess.file_exists(_cache_path(job)):
		return false
	var f := FileAccess.open(_cache_path(job), FileAccess.READ)
	if f == null:
		return false
	var data = f.get_var()
	f.close()
	if not (data is Dictionary) or not data.has("imgs"):
		return false
	var out: Array = []
	for e in data["imgs"]:
		var raw: PackedByteArray = (e["d"] as PackedByteArray).decompress(int(e["n"]), FileAccess.COMPRESSION_ZSTD)
		if raw.size() != int(e["n"]):
			return false
		var im := Image.create_from_data(int(e["w"]), int(e["h"]), bool(e["m"]), int(e["f"]) as Image.Format, raw)
		if im == null or im.is_empty():
			return false
		out.append(ImageTexture.create_from_image(im))
	if out.size() != int(job["angles"]):
		return false
	_tex[job["key"]] = out
	_used[job["key"]] = data["used"]
	_off[job["key"]] = data["off"]
	_full[job["key"]] = data["full"]
	_size[job["key"]] = data["size"]
	return true


func _bake(job: Dictionary, lane: Dictionary = {}) -> void:
	var vp: SubViewport = lane.get("vp", _vp)
	var cam: Camera3D = lane.get("cam", _cam)
	var holder: Node3D = lane.get("holder", _holder)
	var frame_px: Vector2 = job["frame"]
	var jss: float = float(job.get("ss", ss))
	var view_h: float = frame_px.y * cos(TILT) + float(job["extra"])
	vp.size = Vector2i(int(ceil(frame_px.x * jss)), int(ceil(view_h * jss)))
	cam.size = view_h
	Models.walk_phase = float(job.get("phase", -1.0))
	Models.hd = hd_units and bool(job.get("hd", false))
	Models.tier = int(job.get("tier", 1))
	var model := Models.build(job["id"], job["accent"], job.get("faction", ""))
	Models.walk_phase = -1.0
	Models.hd = false
	Models.tier = 1
	holder.add_child(model)
	var out: Array = []
	var rects: Array = []
	var offs: Array = []
	var full := Vector2(vp.size)
	for i in int(job["angles"]):
		# Angle 2D (sens horaire à l'écran) -> rotation autour de Y : signe inversé
		model.rotation.y = -TAU * i / float(job["angles"])
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var used := Rect2i(img.get_used_rect())
		if job.get("crop", false) and used.size.x > 0 and used.size.y > 0:
			# on ne garde que la zone dessinée (+1 pixel) : indispensable pour tenir en mémoire à haute résolution
			var cr := used.grow(1).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			img = img.get_region(cr)
			offs.append(Vector2(cr.position))
			rects.append(Rect2(used.position - cr.position, used.size))
		else:
			offs.append(Vector2.ZERO)
			rects.append(Rect2(used))
		img.generate_mipmaps()
		out.append(ImageTexture.create_from_image(img))
	holder.remove_child(model)
	model.queue_free()
	_tex[job["key"]] = out
	_used[job["key"]] = rects
	_off[job["key"]] = offs
	_full[job["key"]] = full
	_size[job["key"]] = Vector2(frame_px.x, view_h / cos(TILT))
