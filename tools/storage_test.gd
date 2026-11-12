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
		print("capacité Solaris=", main.storage_cap("spice"), " minerai=", main.storage_cap("ore"))
		main.credits = main.storage_cap("spice") - 100
		main.deposit("spice", 500.0, Vector2.ZERO, 0)
		print("après dépôt de 500 : ", main.credits, " (plafond ", main.storage_cap("spice"), ")")
		main._place_building("silo", Vector2i(main.start_cell) + Vector2i(-6, 8), 0)
		print("silo seul: Solaris=", main.storage_cap("spice"), " minerai=", main.storage_cap("ore"))
		main._place_building("silo_minerai", Vector2i(main.start_cell) + Vector2i(-6, 12), 0)
		print("bonus minerai=", main.income_bonus("ore"), " bloc='", main.building_block("silo_minerai"), "'")
		print("avec silo: Solaris=", main.storage_cap("spice"), " minerai=", main.storage_cap("ore"))
		return true
	return false
