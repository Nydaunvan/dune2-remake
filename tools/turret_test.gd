extends SceneTree
## Tourelle indépendante : la coque garde son cap pendant que la tourelle vise et tire ; retour dans l'axe sans cible.
## godot --headless --fixed-fps 60 --path . --script tools/turret_test.gd
var main
var frame := 0
var tank
var foe
var hull0 := 0.0
var fired := false
var hp0 := 0.0
var fails := 0
var _cd := 0.0


func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _check(ok: bool, msg: String) -> void:
	print(("OK  " if ok else "KO  ") + msg)
	if not ok:
		fails += 1


func _process(_d: float) -> bool:
	frame += 1
	if frame == 3:
		var c: Vector2i = main.start_cell
		tank = main._spawn_unit("brute", main._find_free_cell(c + Vector2i(0, 8)), 0)
		_check(tank.turret, "brute a une tourelle indépendante")
		tank.rotation = 0.0
		tank.turret_rot = 0.0
		hull0 = tank.rotation
		# cible à ~ 90° du cap de la coque, à portée
		var cell: Vector2i = main.world_to_cell(tank.position) + Vector2i(0, 4)
		foe = main._spawn_unit("vipere" if main.enemy_faction == "kharn" else GameData.FACTIONS[main.enemy_faction]["units"][2], main._find_free_cell(cell), 1)
		foe.max_hp = 100000.0
		foe.hp = 100000.0
		hp0 = foe.hp
		tank.order_attack(foe)
	if frame > 3 and frame < 200 and is_instance_valid(tank):
		var cd_now: float = tank.cooldown
		var just := cd_now > _cd
		_cd = cd_now
		if just and not fired:
			fired = true
			var want: float = (foe.position - tank.position).angle()
			_check(absf(angle_difference(tank.turret_rot, want)) < 0.3, "tir effectué avec la tourelle alignée sur la cible")
			_check(absf(angle_difference(tank.rotation, hull0)) < 0.05, "la coque n'a pas tourné (%.2f rad d'écart)" % absf(angle_difference(tank.rotation, hull0)))
	if frame == 200:
		_check(fired, "la brute a tiré sans orienter sa coque")
		tank.order_path(PackedVector2Array([tank.position]))
		foe.position += Vector2(6000, 6000)
		tank.position = Vector2(40, 40)
		tank.state = "idle"
		tank.target = null
	if frame == 330:
		print("  état=", tank.state, " rot=", tank.rotation, " tur=", tank.turret_rot, " aim_t=", tank._aim_t)
		_check(absf(angle_difference(tank.turret_rot, tank.rotation)) < 0.1, "tourelle revenue dans l'axe de la coque")
		print("Résultat : %d échec(s)" % fails)
		quit(1 if fails > 0 else 0)
		return true
	return false
