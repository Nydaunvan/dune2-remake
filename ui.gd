class_name GameUI
extends CanvasLayer
## Interface : barre de ressources (haut-gauche) et panneau latéral (radar,
## commandes, menu de construction).

const SIDEBAR_W := 270.0
const COMMANDS := [
	["stop", "Arrêt", true],
	["move", "Déplacer", true],
	["repair", "Réparer", false],
	["sell", "Vendre", false],
]

var game # le nœud principal (main.gd)
var category := "building"
var sidebar: Panel
var topbar: PanelContainer
var radar: Radar
var credits_label: Label
var power_label: Label
var time_label: Label
var info_label: Label
var icon_box: GridContainer
var icons: Array = []


func setup(p_game) -> void:
	game = p_game
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_topbar(root)
	_build_sidebar(root)
	_rebuild_icons()


func is_mouse_over_ui() -> bool:
	var m := get_viewport().get_mouse_position()
	return sidebar.get_global_rect().has_point(m) or topbar.get_global_rect().has_point(m)


# --- Construction de l'interface ---------------------------------------------

func _build_topbar(root: Control) -> void:
	topbar = PanelContainer.new()
	topbar.position = Vector2(10, 10)
	var sb := _flat(Color(0.11, 0.06, 0.13, 0.85), GameData.AMBER.darkened(0.3))
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	topbar.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 28)
	topbar.add_child(hb)
	credits_label = _label(15)
	power_label = _label(15)
	time_label = _label(15)
	hb.add_child(credits_label)
	hb.add_child(power_label)
	hb.add_child(time_label)
	root.add_child(topbar)


func _build_sidebar(root: Control) -> void:
	sidebar = Panel.new()
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_top = 0.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = -SIDEBAR_W
	sidebar.offset_right = 0.0
	sidebar.offset_top = 0.0
	sidebar.offset_bottom = 0.0
	var sb := _flat(Color(0.11, 0.06, 0.13, 0.88), GameData.AMBER.darkened(0.3))
	sb.border_width_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 0
	sb.border_width_left = 3
	sb.set_corner_radius_all(0)
	sidebar.add_theme_stylebox_override("panel", sb)
	root.add_child(sidebar)

	# Radar
	radar = Radar.new()
	radar.game = game
	radar.world_size = game.world_size
	radar.position = Vector2(15, 14)
	radar.size = Vector2(240, 240)
	sidebar.add_child(radar)

	# Commandes
	var bw := (SIDEBAR_W - 30.0 - 3.0 * 4.0) / 4.0
	for i in COMMANDS.size():
		var cmd: Array = COMMANDS[i]
		var b := Button.new()
		b.text = cmd[1]
		b.disabled = not cmd[2]
		b.tooltip_text = "" if cmd[2] else "Disponible dans un prochain jalon"
		b.position = Vector2(15 + i * (bw + 4.0), 264)
		b.size = Vector2(bw, 30)
		_style_button(b)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(game.on_command.bind(cmd[0]))
		sidebar.add_child(b)

	# Onglets Bâtiments / Unités
	var group := ButtonGroup.new()
	var tabs := [["building", "Bâtiments"], ["unit", "Unités"]]
	for i in tabs.size():
		var t := Button.new()
		t.text = tabs[i][1]
		t.toggle_mode = true
		t.button_group = group
		t.button_pressed = (i == 0)
		t.position = Vector2(15 + i * 122, 304)
		t.size = Vector2(118, 28)
		_style_button(t)
		t.pressed.connect(_set_category.bind(tabs[i][0]))
		sidebar.add_child(t)

	# Icônes de production
	icon_box = GridContainer.new()
	icon_box.columns = 2
	icon_box.add_theme_constant_override("h_separation", 4)
	icon_box.add_theme_constant_override("v_separation", 4)
	icon_box.position = Vector2(15, 340)
	sidebar.add_child(icon_box)

	# Informations en bas du panneau
	info_label = _label(12)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.anchor_top = 1.0
	info_label.anchor_bottom = 1.0
	info_label.anchor_left = 0.0
	info_label.anchor_right = 1.0
	info_label.offset_left = 15
	info_label.offset_right = -15
	info_label.offset_top = -80
	info_label.offset_bottom = -12
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sidebar.add_child(info_label)


func _set_category(cat: String) -> void:
	category = cat
	_rebuild_icons()


func _rebuild_icons() -> void:
	for c in icon_box.get_children():
		icon_box.remove_child(c)
		c.queue_free()
	icons.clear()
	var data: Dictionary = GameData.BUILDINGS if category == "building" else GameData.UNITS
	for id in data.keys():
		var icon := BuildIcon.new(id, game)
		icon.clicked.connect(game.on_item_clicked)
		icon_box.add_child(icon)
		icons.append(icon)


# --- Mise à jour --------------------------------------------------------------

func _process(_delta: float) -> void:
	if game == null:
		return
	credits_label.text = "Solaris : %d" % game.credits
	var prod: int = game.power_produced()
	var used: int = game.power_used()
	power_label.text = "Énergie : %d / %d" % [prod, used]
	power_label.add_theme_color_override("font_color",
			GameData.RED if used > prod else GameData.CREAM)
	var t: float = game.game_time
	time_label.text = "%02d:%02d:%02d" % [int(t / 3600.0), int(t / 60.0) % 60, int(t) % 60]

	if game.placing_id != "":
		info_label.text = "Clic gauche : poser le bâtiment\nClic droit ou Échap : annuler"
	elif game.command_mode == "move":
		info_label.text = "Cliquez sur la carte pour déplacer les unités sélectionnées."
	else:
		info_label.text = "%d unité(s) sélectionnée(s)\nClic droit sur une icône : annuler (remboursé)" \
				% game.selected.size()
	for i in icons:
		i.queue_redraw()


# --- Utilitaires de style -----------------------------------------------------

func _label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", GameData.CREAM)
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(4)
	return s


func _style_button(b: Button) -> void:
	var press := _flat(Color("6a3a1a"), GameData.AMBER)
	b.add_theme_stylebox_override("normal", _flat(Color("2a1830"), GameData.AMBER.darkened(0.4)))
	b.add_theme_stylebox_override("hover", _flat(Color("43264a"), GameData.AMBER))
	b.add_theme_stylebox_override("pressed", press)
	b.add_theme_stylebox_override("hover_pressed", press)
	b.add_theme_stylebox_override("disabled", _flat(Color("1a1220"), Color("3a2a3a")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", GameData.CREAM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.4, 0.45))
	b.add_theme_font_size_override("font_size", 12)


# --- Icône de production ------------------------------------------------------

class BuildIcon extends Control:
	signal clicked(id: String, button: int)

	var id := ""
	var game
	var hover := false

	func _init(p_id: String, p_game) -> void:
		id = p_id
		game = p_game
		custom_minimum_size = Vector2(118, 92)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var d := GameData.def(id)
		var tip := "%s — %d $" % [d["name"], d["cost"]]
		var names := PackedStringArray()
		for r in d["requires"]:
			names.append(GameData.BUILDINGS[r]["name"])
		if not names.is_empty():
			tip += "\nNécessite : " + ", ".join(names)
		tooltip_text = tip
		mouse_entered.connect(_set_hover.bind(true))
		mouse_exited.connect(_set_hover.bind(false))

	func _set_hover(v: bool) -> void:
		hover = v
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			clicked.emit(id, event.button_index)
			accept_event()

	func _draw() -> void:
		var d := GameData.def(id)
		var avail: bool = game.is_available(id)
		var p: Dictionary = game.production_for(id)
		var bg := Color("2a1830") if avail else Color("1a1220")
		draw_rect(Rect2(Vector2.ZERO, size), bg)
		draw_rect(Rect2(Vector2.ZERO, size),
				GameData.AMBER if hover else GameData.AMBER.darkened(0.55), false, 1.5)
		_draw_icon(Rect2(8, 6, size.x - 16, 46))
		var font := ThemeDB.fallback_font
		var txt := GameData.CREAM if avail else Color(0.5, 0.45, 0.5)
		draw_string(font, Vector2(8, 68), d["name"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 13, txt)
		draw_string(font, Vector2(8, 85), "%d $" % d["cost"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 12,
				GameData.AMBER if avail else Color(0.4, 0.35, 0.3))
		if not avail:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
		if not p.is_empty():
			if p["ready"]:
				draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.5, 0.2, 0.45))
				draw_string(font, Vector2(0, 40), "PRÊT", HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color.WHITE)
			else:
				draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(0, size.y - 7, size.x * p["progress"], 7), GameData.AMBER)

	func _draw_icon(r: Rect2) -> void:
		var c := r.get_center()
		var steel := Color("8d94a8")
		var trim := GameData.AMBER
		match id:
			"centrale":
				draw_circle(c + Vector2(-14, 4), 13.0, steel)
				draw_circle(c + Vector2(14, 4), 13.0, steel.lightened(0.15))
				draw_arc(c + Vector2(-14, 4), 13.0, 0.0, TAU, 24, trim, 2.0)
				draw_arc(c + Vector2(14, 4), 13.0, 0.0, TAU, 24, trim, 2.0)
			"raffinerie":
				draw_rect(Rect2(c + Vector2(-34, -12), Vector2(44, 28)), steel)
				draw_rect(Rect2(c + Vector2(-34, -12), Vector2(44, 28)), trim, false, 2.0)
				draw_circle(c + Vector2(20, 2), 15.0, steel.lightened(0.15))
				draw_arc(c + Vector2(20, 2), 15.0, 0.0, TAU, 24, trim, 2.0)
			"usine":
				draw_rect(Rect2(c + Vector2(-36, -8), Vector2(72, 26)), steel)
				draw_rect(Rect2(c + Vector2(18, -20), Vector2(10, 14)), steel.darkened(0.3))
				for i in 4:
					draw_rect(Rect2(c + Vector2(-30 + i * 14, -4), Vector2(8, 18)), steel.darkened(0.2))
			"char":
				draw_rect(Rect2(c + Vector2(-18, -11), Vector2(36, 22)), Color("6f7f9e"))
				draw_circle(c, 8.0, Color("4a5875"))
				draw_line(c, c + Vector2(26, 0), Color.BLACK, 4.0)
