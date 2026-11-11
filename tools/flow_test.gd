extends SceneTree
## Parcours complet : engin de chantier -> déploiement -> constructions -> récolte.
## MISSION=-1 (escarmouche) ou 0..4 ; FACTION ; SECONDS (durée simulée).
var main
var frame := 0
var step := 0

func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	var m := int(OS.get_environment("MISSION")) if OS.has_environment("MISSION") else -1
	GameSession.mode = "campaign" if m >= 0 else "skirmish"
	GameSession.mission = maxi(m, 0)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _process(_d: float) -> bool:
	frame += 1
	if frame == 5:
		var mcv := []
		for u in main.units:
			mcv.append("%d:%s" % [u.team, u.id])
		print("carte %dx%d start=%s enemy=%s ally=%s unités=%s" % [main.map_w, main.map_h, main.start_cell, main.enemy_cell, main.ally_cell, mcv])
		print("terrain départ: ", main.terrain[int(main.start_cell.x)][int(main.start_cell.y)], " ok_deploy=", main._deploy_ok(Vector2i(main.start_cell) - Vector2i(1, 1)))
	if frame == 20 and step == 0:
		step = 1
		for u in main.units:
			if u.team == 0 and u.id == "mcv":
				print("déploiement joueur: ", main.deploy_mcv(u, true))
	if frame > 20 and step >= 1 and frame % 120 == 0:
		# file de construction : enchaîne les bâtiments dès que possible
		var order := ["centrale", "raffinerie", "fonderie", "usine", "tourelle"]
		for id in order:
			if main.count_buildings(id) == 0 and main.production["building"].is_empty() and main.ore >= main.item_cost(id) and main.is_available(id):
				main.on_item_clicked(id, MOUSE_BUTTON_LEFT)
				break
		for b in main.production["building"]:
			if b["ready"]:
				var cell := Vector2i(-1, -1)
				for dx in range(-8, 9):
					for dy in range(-8, 9):
						var c := Vector2i(main.start_cell) + Vector2i(dx, dy)
						if cell.x < 0 and main._can_place(b["id"], c):
							cell = c
				if cell.x >= 0:
					main._place_building(b["id"], cell, 0)
					main.production["building"].erase(b)
					break
	var secs := int(OS.get_environment("SECONDS")) if OS.has_environment("SECONDS") else 120
	if frame % 600 == 0:
		var bl := {}
		for b in main.buildings:
			bl["%d:%s" % [b.team, b.id]] = true
		print("[t=%ds] solaris=%d minerai=%d bât=%s units=%d" % [frame / 60, main.credits, main.ore, bl.keys(), main.units.size()])
		if main.mission.size() > 0:
			print("  objectifs: ", main.objectives_status().map(func(o): return "%s (%.0f%%)" % [o["text"], o["frac"] * 100.0]))
	if frame >= secs * 60:
		print("FIN over=", main.over)
		return true
	return false
