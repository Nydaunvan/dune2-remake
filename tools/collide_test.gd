extends SceneTree
## Collisions : 10 unités lancées sur la même case ne doivent plus se chevaucher ; une colonne en marche passe.
var main
var f := 0
var group := []
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _overlap() -> float:
	var worst := 0.0
	for i in group.size():
		for j in range(i + 1, group.size()):
			var d: float = group[i].position.distance_to(group[j].position)
			var need: float = (group[i].radius + group[j].radius) * 0.92
			worst = maxf(worst, need - d)
	return worst
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		var c: Vector2i = Vector2i(main.start_cell) + Vector2i(6, 6)
		for i in 10:
			var u = main._spawn_unit("egide", c, 0)
			u.position = main._cell_to_world(c)
			group.append(u)
		print("recouvrement max au départ: ", snappedf(_overlap(), 0.1))
	if f == 60:
		print("après 1 s: ", snappedf(_overlap(), 0.1))
		for u in group:
			u.order_path(main.path_to(u.position, Vector2i(main.start_cell) + Vector2i(14, 8)))
	if f == 600:
		print("après trajet: recouvrement ", snappedf(_overlap(), 0.1), " arrivés: ", group.filter(func(u): return u.position.distance_to(main._cell_to_world(Vector2i(main.start_cell) + Vector2i(14, 8))) < 90.0).size(), "/10")
		return true
	return false
