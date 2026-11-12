extends SceneTree
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
		var b = main.buildings.filter(func(x): return x.team == 0 and x.id == "centrale")[0]
		var o: float = main.ore; var c: float = main.credits
		main.demolish_building(b)
		print("minerai +", main.ore - o, " solaris +", main.credits - c, " (coût ", GameData.base_cost("centrale"), "/", GameData.sol_cost("centrale"), ")")
		quit()
	return false
