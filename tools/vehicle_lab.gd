extends SceneTree
## Exemple « véhicules ultra HD » : cuit les mêmes modèles en standard (SS 2) et en HD (SS 4 + shader de coque + détails),
## puis assemble une image comparative (gauche = actuel agrandi comme le moteur le ferait à fort zoom, droite = HD).
## xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x800 --path . -s res://tools/vehicle_lab.gd
const IDS := ["recolteur", "belier", "brute"]
const ANGLE := 0.7854 # 45° : vue 3/4
const ZOOM := 4.0     # agrandissement d'affichage (pixels d'écran par pixel du monde)
func _initialize() -> void:
	_run()
func _grab(id: String, hd: bool, ss: float) -> Image:
	Models.hd = hd
	var sb := SpriteBank.new()
	sb.ss = ss
	root.add_child(sb)
	sb._make_viewport()
	var acc: Color = GameData.FACTIONS["solis"]["color"]
	await sb._bake({"key": "k", "id": id, "accent": acc, "faction": "solis", "angles": 16, "frame": SpriteBank.UNIT_FRAME, "extra": SpriteBank.UNIT_EXTRA})
	var tex: Texture2D = sb.frame("k", ANGLE)
	var img := tex.get_image()
	var ur := sb.used_rect("k", ANGLE).grow(3.0)
	var crop := img.get_region(Rect2i(ur.intersection(Rect2(Vector2.ZERO, img.get_size()))))
	# mise à l'échelle d'affichage : ZOOM / ss (bilinéaire quand on agrandit, comme en jeu ; lissage quand on réduit)
	var k := ZOOM / ss
	crop.resize(int(crop.get_width() * k), int(crop.get_height() * k), Image.INTERPOLATE_BILINEAR if k >= 1.0 else Image.INTERPOLATE_LANCZOS)
	sb.queue_free()
	Models.hd = false
	return crop
func _run() -> void:
	var rows: Array = []
	for id in IDS:
		var a := await _grab(id, false, 2.0)
		var b := await _grab(id, true, 4.0)
		rows.append([a, b])
	var w := 0
	var h := 0
	for r in rows:
		w = max(w, r[0].get_width() + r[1].get_width() + 60)
		h += max(r[0].get_height(), r[1].get_height()) + 24
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.86, 0.66, 0.56))
	var y := 12
	for r in rows:
		var rh: int = max(r[0].get_height(), r[1].get_height())
		out.blend_rect(r[0], Rect2i(Vector2i.ZERO, r[0].get_size()), Vector2i(20, y + (rh - r[0].get_height()) / 2))
		out.blend_rect(r[1], Rect2i(Vector2i.ZERO, r[1].get_size()), Vector2i(40 + r[0].get_width(), y + (rh - r[1].get_height()) / 2))
		y += rh + 24
	out.save_png("/tmp/shots/vehicules_comparaison.png")
	print("image : ", out.get_size())
	quit()
