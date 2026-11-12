extends SceneTree
## Vérification rapide des sprites (sans lancer le jeu) : cuit les sprites d'une ou plusieurs factions
## (env FACTION=solis ou "all"), contrôle automatiquement qu'ils existent/ne sont pas vides, que chaque
## bâtiment armé a sa tête, puis écrit une planche (SHOT_OUT) corps + tête, et son index texte.
func _initialize() -> void:
	var facs: Array = ["solis", "kharn", "vael", "conclave"] if OS.get_environment("FACTION") in ["", "all"] else [OS.get_environment("FACTION")]
	var bank := SpriteBank.new()
	root.add_child(bank)
	var t0 := Time.get_ticks_msec()
	bank.setup(null, facs)
	await bank.finished
	print("cuisson ms:", Time.get_ticks_msec() - t0)
	var problems := 0
	var cell := 112
	var cols := 14
	var entries: Array = []
	for fac in facs:
		var ids: Array = ["chantier", "mcv", "recolteur", "mineur", "centrale", "raffinerie", "fonderie", "usine", "tourelle"]
		ids += GameData.buildings_for(fac)
		ids += GameData.FACTIONS[fac]["units"] + GameData.FACTIONS[fac]["air"]
		var seen := {}
		for id in ids:
			if seen.has(id) or GameData.def(id).get("wall", false):
				continue
			seen[id] = true
			var key := "%s|%s" % [id, fac]
			if not bank.has(key):
				print("MANQUANT corps ", key)
				problems += 1
				continue
			var ur: Rect2 = bank.used_rect(key)
			if ur.size.x < 4 or ur.size.y < 4:
				print("VIDE ", key)
				problems += 1
			var head := ""
			var d: Dictionary = GameData.def(id)
			if id == "radar":
				head = "radar_tete|%s" % fac
			elif GameData.BUILDINGS.has(id) and d.has("weapon"):
				head = "%s_tete|%s" % [id, fac]
				if not bank.has(head):
					head = "tourelle_tete|%s" % fac if id != "tourelle" else head
				if not bank.has("%s_tete|%s" % [id, fac]) and id != "tourelle":
					print("TETE PARTAGEE (tourelle) pour ", key)
			entries.append([key, head])
	var rows := int(ceil(entries.size() / float(cols)))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.07, 0.15))
	var idx := ""
	for i in entries.size():
		var key: String = entries[i][0]
		var ox := (i % cols) * cell
		var oy := (i / cols) * cell
		_blit(sheet, bank.frame(key, 0.0), ox, oy, cell)
		if entries[i][1] != "" and bank.has(entries[i][1]):
			_blit(sheet, bank.frame(entries[i][1], 0.0), ox, oy, cell)
		idx += "%d:%s%s  " % [i, key, "+tete" if entries[i][1] != "" else ""]
		if i % 6 == 5:
			idx += "\n"
	print(idx)
	var out := OS.get_environment("SHOT_OUT")
	if out != "":
		sheet.save_png(out)
	print("PROBLEMES=", problems, " entrées=", entries.size())
	quit()
func _blit(sheet: Image, tex: Texture2D, ox: int, oy: int, cell: int) -> void:
	if tex == null:
		return
	var im := tex.get_image()
	if im.is_compressed():
		im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	var sc := minf(float(cell) / im.get_width(), float(cell) / im.get_height())
	im.resize(int(im.get_width() * sc), int(im.get_height() * sc), Image.INTERPOLATE_BILINEAR)
	sheet.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(ox + (cell - im.get_width()) / 2, oy + (cell - im.get_height()) / 2))
