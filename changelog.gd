class_name Changelog
extends CanvasLayer
## Journal des versions consultable partout : liste cliquable à gauche, détail à droite.
## Ouvert depuis le menu principal (numéro de version), le menu pause et la touche F2.

var _was_paused := false
var _detail: RichTextLabel
var _buttons := {}


static func open(host: Node) -> Changelog:
	for c in host.get_tree().root.get_children():
		if c is Changelog:
			return c
	var g := Changelog.new()
	host.get_tree().root.add_child(g)
	g.setup()
	return g


func setup() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var root := Control.new()
	root.theme = UiStyle.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.06, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 120)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	root.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "JOURNAL DES VERSIONS — v%s" % ChangelogData.current()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UiStyle.title_font())
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GameData.GOLD)
	vb.add_child(title)

	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)

	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(330, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	sc.add_child(list)
	for e in ChangelogData.VERSIONS:
		var b := GameUI.NeonButton.new("v%s  %s" % [e[0], e[2]])
		b.custom_minimum_size = Vector2(310, 38)
		b.pressed.connect(_show.bind(e[0]))
		list.add_child(b)
		_buttons[e[0]] = b

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.1, 0.97)
	sb.border_color = Color(0.0, 0.8, 1.0, 0.5)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	hb.add_child(panel)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.add_theme_font_size_override("normal_font_size", 19)
	_detail.add_theme_font_size_override("bold_font_size", 19)
	_detail.add_theme_color_override("default_color", Color(0.9, 0.9, 0.95))
	panel.add_child(_detail)

	var close := GameUI.NeonButton.new("FERMER  (F2 / Échap)")
	close.accent = GameData.RED
	close.custom_minimum_size = Vector2(260, 46)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(close_changelog)
	vb.add_child(close)
	_show(ChangelogData.current())


func _show(ver: String) -> void:
	for k in _buttons:
		_buttons[k].active = (k == ver)
	for e in ChangelogData.VERSIONS:
		if e[0] != ver:
			continue
		var s := "[font_size=28][color=#ffcc55][b]Version %s[/b][/color][/font_size]\n" % e[0]
		s += "[color=#7fe9ff][b]%s[/b][/color]  [color=#9a9ab0](%s)[/color]\n\n" % [e[2], e[1]]
		for it in e[3]:
			s += "•  %s\n" % it
		_detail.text = s
		return


func close_changelog() -> void:
	get_tree().paused = _was_paused
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F2):
		get_viewport().set_input_as_handled()
		close_changelog()
