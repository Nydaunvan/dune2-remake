extends SceneTree
## Planche des bâtiments d'une faction (état actuel). HD=1 pour le shader de coque HD.
## FACTION=solis HD=0 xvfb-run -a godot --rendering-driver opengl3 --resolution 1800x1100 --path . -s res://tools/buildings_lab.gd
var sb: SpriteBank
var fac := "solis"
var ids: Array = []
var f := 0
var canvas: Node2D
var hd := false
func _initialize() -> void:
	if OS.has_environment("FACTION"):
		fac = OS.get_environment("FACTION")
	hd = OS.get_environment("HD") == "1"
	sb = SpriteBank.new()
	sb.hd_units = hd
	sb.ss = 3.0 if hd else 2.0
	root.add_child(sb)
	sb._make_viewport()
	var ids_env := OS.get_environment("IDS")
	ids = ids_env.split(",") if ids_env != "" else ["chantier", "centrale", "raffinerie", "fonderie", "usine", "reparation", "silo", "radar", "aerodrome", "marche", "tourelle", "bunker"]
	_run()
func _run() -> void:
	var accent: Color = GameData.FACTIONS[fac]["color"]
	for id in ids:
		if not GameData.BUILDINGS.has(id):
			continue
		var cs: Vector2i = GameData.def(id)["size"]
		var fr := Vector2(cs * 32) + Vector2(SpriteBank.BUILDING_MARGIN, SpriteBank.BUILDING_MARGIN)
		Models.hd = hd
		await sb._bake({"key": id, "id": id, "accent": accent, "faction": fac, "angles": 1, "frame": fr, "extra": SpriteBank.BUILDING_EXTRA, "ss": sb.ss, "hd": hd})
		Models.hd = false
	canvas = Node2D.new()
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color("c98f78")
	bg.size = Vector2(1800, 1100)
	root.add_child(bg)
	root.move_child(bg, 0)
	canvas.draw.connect(func() -> void:
		var x := 40.0
		var y := 40.0
		var rowh := 0.0
		for id in ids:
			if not sb.has(id):
				continue
			var sz := sb.draw_size(id) * 3.0
			if x + sz.x > 1780:
				x = 40.0
				y += rowh + 30.0
				rowh = 0.0
			canvas.draw_texture_rect(sb.frame(id), Rect2(Vector2(x, y), sz), false)
			canvas.draw_string(ThemeDB.fallback_font, Vector2(x + 4, y + sz.y + 14), id, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.BLACK)
			x += sz.x + 16.0
			rowh = maxf(rowh, sz.y))
	canvas.queue_redraw()
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/shots/batiments_%s.png" % fac)
	print("ok")
	quit()
