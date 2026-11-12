extends SceneTree
## Tuer tous les ennemis ne suffit pas : tous les objectifs de la mission doivent être remplis.
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mode = "campaign"
	GameSession.mission = 1 # destroy_all + train + harvest
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f < 30 or main.get("loading") != null:
		return false
	if f == 30:
		for u in main.units:
			if main.hostile(u.team, 0): u.alive = false
		for b in main.buildings:
			if main.hostile(b.team, 0): b.alive = false
		print("ennemis morts, objectifs=", main.objectives_status().map(func(o): return o["text"] + " " + str(o["done"])))
	if f == 120:
		print("over après destruction seule (attendu false): ", main.over)
		for i in main.mission["objectives"].size():
			main.obj_state[i]["done"] = true
	if f == 200:
		print("over objectifs remplis (attendu true): ", main.over)
		return true
	return false
