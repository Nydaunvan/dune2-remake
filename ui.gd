class_name GameUI
extends CanvasLayer
## Interface moderne : barre de ressources, panneau latéral en verre dépoli
## (radar, commandes, construction), notifications animées.

const SIDEBAR_W := 360.0
const MARGIN := 14.0
const COMMANDS := [
	["stop", "ARRÊT", true],
	["move", "DÉPLACER", true],
	["repair", "RÉPARER", false],
	["sell", "VENDRE", false],
]

var game # le nœud principal (main.gd)
var category := "building"
var root: Control
var sidebar: GlassPanel
var topbar: HudBar
var radar: Radar
var info_label: Label
var icon_box: GridContainer
var icons: Array = []
var tab_buttons: Array = []


func setup(p_game) -> void:
	game = p_game
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_topbar()
	_build_sidebar()
	_rebuild_icons()


func is_mouse_over_ui() -> bool:
	var m := get_viewport().get_mouse_position()
	return sidebar.get_global_rect().has_point(m) or topbar.get_global_rect().has_point(m)


## Notification qui monte et s'efface.
func toast(text: String, color := GameData.CREAM) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = -400.0
	l.offset_right = 400.0
	l.offset_top = 110.0
	l.offset_bottom = 150.0
	root.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "offset_top", 80.0, 2.2).from(110.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "offset_bottom", 120.0, 2.2).from(150.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(1.8)
	tw.chain().tween_callback(l.queue_free)


# --- Construction de l'interface ---------------------------------------------

func _build_topbar() -> void:
	topbar = HudBar.new()
	topbar.game = game
	topbar.position = Vector2(6, 6)
	topbar.size = Vector2(872, 84)
	root.add_child(topbar)


func _build_sidebar() -> void:
	sidebar = GlassPanel.new(0.0, 22.0)
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_top = 0.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = -SIDEBAR_W - MARGIN
	sidebar.offset_right = -MARGIN
	sidebar.offset_top = MARGIN
	sidebar.offset_bottom = -MARGIN
	root.add_child(sidebar)

	# Radar
	radar = Radar.new()
	radar.game = game
	radar.world_size = game.world_size
	radar.position = Vector2(30, 20)
	radar.size = Vector2(300, 300)
	sidebar.add_child(radar)

	# Commandes
	var bw := (SIDEBAR_W - 40.0 - 3.0 * 6.0) / 4.0
	for i in COMMANDS.size():
		var cmd: Array = COMMANDS[i]
		var b := NeonButton.new(cmd[1])
		b.enabled = cmd[2]
		b.tooltip_text = "" if cmd[2] else "Disponible dans un prochain jalon"
		b.position = Vector2(20 + i * (bw + 6.0), 336)
		b.size = Vector2(bw, 38)
		b.pressed.connect(game.on_command.bind(cmd[0]))
		sidebar.add_child(b)

	# Onglets
	var tabs := [["building", "BÂTIMENTS", GameData.CYAN], ["unit", "UNITÉS", GameData.MAGENTA]]
	for i in tabs.size():
		var t := NeonButton.new(tabs[i][1])
		t.accent = tabs[i][2]
		t.active = (i == 0)
		t.position = Vector2(20 + i * ((SIDEBAR_W - 40.0) / 2.0 + 0.0), 386)
		t.size = Vector2((SIDEBAR_W - 46.0) / 2.0, 40)
		t.pressed.connect(_set_category.bind(tabs[i][0]))
		sidebar.add_child(t)
		tab_buttons.append(t)

	# Icônes de production
	icon_box = GridContainer.new()
	icon_box.columns = 2
	icon_box.add_theme_constant_override("h_separation", 8)
	icon_box.add_theme_constant_override("v_separation", 8)
	icon_box.position = Vector2(20, 438)
	sidebar.add_child(icon_box)

	# Infos en bas du panneau
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 15)
	info_label.add_theme_color_override("font_color", GameData.CREAM)
	info_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	info_label.add_theme_constant_override("outline_size", 4)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.anchor_top = 1.0
	info_label.anchor_bottom = 1.0
	info_label.anchor_left = 0.0
	info_label.anchor_right = 1.0
	info_label.offset_left = 22
	info_label.offset_right = -22
	info_label.offset_top = -96
	info_label.offset_bottom = -18
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sidebar.add_child(info_label)


func _set_category(cat: String) -> void:
	category = cat
	for i in tab_buttons.size():
		tab_buttons[i].active = (i == (0 if cat == "building" else 1))
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


func _process(_delta: float) -> void:
	if game == null:
		return
	if game.placing_id != "":
		info_label.text = "Clic gauche : poser le bâtiment\nClic droit ou Échap : annuler"
	elif game.command_mode == "move":
		info_label.text = "Cliquez sur la carte pour déplacer les unités sélectionnées."
	else:
		info_label.text = "%d unité(s) sélectionnée(s)\nClic droit sur une icône : annuler (remboursé)\nF11 : plein écran" \
				% game.selected.size()


# --- Barre de ressources ------------------------------------------------------

class HudBar extends GlassPanel:
	var game
	var shown_credits := 0.0
	var _init_done := false

	func _init() -> void:
		super(8.0, 18.0)

	func _process(delta: float) -> void:
		if game == null:
			return
		if not _init_done:
			shown_credits = float(game.credits)
			_init_done = true
		shown_credits = lerpf(shown_credits, float(game.credits), clampf(delta * 7.0, 0.0, 1.0))
		queue_redraw()

	func _text(pos: Vector2, s: String, fs: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
		var font := ThemeDB.fallback_font
		draw_string_outline(font, pos, s, align, w, fs, 5, Color(0, 0, 0, 0.85))
		draw_string(font, pos, s, align, w, fs, col)

	func _draw() -> void:
		if game == null:
			return
		var o := 8.0
		var dim := Color(0.55, 0.9, 1.0, 0.8)

		# Solaris : le compteur glisse vers la valeur réelle et clignote vert/rouge
		var diff: float = float(game.credits) - shown_credits
		var col := GameData.GOLD
		if absf(diff) > 1.0:
			var k := clampf(absf(diff) / 200.0, 0.0, 1.0)
			col = GameData.GOLD.lerp(Color("5dff9a") if diff > 0.0 else Color("ff5a4a"), k)
		_text(Vector2(o + 24, o + 22), "SOLARIS", 12, dim)
		_text(Vector2(o + 24, o + 56), str(int(round(shown_credits))), 30, col)
		draw_circle(Vector2(o + 10, o + 46), 7.0, GameData.AMBER_HDR)

		# Énergie : jauge néon
		var prod: int = game.power_produced()
		var used: int = game.power_used()
		var ratio := 1.0 if used <= 0 else clampf(float(prod) / float(used), 0.0, 1.0)
		var ok := prod >= used
		var gcol := GameData.CYAN if ok else GameData.RED
		_text(Vector2(o + 270, o + 22), "ÉNERGIE", 12, dim)
		_text(Vector2(o + 270, o + 56), "%d / %d" % [prod, used], 22, Color(1, 1, 1) if ok else GameData.RED)
		var track := Rect2(o + 400, o + 40, 190, 10)
		draw_rect(track, Color(1, 1, 1, 0.12))
		draw_rect(Rect2(track.position, Vector2(track.size.x * ratio, track.size.y)), gcol)

		# Temps
		var t: float = game.game_time
		_text(Vector2(o + 620, o + 22), "TEMPS", 12, dim)
		_text(Vector2(o + 620, o + 56),
				"%02d:%02d:%02d" % [int(t / 3600.0), int(t / 60.0) % 60, int(t) % 60], 24, Color.WHITE)

		# Images par seconde
		_text(Vector2(o + 760, o + 22), "FPS", 12, dim)
		_text(Vector2(o + 760, o + 56), str(Engine.get_frames_per_second()), 22, GameData.GREEN)


# --- Bouton néon --------------------------------------------------------------

class NeonButton extends Control:
	signal pressed

	var text := ""
	var enabled := true
	var active := false
	var accent := Color(0.0, 1.5, 1.9)
	var hover_t := 0.0
	var press_t := 0.0
	var _hover := false
	var _sb := StyleBoxFlat.new()

	func _init(p_text: String) -> void:
		text = p_text
		mouse_filter = Control.MOUSE_FILTER_STOP
		_sb.set_corner_radius_all(11)
		_sb.set_border_width_all(2)
		_sb.anti_aliasing = true
		mouse_entered.connect(func() -> void: _hover = true)
		mouse_exited.connect(func() -> void: _hover = false)

	func _process(delta: float) -> void:
		hover_t = move_toward(hover_t, 1.0 if (_hover and enabled) else 0.0, delta * 8.0)
		press_t = move_toward(press_t, 0.0, delta * 4.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if enabled:
				press_t = 1.0
				pressed.emit()
			accept_event()

	func _draw() -> void:
		var lit := 1.0 if active else maxf(hover_t, press_t)
		var col := accent if enabled else Color(0.35, 0.3, 0.4)
		_sb.bg_color = Color(0.06, 0.04, 0.12, 0.85).lerp(
				Color(col.r * 0.22, col.g * 0.22, col.b * 0.22, 0.95), lit)
		_sb.border_color = Color(col.r, col.g, col.b, 0.45 + 0.55 * lit)
		_sb.shadow_color = Color(col.r, col.g, col.b, 0.55 * lit)
		_sb.shadow_size = int(14.0 * lit)
		draw_style_box(_sb, Rect2(Vector2.ZERO, size))
		var tc := Color(1, 1, 1, 0.95) if enabled else Color(0.5, 0.45, 0.55)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, size.y * 0.5 + 5.0), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, tc)


# --- Carte de production ------------------------------------------------------

class BuildIcon extends Control:
	signal clicked(id: String, button: int)

	var id := ""
	var game
	var hover_t := 0.0
	var _hover := false
	var _sb := StyleBoxFlat.new()

	func _init(p_id: String, p_game) -> void:
		id = p_id
		game = p_game
		custom_minimum_size = Vector2(160, 132)
		mouse_filter = Control.MOUSE_FILTER_STOP
		_sb.set_corner_radius_all(14)
		_sb.set_border_width_all(2)
		_sb.anti_aliasing = true
		var d := GameData.def(id)
		var tip := "%s — %d $" % [d["name"], d["cost"]]
		var names := PackedStringArray()
		for r in d["requires"]:
			names.append(GameData.BUILDINGS[r]["name"])
		if not names.is_empty():
			tip += "\nNécessite : " + ", ".join(names)
		tooltip_text = tip
		mouse_entered.connect(func() -> void: _hover = true)
		mouse_exited.connect(func() -> void: _hover = false)

	func _process(delta: float) -> void:
		hover_t = move_toward(hover_t, 1.0 if _hover else 0.0, delta * 8.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			clicked.emit(id, event.button_index)
			accept_event()

	func _draw() -> void:
		var d := GameData.def(id)
		var avail: bool = game.is_available(id)
		var p: Dictionary = game.production_for(id)
		var ready: bool = (not p.is_empty()) and bool(p["ready"])
		var busy: bool = (not p.is_empty()) and not bool(p["ready"])
		var t := Time.get_ticks_msec() / 1000.0
		var pulse := 0.5 + 0.5 * sin(t * 5.0)

		var accent := GameData.CYAN if avail else Color(0.4, 0.35, 0.5)
		if ready:
			accent = GameData.GREEN
		var lit := maxf(hover_t, 0.35 + 0.65 * pulse if ready else 0.0)
		_sb.bg_color = Color(0.06, 0.04, 0.12, 0.8).lerp(
				Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.2, 0.95), lit)
		_sb.border_color = Color(accent.r, accent.g, accent.b, 0.4 + 0.6 * lit)
		_sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.5 * lit)
		_sb.shadow_size = int(16.0 * lit)
		draw_style_box(_sb, Rect2(Vector2.ZERO, size))

		var c := Vector2(size.x * 0.5, 50.0 - hover_t * 2.0)
		_draw_icon(c, avail)
		if busy:
			draw_arc(c, 38.0, 0.0, TAU, 48, Color(1, 1, 1, 0.12), 4.0, true)
			draw_arc(c, 38.0, -PI / 2.0, -PI / 2.0 + TAU * float(p["progress"]), 48,
					GameData.AMBER_HDR, 4.0, true)
		elif ready:
			draw_arc(c, 38.0, 0.0, TAU, 48, GameData.GREEN, 4.0, true)

		var font := ThemeDB.fallback_font
		var tc := Color(1, 1, 1, 0.95) if avail else Color(0.5, 0.45, 0.55)
		draw_string(font, Vector2(0, 108), String(d["name"]).to_upper(),
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, tc)
		if ready:
			draw_string(font, Vector2(0, 124), "PRÊT — CLIC !", HORIZONTAL_ALIGNMENT_CENTER, size.x, 13,
					Color(0.5, 1.0, 0.7, 0.6 + 0.4 * pulse))
		else:
			draw_string(font, Vector2(0, 124), "%d $" % d["cost"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 13,
					GameData.GOLD if avail else Color(0.4, 0.35, 0.3))

	func _draw_icon(c: Vector2, avail: bool) -> void:
		var fill := Color("2a3350") if avail else Color("201c2c")
		var line := GameData.CYAN if avail else Color(0.4, 0.35, 0.5)
		match id:
			"centrale":
				for s in [-1.0, 1.0]:
					var cc: Vector2 = c + Vector2(15.0 * s, 4.0)
					draw_circle(cc, 14.0, fill)
					draw_arc(cc, 14.0, 0.0, TAU, 28, line, 2.0, true)
			"raffinerie":
				draw_rect(Rect2(c + Vector2(-34, -12), Vector2(44, 28)), fill)
				draw_rect(Rect2(c + Vector2(-34, -12), Vector2(44, 28)), line, false, 2.0)
				draw_circle(c + Vector2(20, 2), 15.0, fill)
				draw_arc(c + Vector2(20, 2), 15.0, 0.0, TAU, 28, line, 2.0, true)
			"usine":
				draw_rect(Rect2(c + Vector2(-34, -8), Vector2(68, 26)), fill)
				draw_rect(Rect2(c + Vector2(-34, -8), Vector2(68, 26)), line, false, 2.0)
				draw_rect(Rect2(c + Vector2(16, -20), Vector2(10, 14)), fill)
				draw_rect(Rect2(c + Vector2(16, -20), Vector2(10, 14)), line, false, 2.0)
			"char":
				draw_rect(Rect2(c + Vector2(-20, -12), Vector2(40, 24)), fill)
				draw_rect(Rect2(c + Vector2(-20, -12), Vector2(40, 24)), line, false, 2.0)
				draw_circle(c, 8.0, fill)
				draw_arc(c, 8.0, 0.0, TAU, 20, line, 2.0, true)
				draw_line(c, c + Vector2(28, 0), line, 3.0, true)
