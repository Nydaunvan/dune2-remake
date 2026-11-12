extends SceneTree
## Duels à budget égal entre unités (sans IA) : mesure la force brute des unités de chaque faction.
## Env : BUDGET (2400), IDS (liste « faction:unité » séparée par des virgules ; défaut : unités de base et intermédiaires).
var main
var frame := 0
var pairs: Array = []
var idx := -1
var t0 := 0.0
var res := {}
var entries: Array = []
var budget := 2400.0
func _initialize() -> void:
	seed(7)
	GameSession.mode = "skirmish"
	GameSession.auto_player = true
	GameSession.faction = "solis"
	GameSession.skirm_foe = "kharn"
	GameSession.skirm_size = 64
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if OS.has_environment("BUDGET"):
		budget = float(OS.get_environment("BUDGET"))
	if OS.has_environment("IDS"):
		for s in OS.get_environment("IDS").split(","):
			entries.append(s.split(":"))
	else:
		for f in ["solis", "kharn", "vael", "conclave"]:
			for id in GameData.FACTIONS[f]["units"]:
				var d: Dictionary = GameData.UNITS[id]
				if d.has("weapon") and int(d.get("level", 1)) <= 2 and float(d.get("vs_ground", 1.0)) >= 0.6 and d["weapon"] != "control":
					entries.append([f, id])
	for i in entries.size():
		for j in range(i + 1, entries.size()):
			if entries[i][0] != entries[j][0]:
				pairs.append([entries[i], entries[j]])
func _clear() -> void:
	for u in main.units.duplicate():
		u.alive = false
		main.units.erase(u)
		u.queue_free()
	for p in root.get_tree().get_nodes_in_group("projectiles"):
		p.queue_free()
func _spawn(e: Array, team: int, x0: int) -> void:
	main.team_factions[team] = e[0]
	var cost: float = float(GameData.UNITS[e[1]]["cost"]) * float(GameData.FACTIONS[e[0]]["unit_cost_mult"])
	var n := int(round(budget / cost))
	var c := Vector2i(main.map_w / 2 + x0, main.map_h / 2)
	for i in n:
		var cell: Vector2i = main._find_free_cell(c + Vector2i(0, (i % 7) - 3) + Vector2i(signi(x0) * (i / 7), 0))
		var u = main._spawn_unit(e[1], cell, team)
		u.order_amove(Vector2i(main.map_w / 2, main.map_h / 2))
func _val(team: int) -> float:
	var s := 0.0
	for u in main.units:
		if u.team == team and u.alive:
			s += u.hp / u.max_hp * float(GameData.UNITS[u.id]["cost"]) * float(GameData.FACTIONS[main.team_factions[team]]["unit_cost_mult"])
	return s / budget
func _next() -> bool:
	_clear()
	idx += 1
	if idx >= pairs.size():
		return false
	_spawn(pairs[idx][0], 0, -7)
	_spawn(pairs[idx][1], 1, 7)
	t0 = main.game_time
	return true
func _process(_d: float) -> bool:
	frame += 1
	if frame == 5:
		for a in main.ais.values():
			a.active = false
		for b in main.buildings.duplicate():
			pass
		Engine.time_scale = 6.0
		_next()
		return false
	if frame < 6 or frame % 10 != 0:
		return false
	var v0 := _val(0)
	var v1 := _val(1)
	if v0 <= 0.0 or v1 <= 0.0 or main.game_time - t0 > 90.0:
		var a: Array = pairs[idx][0]
		var b: Array = pairs[idx][1]
		for k in [[a, v0 - v1], [b, v1 - v0]]:
			var key := "%s:%s" % [k[0][0], k[0][1]]
			res[key] = res.get(key, []) + [k[1]]
		if OS.has_environment("VERBOSE"):
			print("%s:%s %.2f  vs  %s:%s %.2f" % [a[0], a[1], v0, b[0], b[1], v1])
		if not _next():
			var fac := {}
			for key in res:
				var m := 0.0
				for x in res[key]:
					m += x
				m /= res[key].size()
				print("DUEL %-22s %+.2f" % [key, m])
				var f: String = key.split(":")[0]
				fac[f] = fac.get(f, []) + [m]
			for f in fac:
				var m := 0.0
				for x in fac[f]:
					m += x
				print("FACTION %-9s %+.2f" % [f, m / fac[f].size()])
			return true
	return false
