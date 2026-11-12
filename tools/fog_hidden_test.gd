extends SceneTree
## Vérifie que toute base/unité hostile non découverte est cachée dès le départ.
## godot --headless --script tools/fog_hidden_test.gd
var main
var frame := 0
var cases := [[-1, "skirmish"], [0, "mission0"], [4, "mission4"], [9, "mission9"]]
var ci := 0


func _start() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mission = cases[ci][0]
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	frame = 0


func _initialize() -> void:
	_start()


func _process(_d: float) -> bool:
	frame += 1
	if frame < 20 or main.get("loading") != null:
		return false
	var leaks := 0
	var hostile_b := 0
	for b in main.buildings:
		if b.team != 0:
			hostile_b += 1
			var known := false
			for c in b.cells():
				known = known or main.fog_seen[c.y * main.map_w + c.x] == 1
			if b.visible and not known:
				leaks += 1
	for u in main.units:
		if u.team != 0 and u.visible and not main.is_visible_cell(main._world_to_cell(u.position)):
			leaks += 1
	print("%s: bâtiments hostiles=%d fuites=%d" % [cases[ci][1], hostile_b, leaks])
	if leaks > 0:
		print("ÉCHEC")
		quit(1)
		return true
	main.queue_free()
	ci += 1
	if ci >= cases.size():
		print("OK")
		return true
	_start()
	return false
