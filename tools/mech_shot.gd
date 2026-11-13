extends SceneTree
## Planche des mechas d'une faction (4 angles chacun, agrandis). xvfb-run, opengl3.
var bank: SpriteBank
var canvas: Node2D
var f := 0
var facs := ["solis", "kharn", "conclave", "vael"]
var ids := {}
var started := false


func _initialize() -> void:
	bank = SpriteBank.new()
	root.add_child(bank)
	bank.setup(null, [])
	for fc in facs:
		var accent: Color = GameData.FACTIONS[fc]["color"]
		for id in GameData.FACTIONS[fc]["units"]:
			if GameData.UNITS[id].get("armor", "") == "" or not id in ["phalange", "archonte", "cogneur", "gladiateur", "mastodonte", "geode", "stele", "cariatide", "tarentule", "mygale"]:
				continue
			ids[id] = fc
			bank._jobs.append({"key": "%s|%s" % [id, fc], "id": id, "accent": accent, "faction": fc, "angles": 16,
					"frame": SpriteBank.UNIT_FRAME, "extra": SpriteBank.UNIT_EXTRA})
	bank.ready_all = false
	bank._bake_all()
	canvas = Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(_draw_sheet)
	var bg := ColorRect.new()
	bg.color = Color("c98f78")
	bg.size = Vector2(1800, 1000)
	root.add_child(bg)
	root.move_child(bg, 0)


func _draw_sheet() -> void:
	var y := 120.0
	var x := 80.0
	var n := 0
	for id in ids:
		var key := "%s|%s" % [id, ids[id]]
		if not bank.has(key):
			continue
		var sz := bank.draw_size(key) * 1.6
		for a in [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]:
			canvas.draw_texture_rect(bank.frame(key, a), Rect2(Vector2(x, y) - sz / 2.0, sz), false)
			x += 150.0
		canvas.draw_string(ThemeDB.fallback_font, Vector2(x - 600, y + 80), id, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		n += 1
		if n % 2 == 0:
			x = 80.0
			y += 190.0
		else:
			x = 920.0


func _process(_d: float) -> bool:
	f += 1
	if f % 20 == 0:
		canvas.queue_redraw()
	if bank.ready_all and f > 40:
		canvas.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SHOT_OUT") if OS.has_environment("SHOT_OUT") else "/tmp/shots/mechs.png")
		print("saved; baked=", bank._tex.size())
		quit()
		return true
	if f > 2500:
		print("timeout baked=", bank._tex.size())
		return true
	return false
