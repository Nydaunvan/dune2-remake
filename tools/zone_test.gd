extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 5:
		var near := Vector2i(main.start_cell) + Vector2i(6, 0)
		var far := Vector2i(main.start_cell) + Vector2i(30, 0)
		var res := {}
		for c in [near, far]:
			# cherche une case valide terrain-wise la plus proche
			res[c] = main._can_place("centrale", c)
		printerr("proche=", res[near], " loin=", res[far])
		printerr("mcv dans units_for: ", "mcv" in GameData.units_for("solis"), " cout ", main.item_cost("mcv"), " bloc ", main.unit_level_block("mcv"))
	return f > 8
