extends SceneTree
## Chaque tourelle (toutes factions) doit blesser un appareil ennemi à portée.
var main
var f := 0
var towers := ["tourelle", "batterie", "tour_sonique", "bunker", "tour_acide", "tour_prisme"]
var air := {}
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.credits = 99999
		for k in 8:
			main._place_building("reacteur", Vector2i(main.start_cell) + Vector2i(-40 + k * 3, 20), 0, false)
		var i := 0
		for id in towers:
			var cell := Vector2i(main.start_cell) + Vector2i(-30 + (i % 3) * 14, -22 + (i / 3) * 14)
			var b = main._place_building(id, cell, 0, false)
			if b == null:
				print(id, " : pose impossible"); i += 1; continue
			b.level = 1
			var a = main.spawn_for("libellule", 1)
			a.position = b.world_center() + Vector2(110, 0)
			a.seen = true; a.visible = true; a.state = "idle"; a.hp = 5000.0; a.max_hp = 5000.0
			air[id] = [b, a]
			i += 1
		for b in main.buildings:
			b.offline = false
	if f > 5 and f < 600:
		for id in air:
			var a = air[id][1]
			a.position = air[id][0].world_center() + Vector2(110, 0)
	if f == 600:
		for id in air:
			print(id, " : PV avion ", int(air[id][1].hp), "/5000 ", "OK" if air[id][1].hp < 4999.0 else "AUCUN TIR")
		quit()
	return false
