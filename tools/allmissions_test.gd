extends SceneTree
## Démarre une mission (FAC, MIS) et vérifie qu'elle se met en place sans erreur.
var main
var f := 0
func _initialize() -> void:
	GameSession.mode = "campaign"
	GameSession.mission = int(OS.get_environment("MIS"))
	GameSession.faction = OS.get_environment("FAC")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		var o: Array = main.objectives_status()
		print("%s/%d %s | ennemi=%s allié=%s | unités=%d bât=%d | obj=%s" % [OS.get_environment("FAC"), GameSession.mission, main.mission["title"], main.team_factions.get(1), main.team_factions.get(2), main.units.size(), main.buildings.size(), str(o.map(func(x): return x["text"]))])
		return true
	return false
