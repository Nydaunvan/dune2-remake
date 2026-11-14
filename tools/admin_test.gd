extends SceneTree
## Mode admin : ressources infinies, tout débloqué, file élargie ; retour à la normale à la désactivation.
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.mode = "skirmish"
	GameSession.faction = "kharn"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 3:
		var before := 0
		for id in GameData.BUILDINGS:
			if main.is_available(id): before += 1
		main.toggle_admin()
	if f == 6:
		var fac: String = main.faction_id
		var bad: Array = []
		var nb := 0
		for id in GameData.BUILDINGS:
			var d: Dictionary = GameData.BUILDINGS[id]
			if d.get("faction", "") in ["", fac]:
				nb += 1
				if not main.is_available(id): bad.append(id)
		var nu := 0
		for id in GameData.FACTIONS[fac]["units"] + GameData.FACTIONS[fac]["air"]:
			nu += 1
			if not main.is_available(id): bad.append(id)
		print("admin=", main.admin, " credits=", main.credits, " ore=", main.ore, " bâtiments=", nb, " unités=", nu, " indisponibles=", bad, " queue_max=", main.queue_max("unit"))
		main.credits = 5
		main.ore = 5
	if f == 9:
		print("après dépense: credits=", main.credits, " ore=", main.ore)
		main.toggle_admin()
		print("désactivé: admin=", main.admin, " credits=", main.credits, " dispo archonte/mastodonte=", main.is_available("mastodonte"))
		quit()
	return false
