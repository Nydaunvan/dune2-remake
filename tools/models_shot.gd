extends SceneTree
## Planche-contact des modèles 3D cuits. Nécessite un affichage (xvfb-run, opengl3).
var bank: SpriteBank
var canvas: Node2D
var f := 0
var fac := "solis"


func _initialize() -> void:
	if OS.has_environment("FACTION"):
		fac = OS.get_environment("FACTION")
	bank = SpriteBank.new()
	root.add_child(bank)
	bank.setup(null, [fac])
	canvas = Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(_draw_sheet)
	var bg := ColorRect.new()
	bg.color = Color("c98f78")
	bg.size = Vector2(1800, 1000)
	root.add_child(bg)
	root.move_child(bg, 0)


func _draw_sheet() -> void:
	var x := 60.0
	var y := 90.0
	for id in ["recolteur", "mineur"] + GameData.FACTIONS[fac]["units"]:
		var key := "%s|%s" % [id, fac]
		if not bank.has(key):
			continue
		var sz := bank.draw_size(key)
		for a in [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]:
			canvas.draw_texture_rect(bank.frame(key, a), Rect2(Vector2(x, y) - sz / 2.0, sz), false)
			x += 100.0
		x += 20.0
		if x > 1500:
			x = 60.0
			y += 150.0
	x = 150.0
	y = 450.0
	for id in ["chantier", "centrale", "raffinerie", "fonderie", "usine", "tourelle"]:
		var key := "%s|%s" % [id, fac]
		if not bank.has(key):
			continue
		var sz := bank.draw_size(key)
		canvas.draw_texture_rect(bank.frame(key), Rect2(Vector2(x, y) - sz / 2.0, sz), false)
		x += sz.x + 10.0
		if x > 1600:
			x = 150.0
			y += 230.0
	var tk := "tourelle_tete|%s" % fac
	if bank.has(tk):
		var sz := bank.draw_size(tk)
		for k in 4:
			canvas.draw_texture_rect(bank.frame(tk, k * PI / 2.0), Rect2(Vector2(150 + k * 110, 900) - sz / 2.0, sz), false)


func _process(_d: float) -> bool:
	f += 1
	if f % 20 == 0:
		canvas.queue_redraw()
	if bank.ready_all and f > 30:
		canvas.queue_redraw()
		if f > 40 + int(bank.ready_all) * 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("SHOT_OUT") if OS.has_environment("SHOT_OUT") else "/tmp/shots/models.png")
			print("saved; baked=", bank._tex.size())
			quit()
			return true
	if f > 1500:
		print("timeout baked=", bank._tex.size())
		return true
	return false
