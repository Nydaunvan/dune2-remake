class_name SaveSlots
extends VBoxContainer
## Liste des emplacements de sauvegarde (menu pause et menu principal).

signal save_requested(slot: int)
signal load_requested(slot: int)

var can_save := false
var _status: Label


func _init(p_can_save: bool) -> void:
	can_save = p_can_save
	add_theme_constant_override("separation", 10)


func _ready() -> void:
	_build()


func set_status(text: String, color := GameData.GREEN) -> void:
	if _status != null:
		_status.text = text
		_status.add_theme_color_override("font_color", color)


func refresh() -> void:
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	for slot in SaveGame.SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		add_child(row)
		var vb := VBoxContainer.new()
		vb.custom_minimum_size = Vector2(560, 0)
		vb.add_theme_constant_override("separation", 0)
		row.add_child(vb)
		var title := Label.new()
		title.text = SaveGame.slot_name(slot)
		title.add_theme_font_size_override("font_size", 17)
		title.add_theme_color_override("font_color", GameData.GOLD)
		vb.add_child(title)
		var info := SaveGame.describe(slot)
		var l := Label.new()
		l.text = info if info != "" else "— vide —"
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.8 if info != "" else 0.4))
		vb.add_child(l)
		if can_save:
			var sb := PlateButton.new("SAUVEGARDER", 5)
			sb.font_size = 14
			sb.custom_minimum_size = Vector2(200, 52)
			sb.pressed.connect(func() -> void: save_requested.emit(slot))
			row.add_child(sb)
		var lb := PlateButton.new("CHARGER", 3)
		lb.font_size = 14
		lb.custom_minimum_size = Vector2(200, 52)
		lb.enabled = info != ""
		lb.pressed.connect(func() -> void: load_requested.emit(slot))
		row.add_child(lb)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)
