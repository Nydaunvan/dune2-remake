extends Node2D

const TILE := 32
const MAP_W := 64
const MAP_H := 64
const CAM_SPEED := 700.0
const EDGE_SCROLL := true
const EDGE_MARGIN := 12

enum T { SAND, ROCK, MOUNTAIN, SPICE }
const COLORS := {
	T.SAND: Color("c9a25b"),
	T.ROCK: Color("8a7a66"),
	T.MOUNTAIN: Color("4f4638"),
	T.SPICE: Color("d0702a"),
}

var terrain: Array = []
var grid := AStarGrid2D.new()
var camera := Camera2D.new()
var units: Array[Unit] = []
var selected: Array[Unit] = []
var drag_start := Vector2.ZERO
var dragging := false


func _ready() -> void:
	_generate_terrain()
	_build_grid()
	_build_terrain_sprite()
	_setup_camera()
	_spawn_units()


# --- Génération -------------------------------------------------------------

func _generate_terrain() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.06
	var center := Vector2(MAP_W, MAP_H) / 2.0
	for x in MAP_W:
		terrain.append([])
		for y in MAP_H:
			var n := noise.get_noise_2d(x, y)
			var t := T.SAND
			if n > 0.4:
				t = T.MOUNTAIN
			elif n > 0.15:
				t = T.ROCK
			elif n < -0.35:
				t = T.SPICE
			# Zone de départ dégagée
			if Vector2(x, y).distance_to(center) < 6.0:
				t = T.SAND
			terrain[x].append(t)


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


func _build_terrain_sprite() -> void:
	# 1 pixel par case, agrandi : léger et sans asset
	var img := Image.create(MAP_W, MAP_H, false, Image.FORMAT_RGB8)
	for x in MAP_W:
		for y in MAP_H:
			img.set_pixel(x, y, COLORS[terrain[x][y]])
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.centered = false
	s.scale = Vector2(TILE, TILE)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = -10
	add_child(s)


func _setup_camera() -> void:
	camera.position = Vector2(MAP_W, MAP_H) * TILE / 2.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_W * TILE
	camera.limit_bottom = MAP_H * TILE
	add_child(camera)


@warning_ignore("integer_division")
func _spawn_units() -> void:
	var center := Vector2i(MAP_W / 2, MAP_H / 2)
	for i in 5:
		var u := Unit.new()
		u.position = _cell_to_world(center + Vector2i(i - 2, 0))
		add_child(u)
		units.append(u)


# --- Boucle -----------------------------------------------------------------

func _process(delta: float) -> void:
	# Flèches + ZQSD (touches physiques : fonctionne en AZERTY)
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right") + _key(KEY_D) - _key(KEY_A),
		Input.get_axis("ui_up", "ui_down") + _key(KEY_S) - _key(KEY_W))
	if EDGE_SCROLL and get_window().has_focus():
		var m := get_viewport().get_mouse_position()
		var size := get_viewport_rect().size
		if m.x < EDGE_MARGIN: dir.x -= 1
		if m.x > size.x - EDGE_MARGIN: dir.x += 1
		if m.y < EDGE_MARGIN: dir.y -= 1
		if m.y > size.y - EDGE_MARGIN: dir.y += 1
	camera.position += dir.limit_length(1.0) * CAM_SPEED / camera.zoom.x * delta
	if dragging:
		queue_redraw()


func _key(k: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(k) else 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					dragging = true
					drag_start = get_global_mouse_position()
				elif dragging:
					dragging = false
					_finish_selection(get_global_mouse_position())
					queue_redraw()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_order_move(get_global_mouse_position())
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed: _zoom(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed: _zoom(1.0 / 1.1)


func _zoom(factor: float) -> void:
	var z := clampf(camera.zoom.x * factor, 0.5, 2.0)
	camera.zoom = Vector2(z, z)


# --- Sélection & ordres -----------------------------------------------------

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


func _order_move(world_pos: Vector2) -> void:
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


# --- Utilitaires ------------------------------------------------------------

func _is_walkable(c: Vector2i) -> bool:
	return grid.is_in_boundsv(c) and not grid.is_point_solid(c)


func _world_to_cell(p: Vector2) -> Vector2i:
	var c := Vector2i((p / TILE).floor())
	return c.clamp(Vector2i.ZERO, Vector2i(MAP_W - 1, MAP_H - 1))


func _cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c) * TILE + Vector2(TILE, TILE) / 2.0


# --- Rendu ------------------------------------------------------------------

func _draw() -> void:
	if dragging:
		var r := Rect2(drag_start, get_global_mouse_position() - drag_start).abs()
		draw_rect(r, Color(0.3, 1.0, 0.3, 0.15))
		draw_rect(r, Color(0.3, 1.0, 0.3), false, 1.5)
