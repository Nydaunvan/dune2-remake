class_name PauseMenu
extends CanvasLayer
## Menu pause (Échap) : reprendre, sauvegarder / charger à tout moment, retour au menu.

var game
var slots: SaveSlots


func setup(p_game) -> void:
	game = p_game
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.theme = UiStyle.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	cc.add_child(vb)
	var t := Label.new()
	t.text = "PAUSE"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", UiStyle.title_font())
	t.add_theme_font_size_override("font_size", 52)
	t.add_theme_color_override("font_color", game.fdata["accent"])
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	t.add_theme_constant_override("outline_size", 10)
	vb.add_child(t)
	slots = SaveSlots.new(not game.over)
	slots.save_requested.connect(_on_save)
	slots.load_requested.connect(_on_load)
	vb.add_child(slots)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	vb.add_child(hb)
	var resume := GameUI.NeonButton.new("REPRENDRE")
	resume.custom_minimum_size = Vector2(250, 56)
	resume.pressed.connect(close)
	hb.add_child(resume)
	var menu := GameUI.NeonButton.new("MENU PRINCIPAL")
	menu.accent = GameData.RED
	menu.custom_minimum_size = Vector2(250, 56)
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://menu.tscn"))
	hb.add_child(menu)
	get_tree().paused = true


func _on_save(slot: int) -> void:
	if game.save_game(slot, false):
		slots.refresh()
		slots.set_status("Partie sauvegardée — %s" % SaveGame.slot_name(slot))
	else:
		slots.set_status("Échec de la sauvegarde", GameData.RED)


func _on_load(slot: int) -> void:
	game.load_game(slot)


func close() -> void:
	get_tree().paused = false
	game.pause_menu = null
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
