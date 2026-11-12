extends Control
## Menu principal : choix de la faction, puis lancement de la partie.
## Campagnes : à venir. Escarmouche : affrontement contre une IA.

var selected := GameSession.faction
var cards := {}
var _hint: Label


func _ready() -> void:
	theme = UiStyle.theme()
	RenderingServer.set_default_clear_color(Color("0c0610"))
	Fx.setup_display(self, true)
	var snd := Sfx.new()
	add_child(snd)
	snd.start_music()

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
	vb.add_theme_constant_override("separation", 16)
	center.add_child(vb)

	vb.add_child(TitleBanner.new())
	vb.add_child(_label("— CHOISISSEZ VOTRE FACTION —", 20, Color(1.0, 0.85, 0.7), true))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 34)
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
	campaign.pressed.connect(_open_campaign)
	var skirmish := GameUI.NeonButton.new("ESCARMOUCHE")
	skirmish.accent = GameData.MAGENTA
	skirmish.pressed.connect(_start)
	var load_btn := GameUI.NeonButton.new("CHARGER")
	load_btn.accent = GameData.GREEN
	load_btn.pressed.connect(_open_load)
	var quit := GameUI.NeonButton.new("QUITTER")
	quit.accent = GameData.RED
	quit.pressed.connect(get_tree().quit)
	for b in [campaign, skirmish, load_btn, quit]:
		b.custom_minimum_size = Vector2(250, 58)
		btns.add_child(b)

	var opp := CheckButton.new()
	opp.text = "Escarmouche à 3 camps (2 adversaires)"
	opp.button_pressed = GameSession.opponents >= 2
	opp.add_theme_font_size_override("font_size", 16)
	opp.toggled.connect(func(on: bool) -> void: GameSession.opponents = 2 if on else 1)
	opp.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(opp)

	_hint = _label("Campagne : 5 missions par faction — Escarmouche : détruisez la base adverse", 15,
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


# --- Chargement d'une sauvegarde ---------------------------------------------

func _open_load() -> void:
	if _overlay != null:
		_overlay.queue_free()
	_overlay = ColorRect.new()
	(_overlay as ColorRect).color = Color(0.045, 0.024, 0.075, 1.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	cc.add_child(vb)
	vb.add_child(_label("CHARGER UNE PARTIE", 46, Color.WHITE, true))
	var slots := SaveSlots.new(false)
	slots.load_requested.connect(func(slot: int) -> void:
		GameSession.load_slot = slot
		get_tree().change_scene_to_file("res://main.tscn"))
	vb.add_child(slots)
	var back := GameUI.NeonButton.new("RETOUR")
	back.accent = GameData.RED
	back.custom_minimum_size = Vector2(250, 56)
	back.pressed.connect(func() -> void: _overlay.queue_free(); _overlay = null)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	vb.add_child(hb)


# --- Sélection de mission -----------------------------------------------------

var _overlay: Control


func _open_campaign() -> void:
	if _overlay != null:
		_overlay.queue_free()
	var fd: Dictionary = GameData.FACTIONS[selected]
	var done := Campaign.cleared(selected)
	_overlay = ColorRect.new()
	(_overlay as ColorRect).color = Color(0.045, 0.024, 0.075, 1.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	cc.add_child(vb)
	vb.add_child(_label("CAMPAGNE — " + String(fd["name"]).to_upper(), 46, fd["accent"], true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	vb.add_child(row)
	for i in Campaign.count(selected):
		row.add_child(_mission_card(i, done, fd))
	var back := GameUI.NeonButton.new("RETOUR")
	back.accent = GameData.RED
	back.custom_minimum_size = Vector2(250, 56)
	back.pressed.connect(func() -> void: _overlay.queue_free(); _overlay = null)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	vb.add_child(hb)


func _mission_card(i: int, done: int, fd: Dictionary) -> Control:
	var m: Dictionary = Campaign.mission(selected, i)
	var unlocked := i <= done
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(340, 640)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.04, 0.13, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = fd["color"] if unlocked else Color(0.3, 0.27, 0.35)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(20)
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pc.add_child(v)
	var tag := "MISSION %d" % (i + 1)
	if i < done:
		tag += "  —  TERMINÉE"
	v.add_child(_left(tag, 15, GameData.GOLD))
	v.add_child(_left(String(m["title"]).to_upper(), 24, Color.WHITE))
	var br := _left(Campaign.briefing(selected, i), 14, Color(1, 1, 1, 0.8))
	br.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	br.custom_minimum_size = Vector2(300, 330)
	v.add_child(br)
	v.add_child(_left("OBJECTIF", 13, GameData.GOLD))
	var ob := _left(String(m["obj"]), 15, Color.WHITE)
	ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ob.custom_minimum_size = Vector2(300, 40)
	v.add_child(ob)
	v.add_child(_left("Adversaire : " + String(GameData.FACTIONS[Campaign.enemy_of(selected, i)]["name"]), 15,
			Color(1, 0.55, 0.5)))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var det := GameUI.NeonButton.new("DÉTAILS")
	det.accent = GameData.CYAN
	det.custom_minimum_size = Vector2(300, 44)
	det.pressed.connect(_open_details.bind(i))
	v.add_child(det)
	var go := GameUI.NeonButton.new("JOUER" if unlocked else "VERROUILLÉE")
	go.enabled = unlocked
	go.accent = fd["accent"]
	go.custom_minimum_size = Vector2(300, 50)
	go.pressed.connect(func() -> void:
		GameSession.faction = selected
		GameSession.mode = "campaign"
		GameSession.mission = i
		get_tree().change_scene_to_file("res://main.tscn"))
	v.add_child(go)
	return pc


func _open_details(i: int) -> void:
	var fd: Dictionary = GameData.FACTIONS[selected]
	var m: Dictionary = Campaign.mission(selected, i)
	var ov := ColorRect.new()
	ov.color = Color(0.045, 0.024, 0.075, 1.0)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(ov)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	cc.add_child(vb)
	vb.add_child(_label("MISSION %d — %s" % [i + 1, String(m["title"]).to_upper()], 40, fd["accent"], true))
	var br := _left(Campaign.briefing(selected, i), 16, Color(1, 1, 1, 0.8))
	br.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	br.custom_minimum_size = Vector2(1100, 0)
	vb.add_child(br)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 14)
	vb.add_child(grid)
	for sec in Campaign.details(selected, i):
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(530, 0)
		box.add_theme_constant_override("separation", 4)
		box.add_child(_left(String(sec[0]), 14, GameData.GOLD))
		for line in sec[1]:
			var l := _left("◆ " + String(line), 15, Color.WHITE)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(520, 0)
			box.add_child(l)
		grid.add_child(box)
	var back := GameUI.NeonButton.new("RETOUR")
	back.accent = GameData.RED
	back.custom_minimum_size = Vector2(250, 56)
	back.pressed.connect(func() -> void: ov.queue_free())
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	vb.add_child(hb)


func _left(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


# --- Carte de faction ---------------------------------------------------------

class TitleBanner extends Control:
	## Titre du jeu : reflet qui parcourt les lettres, filets et losanges de part et d'autre.
	const TITLE := "THE BUILDING OF A DYNASTY"

	func _init() -> void:
		custom_minimum_size = Vector2(1000, 132)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var f := UiStyle.title_font()
		var fs := 66
		var total := 0.0
		var adv: Array = []
		for ch in TITLE:
			var w := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x + 3.0
			adv.append(w)
			total += w
		var x := (size.x - total) * 0.5
		var y := 78.0
		var wave := fmod(t * 0.28, 1.6) * (total + 300.0) - 150.0
		for i in TITLE.length():
			var ch := TITLE[i]
			var k := clampf(1.0 - absf((x - (size.x - total) * 0.5) - wave) / 130.0, 0.0, 1.0)
			var col := Color(0.97, 0.93, 0.88).lerp(Color(1.0, 0.78, 0.35), k)
			draw_string_outline(f, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, 10, Color(0, 0, 0, 0.85))
			draw_string(f, Vector2(x + 2, y + 3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.85, 0.2, 0.3, 0.35))
			draw_string(f, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, col)
			x += adv[i]
		# Filets ornementaux
		var cx := size.x * 0.5
		var ly := 108.0
		var half := total * 0.5
		for sgn in [-1.0, 1.0]:
			draw_line(Vector2(cx + sgn * 70.0, ly), Vector2(cx + sgn * half, ly), Color(1.0, 0.8, 0.4, 0.55), 1.4, true)
			draw_line(Vector2(cx + sgn * 70.0, ly + 5), Vector2(cx + sgn * (half - 60.0), ly + 5), Color(1.0, 0.8, 0.4, 0.25), 1.0, true)
			var d := Vector2(cx + sgn * half, ly)
			draw_colored_polygon(PackedVector2Array([d + Vector2(0, -5), d + Vector2(5, 0), d + Vector2(0, 5), d + Vector2(-5, 0)]), UiStyle.GOLD)
		var c := Vector2(cx, ly)
		var pulse := 0.8 + 0.2 * sin(t * 2.5)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(8, 0), c + Vector2(0, 8), c + Vector2(-8, 0)]),
				Color(UiStyle.GOLD.r, UiStyle.GOLD.g, UiStyle.GOLD.b, pulse))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3), c + Vector2(3, 0), c + Vector2(0, 3), c + Vector2(-3, 0)]), Color.WHITE)


class FactionCard extends Control:
	signal chosen(id: String)

	var id := ""
	var active := false
	var hover_t := 0.0
	var lit_t := 0.0
	var _hover := false

	func _init(p_id: String) -> void:
		id = p_id
		custom_minimum_size = Vector2(420, 560)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func() -> void: _hover = true)
		mouse_exited.connect(func() -> void: _hover = false)

	func _process(delta: float) -> void:
		hover_t = move_toward(hover_t, 1.0 if _hover else 0.0, delta * 7.0)
		lit_t = move_toward(lit_t, 1.0 if active else 0.0, delta * 5.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			chosen.emit(id)
			accept_event()

	func _draw() -> void:
		var f: Dictionary = GameData.FACTIONS[id]
		var col: Color = f["color"] * 1.5
		col.a = 1.0
		var acc: Color = f["accent"]
		var t := Time.get_ticks_msec() / 1000.0
		var lit := maxf(lit_t, hover_t * 0.55)
		var r := Rect2(Vector2.ZERO, size)
		# Cadre biseauté à lueur
		var line := Color(col.r, col.g, col.b, 0.4 + 0.6 * lit)
		var fill := Color(0.05, 0.025, 0.09, 0.86).lerp(Color(col.r * 0.1, col.g * 0.1, col.b * 0.1, 0.92), lit)
		UiStyle.frame(self, r, 26.0, line, fill, lit * 1.2, 0.0)
		# Bandeau de couleur et reflet supérieur
		draw_rect(Rect2(30, 3, size.x - 60, 3), Color(col.r, col.g, col.b, 0.35 + 0.65 * lit))
		draw_rect(Rect2(3, 8, size.x - 6, 230), Color(col.r, col.g, col.b, 0.05 + 0.08 * lit))
		_draw_embers(col, t, lit)
		_draw_emblem(Vector2(size.x * 0.5, 125.0), col, t, lit)
		# Nom et devise
		UiStyle.text(self, Vector2(0, 258), String(f["name"]).to_upper(), 30, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		UiStyle.text(self, Vector2(0, 285), String(f["tagline"]), 17, acc, false, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		draw_line(Vector2(60, 302), Vector2(size.x - 60, 302), Color(col.r, col.g, col.b, 0.35), 1.2, true)
		var y := 332.0
		for l in String(f["desc"]).split("\n"):
			UiStyle.text(self, Vector2(24, y), l, 15, Color(1, 1, 1, 0.88), false, HORIZONTAL_ALIGNMENT_CENTER, size.x - 48)
			y += 23.0
		y += 18.0
		UiStyle.section(self, Vector2(34, y), size.x - 68, "UNITÉS UNIQUES", acc)
		y += 30.0
		for uid in f["units"]:
			var u: Dictionary = GameData.UNITS[uid]
			draw_colored_polygon(PackedVector2Array([Vector2(34, y - 5), Vector2(39, y - 10), Vector2(44, y - 5), Vector2(39, y)]), acc)
			UiStyle.text(self, Vector2(54, y), String(u["name"]), 17, Color.WHITE, true)
			UiStyle.text(self, Vector2(196, y), String(u["desc"]), 13, Color(1, 1, 1, 0.62))
			y += 28.0
		# Pied : état de sélection
		var fy := size.y - 24.0
		if active:
			var a := 0.75 + 0.25 * sin(t * 5.0)
			UiStyle.text(self, Vector2(0, fy), "◆  SÉLECTIONNÉE  ◆", 14, Color(col.r, col.g, col.b, a), true, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		else:
			UiStyle.text(self, Vector2(0, fy), "CLIQUER POUR CHOISIR", 12, Color(1, 1, 1, 0.3 + 0.3 * hover_t), false, HORIZONTAL_ALIGNMENT_CENTER, size.x)

	## Braises montantes dans la zone de l'emblème.
	func _draw_embers(col: Color, t: float, lit: float) -> void:
		for i in 18:
			var sp := 0.05 + 0.04 * fmod(i * 0.37, 1.0)
			var yy := fposmod(1.0 - (t * sp + i * 0.173), 1.0)
			var xx := 0.1 + 0.8 * fposmod(i * 0.6180339 + sin(t * 0.7 + i) * 0.03, 1.0)
			var a := sin(yy * PI) * (0.25 + 0.5 * lit)
			draw_circle(Vector2(size.x * xx, 30.0 + yy * 205.0), 1.2 + 1.2 * fmod(i * 0.29, 1.0), Color(col.r, col.g, col.b, a))

	func _ring(c: Vector2, rad: float, col: Color, a0: float, segs: int, gap: float, w: float) -> void:
		var step := TAU / segs
		for i in segs:
			draw_arc(c, rad, a0 + i * step, a0 + (i + 1) * step - gap, 8, col, w, true)

	func _draw_emblem(c: Vector2, col: Color, t: float, lit: float) -> void:
		var boost := 1.0 + lit * 0.6
		# halo respirant
		for k in 5:
			draw_circle(c, 86.0 - k * 9.0 + sin(t * 1.6) * 3.0, Color(col.r, col.g, col.b, (0.025 + 0.02 * lit) * (k + 1)))
		draw_circle(c, 64.0, Color(col.r * 0.12, col.g * 0.12, col.b * 0.12, 0.95))
		draw_arc(c, 64.0, 0.0, TAU, 72, Color(col.r, col.g, col.b, 0.9), 2.5, true)
		match id:
			"solis": # soleil : rayons rotatifs, anneau contre-rotatif, satellites
				_ring(c, 74.0, Color(col.r, col.g, col.b, 0.55), -t * 0.5 * boost, 24, 0.12, 2.0)
				var pulse := 1.0 + 0.12 * sin(t * 2.4)
				draw_circle(c, 17.0 * pulse, col)
				draw_circle(c, 11.0 * pulse, Color(1, 1, 1, 0.55))
				for i in 16:
					var a := TAU * i / 16.0 + t * 0.35 * boost
					var long := i % 2 == 0
					var r0 := 26.0
					var r1 := (50.0 if long else 40.0) + (4.0 * sin(t * 3.0 + i) if long else 0.0)
					draw_line(c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a) * r1, col, 4.0 if long else 2.5, true)
				for j in 3:
					var oa := t * (0.9 + 0.25 * j) + j * 2.09
					draw_circle(c + Vector2.from_angle(oa) * 74.0, 3.5, Color(1, 0.95, 0.8))
			"kharn": # écu, chevrons parcourus par une onde, anneau hexagonal
				var hexa := -t * 0.25 * boost
				var hp := PackedVector2Array()
				for i in 7:
					hp.append(c + Vector2.from_angle(hexa + TAU * i / 6.0) * 76.0)
				draw_polyline(hp, Color(col.r, col.g, col.b, 0.6), 2.0, true)
				var bob := sin(t * 1.8) * 2.0
				var cc := c + Vector2(0, bob)
				var shield := PackedVector2Array([cc + Vector2(-32, -36), cc + Vector2(32, -36), cc + Vector2(32, 8),
						cc + Vector2(0, 44), cc + Vector2(-32, 8)])
				draw_colored_polygon(shield, Color(col.r * 0.45, col.g * 0.45, col.b * 0.45))
				draw_polyline(PackedVector2Array(Array(shield) + [shield[0]]), col, 3.0, true)
				for i in 3:
					var wv := clampf(0.35 + 0.65 * sin(t * 3.2 * boost - i * 0.9) , 0.15, 1.0)
					var yy := -16.0 + i * 16.0
					draw_polyline(PackedVector2Array([cc + Vector2(-22, yy), cc + Vector2(0, yy + 22), cc + Vector2(22, yy)]),
							Color(col.r, col.g, col.b, wv), 5.0, true)
			_: # œil : pupille qui suit la souris, clignement, balayage radar
				_ring(c, 74.0, Color(col.r, col.g, col.b, 0.5), t * 0.6 * boost, 3, 1.1, 2.0)
				for k in 3:
					var ph := fposmod(t * 0.5 + k / 3.0, 1.0)
					draw_arc(c, 30.0 + ph * 40.0, 0.0, TAU, 48, Color(col.r, col.g, col.b, (1.0 - ph) * 0.45), 2.0, true)
				var bph := fposmod(t, 4.2)
				var blink := 1.0 if bph < 3.9 else clampf(absf(bph - 4.05) / 0.15, 0.08, 1.0)
				var ey := 27.0 * blink
				var eye := PackedVector2Array([c + Vector2(-46, 0), c + Vector2(0, -ey), c + Vector2(46, 0), c + Vector2(0, ey)])
				draw_colored_polygon(eye, Color(col.r * 0.45, col.g * 0.45, col.b * 0.45))
				draw_polyline(PackedVector2Array(Array(eye) + [eye[0]]), col, 3.0, true)
				var look := (get_local_mouse_position() - c)
				look = look.limit_length(60.0) / 60.0 * 8.0
				if blink > 0.5:
					draw_circle(c + look, 12.0, col)
					draw_circle(c + look, 5.0, Color.BLACK)
					draw_circle(c + look + Vector2(-3, -3), 2.0, Color(1, 1, 1, 0.8))
