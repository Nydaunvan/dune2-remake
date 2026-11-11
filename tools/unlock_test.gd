extends SceneTree
## Bâtiments débloqués : verrous par mission/faction, placement, soins, revenus, silos.
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = OS.get_environment("FAC") if OS.get_environment("FAC") != "" else "vael"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		print("faction ", main.faction_id, " tier ", main.tier)
		for id in GameData.buildings_for(main.faction_id):
			print(id, " débloqué=", main.is_unlocked(id), " dispo=", main.is_available(id))
		main.tier = 9
		main.ore = 9000
		var i := 0
		for id in GameData.buildings_for(main.faction_id):
			if GameData.def(id).get("unlock", 0) == 0:
				continue
			var c: Vector2i = Vector2i(main.start_cell) + Vector2i(-12 + (i % 6) * 4, 10 + (i / 6) * 4)
			main._place_building(id, c, 0)
			i += 1
		print("placés; énergie libre=", main.power_free(), " ok=", main.power_ok())
		var u = main.units.filter(func(x): return x.team == 0 and x.role == "combat")
		if not u.is_empty():
			u[0].hp = 10.0
			u[0].position = main.start_cell * 32.0 + Vector2(-12 * 32 + 20, 10 * 32 + 20)
		print("bonus silo=", main.income_bonus("spice"))
		main.credits = 0
	if f == 120:
		print("crédits après revenus=", main.credits)
		return true
	return false
