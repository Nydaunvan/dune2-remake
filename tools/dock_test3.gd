extends SceneTree
## La case de déchargement est occupée par un autre véhicule immobile : le récolteur plein doit quand même décharger.
var main
var f := 0
var kind := "recolteur"
var A
var t0 := 0.0
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
		for u in main.units.filter(func(u): return u.team == 0 and u.id == kind):
			u.queue_free(); main.units.erase(u)
		var dk = main.find_dock("spice" if kind == "recolteur" else "ore", Vector2i(main.start_cell), 0)
		# on remplit toutes les cases autour du dépôt avec des véhicules à l'arrêt, sauf deux
		var n := 0
		for x in range(dk.cell.x - 1, dk.cell.x + dk.cell_size.x + 1):
			for y in range(dk.cell.y - 1, dk.cell.y + dk.cell_size.y + 1):
				var c := Vector2i(x, y)
				if main._is_walkable(c) and not main._cell_has_unit(c) and n % 4 != 3:
					main._spawn_unit("egide", c, 0)
				n += 1
		A = main._spawn_unit(kind, main._find_free_cell(dk.cell + Vector2i(0, 10)), 0)
		A.cargo = A.cargo_cap
		A._start_return()
	if main.game_time - t0 > 60.0:
		print("DOCK3 ", kind, " cargo=", int(A.cargo), "  OK" if A.cargo <= 0.0 or A.state == "harvest" or A.state == "seek" else "  ÉCHEC")
		quit(); return true
	return false
