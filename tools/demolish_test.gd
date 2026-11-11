extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.ore = 1000
		var n0: int = main.buildings.size()
		for i in 4:
			main._place_building("mur", Vector2i(main.start_cell) + Vector2i(8, i), 0)
		var w = main.buildings.filter(func(b): return b.id == "mur")
		print("murs placés: ", w.size(), " bâtiments ", main.buildings.size())
		main.demolish_building(w[0])
		print("après démolition: ", main.buildings.size(), " minerai ", main.ore)
	if f == 20:
		return true
	return false
