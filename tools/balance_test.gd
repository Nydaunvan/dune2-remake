extends SceneTree
## Équilibrage : fait s'affronter des armées de même coût et affiche les taux de victoire.
##   MODE=factions : armées mixtes (les 3 unités de la faction à parts égales) faction contre faction
##   MODE=units    : chaque unité seule contre l'armée mixte de chaque autre faction
## godot --headless --fixed-fps 60 --path . --script tools/balance_test.gd
## Variables : BUDGET (défaut 3000), TRIALS (défaut 3)

var budget := 3000
var trials := 3
var mode := "factions"
var matches: Array = []
var results := {}
var cur := -1
var main
var frame := 0
var phase := "none"
var start_val := {}


func _initialize() -> void:
	if OS.has_environment("BUDGET"):
		budget = int(OS.get_environment("BUDGET"))
	if OS.has_environment("TRIALS"):
		trials = int(OS.get_environment("TRIALS"))
	if OS.has_environment("MODE"):
		mode = OS.get_environment("MODE")
	var facs := ["solis", "kharn", "vael"]
	if mode == "factions":
		for a in facs:
			for b in facs:
				if a <= b:
					for t in trials:
						matches.append({"a": {"f": a, "u": GameData.FACTIONS[a]["units"]}, "b": {"f": b, "u": GameData.FACTIONS[b]["units"]},
								"label": "%s vs %s" % [a, b], "swap": t % 2 == 1})
	else:
		for a in facs:
			for uid in GameData.FACTIONS[a]["units"]:
				for b in facs:
					if b != a:
						for t in trials:
							matches.append({"a": {"f": a, "u": [uid]}, "b": {"f": b, "u": GameData.FACTIONS[b]["units"]},
									"label": "%s (%s) vs armée %s" % [uid, a, b], "swap": t % 2 == 1})
	_next()


func _next() -> void:
	if main != null:
		main.queue_free()
		main = null
	cur += 1
	if cur >= matches.size():
		_report()
		quit()
		return
	GameSession.faction = matches[cur]["a"]["f"]
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	frame = 0
	phase = "setup"


func _cost(fid: String, uid: String) -> int:
	return int(round(float(GameData.UNITS[uid]["cost"]) * float(GameData.FACTIONS[fid]["unit_cost_mult"])))


func _army_value(team: int) -> int:
	var v := 0
	for u in main.units:
		if u.team == team and u.alive and u.role == "combat":
			v += int(round(float(GameData.UNITS[u.id]["cost"]) * float(GameData.FACTIONS[main.faction_id_of(team)]["unit_cost_mult"]) * u.hp / u.max_hp))
	return v


func _spawn_army(team: int, side: Dictionary, x: int) -> void:
	var ids: Array = side["u"]
	var per: float = float(budget) / ids.size()
	var y := 8
	for uid in ids:
		var n := maxi(1, int(round(per / _cost(side["f"], uid))))
		for i in n:
			var c: Vector2i = main._find_free_cell(Vector2i(x, y + (i % 8) * 2))
			var u: Unit = main._spawn_unit(uid, c, team)
			u.name = "u"
		y += 3


func _process(_d: float) -> bool:
	if phase == "none":
		return false
	frame += 1
	if phase == "setup" and frame == 3:
		main.ai.active = false
		main._fog_t = 1e12 # pas de brouillard pendant les tests
		for u in main.units.duplicate():
			u._die()
		var m: Dictionary = matches[cur]
		# Les camps sont ajustés pour que l'équipe 0 = faction joueur (celle de la scène) ; l'autre = ennemie
		main.enemy_faction = m["b"]["f"]
		main.ai.faction_id = m["b"]["f"]
		main.ai.fdata = GameData.FACTIONS[m["b"]["f"]]
		var xa := 20 if not m["swap"] else 34
		var xb := 34 if not m["swap"] else 20
		_spawn_army(0, m["a"], xa)
		_spawn_army(1, m["b"], xb)
		for u in main.units:
			var tx := xb if u.team == 0 else xa
			u.order_amove(main._find_free_cell(Vector2i(tx, 12)))
		start_val = {"a": _army_value(0), "b": _army_value(1)}
		phase = "fight"
	elif phase == "fight":
		var a := _army_value(0)
		var b := _army_value(1)
		var done := a == 0 or b == 0 or frame > 60 * 120
		if done:
			var key: String = matches[cur]["label"]
			var r: Dictionary = results.get(key, {"a_wins": 0, "b_wins": 0, "draws": 0, "a_left": 0.0, "b_left": 0.0, "n": 0})
			r["n"] += 1
			if a > b:
				r["a_wins"] += 1
			elif b > a:
				r["b_wins"] += 1
			else:
				r["draws"] += 1
			r["a_left"] += float(a) / maxf(start_val["a"], 1.0)
			r["b_left"] += float(b) / maxf(start_val["b"], 1.0)
			results[key] = r
			_next()
	return false


func _report() -> void:
	print("=== Équilibrage (%s) — budget %d, %d essais ===" % [mode, budget, trials])
	for key in results:
		var r: Dictionary = results[key]
		print("%-36s  A gagne %d / B gagne %d / nul %d   reste A %3d %%  B %3d %%" % [
				key, r["a_wins"], r["b_wins"], r["draws"], int(100.0 * r["a_left"] / r["n"]), int(100.0 * r["b_left"] / r["n"])])
