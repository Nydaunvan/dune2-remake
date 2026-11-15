extends SceneTree
## Captures comparatives du terrain : ancien shader (terrain_classic.gdshader) et nouveau (terrain.gdshader)
## sur les mêmes zones (épice, montagne, sable) à deux zooms, sans brouillard ni interface. Mesure aussi le temps par image.
## xvfb-run -a godot --rendering-driver opengl3 --resolution 1600x900 --path . -s res://tools/terrain_shot.gd
var main
var f := 0
var started := false
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.mode = "skirmish"
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null or started:
		return false
	f += 1
	if f == 3:
		started = true
		_run()
	return false
func _frames(n: int) -> void:
	for i in n:
		await process_frame
func _run() -> void:
	var rect: ColorRect = null
	for c in main.get_children():
		if c is ColorRect:
			if c.z_index == 40:
				c.visible = false
			elif c.z_index == -10:
				rect = c
	main.ui.visible = false
	for t in main.units:
		t.visible = false
	for b in main.buildings:
		b.visible = false
	var spots: Array = []
	var sf: Vector2 = main.spice_fields[0] if not main.spice_fields.is_empty() else Vector2(48, 48)
	spots.append(["epice", sf * 32.0, 1.3])
	spots.append(["epice_zoom", sf * 32.0, 2.5])
	var best := Vector2i(-1, -1)
	for x in range(4, main.map_w - 4):
		for y in range(4, main.map_h - 4):
			if main.terrain[x][y] == main.T.MOUNTAIN and main.terrain[x + 1][y] == main.T.ROCK and main.terrain[x][y + 1] == main.T.SAND:
				best = Vector2i(x, y)
	if best.x >= 0:
		var bp := (Vector2(best) + Vector2(0.5, 0.5)) * 32.0
		spots.append(["montagne", bp, 1.3])
		spots.append(["montagne_zoom", bp, 2.5])
	spots.append(["sable", Vector2(main.start_cell.x, main.start_cell.y - 14) * 32.0, 1.3])
	spots.append(["vue_large", Vector2(main.map_w, main.map_h) * 16.0, 0.6])
	var shaders := {"avant": load("res://shaders/terrain_classic.gdshader"), "apres": load("res://shaders/terrain.gdshader")}
	var mat: ShaderMaterial = rect.material
	var res := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/shots"
	for s in spots:
		main.camera.zoom = Vector2(s[2], s[2])
		main.center_camera(s[1])
		for tag in shaders:
			mat.shader = shaders[tag]
			await _frames(4)
			var t0 := Time.get_ticks_usec()
			for i in 6:
				await RenderingServer.frame_post_draw
			var ms := (Time.get_ticks_usec() - t0) / 6000.0
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/terrain_%s_%s.png" % [res, tag, s[0]])
			print("%s %s : %.0f ms/image" % [tag, s[0], ms])
	# bascule HD <-> Standard en cours de partie (menu pause)
	var was := DisplayCfg.terrain_hd()
	main.apply_terrain_quality()
	var p1: String = mat.shader.resource_path
	DisplayCfg.toggle_terrain()
	main.apply_terrain_quality()
	var p2: String = mat.shader.resource_path
	DisplayCfg.toggle_terrain()
	main.apply_terrain_quality()
	print("bascule : %s -> %s -> %s (hd au départ : %s)" % [p1.get_file(), p2.get_file(), mat.shader.resource_path.get_file(), was])
	quit()
