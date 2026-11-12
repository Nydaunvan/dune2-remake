extends SceneTree
## Planche-contact des nouvelles unités / nouveaux bâtiments d'une faction (modèles ModelsExt).
## xvfb-run -a godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --script tools/ext_shot.gd
var bank: SpriteBank
var canvas: Node2D
var f := 0
var fac := "solis"
var out := "/tmp/shots/ext.png"


func _initialize() -> void:
	if OS.has_environment("FACTION"):
		fac = OS.get_environment("FACTION")
	if OS.has_environment("SHOT_OUT"):
		out = OS.get_environment("SHOT_OUT")
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
	var y := 70.0
	var ids: Array = []
	for id in GameData.FACTIONS[fac]["units"] + GameData.FACTIONS[fac]["air"]:
		if ModelsExt.has(id):
			ids.append(id)
	for id in ids:
		var key := "%s|%s" % [id, fac]
		if not bank.has(key):
			continue
		var sz := bank.draw_size(key)
		for a in [0.0, 0.9]:
			canvas.draw_texture_rect(bank.frame(key, a), Rect2(Vector2(x, y) - sz / 2.0, sz), false)
			x += 100.0
		x += 14.0
		if x > 1650:
			x = 60.0
			y += 120.0
	x = 90.0
	y = maxf(y + 150.0, 470.0)
	for id in GameData.buildings_for(fac):
		if not ModelsExt.has(id) or GameData.def(id).get("faction", "") != fac:
			continue
		var key := "%s|%s" % [id, fac]
		if not bank.has(key):
			continue
		var sz := bank.draw_size(key)
		if x + sz.x > 1750:
			x = 90.0
			y += 190.0
		canvas.draw_texture_rect(bank.frame(key), Rect2(Vector2(x, y) - sz / 2.0 + Vector2(sz.x / 2.0, 0), sz), false)
		var hk := "%s_tete|%s" % [id, fac]
		if bank.has(hk):
			var hs := bank.draw_size(hk)
			canvas.draw_texture_rect(bank.frame(hk, 0.0), Rect2(Vector2(x + sz.x / 2.0, y) - hs / 2.0, hs), false)
		x += sz.x + 12.0


func _process(_d: float) -> bool:
	f += 1
	if f % 20 == 0:
		canvas.queue_redraw()
	if bank.ready_all and f > 30:
		canvas.queue_redraw()
		if f > 45:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out)
			print("saved ", out, " baked=", bank._tex.size())
			quit()
			return true
	if f > 3000:
		print("timeout baked=", bank._tex.size())
		return true
	return false
