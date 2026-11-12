extends SceneTree
## Capture d'écran (nécessite un affichage, ex. xvfb-run) :
## xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility --path . --script tools/shot.gd
## Variables : SHOT_SCENE (main|menu), SHOT_FRAMES, SHOT_OUT, FACTION, SHOT_FOCUS=x,y (cases)
var f := 0
var node
var frames := 90


func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.instant_bases = OS.has_environment("SHOT_BASE")
	var sc := OS.get_environment("SHOT_SCENE") if OS.has_environment("SHOT_SCENE") else "main"
	if OS.has_environment("SHOT_FRAMES"):
		frames = int(OS.get_environment("SHOT_FRAMES"))
	if OS.has_environment("SHOT_MISSION"):
		GameSession.mode = "campaign"
		GameSession.mission = int(OS.get_environment("SHOT_MISSION"))
	node = load("res://%s.tscn" % sc).instantiate()
	root.add_child(node)


func _process(_d: float) -> bool:
	if OS.has_environment("SHOT_AFTERLOAD") and node.get("loading") != null:
		return false # on attend la fin du chargement
	f += 1
	if f == 10 and OS.has_environment("SHOT_WORM"):
		var best := Vector2i(-1, -1)
		for dx in range(-14, 15):
			for dy in range(-14, 15):
				var c := Vector2i(node.start_cell) + Vector2i(dx, dy)
				if node.terrain[c.x][c.y] == 0 and (best.x < 0 or Vector2(dx, dy).length() < Vector2(best - Vector2i(node.start_cell)).length()):
					best = c
		node.units[0].position = Vector2(best) * 32.0 + Vector2(16, 16)
		node.center_camera(node.units[0].position)
		node._spawn_worm(node.units[0])
	if f == 8 and OS.has_environment("SHOT_PAUSE"):
		node.save_game(1, false)
		node.open_pause_menu()
	if f == 8 and OS.has_environment("SHOT_MCV"):
		for u in node.units:
			if u.team == 0 and u.id == "mcv":
				u.selected = true
				node.selected.append(u)
	if f == 8 and OS.has_environment("SHOT_ALLYVIEW"):
		node.center_camera(node.ally_cell * 32.0)
	if f == 5 and OS.has_environment("SHOT_GUIDE"):
		var g = Guide.open(node, GameSession.faction)
		g._show(OS.get_environment("SHOT_GUIDE"))
	if f == 5 and OS.has_environment("SHOT_OVERLAY"):
		node._open_campaign()
	if f == 3 and OS.has_environment("SHOT_FOCUS"):
		var p := OS.get_environment("SHOT_FOCUS").split(",")
		node.camera.zoom = Vector2(float(OS.get_environment("SHOT_ZOOM")), float(OS.get_environment("SHOT_ZOOM"))) if OS.has_environment("SHOT_ZOOM") else node.camera.zoom
		node.center_camera(Vector2(float(p[0]), float(p[1])) * 32.0)
	if f == 3 and OS.has_environment("SHOT_NOBANK") and node.bank != null:
		node.bank.queue_free()
		node.bank = null
	if f == 9 and OS.has_environment("SHOT_AIR"):
		node.tier = 9
		node.ui._set_category("unit" if OS.get_environment("SHOT_AIR") == "unit" else "building")
		var ids: Array = GameData.FACTIONS[node.faction_id]["air"]
		for i in ids.size():
			var u = node._spawn_unit(ids[i], node.world_to_cell(node.start_cell * 32.0) + Vector2i(i * 3 - 3, 3), 0)
			u.position = node.start_cell * 32.0 + Vector2(i * 70 - 70, 70)
			u.rotation = -0.4
		node.center_camera(node.start_cell * 32.0 + Vector2(0, 70))
	if f == 6 and OS.has_environment("SHOT_LEVELS"):
		# Une rangée par niveau : tous les bâtiments de la faction aux niveaux 1, 2 et 3
		for lv in 3:
			var x := 0
			for id in GameData.buildings_for(node.faction_id):
				if GameData.def(id).get("wall", false):
					continue
				var size: Vector2i = GameData.def(id)["size"]
				var b = node._place_building(id, Vector2i(node.start_cell) + Vector2i(-4 + x, -10 + lv * 5), 0, false)
				if b != null:
					for i in lv:
						b.upgrade()
				x += size.x + 1
		node.center_camera(node.start_cell * 32.0 + Vector2(120, -190))
	if f >= 10 and OS.has_environment("SHOT_HARVEST"):
		for u in node.units:
			if u.team == 0 and u.id == "recolteur":
				if f == 10:
					var n: Vector2i = node.find_resource("spice", node.world_to_cell(u.position), 60)
					u.position = Vector2(n) * 32.0 + Vector2(16, 16)
					u.work_cell = n
					u.state = "harvest"
					u.cargo = 0.0
					node.center_camera(u.position)
				u.state = "harvest"
				u.cargo = minf(u.cargo, 1.0)
				break
	if f == 12 and OS.has_environment("SHOT_UPG"):
		for b in node.buildings:
			if b.team == 0:
				b.up_total = 100.0
				b.up_left = 60.0
				b.hp = b.max_hp * 0.6
	if f == 10 and OS.has_environment("SHOT_SELECT"):
		for b in node.buildings:
			if b.team == 0 and b.id == OS.get_environment("SHOT_SELECT"):
				node.inspected = b
				node.selected_building = b
				b.selected = true
				node.ore = 3000
	if f == frames:
		var out := OS.get_environment("SHOT_OUT") if OS.has_environment("SHOT_OUT") else "/tmp/shots/shot.png"
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		return true
	return false
