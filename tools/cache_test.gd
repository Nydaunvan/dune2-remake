extends SceneTree
## Cache disque des sprites : 1re cuisson (lente) puis relecture (rapide), images identiques.
## xvfb-run -a godot --rendering-driver opengl3 --path . -s res://tools/cache_test.gd
var fails := 0
func _initialize() -> void:
	_run()
func _mk() -> SpriteBank:
	var sb := SpriteBank.new()
	sb.hd_units = true
	sb.ss_unit = 2.0
	sb.ss_building = 2.0
	root.add_child(sb)
	sb._make_viewport()
	var accent: Color = GameData.FACTIONS["solis"]["color"]
	sb._jobs = [
		{"key": "recolteur|solis", "id": "recolteur", "accent": accent, "faction": "solis", "angles": 16, "frame": SpriteBank.UNIT_FRAME, "extra": SpriteBank.UNIT_EXTRA, "ss": 2.0, "crop": true, "hd": true},
		{"key": "raffinerie|solis", "id": "raffinerie", "accent": accent, "faction": "solis", "angles": 1, "frame": Vector2(3 * 32 + 44, 2 * 32 + 44), "extra": SpriteBank.BUILDING_EXTRA, "ss": 2.0, "hd": true},
		{"key": "raffinerie|solis|L2", "id": "raffinerie", "accent": accent, "faction": "solis", "angles": 1, "frame": Vector2(3 * 32 + 44, 2 * 32 + 44), "extra": SpriteBank.BUILDING_EXTRA, "ss": 2.0, "hd": true, "tier": 2},
	]
	return sb
func _check(ok: bool, m: String) -> void:
	print(("OK  " if ok else "KO  ") + m)
	if not ok:
		fails += 1
func _run() -> void:
	var a := _mk()
	var t0 := Time.get_ticks_msec()
	a._bake_all()
	while not a.ready_all:
		await process_frame
	print("cuisson : core_ok=", a.core_ok, " core %d/%d" % [a.core_done, a.core_total])
	var t_bake := (Time.get_ticks_msec() - t0) / 1000.0
	var b := _mk()
	t0 = Time.get_ticks_msec()
	b._bake_all()
	while not b.ready_all:
		await process_frame
	var t_load := (Time.get_ticks_msec() - t0) / 1000.0
	print("cuisson %.1f s / cache %.2f s" % [t_bake, t_load])
	_check(t_load < t_bake * 0.5, "relecture bien plus rapide")
	_check(a.core_ok and a.core_total == 16 + 1, "indispensable détecté (%d images)" % a.core_total)
	for k in ["recolteur|solis", "raffinerie|solis", "raffinerie|solis|L2"]:
		_check(b.has(k), "clé %s présente" % k)
		var n: int = a._tex[k].size()
		_check(b._tex[k].size() == n, "%s : %d images" % [k, n])
		var same := true
		for i in n:
			var ia: Image = (a._tex[k][i] as ImageTexture).get_image()
			var ib: Image = (b._tex[k][i] as ImageTexture).get_image()
			if ia.get_data() != ib.get_data():
				same = false
		_check(same, "%s : pixels identiques" % k)
		_check(a._used[k] == b._used[k] and a._off[k] == b._off[k] and a._full[k] == b._full[k] and a._size[k] == b._size[k], "%s : métadonnées identiques" % k)
	print("Résultat : %d échec(s)" % fails)
	quit(1 if fails > 0 else 0)
