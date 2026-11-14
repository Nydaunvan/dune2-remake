extends SceneTree
## Un mécha en marche dans une vraie partie : image de marche utilisée, aucune erreur.
var main
var f := 0
var u
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.mode = "skirmish"
	GameSession.faction = "vael"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 5:
		u = main._spawn_unit("tarentule", main._find_free_cell(Vector2i(main.start_cell) + Vector2i(0, 6)), 0)
		main.center_camera(u.position)
	if f == 15:
		main.order_unit_move(u, u.position + Vector2(400, 60))
	if f == 120:
		var seen := {}
		print("walk_idx=", u._walk_idx, " walk=", snappedf(u._walk, 0.1), " stride=", snappedf(u._stride, 0.1), " bank_has_w0=", main.bank.has("tarentule|vael|w0"))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/shots/walk_game.png")
		quit()
	return false
