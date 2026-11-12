extends SceneTree
## Un ouvrier attaqué rentre à la base automatiquement.
var main
var f := 0
var w
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		for u in main.units:
			if u.team == 0 and u.is_worker():
				w = u
				break
		w.position += Vector2(600, 0)
		w.state = "harvest"
		print("avant : ", w.state)
		w.take_damage(5.0, "cannon", main.units.filter(func(x): return x.team != 0)[0])
		print("après coup : ", w.state, " chemin=", w.path.size())
	if f == 200:
		print("t+: ", w.state, " pos=", w.position, " hurt=", w._hurt_t)
	if f == 1200:
		print("fin : ", w.state, " hurt=", w._hurt_t)
		quit()
	return false
