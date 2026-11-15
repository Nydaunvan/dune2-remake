extends SceneTree
## Captures : moissonneuse sur la rampe de la raffinerie (déchargement) et char sur le centre de réparation. xvfb, opengl3.
var f := 0
var node
var h
var t
var rep
var shot := {}
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.instant_bases = true
	GameSession.mode = "skirmish"
	node = load("res://main.tscn").instantiate()
	root.add_child(node)
func _process(_d: float) -> bool:
	if node.get("loading") != null:
		return false
	f += 1
	var c := Vector2i(node.start_cell)
	if f == 5:
		node.tier = 9
		node.credits = 9000
		rep = node._place_building("reparation", c + Vector2i(10, -6), 0, false)
		h = node._spawn_unit("recolteur", node._find_free_cell(c + Vector2i(0, 6)), 0)
		h.cargo = h.cargo_cap
		h.cargo_kind = "spice"
		h._start_return()
		t = node._spawn_unit("brute", node._find_free_cell(c + Vector2i(10, 2)), 0)
		t.hp = t.max_hp * 0.3
		t.order_repair(rep)
		node.camera.zoom = Vector2(3.0, 3.0)
	if is_instance_valid(h) and h._dk == "work":
		node.center_camera(h.position + Vector2(0, -20))
		if not shot.has("h") and h._dk_t > 0.6:
			shot["h"] = true
			root.get_texture().get_image().save_png("/tmp/shots/dock_raff.png")
			print("saved raff")
	if is_instance_valid(t) and t._dk == "work" and shot.has("h") and not shot.has("t"):
		node.center_camera(t.position + Vector2(0, -20))
		shot["t"] = f + 8
	if shot.has("t") and f == shot["t"]:
		root.get_texture().get_image().save_png("/tmp/shots/dock_rep.png")
		print("saved rep")
		return true
	return f > 4000
