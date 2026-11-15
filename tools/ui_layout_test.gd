extends SceneTree
## Menu principal : aucun contrôle hors écran aux tailles réellement obtenues (stretch canvas_items + expand).
const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1920, 1440), Vector2i(1920, 1200)]
func _initialize() -> void:
	var failed := 0
	for size in SIZES:
		var vp := SubViewport.new()
		vp.size = size
		root.add_child(vp)
		var ui = load("res://menu.tscn").instantiate()
		vp.add_child(ui)
		await process_frame
		await process_frame
		await process_frame
		var screen := Rect2(Vector2.ZERO, Vector2(size))
		var n := 0
		for node in ui.find_children("*", "Control", true, false):
			var c := node as Control
			if c.is_visible_in_tree() and c.size.x > 0.0 and not screen.encloses(c.get_global_rect()):
				failed += 1
				if n < 6:
					print("HORS ÉCRAN ", size, " ", ui.get_path_to(c), " ", c.get_global_rect())
				n += 1
		vp.queue_free()
	print("Résultat : %d contrôle(s) hors écran" % failed)
	quit(1 if failed > 0 else 0)
