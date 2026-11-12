extends SceneTree
## Ressources de départ d'escarmouche (FAC) avec le réglage RÉDUITES : le minimum vital doit être finançable.
var main
var f := 0
func _initialize() -> void:
	GameSession.mode = "skirmish"
	GameSession.skirm_res = 0.6
	GameSession.faction = OS.get_environment("FAC")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		var sol := 0
		var ore := 0
		for b in ["centrale", "raffinerie", "fonderie"]:
			sol += GameData.sol_cost(b); ore += int(GameData.def(b)["cost"])
		for u in ["recolteur", "mineur"]:
			sol += main.item_cost(u); ore += main.item_ore(u)
		print("%s: Solaris %d (besoin %d) minerai %d (besoin %d) -> %s" % [OS.get_environment("FAC"), main.credits, sol, main.ore, ore, "OK" if main.credits >= sol and main.ore >= ore else "INSUFFISANT"])
		return true
	return false
