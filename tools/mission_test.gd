extends SceneTree
## Simule la réussite de chaque type d'objectif. MISSION=0..4, FACTION.
var main
var frame := 0
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.mode = "campaign"
	GameSession.mission = int(OS.get_environment("MISSION"))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	frame += 1
	var m: Dictionary = main.mission
	if frame == 30:
		for u in main.units:
			if u.team == 0 and u.id == "mcv":
				main.deploy_mcv(u, true)
	if frame == 60:
		print("objectifs:", main.objectives_status().map(func(o): return o["text"]))
		for o in m["objectives"]:
			match o["type"]:
				"build":
					for id in o["ids"]:
						for i in int(o["ids"][id]):
							var c := Vector2i(-1, -1)
							for dx in range(-8, 9):
								for dy in range(-8, 9):
									var cc := Vector2i(main.start_cell) + Vector2i(dx, dy)
									if c.x < 0 and main._can_place(id, cc):
										c = cc
							main._place_building(id, c, 0)
				"harvest":
					main.earned = o["amount"]
				"train":
					for i in int(o["count"]):
						main._spawn_unit("egide" if i % 2 == 0 else "sentinelle", main._find_free_cell(Vector2i(main.start_cell) + Vector2i(0, 5)), 0)
				"survive":
					main.game_time = o["time"] + 1.0
				"waves":
					main.stats.waves_repelled = int(o["count"])
				"worms":
					main.stats.worm_kills = int(o["count"])
				"outposts":
					for b in main.buildings.duplicate():
						if b.outpost >= 0:
							b.take_damage(999999.0, "cannon")
				"escort":
					main.game_time = 400.0
					for u in main.units:
						if u.convoy:
							u.position = main.mission_points["dest"] * 32.0 + Vector2(16, 16)
				"hold":
					main.hold_t = 61.0
					main.zone_done = true
				"destroy_all":
					pass
		main._update_objectives(0.0)
		print("après:", main.objectives_status().map(func(o): return "%s %s" % [o["text"], str(o["done"])]))
		print("encore ennemi vivant: ", main._side_alive(1))
		for t in [1]:
			for b in main.buildings.duplicate():
				if b.team == t:
					b.take_damage(999999.0, "cannon")
			for u in main.units.duplicate():
				if u.team == t and u.id == "mcv":
					u.take_damage(999999.0, "cannon")
	if frame == 120:
		print("over=", main.over, " cleared=", Campaign.cleared(GameSession.faction))
		return true
	return false
