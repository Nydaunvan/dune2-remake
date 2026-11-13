extends SceneTree
## Un récolteur / mineur qui sort d'usine part directement vers son champ : pas de tour autour du bâtiment.
## Mesure : longueur parcourue / distance directe (ratio ≤ 1,6 attendu).
var main
var f := 0
var kind := "recolteur"
var u
var t0 := 0.0
var dist := 0.0
var last: Vector2
var start: Vector2
func _initialize() -> void:
	GameSession.instant_bases = true
	if OS.has_environment("KIND"):
		kind = OS.get_environment("KIND")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	Engine.time_scale = 6.0
func _process(_d: float) -> bool:
	f += 1
	if main.get("loading") != null or f < 10:
		return false
	if t0 == 0.0:
		t0 = main.game_time
		for w in main.units.filter(func(w): return w.team == 0 and w.id == kind):
			w.queue_free(); main.units.erase(w)
		u = main.spawn_for(kind, 0)
		last = u.position
		start = u.position
	dist += u.position.distance_to(last)
	last = u.position
	if u.state == "harvest" or main.game_time - t0 > 90.0:
		var direct := start.distance_to(u.position)
		var ratio := dist / maxf(direct, 1.0)
		print("SORTIE ", kind, " parcouru=", int(dist), " direct=", int(direct), " ratio=", snappedf(ratio, 0.01), "  OK" if ratio < 1.6 and u.state == "harvest" else "  ÉCHEC")
		quit(); return true
	return false
