extends SceneTree
## Menu pause : le bouton « TERRAIN : HD / STANDARD » existe, bascule, et rien ne sort de l'écran.
class Stub extends Node:
	var fdata := {"accent": Color(0.4, 0.8, 1.0)}
	var over := false
	var mission := {}
	var admin := false
	var faction_id := "solis"
	var calls := 0
	func apply_terrain_quality() -> void:
		calls += 1
	func toggle_admin() -> void:
		admin = not admin
func _find_button(n: Node, prefix: String) -> Control:
	for c in n.find_children("*", "Control", true, false):
		if "text" in c and String(c.text).begins_with(prefix):
			return c
	return null
func _initialize() -> void:
	var failed := 0
	var cfg_before := DisplayCfg.terrain_hd()
	for size in [Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1920, 1200)]:
		var vp := SubViewport.new()
		vp.size = size
		root.add_child(vp)
		var g := Stub.new()
		vp.add_child(g)
		var pm := PauseMenu.new()
		vp.add_child(pm)
		await process_frame
		pm.setup(g)
		for i in 3:
			await process_frame
		var b := _find_button(pm, "TERRAIN")
		if b == null:
			failed += 1
			push_error("bouton TERRAIN introuvable")
		else:
			var t0: String = b.text
			b.pressed.emit()
			await process_frame
			if b.text == t0 or g.calls != 1:
				failed += 1
				push_error("la bascule n'a rien changé : %s -> %s (appels %d)" % [t0, b.text, g.calls])
			b.pressed.emit()
		var screen := Rect2(Vector2.ZERO, Vector2(size))
		for node in pm.find_children("*", "Control", true, false):
			var c := node as Control
			if c.is_visible_in_tree() and c.size.x > 0.0 and not screen.encloses(c.get_global_rect()):
				failed += 1
				print("HORS ÉCRAN ", size, " ", pm.get_path_to(c), " ", c.get_global_rect())
		paused = false
		vp.queue_free()
	if DisplayCfg.terrain_hd() != cfg_before:
		DisplayCfg.toggle_terrain()
	print("Résultat : %d échec(s)" % failed)
	quit(1 if failed > 0 else 0)
