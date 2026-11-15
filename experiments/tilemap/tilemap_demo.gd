extends Node2D
## Essai : une carte de désert peinte en TileMapLayer (sable, roche, épice, dunes), générée par bruit.
## Flèches / ZQSD : déplacer la caméra ; clic : affiche la tuile (type, constructible, vitesse).
const SIZE := 192
const TILESET := preload("res://experiments/tilemap/world_tileset.tres")

var layer: TileMapLayer
var cam: Camera2D
var label: Label


func _ready() -> void:
	generate(SIZE, 1234)
	cam = Camera2D.new()
	cam.position = Vector2(SIZE, SIZE) * 16.0
	add_child(cam)
	var cl := CanvasLayer.new()
	add_child(cl)
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 20)
	label.text = "TileMapLayer — flèches : caméra, clic : tuile"
	cl.add_child(label)


func generate(size: int, seed_v: int) -> float:
	if layer == null:
		layer = TileMapLayer.new()
		layer.tile_set = TILESET
		add_child(layer)
	var t0 := Time.get_ticks_usec()
	var height := FastNoiseLite.new()
	height.seed = seed_v
	height.frequency = 0.018
	var detail := FastNoiseLite.new()
	detail.seed = seed_v + 1
	detail.frequency = 0.09
	var spice := FastNoiseLite.new()
	spice.seed = seed_v + 2
	spice.frequency = 0.035
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for y in size:
		for x in size:
			var h := height.get_noise_2d(x, y)
			var det := detail.get_noise_2d(x, y)
			var atlas := Vector2i(rng.randi() % 2, 0) # sable A / B
			if h > 0.34:
				atlas = Vector2i(2, 1) # roche profonde
			elif h > 0.2:
				atlas = Vector2i(2, 0) # roche
			elif spice.get_noise_2d(x, y) > 0.42:
				atlas = Vector2i(3, 0) # épice
			elif det > 0.25:
				atlas = Vector2i(0 + rng.randi() % 2, 1) # dunes
			elif det < -0.3:
				atlas = Vector2i(3, 1) # sable sombre
			layer.set_cell(Vector2i(x, y), 0, atlas)
	return (Time.get_ticks_usec() - t0) / 1000.0


func _process(delta: float) -> void:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	cam.position += v * 900.0 * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := layer.local_to_map(layer.get_local_mouse_position())
		var d := layer.get_cell_tile_data(cell)
		if d:
			label.text = "Case %s : %s — constructible : %s — vitesse ×%.1f" % [cell, d.get_custom_data("kind"), d.get_custom_data("buildable"), d.get_custom_data("speed")]
