extends SceneTree
## Profondeur : un véhicule au nord d'un bâtiment doit passer derrière, au sud devant.
var main
var f := 0
var u1
var u2
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.mode = "skirmish"
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 5:
		var b = null
		for x in main.buildings:
			if x.team == 0 and x.id == "usine":
				b = x
		if b == null:
			b = main.buildings[0]
		var cx: int = b.cell.x + b.cell_size.x / 2
		u1 = main.units[0]
		u2 = main.units[1] if main.units.size() > 1 else main.units[0]
		u1.position = Vector2(cx - 1, b.cell.y - 1) * 32.0 + Vector2(16, 20)
		u2.position = Vector2(cx + 1, b.cell.y + b.cell_size.y) * 32.0 + Vector2(16, 12)
		main.center_camera(Vector2(cx, b.cell.y + 1) * 32.0)
	if f == 40:
		print("z nord=", u1.z_index, " sud=", u2.z_index)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/shots/depth.png")
		quit()
	return false
