extends Node2D
## Scène principale : terrain (shader), caméra, sélection, production et
## placement de bâtiments. L'interface est dans ui.gd.

const TILE := 32
const MAP_W := 64
const MAP_H := 64
const FIELD_SCALE := 4  # échantillons de relief par case (texture envoyée au shader)
const MINIMAP_RES := 128
const WORLD_SIZE := Vector2(MAP_W * TILE, MAP_H * TILE)
const SIDEBAR_EXTRA := 390.0 # la caméra peut défiler sous le panneau latéral
const CAM_SPEED := 800.0
const EDGE_SCROLL := true
const EDGE_MARGIN := 12
const FX_GLOW := true # HDR 2D + bloom (Forward+). Mettre false en cas de souci d'affichage.

# Zone de départ (plateau rocheux) et bassin d'épice, en cases
const START := Vector2(32, 32)
const SPICE_POS := Vector2(20, 37)
const ROCK_H := 0.12
const MOUNTAIN_H := 0.5
const SPICE_T := 0.35

# Couleurs de la mini-carte
const MM_SAND := Color("d89580")
const MM_SPICE := Color("e2762a")
const MM_ROCK := Color("6e3329")
const MM_MOUNTAIN := Color("2a100e")

enum T { SAND, ROCK, MOUNTAIN, SPICE }

var world_size := WORLD_SIZE
var terrain: Array = []
var grid := AStarGrid2D.new()
var camera := Camera2D.new()
var map_texture: ImageTexture # mini-carte du radar
var ui: GameUI

var units: Array[Unit] = []
var selected: Array[Unit] = []
var buildings: Array[Building] = []
var occupied := {} # Vector2i -> true (cases prises par un bâtiment)

var credits := 3000
var game_time := 0.0
var production := {"building": {}, "unit": {}}
var placing_id := ""
var command_mode := ""

var drag_start := Vector2.ZERO
var dragging := false

var noise_h := FastNoiseLite.new()
var noise_s := FastNoiseLite.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1c0f20"))
	_setup_display()
	_setup_noise()
	_generate_terrain()
	_build_grid()
	_build_terrain()
	_build_minimap()
	camera.position = START * TILE
	camera.zoom = Vector2(1.3, 1.3)
	add_child(camera)
	_clamp_camera()
	_place_building("chantier", Vector2i(31, 31))
	_spawn_start_units()
	ui = GameUI.new()
	add_child(ui)
	ui.setup(self)


## Antialiasing MSAA 2D et, si FX_GLOW, rendu HDR avec bloom (Forward+).
func _setup_display() -> void:
	var vp := get_viewport()
	vp.msaa_2d = Viewport.MSAA_4X
	if FX_GLOW:
		vp.use_hdr_2d = true
		var env := Environment.new()
		env.background_mode = Environment.BG_CANVAS
		env.glow_enabled = true
		env.glow_intensity = 0.7
		env.glow_strength = 1.0
		env.glow_bloom = 0.0
		env.glow_hdr_threshold = 1.0
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		var we := WorldEnvironment.new()
		we.environment = env
		add_child(we)


# --- Terrain ------------------------------------------------------------------

func _setup_noise() -> void:
	var base := randi()
	noise_h.seed = base
	noise_h.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_h.frequency = 0.07
	noise_h.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_h.fractal_octaves = 3
	noise_s.seed = base + 101
	noise_s.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_s.frequency = 0.09
	noise_s.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_s.fractal_octaves = 2


## Hauteur du terrain en un point (coordonnées en cases, flottantes).
func _height(p: Vector2) -> float:
	var h := noise_h.get_noise_2d(p.x, p.y) * 0.8
	h = lerpf(h, 0.28, smoothstep(9.0, 4.5, p.distance_to(START)))      # plateau de départ
	h = lerpf(h, -0.4, smoothstep(8.0, 4.0, p.distance_to(SPICE_POS)))  # bassin de sable
	var edge := minf(minf(p.x, MAP_W - p.x), minf(p.y, MAP_H - p.y))
	h = lerpf(h, 0.7, smoothstep(3.0, 0.5, edge))                       # chaîne de bord de carte
	return h


func _spice(p: Vector2) -> float:
	return noise_s.get_noise_2d(p.x, p.y) * 0.8 \
			+ 0.7 * smoothstep(7.0, 1.0, p.distance_to(SPICE_POS))


func _cell_type(c: Vector2i) -> int:
	var p := Vector2(c) + Vector2(0.5, 0.5)
	var h := _height(p)
	if h > MOUNTAIN_H:
		return T.MOUNTAIN
	if h > ROCK_H:
		return T.ROCK
	if _spice(p) > SPICE_T:
		return T.SPICE
	return T.SAND


func _generate_terrain() -> void:
	for x in MAP_W:
		terrain.append([])
		for y in MAP_H:
			terrain[x].append(_cell_type(Vector2i(x, y)))


func _build_grid() -> void:
	grid.region = Rect2i(0, 0, MAP_W, MAP_H)
	grid.cell_size = Vector2(TILE, TILE)
	grid.offset = Vector2(TILE, TILE) / 2.0 # les chemins passent par le centre des cases
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in MAP_W:
		for y in MAP_H:
			if terrain[x][y] == T.MOUNTAIN:
				grid.set_point_solid(Vector2i(x, y))


## Envoie le relief au shader du terrain : texture R = hauteur, G = épice.
func _build_terrain() -> void:
	var fw := MAP_W * FIELD_SCALE
	var fh := MAP_H * FIELD_SCALE
	var img := Image.create(fw, fh, false, Image.FORMAT_RGBAH)
	for y in fh:
		for x in fw:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / FIELD_SCALE
			img.set_pixel(x, y, Color(_height(p), _spice(p), 0.0, 1.0))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("field", ImageTexture.create_from_image(img))
	mat.set_shader_parameter("world_size", WORLD_SIZE)
	mat.set_shader_parameter("tile", float(TILE))
	mat.set_shader_parameter("rock_h", ROCK_H)
	mat.set_shader_parameter("mountain_h", MOUNTAIN_H)
	mat.set_shader_parameter("spice_t", SPICE_T)
	var rect := ColorRect.new()
	rect.size = WORLD_SIZE
	rect.color = Color.WHITE
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = -10
	add_child(rect)


func _build_minimap() -> void:
	var img := Image.create(MINIMAP_RES, MINIMAP_RES, false, Image.FORMAT_RGB8)
	var k := float(MAP_W) / MINIMAP_RES
	for y in MINIMAP_RES:
		for x in MINIMAP_RES:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) * k
			var h := _height(p)
			var col := MM_SAND
			if h > MOUNTAIN_H:
				col = MM_MOUNTAIN
			elif h > ROCK_H:
				col = MM_ROCK
			elif _spice(p) > SPICE_T:
				col = MM_SPICE
			img.set_pixel(x, y, col)
	map_texture = ImageTexture.create_from_image(img)


# --- Boucle -------------------------------------------------------------------

func _process(delta: float) -> void:
	game_time += delta
	_update_production(delta)
	_move_camera(delta)

	if dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = false # relâché au-dessus de l'interface
		_finish_selection(get_global_mouse_position())
	if dragging or placing_id != "":
		queue_redraw()
	Input.set_default_cursor_shape(
			Input.CURSOR_CROSS if (placing_id != "" or command_mode != "") else Input.CURSOR_ARROW)


func _move_camera(delta: float) -> void:
	# Flèches + ZQSD (touches physiques : fonctionne en AZERTY)
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right") + _key(KEY_D) - _key(KEY_A),
		Input.get_axis("ui_up", "ui_down") + _key(KEY_S) - _key(KEY_W))
	if EDGE_SCROLL and get_window().has_focus() and not ui.is_mouse_over_ui():
		var m := get_viewport().get_mouse_position()
		var vp := get_viewport_rect().size
		if m.x < EDGE_MARGIN: dir.x -= 1
		if m.x > vp.x - EDGE_MARGIN: dir.x += 1
		if m.y < EDGE_MARGIN: dir.y -= 1
		if m.y > vp.y - EDGE_MARGIN: dir.y += 1
	camera.position += dir.limit_length(1.0) * CAM_SPEED / camera.zoom.x * delta
	_clamp_camera()


## Garde la caméra dans le monde, quelle que soit la taille de la fenêtre.
func _clamp_camera() -> void:
	var vp := get_viewport_rect().size
	var min_z := maxf(vp.x / (WORLD_SIZE.x + SIDEBAR_EXTRA), vp.y / WORLD_SIZE.y)
	if camera.zoom.x < min_z:
		camera.zoom = Vector2(min_z, min_z)
	var half := vp / camera.zoom / 2.0
	camera.position.x = clampf(camera.position.x, half.x, WORLD_SIZE.x + SIDEBAR_EXTRA - half.x)
	camera.position.y = clampf(camera.position.y, half.y, WORLD_SIZE.y - half.y)


func center_camera(world_pos: Vector2) -> void:
	camera.position = world_pos
	_clamp_camera()


func _key(k: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(k) else 0.0


func _zoom(factor: float) -> void:
	var z := clampf(camera.zoom.x * factor, 0.4, 2.5)
	camera.zoom = Vector2(z, z)
	_clamp_camera()


# --- Entrées ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			placing_id = ""
			command_mode = ""
		elif event.keycode == KEY_F11:
			var w := get_window()
			w.mode = Window.MODE_MAXIMIZED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_left_pressed()
				elif dragging:
					dragging = false
					_finish_selection(get_global_mouse_position())
					queue_redraw()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					if placing_id != "" or command_mode != "":
						placing_id = ""
						command_mode = ""
					else:
						order_move(get_global_mouse_position())
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed: _zoom(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed: _zoom(1.0 / 1.1)


func _left_pressed() -> void:
	if placing_id != "":
		var cell := _ghost_cell()
		if _can_place(placing_id, cell):
			_place_building(placing_id, cell)
			production["building"] = {}
			placing_id = ""
		else:
			ui.toast("Emplacement invalide : roche libre, près de la base", GameData.RED)
	elif command_mode == "move":
		order_move(get_global_mouse_position())
		command_mode = ""
	else:
		dragging = true
		drag_start = get_global_mouse_position()


# --- Sélection & ordres -------------------------------------------------------

func _finish_selection(end: Vector2) -> void:
	if not Input.is_key_pressed(KEY_SHIFT):
		for u in selected:
			u.selected = false
		selected.clear()
	var rect := Rect2(drag_start, end - drag_start).abs()
	var is_click := rect.size.length() < 6.0
	for u in units:
		var hit := u.position.distance_to(end) < u.radius + 4.0 if is_click \
				else rect.has_point(u.position)
		if hit and u not in selected:
			u.selected = true
			selected.append(u)


func order_move(world_pos: Vector2) -> void:
	var target := _world_to_cell(world_pos)
	for i in selected.size():
		var cell := target + _formation_offset(i, selected.size())
		if not _is_walkable(cell):
			cell = target
		if not _is_walkable(cell):
			continue
		var from := _world_to_cell(selected[i].position)
		selected[i].follow(grid.get_point_path(from, cell))


@warning_ignore("integer_division")
func _formation_offset(i: int, n: int) -> Vector2i:
	var w := ceili(sqrt(n))
	return Vector2i(i % w - w / 2, i / w - w / 2)


func on_command(cmd: String) -> void:
	match cmd:
		"stop":
			for u in selected:
				u.path = PackedVector2Array()
		"move":
			placing_id = ""
			command_mode = "move"


# --- Production & construction ------------------------------------------------

func is_available(id: String) -> bool:
	for r in GameData.def(id)["requires"]:
		if not has_building(r):
			return false
	return true


func has_building(id: String) -> bool:
	for b in buildings:
		if b.id == id:
			return true
	return false


func power_produced() -> int:
	var total := 0
	for b in buildings:
		if b.power > 0:
			total += b.power
	return total


func power_used() -> int:
	var total := 0
	for b in buildings:
		if b.power < 0:
			total -= b.power
	return total


func production_for(id: String) -> Dictionary:
	var p: Dictionary = production["unit" if GameData.UNITS.has(id) else "building"]
	if not p.is_empty() and p["id"] == id:
		return p
	return {}


func on_item_clicked(id: String, button: int) -> void:
	var cat := "unit" if GameData.UNITS.has(id) else "building"
	var p: Dictionary = production[cat]
	var d := GameData.def(id)
	if button == MOUSE_BUTTON_RIGHT:
		if not p.is_empty() and p["id"] == id:
			credits += int(d["cost"]) # annulation : remboursement intégral
			production[cat] = {}
			if placing_id == id:
				placing_id = ""
			ui.toast("%s annulé — remboursé" % d["name"], GameData.AMBER)
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	if not p.is_empty():
		if p["id"] == id and p["ready"] and cat == "building":
			command_mode = ""
			placing_id = id
		else:
			ui.toast("Production déjà en cours", GameData.AMBER)
		return
	if not is_available(id):
		ui.toast("Prérequis manquant", GameData.RED)
		return
	if credits < int(d["cost"]):
		ui.toast("Solaris insuffisants", GameData.RED)
		return
	credits -= int(d["cost"])
	production[cat] = {"id": id, "progress": 0.0, "time": float(d["time"]), "ready": false}


func _update_production(delta: float) -> void:
	# Énergie insuffisante : production deux fois plus lente
	var factor := 1.0 if power_produced() >= power_used() else 0.5
	for cat in production.keys():
		var p: Dictionary = production[cat]
		if p.is_empty() or p["ready"]:
			continue
		p["progress"] += delta * factor / p["time"]
		if p["progress"] >= 1.0:
			p["progress"] = 1.0
			var item_name: String = GameData.def(p["id"])["name"]
			if cat == "unit":
				_spawn_produced_unit()
				production[cat] = {}
				ui.toast("%s prêt !" % item_name, GameData.GREEN)
			else:
				p["ready"] = true
				ui.toast("%s prêt — cliquez sur l'icône pour la poser" % item_name, GameData.GREEN)


func _ghost_cell() -> Vector2i:
	var size: Vector2i = GameData.BUILDINGS[placing_id]["size"]
	return _world_to_cell(get_global_mouse_position()) - size / 2


## Un bâtiment se pose sur la roche, sans chevauchement, près de la base.
func _can_place(id: String, cell: Vector2i) -> bool:
	var size: Vector2i = GameData.BUILDINGS[id]["size"]
	for dx in size.x:
		for dy in size.y:
			var c := cell + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0 or c.x >= MAP_W or c.y >= MAP_H:
				return false
			if terrain[c.x][c.y] != T.ROCK or occupied.has(c):
				return false
	var center := Vector2(cell) + Vector2(size) / 2.0
	for b in buildings:
		if center.distance_to(b.center_cell()) <= 9.0:
			return true
	return false


func _place_building(id: String, cell: Vector2i) -> void:
	var d: Dictionary = GameData.BUILDINGS.get(id, GameData.START_BUILDING)
	var b := Building.new()
	b.setup(id, cell, d["size"], TILE, d["power"])
	add_child(b)
	buildings.append(b)
	for c in b.cells():
		occupied[c] = true
		grid.set_point_solid(c, true)


@warning_ignore("integer_division")
func _spawn_produced_unit() -> void:
	var origin := Vector2i(MAP_W / 2, MAP_H / 2 + 4)
	for b in buildings:
		if b.id == "usine":
			origin = b.cell + Vector2i(b.cell_size.x / 2, b.cell_size.y)
			break
	_spawn_unit(_find_free_cell(origin))


func _spawn_start_units() -> void:
	for i in 3:
		_spawn_unit(Vector2i(29 + i * 2, 36))


func _spawn_unit(cell: Vector2i) -> void:
	var u := Unit.new()
	u.position = _cell_to_world(cell)
	add_child(u)
	units.append(u)


func _find_free_cell(start: Vector2i) -> Vector2i:
	for r in 8:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := start + Vector2i(dx, dy)
				if _is_walkable(c) and not _cell_has_unit(c):
					return c
	return start


func _cell_has_unit(c: Vector2i) -> bool:
	for u in units:
		if _world_to_cell(u.position) == c:
			return true
	return false


# --- Utilitaires --------------------------------------------------------------

func _is_walkable(c: Vector2i) -> bool:
	return grid.is_in_boundsv(c) and not grid.is_point_solid(c)


func _world_to_cell(p: Vector2) -> Vector2i:
	var c := Vector2i((p / TILE).floor())
	return c.clamp(Vector2i.ZERO, Vector2i(MAP_W - 1, MAP_H - 1))


func _cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c) * TILE + Vector2(TILE, TILE) / 2.0


# --- Rendu --------------------------------------------------------------------

func _draw() -> void:
	if dragging:
		var r := Rect2(drag_start, get_global_mouse_position() - drag_start).abs()
		draw_rect(r, Color(0.3, 1.0, 0.6, 0.12))
		draw_rect(r, GameData.GREEN, false, 1.5)
	if placing_id != "":
		var size: Vector2i = GameData.BUILDINGS[placing_id]["size"]
		var cell := _ghost_cell()
		var ok := _can_place(placing_id, cell)
		var col := Color(0.3, 1.0, 0.5, 0.35) if ok else Color(1.0, 0.25, 0.25, 0.35)
		for dx in size.x:
			for dy in size.y:
				var rect := Rect2(Vector2(cell + Vector2i(dx, dy)) * TILE, Vector2(TILE, TILE))
				draw_rect(rect, col)
				draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)
