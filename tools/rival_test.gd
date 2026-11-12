extends SceneTree
## Escarmouche à 3 camps : team 2 hostile ; l'IA 2 attaque le joueur ou team 1 ; victoire = les deux détruits.
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.opponents = 2
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 10:
		print("start")
		print("hostile 0-1:", main.hostile(0, 1), " 0-2:", main.hostile(0, 2), " 1-2:", main.hostile(1, 2), " 2-2:", main.hostile(2, 2))
		print("foes:", main.ais[1].foe, main.ais[2].foe, " factions:", main.team_factions)
		for b in main.buildings.duplicate():
			if b.team == 1:
				b.alive = false
		for u in main.units.duplicate():
			if u.team == 1:
				u.alive = false
		print("foes alive after team1 dead:", main._foes_alive())
		print("objectifs:", main.ui.objective_panel._items())
		var st: Dictionary = main._collect_state()
		print("saved third_hostile:", st["third_hostile"])
		return true
	return false
