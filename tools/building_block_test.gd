extends SceneTree
## Contraintes des bâtiments évolués : niveaux requis et nombre maximal.
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		for id in ["reacteur", "aerodrome", "batterie", "reparation", "radar", "tourelle", "tour_sonique", "relais_solaire"]:
			print(id, " -> '", main.building_block(id), "'")
		for b in main.buildings:
			if b.team == 0 and b.id in ["usine", "centrale"]:
				b.level = 2
		print("après niv.2 : reacteur='", main.building_block("reacteur"), "' aerodrome='", main.building_block("aerodrome"), "'")
		main._place_building("radar", Vector2i(30, 30), 0, false)
		main._place_building("radar", Vector2i(34, 30), 0, false)
		print("2 radars -> '", main.building_block("radar"), "'")
		quit()
	return false
