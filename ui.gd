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
	root.theme = UiStyle.theme()
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
			or (info_panel != null and info_panel.visible
			and (info_panel.get_global_transform() * Rect2(Vector2.ZERO, info_panel.size)).has_point(m))


## Notification qui monte et s'efface.
func toast(text: String, color := GameData.CREAM) -> void:
	if event_log != null:
		event_log.add(text, color)
	var l := Label.new()
	var wrapped := UiStyle.wrap_lines(text, 22, 620.0, true)
	l.text = "\n".join(PackedStringArray(wrapped))
	var extra := 28.0 * (wrapped.size() - 1)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiStyle.title_font())
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.02, 0.09, 0.5)
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
	l.offset_bottom = 150.0 + extra
	root.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "offset_top", 80.0, 2.2).from(110.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "offset_bottom", 120.0 + extra, 2.2).from(150.0 + extra).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(1.8)
	tw.chain().tween_callback(l.queue_free)


# --- Construction de l'interface ---------------------------------------------

var objective_panel: ObjectivePanel
var event_log: EventLog


func _build_objective() -> void:
	objective_panel = ObjectivePanel.new(game)
	objective_panel.position = Vector2(6, 100)
	objective_panel.size = Vector2(430, 76)
	root.add_child(objective_panel)


func toggle_objectives() -> void:
	objective_panel.visible = not objective_panel.visible
	if objective_panel.visible:
		objective_panel.pulse = 1.0


func _build_topbar() -> void:
	topbar = HudBar.new()
	topbar.game = game
	topbar.position = Vector2(6, 6)
	topbar.size = Vector2(1480, 80)
	root.add_child(topbar)
	var guide_btn := PlateButton.new("GUIDE", 3)
	guide_btn.font_size = 16
	guide_btn.position = Vector2(1076, 12)
	guide_btn.size = Vector2(122, 56)
	guide_btn.pressed.connect(func() -> void: Guide.open(game, game.faction_id))
	topbar.add_child(guide_btn)
	var obj_btn := PlateButton.new("OBJECTIFS", 4)
	obj_btn.font_size = 16
	obj_btn.position = Vector2(1204, 12)
	obj_btn.size = Vector2(142, 56)
	obj_btn.pressed.connect(toggle_objectives)
	topbar.add_child(obj_btn)
	var menu_btn := PlateButton.new("MENU", 1)
	menu_btn.font_size = 16
	menu_btn.position = Vector2(1352, 12)
	menu_btn.size = Vector2(112, 56)
	menu_btn.pressed.connect(game.open_pause_menu)
	topbar.add_child(menu_btn)


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

	# Journal des événements (remplace les anciens boutons de commande, désormais dans l'encart d'unité)
	event_log = EventLog.new()
	event_log.position = Vector2(24, 362)
	event_log.size = Vector2(SIDEBAR_W - 48.0, 88)
	sidebar.add_child(event_log)

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
		var cap: int = game.army_cap()
		info_label.text = "File : bâtiments %d/%d — unités %d/%d%s\nClic droit : ordre / annuler une icône\nÉchap pause — O objectifs — M son" \
				% [game.production["building"].size(), game.queue_max("building"),
				game.production["unit"].size(), game.queue_max("unit"),
				(" — armée %d/%d" % [game.army_count(), cap]) if cap > 0 else ""]


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
	vb.add_theme_constant_override("separation", 14)
	cc.add_child(vb)
	var l := Label.new()
	l.text = "VICTOIRE" if victory else "DÉFAITE"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 72)
	var col: Color = GameData.GREEN if victory else GameData.RED
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 14)
	vb.add_child(l)
	var sub := Label.new()
	sub.text = reason if reason != "" else ("Mission accomplie." if victory else "Mission échouée.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", GameData.CREAM)
	vb.add_child(sub)
	vb.add_child(_recap_panel(col))
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 24)
	vb.add_child(btns)
	if not game.mission.is_empty():
		var m: int = GameSession.mission
		var go := NeonButton.new("")
		go.accent = col
		go.custom_minimum_size = Vector2(300, 52)
		if victory and m + 1 < Campaign.count(game.faction_id):
			go.text = "MISSION SUIVANTE"
			go.pressed.connect(func() -> void:
				GameSession.mission = m + 1
				get_tree().change_scene_to_file("res://main.tscn"))
			btns.add_child(go)
		elif not victory:
			go.text = "RECOMMENCER"
			go.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main.tscn"))
			btns.add_child(go)
		else:
			sub.text = "Campagne terminée : Arrakis est à vous."
	var b := NeonButton.new("RETOUR AU MENU")
	b.accent = col
	b.custom_minimum_size = Vector2(300, 52)
	b.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://menu.tscn"))
	btns.add_child(b)
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.6, 1.2)


## Tableau récapitulatif (statistiques, unités, bâtiments) affiché sur l'écran de fin.
func _recap_panel(col: Color) -> Control:
	var st: GameStats = game.stats
	var fac: String = game.faction_id
	var mins := int(game.game_time) / 60
	var secs := int(game.game_time) % 60
	var gen: Array = [
		["Durée", "%d min %02d s" % [mins, secs]],
		["Solaris gagnés / dépensés", "%d / %d" % [game.earned, st.spent_sol]],
		["Minerai récolté / dépensé", "%d / %d" % [game.ore_earned, st.spent_ore]],
		["Dégâts infligés", str(int(st.dmg_dealt))],
		["Dégâts subis", str(int(st.dmg_taken))],
		["Ennemis abattus", str(GameStats.total(st.foes_killed))],
		["Ennemis dévorés par les vers", str(GameStats.total(st.foes_eaten))],
		["Vos unités dévorées par les vers", str(GameStats.total(st.units_eaten))],
		["Apparitions / morsures de vers", "%d / %d" % [st.worm_apparitions, st.worm_bites]],
		["Promotions", str(st.promotions)],
		["Modernisations / améliorations", "%d / %d" % [st.techs, st.upgrades]],
		["Bâtiments démolis", str(st.b_demolished)],
		["Armée maximale", str(st.max_army)],
	]
	if st.top_id != "":
		gen.append(["Unité la plus décorée", "%s (%d)" % [GameData.name_of(st.top_id, fac), st.top_kills]])
	var urows: Array = [["Unité", "Prod.", "Perdues", "Vers", "Abattus"]]
	var ids := {}
	for d in [st.units_built, st.units_lost, st.foes_killed, st.foes_eaten]:
		for k in d:
			ids[k] = true
	for k in ids:
		urows.append([GameData.name_of(k, fac), int(st.units_built.get(k, 0)), int(st.units_lost.get(k, 0)),
				int(st.units_eaten.get(k, 0)), int(st.foes_killed.get(k, 0)) + int(st.foes_eaten.get(k, 0))])
	var brows: Array = [["Bâtiment", "Const.", "Perdus", "Détruits"]]
	var bids := {}
	for d in [st.b_built, st.b_lost, st.b_foe]:
		for k in d:
			bids[k] = true
	for k in bids:
		brows.append([GameData.name_of(k, fac), int(st.b_built.get(k, 0)), int(st.b_lost.get(k, 0)), int(st.b_foe.get(k, 0))])
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.add_child(_recap_col("STATISTIQUES", gen, col, 440))
	hb.add_child(_recap_col("UNITÉS", urows, col, 470))
	hb.add_child(_recap_col("BÂTIMENTS", brows, col, 400))
	return hb


func _recap_col(title: String, rows: Array, col: Color, w: int) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.09, 0.85)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(w, 410)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", col)
	v.add_child(t)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var g := GridContainer.new()
	g.columns = (rows[0] as Array).size()
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 3)
	sc.add_child(g)
	var ncol := g.columns
	if rows.size() <= 1:
		var e := Label.new()
		e.text = "Rien à signaler."
		e.add_theme_color_override("font_color", GameData.CREAM)
		v.add_child(e)
	var first_header := ncol > 2
	for ri in rows.size():
		for ci in ncol:
			var c := Label.new()
			c.text = str(rows[ri][ci])
			c.add_theme_font_size_override("font_size", 15)
			var head: bool = first_header and ri == 0
			c.add_theme_color_override("font_color", GameData.AMBER if head else (GameData.CREAM if ci == 0 else Color.WHITE))
			if ci == 0:
				c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else:
				c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			g.add_child(c)
	return pc


# --- Objectif de mission ------------------------------------------------------

class EventLog extends Control:
	## Derniers messages du jeu (les notifications à l'écran disparaissent vite).
	const MAX := 4
	var lines: Array = [] # [texte, couleur, instant]

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func add(text: String, color: Color) -> void:
		if not lines.is_empty() and lines[0][0] == text:
			return
		lines.push_front([text, color, Time.get_ticks_msec() / 1000.0])
		while lines.size() > MAX:
			lines.pop_back()
		queue_redraw()

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		UiStyle.section(self, Vector2(0, 14), size.x, "JOURNAL", UiStyle.GOLD)
		var now := Time.get_ticks_msec() / 1000.0
		var y := 34.0
		var left := 5 # lignes disponibles
		for l in lines:
			if left <= 0:
				break
			var age := now - float(l[2])
			var c: Color = l[1]
			c.a = clampf(1.0 - age / 90.0, 0.35, 1.0)
			var wl := UiStyle.wrap_lines(String(l[0]), 12, size.x - 12.0)
			for i in mini(wl.size(), mini(2, left)):
				UiStyle.text(self, Vector2(0 if i == 0 else 8, y), String(wl[i]), 12, c)
				y += 14.0
				left -= 1
			y += 2.0
		if lines.is_empty():
			UiStyle.text(self, Vector2(0, y), "Aucun événement", 13, UiStyle.TEXT_DIM)


class ObjectivePanel extends GlassPanel:
	var game
	var pulse := 0.0

	## Objectifs affichés : ceux de la mission, ou la victoire par destruction en escarmouche.
	func _items() -> Array:
		if not game.mission.is_empty():
			return game.objectives_status()
		var out: Array = []
		var teams: Array = game.team_factions.keys().filter(func(t: int) -> bool: return game.hostile(t, 0))
		teams.sort()
		for t in teams:
			var n := 0
			for b in game.buildings:
				if b.alive and b.team == t:
					n += 1
			var alive: bool = game._team_alive(t)
			var fname: String = game.fdata_of(t)["name"]
			var txt := "Détruire la base %s : %d structure(s)" % [fname, n] if teams.size() > 1 \
					else "Détruire la base adverse : %d structure(s)" % n
			out.append({"text": txt, "frac": 0.0 if alive else 1.0, "done": not alive})
		return out

	func _init(p_game) -> void:
		super(8.0, 4.0, p_game.fdata["color"], p_game.fdata["accent"], 14.0)
		game = p_game
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _text_lines(o: Dictionary) -> Array:
		return UiStyle.wrap_lines(String(o["text"]), 14, 450.0 - 42.0 - 20.0)

	func _process(_delta: float) -> void:
		var h := 44.0
		for o in _items():
			h += 40.0 + 17.0 * (_text_lines(o).size() - 1)
		size = Vector2(450, h)
		pulse = move_toward(pulse, 0.0, _delta * 1.5)
		queue_redraw()

	func _draw() -> void:
		var m: Dictionary = game.mission
		var head := "ESCARMOUCHE — OBJECTIF"
		if not m.is_empty():
			head = "MISSION %d — %s" % [GameSession.mission + 1, String(m["title"]).to_upper()]
		if pulse > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.8, 0.3, 0.18 * pulse))
		UiStyle.text(self, Vector2(20, 26), head, 13, UiStyle.GOLD, true)
		var y := 54.0
		for o in _items():
			var done: bool = o["done"]
			var c := Vector2(26, y - 5.0)
			var col := GameData.GREEN if done else UiStyle.GOLD
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]),
					col if done else Color(col.r, col.g, col.b, 0.25))
			draw_polyline(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0), c + Vector2(0, -6)]),
					col, 1.4)
			var yt := y
			for ln in _text_lines(o):
				UiStyle.text(self, Vector2(42, yt), String(ln), 14, UiStyle.TEXT if not done else GameData.GREEN)
				yt += 17.0
			yt -= 17.0
			UiStyle.seg_bar(self, Rect2(42, yt + 8.0, size.x - 62.0, 6), float(o["frac"]), col, 8.0, 3.0)
			y = yt + 40.0


# --- Barre de ressources ------------------------------------------------------

class HudBar extends Control:
	var game
	var shown_credits := 0.0
	var shown_ore := 0.0
	var shown_load := 0.0
	var _init_done := false
	var _t := 0.0
	const GOLD_LINE := Color("e2b24a")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	## Dégradé bleu (marge) → ambre → rouge (seuil critique) selon la charge 0..1.
	func _power_color(f: float) -> Color:
		var blue := GameData.CYAN
		var amber := GameData.AMBER_HDR
		var red := GameData.RED
		if f < 0.6:
			return blue.lerp(amber, f / 0.6 * 0.5)
		if f < 0.85:
			return blue.lerp(amber, 0.5 + (f - 0.6) / 0.25 * 0.5)
		return amber.lerp(red, clampf((f - 0.85) / 0.15, 0.0, 1.0))

	func _process(delta: float) -> void:
		if game == null:
			return
		_t += delta
		var prod: int = game.power_produced()
		var used: int = game.power_used()
		var lf := clampf(float(used) / float(prod), 0.0, 1.0) if prod > 0 else (1.0 if used > 0 else 0.0)
		if not _init_done:
			shown_credits = float(game.credits)
			shown_ore = float(game.ore)
			shown_load = lf
			_init_done = true
		shown_credits = lerpf(shown_credits, float(game.credits), clampf(delta * 7.0, 0.0, 1.0))
		shown_ore = lerpf(shown_ore, float(game.ore), clampf(delta * 7.0, 0.0, 1.0))
		shown_load = lerpf(shown_load, lf, clampf(delta * 6.0, 0.0, 1.0))
		queue_redraw()

	# --- Primitives lissées -----------------------------------------------------------------

	## Texte net : ombre portée douce plutôt qu'un contour épais.
	func _tx(pos: Vector2, s: String, size: int, col: Color, title := false) -> void:
		var f := UiStyle.title_font() if title else UiStyle.body_font()
		draw_string(f, pos + Vector2(0, 1.6), s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(0, 0, 0, 0.55))
		draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)

	## Gélule (barre arrondie) de largeur w.
	func _cap(r: Rect2, w: float) -> PackedVector2Array:
		var rad := r.size.y * 0.5
		w = maxf(w, r.size.y)
		var cy := r.position.y + rad
		var pts := PackedVector2Array()
		for i in 11:
			var a := PI * 0.5 + PI * float(i) / 10.0
			pts.append(Vector2(r.position.x + rad + cos(a) * rad, cy + sin(a) * rad))
		for i in 11:
			var a := -PI * 0.5 + PI * float(i) / 10.0
			pts.append(Vector2(r.position.x + w - rad + cos(a) * rad, cy + sin(a) * rad))
		return pts

	## Jauge lisse : rail sombre, remplissage en dégradé avec reflet, graduations discrètes.
	func _gauge(r: Rect2, frac: float, c_left: Color, c_right: Color, ticks := true) -> void:
		draw_colored_polygon(_cap(r, r.size.x), Color(0.0, 0.0, 0.0, 0.5))
		if frac > 0.003:
			var pts := _cap(r, r.size.x * clampf(frac, 0.0, 1.0))
			var cols := PackedColorArray()
			for p in pts:
				var k := clampf((p.x - r.position.x) / r.size.x, 0.0, 1.0)
				var v := clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)
				var c := c_left.lerp(c_right, k / maxf(frac, 0.05))
				c = c.lerp(Color.WHITE, (1.0 - v) * 0.28).lerp(Color.BLACK, v * 0.22)
				c.a = 1.0
				cols.append(c)
			draw_polygon(pts, cols)
			var hw := r.size.x * clampf(frac, 0.0, 1.0)
			draw_line(r.position + Vector2(r.size.y * 0.5, 1.4), r.position + Vector2(maxf(hw - r.size.y * 0.5, r.size.y * 0.5), 1.4),
					Color(1, 1, 1, 0.45), 1.0, true)
		if ticks:
			for q: float in [0.25, 0.5, 0.75]:
				var x := r.position.x + r.size.x * q
				draw_line(Vector2(x, r.position.y + 1.0), Vector2(x, r.end.y - 1.0), Color(0, 0, 0, 0.35), 1.0, true)
		draw_polyline(UiStyle.closed(_cap(r, r.size.x)), Color(1, 1, 1, 0.2), 1.0, true)

	## Cartouche d'une valeur : fond enfoncé, fin liseré teinté.
	func _slot(r: Rect2, col: Color) -> void:
		var pts := UiStyle.chamfer(r, 9.0, true)
		draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.28))
		draw_polyline(UiStyle.closed(pts), Color(col.r, col.g, col.b, 0.28), 1.2, true)
		draw_line(r.position + Vector2(12, 1.2), Vector2(r.end.x - 12, r.position.y + 1.2), Color(1, 1, 1, 0.07), 1.0, true)

	## Médaillon rond portant un symbole.
	func _medal(c: Vector2, col: Color, glyph: String) -> void:
		draw_circle(c, 20.0, Color(col.r, col.g, col.b, 0.1))
		draw_circle(c, 17.0, Color(0.03, 0.02, 0.07, 0.95))
		draw_arc(c, 17.0, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.95), 2.0, true)
		draw_arc(c, 13.0, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.25), 1.0, true)
		if glyph == "clock":
			draw_arc(c, 8.0, 0.0, TAU, 28, col, 1.6, true)
			draw_line(c, c + Vector2(0, -6.0), col, 1.8, true)
			draw_line(c, c + Vector2(4.5, 2.0), col, 1.8, true)
		else:
			UiStyle.glyph(self, glyph, c, 15.0, col)

	func _sep(x: float) -> void:
		draw_line(Vector2(x, 18), Vector2(x, size.y - 18), Color(GOLD_LINE.r, GOLD_LINE.g, GOLD_LINE.b, 0.22), 1.0, true)

	# --- Dessin -----------------------------------------------------------------------------------

	func _draw_frame() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var out := UiStyle.chamfer(r.grow(-3.0), 16.0, true)
		# ombre portée
		for k in 4:
			draw_polyline(UiStyle.closed(UiStyle.chamfer(r.grow(-3.0 + k * 0.9), 16.0 + k, true)), Color(0, 0, 0, 0.1), 2.0, true)
		# fond : dégradé vertical indigo, quasi opaque (aucun bruit ni trame)
		var cols := PackedColorArray()
		for p in out:
			var v := clampf(p.y / size.y, 0.0, 1.0)
			cols.append(Color(0.13, 0.085, 0.2, 0.96).lerp(Color(0.045, 0.028, 0.085, 0.97), pow(v, 0.8)))
		draw_polygon(out, cols)
		# reflet de verre sur la moitié haute
		var gl := PackedVector2Array([Vector2(22, 5.0), Vector2(size.x - 22, 5.0), Vector2(size.x - 22, size.y * 0.42), Vector2(22, size.y * 0.42)])
		draw_polygon(gl, PackedColorArray([Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))
		# double liseré doré
		draw_polyline(UiStyle.closed(out), Color(GOLD_LINE.r, GOLD_LINE.g, GOLD_LINE.b, 0.95), 1.8, true)
		draw_polyline(UiStyle.closed(UiStyle.chamfer(r.grow(-8.0), 12.0, true)), Color(GOLD_LINE.r, GOLD_LINE.g, GOLD_LINE.b, 0.2), 1.0, true)
		# équerres brillantes aux angles taillés
		for sx: float in [0.0, 1.0]:
			var x := 3.0 + (size.x - 6.0) * sx
			var d: float = 1.0 - 2.0 * sx
			draw_line(Vector2(x + d * 16.0, 3.0), Vector2(x + d * 44.0, 3.0), Color(1.0, 0.9, 0.55, 1.0), 2.6, true)
			draw_line(Vector2(x + d * 16.0, size.y - 3.0), Vector2(x + d * 44.0, size.y - 3.0), Color(1.0, 0.9, 0.55, 0.0 + 0.7), 2.0, true)
		# losanges d'extrémité
		for x: float in [14.0, size.x - 14.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(x, size.y * 0.5 - 6), Vector2(x + 4, size.y * 0.5), Vector2(x, size.y * 0.5 + 6), Vector2(x - 4, size.y * 0.5)]), GOLD_LINE)

	func _resource(x: float, w: float, label: String, value: String, vcol: Color, glyph: String, gcol: Color,
			cap: int, amount: int) -> void:
		_slot(Rect2(x, 11, w, size.y - 22), gcol)
		_medal(Vector2(x + 31, size.y * 0.5), gcol, glyph)
		_tx(Vector2(x + 58, 28), label, 11, UiStyle.TEXT_DIM, true)
		_tx(Vector2(x + 58, 56), value, 28, vcol)
		var vw := UiStyle.text_width(value, 28)
		var full := amount >= cap
		_tx(Vector2(x + 58 + vw + 7, 56), "/ %d" % cap, 14, GameData.RED if full else UiStyle.TEXT_DIM)
		var fill := clampf(float(amount) / float(cap), 0.0, 1.0)
		var lo := gcol.darkened(0.35)
		var hi := gcol.lightened(0.2)
		if fill > 0.95:
			lo = GameData.RED.darkened(0.2)
			hi = GameData.RED
		elif fill > 0.8:
			hi = GameData.AMBER
		_gauge(Rect2(x + 58, 62, w - 74, 7), fill, lo, hi)

	func _draw() -> void:
		if game == null:
			return
		_draw_frame()
		# Solaris : le compteur glisse vers la valeur réelle et clignote vert/rouge
		var diff: float = float(game.credits) - shown_credits
		var col := GameData.GOLD
		if absf(diff) > 1.0:
			var k := clampf(absf(diff) / 200.0, 0.0, 1.0)
			col = GameData.GOLD.lerp(Color("5dff9a") if diff > 0.0 else Color("ff5a4a"), k)
		_resource(26, 238, "SOLARIS", str(int(round(shown_credits))), col, "credit", GameData.AMBER_HDR,
				game.storage_cap("spice"), game.credits)
		_resource(274, 238, "MINERAI", str(int(round(shown_ore))), GameData.ORE_BLUE, "ore", GameData.CYAN,
				game.storage_cap("ore"), game.ore)

		# Énergie : jauge lisse (consommation / production), bleu = large marge, rouge = seuil critique
		var prod: int = game.power_produced()
		var used: int = game.power_used()
		var ok := prod >= used
		var load_col := _power_color(shown_load)
		var ex := 522.0
		_slot(Rect2(ex, 11, 272, size.y - 22), load_col)
		_medal(Vector2(ex + 31, size.y * 0.5), load_col, "power")
		_tx(Vector2(ex + 58, 28), "ÉNERGIE", 11, UiStyle.TEXT_DIM, true)
		_tx(Vector2(ex + 58, 56), "%d" % used, 24, Color.WHITE if ok else GameData.RED)
		var uw := UiStyle.text_width("%d" % used, 24)
		_tx(Vector2(ex + 58 + uw + 6, 56), "/ %d" % prod, 15, UiStyle.TEXT_DIM)
		_gauge(Rect2(ex + 58, 62, 198, 7), shown_load, _power_color(0.0), load_col)

		# Temps
		var t: float = game.game_time
		var tx := 806.0
		_slot(Rect2(tx, 11, 164, size.y - 22), UiStyle.GOLD)
		_medal(Vector2(tx + 31, size.y * 0.5), UiStyle.GOLD, "clock")
		_tx(Vector2(tx + 58, 28), "TEMPS", 11, UiStyle.TEXT_DIM, true)
		_tx(Vector2(tx + 58, 57), "%02d:%02d:%02d" % [int(t / 3600.0), int(t / 60.0) % 60, int(t) % 60], 25, Color.WHITE)

		# Images par seconde
		var fx := 982.0
		var fps := int(Engine.get_frames_per_second())
		var fcol := GameData.GREEN if fps >= 45 else (GameData.AMBER if fps >= 25 else GameData.RED)
		_slot(Rect2(fx, 11, 82, size.y - 22), fcol)
		_tx(Vector2(fx + 16, 28), "FPS", 11, UiStyle.TEXT_DIM, true)
		_tx(Vector2(fx + 16, 57), "%d" % fps, 25, fcol)


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
			"sonic": "Onde sonique", "acid": "Acide", "control": "Contrôle mental", "shard": "Éclats de cristal",
			"mortar": "Mortier", "flame": "Lance-flammes", "plasma": "Plasma", "laser": "Laser"}
	const COL2 := 430.0
	const PANEL_SCALE := 0.78

	var game
	var btn: GameUI.NeonButton
	var rbtn: GameUI.NeonButton
	var dbtn: GameUI.NeonButton
	var cmd_btns: Array = []
	var _confirm_t := 0.0
	var _focus = null

	func _init(p_game) -> void:
		super(8.0, 4.0, p_game.fdata["color"], p_game.fdata["accent"], 24.0)
		game = p_game
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_left = 16.0
		offset_right = 16.0 + 800.0
		offset_top = -296.0
		offset_bottom = -16.0
		# Cartouche compact : réduit vers son coin bas-gauche pour dégager la zone de jeu
		pivot_offset = Vector2(0, 280)
		scale = Vector2(PANEL_SCALE, PANEL_SCALE)
		btn = GameUI.NeonButton.new("AMÉLIORER")
		btn.accent = GameData.GOLD
		btn.glyph = "credit"
		btn.position = Vector2(COL2, 244)
		btn.size = Vector2(330, 36)
		btn.pressed.connect(func() -> void:
			if _focus is Building:
				if _focus.up_left > 0.0:
					game.cancel_upgrade(_focus)
				else:
					game.upgrade_building(_focus)
			elif _focus is Unit:
				if _focus.tech_left > 0.0:
					game.cancel_unit_tech(_focus)
				else:
					game.upgrade_unit(_focus))
		add_child(btn)
		rbtn = GameUI.NeonButton.new("RÉPARER")
		rbtn.accent = GameData.GREEN
		rbtn.glyph = "credit"
		rbtn.position = Vector2(34, 244)
		rbtn.size = Vector2(262, 36)
		rbtn.pressed.connect(func() -> void:
			if _focus is Building:
				game.toggle_repair(_focus)
			elif _focus is Unit:
				game.repair_unit(_focus))
		add_child(rbtn)
		dbtn = GameUI.NeonButton.new("DÉMOLIR")
		dbtn.accent = GameData.RED
		dbtn.glyph = "stop"
		dbtn.position = Vector2(304, 244)
		dbtn.size = Vector2(112, 36)
		dbtn.pressed.connect(func() -> void:
			if _focus is Building:
				if _confirm_t > 0.0:
					_confirm_t = 0.0
					game.demolish_building(_focus)
				else:
					_confirm_t = 3.0
					game.ui.toast("Cliquez à nouveau sur DÉMOLIR pour confirmer", GameData.AMBER))
		add_child(dbtn)
		# Commandes d'unité : Arrêt / Déplacer / Attaquer / Déployer (ou Décharger)
		for i in COMMANDS.size():
			var cmd: Array = COMMANDS[i]
			var cb := GameUI.NeonButton.new(cmd[1])
			cb.position = Vector2(398.0 + i * 96.0, 14)
			cb.size = Vector2(90, 32)
			cb.pressed.connect(func() -> void:
				var c: String = cb.get_meta("cmd")
				game.on_command(c))
			cb.set_meta("cmd", cmd[0])
			add_child(cb)
			cmd_btns.append(cb)
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
		var is_b: bool = _focus is Building and _focus.team == 0 and GameData.can_upgrade(_focus.id)
		var is_u: bool = _focus is Unit and _focus.team == 0 and GameData.UNIT_TECH.has(_focus.id)
		btn.visible = is_b or is_u
		if is_b:
			var b: Building = _focus
			btn.position = Vector2(COL2, 14)
			btn.size = Vector2(340, 32)
			rbtn.position = Vector2(COL2, 52)
			rbtn.size = Vector2(224, 32)
			dbtn.position = Vector2(COL2 + 232.0, 52)
			dbtn.size = Vector2(108, 32)
			var why: String = game.upgrade_block(b, game.ore)
			btn.enabled = why == "" or b.up_left > 0.0
			btn.accent = GameData.RED if b.up_left > 0.0 else GameData.GOLD
			if b.up_left > 0.0:
				btn.text = "ANNULER — %d S RESTANTES" % int(ceil(b.up_left))
				why = "Annule l'amélioration et rembourse la part déjà payée"
			elif b.level >= GameData.MAX_LEVEL:
				btn.text = "NIVEAU MAXIMUM"
			else:
				btn.text = "AMÉLIORER — %d MIN. · %d S" % [game.upgrade_cost(b), int(game.upgrade_time(b))]
			btn.glyph = "ore"
			btn.tooltip_text = why
		elif is_u:
			var u: Unit = _focus
			btn.position = Vector2(592, 52)
			btn.size = Vector2(188, 32)
			rbtn.position = Vector2(398, 52)
			rbtn.size = Vector2(186, 32)
			var why2: String = game.unit_upgrade_block(u)
			btn.enabled = why2 == "" or u.tech_left > 0.0
			btn.accent = GameData.RED if u.tech_left > 0.0 else GameData.GOLD
			if u.tech_left > 0.0:
				btn.text = "ANNULER — %d S" % int(ceil(u.tech_left))
				why2 = "Annule la modernisation et rembourse la part déjà payée"
			elif u.tech > 0:
				btn.text = "MODERNISÉE"
			else:
				btn.text = "MODERNISER — %d SOL. · %d S" % [GameData.tech_cost(u.id), int(GameData.tech_time(u.id))]
			btn.glyph = "credit"
			btn.tooltip_text = why2
		_update_commands()
		if _focus is Building:
			rbtn.position = Vector2(COL2, 52)
			rbtn.size = Vector2(224, 32)
			dbtn.position = Vector2(COL2 + 232.0, 52)
			dbtn.size = Vector2(108, 32)
		elif _focus is Unit:
			rbtn.position = Vector2(398, 52)
			rbtn.size = Vector2(186, 32)
		var can_rep: bool = (_focus is Building or _focus is Unit) and _focus.team == 0 \
				and not (_focus is Unit and (_focus.role == "convoy"))
		rbtn.visible = can_rep
		dbtn.visible = _focus is Building and _focus.team == 0
		_confirm_t = maxf(0.0, _confirm_t - _delta)
		dbtn.text = "CONFIRMER ?" if _confirm_t > 0.0 else "DÉMOLIR"
		if _focus is Building and _confirm_t > 0.0:
			dbtn.text = "CONFIRMER (+%d / +%d)" % [int(round(float(GameData.base_cost(_focus.id)) * 0.4)),
					int(round(GameData.sol_cost(_focus.id) * 0.4))]
		dbtn.accent = GameData.RED if _confirm_t > 0.0 else Color(0.75, 0.35, 0.35)
		if can_rep:
			if _focus is Building:
				var rb: Building = _focus
				rbtn.enabled = game.repair_block(rb) == "" and (rb.repairing or rb.hp < rb.max_hp - 0.5)
				rbtn.text = "ARRÊTER LA RÉPARATION" if rb.repairing else "RÉPARER — %d MIN." % game.repair_cost_full(rb)
				rbtn.glyph = "ore"
				rbtn.tooltip_text = game.repair_block(rb)
			else:
				var ru: Unit = _focus
				rbtn.enabled = game.unit_repair_block(ru) == ""
				rbtn.text = "RÉPARATION EN COURS" if ru.state == "repair" else "RÉPARER — %d SOL." % game.unit_repair_cost(ru)
				rbtn.glyph = "credit"
				rbtn.tooltip_text = game.unit_repair_block(ru)
		queue_redraw()

	## Les commandes ne s'affichent que pour des unités à soi, et seulement celles qui ont un sens
	## pour la sélection (pas d'ATTAQUER sans unité armée ; VIDER pour les ouvriers).
	func _update_commands() -> void:
		var show := false
		if _focus is Unit and _focus.team == 0 and not _focus.convoy:
			show = true
		elif _focus is String:
			show = true
		var has_mcv := false
		var has_loaded := false
		var has_worker := false
		var has_armed := false
		for u in game.selected:
			if u.role == "mcv":
				has_mcv = true
			if u.role == "transport" and not u.cargo_units.is_empty():
				has_loaded = true
			if u.is_worker():
				has_worker = true
			if u.weapon != "":
				has_armed = true
		var last: GameUI.NeonButton = cmd_btns[3]
		if has_mcv:
			last.text = "DÉPLOYER"
			last.set_meta("cmd", "deploy")
			last.enabled = true
		elif has_loaded:
			last.text = "DÉCHARGER"
			last.set_meta("cmd", "unload")
			last.enabled = true
		elif has_worker:
			last.text = "VIDER"
			last.set_meta("cmd", "unload")
			last.enabled = true
			last.tooltip_text = "Retourne au dépôt décharger la cargaison, même incomplète (U)"
		else:
			last.text = "DÉPLOYER"
			last.set_meta("cmd", "deploy")
			last.enabled = false
		var show_last := has_mcv or has_loaded or has_worker
		var vis := [show, show, show and has_armed, show and show_last]
		var x := 398.0
		for i in cmd_btns.size():
			cmd_btns[i].visible = vis[i]
			if vis[i]:
				cmd_btns[i].position = Vector2(x, 14)
				x += 96.0
		if show:
			cmd_btns[1].active = game.command_mode == "move"
			cmd_btns[2].active = game.command_mode == "attack"

	## Ligne « LIBELLÉ  valeur » ; la valeur passe à la ligne si elle déborde. Renvoie la hauteur utilisée.
	func _row(x: float, y: float, label: String, value: String, vcol := UiStyle.TEXT) -> float:
		UiStyle.text(self, Vector2(x, y), label.to_upper(), 11, UiStyle.TEXT_DIM, true)
		var yn := UiStyle.para(self, Vector2(x + 120, y), value, 15, vcol, COL2 - x - 120.0 - 14.0, 18.0)
		return maxf(22.0, yn - y + 4.0)

	## Texte de la 2e colonne, à la ligne dans 340 px. Renvoie la ligne de base suivante.
	func _c2(y: float, s: String, size: int, col: Color) -> float:
		return UiStyle.para(self, Vector2(COL2, y), s, size, col, 340.0, size + 5.0)

	func _hp_block(name_s: String, sub: String, hp: float, hp_max: float, mine: bool, tag := "") -> void:
		var col := Color.WHITE if mine else GameData.RED
		# Le titre ne doit jamais déborder sur les boutons (AMÉLIORER, RÉPARER…) : corps réduit si besoin
		var max_w := 700.0
		if btn.visible:
			max_w = (COL2 if _focus is Building else 398.0) - 34.0 - 22.0
		var title := name_s.to_upper()
		var fs := 24
		while fs > 14 and UiStyle.text_width(title, fs, true) > max_w:
			fs -= 1
		UiStyle.text(self, Vector2(34, 58), title, fs, col, true)
		var tag_in_title := false
		if tag != "":
			var w := UiStyle.text_width(title, fs, true)
			tag_in_title = w + 14.0 + UiStyle.text_width(tag, 14) <= max_w
			if tag_in_title:
				UiStyle.text(self, Vector2(34 + w + 14, 58), tag, 14, UiStyle.GOLD, true)
		if sub != "":
			var sl := UiStyle.wrap_lines(sub, 13, minf(max_w + 20.0, 730.0))
			for i in mini(sl.size(), 2):
				var ln: String = sl[i]
				if i == 1 and sl.size() > 2:
					ln = ln.substr(0, maxi(ln.length() - 1, 1)) + "…"
				UiStyle.text(self, Vector2(34, 76 + 15 * i), ln, 13, UiStyle.TEXT_DIM)
		if tag != "" and not tag_in_title:
			var sw := UiStyle.text_width(sub, 13) if sub != "" else 0.0
			UiStyle.text(self, Vector2(34 + minf(sw, 200.0) + (14.0 if sub != "" else 0.0), 76), tag, 13, UiStyle.GOLD, true)
		UiStyle.seg_bar(self, Rect2(34, 96, 340, 11), hp / maxf(hp_max, 1.0), GameData.GREEN if mine else GameData.RED, 8.0, 3.0)
		UiStyle.text(self, Vector2(386, 106), "%d / %d" % [int(hp), int(hp_max)], 13, UiStyle.TEXT)

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
			UiStyle.text(self, Vector2(x + 34, y), GameData.dname(id), 15, UiStyle.TEXT)
			y += 22.0
			if y > 228.0:
				y = 152.0
				x += 190.0
		UiStyle.section(self, Vector2(COL2, 128), 340, "ORDRES", UiStyle.GOLD)
		var ym := _c2(154.0, "Clic droit : déplacer ou attaquer", 14, UiStyle.TEXT)
		ym = _c2(ym + 3.0, "ATTAQUER : avance en tirant", 14, UiStyle.TEXT)
		_c2(ym + 3.0, "ARRÊT : annule les ordres", 14, UiStyle.TEXT)

	func _tech_line(u: Unit) -> String:
		if not GameData.UNIT_TECH.has(u.id):
			return ""
		return ("Modernisée : " if u.tech > 0 else "Modernisation : ") + GameData.tech_text(u.id)

	func _draw_unit(u: Unit) -> void:
		var d := GameData.def(u.id)
		var mine: bool = u.team == 0
		var rank_tag := String(GameData.RANKS[u.rank]["name"]).to_upper() if u.role == "combat" else ""
		_hp_block(GameData.name_of(u.id, game.faction_id_of(u.team)), GameData.desc_of(u.id, game.faction_id_of(u.team)), u.hp, u.max_hp, mine, rank_tag)
		if u.role == "mcv" or u.role == "convoy":
			UiStyle.section(self, Vector2(34, 128), 360, "CARACTÉRISTIQUES", UiStyle.GOLD)
			var yr := 152.0
			yr += _row(34, yr, "Blindage", ARMOR.get(u.armor, u.armor))
			_row(34, yr, "Vitesse", "%d    Vision %d cases" % [int(u.speed), u.vision])
			UiStyle.section(self, Vector2(COL2, 128), 340, "RÔLE", UiStyle.GOLD)
			if u.role == "mcv":
				_c2(154.0, "Placez-le sur un sol rocheux dégagé puis cliquez sur DÉPLOYER pour créer votre " + GameData.dname("chantier") + " (3x3 cases).", 14, UiStyle.TEXT)
			else:
				_c2(154.0, "Cargaison à évacuer par le point cyan, au bord de la carte (visible sur la carte et le radar).", 14, UiStyle.TEXT)
			return
		UiStyle.section(self, Vector2(34, 128), 360, "CARACTÉRISTIQUES", UiStyle.GOLD)
		var y := 152.0
		y += _row(34, y, "Blindage", ARMOR.get(u.armor, u.armor))
		y += _row(34, y, "Vitesse", "%d    Vision %d cases" % [int(u.speed), u.vision])
		if u.weapon != "":
			var mult := 1.0 + GameData.RANK_DMG * u.rank
			y += _row(34, y, "Arme", String(WEAPON.get(u.weapon, u.weapon)) + (" — air + sol" if GameData.can_hit_air(u.id) else " — sol seulement"))
			_row(34, y, "Dégâts", "%.0f /s    Portée %d cases" % [u.dps * mult, int(u.w_range / 32.0)])
		elif u.heal_rate > 0.0:
			y += _row(34, y, "Soins", "%d PV/s aux alliés" % int(u.heal_rate))
			_row(34, y, "Rayon", "%d cases" % int(u.heal_range / 32.0))
		elif u.role == "transport":
			y += _row(34, y, "Soute", "%d / %d unités" % [u.cargo_units.size(), u.slots])
			_row(34, y, "Vol", "Ignore le terrain")
		else:
			y += _row(34, y, "Capacité", "%d  (%d en soute)" % [roundi(u.cargo_cap), roundi(u.cargo)])
			_row(34, y, "Rendement", "%d /s" % int(u.harvest_rate))
		UiStyle.section(self, Vector2(COL2, 128), 340, "ÉVOLUTION" if u.role == "combat" else "RÔLE", UiStyle.GOLD)
		var y2 := 154.0
		if u.role == "combat":
			var nxt := ""
			if u.rank + 1 < GameData.RANKS.size():
				nxt = "Prochain rang : %d éliminations" % GameData.RANKS[u.rank + 1]["kills"]
			else:
				nxt = "Rang maximum"
			y2 = _c2(y2, "%d éliminations — %s" % [u.kills, nxt.trim_prefix("Prochain rang : ")], 14, UiStyle.GOLD)
			if u.weapon == "control":
				y2 = _c2(y2 + 2.0, "Contrôle un char ennemi 15 s (toutes les 20 s)", 13, GameData.CYAN)
			elif u.weapon == "sonic":
				y2 = _c2(y2 + 2.0, "Dégâts de zone, touche aussi les alliés", 13, GameData.AMBER)
			else:
				y2 = _c2(y2 + 2.0, "Chaque rang : +15 % dégâts et PV", 13, UiStyle.TEXT_DIM)
		elif u.role == "transport":
			y2 = _c2(y2, "Clic droit sur une unité : l'embarquer", 13, UiStyle.TEXT)
			y2 = _c2(y2 + 2.0, "Clic droit au sol : y aller. Bouton DÉCHARGER (U) pour déposer", 13, UiStyle.TEXT)
		else:
			y2 = _c2(y2, "Récolte automatiquement et rapporte à : " + GameData.dname("raffinerie" if u.cargo_kind == "spice" else "fonderie") + ".", 14, UiStyle.TEXT)
		if _tech_line(u) != "":
			_c2(y2 + 2.0, _tech_line(u), 13, GameData.GREEN if u.tech > 0 else UiStyle.TEXT)

	## Lignes d'info des bâtiments sans cas particulier : déduites de leurs caractéristiques.
	func _generic_rows(rows: Array, b: Building, d: Dictionary) -> void:
		if b.weapon != "":
			rows.append(["Dégâts", "%.0f /s%s" % [b.dps, " (zone)" if float(GameData.WEAPONS[b.weapon]["splash"]) > 0.0 else ""]])
			rows.append(["Portée", "%d cases — %s" % [int(b.w_range / 32.0), "air + sol" if d.get("aa", false) else "sol seulement"]])
		if d.has("income"):
			rows.append(["Revenu", "+%.1f Solaris/s" % float(d["income"])])
		if d.has("ore_income"):
			rows.append(["Revenu", "+%.1f minerai/s" % float(d["ore_income"])])
		if d.has("heal"):
			rows.append(["Soins", "%d PV/s sur %d cases" % [int(d["heal"]), int(d["heal_range"])]])
		if d.has("aura_regen"):
			rows.append(["Aura", "%d PV/s aux bâtiments (%d cases)" % [int(d["aura_regen"]), int(d.get("aura_range", 6))]])
		if d.has("storage"):
			rows.append(["Stockage", String(d["storage"])])
		if d.get("wall", false):
			rows.append(["Rôle", "Barrière"])
		if d.has("vision") and int(d["vision"]) > 12:
			rows.append(["Détection", "%d cases" % int(d["vision"])])
		if b.power > 0:
			rows.append(["Énergie", "+%d" % b.power])


	func _building_sub(b: Building, mine: bool) -> String:
		var ds := GameData.desc_of(b.id, game.faction_id_of(b.team))
		if ds == "":
			return "Structure alliée" if mine else "Structure ennemie"
		return ds if mine else "Ennemi — " + ds

	func _draw_building(b: Building) -> void:
		var d := GameData.def(b.id)
		var mine: bool = b.team == 0
		_hp_block(GameData.name_of(b.id, game.faction_id_of(b.team)), _building_sub(b, mine), b.hp, b.max_hp, mine)
		UiStyle.section(self, Vector2(34, 128), 360, "CARACTÉRISTIQUES", UiStyle.GOLD)
		var rows: Array = []
		if not d.get("wall", false) and GameData.can_upgrade(b.id):
			rows.append(["Niveau", "%d / %d" % [b.level, GameData.MAX_LEVEL]])
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
				rows.append(["Stockage", "+1500 Solaris"])
			"fonderie":
				rows.append(["Minerai", "+%d %% par récolte" % int(12 * (b.level - 1))])
				rows.append(["Stockage", "+1500 minerai"])
			"tourelle", "batterie", "tour_sonique", "bunker", "tour_acide", "tour_prisme":
				rows.append(["Dégâts", "%.0f /s" % b.dps])
				rows.append(["Portée", "%d cases" % int(b.w_range / 32.0)])
			"silo":
				rows.append(["Solaris", "+10 % par silo (3 max.)"])
				rows.append(["Stockage", "+2000 Solaris"])
			"silo_minerai":
				rows.append(["Minerai", "+10 % par silo (3 max.)"])
				rows.append(["Stockage", "+2000 minerai"])
			"reparation":
				rows.append(["Soins", "%d PV/s" % int(d["heal"])])
				rows.append(["Rayon", "%d cases" % int(d["heal_range"])])
			"reacteur", "relais_solaire":
				rows.append(["Énergie", "+%d" % b.power])
			"marche":
				rows.append(["Revenu", "+%d Solaris/s" % int(d["income"])])
			"serre":
				rows.append(["Revenu", "+%d minerai/s" % int(d["ore_income"])])
			"mur", "mur_acier", "mur_cristal":
				rows.append(["Rôle", "Barrière"])
			_:
				_generic_rows(rows, b, d)
		if b.power < 0:
			rows.append(["Consomme", "%d énergie" % -b.power])
		elif b.power == 0 and b.id != "mur" and b.id != "mur_acier" and b.id != "mur_cristal" and not d.get("wall", false):
			rows.append(["Consomme", "0 énergie"])
		rows.append(["Vision", "%d cases" % b.vision])
		if b.offline:
			rows.append(["État", "HORS TENSION"])
		var y := 152.0
		for r in rows:
			y += _row(34, y, r[0], r[1], GameData.RED if r[0] == "État" else UiStyle.TEXT)
		if mine and GameData.can_upgrade(b.id):
			UiStyle.section(self, Vector2(COL2, 128), 340, "NIVEAU SUIVANT" if b.level < GameData.MAX_LEVEL else "ÉVOLUTION", UiStyle.GOLD)
			if b.level < GameData.MAX_LEVEL:
				var yy := 154.0
				var up_txt: String = String(GameData.UPGRADES.get(b.id, ""))
				if up_txt == "":
					up_txt = "+40 % PV" + (", +25 % de dégâts" if b.weapon != "" else "")
				var parts: Array = Array(up_txt.split(", "))
				var dp := GameData.power_at(b.id, b.level + 1) - GameData.power_at(b.id, b.level)
				if dp < 0:
					parts.append("consomme %d énergie de plus" % -dp)
				for part in parts:
					yy = UiStyle.para(self, Vector2(COL2, yy), "◆ " + part, 13,
							GameData.AMBER if String(part).begins_with("consomme") else UiStyle.TEXT, 340.0, 17.0) + 3.0
				var why: String = game.upgrade_block(b, game.ore)
				if why != "":
					UiStyle.para(self, Vector2(COL2, maxf(yy, 214.0)), why, 13, GameData.RED, 340.0, 16.0)
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
		var avail_w := size.x - 14.0 - gw
		while fs > 11 and tw > avail_w:
			fs -= 1
			tw = UiStyle.text_width(text, fs, true)
		# Toujours trop long : retour à la ligne (2 lignes max.) plutôt que de déborder du bouton
		var lines: Array = [text]
		if tw > avail_w:
			lines = UiStyle.wrap_lines(text, fs, avail_w, true)
			if lines.size() > 2:
				lines = [lines[0], String(" ".join(PackedStringArray(lines.slice(1))))]
			fs = 10
			while fs > 8 and lines.any(func(l) -> bool: return UiStyle.text_width(String(l), fs, true) > avail_w):
				fs -= 1
		var wmax := 0.0
		for l in lines:
			wmax = maxf(wmax, UiStyle.text_width(String(l), fs, true))
		var x0 := (size.x - wmax - gw) * 0.5
		if glyph != "":
			UiStyle.glyph(self, glyph, Vector2(x0 + 8, size.y * 0.5), 12.0, col if enabled else tc)
		for i in lines.size():
			var ly := size.y * 0.5 + 5.0 + (i - (lines.size() - 1) * 0.5) * (fs + 3.0)
			var lw := UiStyle.text_width(String(lines[i]), fs, true)
			UiStyle.text(self, Vector2(x0 + gw + (wmax - lw) * 0.5, ly), String(lines[i]), fs, tc, true)


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
		var tip := "%s — %s" % [GameData.name_of(id, game.faction_id), game.cost_label(id)]
		if not GameData.UNITS.has(id) and not d.get("wall", false):
			var pw: int = int(d.get("power", 0))
			tip += "\nÉnergie : " + ("produit +%d" % pw if pw > 0 else ("consomme %d" % -pw if pw < 0 else "aucune consommation"))
			var up := GameData.upgrade_power(id)
			if up > 0 and GameData.can_upgrade(id):
				tip += " (+%d par niveau)" % up
		if GameData.desc_of(id, game.faction_id) != "":
			tip += "\n" + GameData.desc_of(id, game.faction_id)
		var names := GameData.req_names(d)
		if not names.is_empty():
			tip += "\nNécessite : " + ", ".join(names)
		tooltip_text = UiStyle.wrap_text(tip, 14, 360.0)
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

	## Mention orange sous l'icône : à la ligne (2 lignes max.) dans la largeur de la carte.
	func _card_note(s: String, fs: int) -> void:
		var wl := UiStyle.wrap_lines(s, fs, size.x - 16.0, true)
		var n := mini(wl.size(), 2)
		var y0 := 84.0 - (n - 1) * 6.0
		for i in n:
			UiStyle.text(self, Vector2(0, y0 + i * 13.0), String(wl[i]), fs, GameData.AMBER, true,
					HORIZONTAL_ALIGNMENT_CENTER, size.x)

	func _draw() -> void:
		var d := GameData.def(id)
		var p: Dictionary = game.production_for(id)
		var ready: bool = (not p.is_empty()) and bool(p["ready"])
		var avail: bool = game.is_available(id) or ready
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
		if game.unit_level_block(id) != "" and (GameData.UNITS.has(id) or game.is_unlocked(id)):
			_card_note(String(game.unit_level_block(id)).to_upper(), 11)
		elif GameData.UNITS.has(id) and not avail:
			_card_note("BÂTIMENT REQUIS", 11)
		if not GameData.UNITS.has(id) and not game.is_unlocked(id):
			var lock_s := "CHANTIER NIV. %d" % game.chantier_needed(id) if game.mission.is_empty() \
					else "MISSION %d" % Campaign.mission_for_unlock(game.faction_id, int(d.get("unlock", 0)))
			_card_note(lock_s, 12)
		elif d.has("faction") and not GameData.UNITS.has(id):
			UiStyle.text(self, Vector2(12, 24), "FACTION", 10, game.fdata["color"] * 1.5, true)
		if not GameData.UNITS.has(id) and game.is_unlocked(id) and not d.get("wall", false):
			var pw: int = int(d.get("power", 0))
			var pc := GameData.GREEN if pw > 0 else (GameData.AMBER if pw < 0 else UiStyle.TEXT_DIM)
			if not avail:
				pc = Color(0.4, 0.35, 0.3)
			var pt := ("+%d" % pw) if pw > 0 else str(pw)
			var py := 50.0 if game.queued_count(id) > 0 else 28.0
			var pwid := UiStyle.text_width(pt, 12, true)
			UiStyle.text(self, Vector2(size.x - 12.0 - pwid, py), pt, 12, pc, true)
			UiStyle.glyph(self, "power", Vector2(size.x - 20.0 - pwid, py - 4.0), 9.0, pc)
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
		var nm := GameData.name_of(id, game.faction_id).to_upper()
		var nsz := 12
		while nsz > 8 and UiStyle.text_width(nm, nsz, true) > size.x - 6.0:
			nsz -= 1 # les noms longs rétrécissent pour tenir dans la carte
		UiStyle.text(self, Vector2(0, 104), nm, nsz, tc, true, HORIZONTAL_ALIGNMENT_CENTER, size.x)
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
			if is_unit:
				# Unité : Solaris + un peu de minerai, chacun en rouge s'il manque
				var ou: int = game.item_ore(id)
				var c_sol := cc if (not avail or game.credits >= game.item_cost(id) * 0.1) else GameData.RED
				var c_ore := GameData.ORE_BLUE if game.ore >= ou * 0.1 else GameData.RED
				if not avail:
					c_ore = cc
				var w1 := UiStyle.text_width(label, 13)
				var w2 := UiStyle.text_width(str(ou), 13)
				var x1 := (size.x - (w1 + w2 + 42.0)) * 0.5
				UiStyle.glyph(self, "credit", Vector2(x1 + 6, 118), 10.0, c_sol)
				UiStyle.text(self, Vector2(x1 + 17, 123), label, 13, c_sol)
				var x2 := x1 + 17.0 + w1 + 8.0
				UiStyle.glyph(self, "ore", Vector2(x2 + 6, 118), 10.0, c_ore)
				UiStyle.text(self, Vector2(x2 + 17, 123), str(ou), 13, c_ore)
			else:
				# Bâtiment : minerai + Solaris, chacun en rouge s'il manque
				var sol := GameData.sol_cost(id)
				var c_ore := cc if (not avail or game.ore >= game.item_cost(id)) else GameData.RED
				var c_sol := GameData.GOLD if game.credits >= sol else GameData.RED
				if not avail:
					c_sol = cc
				var w1 := UiStyle.text_width(label, 13)
				var w2 := UiStyle.text_width(str(sol), 13)
				var x1 := (size.x - (w1 + w2 + 42.0)) * 0.5
				UiStyle.glyph(self, "ore", Vector2(x1 + 6, 118), 10.0, c_ore)
				UiStyle.text(self, Vector2(x1 + 17, 123), label, 13, c_ore)
				var x2 := x1 + 17.0 + w1 + 8.0
				UiStyle.glyph(self, "credit", Vector2(x2 + 6, 118), 10.0, c_sol)
				UiStyle.text(self, Vector2(x2 + 17, 123), str(sol), 13, c_sol)

	## Bâtiments débloqués : on affiche le modèle 3D cuit (ou un bloc simple sans affichage).
	func _draw_baked_icon(c: Vector2, avail: bool) -> void:
		var key := "%s|%s" % [id, game.faction_id]
		var is_unit := GameData.UNITS.has(id)
		var ang := 0.45 if is_unit else 0.0
		var tex = game.bank.frame(key, ang)
		if tex == null:
			return
		var src: Rect2 = game.bank.used_rect(key, ang)
		if src.size.x < 2.0 or src.size.y < 2.0:
			src = Rect2(Vector2.ZERO, tex.get_size())
		# On cadre sur la partie réellement dessinée du modèle, pour qu'elle remplisse l'icône
		var k := minf(minf(92.0 / src.size.x, 66.0 / src.size.y), 2.4)
		var dsz := src.size * k
		var col := Color.WHITE if avail else Color(0.5, 0.5, 0.56, 0.85)
		var cc := c + Vector2(0, 2)
		draw_texture_rect_region(tex, Rect2(cc - dsz / 2.0, dsz), src, col)
		# Tête de tourelle / antenne : cuite à part, elle se superpose au socle comme sur la carte
		if is_unit:
			return
		var d := GameData.def(id)
		var hk := ""
		if id == "radar":
			hk = "radar_tete|%s" % game.faction_id
		elif d.has("weapon") and not d.get("wall", false):
			hk = "%s_tete|%s" % [id, game.faction_id]
			if not game.bank.has(hk):
				hk = "tourelle_tete|%s" % game.faction_id
		if hk != "" and game.bank.has(hk):
			var ha := 0.45
			var ht = game.bank.frame(hk, ha)
			if ht != null:
				var wk: float = k * tex.get_size().x / maxf(game.bank.draw_size(key).x, 1.0)
				var hsz: Vector2 = game.bank.draw_size(hk) * wk
				var tc: Vector2 = cc + (tex.get_size() * 0.5 - (src.position + src.size * 0.5)) * k
				draw_texture_rect(ht, Rect2(tc - hsz / 2.0, hsz), false, col)

	func _draw_icon(c: Vector2, avail: bool) -> void:
		var fill := Color("2a3350") if avail else Color("201c2c")
		var line: Color = game.fdata["color"] * 1.6 if avail else Color(0.4, 0.35, 0.5)
		line.a = 1.0
		var role: String = GameData.def(id).get("role", "")
		if game.bank != null and game.bank.has("%s|%s" % [id, game.faction_id]):
			_draw_baked_icon(c, avail)
			return
		if GameData.def(id).get("wall", false):
			var wc := GameData.wall_color(id, game.faction_id)
			if not avail:
				wc = wc.darkened(0.4)
			for i in 3:
				var r := Rect2(c + Vector2(-33 + i * 22, -11), Vector2(22, 22))
				draw_rect(r, wc.darkened(0.3))
				draw_rect(Rect2(r.position, r.size - Vector2(0, 4)), wc)
				draw_rect(r, Color(0, 0, 0, 0.4), false, 1.0)
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
