extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		var u = main.units.filter(func(x): return x.team == 0 and x.id == "recolteur")[0]
		u.state = "harvest"
		u._harvest(0.1)
		print("fx on:", u._work_fx.emitting, u._work_fx2.emitting)
		return true
	return false
