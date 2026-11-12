extends SceneTree
## Un véhicule à l'arrêt barre la route : l'autre doit le contourner sans le pousser.
var main
var f := 0
var a
var b
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 10:
		var c := Vector2i(main.start_cell) + Vector2i(0, 8)
		a = main.spawn_for("sentinelle", 0)
		b = main.spawn_for("sentinelle", 0)
		a.position = main._cell_to_world(c)
		b.position = main._cell_to_world(c + Vector2i(4, 0))
		var bpos: Vector2 = b.position
		a.order_path(main.path_to(a.position, c + Vector2i(8, 0)))
		set_meta("bpos", bpos)
	if f == 1500:
		var bp: Vector2 = get_meta("bpos")
		print("a.path=", a.path, " state=", a.state, " blk=", a._blocked_t, " apos=", a.position, " bpos=", b.position); print("b déplacé de ", b.position.distance_to(bp), " ; a arrivé à ", a.position.distance_to(main._cell_to_world(Vector2i(main.start_cell) + Vector2i(8, 8))))
		return true
	return false
