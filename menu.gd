extends Control
## Menu principal : choix de la faction, puis lancement de la partie.
## Escarmouche : affrontement contre 1 à 3 IA.

var selected := GameSession.faction
var cards := {}
var _hint: Label


func _ready() -> void:
	UiStyle.fix_gamma()
	DisplayCfg.apply()
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
	row.add_theme_constant_override("separation", 22)
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
	var campaign := PlateButton.new("CAMPAGNE", 3)
	campaign.pressed.connect(_open_campaign)
	var skirmish := PlateButton.new("ESCARMOUCHE", 2)
	skirmish.pressed.connect(_open_skirmish)
	var load_btn := PlateButton.new("CHARGER", 5)
	load_btn.pressed.connect(_open_load)
	var guide_btn := PlateButton.new("GUIDE", 4)
	guide_btn.pressed.connect(func() -> void: Guide.open(self, selected))
	var quit := PlateButton.new("QUITTER", 1)
	quit.pressed.connect(get_tree().quit)
	for b in [campaign, skirmish, load_btn, guide_btn, quit]:
		b.custom_minimum_size = Vector2(250, 64)
		btns.add_child(b)

	_hint = _label("Campagne : 15 à 18 missions par faction — Escarmouche : détruisez la ou les bases adverses", 15,
			Color(1, 1, 1, 0.55), false)
	vb.add_child(_hint)

	# Numéro de version : simple texte cliquable → journal des versions
	var ver := Label.new()
	ver.text = "Version %s — Nouveautés" % ChangelogData.current()
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 15)
	ver.add_theme_color_override("font_color", Color(GameData.GOLD.r, GameData.GOLD.g, GameData.GOLD.b, 0.75))
	ver.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	ver.add_theme_constant_override("outline_size", 3)
	ver.mouse_filter = Control.MOUSE_FILTER_STOP
	ver.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ver.mouse_entered.connect(func() -> void: ver.add_theme_color_override("font_color", Color(1, 1, 1, 1)))
	ver.mouse_exited.connect(func() -> void: ver.add_theme_color_override("font_color", Color(GameData.GOLD.r, GameData.GOLD.g, GameData.GOLD.b, 0.75)))
	ver.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Changelog.open(self))
	vb.add_child(ver)


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


# --- Paramètres de l'escarmouche ---------------------------------------------

func _open_skirmish() -> void:
	if _overlay != null:
		_overlay.queue_free()
	var fd: Dictionary = GameData.FACTIONS[selected]
	var others: Array = GameData.FACTIONS.keys().filter(func(k: String) -> bool: return k != selected)
	if GameSession.skirm_foe != "" and not others.has(GameSession.skirm_foe):
		GameSession.skirm_foe = ""
	_overlay = ColorRect.new()
	(_overlay as ColorRect).color = Color(0.045, 0.024, 0.075, 1.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	cc.add_child(vb)
	vb.add_child(_label("ESCARMOUCHE — " + String(fd["name"]).to_upper(), 44, fd["accent"], true))

	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.04, 0.13, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = fd["color"]
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(26)
	pc.add_theme_stylebox_override("panel", sb)
	vb.add_child(pc)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 20)
	pc.add_child(rows)

	var two := GameSession.opponents >= 2
	rows.add_child(_option_row("NOMBRE D'ADVERSAIRES", [
		["1 ADVERSAIRE", GameSession.opponents <= 1, func() -> void: GameSession.opponents = 1],
		["2 ADVERSAIRES", GameSession.opponents == 2, func() -> void: GameSession.opponents = 2],
		["3 ADVERSAIRES", GameSession.opponents >= 3, func() -> void: GameSession.opponents = 3]]))
	var foe_opts: Array = [["ALÉATOIRE", GameSession.skirm_foe == "", func() -> void: GameSession.skirm_foe = ""]]
	for k in others:
		foe_opts.append([String(GameData.FACTIONS[k]["name"]).to_upper(), GameSession.skirm_foe == k,
				func() -> void: GameSession.skirm_foe = k])
	if two:
		rows.add_child(_info_row("FACTIONS ADVERSES", ("Les trois autres factions s'affrontent toutes : quatre camps, chacun pour soi" if GameSession.opponents >= 3 else "Deux factions adverses tirées au sort parmi les autres — chacune est hostile à tous (chacun pour soi)")))
	else:
		rows.add_child(_option_row("FACTION ADVERSE", foe_opts))
	rows.add_child(_option_row("TAILLE DE LA CARTE", [
		["PETITE (80)", GameSession.skirm_size == 80, func() -> void: GameSession.skirm_size = 80],
		["MOYENNE (96)", GameSession.skirm_size == 96, func() -> void: GameSession.skirm_size = 96],
		["GRANDE (112)", GameSession.skirm_size == 112, func() -> void: GameSession.skirm_size = 112]]))
	rows.add_child(_option_row("RESSOURCES DE DÉPART", [
		["RÉDUITES", is_equal_approx(GameSession.skirm_res, 0.6), func() -> void: GameSession.skirm_res = 0.6],
		["NORMALES", is_equal_approx(GameSession.skirm_res, 1.0), func() -> void: GameSession.skirm_res = 1.0],
		["ABONDANTES", is_equal_approx(GameSession.skirm_res, 1.6), func() -> void: GameSession.skirm_res = 1.6]]))
	rows.add_child(_option_row("DIFFICULTÉ DE L'IA", [
		["FACILE", GameSession.skirm_diff == 0, func() -> void: GameSession.skirm_diff = 0],
		["NORMALE", GameSession.skirm_diff == 1, func() -> void: GameSession.skirm_diff = 1],
		["DIFFICILE", GameSession.skirm_diff == 2, func() -> void: GameSession.skirm_diff = 2]]))

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 24)
	vb.add_child(hb)
	var back := GameUI.NeonButton.new("RETOUR")
	back.accent = GameData.RED
	back.custom_minimum_size = Vector2(250, 56)
	back.pressed.connect(func() -> void: _overlay.queue_free(); _overlay = null)
	hb.add_child(back)
	var go := GameUI.NeonButton.new("LANCER")
	go.accent = fd["accent"]
	go.custom_minimum_size = Vector2(250, 56)
	go.pressed.connect(_start)
	hb.add_child(go)


## Ligne de réglage : titre + boutons exclusifs [texte, actif, action].
func _option_row(title: String, opts: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(_left(title, 14, GameData.GOLD))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	box.add_child(hb)
	for o in opts:
		var b := GameUI.NeonButton.new(o[0])
		b.custom_minimum_size = Vector2(250, 48)
		b.active = o[1]
		var act: Callable = o[2]
		b.pressed.connect(func() -> void:
			act.call()
			_open_skirmish())
		hb.add_child(b)
	return box


func _info_row(title: String, text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(_left(title, 14, GameData.GOLD))
	var l := _left(text, 16, Color(1, 0.55, 0.5))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(786, 48)
	box.add_child(l)
	return box


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
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1500, 670)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	scroll.add_child(row)
	for i in Campaign.count(selected):
		row.add_child(_mission_card(i, done, fd))
	# On amène la première mission jouable à l'écran
	var first_open := mini(done, Campaign.count(selected) - 1)
	scroll.set_deferred("scroll_horizontal", maxi(first_open - 1, 0) * 354)
	vb.add_child(_label("Faites défiler (molette / glisser) : %d missions" % Campaign.count(selected), 14, Color(1, 1, 1, 0.5), false))
	var back := GameUI.NeonButton.new("RETOUR")
	back.accent = GameData.RED
	back.custom_minimum_size = Vector2(250, 56)
	back.pressed.connect(func() -> void: _overlay.queue_free(); _overlay = null)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	for dir in [-1, 1]:
		var arrow := GameUI.NeonButton.new("◀  MISSIONS" if dir < 0 else "MISSIONS  ▶")
		arrow.accent = fd["accent"]
		arrow.custom_minimum_size = Vector2(190, 56)
		arrow.pressed.connect(func() -> void:
			var tw := create_tween()
			tw.tween_property(scroll, "scroll_horizontal", clampi(scroll.scroll_horizontal + dir * 1062, 0, 100000), 0.35))
		hb.add_child(arrow)
		if dir < 0:
			hb.add_child(back)
	var rst := GameUI.NeonButton.new("RÉINITIALISER")
	rst.accent = GameData.AMBER
	rst.custom_minimum_size = Vector2(210, 56)
	rst.enabled = done > 0
	rst.pressed.connect(_confirm_reset)
	hb.add_child(rst)
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
	var ttl := _left(String(m["title"]).to_upper(), 22, Color.WHITE)
	ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ttl.custom_minimum_size = Vector2(300, 56) # deux lignes réservées : un long titre ne déborde plus
	v.add_child(ttl)
	var lvl := Campaign.level_of(selected, i)
	var dcol := Color(0.4, 1.0, 0.6).lerp(Color(1.0, 0.3, 0.25), float(lvl - 1) / 9.0)
	v.add_child(_left("DIFFICULTÉ  %s%s  %d/10" % ["◆".repeat(lvl), "◇".repeat(10 - lvl), lvl], 13, dcol))
	var br := _left(Campaign.briefing(selected, i), 14, Color(1, 1, 1, 0.8))
	br.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	br.custom_minimum_size = Vector2(300, 260)
	v.add_child(br)
	v.add_child(_left("OBJECTIF", 13, GameData.GOLD))
	var ob := _left(String(m["obj"]), 15, Color.WHITE)
	ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ob.custom_minimum_size = Vector2(300, 40)
	v.add_child(ob)
	var foes := _left(Campaign.foes_text(selected, i), 15, Color(1, 0.55, 0.5))
	foes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foes.custom_minimum_size = Vector2(300, 40)
	v.add_child(foes)
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


## Demande confirmation avant d'effacer la progression de la campagne de la faction choisie.
func _confirm_reset() -> void:
	var fd: Dictionary = GameData.FACTIONS[selected]
	var ov := ColorRect.new()
	ov.color = Color(0.03, 0.015, 0.06, 0.94)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(ov)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 22)
	cc.add_child(vb)
	vb.add_child(_label("RÉINITIALISER LA CAMPAGNE ?", 40, GameData.AMBER, true))
	var txt := _left("La progression de la campagne %s sera effacée : les missions terminées seront de nouveau verrouillées" % fd["name"]
			+ " (sauf la première). Cette action est définitive.", 17, Color(1, 1, 1, 0.85))
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.custom_minimum_size = Vector2(760, 0)
	vb.add_child(txt)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 24)
	vb.add_child(hb)
	var no := GameUI.NeonButton.new("ANNULER")
	no.custom_minimum_size = Vector2(240, 56)
	no.pressed.connect(func() -> void: ov.queue_free())
	hb.add_child(no)
	var yes := GameUI.NeonButton.new("RÉINITIALISER")
	yes.accent = GameData.RED
	yes.custom_minimum_size = Vector2(240, 56)
	yes.pressed.connect(func() -> void:
		Campaign.reset(selected)
		_open_campaign())
	hb.add_child(yes)


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
	## Titre du jeu : logo illustré (assets/logo.png).

	func _init() -> void:
		custom_minimum_size = Vector2(1000, 190)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var logo := UiStyle.logo()
		if logo == null:
			return
		var h := minf(size.y, 190.0)
		var w := h * float(logo.get_width()) / float(logo.get_height())
		var t := Time.get_ticks_msec() / 1000.0
		var lum := 1.0 + 0.04 * sin(t * 1.6) # très léger scintillement
		draw_texture_rect(logo, Rect2((size.x - w) * 0.5, (size.y - h) * 0.5, w, h), false, Color(lum, lum, lum, 1.0))


class PlateButton extends Control:
	## Bouton du menu : plaque illustrée (assets/ui/btnN.png) avec le texte par-dessus.
	signal pressed

	var text := ""
	var tex_id := 1
	var hover_t := 0.0
	var press_t := 0.0
	var _hover := false

	func _init(p_text: String, p_tex: int) -> void:
		text = p_text
		tex_id = p_tex
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mouse_entered.connect(func() -> void: _hover = true)
		mouse_exited.connect(func() -> void: _hover = false)

	func _process(delta: float) -> void:
		hover_t = move_toward(hover_t, 1.0 if _hover else 0.0, delta * 8.0)
		press_t = move_toward(press_t, 0.0, delta * 5.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			press_t = 1.0
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var tex := UiStyle.btn_tex(tex_id)
		var grow := 3.0 * hover_t - 2.0 * press_t
		var r := Rect2(Vector2(-grow, -grow * 0.3), Vector2(size.x + grow * 2.0, size.y + grow * 0.6))
		if tex != null:
			var k := 1.0 + 0.28 * hover_t - 0.25 * press_t
			draw_texture_rect(tex, r, false, Color(k, k, k, 1.0))
		var fs := 17
		var col := Color(1.0, 0.97, 0.9).lerp(Color.WHITE, hover_t)
		UiStyle.text(self, Vector2(0, size.y * 0.56 + fs * 0.36), text, fs, col, true, HORIZONTAL_ALIGNMENT_CENTER, size.x)


class FactionCard extends Control:
	signal chosen(id: String)

	var id := ""
	var active := false
	var hover_t := 0.0
	var lit_t := 0.0
	var _hover := false

	func _init(p_id: String) -> void:
		id = p_id
		custom_minimum_size = Vector2(420, 470)
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
		draw_rect(Rect2(3, 8, size.x - 6, 200), Color(col.r, col.g, col.b, 0.05 + 0.08 * lit))
		_draw_embers(col, t, lit)
		_draw_emblem(Vector2(size.x * 0.5, 108.0), col, t, lit)
		# Plaque du nom : nom et devise centrés horizontalement et verticalement
		var plate := Rect2(26, 200, size.x - 52, 74)
		draw_rect(plate, Color(col.r * 0.12, col.g * 0.12, col.b * 0.12, 0.55 + 0.25 * lit))
		draw_line(plate.position, plate.position + Vector2(plate.size.x, 0), Color(col.r, col.g, col.b, 0.35 + 0.4 * lit), 1.2, true)
		draw_line(plate.position + Vector2(0, plate.size.y), plate.end, Color(col.r, col.g, col.b, 0.35 + 0.4 * lit), 1.2, true)
		UiStyle.text_center(self, Rect2(plate.position.x, plate.position.y + 4, plate.size.x, 42), String(f["name"]).to_upper(), 30, Color.WHITE, true, true)
		UiStyle.text_center(self, Rect2(plate.position.x, plate.position.y + 46, plate.size.x, 24), String(f["tagline"]), 17, acc)
		var y := 304.0
		for l in String(f["desc"]).split("\n"):
			var fs := 15
			var fnt := UiStyle.body_font()
			while fs > 11 and fnt.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x - 48.0:
				fs -= 1
			UiStyle.text(self, Vector2(24, y), l, fs, Color(1, 1, 1, 0.88), false, HORIZONTAL_ALIGNMENT_CENTER, size.x - 48)
			y += 23.0
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

	func _poly(pts: Array, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array(pts), col)

	func _sh(col: Color, k: float, a := 1.0) -> Color:
		return Color(minf(col.r * k, 1.0), minf(col.g * k, 1.0), minf(col.b * k, 1.0), a)

	func _draw_emblem(c: Vector2, col: Color, t: float, lit: float) -> void:
		var boost := 1.0 + lit * 0.6
		# halo respirant
		for k in 6:
			draw_circle(c, 98.0 - k * 9.0 + sin(t * 1.6) * 3.0, Color(col.r, col.g, col.b, (0.02 + 0.018 * lit) * (k + 1)))
		_draw_flanks(c, col, t, boost)
		# médaillon : fond en dégradé radial
		for k in 8:
			draw_circle(c, 66.0 - k * 7.5, _sh(col, 0.06 + 0.3 * float(k) / 7.0))
		# anneaux biseautés
		draw_arc(c, 68.0, 0.0, TAU, 80, _sh(col, 0.4), 7.0, true)
		draw_arc(c, 70.5, 0.0, TAU, 80, col, 2.5, true)
		draw_arc(c, 63.0, 0.0, TAU, 80, _sh(col, 1.0, 0.4), 1.2, true)
		# graduations qui tournent lentement
		for i in 48:
			var ga := TAU * i / 48.0 + t * 0.06 * boost
			var big := i % 4 == 0
			var r1 := 74.0 + (7.0 if big else 3.5)
			draw_line(c + Vector2.from_angle(ga) * 74.0, c + Vector2.from_angle(ga) * r1, _sh(col, 1.0, 0.85 if big else 0.4), 2.0 if big else 1.0, true)
		# losanges cardinaux
		for i in 4:
			var oa := i * PI / 2.0
			var op := c + Vector2.from_angle(oa) * 87.0
			var pulse := 1.0 + 0.2 * sin(t * 3.0 + i)
			var d := 5.0 * pulse
			_poly([op + Vector2(0, -d), op + Vector2(d, 0), op + Vector2(0, d), op + Vector2(-d, 0)], Color(1, 0.96, 0.85, 0.9))
		match id:
			"solis":
				_sym_solis(c, col, t, boost)
			"kharn":
				_sym_kharn(c, col, t, boost)
			"conclave":
				_sym_conclave(c, col, t, boost)
			_:
				_sym_vael(c, col, t, boost)
		# reflet de verre sur le médaillon
		draw_arc(c, 57.0, PI * 1.1, PI * 1.55, 20, Color(1, 1, 1, 0.28), 3.0, true)
		draw_arc(c, 57.0, PI * 1.62, PI * 1.7, 6, Color(1, 1, 1, 0.2), 3.0, true)

	## Ornements de part et d'autre du médaillon, propres à chaque faction.
	func _draw_flanks(c: Vector2, col: Color, t: float, boost: float) -> void:
		for sd: float in [-1.0, 1.0]:
			match id:
				"solis": # faisceaux lumineux effilés
					for i in range(-2, 3):
						var ang := i * 0.2
						var ln := 150.0 - absf(i) * 16.0 + 6.0 * sin(t * 2.0 + i * 1.3 + sd)
						var dir := Vector2(sd * cos(ang), sin(ang))
						var perp := Vector2(-dir.y, dir.x)
						_poly([c + dir * 90.0 + perp * 3.5, c + dir * ln, c + dir * 90.0 - perp * 3.5], Color(col.r, col.g, col.b, 0.62 - absf(i) * 0.12))
				"kharn": # ailes de lames effilées
					for i in 4:
						var wave := 0.55 + 0.45 * sin(t * 2.6 * boost - i * 0.8)
						var y0 := -26.0 + i * 17.0
						var tip := c + Vector2(sd * (156.0 - i * 16.0), -48.0 + i * 28.0)
						_poly([c + Vector2(sd * 86.0, y0 - 7.0), tip, c + Vector2(sd * 86.0, y0 + 7.0)], _sh(col, 0.45 + 0.35 * wave))
						draw_line(c + Vector2(sd * 86.0, y0 - 7.0), tip, col, 1.6, true)
				"conclave": # éclats cristallins en grappe
					for i in 3:
						var h := (50.0 - i * 15.0) * (1.0 + 0.06 * sin(t * 2.0 + i + sd))
						var bx := c.x + sd * (96.0 + i * 20.0)
						var by := c.y + 34.0 - i * 6.0
						var w := 11.0 - i * 2.0
						_poly([Vector2(bx, by - h), Vector2(bx - w, by - h * 0.35), Vector2(bx, by)], _sh(col, 0.75, 0.95))
						_poly([Vector2(bx, by - h), Vector2(bx, by), Vector2(bx + w, by - h * 0.35)], _sh(col, 0.4, 0.95))
						draw_polyline(PackedVector2Array([Vector2(bx, by - h), Vector2(bx - w, by - h * 0.35), Vector2(bx, by), Vector2(bx + w, by - h * 0.35), Vector2(bx, by - h)]), col, 1.6, true)
				_: # ailerons courbes qui pulsent vers l'extérieur
					for k in 3:
						var rr := 30.0 + k * 15.0
						var a0 := -1.0 if sd > 0.0 else PI - 1.0
						var ph := 0.4 + 0.6 * maxf(0.0, sin(t * 2.4 * boost - k * 0.9))
						draw_arc(c + Vector2(sd * 58.0, 0), rr, a0, a0 + 2.0, 24, Color(col.r, col.g, col.b, 0.3 + 0.6 * ph), 4.0 - k * 0.8, true)

	func _sym_solis(c: Vector2, col: Color, t: float, boost: float) -> void:
		_ring(c, 59.0, Color(col.r, col.g, col.b, 0.5), -t * 0.5 * boost, 24, 0.12, 1.6)
		for layer in 2:
			for i in 12:
				var a := TAU * i / 12.0 + t * (0.3 if layer == 0 else -0.22) * boost + layer * 0.13
				var r1 := (52.0 if layer == 0 else 40.0) + 3.0 * sin(t * 3.0 + i * 1.7)
				var w := 0.12 if layer == 0 else 0.17
				_poly([c + Vector2.from_angle(a - w) * 22.0, c + Vector2.from_angle(a) * r1, c + Vector2.from_angle(a + w) * 22.0],
						Color(col.r, col.g, col.b, 0.95 if layer == 0 else 0.55))
		var pulse := 1.0 + 0.1 * sin(t * 2.4)
		draw_circle(c, 23.0 * pulse, _sh(col, 0.7))
		draw_circle(c, 19.0 * pulse, col)
		draw_circle(c, 13.0 * pulse, Color(1, 0.95, 0.75, 0.9))
		draw_circle(c, 7.0 * pulse, Color(1, 1, 1, 0.95))
		for j in 3:
			var oa := t * (0.9 + 0.25 * j) + j * 2.09
			var sp := c + Vector2.from_angle(oa) * 59.0
			draw_circle(sp, 5.0, Color(col.r, col.g, col.b, 0.35))
			draw_circle(sp, 3.2, Color(1, 0.95, 0.8))

	func _sym_kharn(c: Vector2, col: Color, t: float, boost: float) -> void:
		var cc := c + Vector2(0, sin(t * 1.8) * 1.5)
		var o := PackedVector2Array([cc + Vector2(-32, -38), cc + Vector2(32, -38), cc + Vector2(32, 6), cc + Vector2(0, 46), cc + Vector2(-32, 6)])
		_poly([o[0], cc + Vector2(0, -38), cc + Vector2(0, 46), o[4]], _sh(col, 0.58))
		_poly([cc + Vector2(0, -38), o[1], o[2], cc + Vector2(0, 46)], _sh(col, 0.32))
		draw_polyline(PackedVector2Array(Array(o) + [o[0]]), col, 3.2, true)
		var inner := PackedVector2Array()
		for p in o:
			inner.append(cc + (p - cc) * 0.84)
		draw_polyline(PackedVector2Array(Array(inner) + [inner[0]]), Color(1, 0.9, 0.85, 0.45), 1.2, true)
		for i in 3:
			var wv := clampf(0.35 + 0.65 * sin(t * 3.2 * boost - i * 0.9), 0.15, 1.0)
			var yy := -20.0 + i * 15.0
			draw_polyline(PackedVector2Array([cc + Vector2(-20, yy), cc + Vector2(0, yy + 20), cc + Vector2(20, yy)]), Color(1, 0.85, 0.8, wv), 5.0, true)
		for rv in [Vector2(-25, -31), Vector2(25, -31), Vector2(-25, 2), Vector2(25, 2)]:
			draw_circle(cc + rv, 2.2, Color(1, 0.9, 0.85, 0.9))

	func _sym_conclave(c: Vector2, col: Color, t: float, boost: float) -> void:
		var br := 1.0 + 0.05 * sin(t * 2.2)
		var T := c + Vector2(0, -50.0 * br)
		var B := c + Vector2(0, 50.0 * br)
		var UL := c + Vector2(-27, -17)
		var UR := c + Vector2(27, -17)
		var LL := c + Vector2(-27, 11)
		var LR := c + Vector2(27, 11)
		var M := c + Vector2(0, -5)
		var facets := [[T, UL, M], [T, M, UR], [UL, LL, M], [M, LR, UR], [LL, B, M], [M, B, LR]]
		var base := [0.75, 1.0, 0.45, 0.62, 0.3, 0.5]
		for i in 6:
			var k: float = base[i] + 0.35 * maxf(0.0, sin(t * 2.6 - i * 0.9))
			var f: Array = facets[i]
			_poly(f, Color(minf(col.r * k, 1.0), minf(col.g * k * 0.9, 1.0), minf(col.b * k * 1.05, 1.0), 0.97))
		draw_polyline(PackedVector2Array([T, UL, LL, B, LR, UR, T]), col, 3.0, true)
		draw_line(T, M, Color(1, 0.95, 1, 0.5), 1.5, true)
		draw_line(UL, M, Color(1, 0.95, 1, 0.3), 1.2, true)
		draw_line(UR, M, Color(1, 0.95, 1, 0.3), 1.2, true)
		for j in 4:
			var oa := t * (0.8 + 0.2 * j) + j * 1.57
			var op := c + Vector2.from_angle(oa) * Vector2(60.0, 46.0)
			_poly([op + Vector2(0, -6), op + Vector2(4, 0), op + Vector2(0, 6), op + Vector2(-4, 0)], Color(0.95, 0.85, 1.0))

	func _sym_vael(c: Vector2, col: Color, t: float, boost: float) -> void:
		# balayage radar en éventail
		var sw := t * 1.4 * boost
		for j in 14:
			var a0 := sw - j * 0.07
			_poly([c, c + Vector2.from_angle(a0) * 60.0, c + Vector2.from_angle(a0 + 0.07) * 60.0], Color(col.r, col.g, col.b, 0.2 * (1.0 - j / 14.0)))
		for k in 3:
			var ph := fposmod(t * 0.5 + k / 3.0, 1.0)
			draw_arc(c, 24.0 + ph * 36.0, 0.0, TAU, 48, Color(col.r, col.g, col.b, (1.0 - ph) * 0.4), 1.6, true)
		var bph := fposmod(t, 4.2)
		var blink := 1.0 if bph < 3.9 else clampf(absf(bph - 4.05) / 0.15, 0.08, 1.0)
		var ey := 28.0 * blink
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		for i in 17:
			var u := -1.0 + i / 8.0
			var yv := ey * (1.0 - u * u)
			top.append(c + Vector2(u * 50.0, -yv))
			bot.append(c + Vector2(u * 50.0, yv * 0.85))
		var bot_r := Array(bot)
		bot_r.reverse()
		_poly(Array(top) + bot_r, _sh(col, 0.2))
		var look := (get_local_mouse_position() - c)
		look = look.limit_length(60.0) / 60.0 * 8.0
		if blink > 0.5:
			var ip := c + look
			draw_circle(ip, 18.0, _sh(col, 0.55))
			draw_circle(ip, 15.0, col)
			for i in 14:
				var ra := TAU * i / 14.0
				draw_line(ip + Vector2.from_angle(ra) * 7.0, ip + Vector2.from_angle(ra) * 14.0, _sh(col, 0.6, 0.7), 1.2, true)
			draw_circle(ip, 6.5 + 1.5 * sin(t * 2.0), Color.BLACK)
			draw_circle(ip + Vector2(-4, -4), 2.4, Color(1, 1, 1, 0.9))
		draw_polyline(top, col, 3.2, true)
		draw_polyline(bot, col, 2.4, true)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		Guide.open(self, selected)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		Changelog.open(self)
