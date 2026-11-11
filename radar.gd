class_name Radar
extends Control
## Radar tactique circulaire avec balayage animé.
## Clic gauche / glisser : déplace la caméra. Clic droit : ordre de déplacement.

var game # le nœud principal (main.gd)
var world_size := Vector2(2048, 2048)
var map_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 14.0
	map_rect = Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
	var t := Time.get_ticks_msec() / 1000.0

	# Fond + carte découpée en disque
	draw_circle(c, r + 3.0, Color("0b0714"))
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 64:
		var pt := c + Vector2.from_angle(TAU * i / 64.0) * r
		pts.append(pt)
		uvs.append((pt - map_rect.position) / map_rect.size)
	draw_colored_polygon(pts, Color(1, 1, 1, 0.92), uvs, game.map_texture)
	if game.fog_radar_tex != null: # brouillard de guerre sur la carte
		draw_colored_polygon(pts, Color.WHITE, uvs, game.fog_radar_tex)

	# Bâtiments et unités
	for b in game.buildings:
		if b.team != 0 and not b.visible:
			continue
		var rp := _to_radar(b.position)
		var rs := Vector2(b.cell_size * b.tile) / world_size * map_rect.size
		draw_rect(Rect2(rp, rs), Color(0.6, 0.85, 1.0) if b.team == 0 else Color(1.0, 0.35, 0.3))
	for u in game.units:
		if u.team != 0 and not u.seen:
			continue
		var up := _to_radar(u.position)
		if up.distance_to(c) < r:
			draw_circle(up, 2.6, GameData.CYAN if u.team == 0 else Color(2.0, 0.4, 0.3))

	# Ver géant (visible sur le radar une fois l'alerte donnée)
	if game.worm != null:
		var wp := _to_radar(game.worm.position)
		var blink := 0.5 + 0.5 * sin(t * 8.0)
		draw_circle(wp, 4.0 + blink * 3.0, Color(2.0, 0.3, 0.2, 0.9))
		draw_arc(wp, 9.0 + blink * 4.0, 0.0, TAU, 24, Color(2.0, 0.3, 0.2, 0.6), 1.5, true)

	# Balayage
	var a0 := t * 2.2
	for k in 14:
		var a := a0 - k * 0.05
		var alpha := (1.0 - k / 14.0) * 0.35
		draw_line(c, c + Vector2.from_angle(a) * r,
				Color(GameData.CYAN.r, GameData.CYAN.g, GameData.CYAN.b, alpha), 3.0, true)

	# Cadre de la caméra
	var vp: Vector2 = game.get_viewport_rect().size / game.camera.zoom
	var top_left := _to_radar(game.camera.position - vp / 2.0)
	var cam := Rect2(top_left, vp / world_size * map_rect.size).intersection(map_rect)
	draw_rect(cam, Color(1, 1, 1, 0.9), false, 1.5)

	# Anneaux néon et graduations
	draw_arc(c, r + 3.0, 0.0, TAU, 128, GameData.CYAN, 3.0, true)
	draw_arc(c, r + 10.0, 0.0, TAU, 128, Color(GameData.MAGENTA.r, GameData.MAGENTA.g, GameData.MAGENTA.b, 0.7), 1.5, true)
	for i in 36:
		var a := TAU * i / 36.0
		var l := 7.0 if i % 3 == 0 else 3.0
		draw_line(c + Vector2.from_angle(a) * (r + 12.0),
				c + Vector2.from_angle(a) * (r + 12.0 + l),
				Color(1, 1, 1, 0.45), 1.5, true)


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
