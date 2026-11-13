extends SceneTree
## Raffinerie / fonderie : des récolteurs qui déchargent pendant que d'autres sortent d'usine.
## Aucun récolteur plein ne doit rester bloqué (plus de 25 s d'attente sans décharger).
## Usage : KIND=recolteur|mineur  (GODOT --headless --fixed-fps 60 --script tools/dock_test.gd)
var main
var f := 0
var kind := "recolteur"
var wait := {}      # unité -> temps passé plein à attendre
var worst := 0.0
var spawned := 0
var last_spawn := 0.0
var t0 := 0.0
var _lastd := -1
func _initialize() -> void:
	GameSession.instant_bases = true
	if OS.has_environment("KIND"):
		kind = OS.get_environment("KIND")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	Engine.time_scale = 8.0
func _workers() -> Array:
	return main.units.filter(func(u): return u.team == 0 and u.id == kind and u.alive)
func _process(_d: float) -> bool:
	f += 1
	if main.get("loading") != null or f < 10:
		return false
	if t0 == 0.0:
		t0 = main.game_time
		# 4 récolteurs de départ, tous pleins, envoyés se vider
		var s: Vector2i = Vector2i(main.start_cell)
		for i in 3:
			main._spawn_unit(kind, main._find_free_cell(s + Vector2i(2 + i, 8)), 0)
		for u in _workers():
			u.cargo = u.cargo_cap
			u._start_return()
	var t: float = main.game_time - t0
	# une nouvelle unité sort de l'usine toutes les 2,5 s (pendant les déchargements)
	if t - last_spawn > 2.5 and spawned < 8:
		last_spawn = t
		spawned += 1
		var u = main.spawn_for(kind, 0)
		u.cargo = u.cargo_cap # la nouvelle unité part aussi se vider
	for u in _workers():
		if u.emerging:
			continue
		if u.cargo >= u.cargo_cap - 0.01 and u.state != "harvest":
			wait[u] = float(wait.get(u, 0.0)) + _d
		else:
			wait[u] = 0.0
		worst = maxf(worst, float(wait[u]))
	if int(t) % 30 == 0 and int(t) != _lastd:
		_lastd = int(t)
		for u in _workers():
			if float(wait.get(u, 0.0)) > 15.0:
				var dk = main.find_dock(u.cargo_kind, main.world_to_cell(u.position), 0)
				print("  t=", int(t), " attente=", int(wait[u]), " état=", u.state, " cargo=", int(u.cargo), " chemin=", u.path.size(), " cell=", main.world_to_cell(u.position), " dock=", main.dock_cell(dk, main.world_to_cell(u.position)), " blocked=", snappedf(u._blocked_t, 0.1), " emerging=", u.emerging)
	if t > 150.0:
		var n := 0
		var stuck := 0
		for u in _workers():
			n += 1
			if float(wait.get(u, 0.0)) > 25.0:
				stuck += 1
		print("DOCK ", kind, ": unités=", n, " bloquées=", stuck, " pire attente=", int(worst), " s", "  OK" if stuck == 0 and worst < 40.0 else "  ÉCHEC")
		quit()
		return true
	return false
