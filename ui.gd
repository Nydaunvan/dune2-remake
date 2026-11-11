class_name GameUI
extends CanvasLayer
## Interface moderne : barre de ressources, panneau latéral en verre dépoli
## (radar, commandes, construction), notifications animées.

const SIDEBAR_W := 360.0
const MARGIN := 14.0
const COMMANDS := [
	["stop", "ARRÊT", true],
	["move", "DÉPLACER", true],
	["attack", "ATTAQUER", true],
	["deploy", "DÉPLOYER", true],
]

var game # le nœud principal (main.gd)
var category := "building"
var root: Control
var sidebar: GlassPanel
var topbar: HudBar
var radar: Radar
var info_label: Label
var info_panel: InfoPanel
var icon_box: GridContainer
var icon_scroll: ScrollContainer
var icons: Array = []
var tab_buttons: Array = []


func setup(p_game) -> void:
	game = p_game
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_topbar()
	_build_objective()
	_build_sidebar()
	_rebuild_icons()
	info_panel = InfoPanel.new(game)
	root.add_child(info_panel)


func is_mouse_over_ui() -> bool:
	var m := get_viewport().get_mouse_position()
	return sidebar.get_global_rect().has_point(m) or topbar.get_global_rect().has_point(m) \
			or (info_panel != null and info_panel.visible and info_panel.get_global_rect().has_point(m))


## Notification qui monte et s'efface.
func toast(text: String, color := GameData.CREAM) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiStyle.title_font())
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.02, 0.09, 0.82)
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_color = UiStyle.GOLD
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = -330.0
	l.offset_right = 330.0
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

func _build_objective() -> void:
	if game.mission.is_empty():
		return
	var p := ObjectivePanel.new(game)
	p.position = Vector2(6, 100)
	p.size = Vector2(430, 76)
	root.add_child(p)


func _build_topbar() -> void:
	topbar = HudBar.new()
	topbar.game = game
	topbar.position = Vector2(6, 6)
	topbar.size = Vector2(1100, 84)
	root.add_child(topbar)


func _build_sidebar() -> void:
	sidebar = GlassPanel.new(0.0, 4.0, game.fdata["color"], game.fdata["accent"], 24.0)
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_top = 0.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = -SIDEBAR_W - MARGIN
	sidebar.offset_right = -MARGIN
	sidebar.offset_top = MARGIN
	sidebar.offset_bottom = -MARGIN
	root.add_child(sidebar)

	var header := SideHeader.new(game)
	header.position = Vector2(24, 14)
	header.size = Vector2(SIDEBAR_W - 48.0, 34)
	sidebar.add_child(header)

	# Radar
	radar = Radar.new()
	radar.game = game
	radar.world_size = game.world_size
	radar.position = Vector2(30, 52)
	radar.size = Vector2(300, 300)
	sidebar.add_child(radar)

	# Commandes (2 x 2)
	var bw := (SIDEBAR_W - 48.0 - 8.0) / 2.0
	for i in COMMANDS.size():
		var cmd: Array = COMMANDS[i]
		var b := NeonButton.new(cmd[1])
		b.glyph = cmd[0]
		b.enabled = cmd[2]
		b.tooltip_text = "" if cmd[2] else "Disponible dans un prochain jalon"
		b.position = Vector2(24 + (i % 2) * (bw + 8.0), 364 + (i / 2) * 44)
		b.size = Vector2(bw, 38)
		b.pressed.connect(game.on_command.bind(cmd[0]))
		sidebar.add_child(b)

	# Onglets
	var tabs := [["building", "BÂTIMENTS", GameData.CYAN], ["unit", "UNITÉS", GameData.MAGENTA]]
	for i in tabs.size():
		var t := NeonButton.new(tabs[i][1])
		t.accent = tabs[i][2]
		t.active = (i == 0)
		t.position = Vector2(24 + i * ((SIDEBAR_W - 48.0) / 2.0 + 4.0), 462)
		t.size = Vector2((SIDEBAR_W - 56.0) / 2.0, 38)
		t.pressed.connect(_set_category.bind(tabs[i][0]))
		sidebar.add_child(t)
		tab_buttons.append(t)

	# Icônes de production
	icon_box = GridContainer.new()
	icon_box.columns = 2
	icon_box.add_theme_constant_override("h_separation", 8)
	icon_box.add_theme_constant_override("v_separation", 8)
	icon_scroll = ScrollContainer.new()
	icon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	icon_scroll.position = Vector2(18, 512)
	icon_scroll.size = Vector2(SIDEBAR_W - 26.0, 392)
	icon_scroll.clip_contents = true
	sidebar.add_child(icon_scroll)
	icon_scroll.add_child(icon_box)

	# Infos en bas du panneau
	info_label = Label.new()
	info_label.add_theme_font_override("font", UiStyle.body_font())
	info_label.add_theme_font_size_override("font_size", 14)
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
	info_label.offset_top = -88
	info_label.offset_bottom = -22
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
	var ids: Array = GameData.buildings_for(game.faction_id) if category == "building" \
			else GameData.units_for(game.faction_id)
	for id in ids:
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
	elif game.command_mode == "attack":
		info_label.text = "Cliquez : les unités avancent en attaquant tout sur leur route."
	else:
		info_label.text = "File : bâtiments %d/%d — unités %d/%d\nClic droit : ordre / annuler une icône\nF11 plein écran — F10 menu — M son" \
				% [game.production["building"].size(), game.queue_max("building"),
				game.production["unit"].size(), game.queue_max("unit")]


## Écran de fin de partie.
func show_end(victory: bool, reason := "") -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.05, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 26)
	cc.add_child(vb)
	var l := Label.new()
	l.text = "VICTOIRE" if victory else "DÉFAITE"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 110)
	var col: Color = GameData.GREEN if victory else GameData.RED
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 14)
	vb.add_child(l)
	var sub := Label.new()
	sub.text = reason if reason != "" else ("Mission accomplie." if victory else "Mission échouée.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", GameData.CREAM)
	vb.add_child(sub)
	if not game.mission.is_empty():
		var m: int = GameSession.mission
		var go := NeonButton.new("")
		go.accent = col
		go.custom_minimum_size = Vector2(320, 60)
		if victory and m + 1 < Campaign.count(game.faction_id):
			go.text = "MISSION SUIVANTE"
			go.pressed.connect(func() -> void:
				GameSession.mission = m + 1
				get_tree().change_scene_to_file("res://main.tscn"))
			vb.add_child(go)
		elif not victory:
			go.text = "RECOMMENCER"
			go.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main.tscn"))
			vb.add_child(go)
		else:
			sub.text = "Campagne terminée : Arrakis est à vous."
	var b := NeonButton.new("RETOUR AU MENU")
	b.accent = col
	b.custom_minimum_size = Vector2(320, 60)
	b.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://menu.tscn"))
	vb.add_child(b)
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.6, 1.2)


# --- Objectif de mission ------------------------------------------------------

class ObjectivePanel extends GlassPanel:
	var game

	func _init(p_game) -> void:
		super(8.0, 4.0, p_game.fdata["color"], p_game.fdata["accent"], 14.0)
		game = p_game
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		var n: int = game.objectives_status().size()
		size = Vector2(450, 44 + 40 * n)
		queue_redraw()

	func _draw() -> void:
		var m: Dictionary = game.mission
		UiStyle.text(self, Vector2(20, 26), "MISSION %d — %s" % [GameSession.mission + 1, String(m["title"]).to_upper()],
				13, UiStyle.GOLD, true)
		var y := 54.0
		for o in game.objectives_status():
			var done: bool = o["done"]
			var c := Vector2(26, y - 5.0)
			var col := GameData.GREEN if done else UiStyle.GOLD
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]),
					col if done else Color(col.r, col.g, col.b, 0.25))
			draw_polyline(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0), c + Vector2(0, -6)]),
					col, 1.4)
			UiStyle.text(self, Vector2(42, y), String(o["text"]), 14, UiStyle.TEXT if not done else GameData.GREEN)
			UiStyle.seg_bar(self, Rect2(42, y + 8.0, size.x - 62.0, 6), float(o["frac"]), col, 8.0, 3.0)
			y += 40.0


# --- Barre de ressources ------------------------------------------------------

class HudBar extends GlassPanel:
	var game
	var shown_credits := 0.0
	var shown_ore := 0.0
	var _init_done := false

	func _init() -> void:
		super(8.0, 4.0, Color(0.75, 0.55, 0.15), Color(1.0, 0.85, 0.4), 18.0)

	func _process(delta: float) -> void:
		if game == null:
			return
		if not _init_done:
			shown_credits = float(game.credits)
			shown_ore = float(game.ore)
			_init_done = true
		shown_credits = lerpf(shown_credits, float(game.credits), clampf(delta * 7.0, 0.0, 1.0))
		shown_ore = lerpf(shown_ore, float(game.ore), clampf(delta * 7.0, 0.0, 1.0))
		queue_redraw()

	func _chip(x: float, label: String, value: String, vcol: Color, glyph: String, gcol: Color, vsize := 30) -> void:
		UiStyle.glyph(self, glyph, Vector2(x + 10, 54), 14.0, gcol)
		UiStyle.text(self, Vector2(x + 28, 36), label, 11, UiStyle.TEXT_DIM, true)
		UiStyle.text(self, Vector2(x + 28, 64), value, vsize, vcol)

	func _sep(x: float) -> void:
		draw_line(Vector2(x, 28), Vector2(x, 66), Color(UiStyle.GOLD.r, UiStyle.GOLD.g, UiStyle.GOLD.b, 0.35), 1.2)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 24), Vector2(x + 3, 28), Vector2(x, 32), Vector2(x - 3, 28)]), UiStyle.GOLD)

	func _draw() -> void:
		if game == null:
			return
		# Solaris : le compteur glisse vers la valeur réelle et clignote vert/rouge
		var diff: float = float(game.credits) - shown_credits
		var col := GameData.GOLD
		if absf(diff) > 1.0:
			var k := clampf(absf(diff) / 200.0, 0.0, 1.0)
			col = GameData.GOLD.lerp(Color("5dff9a") if diff > 0.0 else Color("ff5a4a"), k)
		_chip(30, "SOLARIS", str(int(round(shown_credits))), col, "credit", GameData.AMBER_HDR)
		_sep(228)
		_chip(246, "MINERAI", str(int(round(shown_ore))), GameData.ORE_BLUE, "ore", GameData.CYAN)
		_sep(444)

		# Énergie : jauge segmentée
		var prod: int = game.power_produced()
		var used: int = game.power_used()
		var ratio := 1.0 if used <= 0 else clampf(float(prod) / float(used), 0.0, 1.0)
		var ok := prod >= used
		var gcol := GameData.CYAN if ok else GameData.RED
		UiStyle.glyph(self, "power", Vector2(472, 54), 14.0, gcol)
		UiStyle.text(self, Vector2(490, 36), "ÉNERGIE", 11, UiStyle.TEXT_DIM, true)
		UiStyle.text(self, Vector2(490, 64), "%d / %d" % [prod, used], 22, Color.WHITE if ok else GameData.RED)
		UiStyle.seg_bar(self, Rect2(590, 50, 196, 12), ratio, gcol, 8.0, 3.0)
		_sep(812)

		var t: float = game.game_time
		UiStyle.text(self, Vector2(836, 36), "TEMPS", 11, UiStyle.TEXT_DIM, true)
		UiStyle.text(self, Vector2(836, 64),
				"%02d:%02d:%02d" % [int(t / 3600.0), int(t / 60.0) % 60, int(t) % 60], 24, Color.WHITE)
		_sep(980)
		UiStyle.text(self, Vector2(1000, 36), "FPS", 11, UiStyle.TEXT_DIM, true)
		UiStyle.text(self, Vector2(1000, 64), str(Engine.get_frames_per_second()), 22, GameData.GREEN)


class SideHeader extends Control:
	var game

	func _init(p_game) -> void:
		game = p_game
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col: Color = game.fdata["color"]
		var name_s: String = String(game.fdata["name"]).to_upper()
		# Emblème : losange emboîté
		var c := Vector2(14, 17)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -13), c + Vector2(13, 0), c + Vector2(0, 13), c + Vector2(-13, 0)]), col * 1.4)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(7, 0), c + Vector2(0, 7), c + Vector2(-7, 0)]), UiStyle.INK)
		UiStyle.text(self, Vector2(36, 24), name_s, 18, UiStyle.TEXT, true)
		var w := UiStyle.text_width(name_s, 18, true)
		draw_line(Vector2(36 + w + 12, 17), Vector2(size.x, 17), Color(UiStyle.GOLD.r, UiStyle.GOLD.g, UiStyle.GOLD.b, 0.45), 1.2, true)


# --- Panneau d'informations ---------------------------------------------------

class InfoPanel extends GlassPanel:
	const ARMOR := {"light": "Léger", "medium": "Moyen", "heavy": "Lourd", "building": "Structure"}
	const WEAPON := {"autocannon": "Autocanon", "cannon": "Canon", "rocket": "Roquettes",
			"sonic": "Onde sonique", "acid": "Acide", "control": "Contrôle mental"}
	const COL2 := 430.0

	var game
	var btn: GameUI.NeonButton
	var _focus = null

	func _init(p_game) -> void:
		super(8.0, 4.0, p_game.fdata["color"], p_game.fdata["accent"], 24.0)
		game = p_game
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_left = 16.0
		offset_right = 16.0 + 800.0
		offset_top = -262.0
		offset_bottom = -16.0
		btn = GameUI.NeonButton.new("AMÉLIORER")
		btn.accent = GameData.GOLD
		btn.glyph = "credit"
		btn.position = Vector2(COL2, 190)
		btn.size = Vector2(330, 40)
		btn.pressed.connect(func() -> void:
			if _focus is Building:
				game.upgrade_building(_focus)
			elif _focus is Unit:
				game.upgrade_unit(_focus))
		add_child(btn)
		visible = false

	func _ok(e) -> bool:
		return e != null and is_instance_valid(e) and e.alive

	func _find_focus():
		if _ok(game.selected_building):
			return game.selected_building
		if _ok(game.inspected):
			return game.inspected
		if game.selected.size() == 1 and _ok(game.selected[0]):
			return game.selected[0]
		if game.selected.size() > 1:
			return "multi"
		return null

	func _process(_delta: float) -> void:
		if game == null:
			return
		_focus = _find_focus()
		visible = _focus != null
		var is_b: bool = _focus is Building and _focus.team == 0 and not GameData.def(_focus.id).get("no_upgrade", false)
		var is_u: bool = _focus is Unit and _focus.team == 0 and GameData.UNIT_TECH.has(_focus.id)
		btn.visible = is_b or is_u
		if is_b:
			var b: Building = _focus
			btn.position = Vector2(COL2, 190)
			var why: String = game.upgrade_block(b, game.ore)
			btn.enabled = why == ""
			if b.up_left > 0.0:
				btn.text = "AMÉLIORATION — %d S" % int(ceil(b.up_left))
			elif b.level >= GameData.MAX_LEVEL:
				btn.text = "NIVEAU MAXIMUM"
			else:
				btn.text = "AMÉLIORER — %d MIN. · %d S" % [game.upgrade_cost(b), int(game.upgrade_time(b))]
			btn.glyph = "ore"
			btn.tooltip_text = why
		elif is_u:
			var u: Unit = _focus
			btn.position = Vector2(COL2, 208)
			var why2: String = game.unit_upgrade_block(u)
			btn.enabled = why2 == ""
			if u.tech_left > 0.0:
				btn.text = "MODERNISATION — %d S" % int(ceil(u.tech_left))
			elif u.tech > 0:
				btn.text = "MODERNISÉE"
			else:
				btn.text = "MODERNISER — %d SOL. · %d S" % [GameData.tech_cost(u.id), int(GameData.tech_time(u.id))]
			btn.glyph = "credit"
			btn.tooltip_text = why2
		queue_redraw()

	func _row(x: float, y: float, label: String, value: String, vcol := UiStyle.TEXT) -> void:
		UiStyle.text(self, Vector2(x, y), label.to_upper(), 11, UiStyle.TEXT_DIM, true)
		UiStyle.text(self, Vector2(x + 120, y), value, 15, vcol)

	func _hp_block(name_s: String, sub: String, hp: float, hp_max: float, mine: bool, tag := "") -> void:
		var col := Color.WHITE if mine else GameData.RED
		UiStyle.text(self, Vector2(34, 58), name_s.to_upper(), 24, col, true)
		if tag != "":
			var w := UiStyle.text_width(name_s.to_upper(), 24, true)
			UiStyle.text(self, Vector2(34 + w + 14, 58), tag, 14, UiStyle.GOLD, true)
		if sub != "":
			UiStyle.text(self, Vector2(34, 78), sub, 13, UiStyle.TEXT_DIM)
		UiStyle.seg_bar(self, Rect2(34, 90, 340, 11), hp / maxf(hp_max, 1.0), GameData.GREEN if mine else GameData.RED, 8.0, 3.0)
		UiStyle.text(self, Vector2(386, 100), "%d / %d" % [int(hp), int(hp_max)], 13, UiStyle.TEXT)

	func _draw() -> void:
		if _focus == null:
			return
		if _focus is String:
			_draw_multi()
		elif _focus is Building:
			_draw_building(_focus)
		else:
			_draw_unit(_focus)

	func _draw_multi() -> void:
		var hp := 0.0
		var hp_max := 0.0
		var counts := {}
		for u in game.selected:
			counts[u.id] = int(counts.get(u.id, 0)) + 1
			hp += u.hp
			hp_max += u.max_hp
		_hp_block("%d unités" % game.selected.size(), "Sélection multiple", hp, hp_max, true)
		UiStyle.section(self, Vector2(34, 128), 360, "COMPOSITION", UiStyle.GOLD)
		var x := 34.0
		var y := 152.0
		for id in counts:
			UiStyle.text(self, Vector2(x, y), "%d ×" % counts[id], 15, UiStyle.GOLD)
			UiStyle.text(self, Vector2(x + 34, y), String(GameData.def(id)["name"]), 15, UiStyle.TEXT)
			y += 22.0
			if y > 228.0:
				y = 152.0
				x += 190.0
		UiStyle.section(self, Vector2(COL2, 128), 340, "ORDRES", UiStyle.GOLD)
		UiStyle.text(self, Vector2(COL2, 154), "Clic droit : déplacer ou attaquer", 14, UiStyle.TEXT)
		UiStyle.text(self, Vector2(COL2, 176), "ATTAQUER : avance en tirant", 14, UiStyle.TEXT)
		UiStyle.text(self, Vector2(COL2, 198), "ARRÊT : annule les ordres", 14, UiStyle.TEXT)

	func _tech_line(u: Unit) -> String:
		if not GameData.UNIT_TECH.has(u.id):
			return ""
		return ("Modernisée : " if u.tech > 0 else "Modernisation : ") + GameData.tech_text(u.id)

	func _draw_unit(u: Unit) -> void:
		var d := GameData.def(u.id)
		var mine: bool = u.team == 0
		var rank_tag := String(GameData.RANKS[u.rank]["name"]).to_upper() if u.role == "combat" else ""
		_hp_block(String(d["name"]), String(d.get("desc", "")), u.hp, u.max_hp, mine, rank_tag)
		if u.role == "mcv" or u.role == "convoy":
			UiStyle.section(self, Vector2(34, 128), 360, "CARACTÉRISTIQUES", UiStyle.GOLD)
			_row(34, 152, "Blindage", ARMOR.get(u.armor, u.armor))
			_row(34, 174, "Vitesse", "%d    Vision %d cases" % [int(u.speed), u.vision])
			UiStyle.section(self, Vector2(COL2, 128), 340, "RÔLE", UiStyle.GOLD)
			if u.role == "mcv":
				UiStyle.text(self, Vector2(COL2, 154), "Placez-le sur un sol rocheux dégagé", 14, UiStyle.TEXT)
				UiStyle.text(self, Vector2(COL2, 176), "puis cliquez sur DÉPLOYER pour", 14, UiStyle.TEXT)
				UiStyle.text(self, Vector2(COL2, 198), "créer votre Chantier (3x3 cases).", 14, UiStyle.TEXT)
			else:
				UiStyle.text(self, Vector2(COL2, 154), "Cargaison à livrer au point cyan", 14, UiStyle.TEXT)
				UiStyle.text(self, Vector2(COL2, 176), "indiqué sur la carte et le radar.", 14, UiStyle.TEXT)
			return
		UiStyle.section(self, Vector2(34, 128), 360, "CARACTÉRISTIQUES", UiStyle.GOLD)
		var y := 152.0
		_row(34, y, "Blindage", ARMOR.get(u.armor, u.armor))
		y += 22.0
		_row(34, y, "Vitesse", "%d    Vision %d cases" % [int(u.speed), u.vision])
		y += 22.0
		if u.weapon != "":
			var mult := 1.0 + GameData.RANK_DMG * u.rank
			_row(34, y, "Arme", WEAPON.get(u.weapon, u.weapon))
			y += 22.0
			_row(34, y, "Dégâts", "%.0f /s    Portée %d cases" % [u.dps * mult, int(u.w_range / 32.0)])
		else:
			_row(34, y, "Capacité", "%d  (%d en soute)" % [int(u.cargo_cap), int(u.cargo)])
			y += 22.0
			_row(34, y, "Rendement", "%d /s" % int(u.harvest_rate))
		UiStyle.section(self, Vector2(COL2, 128), 340, "ÉVOLUTION" if u.role == "combat" else "RÔLE", UiStyle.GOLD)
		if u.role == "combat":
			var nxt := ""
			if u.rank + 1 < GameData.RANKS.size():
				nxt = "Prochain rang : %d éliminations" % GameData.RANKS[u.rank + 1]["kills"]
			else:
				nxt = "Rang maximum"
			UiStyle.text(self, Vector2(COL2, 154), "%d éliminations — %s" % [u.kills, nxt.trim_prefix("Prochain rang : ")], 14, UiStyle.GOLD)
			if u.weapon == "control":
				UiStyle.text(self, Vector2(COL2, 176), "Contrôle un char ennemi 15 s (toutes les 20 s)", 13, GameData.CYAN)
			elif u.weapon == "sonic":
				UiStyle.text(self, Vector2(COL2, 176), "Dégâts de zone, touche aussi les alliés", 13, GameData.AMBER)
			else:
				UiStyle.text(self, Vector2(COL2, 176), "Chaque rang : +15 % dégâts et PV", 13, UiStyle.TEXT_DIM)
			UiStyle.text(self, Vector2(COL2, 198), _tech_line(u), 13, GameData.GREEN if u.tech > 0 else UiStyle.TEXT)
		else:
			UiStyle.text(self, Vector2(COL2, 154), "Récolte automatiquement et rapporte", 14, UiStyle.TEXT)
			UiStyle.text(self, Vector2(COL2, 176), "à la Raffinerie" if u.cargo_kind == "spice" else "à la Fonderie", 14, UiStyle.TEXT)
			UiStyle.text(self, Vector2(COL2, 198), _tech_line(u), 13, GameData.GREEN if u.tech > 0 else UiStyle.TEXT)

	func _draw_building(b: Building) -> void:
		var d := GameData.def(b.id)
		var mine: bool = b.team == 0
		_hp_block(String(d["name"]), "Structure alliée" if mine else "Structure ennemie", b.hp, b.max_hp, mine,
				"NIVEAU %d/%d" % [b.level, GameData.MAX_LEVEL])
		UiStyle.section(self, Vector2(34, 128), 360, "CARACTÉRISTIQUES", UiStyle.GOLD)
		var rows: Array = []
		match b.id:
			"chantier":
				rows.append(["File bât.", "%d places" % (2 + 2 * (b.level - 1))])
			"usine":
				rows.append(["File unités", "%d places" % game.queue_max("unit")])
				rows.append(["Production", "+%d %%" % int(25 * (b.level - 1))])
			"centrale":
				rows.append(["Énergie", "+%d" % b.power])
			"raffinerie":
				rows.append(["Solaris", "+%d %% par récolte" % int(12 * (b.level - 1))])
			"fonderie":
				rows.append(["Minerai", "+%d %% par récolte" % int(12 * (b.level - 1))])
			"tourelle", "batterie", "tour_sonique", "bunker", "tour_acide":
				rows.append(["Dégâts", "%.0f /s" % b.dps])
				rows.append(["Portée", "%d cases" % int(b.w_range / 32.0)])
			"silo":
				rows.append(["Solaris", "+10 % par silo (3 max.)"])
			"reparation":
				rows.append(["Soins", "%d PV/s" % int(d["heal"])])
				rows.append(["Rayon", "%d cases" % int(d["heal_range"])])
			"reacteur", "relais_solaire":
				rows.append(["Énergie", "+%d" % b.power])
			"marche":
				rows.append(["Revenu", "+%d Solaris/s" % int(d["income"])])
			"mur", "mur_acier":
				rows.append(["Rôle", "Barrière"])
		if b.power < 0:
			rows.append(["Consomme", "%d énergie" % -b.power])
		rows.append(["Vision", "%d cases" % b.vision])
		var y := 152.0
		for r in rows:
			_row(34, y, r[0], r[1])
			y += 22.0
		if mine and not d.get("no_upgrade", false):
			UiStyle.section(self, Vector2(COL2, 128), 340, "NIVEAU SUIVANT" if b.level < GameData.MAX_LEVEL else "ÉVOLUTION", UiStyle.GOLD)
			if b.level < GameData.MAX_LEVEL:
				var yy := 154.0
				for part in String(GameData.UPGRADES.get(b.id, "")).split(", "):
					UiStyle.text(self, Vector2(COL2, yy), "◆ " + part, 13, UiStyle.TEXT)
					yy += 20.0
				var why: String = game.upgrade_block(b, game.ore)
				if why != "":
					UiStyle.text(self, Vector2(COL2, 236), why, 13, GameData.RED)
			else:
				UiStyle.text(self, Vector2(COL2, 154), "Niveau maximum atteint", 15, UiStyle.GOLD)


# --- Bouton néon --------------------------------------------------------------

class NeonButton extends Control:
	signal pressed

	var text := ""
	var glyph := ""
	var enabled := true
	var active := false
	var accent := Color(0.0, 1.5, 1.9)
	var hover_t := 0.0
	var press_t := 0.0
	var _hover := false

	func _init(p_text: String) -> void:
		text = p_text
		mouse_filter = Control.MOUSE_FILTER_STOP
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
		var line := Color(col.r, col.g, col.b, 0.5 + 0.5 * lit)
		var fill := Color(col.r * 0.3, col.g * 0.3, col.b * 0.3, 1.0).clamp(Color(0, 0, 0, 1), Color(0.7, 0.7, 0.7, 1))
		UiStyle.frame(self, Rect2(Vector2.ZERO, size), minf(10.0, size.y * 0.3), line,
				UiStyle.PANEL, lit, lit)
		if lit > 0.0:
			draw_colored_polygon(UiStyle.chamfer(Rect2(Vector2(3, 3), size - Vector2(6, 6)), minf(8.0, size.y * 0.25)),
					Color(fill.r, fill.g, fill.b, 0.55 * lit))
		var tc := Color(1, 1, 1, 0.95) if enabled else Color(0.5, 0.45, 0.55)
		var fs := 13
		var tw := UiStyle.text_width(text, fs, true)
		var gw := 22.0 if glyph != "" else 0.0
		var x0 := (size.x - tw - gw) * 0.5
		if glyph != "":
			UiStyle.glyph(self, glyph, Vector2(x0 + 8, size.y * 0.5), 12.0, col if enabled else tc)
		UiStyle.text(self, Vector2(x0 + gw, size.y * 0.5 + 5.0), text, fs, tc, true)


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
		var tip := "%s — %s" % [d["name"], game.cost_label(id)]
		if d.has("desc"):
			tip += "\n" + d["desc"]
		var names := PackedStringArray()
		for r in d["requires"]:
			names.append(GameData.BUILDINGS[r]["name"])
		if d.has("level"):
			names.insert(0, "Usine niveau %d" % int(d["level"]))
		if not names.is_empty():
			tip += "\nNécessite : " + ", ".join(names)
		tooltip_text = tip
		mouse_entered.connect(func() -> void: _hover = true)
		mouse_exited.connect(func() -> void: _hover = false)

	func _process(delta: float) -> void:
		hover_t = move_toward(hover_t, 1.0 if _hover else 0.0, delta * 8.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed \
				and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
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

		var fcol: Color = game.fdata["color"]
		var accent: Color = fcol * 1.5 if avail else Color(0.4, 0.35, 0.5)
		accent.a = 1.0
		if ready:
			accent = GameData.GREEN
		var lit := maxf(hover_t, 0.35 + 0.65 * pulse if ready else 0.0)
		var line := Color(accent.r, accent.g, accent.b, 0.45 + 0.55 * lit)
		UiStyle.frame(self, Rect2(Vector2(2, 2), size - Vector2(4, 4)), 14.0, line, UiStyle.PANEL, lit * 0.8, lit * 0.6)
		# Liseré de faction en haut
		if avail:
			draw_rect(Rect2(20, 6, size.x - 40.0, 2.0), Color(fcol.r, fcol.g, fcol.b, 0.7))

		var c := Vector2(size.x * 0.5, 50.0 - hover_t * 2.0)
		_draw_icon(c, avail)
		if avail and not GameData.UNITS.has(id) and game.power_block(id) != "":
			UiStyle.text(self, Vector2(12, 24), "ÉNERGIE", 11, GameData.RED, true)
		if GameData.UNITS.has(id) and game.unit_level_block(id) != "":
			UiStyle.text(self, Vector2(0, 84), String(game.unit_level_block(id)).to_upper(), 11, GameData.AMBER, true,
					HORIZONTAL_ALIGNMENT_CENTER, size.x)
		elif GameData.UNITS.has(id) and not avail:
			UiStyle.text(self, Vector2(0, 84), "BÂTIMENT REQUIS", 11, GameData.AMBER, true,
					HORIZONTAL_ALIGNMENT_CENTER, size.x)
		if not GameData.UNITS.has(id) and not game.is_unlocked(id):
			UiStyle.text(self, Vector2(0, 84), "MISSION %d" % int(d.get("unlock", 0)), 12, GameData.AMBER, true,
					HORIZONTAL_ALIGNMENT_CENTER, size.x)
		elif d.has("faction") and not GameData.UNITS.has(id):
			UiStyle.text(self, Vector2(12, 24), "FACTION", 10, game.fdata["color"] * 1.5, true)
		var queued: int = game.queued_count(id)
		if queued > 0:
			var tag := Rect2(size.x - 44.0, 12.0, 32.0, 20.0)
			draw_colored_polygon(UiStyle.chamfer(tag, 6.0), Color(0.05, 0.03, 0.1, 0.95))
			draw_polyline(UiStyle.closed(UiStyle.chamfer(tag, 6.0)), UiStyle.GOLD, 1.6, true)
			UiStyle.text(self, Vector2(tag.position.x, tag.position.y + 15.0), "x%d" % queued, 13, Color.WHITE,
					true, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x)
		if busy:
			draw_arc(c, 38.0, 0.0, TAU, 48, Color(1, 1, 1, 0.12), 4.0, true)
			draw_arc(c, 38.0, -PI / 2.0, -PI / 2.0 + TAU * float(p["progress"]), 48,
					GameData.AMBER_HDR, 4.0, true)
		elif ready:
			draw_arc(c, 38.0, 0.0, TAU, 48, GameData.GREEN, 4.0, true)

		var tc := UiStyle.TEXT if avail else Color(0.5, 0.45, 0.55)
		UiStyle.text(self, Vector2(0, 104), String(d["name"]).to_upper(), 12, tc, true,
				HORIZONTAL_ALIGNMENT_CENTER, size.x)
		if ready:
			UiStyle.text(self, Vector2(0, 122), "PRÊT — CLIC", 12, Color(0.5, 1.0, 0.7, 0.6 + 0.4 * pulse), true,
					HORIZONTAL_ALIGNMENT_CENTER, size.x)
		else:
			var rich: bool = game.can_afford(id)
			var is_unit := GameData.UNITS.has(id)
			var cc := GameData.GOLD if is_unit else GameData.ORE_BLUE
			if not avail:
				cc = Color(0.4, 0.35, 0.3)
			elif not rich:
				cc = GameData.RED
			var label := str(game.item_cost(id))
			var w := UiStyle.text_width(label, 14)
			var x0 := (size.x - w - 18.0) * 0.5
			UiStyle.glyph(self, "credit" if is_unit else "ore", Vector2(x0 + 6, 118), 11.0, cc)
			UiStyle.text(self, Vector2(x0 + 18, 123), label, 14, cc)

	## Bâtiments débloqués : on affiche le modèle 3D cuit (ou un bloc simple sans affichage).
	func _draw_baked_icon(c: Vector2, avail: bool) -> void:
		var key := "%s|%s" % [id, game.faction_id]
		var tex = game.bank.frame(key) if game.bank != null and game.bank.has(key) else null
		if tex != null:
			var sz: Vector2 = game.bank.draw_size(key)
			var k := minf(1.0, minf(76.0 / sz.x, 62.0 / sz.y))
			draw_texture_rect(tex, Rect2(c - sz * k / 2.0, sz * k), false,
					Color.WHITE if avail else Color(0.45, 0.45, 0.5, 0.8))
		else:
			var line: Color = game.fdata["color"] * 1.6 if avail else Color(0.4, 0.35, 0.5)
			draw_rect(Rect2(c + Vector2(-22, -14), Vector2(44, 28)), Color("2a3350"))
			draw_rect(Rect2(c + Vector2(-22, -14), Vector2(44, 28)), line, false, 2.0)

	func _draw_icon(c: Vector2, avail: bool) -> void:
		var fill := Color("2a3350") if avail else Color("201c2c")
		var line: Color = game.fdata["color"] * 1.6 if avail else Color(0.4, 0.35, 0.5)
		line.a = 1.0
		var role: String = GameData.def(id).get("role", "")
		if GameData.BUILDINGS.has(id) and GameData.BUILDINGS[id].has("unlock"):
			_draw_baked_icon(c, avail)
			return
		if role == "harvester":
			draw_rect(Rect2(c + Vector2(-22, -13), Vector2(44, 26)), fill)
			draw_rect(Rect2(c + Vector2(-22, -13), Vector2(44, 26)), line, false, 2.0)
			draw_rect(Rect2(c + Vector2(-16, -8), Vector2(26, 16)), Color("e2762a") if avail else fill)
			draw_rect(Rect2(c + Vector2(12, -9), Vector2(8, 18)), line)
			return
		if role == "miner":
			draw_rect(Rect2(c + Vector2(-20, -12), Vector2(34, 24)), fill)
			draw_rect(Rect2(c + Vector2(-20, -12), Vector2(34, 24)), line, false, 2.0)
			draw_rect(Rect2(c + Vector2(-15, -7), Vector2(18, 14)), GameData.ORE_BLUE if avail else fill)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(14, -10), c + Vector2(30, 0), c + Vector2(14, 10)]), Color("9aa3b5"))
			return
		if role == "combat":
			draw_rect(Rect2(c + Vector2(-20, -12), Vector2(40, 24)), fill)
			draw_rect(Rect2(c + Vector2(-20, -12), Vector2(40, 24)), line, false, 2.0)
			draw_circle(c, 8.0, fill)
			draw_arc(c, 8.0, 0.0, TAU, 20, line, 2.0, true)
			draw_line(c, c + Vector2(28, 0), line, 3.0, true)
			return
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
			"fonderie":
				draw_rect(Rect2(c + Vector2(-30, -10), Vector2(36, 28)), fill)
				draw_rect(Rect2(c + Vector2(-30, -10), Vector2(36, 28)), line, false, 2.0)
				draw_rect(Rect2(c + Vector2(10, -22), Vector2(9, 22)), fill)
				draw_rect(Rect2(c + Vector2(24, -22), Vector2(9, 22)), fill)
				draw_rect(Rect2(c + Vector2(-22, 6), Vector2(20, 7)), Color(1.9, 0.7, 0.25) if avail else fill)
			"tourelle":
				draw_circle(c, 20.0, fill)
				draw_arc(c, 20.0, 0.0, TAU, 28, line, 2.0, true)
				draw_circle(c, 9.0, line)
				draw_line(c, c + Vector2(30, -8), line, 5.0, true)
			"usine":
				draw_rect(Rect2(c + Vector2(-34, -8), Vector2(68, 26)), fill)
				draw_rect(Rect2(c + Vector2(-34, -8), Vector2(68, 26)), line, false, 2.0)
				draw_rect(Rect2(c + Vector2(16, -20), Vector2(10, 14)), fill)
				draw_rect(Rect2(c + Vector2(16, -20), Vector2(10, 14)), line, false, 2.0)
