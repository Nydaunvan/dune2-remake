extends SceneTree
## Banc d'équilibrage : une partie IA contre IA (FAC_A = camp 0, FAC_B = camp 1), en accéléré.
## Env : FAC_A, FAC_B, SEED, SIZE (64), DIFF (2), TMAX (secondes de jeu, 2100), SCALE (8).
## Sortie : une ligne « BENCH {json} ».
var main
var frame := 0
var tmax := 2100.0
var seen := {}
var built := {0: {}, 1: {}}
var first_wave := {0: -1.0, 1: -1.0}
var peak := {0: 0, 1: 0}
var samples: Array = []
func _env(k: String, d: String) -> String:
	return OS.get_environment(k) if OS.has_environment(k) else d
func _initialize() -> void:
	seed(int(_env("SEED", "1")))
	GameSession.mode = "skirmish"
	GameSession.auto_player = true
	GameSession.faction = _env("FAC_A", "solis")
	GameSession.skirm_foe = _env("FAC_B", "kharn")
	GameSession.opponents = 1
	GameSession.skirm_size = int(_env("SIZE", "64"))
	GameSession.skirm_diff = int(_env("DIFF", "2"))
	GameSession.skirm_res = 1.0
	tmax = float(_env("TMAX", "2100"))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _score(t: int) -> float:
	var s := 0.0
	for b in main.buildings:
		if b.team == t and b.alive:
			s += float(GameData.def(b.id).get("cost", 1500)) * b.hp / maxf(b.max_hp, 1.0)
	for u in main.units:
		if u.team == t and u.alive:
			s += float(GameData.def(u.id).get("cost", 300)) * u.hp / maxf(u.max_hp, 1.0)
	return s
func _process(_d: float) -> bool:
	frame += 1
	if frame == 5:
		Engine.time_scale = float(_env("SCALE", "8"))
	if frame < 10 or frame % 30 != 0:
		return false
	for u in main.units:
		var k: int = u.get_instance_id()
		if not seen.has(k) and u.team <= 1:
			seen[k] = true
			built[u.team][u.id] = int(built[u.team].get(u.id, 0)) + 1
	for t in [0, 1]:
		var n := 0
		for u in main.units:
			if u.team == t and u.alive and u.role == "combat":
				n += 1
		peak[t] = maxi(peak[t], n)
		if first_wave[t] < 0.0 and main.ais[t].mode != "muster":
			first_wave[t] = main.game_time
	if frame % 450 == 0 and OS.has_environment("TRACE"):
		for t in [0, 1]:
			var a = main.ais[t]
			var w := {}
			for u in main.units:
				if u.team == t and u.alive and u.is_worker():
					w[u.id + ":" + u.state] = int(w.get(u.id + ":" + u.state, 0)) + 1
			var arm := 0
			for u in main.units:
				if u.team == t and u.alive and u.role == "combat":
					arm += 1
			var bl := {}
			for b in main.buildings:
				if b.team == t and b.alive:
					bl[b.id + str(b.level)] = int(bl.get(b.id + str(b.level), 0)) + 1
			var st := {}
			for u in a._army():
				var k2: String = u.state + ("*" if u.has_meta("ai_hurt") else "") + ("r" if u in a.raid else "")
				st[k2] = int(st.get(k2, 0)) + 1
			var tg = a._pick_target()
			var dfn: float = a._power(a._defenders_near(tg.world_center(), 9.0 * main.TILE)) if tg != null else -1.0
			print("T %4d c%d $%d min%d armée=%d mode=%s vague=%d lim=%d états=%s cible=%s déf=%.0f moi=%.0f but=%s bq=%s uq=%s ouvr=%s bât=%s" % [int(main.game_time), t, a.credits, a.ore, arm, a.mode, a.wave_size, a._army_limit(), str(st), tg.id if tg != null else "-", dfn, a._power(a._army()), a.goal_text, str(a.build_q.get("id", "-")), str(a.unit_q.get("id", "-")), str(w), str(bl)])
	if frame % 900 == 0:
		samples.append([int(main.game_time), int(_score(0)), int(_score(1))])
	var a0: bool = main._team_alive(0)
	var a1: bool = main._team_alive(1)
	if main.over or not a0 or not a1 or main.game_time >= tmax:
		var s0 := _score(0)
		var s1 := _score(1)
		var win := "A" if (a0 and not a1) else ("B" if (a1 and not a0) else ("A~" if s0 > s1 * 1.25 else ("B~" if s1 > s0 * 1.25 else "=")))
		var bl := [{}, {}]
		for b in main.buildings:
			if b.alive and b.team <= 1:
				bl[b.team][b.id] = int(bl[b.team].get(b.id, 0)) + 1
		print("BENCH ", JSON.stringify({"a": GameSession.faction, "b": main.team_factions[1], "seed": _env("SEED", "1"), "win": win, "t": int(main.game_time),
				"score": [int(s0), int(s1)], "built": [built[0], built[1]], "bld": bl, "wave": [int(first_wave[0]), int(first_wave[1])],
				"peak": [peak[0], peak[1]], "res": [[main.ais[0].credits, main.ais[0].ore], [main.ais[1].credits, main.ais[1].ore]], "samples": samples}))
		return true
	return false
