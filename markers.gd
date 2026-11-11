class_name MissionMarkers
extends Node2D
## Repères de mission dessinés au-dessus du brouillard : zone à tenir, destination du convoi.

var game


func _init(p_game) -> void:
	game = p_game
	z_index = 50


## Repères actifs : [{pos (monde), color, radius (px), kind}]
func points() -> Array:
	var out: Array = []
	if game.mission.is_empty():
		return out
	var tile: float = game.TILE
	if game.mission_points.has("zone"):
		var done: bool = game.zone_done
		out.append({"pos": game.mission_points["zone"] * tile + Vector2(tile, tile) * 0.5,
				"color": GameData.GREEN if done else GameData.GOLD, "radius": game.ZONE_RADIUS * tile, "kind": "zone"})
	if game.mission_points.has("dest") and not game.escort_done:
		out.append({"pos": game.mission_points["dest"] * tile + Vector2(tile, tile) * 0.5,
				"color": GameData.CYAN, "radius": 3.0 * tile, "kind": "dest"})
	return out


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for p in points():
		var c: Color = p["color"]
		var r: float = p["radius"]
		draw_arc(p["pos"], r, 0.0, TAU, 64, Color(c.r, c.g, c.b, 0.55 + 0.25 * sin(t * 3.0)), 3.0, true)
		draw_arc(p["pos"], r * 0.6, 0.0, TAU, 48, Color(c.r, c.g, c.b, 0.25), 2.0, true)
		if p["kind"] == "dest":
			var q: Vector2 = p["pos"]
			draw_colored_polygon(PackedVector2Array([q + Vector2(0, -14), q + Vector2(14, 0), q + Vector2(0, 14), q + Vector2(-14, 0)]),
					Color(c.r, c.g, c.b, 0.6))
