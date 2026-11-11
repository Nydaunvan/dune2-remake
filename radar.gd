class_name Radar
extends Control
## Radar circulaire : carte, unités, bâtiments et cadre de la caméra.
## Clic gauche / glisser : déplace la caméra. Clic droit : ordre de déplacement.

var game # le nœud principal (main.gd)
var world_size := Vector2(2048, 2048)
var map_rect := Rect2()
var _timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_timer += delta
	if _timer > 0.1:
		_timer = 0.0
		queue_redraw()


func _draw() -> void:
	if game == null:
		return
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 10.0
	draw_circle(c, r + 4.0, Color("120a16"))
	var side := r * 1.38 # le carré de la carte tient dans le cercle
	map_rect = Rect2(c - Vector2(side, side) / 2.0, Vector2(side, side))
	draw_texture_rect(game.map_texture, map_rect, false)

	for b in game.buildings:
		var rp := _to_radar(b.position)
		var rs := Vector2(b.cell_size * b.tile) / world_size * map_rect.size
		draw_rect(Rect2(rp, rs), Color("9fd0ff"))
	for u in game.units:
		draw_rect(Rect2(_to_radar(u.position) - Vector2(1.5, 1.5), Vector2(3, 3)), Color("5ad7ff"))

	# Cadre de la caméra
	var vp: Vector2 = game.get_viewport_rect().size / game.camera.zoom
	var top_left := _to_radar(game.camera.position - vp / 2.0)
	var cam := Rect2(top_left, vp / world_size * map_rect.size).intersection(map_rect)
	draw_rect(cam, Color.WHITE, false, 1.5)

	# Anneau décoratif
	draw_arc(c, r + 4.0, 0.0, TAU, 96, GameData.AMBER, 3.0, true)
	draw_arc(c, r - 1.0, 0.0, TAU, 96, Color("7a3a1a"), 2.0, true)
	for i in 36:
		var a := TAU * i / 36.0
		var long := 7.0 if i % 3 == 0 else 3.0
		draw_line(c + Vector2.from_angle(a) * (r + 7.0),
				c + Vector2.from_angle(a) * (r + 7.0 + long), GameData.AMBER.darkened(0.2), 1.5)


func _to_radar(world: Vector2) -> Vector2:
	return map_rect.position + world / world_size * map_rect.size


func _to_world(p: Vector2) -> Vector2:
	return ((p - map_rect.position) / map_rect.size * world_size).clamp(Vector2.ZERO, world_size)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			game.center_camera(_to_world(event.position))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			game.order_move(_to_world(event.position))
		accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		game.center_camera(_to_world(event.position))
		accept_event()
