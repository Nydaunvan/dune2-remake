extends SceneTree
## Rampes : une moissonneuse monte sur la rampe de la raffinerie, décharge en quelques secondes, redescend ; un véhicule blessé monte sur le centre de réparation.
## godot --headless --fixed-fps 60 --path . --script tools/dock_test.gd
var main
var frame := 0
var h
var phases := {}
var rot_end := 0.0
var progressive := false
var foot_cell := Vector2i(-1, -1)
var left_foot := false
var tank
var fails := 0
var ore0 := 0.0
var maxlift := 0.0
var saw_work := false
var emptied := false
var work_frames := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _check(ok: bool, msg: String) -> void:
	print(("OK  " if ok else "KO  ") + msg)
	if not ok:
		fails += 1
func _process(_d: float) -> bool:
	frame += 1
	if frame == 2:
		# bâtiments collés au pied de la rampe : la sortie doit rester possible
		for b in main.buildings:
			if b.id == "raffinerie" and b.team == 0:
				var q: Dictionary = Models.ramp_of("raffinerie", GameSession.faction)
				var foot: Vector2 = b.world_center() + Vector2(q["x"], q["z0"] + 4.0)
				var fc: Vector2i = main.world_to_cell(foot)
				for off in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(1, 1)]:
					main._place_building("mur", fc + off, 0, false)
				foot_cell = fc
				break
	if frame == 3:
		h = main._spawn_unit("recolteur", main._find_free_cell(Vector2i(main.start_cell) + Vector2i(0, 6)), 0)
		h.cargo = h.cargo_cap
		h.cargo_kind = "spice"
		ore0 = float(main.credits)
		h._start_return()
		print("état=", h.state, " cargo=", h.cargo)
	if frame > 3 and frame < 1500 and is_instance_valid(h):
		maxlift = maxf(maxlift, h.ramp_lift)
		if h._dk == "work":
			saw_work = true
			work_frames += 1
			if work_frames == 5:
				var rb = null
				for bb in main.buildings:
					if bb.id == "raffinerie" and bb.team == 0:
						rb = bb
				var q2: Dictionary = Models.ramp_of("raffinerie", GameSession.faction)
				var rel: Vector2 = h.position - rb.world_center()
				print("DOCK pos relative=", rel, " piste x=", q2.get("x"), " nez z=", q2.get("nose"), " (centre véhicule attendu z=", float(q2.get("nose", 0)) + h.radius, ")")
		phases[h._dk] = true
		if h._dk == "turn":
			rot_end = h.rotation
		if h._dk == "work":
			var cr := float(main.credits)
			if not progressive and cr > ore0 and h.cargo > 0.0:
				progressive = true # le compteur a monté alors que la benne n'est pas encore vide
		if h._dk == "down" and h.cargo == 0.0:
			emptied = true
		if h._dk == "" and saw_work and h.position.distance_to(Vector2(foot_cell) * 32.0 + Vector2(16, 16)) > 48.0:
			left_foot = true
	if frame == 1500:
		_check(saw_work, "la moissonneuse est montée sur la plaque et a déchargé")
		_check(maxlift > 3.0 or Models.ramp_of("raffinerie", GameSession.faction).has("nose"), "hauteur de rampe atteinte (%.1f px)" % maxlift)
		_check(work_frames > 60, "déchargement progressif (%d images, pas instantané)" % work_frames)
		_check(progressive, "le compteur de Solaris monte pendant le déchargement")
		_check(phases.has("align") and phases.has("turn"), "pivote face à la rampe puis fait demi-tour pour repartir (%s)" % str(phases.keys()))
		_check(absf(angle_difference(rot_end, -PI / 2.0)) > 1.0, "cap de sortie différent du cap de la rampe (%.0f°)" % rad_to_deg(rot_end))
		_check(emptied, "cargaison vidée avant la descente")
		_check(h._dk == "" and h.ramp_lift == 0.0, "redescendue (état %s, lift %.1f)" % [h._dk, h.ramp_lift])
		_check(left_foot, "la moissonneuse a pu repartir malgré les murs collés à la rampe (pos %s)" % str(h.position))
		_check(float(main.credits) > ore0, "crédits encaissés (%d -> %d)" % [int(ore0), int(main.credits)])
		if OS.has_environment("DOCK_ONLY"):
			print("Résultat : %d échec(s)" % fails)
			quit(1 if fails > 0 else 0)
			return true
		tank = main._spawn_unit("brute", main._find_free_cell(Vector2i(main.start_cell) + Vector2i(0, 8)), 0)
		tank.hp = tank.max_hp * 0.4
		var rep = null
		for b in main.buildings:
			if b.id == "reparation" and b.team == 0:
				rep = b
		if rep == null:
			rep = main._place_building("reparation", Vector2i(main.start_cell) + Vector2i(8, 12), 0, false)
		main.credits = 5000
		tank.order_repair(rep)
		maxlift = 0.0
		saw_work = false
	if frame > 1500 and frame < 3300 and is_instance_valid(tank):
		maxlift = maxf(maxlift, tank.ramp_lift)
		if tank._dk == "work":
			saw_work = true
	if frame == 3300:
		_check(saw_work, "le char est monté sur la plateforme de réparation")
		_check(tank.hp >= tank.max_hp - 1.0, "char réparé (%d/%d)" % [int(tank.hp), int(tank.max_hp)])
		_check(tank._dk == "" and tank.ramp_lift == 0.0, "redescendu")
		print("Résultat : %d échec(s)" % fails)
		quit(1 if fails > 0 else 0)
		return true
	return false
