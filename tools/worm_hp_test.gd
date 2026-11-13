extends SceneTree
## Ver : vie persistante, tir des unités (même enfoui), mort. godot --headless --fixed-fps 60 --script tools/worm_hp_test.gd
var main
var frame := 0
var shooters: Array = []


func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "kharn"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame == 3:
		main._worm_pick()
		print("roster: ", main.worm_roster)
		for r in main.worm_roster:
			r["hp"] = 300.0
		var prey = null
		var sc: Vector2i = main.start_cell
		for r in range(6, 40):
			for a in 16:
				var cc: Vector2i = sc + Vector2i(Vector2.from_angle(TAU * a / 16.0) * r)
				if main.worm_ok_cell(cc) and main._is_walkable(cc) and main.worm_spawn_point(main._cell_to_world(cc), 20, 36).x >= 0.0:
					prey = main._spawn_unit("recolteur", cc, 0)
					break
			if prey != null:
				break
		print("proie: ", prey)
		# cible sur le sable : on cherche une case sable libre pour la proie
		main._spawn_worm(prey)
		print("ver créé: ", main.worm != null, " idx=", main.worm.idx if main.worm else -1)
		var c: Vector2i = main.world_to_cell(main.worm.position)
		for i in 8:
			var u = main._spawn_unit("gladiateur" if i % 2 == 0 else "titan", main._find_free_cell(c + Vector2i(-4 + i, 3)), 0)
			shooters.append(u)
			u.order_amove(c)
	if frame % 300 == 0 and main.worm != null:
		print("t=%d phase=%s hp=%d alive=%s" % [frame, main.worm.phase, int(main.worm.hp), main.worm.alive])
	if frame >= 2400:
		print("fin: ver=", main.worm, " roster=", main.worm_roster, " cooldown=", int(main.worm_cooldown))
		quit()
		return true
	return false
