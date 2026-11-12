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
	var r := minf(size.x, size.y) / 2.0 - 16.0
	map_rect = Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
	var t := Time.get_ticks_msec() / 1000.0
	var acc: Color = GameData.CYAN

	# Halo diffus et fond « verre » sombre
	for k in 6:
		draw_circle(c, r + 18.0 - k * 2.5, Color(acc.r, acc.g, acc.b, 0.025 + k * 0.012))
	draw_circle(c, r + 4.0, Color(0.03, 0.02, 0.07, 0.96))

	# Carte découpée en disque + brouillard
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 96:
		var pt := c + Vector2.from_angle(TAU * i / 96.0) * r
		pts.append(pt)
		uvs.append((pt - map_rect.position) / map_rect.size)
	draw_colored_polygon(pts, Color(1, 1, 1, 0.95), uvs, game.map_texture)
	if game.fog_radar_tex != null:
		draw_colored_polygon(pts, Color.WHITE, uvs, game.fog_radar_tex)

	# Grille discrète : anneaux de portée et axes
	var grid := Color(acc.r, acc.g, acc.b, 0.13)
	for f in [0.33, 0.66]:
		draw_arc(c, r * f, 0.0, TAU, 64, grid, 1.0, true)
	draw_line(c - Vector2(r, 0), c + Vector2(r, 0), grid, 1.0)
	draw_line(c - Vector2(0, r), c + Vector2(0, r), grid, 1.0)

	# Bâtiments (rien d'hostile tant que non repéré)
	for b in game.buildings:
		if not b.alive:
			continue
		if game.hostile(b.team, 0) and not b.visible:
			continue
		var rp := _to_radar(b.position)
		var rs := Vector2(b.cell_size * b.tile) / world_size * map_rect.size
		var col := _team_color(b.team)
		var rc := Rect2(rp, rs)
		if (rc.get_center() - c).length() > r:
			continue
		draw_rect(rc, Color(col.r, col.g, col.b, 0.85))
		draw_rect(rc, Color(1, 1, 1, 0.55), false, 1.0)

	# Unités (hostiles : seulement si actuellement vues)
	for u in game.units:
		if not u.alive or u.carried:
			continue
		if game.hostile(u.team, 0) and not u.seen:
			continue
		var up := _to_radar(u.position)
		if up.distance_to(c) < r - 2.0:
			var uc := _team_color(u.team)
			draw_circle(up, 3.4, Color(0, 0, 0, 0.55))
			draw_circle(up, 2.3, uc)

	# Repères de mission
	if game.markers != null:
		for m in game.markers.points():
			var mp := _to_radar(m["pos"])
			var mc: Color = m["color"]
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_arc(mp, maxf(m["radius"] / world_size.x * map_rect.size.x, 4.0), 0.0, TAU, 24,
					Color(mc.r, mc.g, mc.b, 0.55 + 0.45 * pulse), 2.0, true)

	# Ver géant : zone de danger
	var wz: Dictionary = game.worm_zone()
	if not wz.is_empty():
		var wc := _to_radar(wz["center"])
		var wr: float = float(wz["radius"]) / world_size.x * map_rect.size.x
		var blink := 0.5 + 0.5 * sin(t * 5.0)
		draw_circle(wc, wr, Color(1.0, 0.15, 0.1, 0.16 + 0.12 * blink))
		draw_arc(wc, wr, 0.0, TAU, 32, Color(1.0, 0.35, 0.25, 0.7 + 0.3 * blink), 2.0, true)

	# Balayage doux
	var a0 := t * 1.6
	for k in 22:
		var a := a0 - k * 0.04
		draw_line(c, c + Vector2.from_angle(a) * r,
				Color(acc.r, acc.g, acc.b, (1.0 - k / 22.0) * 0.22), 3.0, true)
	draw_line(c, c + Vector2.from_angle(a0) * r, Color(acc.r, acc.g, acc.b, 0.55), 1.2, true)

	# Cadre de caméra à coins marqués
	var vp: Vector2 = game.get_viewport_rect().size / game.camera.zoom
	var top_left := _to_radar(game.camera.position - vp / 2.0)
	var cam := Rect2(top_left, vp / world_size * map_rect.size).intersection(map_rect)
	draw_rect(cam, Color(1, 1, 1, 0.16))
	draw_rect(cam, Color(1, 1, 1, 0.55), false, 1.0)
	var cl := minf(8.0, minf(cam.size.x, cam.size.y) / 2.0)
	for corner in [[cam.position, Vector2(1, 0), Vector2(0, 1)],
			[cam.position + Vector2(cam.size.x, 0), Vector2(-1, 0), Vector2(0, 1)],
			[cam.position + Vector2(0, cam.size.y), Vector2(1, 0), Vector2(0, -1)],
			[cam.end, Vector2(-1, 0), Vector2(0, -1)]]:
		draw_line(corner[0], corner[0] + corner[1] * cl, Color.WHITE, 2.0)
		draw_line(corner[0], corner[0] + corner[2] * cl, Color.WHITE, 2.0)

	# Anneau fin, liseré intérieur et graduations
	draw_arc(c, r + 1.0, 0.0, TAU, 128, Color(0, 0, 0, 0.6), 3.0, true)
	draw_arc(c, r + 4.0, 0.0, TAU, 128, Color(acc.r, acc.g, acc.b, 0.95), 2.0, true)
	draw_arc(c, r + 9.0, 0.0, TAU, 128, Color(1, 1, 1, 0.12), 1.0, true)
	for i in 72:
		var a := TAU * i / 72.0
		var major := i % 18 == 0
		var l := 8.0 if major else (4.0 if i % 6 == 0 else 2.0)
		draw_line(c + Vector2.from_angle(a) * (r + 10.0),
				c + Vector2.from_angle(a) * (r + 10.0 + l),
				Color(acc.r, acc.g, acc.b, 0.8) if major else Color(1, 1, 1, 0.3), 1.5 if major else 1.0, true)
	# Repère nord
	var nf := ThemeDB.fallback_font
	draw_string(nf, Vector2(c.x - 4.0, 11.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.85))


func _team_color(team: int) -> Color:
	if game.side_of(team) == 0:
		return Color(0.55, 0.85, 1.0) if team == 0 else Color(0.5, 1.0, 0.6)
	return Color(1.0, 0.35, 0.3)


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
