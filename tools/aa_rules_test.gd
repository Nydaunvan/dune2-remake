extends SceneTree
## Règles anti-air : la Tourelle touche l'air, l'Égide non ; les chasseurs frappent faiblement le sol.
var main
var f := 0
var tur
var heli
var tank
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		var c := Vector2i(main.start_cell) + Vector2i(10, 10)
		main.ore = 9000
		main.tier = 9
		tur = main._place_building("tourelle", c, 0)
		heli = main._spawn_unit("marteau", c + Vector2i(4, 0), 1)
		tank = main._spawn_unit("egide", c + Vector2i(-4, 8), 0)
		var heli2 = main._spawn_unit("marteau", c + Vector2i(-6, 8), 1)
		heli2.hp = heli2.hp # témoin : cible hors portée de la tourelle
		print("tourelle aa=", GameData.can_hit_air("tourelle"), " égide aa=", GameData.can_hit_air("egide"),
			" salve aa=", GameData.can_hit_air("salve"), " batterie aa=", GameData.can_hit_air("batterie"))
		print("libellule vs sol=", GameData.aim_mult("libellule", false), " vs air=", GameData.aim_mult("libellule", true),
			" salve vs air=", GameData.aim_mult("salve", true))
	if f == 5 + 600:
		var hp0: float = GameData.UNITS["marteau"]["hp"]
		print("marteau ennemi: ", "mort" if not is_instance_valid(heli) or not heli.alive else "pv %d/%d" % [heli.hp, hp0])
		print("égide alliée touchée par le marteau: pv ", tank.hp if is_instance_valid(tank) else -1)
		quit()
	return false
