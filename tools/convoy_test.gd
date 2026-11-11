extends SceneTree
## Convoi : départ différé, route dégagée, embuscades réduites.
var main
var f := 0
func _initialize() -> void:
	GameSession.mode = "campaign"
	GameSession.mission = 1
	GameSession.faction = "kharn"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		var g := 0
		for u in main.units:
			if u.team == 1 and u.guard:
				g += 1
		print("gardes d'embuscade: ", g, " convoi: ", main._convoy_alive(), " départ: ", main.mission["convoy"]["start"])
		main.game_time = 421.0
	if f == 60:
		var moving := 0
		for u in main.units:
			if u.convoy and u.path.size() > 0:
				moving += 1
		print("convoi en route: ", main.convoy_started, " camions avec chemin: ", moving)
		return true
	return false
