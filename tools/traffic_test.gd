extends SceneTree
## Deux colonnes qui se croisent : arrivée de tous, peu de recouvrement ; récolteur plein : va se vider.
var main
var f := 0
var A := []
var B := []
var wk
var d0 := 0.0
var ga: Vector2i
var gb: Vector2i
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _cnt(g: Array, goal: Vector2i) -> int:
	return g.filter(func(u): return u.position.distance_to(main._cell_to_world(goal)) < 130.0).size()
func _process(_d: float) -> bool:
	f += 1
	if main.get("loading") != null or f < 10:
		return false
	if f == 10:
		var s: Vector2i = Vector2i(main.start_cell)
		ga = s + Vector2i(4, 14)
		gb = s + Vector2i(18, 14)
		for i in 8:
			var ua = main._spawn_unit("egide", main._find_free_cell(ga + Vector2i(i % 2, i / 2)), 0)
			var ub = main._spawn_unit("egide", main._find_free_cell(gb + Vector2i(i % 2, i / 2)), 0)
			A.append(ua); B.append(ub)
		for u in A: d0 += u.position.distance_to(main._cell_to_world(gb))
		for u in B: d0 += u.position.distance_to(main._cell_to_world(ga))
		for u in A: u.order_path(main.path_to(u.position, gb))
		for u in B: u.order_path(main.path_to(u.position, ga))
		for u in main.units:
			if u.id == "recolteur" and u.team == 0:
				wk = u
		if wk != null:
			wk.cargo = wk.cargo_cap
			wk.state = "seek"
			wk._seek_started = false
	if wk != null and f == 25:
		print("récolteur plein: état=", wk.state, " cargo=", wk.cargo, "/", wk.cargo_cap, " path=", wk.path.size(), " dock=", main.find_dock(wk.cargo_kind, main.world_to_cell(wk.position), 0))
	if f == 1500:
		var d1 := 0.0
		for u in A: d1 += u.position.distance_to(main._cell_to_world(gb))
		for u in B: d1 += u.position.distance_to(main._cell_to_world(ga))
		var stuck := 0
		for u in A + B:
			if not u.path.is_empty() and u._blocked_t > 0.0: stuck += 1
		print("progression %d%%  bloqués %d  arrivés A %d B %d" % [int(100.0 * (1.0 - d1 / d0)), stuck, _cnt(A, gb), _cnt(B, ga)])
		return true
	return false
