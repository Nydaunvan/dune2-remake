extends Control
## Menu principal : choix de la faction, puis lancement de la partie.
## Campagnes : à venir. Escarmouche : bac à sable pour l'instant (IA au prochain jalon).

var selected := GameSession.faction
var cards := {}
var _hint: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0c0610"))
	Fx.setup_display(self, true)

	var bg := ColorRect.new()
	bg.color = Color.WHITE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/menu_bg.gdshader")
	bg.material = mat
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 22)
	center.add_child(vb)

	vb.add_child(_label("DUNE II — REMAKE", 76, Color.WHITE, true))
	vb.add_child(_label("Choisissez votre faction", 26, Color(1.0, 0.85, 0.7), true))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	for id in GameData.FACTIONS.keys():
		var card := FactionCard.new(id)
		card.chosen.connect(_on_chosen)
		row.add_child(card)
		cards[id] = card
	_refresh_cards()

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 20)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(btns)
	var campaign := GameUI.NeonButton.new("CAMPAGNE")
	campaign.enabled = false
	campaign.tooltip_text = "Les campagnes arrivent dans un prochain jalon"
	var skirmish := GameUI.NeonButton.new("ESCARMOUCHE")
	skirmish.accent = GameData.MAGENTA
	skirmish.pressed.connect(_start)
	var quit := GameUI.NeonButton.new("QUITTER")
	quit.accent = GameData.RED
	quit.pressed.connect(get_tree().quit)
	for b in [campaign, skirmish, quit]:
		b.custom_minimum_size = Vector2(250, 58)
		btns.add_child(b)

	_hint = _label("Campagnes : bientôt — Escarmouche : bac à sable (IA au prochain jalon)", 15,
			Color(1, 1, 1, 0.55), false)
	vb.add_child(_hint)


func _label(text: String, size: int, color: Color, outline: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 10)
	return l


func _on_chosen(id: String) -> void:
	selected = id
	_refresh_cards()


func _refresh_cards() -> void:
	for id in cards.keys():
		cards[id].active = (id == selected)


func _start() -> void:
	GameSession.faction = selected
	GameSession.mode = "skirmish"
	get_tree().change_scene_to_file("res://main.tscn")


# --- Carte de faction ---------------------------------------------------------

class FactionCard extends Control:
	signal chosen(id: String)

	var id := ""
	var active := false
	var hover_t := 0.0
	var _hover := false
	var _sb := StyleBoxFlat.new()

	func _init(p_id: String) -> void:
		id = p_id
		custom_minimum_size = Vector2(440, 560)
		mouse_filter = Control.MOUSE_FILTER_STOP
		_sb.set_corner_radius_all(22)
		_sb.set_border_width_all(3)
		_sb.anti_aliasing = true
		mouse_entered.connect(func() -> void: _hover = true)
		mouse_exited.connect(func() -> void: _hover = false)

	func _process(delta: float) -> void:
		hover_t = move_toward(hover_t, 1.0 if _hover else 0.0, delta * 7.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			chosen.emit(id)
			accept_event()

	func _draw() -> void:
		var f: Dictionary = GameData.FACTIONS[id]
		var col: Color = f["color"] * 1.5
		col.a = 1.0
		var lit := 1.0 if active else hover_t * 0.6
		_sb.bg_color = Color(0.06, 0.03, 0.10, 0.82).lerp(Color(col.r * 0.12, col.g * 0.12, col.b * 0.12, 0.92), lit)
		_sb.border_color = Color(col.r, col.g, col.b, 0.35 + 0.65 * lit)
		_sb.shadow_color = Color(col.r, col.g, col.b, 0.6 * lit)
		_sb.shadow_size = int(26.0 * lit)
		draw_style_box(_sb, Rect2(Vector2.ZERO, size))

		var t := Time.get_ticks_msec() / 1000.0
		_draw_emblem(Vector2(size.x * 0.5, 120.0), col, t)

		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(0, 232), f["name"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 32, 6, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, 232), f["name"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 32, Color.WHITE)
		draw_string(font, Vector2(0, 262), f["tagline"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, f["accent"])

		var y := 304.0
		for line in String(f["desc"]).split("\n"):
			draw_string(font, Vector2(24, y), line, HORIZONTAL_ALIGNMENT_CENTER, size.x - 48, 16, Color(1, 1, 1, 0.85))
			y += 24.0
		y += 12.0
		draw_string(font, Vector2(24, y), "UNITÉS UNIQUES", HORIZONTAL_ALIGNMENT_LEFT, size.x - 48, 13, Color(1, 1, 1, 0.5))
		y += 26.0
		for uid in f["units"]:
			var u: Dictionary = GameData.UNITS[uid]
			draw_string(font, Vector2(24, y), String(u["name"]), HORIZONTAL_ALIGNMENT_LEFT, 160, 17, Color.WHITE)
			draw_string(font, Vector2(150, y), String(u["desc"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 170, 14, Color(1, 1, 1, 0.65))
			y += 28.0
		if active:
			draw_string(font, Vector2(0, size.y - 22), "SÉLECTIONNÉE", HORIZONTAL_ALIGNMENT_CENTER, size.x, 15,
					Color(col.r, col.g, col.b, 0.7 + 0.3 * sin(t * 5.0)))

	func _draw_emblem(c: Vector2, col: Color, t: float) -> void:
		draw_circle(c, 62.0, Color(col.r * 0.2, col.g * 0.2, col.b * 0.2, 0.9))
		draw_arc(c, 62.0, 0.0, TAU, 64, col, 3.0, true)
		match id:
			"solis": # soleil à rayons
				draw_circle(c, 20.0, col)
				for i in 12:
					var a := TAU * i / 12.0 + t * 0.4
					draw_line(c + Vector2.from_angle(a) * 28.0, c + Vector2.from_angle(a) * 46.0, col, 4.0, true)
			"kharn": # écu et chevrons
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(-30, -34), c + Vector2(30, -34), c + Vector2(30, 6),
					c + Vector2(0, 40), c + Vector2(-30, 6)]), Color(col.r * 0.5, col.g * 0.5, col.b * 0.5))
				draw_polyline(PackedVector2Array([c + Vector2(-22, -14), c + Vector2(0, 8), c + Vector2(22, -14)]), col, 5.0, true)
				draw_polyline(PackedVector2Array([c + Vector2(-22, 2), c + Vector2(0, 24), c + Vector2(22, 2)]), col, 5.0, true)
			_: # œil / losange
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(-44, 0), c + Vector2(0, -26), c + Vector2(44, 0), c + Vector2(0, 26)]),
					Color(col.r * 0.5, col.g * 0.5, col.b * 0.5))
				draw_circle(c + Vector2(sin(t * 1.3) * 4.0, 0.0), 11.0, col)
				draw_circle(c, 4.0, Color.BLACK)
