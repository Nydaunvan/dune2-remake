extends SceneTree
var main
var f := 0
var snap := {}
func _snap(m) -> Dictionary:
	var res := 0.0
	for c in m.resource:
		res += float(m.resource[c]["amount"])
	var lv := 0
	for b in m.buildings:
		lv += b.level * 10 + int(b.hp)
	var uh := 0.0
	for u in m.units:
		uh += u.hp + u.position.x * 0.001
	return {"b": m.buildings.size(), "u": m.units.size(), "cr": m.credits, "ore": m.ore, "res": int(res),
			"lv": lv, "uh": int(uh), "t": int(m.game_time), "prod": m.production["unit"].size(), "ter": m.terrain.hash()}
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.credits = 1234
		main.ore = 777
		var ch = main.buildings[0]
		for b in main.buildings:
			if b.id == "centrale":
				b.upgrade()
		main.begin_upgrade(main.buildings[0])
		main.extract(main.resource.keys()[0], 100000.0)
		main.extract(main.resource.keys()[5], 50.0)
		main.units[0].hp = 17.0
		main.units[1].tech_left = 5.0
		main.production["unit"].append({"id": main.fdata["units"][0], "progress": 0.4, "time": 8.0, "ready": false, "paid": 100, "paid_sol": 0})
		main.game_time = 321.0
		snap = _snap(main)
		print("avant : ", snap)
		print("save ok=", main.save_game(3, false), " desc=", SaveGame.describe(3))
		main.queue_free()
	elif f == 6:
		GameSession.instant_bases = true
		GameSession.load_slot = 3
		main = load("res://main.tscn").instantiate()
		root.add_child(main)
	elif f == 12:
		var s2 := _snap(main)
		print("après : ", s2)
		var ok := true
		for k in snap:
			if snap[k] != s2[k]:
				ok = false
				print("DIFFÉRENCE ", k, " ", snap[k], " -> ", s2[k])
		print("RESULT ", "OK" if ok else "ECHEC", " unit0 state=", main.units[0].state, " selected_slots=", GameSession.load_slot)
		SaveGame.delete(3)
		return true
	return false
