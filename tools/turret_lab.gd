extends SceneTree
## Lab tourelles : cuit coque + tourelle (HD) et assemble la coque fixe avec la tourelle sous 4 caps différents.
## xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x800 --path . -s res://tools/turret_lab.gd
const IDS := ["sentinelle", "brute", "egide", "belier"]
const HULL := 0.7854
const TURRETS := [0.7854, 2.4, -0.6, -2.2]
const Z := 3.0
func _initialize() -> void:
	_run()
func _run() -> void:
	var sb := SpriteBank.new()
	sb.hd_units = true
	sb.ss_unit = 3.0
	root.add_child(sb)
	sb._make_viewport()
	var acc: Color = GameData.FACTIONS["solis"]["color"]
	var rows: Array = []
	for id in IDS:
		if not Models.has_turret(id):
			print("pas de tourelle: ", id)
			continue
		var k := "%s|solis" % id
		var tk := "%s_tete|solis" % id
		await sb._bake({"key": k, "id": id, "accent": acc, "faction": "solis", "angles": 16, "frame": SpriteBank.UNIT_FRAME, "extra": SpriteBank.UNIT_EXTRA, "ss": 3.0, "crop": true, "hd": true})
		await sb._bake({"key": tk, "id": id + "_tete", "accent": acc, "faction": "solis", "angles": 16, "frame": Vector2(96, 96), "extra": 44.0, "ss": 3.0, "crop": true, "hd": true})
		var cells: Array = []
		for ta in TURRETS:
			var img := Image.create(int(120 * Z), int(100 * Z), false, Image.FORMAT_RGBA8)
			img.fill(Color(0.86, 0.66, 0.56))
			var c := Vector2(img.get_width(), img.get_height()) * 0.5
			_blit(img, sb, k, HULL, c, Vector2.ZERO, HULL - sb.snap_angle(k, HULL))
			var po := Models.turret_offset(id, HULL)
			_blit(img, sb, tk, ta, c + po * Z, Vector2.ZERO, 0.0)
			cells.append(img)
		rows.append(cells)
	if rows.is_empty():
		quit(1)
		return
	var cw: int = rows[0][0].get_width()
	var ch: int = rows[0][0].get_height()
	var out := Image.create(cw * TURRETS.size(), ch * rows.size(), false, Image.FORMAT_RGBA8)
	for r in rows.size():
		for i in rows[r].size():
			out.blit_rect(rows[r][i], Rect2i(Vector2i.ZERO, rows[r][i].get_size()), Vector2i(i * cw, r * ch))
	out.save_png("/tmp/shots/tourelles.png")
	print("ok ", out.get_size())
	quit()
func _blit(dst: Image, sb: SpriteBank, key: String, ang: float, centre: Vector2, _o: Vector2, _rot: float) -> void:
	var tex: Texture2D = sb.frame(key, ang)
	var im := tex.get_image()
	var dr: Rect2 = sb.draw_rect(key, ang)
	var sz := Vector2i((dr.size * Z).round())
	im.resize(sz.x, sz.y, Image.INTERPOLATE_LANCZOS)
	dst.blend_rect(im, Rect2i(Vector2i.ZERO, sz), Vector2i((centre + dr.position * Z).round()))
