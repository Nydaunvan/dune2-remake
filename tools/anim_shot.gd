extends SceneTree
## Captures des animations de bâtiments (radar, tour sonique, sortie d'usine) — nécessite xvfb.
var f := 0
var node
var u1
var u2
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.instant_bases = true
	node = load("res://main.tscn").instantiate()
	root.add_child(node)
func _process(_d: float) -> bool:
	if node.get("loading") != null:
		return false
	f += 1
	var o := Vector2i(node.start_cell)
	if f == 5:
		node.tier = 9
		node._place_building("radar", o + Vector2i(6, -12), 0, false)
		node._place_building("tour_sonique", o + Vector2i(10, -12), 0, false)
		node._place_building("usine", o + Vector2i(-6, -12), 0, false)
		node._place_building("aerodrome", o + Vector2i(-6, -7), 0, false)
		node.camera.zoom = Vector2(2.2, 2.2)
		node._place_building("reacteur", o + Vector2i(14, -12), 0, false)
		node._place_building("reacteur", o + Vector2i(18, -12), 0, false)
		node.center_camera((Vector2(o) + Vector2(2, -9)) * 32.0)
	if f == 20:
		u1 = node.spawn_for("egide" if node.faction_id == "solis" else GameData.FACTIONS[node.faction_id]["units"][1], 0)
		u2 = node.spawn_for(GameData.FACTIONS[node.faction_id]["air"][0], 0)
	for k in [6, 13, 20, 40]:
		if f == 20 + k:
			var out := "/tmp/shots/anim_%d.png" % k
			root.get_texture().get_image().save_png(out)
			print("saved ", out, " u1=", u1.position if u1 else "-", " em=", u1.emerging if u1 else "-")
	return f >= 20 + 40
