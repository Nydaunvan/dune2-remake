extends SceneTree
## Cycle de marche des mechas : une ligne par mécha, une colonne par phase (vue de profil).
## xvfb-run -a godot --rendering-driver opengl3 --resolution 1500x1000 -s tools/walk_shot.gd
var bank: SpriteBank
var canvas: Node2D
var f := 0
var rows := [["phalange", "solis"], ["archonte", "solis"], ["cogneur", "kharn"], ["mastodonte", "kharn"], ["geode", "conclave"], ["stele", "conclave"], ["tarentule", "vael"], ["mygale", "vael"]]


func _initialize() -> void:
	bank = SpriteBank.new()
	root.add_child(bank)
	bank.setup(null, [])
	for r in rows:
		var accent: Color = GameData.FACTIONS[r[1]]["color"]
		for k in Models.WALK_FRAMES + 1:
			var job := {"key": "%s|%s|w%d" % [r[0], r[1], k], "id": r[0], "accent": accent, "faction": r[1], "angles": 16,
					"frame": SpriteBank.UNIT_FRAME, "extra": SpriteBank.UNIT_EXTRA, "phase": float(k) / Models.WALK_FRAMES}
			if k == Models.WALK_FRAMES:
				job["key"] = "%s|%s|stand" % [r[0], r[1]]
				job["phase"] = -1.0
			bank._jobs.append(job)
	bank.ready_all = false
	bank._bake_all()
	canvas = Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(_draw_sheet)
	var bg := ColorRect.new()
	bg.color = Color("c98f78")
	bg.size = Vector2(1500, 1000)
	root.add_child(bg)
	root.move_child(bg, 0)


func _draw_sheet() -> void:
	var y := 70.0
	for r in rows:
		for k in Models.WALK_FRAMES + 1:
			var key := "%s|%s|w%d" % [r[0], r[1], k] if k < Models.WALK_FRAMES else "%s|%s|stand" % [r[0], r[1]]
			if bank.has(key):
				var sz := bank.draw_size(key) * 1.7
				canvas.draw_texture_rect(bank.frame(key, float(OS.get_environment("ANG")) if OS.has_environment("ANG") else 0.0), Rect2(Vector2(110.0 + k * 190.0, y) - sz / 2.0, sz), false)
		canvas.draw_string(ThemeDB.fallback_font, Vector2(8, y + 50), r[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		y += 120.0


func _process(_d: float) -> bool:
	f += 1
	if f % 20 == 0:
		canvas.queue_redraw()
	if bank.ready_all and f > 40:
		canvas.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/shots/walk.png")
		print("saved")
		quit()
		return true
	if f > 4000:
		print("timeout")
		return true
	return false
