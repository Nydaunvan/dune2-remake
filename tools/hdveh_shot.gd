extends SceneTree
## Jeu réel, véhicules HD : tanks (tourelle indépendante) + mécha + roues, en action. xvfb, opengl3.
var f := 0
var node
var us: Array = []
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
	var c: Vector2i = node.start_cell
	if f == 5:
		node.hide_fog_for_test() if node.has_method("hide_fog_for_test") else null
		var ids: Array = ["brute", "sentinelle", "egide", "ombre", "prisme"]
		for i in ids.size():
			var u = node._spawn_unit(ids[i], node._find_free_cell(c + Vector2i(-4 + i * 2, 9)), 0)
			us.append(u)
		var mc: Array = []
		for uid in GameData.FACTIONS[node.faction_id]["units"]:
			if ModelsExt.STYLES.get(uid, {}).get("k", "") == "mech":
				mc.append(uid)
		for m in mc.slice(0, 2):
			us.append(node._spawn_unit(m, node._find_free_cell(c + Vector2i(-2 + us.size(), 12)), 0))
		var e = node._spawn_unit("vipere" if node.enemy_faction == "kharn" else GameData.FACTIONS[node.enemy_faction]["units"][2], node._find_free_cell(c + Vector2i(6, 11)), 1)
		e.max_hp = 1e6
		e.hp = 1e6
		node.camera.zoom = Vector2(3.0, 3.0)
		node.center_camera(Vector2(c + Vector2i(1, 10)) * 32.0)
	if f == 40:
		for u in us:
			u.order_amove(c + Vector2i(8, 11))
	for k in [30, 120, 220]:
		if f == k:
			for n in ["ui", "fog"]:
				pass
			root.get_texture().get_image().save_png("/tmp/shots/hdveh_%d.png" % k)
			print("saved ", k)
	return f >= 220
