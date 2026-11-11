extends Node2D
## Scène principale : terrain (shader), ressources, caméra, sélection,
## production, placement de bâtiments et vers géants. Interface : ui.gd.

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

# Terrain
const START := Vector2(32, 32)                              # centre du plateau de départ
const SPICE_FIELDS := [Vector2(20, 37), Vector2(46, 46)]    # bassins de sable à épice
const ORE_FIELDS := [Vector2(42, 25), Vector2(18, 22)]      # filons sur plateaux rocheux
const ROCK_H := 0.12
const MOUNTAIN_H := 0.5
const SPICE_T := 0.35
const ORE_T := 0.35
const SPICE_PER_CELL := 600.0
const ORE_PER_CELL := 500.0

# Ver géant : rare et aléatoire
const WORM_GRACE := 150.0    # aucune apparition avant (secondes)
const WORM_RATE := 0.0012    # probabilité par seconde et par récolteur en activité sur le sable
const WORM_COOLDOWN := 240.0 # pause après chaque apparition

# Couleurs de la mini-carte
const MM_SAND := Color("d89580")
const MM_SPICE := Color("e2762a")
const MM_ROCK := Color("6e3329")
const MM_ORE := Color("8fb2e8")
const MM_MOUNTAIN := Color("2a100e")

enum T { SAND, ROCK, MOUNTAIN, SPICE, ORE }

var world_size := WORLD_SIZE
var faction_id := "solis"
var fdata := {}
var terrain: Array = []
var resource := {} # Vector2i -> {kind, amount, max}
var dirty := {}    # cases dont la texture doit être rafraîchie
var grid := AStarGrid2D.new()
var camera := Camera2D.new()
var map_texture: ImageTexture # mini-carte du radar
var field_img: Image
var field_tex: ImageTexture
var ui: GameUI

var units: Array[Unit] = []
var selected: Array[Unit] = []
var buildings: Array[Building] = []
var occupied := {} # Vector2i -> true (cases prises par un bâtiment)

var credits := 1500 # Solaris (épice raffinée) : payent les unités
var ore := 1500     # Minerai : paye les bâtiments
var game_time := 0.0
var production := {"building": {}, "unit": {}}
var placing_id := ""
var command_mode := ""

var worm: Worm
var worm_cooldown := 0.0
var _field_timer := 0.0
var _shake_t := 0.0
var _shake_dur := 0.01
var _shake_amp := 0.0

var drag_start := Vector2.ZERO
var dragging := false

var noise_h := FastNoiseLite.new()
var noise_s := FastNoiseLite.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1c0f20"))
	Fx.setup_display(self, FX_GLOW)
	faction_id = GameSession.faction
	fdata = GameData.FACTIONS[faction_id]
	_setup_noise()
	_generate_terrain()
	_init_resources()
	_build_grid()
	_build_terrain()
	_build_minimap()
	camera.position = START * TILE
	camera.zoom = Vector2(1.3, 1.3)
	add_child(camera)
	_clamp_camera()
	_place_start_base()
	_spawn_start_units()
	ui = GameUI.new()
	add_child(ui)
	ui.setup(self)
	ui.toast("%s — bonne chance, commandant" % fdata["name"], fdata["accent"])


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
	for sf in SPICE_FIELDS:
		h = lerpf(h, -0.4, smoothstep(8.0, 4.0, p.distance_to(sf)))     # bassins de sable
	for orf in ORE_FIELDS:
		h = lerpf(h, 0.28, smoothstep(7.0, 3.5, p.distance_to(orf)))     # plateaux à minerai
	var edge := minf(minf(p.x, MAP_W - p.x), minf(p.y, MAP_H - p.y))
	h = lerpf(h, 0.7, smoothstep(3.0, 0.5, edge))                       # chaîne de bord de carte
	return h


func _spice(p: Vector2) -> float:
	var best := 0.0
	for sf in SPICE_FIELDS:
		best = maxf(best, smoothstep(7.0, 1.0, p.distance_to(sf)))
	return noise_s.get_noise_2d(p.x, p.y) * 0.8 + 0.7 * best


func _ore(p: Vector2) -> float:
	var best := 0.0
	for orf in ORE_FIELDS:
		best = maxf(best, smoothstep(5.5, 1.0, p.distance_to(orf)))
	return noise_s.get_noise_2d(p.x + 100.0, p.y + 100.0) * 0.5 + 0.75 * best


func _cell_type(c: Vector2i) -> int:
	var p := Vector2(c) + Vector2(0.5, 0.5)
	var h := _height(p)
	if h > MOUNTAIN_H:
		return T.MOUNTAIN
	if h > ROCK_H:
		return T.ORE if _ore(p) > ORE_T else T.ROCK
	if _spice(p) > SPICE_T:
		return T.SPICE
	return T.SAND


func _generate_terrain() -> void:
	for x in MAP_W:
		terrain.append([])
		for y in MAP_H:
			terrain[x].append(_cell_type(Vector2i(x, y)))


func _init_resources() -> void:
	for x in MAP_W:
		for y in MAP_H:
			var t: int = terrain[x][y]
			if t == T.SPICE:
				resource[Vector2i(x, y)] = {"kind": "spice", "amount": SPICE_PER_CELL, "max": SPICE_PER_CELL}
			elif t == T.ORE:
				resource[Vector2i(x, y)] = {"kind": "ore", "amount": ORE_PER_CELL, "max": ORE_PER_CELL}


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


## Envoie le relief au shader : texture R = hauteur, G = épice, B = minerai.
func _build_terrain() -> void:
	var fw := MAP_W * FIELD_SCALE
	var fh := MAP_H * FIELD_SCALE
	field_img = Image.create(fw, fh, false, Image.FORMAT_RGBAH)
	for y in fh:
		for x in fw:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / FIELD_SCALE
			field_img.set_pixel(x, y, Color(_height(p), _spice(p), _ore(p), 1.0))
	field_tex = ImageTexture.create_from_image(field_img)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("field", field_tex)
	mat.set_shader_parameter("world_size", WORLD_SIZE)
	mat.set_shader_parameter("tile", float(TILE))
	mat.set_shader_parameter("rock_h", ROCK_H)
	mat.set_shader_parameter("mountain_h", MOUNTAIN_H)
	mat.set_shader_parameter("spice_t", SPICE_T)
	mat.set_shader_parameter("ore_t", ORE_T)
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
				col = MM_ORE if _ore(p) > ORE_T else MM_ROCK
			elif _spice(p) > SPICE_T:
				col = MM_SPICE
			img.set_pixel(x, y, col)
	map_texture = ImageTexture.create_from_image(img)


## Réécrit dans la texture les cases dont la quantité a changé (la tache rétrécit).
func _refresh_field() -> void:
	for c in dirty.keys():
		var info: Dictionary = dirty[c]
		var frac: float = info["frac"]
		for dx in FIELD_SCALE:
			for dy in FIELD_SCALE:
				var tx: int = c.x * FIELD_SCALE + dx
				var ty: int = c.y * FIELD_SCALE + dy
				var p := (Vector2(tx, ty) + Vector2(0.5, 0.5)) / FIELD_SCALE
				var col := field_img.get_pixel(tx, ty)
				if info["kind"] == "spice":
					col.g = _spice(p) * pow(frac, 0.7) if frac > 0.0 else -1.0
				else:
					col.b = _ore(p) * pow(frac, 0.7) if frac > 0.0 else -1.0
				field_img.set_pixel(tx, ty, col)
	dirty.clear()
	field_tex.update(field_img)


# --- Ressources ---------------------------------------------------------------

## Retire de la ressource d'une case ; renvoie la quantité réellement obtenue.
func extract(cell: Vector2i, amount: float) -> float:
	var r = resource.get(cell)
	if r == null:
		return 0.0
	var got := minf(amount, float(r["amount"]))
	r["amount"] = float(r["amount"]) - got
	var frac := float(r["amount"]) / float(r["max"])
	dirty[cell] = {"kind": r["kind"], "frac": frac}
	if r["amount"] <= 0.5:
		resource.erase(cell)
		terrain[cell.x][cell.y] = T.SAND if r["kind"] == "spice" else T.ROCK
		dirty[cell] = {"kind": r["kind"], "frac": 0.0}
	return got


## Case de ressource la plus proche (de ce type), ou (-1, -1).
func find_resource(kind: String, from: Vector2i, max_dist := 999) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for c in resource:
		var r: Dictionary = resource[c]
		if r["kind"] != kind or occupied.has(c):
			continue
		var d := Vector2(c - from).length()
		if d < best_d and d <= max_dist:
			best_d = d
			best = c
	return best


## Raffinerie (épice) ou fonderie (minerai) la plus proche.
func find_dock(kind: String, from: Vector2i) -> Building:
	var want := "raffinerie" if kind == "spice" else "fonderie"
	var best: Building = null
	var best_d := INF
	for b in buildings:
		if b.id == want:
			var d := Vector2(from).distance_to(b.center_cell())
			if d < best_d:
				best_d = d
				best = b
	return best


## Case libre contre le bâtiment, la plus proche de `from`.
func dock_cell(b: Building, from: Vector2i) -> Vector2i:
	var best := b.cell
	var best_d := INF
	for x in range(b.cell.x - 1, b.cell.x + b.cell_size.x + 1):
		for y in range(b.cell.y - 1, b.cell.y + b.cell_size.y + 1):
			var c := Vector2i(x, y)
			if _is_walkable(c):
				var d := Vector2(c - from).length()
				if d < best_d:
					best_d = d
					best = c
	return best


## Dépôt d'une cargaison : épice → Solaris, minerai → minerai (bonus de faction).
func deposit(kind: String, amount: float, world_pos: Vector2) -> void:
	if kind == "spice":
		var gain := int(amount * float(fdata["spice_mult"]))
		credits += gain
		popup(world_pos, "+%d $" % gain, GameData.GOLD)
	else:
		var gain := int(amount * float(fdata["ore_mult"]))
		ore += gain
		popup(world_pos, "+%d min." % gain, GameData.ORE_BLUE)


## Texte flottant dans le monde.
func popup(world_pos: Vector2, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = world_pos - Vector2(30, 34)
	l.z_index = 20
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 40.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


# --- Vers géants --------------------------------------------------------------

func _update_worm(delta: float) -> void:
	if worm != null:
		return
	worm_cooldown -= delta
	if worm_cooldown > 0.0 or game_time < WORM_GRACE:
		return
	var workers := _harvesters_on_sand()
	if workers.is_empty():
		return
	# Très rare : probabilité proportionnelle au nombre de récolteurs en activité
	if randf() < WORM_RATE * workers.size() * delta:
		_spawn_worm(workers.pick_random())


func _harvesters_on_sand() -> Array:
	var out := []
	for u in units:
		if u.is_worker() and u.state == "harvest" and is_sand_at(u.position):
			out.append(u)
	return out


func _spawn_worm(target) -> void:
	var start: Vector2 = target.position + Vector2.RIGHT * 640.0
	for i in 16:
		var p: Vector2 = target.position + Vector2.from_angle(randf() * TAU) * 640.0
		p = p.clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))
		if is_sand_at(p):
			start = p
			break
	start = start.clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))
	worm = Worm.new()
	worm.setup(self, start, target)
	add_child(worm)
	worm.finished.connect(_on_worm_finished)
	alert_worm()


func _on_worm_finished() -> void:
	worm = null
	worm_cooldown = WORM_COOLDOWN


## Alerte : les ouvriers proches, sur le sable, se réfugient sur la roche.
func alert_worm() -> void:
	ui.toast("ALERTE : vibrations détectées, un ver approche !", GameData.RED)
	for u in units:
		if u.is_worker() and is_sand_at(u.position) and u.position.distance_to(worm.position) < 700.0:
			u.flee()


func nearest_sand_unit(pos: Vector2, max_d: float) -> Unit:
	var best: Unit = null
	var best_d := max_d
	for u in units:
		if is_sand_at(u.position):
			var d := u.position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = u
	return best


func find_safe_cell(from: Vector2i) -> Vector2i:
	for r in range(1, 40):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := from + Vector2i(dx, dy)
				if c.x < 0 or c.y < 0 or c.x >= MAP_W or c.y >= MAP_H:
					continue
				var t: int = terrain[c.x][c.y]
				if (t == T.ROCK or t == T.ORE) and _is_walkable(c):
					var d := Vector2(dx, dy).length()
					if d < best_d:
						best_d = d
						best = c
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)


func shake(amp: float, dur: float) -> void:
	_shake_amp = amp
	_shake_dur = dur
	_shake_t = dur


func on_unit_lost(u: Unit) -> void:
	units.erase(u)
	selected.erase(u)


# --- Boucle -------------------------------------------------------------------

func _process(delta: float) -> void:
	game_time += delta
	_update_production(delta)
	_update_worm(delta)
	_move_camera(delta)

	_field_timer += delta
	if _field_timer > 0.3 and not dirty.is_empty():
		_field_timer = 0.0
		_refresh_field()
	if _shake_t > 0.0:
		_shake_t -= delta
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) \
				* _shake_amp * clampf(_shake_t / _shake_dur, 0.0, 1.0)
	else:
		camera.offset = Vector2.ZERO

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
		match event.keycode:
			KEY_ESCAPE:
				placing_id = ""
				command_mode = ""
			KEY_F11:
				var w := get_window()
				w.mode = Window.MODE_MAXIMIZED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_F10:
				get_tree().change_scene_to_file("res://menu.tscn")
			KEY_F9: # test : fait surgir un ver tout de suite
				if worm == null and not units.is_empty():
					var sand := _harvesters_on_sand()
					_spawn_worm(sand.pick_random() if not sand.is_empty() else units.pick_random())
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
		selected[i].order_path(path_to(selected[i].position, cell))


@warning_ignore("integer_division")
func _formation_offset(i: int, n: int) -> Vector2i:
	var w := ceili(sqrt(n))
	return Vector2i(i % w - w / 2, i / w - w / 2)


func on_command(cmd: String) -> void:
	match cmd:
		"stop":
			for u in selected:
				u.stop()
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


## Coût réel (bonus de faction inclus). Unités : Solaris. Bâtiments : minerai.
func item_cost(id: String) -> int:
	var c := float(GameData.def(id)["cost"])
	if GameData.UNITS.has(id):
		c *= float(fdata["unit_cost_mult"])
	return int(round(c))


func cost_label(id: String) -> String:
	return ("%d $" if GameData.UNITS.has(id) else "%d min.") % item_cost(id)


func can_afford(id: String) -> bool:
	return (credits if GameData.UNITS.has(id) else ore) >= item_cost(id)


func _add_money(id: String, amount: int) -> void:
	if GameData.UNITS.has(id):
		credits += amount
	else:
		ore += amount


func on_item_clicked(id: String, button: int) -> void:
	var cat := "unit" if GameData.UNITS.has(id) else "building"
	var p: Dictionary = production[cat]
	var d := GameData.def(id)
	if button == MOUSE_BUTTON_RIGHT:
		if not p.is_empty() and p["id"] == id:
			_add_money(id, int(p["paid"])) # annulation : remboursement intégral
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
	if not can_afford(id):
		ui.toast("Minerai insuffisant" if cat == "building" else "Solaris insuffisants", GameData.RED)
		return
	var cost := item_cost(id)
	_add_money(id, -cost)
	var t := float(d["time"])
	if cat == "building":
		t *= float(fdata["build_time_mult"])
	production[cat] = {"id": id, "progress": 0.0, "time": t, "ready": false, "paid": cost}


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
				_spawn_produced_unit(p["id"])
				production[cat] = {}
				ui.toast("%s prêt !" % item_name, GameData.GREEN)
			else:
				p["ready"] = true
				ui.toast("%s prêt — cliquez sur l'icône pour le poser" % item_name, GameData.GREEN)


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
	b.setup(id, cell, d["size"], TILE, d["power"], fdata["color"])
	add_child(b)
	buildings.append(b)
	for c in b.cells():
		occupied[c] = true
		grid.set_point_solid(c, true)


func _place_start_base() -> void:
	_place_building("chantier", Vector2i(31, 30))
	_place_building("centrale", Vector2i(28, 30))
	_place_building("raffinerie", Vector2i(35, 31))
	_place_building("fonderie", Vector2i(28, 33))


func _spawn_produced_unit(id: String) -> void:
	var from_id: String = GameData.def(id)["from"]
	_spawn_unit(id, _find_free_cell(_dock_of(from_id)))


func _dock_of(building_id: String) -> Vector2i:
	var s := Vector2i(int(START.x), int(START.y))
	for b in buildings:
		if b.id == building_id:
			return dock_cell(b, s)
	return s


func _spawn_start_units() -> void:
	_spawn_unit("recolteur", _find_free_cell(_dock_of("raffinerie")))
	_spawn_unit("mineur", _find_free_cell(_dock_of("fonderie")))
	var ids: Array = fdata["units"]
	for i in 2:
		_spawn_unit(ids[i], _find_free_cell(Vector2i(31 + i * 2, 35)))


func _spawn_unit(id: String, cell: Vector2i) -> void:
	var u := Unit.new()
	u.setup(id, self, fdata["color"])
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


func is_sand_at(world: Vector2) -> bool:
	var c := _world_to_cell(world)
	var t: int = terrain[c.x][c.y]
	return t == T.SAND or t == T.SPICE


func path_to(from_world: Vector2, to_cell: Vector2i) -> PackedVector2Array:
	return grid.get_point_path(_world_to_cell(from_world), to_cell)


func world_to_cell(p: Vector2) -> Vector2i:
	return _world_to_cell(p)


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
