extends SceneTree
## Tests de combat sans affichage.
##   SCENARIO=duel : deux petits groupes s'affrontent (dégâts, mort, projectiles)
##   SCENARIO=sim  : partie complète, joueur passif, on observe l'IA (défaut)
## godot --headless --fixed-fps 60 --path . --script tools/combat_test.gd

var main
var frame := 0
var scenario := "sim"
var minutes := 8


func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.mode = "skirmish"
	if OS.has_environment("SCENARIO"):
		scenario = OS.get_environment("SCENARIO")
	if OS.has_environment("MINUTES"):
		minutes = int(OS.get_environment("MINUTES"))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		var a: Vector2i = main._find_free_cell(Vector2i(main.START) + Vector2i(0, 4))
		var b: Vector2i = main._find_free_cell(Vector2i(main.ENEMY_START) + Vector2i(0, 4))
		var p: PackedVector2Array = main.grid.get_point_path(a, b)
		print("chemin base->base : %d points (%s vs %s)" % [p.size(), main.faction_id, main.enemy_faction])
		var s: PackedVector2Array = main.grid.get_point_path(b, Vector2i(53, 29))
		print("chemin ennemi->épice : %d points" % s.size())
		if scenario == "duel":
			_setup_duel()
		if scenario == "victory":
			for eb in main.buildings.duplicate():
				if eb.team == 1:
					eb.take_damage(99999.0, "cannon", null)
			print("victoire déclenchée : fini=%s" % str(main.over))
			return true
	if scenario == "duel":
		return _run_duel()
	return _run_sim()


func _units_of(team: int, role := "") -> Array:
	return main.units.filter(func(u: Unit) -> bool: return u.team == team and (role == "" or u.role == role))


func _setup_duel() -> void:
	# On vide l'IA et on place deux groupes face à face au milieu de la carte
	main.ai.active = false
	for u in main.units.duplicate():
		u._die()
	var mid := Vector2i(24, 12)
	for i in 3:
		main._spawn_unit(main.fdata["units"][1], mid + Vector2i(0, i * 2), 0)
	var enemy_ids: Array = main.ai.fdata["units"]
	for i in 3:
		main._spawn_unit(enemy_ids[i % 3], mid + Vector2i(7, i * 2), 1)
	print("duel : %d alliés vs %d ennemis (%s)" % [_units_of(0).size(), _units_of(1).size(), ",".join(enemy_ids)])
	for u in _units_of(0):
		u.order_amove(mid + Vector2i(8, 2))


func _run_duel() -> bool:
	if frame % 300 == 0:
		var mine := _units_of(0).map(func(u: Unit) -> String: return "%s:%d" % [u.id, int(u.hp)])
		var theirs := _units_of(1).map(func(u: Unit) -> String: return "%s:%d" % [u.id, int(u.hp)])
		print("[t=%ds] alliés=%s ennemis=%s" % [frame / 60, mine, theirs])
	if frame >= 3600:
		print("FIN DUEL")
		return true
	return false


func _run_sim() -> bool:
	if frame % 1800 == 0:
		var ai: SkirmishAI = main.ai
		var names := {}
		for b in main.buildings:
			var k := "%s%d" % [b.id, b.team]
			names[k] = int(names.get(k, 0)) + 1
		var mine_hp := 0
		for b in main.buildings:
			if b.team == 0:
				mine_hp += int(b.hp)
		print("[t=%dmin%02d] IA $%d min%d | armée IA=%d joueur=%d | assaut=%s | bâtiments=%s | hp base joueur=%d | fini=%s" % [
				frame / 3600, (frame / 60) % 60, ai.credits, ai.ore, ai._army().size(),
				_units_of(0, "combat").size(), str(ai.assaulting), str(names), mine_hp, str(main.over)])
	if main.over or frame >= minutes * 3600:
		print("FIN SIM — fini=%s" % str(main.over))
		return true
	return false
