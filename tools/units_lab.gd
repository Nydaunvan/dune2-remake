extends SceneTree
## Planche des unités d'une faction : coque + tourelle assemblées sous deux caps (2e ligne : phase de marche pour les mechas).
## FACTION=kharn IDS=brute,titan xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x800 --path . -s res://tools/units_lab.gd
const Z := 4.0
var fac := "kharn"
func _initialize() -> void:
	_run()
func _run() -> void:
	if OS.has_environment("FACTION"):
		fac = OS.get_environment("FACTION")
	var sb := SpriteBank.new()
	sb.hd_units = true
	sb.ss_unit = 3.0
	root.add_child(sb)
	sb._make_viewport()
	var acc: Color = GameData.FACTIONS[fac]["color"]
	var ids: Array = GameData.units_for(fac)
	if OS.get_environment("IDS") != "":
		ids = OS.get_environment("IDS").split(",")
	var angs := [0.7854, 3.9]
	var cells: Array = []
	for id in ids:
		var k := "%s|%s" % [id, fac]
		var tk := "%s_tete|%s" % [id, fac]
		var is_mech: bool = ModelsExt.STYLES.get(id, {}).get("k", "") == "mech"
		await sb._bake({"key": k, "id": id, "accent": acc, "faction": fac, "angles": 16, "frame": SpriteBank.UNIT_FRAME, "extra": SpriteBank.UNIT_EXTRA, "ss": 3.0, "crop": true, "hd": true})
		var has_t := Models.has_turret(id, fac)
		if has_t:
			await sb._bake({"key": tk, "id": id + "_tete", "accent": acc, "faction": fac, "angles": 16, "frame": Vector2(96, 96), "extra": 44.0, "ss": 3.0, "crop": true, "hd": true})
		var variants: Array = [""]
		if is_mech:
			variants = ["", "w2"]
			await sb._bake({"key": k + "|w2", "id": id, "accent": acc, "faction": fac, "angles": 16, "frame": SpriteBank.UNIT_FRAME, "extra": SpriteBank.UNIT_EXTRA, "phase": 0.25, "ss": 3.0, "crop": true, "hd": true})
		for a in angs:
			for v in variants:
				var img := Image.create(int(80 * Z), int(70 * Z), false, Image.FORMAT_RGBA8)
				img.fill(Color(0.86, 0.66, 0.56))
				var c := Vector2(img.get_width(), img.get_height()) * 0.5
				var kk: String = k if v == "" else k + "|" + v
				_blit(img, sb, kk, a, c)
				if has_t:
					_blit(img, sb, tk, a, c + Models.turret_offset(id, a, fac) * Z)
				cells.append(img)
	var cols := 4
	var rows := int(ceil(cells.size() / float(cols)))
	var cw: int = cells[0].get_width()
	var ch: int = cells[0].get_height()
	var out := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGBA8)
	for i in cells.size():
		out.blit_rect(cells[i], Rect2i(Vector2i.ZERO, cells[i].get_size()), Vector2i((i % cols) * cw, (i / cols) * ch))
	var path := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/shots/units_%s.png" % fac
	out.save_png(path)
	print("ok ", out.get_size(), " ", path)
	quit()
func _blit(dst: Image, sb: SpriteBank, key: String, ang: float, centre: Vector2) -> void:
	var tex: Texture2D = sb.frame(key, ang)
	var im := tex.get_image()
	var dr: Rect2 = sb.draw_rect(key, ang)
	var sz := Vector2i((dr.size * Z).round())
	im.resize(sz.x, sz.y, Image.INTERPOLATE_LANCZOS)
	dst.blend_rect(im, Rect2i(Vector2i.ZERO, sz), Vector2i((centre + dr.position * Z).round()))
