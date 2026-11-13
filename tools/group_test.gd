extends SceneTree
## Mesure les déplacements de groupe : 12 véhicules reçoivent un ordre de déplacement (loin, à travers
## la carte et ses montagnes) puis un ordre d'attaque. Mesure : temps d'arrivée du premier et du dernier,
## chevauchements à l'arrivée, unités bloquées, temps avant que tout le monde tire.
## Env : SEED (carte), N (12), IDS (unités séparées par des virgules).
var main
var frame := 0
var group: Array = []
var phase := 0
var t0 := 0.0
var goal := Vector2.ZERO
var first_arr := -1.0
var foe
var ideal := 0.0
var report := {}
func _env(k: String, d: String) -> String:
	return OS.get_environment(k) if OS.has_environment(k) else d
func _initialize() -> void:
	seed(int(_env("SEED", "3")))
	GameSession.mode = "skirmish"
	GameSession.faction = "solis"
	GameSession.skirm_foe = "kharn"
	GameSession.skirm_size = 96
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _overlaps() -> int:
	var n := 0
	for i in group.size():
		for j in range(i + 1, group.size()):
			if group[i].position.distance_to(group[j].position) < 17.0:
				n += 1
	return n
func _arrived(u) -> bool:
	return u.path.is_empty() and u.state == "idle"
func _process(_d: float) -> bool:
	frame += 1
	if frame > 4000 or (frame > 30 and phase == 0):
		print("GROUPE ÉCHEC : test interrompu (phase %d)" % phase)
		return true
	if frame == 5:
		for a in main.ais.values():
			a.active = false
		for u in main.units.duplicate():
			if u.team != 0:
				u.alive = false
				main.units.erase(u)
				u.queue_free()
		var ids: Array = _env("IDS", "egide,egide,egide,egide,sentinelle,sentinelle,sentinelle,sentinelle,pisteur,pisteur,citadelle,citadelle").split(",")
		var n := int(_env("N", "12"))
		var c := Vector2i(main.start_cell) + Vector2i(0, 6)
		for i in n:
			var u = main._spawn_unit(ids[i % ids.size()], main._find_free_cell(c + Vector2i(i % 4, i / 4)), 0)
			group.append(u)
		main.selected.clear()
		for u in group:
			main.selected.append(u)
		# cible : près de la base adverse (trajet long, à travers le relief)
		var gc: Vector2i = main._find_free_cell(Vector2i(main.enemy_cell) + Vector2i(0, -8))
		goal = main._cell_to_world(gc)
		var p: PackedVector2Array = main.path_to(group[0].position, gc)
		for i in range(1, p.size()):
			ideal += p[i - 1].distance_to(p[i])
		main.order_move(goal)
		t0 = main.game_time
		Engine.time_scale = 6.0
		phase = 1
		return false
	if phase == 1 and frame % 6 == 0:
		var t: float = main.game_time - t0
		var arr := 0
		for u in group:
			if _arrived(u):
				arr += 1
		if arr > 0 and first_arr < 0.0:
			first_arr = t
		if OS.has_environment("DBG") and frame % 120 == 0:
			var st := {}
			for u in group:
				var k: String = u.state + ("+" if not u.path.is_empty() else "")
				st[k] = int(st.get(k, 0)) + 1
			print("t=%.0f arr=%d %s" % [t, arr, str(st)])
		if arr == group.size() or t > 150.0:
			var slowest := 999.0
			for u in group:
				slowest = minf(slowest, u.speed)
			var far := 0
			var maxd := 0.0
			for u in group:
				var d: float = u.position.distance_to(goal)
				maxd = maxf(maxd, d)
				if d > 5.0 * main.TILE:
					far += 1
			report["move"] = "arrivés %d/%d, premier %.0f s, dernier %.0f s (trajet idéal du plus lent %.0f s), chevauchements %d, loin du but %d, écart max %.1f cases" % [arr, group.size(), first_arr, t, ideal / slowest, _overlaps(), far, maxd / main.TILE]
			# phase 2 : attaque d'une cible
			foe = main._place_building("centrale", main._find_free_cell(Vector2i(main.enemy_cell) + Vector2i(6, 6)), 1, false) if main.count_buildings("centrale", 1) == 0 else null
			if foe == null:
				for b in main.buildings:
					if b.team == 1:
						foe = b
			foe.max_hp = 1000000.0
			foe.hp = foe.max_hp
			for u in group:
				u.order_attack(foe)
			t0 = main.game_time
			phase = 2
		return false
	if phase == 2 and frame % 6 == 0:
		var t: float = main.game_time - t0
		var firing := 0
		group = group.filter(func(u) -> bool: return is_instance_valid(u) and u.alive and not u.eaten)  # un ver peut passer par là
		for u in group:
			if u.alive and u.position.distance_to(foe.world_center()) <= u.w_range + foe.radius_px() + 4.0 and u.path.is_empty():
				firing += 1
		if firing == group.size() or t > 60.0:
			for u in group:
				if not (u.alive and u.position.distance_to(foe.world_center()) <= u.w_range + foe.radius_px() + 4.0 and u.path.is_empty()):
					print("  pas en position : %s état=%s chemin=%d distance=%.0f portée=%.0f rayon cible=%.0f" % [u.id, u.state, u.path.size(), u.position.distance_to(foe.world_center()), u.w_range, foe.radius_px()])
			report["attack"] = "en position de tir %d/%d après %.0f s, chevauchements %d" % [firing, group.size(), t, _overlaps()]
			print("GROUPE déplacement : ", report["move"])
			print("GROUPE attaque     : ", report["attack"])
			var ok: bool = report["move"].begins_with("arrivés %d/%d" % [group.size(), group.size()]) and report["attack"].begins_with("en position de tir %d/%d" % [group.size(), group.size()]) and _overlaps() == 0
			print("GROUPE OK" if ok else "GROUPE ÉCHEC")
			return true
	return false
