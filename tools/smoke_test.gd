extends SceneTree
## Test de fumée sans affichage : lance la partie, laisse tourner la simulation
## et affiche l'évolution des ressources, des ouvriers et du ver.
## godot --headless --fixed-fps 60 --path . --script tools/smoke_test.gd

var main
var frame := 0
var worm_spawned := false


func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 5:
		print("[%d] unités=%d bâtiments=%d ressources=%d" % [frame, main.units.size(), main.buildings.size(), main.resource.size()])
	if frame % 600 == 0:
		var parts := []
		for u in main.units:
			if u.is_worker():
				parts.append("%s:%s(%d)" % [u.id, u.state, int(u.cargo)])
		print("[t=%ds] solaris=%d minerai=%d ouvriers=%s" % [frame / 60, main.credits, main.ore, parts])
	if frame >= 300 and not worm_spawned:
		var sand = main._harvesters_on_sand()
		if not sand.is_empty():
			worm_spawned = true
			var tgt = sand[0]
			print("[t=%ds] ver forcé sur %s (%s), unités=%d" % [frame / 60, tgt.id, tgt.state, main.units.size()])
			main._spawn_worm(tgt)
	if frame % 300 == 0 and worm_spawned:
		print("[t=%ds] unités=%d ver=%s" % [frame / 60, main.units.size(), str(main.worm != null)])
	if frame >= 3600:
		print("FIN OK")
		return true
	return false
