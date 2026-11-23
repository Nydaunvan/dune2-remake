class_name GameUI
extends CanvasLayer
## Interface moderne : barre de ressources, panneau latéral en verre dépoli
## (radar, commandes, construction), notifications animées.

const MARGIN := 12.0
const TOPBAR_H := 96.0
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
var radar_panel: Control
var sel_frame: Control
var log_panel: GlassPanel
var topbar: HudBar
var radar: Radar
var info_label: Label
var info_panel: InfoPanel
var icon_box: GridContainer
var icon_scroll: ScrollContainer
var icons: Array = []
var tab_buttons: Array = []
var queue_panel: QueuePanel


func setup(p_game) -> void:
	game = p_game
	UiSkin.use(game.faction_id)
	UiStyle._theme = null
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.theme()
	add_child(root)
	_build_topbar()
	_build_objective()
	_build_sidebar()
	_rebuild_icons()
	_build_selection()


func is_mouse_over_ui() -> bool:
	var m := get_viewport().get_mouse_position()
	return sidebar.get_global_rect().has_point(m) or topbar.get_global_rect().has_point(m) \
			or radar_panel.get_global_rect().has_point(m) \
			or (log_panel != null and log_panel.get_global_rect().has_point(m)) \
			or (sel_frame != null and sel_frame.visible and sel_frame.get_global_rect().has_point(m))


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
	var sb: StyleBox
	if color.r > 0.8 and color.g < 0.55:
		sb = UiSkin.flat_box(GameData.RED, Color(0.14, 0.02, 0.02, 0.8))
	else:
		sb = UiSkin.flat_box(UiSkin.accent, Color(0.04, 0.035, 0.05, 0.7))
	(sb as StyleBoxFlat).content_margin_left = 24
	(sb as StyleBoxFlat).content_margin_right = 24
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = -330.0
	l.offset_right = 330.0
	l.offset_top = 130.0
	l.offset_bottom = 170.0 + extra
	root.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "offset_top", 100.0, 2.2).from(130.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "offset_bottom", 140.0 + extra, 2.2).from(170.0 + extra).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(1.8)
	tw.chain().tween_callback(l.queue_free)


# --- Construction de l'interface ---------------------------------------------

var objective_panel: ObjectivePanel
var event_log: EventLog


func _build_objective() -> void:
	objective_panel = ObjectivePanel.new(game)
	objective_panel.position = Vector2(MARGIN, TOPBAR_H + 6.0)
	root.add_child(objective_panel)


func toggle_objectives() -> void:
	objective_panel.visible = not objective_panel.visible
	if objective_panel.visible:
		objective_panel.pulse = 1.0


func _build_topbar() -> void:
	topbar = HudBar.new()
	topbar.game = game
	topbar.position = Vector2(MARGIN, 2.0)
	topbar.size = Vector2(1400.0, TOPBAR_H)
	root.add_child(topbar)
	var x := HudBar.BAR_W + 16.0
	for def in [["Guide", func() -> void: Guide.open(game, game.faction_id)], ["Objectifs", toggle_objectives], ["Menu", game.open_pause_menu]]:
		var fb := FlatButton.new(def[0])
		fb.position = Vector2(x, 22)
		fb.size = Vector2(150, 56)
		fb.pressed.connect(def[1])
		topbar.add_child(fb)
		x += 156.0


func _build_sidebar() -> void:
	sidebar = GlassPanel.new(0.0, 4.0)
	sidebar.set_skin("panneau_construction")
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_top = 0.0
	sidebar.anchor_bottom = 1.0
	var vh := maxf(root.get_viewport_rect().size.y, 1080.0)
	sidebar_w = minf(vh * UiSkin.aspect("panneau_construction"), 560.0)
	sidebar.offset_left = -sidebar_w
	sidebar.offset_right = 0.0
	root.add_child(sidebar)
	var inn := UiSkin.inner("panneau_construction", Rect2(0, 0, sidebar_w, vh)).grow_individual(sidebar_w * 0.03, 0.0, sidebar_w * 0.03, 0.0)

	# En-tête de faction : dans la partie haute ornée du panneau
	var hh := minf(inn.position.y - 18.0, 230.0)
	var hw := minf(hh * UiSkin.aspect("entete_faction"), inn.size.x + 60.0)
	hh = hw / UiSkin.aspect("entete_faction")
	var header := SideHeader.new(game)
	header.position = Vector2(inn.get_center().x - hw * 0.5, 10.0 + (inn.position.y - 18.0 - hh) * 0.5)
	header.size = Vector2(hw, hh)
	sidebar.add_child(header)

	# Radar : cadre du kit en bas à gauche, carte dans sa zone intérieure
	radar_w = 260.0
	var rh := radar_w / UiSkin.aspect("radar")
	radar_panel = ArtFrame.new("radar")
	radar_panel.anchor_top = 1.0
	radar_panel.anchor_bottom = 1.0
	radar_panel.offset_left = 6.0
	radar_panel.offset_right = 6.0 + radar_w
	radar_panel.offset_top = -rh - 6.0
	radar_panel.offset_bottom = -6.0
	root.add_child(radar_panel)
	var ri := UiSkin.inner("radar", Rect2(Vector2.ZERO, Vector2(radar_w, rh)))
	radar = Radar.new()
	radar.game = game
	radar.world_size = game.world_size
	radar.square = UiSkin.shape("radar") == "square"
	radar.position = ri.position
	radar.size = ri.size
	radar_panel.add_child(radar)

	if not _solis_compact():
		_build_log()

	# Onglets
	var tabs := [["building", "BÂTIMENTS"], ["unit", "UNITÉS"]]
	var tw := (inn.size.x - 6.0) / 2.0
	for i in tabs.size():
		var t := NeonButton.new(tabs[i][1])
		t.style = "tab"
		t.active = (i == 0)
		t.position = Vector2(inn.position.x + i * (tw + 6.0), inn.position.y)
		t.size = Vector2(tw, tw / UiSkin.aspect("onglet_actif"))
		t.pressed.connect(_set_category.bind(tabs[i][0]))
		sidebar.add_child(t)
		tab_buttons.append(t)

	# Cartes de production : deux colonnes, réduites pour tenir dans la colonne
	card_cols = 1 # une seule colonne verticale de cartes (image seule)
	var _scroll_h := inn.size.y - tw / UiSkin.aspect("onglet_actif") - 6.0 - 136.0
	card_slot_w = minf(inn.size.x - 8.0, _scroll_h / 2.6 * UiSkin.aspect("vignette_normal")) # ~2,6 cartes visibles
	card_scale = 1.0
	UiSkin.card_w = card_slot_w
	icon_box = GridContainer.new()
	icon_box.columns = card_cols
	icon_box.add_theme_constant_override("h_separation", 6)
	icon_box.add_theme_constant_override("v_separation", 6)
	icon_scroll = ScrollContainer.new()
	icon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var tab_h := tw / UiSkin.aspect("onglet_actif")
	icon_scroll.position = Vector2(inn.position.x, inn.position.y + tab_h + 6.0)
	icon_scroll.size = Vector2(inn.size.x, inn.size.y - tab_h - 6.0 - 136.0)
	icon_scroll.clip_contents = true
	sidebar.add_child(icon_scroll)
	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size.x = inn.size.x
	icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_scroll.add_child(icon_center)
	icon_center.add_child(icon_box)

	# Infos en bas de la colonne
	info_label = Label.new()
	info_label.add_theme_font_override("font", UiStyle.body_font())
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", UiStyle.TEXT)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.position = Vector2(inn.position.x, inn.end.y - 28.0)
	info_label.size = Vector2(inn.size.x, 28.0)
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sidebar.add_child(info_label)
	queue_panel = QueuePanel.new(game)
	queue_panel.position = Vector2(inn.position.x, inn.end.y - 132.0)
	queue_panel.size = Vector2(inn.size.x, 102.0)
	sidebar.add_child(queue_panel)


var card_scale := 0.85
var sidebar_w := 540.0
var card_cols := 1
var card_slot_w := 160.0
var radar_w := 340.0


## Solis et Kharn : les objectifs prennent le cadre du journal, qui disparaît ; carte plus petite.
func _solis_compact() -> bool:
	return true


func _build_log() -> void:
	log_panel = GlassPanel.new(0.0, 4.0)
	log_panel.set_skin("panneau_journal")
	log_panel.position = Vector2(MARGIN, 200)
	log_panel.size = UiSkin.outer_for("panneau_journal", Vector2(330, 118))
	root.add_child(log_panel)
	var li := UiSkin.inner("panneau_journal", Rect2(Vector2.ZERO, log_panel.size))
	event_log = EventLog.new()
	event_log.position = li.position
	event_log.size = li.size
	log_panel.add_child(event_log)
	log_panel.visible = false # encart « journal » supprimé de l'interface (le flux d'événements reste alimenté)


## Cadre de sélection : bandeau du kit en bas, avec emplacement de portrait intégré.
func _build_selection() -> void:
	var x0 := radar_w + 14.0
	var fw := 1920.0 - sidebar_w - 8.0 - x0
	fw *= 1.0 # cadre réduit, proportions d'origine
	var fh := fw / UiSkin.aspect("panneau_selection")
	sel_frame = ArtFrame.new("panneau_selection")
	sel_frame.anchor_top = 1.0
	sel_frame.anchor_bottom = 1.0
	sel_frame.offset_left = x0
	sel_frame.offset_right = x0 + fw
	sel_frame.offset_top = -fh - 4.0
	sel_frame.offset_bottom = -4.0
	root.add_child(sel_frame)
	var ph := UiSkin.inner("selection_portrait", Rect2(Vector2.ZERO, Vector2(fw, fh)))
	var ps := minf(ph.size.x, ph.size.y) * 1.2
	var portrait := Portrait.new(game)
	portrait.size = Vector2(ps, ps)
	portrait.position = ph.get_center() - Vector2(ps, ps) * 0.5
	portrait.fit = Vector2(ps, ps) * 0.8
	sel_frame.add_child(portrait)
	var inn := UiSkin.inner("panneau_selection", Rect2(Vector2.ZERO, Vector2(fw, fh))).grow_individual(fh * 0.0, fh * 0.05, fh * 0.02, fh * 0.03)
	info_panel = InfoPanel.new(game)
	info_panel.portrait = portrait
	info_panel.frame = sel_frame
	var k := inn.size.y / 190.0
	var wl := inn.size.x / k
	if wl < 880.0:
		wl = 880.0
		k = inn.size.x / wl
	info_panel.size = Vector2(wl, 190.0)
	info_panel.W3 = wl - InfoPanel.COL2 - 14.0
	info_panel.scale = Vector2(k, k)
	info_panel.position = inn.position + (inn.size - info_panel.size * k) * 0.5
	sel_frame.add_child(info_panel)
	sel_frame.visible = false


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
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_box.add_child(icon)
		icons.append(icon)


func _process(_delta: float) -> void:
	if game == null:
		return
	if log_panel != null:
		log_panel.position.y = objective_panel.position.y + (objective_panel.size.y + 6.0 if objective_panel.visible else 0.0)
	if game.placing_id != "":
		info_label.text = "Clic gauche : poser le bâtiment\nClic droit ou Échap : annuler"
	elif game.command_mode == "move":
		info_label.text = "Cliquez sur la carte pour déplacer les unités sélectionnées."
	elif game.command_mode == "attack":
		info_label.text = "Cliquez : les unités avancent en attaquant tout sur leur route."
	else:
		var cap: int = game.army_cap()
		info_label.text = "Clic droit : annuler — Échap pause — O objectifs%s" \
				% [(" — armée %d/%d" % [game.army_count(), cap]) if cap > 0 else ""]


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

class ArtFrame extends Control:
	## Cadre illustré du kit de faction, étiré sur tout le contrôle ; le contenu s'ajoute en enfants.
	var art := ""

	func _init(p_art: String) -> void:
		art = p_art
		mouse_filter = Control.MOUSE_FILTER_STOP
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	func _draw() -> void:
		UiSkin.panel(self, art, Rect2(Vector2.ZERO, size))


class EventLog extends Control:
	## Derniers messages du jeu (les notifications à l'écran disparaissent vite).
	const MAX := 5
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
		var dm := Vector2(8, 11)
		_diamond(dm, 5.0, UiSkin.accent)
		UiStyle.text(self, Vector2(22, 17), "JOURNAL", 15, UiSkin.accent, true)
		var now := Time.get_ticks_msec() / 1000.0
		var y := 40.0
		var left := 5 # lignes disponibles
		for l in lines:
			if left <= 0:
				break
			var age := now - float(l[2])
			var c: Color = l[1]
			c.a = clampf(1.0 - age / 90.0, 0.4, 1.0)
			var wl := UiStyle.wrap_lines(String(l[0]), 12, size.x - 12.0)
			for i in mini(wl.size(), mini(2, left)):
				UiStyle.text(self, Vector2(0 if i == 0 else 10, y), String(wl[i]), 12, c)
				y += 14.0
				left -= 1
			y += 1.0
		if lines.is_empty():
			UiStyle.text(self, Vector2(0, y), "Aucun événement", 12, UiStyle.TEXT_DIM)

	func _diamond(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), col, 2.0, true)


class ObjectivePanel extends Control:
	var ART := "panneau_objectifs"
	const CW := 300.0 # largeur de contenu
	var game
	var pulse := 0.0
	var _off := Vector2.ZERO

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
		game = p_game
		ART = "panneau_journal"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	func _text_lines(o: Dictionary) -> Array:
		return UiStyle.wrap_lines(String(o["text"]), 14, CW - 30.0)

	func _process(_delta: float) -> void:
		var h := 30.0
		for o in _items():
			h += 38.0 + 17.0 * (_text_lines(o).size() - 1)
		size = UiSkin.outer_for(ART, Vector2(CW, maxf(h, 70.0)))
		_off = UiSkin.inner(ART, Rect2(Vector2.ZERO, size)).position
		pulse = move_toward(pulse, 0.0, _delta * 1.5)
		queue_redraw()

	func _diamond(c: Vector2, r: float, col: Color, filled: bool) -> void:
		if UiSkin.tex("icone_objectif") != null:
			UiSkin.image(self, "icone_objectif", Rect2(c - Vector2(r, r) * 1.5, Vector2(r, r) * 3.0), Color(0.55, 1.0, 0.7) if filled else Color.WHITE)
			return
		var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		if filled:
			draw_colored_polygon(pts, col)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), col, 2.0, true)

	func _draw() -> void:
		UiSkin.panel(self, ART, Rect2(Vector2.ZERO, size))
		draw_set_transform(_off, 0.0, Vector2.ONE)
		var m: Dictionary = game.mission
		var head := "OBJECTIFS"
		if not m.is_empty():
			head = "MISSION %d — %s" % [GameSession.mission + 1, String(m["title"]).to_upper()]
		if pulse > 0.0:
			draw_rect(Rect2(Vector2(-4, -4), size - _off * 2.0 + Vector2(8, 8)), Color(1.0, 0.8, 0.3, 0.14 * pulse))
		var hs := 16
		while hs > 11 and UiStyle.text_width(head, hs, true) > CW - 26.0:
			hs -= 1
		_diamond(Vector2(8, 11), 5.0, UiSkin.accent, false)
		UiStyle.text(self, Vector2(24, 17), head, hs, UiSkin.accent, true)
		var y := 40.0
		for o in _items():
			var done: bool = o["done"]
			var col := GameData.GREEN if done else UiStyle.GOLD
			_diamond(Vector2(8, y - 4.0), 4.0, col, done)
			var yt := y
			for ln in _text_lines(o):
				UiStyle.text(self, Vector2(24, yt), String(ln), 14, UiStyle.TEXT if not done else GameData.GREEN)
				yt += 17.0
			yt -= 17.0
			UiSkin.bar(self, Rect2(24, yt + 5.0, CW - 30.0, 10), float(o["frac"]))
			y = yt + 38.0


# --- File de production ---------------------------------------------------------

class QueuePanel extends Control:
	var game

	func _init(p_game) -> void:
		game = p_game
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var cat: String = game.ui.category
		var q: Array = game.production[cat]
		var cap: int = game.queue_max(cat)
		UiStyle.text(self, Vector2(4, 16), "FILE DE PRODUCTION", 14, UiSkin.accent, true)
		var cnt := "%d/%d" % [q.size(), cap]
		UiStyle.text(self, Vector2(size.x - 4.0 - UiStyle.text_width(cnt, 13, true), 16), cnt, 13, UiStyle.TEXT_DIM, true)
		var n := clampi(cap, 1, 8)
		var gap := 4.0
		var w := minf(66.0, (size.x - gap * (n - 1)) / n)
		var x0 := (size.x - (w * n + gap * (n - 1))) * 0.5
		for i in n:
			var r := Rect2(x0 + i * (w + gap), 28, w, w / UiSkin.aspect("slot_production"))
			UiSkin.panel(self, "slot_production", r)
			if i < q.size():
				var it: Dictionary = q[i]
				var key := "%s|%s" % [it["id"], game.faction_id]
				if game.bank != null and game.bank.has(key):
					var tex = game.bank.frame(key, 0.45 if GameData.UNITS.has(it["id"]) else 0.0)
					if tex != null:
						var src: Rect2 = game.bank.used_rect(key, 0.45 if GameData.UNITS.has(it["id"]) else 0.0)
						if src.size.x < 2.0:
							src = Rect2(Vector2.ZERO, tex.get_size())
						var k := minf((r.size.x * 0.56) / src.size.x, (r.size.y * 0.5) / src.size.y)
						var dsz := src.size * k
						draw_texture_rect_region(tex, Rect2(r.get_center() + Vector2(0, r.size.y * 0.06) - dsz / 2.0, dsz), src)
				if i == 0:
					if bool(it["ready"]):
						UiStyle.text(self, Vector2(r.position.x, r.end.y - 9.0), "PRÊT", 11, Color("6fe0a0"), true,
								HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
					else:
						UiSkin.bar(self, Rect2(r.position.x + r.size.x * 0.18, r.end.y - r.size.y * 0.27, r.size.x * 0.64, 9.0), float(it["progress"]))


class TipCard extends Control:
	const W := 300.0
	var rows: Array = [] # [kind, ...]
	var h := 0.0

	func _init(p_id: String, game) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var d := GameData.def(p_id)
		var is_unit := GameData.UNITS.has(p_id)
		rows.append(["title", GameData.name_of(p_id, game.faction_id)])
		var first: int = game.item_cost(p_id)
		var second: int = game.item_ore(p_id) if is_unit else GameData.sol_cost(p_id)
		rows.append(["cost", "icone_epice" if is_unit else "icone_minerai", str(first), "icone_minerai" if is_unit else "icone_epice", str(second)])
		if not is_unit and not d.get("wall", false):
			var pw: int = int(d.get("power", 0))
			var txt := "Produit +%d" % pw if pw > 0 else ("Consomme %d" % -pw if pw < 0 else "Aucune consommation")
			var up := GameData.upgrade_power(p_id)
			if up > 0 and GameData.can_upgrade(p_id):
				txt += "  (+%d par niveau)" % up
			rows.append(["power", txt, pw])
		var ds := GameData.desc_of(p_id, game.faction_id)
		if ds != "":
			for l in UiStyle.wrap_lines(ds, 14, W - 28.0):
				rows.append(["text", String(l), UiStyle.TEXT_DIM])
		var names := GameData.req_names(d)
		if not names.is_empty():
			for l in UiStyle.wrap_lines("Nécessite : " + ", ".join(names), 14, W - 28.0):
				rows.append(["text", String(l), GameData.AMBER])
		var warn := ""
		if not is_unit and not game.is_unlocked(p_id):
			warn = "Verrouillé : " + ("chantier niv. %d" % game.chantier_needed(p_id) if game.mission.is_empty() \
					else "mission %d" % Campaign.mission_for_unlock(game.faction_id, int(d.get("unlock", 0))))
		elif String(game.unit_level_block(p_id)) != "":
			warn = String(game.unit_level_block(p_id))
		elif not is_unit and game.power_block(p_id) != "":
			warn = "Énergie insuffisante"
		if warn != "":
			rows.append(["text", warn, GameData.RED])
		h = 18.0
		for r in rows:
			h += {"title": 30.0, "cost": 32.0, "power": 26.0}.get(String(r[0]), 19.0)
		h += 10.0
		custom_minimum_size = Vector2(W, h)
		size = custom_minimum_size

	func _draw() -> void:
		var acc: Color = UiSkin.accent
		draw_rect(Rect2(0, 0, size.x, 3.0), Color(acc.r, acc.g, acc.b, 0.85))
		var y := 18.0
		for row in rows:
			match String(row[0]):
				"title":
					UiStyle.text_o(self, Vector2(14, y + 18.0), String(row[1]), 20, acc, true)
					draw_line(Vector2(14, y + 25.0), Vector2(W - 14.0, y + 25.0), Color(acc.r, acc.g, acc.b, 0.45), 1.0)
					y += 30.0
				"cost":
					UiSkin.image(self, String(row[1]), Rect2(14, y, 24, 24))
					UiStyle.text_o(self, Vector2(44, y + 19.0), String(row[2]), 19, Color.WHITE, true)
					UiSkin.image(self, String(row[3]), Rect2(W * 0.5, y, 24, 24))
					UiStyle.text_o(self, Vector2(W * 0.5 + 30.0, y + 19.0), String(row[4]), 19, Color.WHITE, true)
					y += 32.0
				"power":
					var pw: int = int(row[2])
					var pc := Color("6fe0a0") if pw > 0 else (GameData.AMBER if pw < 0 else UiStyle.TEXT_DIM)
					UiSkin.image(self, "icone_energie", Rect2(14, y, 22, 22))
					UiStyle.text_o(self, Vector2(42, y + 17.0), String(row[1]), 16, pc, true)
					y += 26.0
				_:
					UiStyle.text_o(self, Vector2(14, y + 14.0), String(row[1]), 14, row[2])
					y += 19.0


# --- Barre de ressources ------------------------------------------------------

class HudBar extends Control:
	var game
	var shown_credits := 0.0
	var shown_ore := 0.0
	var shown_load := 0.0
	var _init_done := false
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

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

	## Cellule de ressource : icône, valeur, plafond et jauge fine.
	func _resource(x: float, w: float, value: String, vcol: Color, icon: String, cap: int, amount: int, gcol: Color) -> void:
		UiSkin.image(self, icon, Rect2(x + 18, 14, 34, 34))
		_tx(Vector2(x + 64, 38), value, 26, vcol, true)
		var vw := UiStyle.text_width(value, 26, true)
		_tx(Vector2(x + 64 + vw + 8, 38), "/ %d" % cap, 15, UiStyle.TEXT_DIM)
		var fill := clampf(float(amount) / float(maxi(cap, 1)), 0.0, 1.0)
		var bc := GameData.RED if fill > 0.95 else (GameData.AMBER if fill > 0.8 else gcol)
		UiStyle.seg_bar(self, Rect2(x + 64, 47, w - 90.0, 4), fill, bc)

	func _slash(x: float) -> void:
		draw_line(Vector2(x + 8, 50), Vector2(x - 8, 14), Color(0.85, 0.66, 0.42, 0.55), 2.0, true)

	const BAR_W := 880.0

	## Cellule : icône, valeur, plafond et jauge fine, dans la bande intérieure du bandeau.
	func _cell(x: float, w: float, value: String, vcol: Color, icon: String, cap: int, amount: int, gcol: Color) -> void:
		var ty := 70.0
		UiSkin.image(self, icon, Rect2(x, ty - 24.0, 28, 28))
		_tx(Vector2(x + 34, ty), value, 22, vcol, true)
		var vw := UiStyle.text_width(value, 22, true)
		_tx(Vector2(x + 34 + vw + 6, ty), "/ %d" % cap, 13, UiStyle.TEXT_DIM)
		var fill := clampf(float(amount) / float(maxi(cap, 1)), 0.0, 1.0)
		var bc := GameData.RED if fill > 0.95 else (GameData.AMBER if fill > 0.8 else gcol)
		UiStyle.seg_bar(self, Rect2(x + 34, ty + 5, w - 44.0, 3), fill, bc)

	func _draw() -> void:
		if game == null:
			return
		UiSkin.band(self, "barre_ressources", Rect2(0, 0, BAR_W, TOPBAR_H))
		var inn := UiSkin.inner("barre_ressources", Rect2(0, 0, BAR_W, TOPBAR_H))
		var x0 := inn.get_center().x - 378.0 # contenu (~756 px) centré dans le bandeau
		# Solaris : le compteur glisse vers la valeur réelle et clignote vert/rouge
		var diff: float = float(game.credits) - shown_credits
		var col := Color.WHITE
		if absf(diff) > 1.0:
			var k := clampf(absf(diff) / 200.0, 0.0, 1.0)
			col = Color.WHITE.lerp(Color("5dff9a") if diff > 0.0 else Color("ff5a4a"), k)
		_cell(x0, 180, str(int(round(shown_credits))), col, "icone_epice",
				game.storage_cap("spice"), game.credits, UiStyle.GOLD)
		_cell(x0 + 185, 180, str(int(round(shown_ore))), Color.WHITE, "icone_minerai",
				game.storage_cap("ore"), game.ore, Color("8fb2e8"))
		# Énergie : consommation / production, vert = large marge, rouge = seuil critique
		var prod: int = game.power_produced()
		var used: int = game.power_used()
		var ok := prod >= used
		var load_col := Color("6fd69a").lerp(GameData.RED, clampf((shown_load - 0.7) / 0.3, 0.0, 1.0))
		var ex := x0 + 370.0
		UiSkin.image(self, "icone_energie", Rect2(ex, 46, 28, 28))
		_tx(Vector2(ex + 34, 70), "%d" % used, 22, Color.WHITE if ok else GameData.RED, true)
		_tx(Vector2(ex + 34 + UiStyle.text_width("%d" % used, 22, true) + 6, 70), "/ %d" % prod, 13, UiStyle.TEXT_DIM)
		UiStyle.seg_bar(self, Rect2(ex + 34, 75, 130, 3), shown_load, load_col)
		# Temps
		var t: float = game.game_time
		var tx := x0 + 560.0
		UiSkin.image(self, "icone_horloge", Rect2(tx, 46, 26, 26))
		_tx(Vector2(tx + 32, 70), "%02d:%02d:%02d" % [int(t / 3600.0), int(t / 60.0) % 60, int(t) % 60], 20, Color.WHITE, true)
		# Images par seconde
		var fps := int(Engine.get_frames_per_second())
		var fcol := Color("6fd69a") if fps >= 45 else (GameData.AMBER if fps >= 25 else GameData.RED)
		var fx := x0 + 700.0
		_tx(Vector2(fx, 70), "%d" % fps, 20, fcol, true)
		_tx(Vector2(fx + UiStyle.text_width("%d" % fps, 20, true) + 4, 70), "fps", 12, UiStyle.TEXT_DIM)


## Bouton de la barre du haut (textures du skin : normal, survol, pressé).
class FlatButton extends Control:
	signal pressed
	var text := ""
	var _hover := false
	var _down := false

	func _init(p_text: String) -> void:
		text = p_text
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
		mouse_exited.connect(func() -> void: _hover = false; _down = false; queue_redraw())

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_down = event.pressed
			if event.pressed:
				pressed.emit()
			queue_redraw()
			accept_event()

	func _draw() -> void:
		var n := "bouton_presse" if _down else ("bouton_actif" if _hover else "bouton_normal")
		UiSkin.panel(self, n, Rect2(Vector2.ZERO, size))
		UiStyle.text_center(self, UiSkin.inner("bouton_normal", Rect2(Vector2.ZERO, size)), text.to_upper(), 16, Color.WHITE, true)


class SideHeader extends Control:
	var game

	func _init(p_game) -> void:
		game = p_game
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var name_s: String = String(game.fdata["name"]).to_upper()
		UiSkin.panel(self, "entete_faction", Rect2(Vector2.ZERO, size))
		var inn := UiSkin.inner("entete_faction", Rect2(Vector2.ZERO, size))
		var fs := 22
		while fs > 11 and UiStyle.text_width(name_s, fs, true) > inn.size.x:
			fs -= 1
		UiStyle.text_center(self, inn, name_s, fs, UiSkin.accent, true)


# --- Panneau d'informations ---------------------------------------------------

class InfoPanel extends Control:
	const ARMOR := {"light": "Léger", "medium": "Moyen", "heavy": "Lourd", "building": "Structure"}
	const WEAPON := {"autocannon": "Autocanon", "cannon": "Canon", "rocket": "Roquettes",
			"sonic": "Onde sonique", "acid": "Acide", "control": "Contrôle mental", "shard": "Éclats de cristal",
			"mortar": "Mortier", "flame": "Lance-flammes", "plasma": "Plasma", "laser": "Laser"}
	const LX := 14.0
	const RX := 316.0   # colonne des caractéristiques
	const COL2 := 596.0 # colonne des ordres / du rôle
	const CMD := COL2
	var W3 := 270.0
	var portrait: Portrait
	var frame: Control # cadre illustré qui contient le portrait et ce panneau

	var game
	var btn: GameUI.NeonButton
	var rbtn: GameUI.NeonButton
	var dbtn: GameUI.NeonButton
	var cmd_btns: Array = []
	var _confirm_t := 0.0
	var _focus = null

	func _init(p_game) -> void:
		game = p_game
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		size = Vector2(880.0, 190.0) # taille logique : la mise à l'échelle l'ajuste à la zone du cadre
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
		rbtn.glyph = "repair"
		rbtn.position = Vector2(LX, 244)
		rbtn.size = Vector2(262, 36)
		rbtn.pressed.connect(func() -> void:
			if _focus is Building:
				game.toggle_repair(_focus)
			elif _focus is Unit:
				game.repair_unit(_focus))
		add_child(rbtn)
		dbtn = GameUI.NeonButton.new("DÉMOLIR")
		dbtn.accent = GameData.RED
		dbtn.glyph = "demolish"
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
			cb.position = Vector2(CMD + i * 82.0, 14)
			cb.size = Vector2(78, 30)
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
		if frame != null:
			frame.visible = _focus != null
		portrait.set_focus(_focus)
		var is_b: bool = _focus is Building and _focus.team == 0 and GameData.can_upgrade(_focus.id)
		var is_u: bool = _focus is Unit and _focus.team == 0 and GameData.UNIT_TECH.has(_focus.id)
		btn.visible = is_b or is_u
		if is_b:
			var b: Building = _focus
			btn.position = Vector2(COL2, 14)
			btn.size = Vector2(W3, 30)
			rbtn.position = Vector2(LX, 112)
			rbtn.size = Vector2(176, 30)
			dbtn.position = Vector2(LX + 184.0, 112)
			dbtn.size = Vector2(116, 30)
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
			btn.glyph = "cancel" if b.up_left > 0.0 else "upgrade"
			btn.tooltip_text = why
		elif is_u:
			var u: Unit = _focus
			btn.position = Vector2(COL2, 50)
			btn.size = Vector2(W3, 30)
			rbtn.position = Vector2(LX, 112)
			rbtn.size = Vector2(300, 30)
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
			btn.glyph = "cancel" if u.tech_left > 0.0 else "upgrade"
			btn.tooltip_text = why2
		_update_commands()
		if _focus is Building:
			rbtn.position = Vector2(LX, 112)
			rbtn.size = Vector2(176, 30)
			dbtn.position = Vector2(LX + 184.0, 112)
			dbtn.size = Vector2(116, 30)
		elif _focus is Unit:
			rbtn.position = Vector2(LX, 112)
			rbtn.size = Vector2(300, 30)
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
				rbtn.glyph = "repair"
				rbtn.tooltip_text = game.repair_block(rb)
			else:
				var ru: Unit = _focus
				rbtn.enabled = game.unit_repair_block(ru) == ""
				rbtn.text = "RÉPARATION EN COURS" if ru.state == "repair" else "RÉPARER — %d SOL." % game.unit_repair_cost(ru)
				rbtn.glyph = "repair"
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
		var x := CMD
		for i in cmd_btns.size():
			cmd_btns[i].visible = vis[i]
			if vis[i]:
				cmd_btns[i].position = Vector2(x, 14)
				x += 82.0
		if show:
			cmd_btns[1].active = game.command_mode == "move"
			cmd_btns[2].active = game.command_mode == "attack"

	## Ligne « LIBELLÉ  valeur » ; la valeur passe à la ligne si elle déborde. Renvoie la hauteur utilisée.
	func _row(x: float, y: float, label: String, value: String, vcol := UiStyle.TEXT) -> float:
		UiStyle.text_o(self, Vector2(x, y), label.to_upper(), 12, UiStyle.TEXT_DIM, true)
		var yn := UiStyle.para(self, Vector2(x + 104, y), value, 16, vcol, COL2 - x - 104.0 - 12.0, 19.0)
		return maxf(23.0, yn - y + 4.0)

	## Texte de la 2e colonne, à la ligne dans 340 px. Renvoie la ligne de base suivante.
	func _c2(y: float, s: String, size: int, col: Color) -> float:
		return UiStyle.para(self, Vector2(COL2, y), s, size + 1, col, W3, size + 6.0)

	func _hp_block(name_s: String, sub: String, hp: float, hp_max: float, mine: bool, tag := "") -> void:
		var col: Color = UiSkin.accent if mine else GameData.RED
		var max_w := 300.0
		var title := name_s.to_upper()
		var fs := 22
		while fs > 13 and UiStyle.text_width(title, fs, true) > max_w:
			fs -= 1
		UiStyle.text_o(self, Vector2(LX, 30), title, fs, col, true)
		var ty := 48.0
		if tag != "":
			UiStyle.text_o(self, Vector2(LX, ty), tag, 13, UiStyle.GOLD, true)
			ty += 16.0
		if sub != "":
			var sl := UiStyle.wrap_lines(sub, 13, max_w)
			var nmax := 2 if tag == "" else 1
			for i in mini(sl.size(), nmax):
				var ln: String = sl[i]
				if i == nmax - 1 and sl.size() > nmax:
					ln = ln.substr(0, maxi(ln.length() - 1, 1)) + "…"
				UiStyle.text(self, Vector2(LX, ty + 15 * i), ln, 13, UiStyle.TEXT_DIM)
		var br := Rect2(LX, 80, max_w, 20)
		UiSkin.bar(self, br, hp / maxf(hp_max, 1.0), Color("6fe0a0") if mine else Color(1.0, 0.45, 0.4))
		UiStyle.text_o(self, Vector2(LX, br.end.y - 5.0), "%d / %d" % [int(hp), int(hp_max)], 13, Color.WHITE, true,
				HORIZONTAL_ALIGNMENT_CENTER, max_w)

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
		UiStyle.section(self, Vector2(RX, 16), 262, "COMPOSITION", UiStyle.GOLD)
		var x := RX
		var y := 40.0
		for id in counts:
			UiStyle.text(self, Vector2(x, y), "%d ×" % counts[id], 15, UiStyle.GOLD)
			UiStyle.text(self, Vector2(x + 34, y), GameData.dname(id), 15, UiStyle.TEXT)
			y += 22.0
			if y > 150.0:
				y = 40.0
				x += 150.0
		UiStyle.section(self, Vector2(COL2, 92), W3, "ORDRES", UiStyle.GOLD)
		var ym := _c2(118.0, "Clic droit : déplacer ou attaquer", 14, UiStyle.TEXT)
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
			UiStyle.section(self, Vector2(RX, 16), 262, "CARACTÉRISTIQUES", UiStyle.GOLD)
			var yr := 40.0
			yr += _row(RX, yr, "Blindage", ARMOR.get(u.armor, u.armor))
			_row(RX, yr, "Vitesse", "%d    Vision %d cases" % [int(u.speed), u.vision])
			UiStyle.section(self, Vector2(COL2, 92), W3, "RÔLE", UiStyle.GOLD)
			if u.role == "mcv":
				_c2(118.0, "Placez-le sur un sol rocheux dégagé puis cliquez sur DÉPLOYER pour créer votre " + GameData.dname("chantier") + " (3x3 cases).", 14, UiStyle.TEXT)
			else:
				_c2(118.0, "Cargaison à évacuer par le point cyan, au bord de la carte (visible sur la carte et le radar).", 14, UiStyle.TEXT)
			return
		UiStyle.section(self, Vector2(RX, 16), 262, "CARACTÉRISTIQUES", UiStyle.GOLD)
		var y := 40.0
		y += _row(RX, y, "Blindage", ARMOR.get(u.armor, u.armor))
		y += _row(RX, y, "Vitesse", "%d    Vision %d cases" % [int(u.speed), u.vision])
		if u.weapon != "":
			var mult := 1.0 + GameData.RANK_DMG * u.rank
			y += _row(RX, y, "Arme", String(WEAPON.get(u.weapon, u.weapon)) + (" — air + sol" if GameData.can_hit_air(u.id) else " — sol seulement"))
			_row(RX, y, "Dégâts", "%.0f /s    Portée %d cases" % [u.dps * mult, int(u.w_range / 32.0)])
		elif u.heal_rate > 0.0:
			y += _row(RX, y, "Soins", "%d PV/s aux alliés" % int(u.heal_rate))
			_row(RX, y, "Rayon", "%d cases" % int(u.heal_range / 32.0))
		elif u.role == "transport":
			y += _row(RX, y, "Soute", "%d / %d unités" % [u.cargo_units.size(), u.slots])
			_row(RX, y, "Vol", "Ignore le terrain")
		else:
			y += _row(RX, y, "Capacité", "%d  (%d en soute)" % [roundi(u.cargo_cap), roundi(u.cargo)])
			_row(RX, y, "Rendement", "%d /s" % int(u.harvest_rate))
		UiStyle.section(self, Vector2(COL2, 92), W3, "ÉVOLUTION" if u.role == "combat" else "RÔLE", UiStyle.GOLD)
		var y2 := 118.0
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
		UiStyle.section(self, Vector2(RX, 16), 262, "CARACTÉRISTIQUES", UiStyle.GOLD)
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
			"reacteur":
				rows.append(["Énergie", "+%d" % b.power])
			"marche":
				rows.append(["Revenu", "+%d Solaris/s" % int(d["income"])])
			"serre":
				rows.append(["Revenu", "+%d minerai/s" % int(d["ore_income"])])
			"mur":
				rows.append(["Rôle", "Barrière"])
			_:
				_generic_rows(rows, b, d)
		if b.power < 0:
			rows.append(["Consomme", "%d énergie" % -b.power])
		elif b.power == 0 and b.id != "mur" and not d.get("wall", false):
			rows.append(["Consomme", "0 énergie"])
		rows.append(["Vision", "%d cases" % b.vision])
		if b.offline:
			rows.append(["État", "HORS TENSION"])
		var y := 40.0
		for r in rows:
			y += _row(RX, y, r[0], r[1], GameData.RED if r[0] == "État" else UiStyle.TEXT)
		if mine and GameData.can_upgrade(b.id):
			UiStyle.section(self, Vector2(COL2, 92), W3, "NIVEAU SUIVANT" if b.level < GameData.MAX_LEVEL else "ÉVOLUTION", UiStyle.GOLD)
			if b.level < GameData.MAX_LEVEL:
				var yy := 118.0
				var up_txt: String = String(GameData.UPGRADES.get(b.id, ""))
				if up_txt == "":
					up_txt = "+40 % PV" + (", +25 % de dégâts" if b.weapon != "" else "")
				var parts: Array = Array(up_txt.split(", "))
				var dp := GameData.power_at(b.id, b.level + 1) - GameData.power_at(b.id, b.level)
				if dp < 0:
					parts.append("consomme %d énergie de plus" % -dp)
				for part in parts:
					yy = UiStyle.para(self, Vector2(COL2, yy), "◆ " + part, 13,
							GameData.AMBER if String(part).begins_with("consomme") else UiStyle.TEXT, W3, 18.0) + 3.0
				var why: String = game.upgrade_block(b, game.ore)
				if why != "":
					UiStyle.para(self, Vector2(COL2, maxf(yy, 168.0)), why, 13, GameData.RED, W3, 16.0)
			else:
				UiStyle.text(self, Vector2(COL2, 118), "Niveau maximum atteint", 15, UiStyle.GOLD)


# --- Bouton néon --------------------------------------------------------------

class NeonButton extends Control:
	signal pressed

	var text := ""
	var glyph := ""
	var enabled := true
	var active := false
	var style := "action" # "action" : boutons du panneau ; "tab" : onglets
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

	func _icon(c: Vector2, sz: float, col: Color) -> void:
		var tex_name: String = {"ore": "icone_minerai", "credit": "icone_epice", "repair": "icone_reparation",
				"demolish": "icone_demolition", "upgrade": "icone_amelioration", "cancel": "icone_annulation"}.get(glyph, "")
		if tex_name != "" and UiSkin.tex(tex_name) != null:
			UiSkin.image(self, tex_name, Rect2(c - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), col)
		else:
			UiStyle.glyph(self, glyph, c, sz * 0.5, col)

	func _draw() -> void:
		var lit := 1.0 if active else maxf(hover_t, press_t)
		var n := ""
		if style == "tab":
			n = "onglet_actif" if (active or lit > 0.5) else "onglet_inactif"
		else:
			n = "bouton_presse" if press_t > 0.5 else ("bouton_actif" if lit > 0.3 else "bouton_normal")
		var tint := Color.WHITE
		if style != "tab" and accent.r > 0.6 and accent.g < 0.45 and accent.b < 0.45:
			tint = Color(1.35, 0.55, 0.5)
		if not enabled:
			tint = Color(0.55, 0.55, 0.6)
		UiSkin.panel(self, n, Rect2(Vector2.ZERO, size), tint)
		var ctr := UiSkin.inner(n, Rect2(Vector2.ZERO, size)).get_center() - size * 0.5
		var tc := Color.WHITE if enabled else Color(0.5, 0.52, 0.56)
		if style == "tab" and UiSkin.tab_text != Color.WHITE:
			tc = UiSkin.tab_text if (active or lit > 0.5) else UiSkin.tab_text_off
		var ic := Color.WHITE if enabled else Color(1, 1, 1, 0.4)
		var fs := 16 if style == "tab" else 14
		var tw := UiStyle.text_width(text, fs, true)
		var gw := 26.0 if glyph != "" else 0.0
		var avail_w := size.x * 0.76 - gw
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
		var x0 := (size.x - wmax - gw) * 0.5 + ctr.x
		if glyph != "":
			_icon(Vector2(x0 + 11, size.y * 0.5 + ctr.y), 20.0, ic)
		for i in lines.size():
			var ly := size.y * 0.5 + ctr.y + 5.0 + (i - (lines.size() - 1) * 0.5) * (fs + 3.0)
			var lw := UiStyle.text_width(String(lines[i]), fs, true)
			UiStyle.text(self, Vector2(x0 + gw + (wmax - lw) * 0.5, ly), String(lines[i]), fs, tc, true)


# --- Portrait (panneau de sélection) ----------------------------------------------

class Portrait extends BuildIcon:
	var focus = null

	func _init(p_game) -> void:
		super("", p_game)
		custom_minimum_size = Vector2.ZERO
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		fit = Vector2(110, 90)

	func set_focus(f) -> void:
		focus = f
		if f is Building or f is Unit:
			id = f.id
			fac = game.faction_id_of(f.team)
		else:
			id = ""

	func _draw() -> void:
		if id == "" or game.bank == null:
			if focus is String:
				UiStyle.text(self, Vector2(0, size.y * 0.5 + 8), "%d" % game.selected.size(), 34, UiStyle.TEXT, true,
						HORIZONTAL_ALIGNMENT_CENTER, size.x)
			return
		_draw_baked_icon(size * 0.5, true)


# --- Carte de production ------------------------------------------------------

class BuildIcon extends Control:
	signal clicked(id: String, button: int)

	var id := ""
	var game
	var hover_t := 0.0
	var _hover := false
	var fit := Vector2(112, 52) # zone occupée par le modèle
	var fac := ""

	func _fid() -> String:
		return fac if fac != "" else game.faction_id

	func _init(p_id: String, p_game) -> void:
		id = p_id
		game = p_game
		custom_minimum_size = Vector2(UiSkin.card_w, UiSkin.card_w / UiSkin.aspect("vignette_normal"))
		mouse_filter = Control.MOUSE_FILTER_STOP
		if p_id == "":
			return
		tooltip_text = " "
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

	## Pièces de coût : [icône, texte, couleur] ; l'énergie (si le bâtiment en produit ou en consomme) vient à la suite.
	func _cost_items(avail: bool) -> Array:
		var is_unit := GameData.UNITS.has(id)
		var rich: bool = game.can_afford(id)
		var cc := Color.WHITE
		if not avail:
			cc = Color(0.55, 0.57, 0.6)
		elif not rich:
			cc = GameData.RED
		var first: int = game.item_cost(id)
		var second: int = game.item_ore(id) if is_unit else GameData.sol_cost(id)
		var c1 := cc
		var c2 := cc
		if avail:
			if is_unit:
				c1 = cc if game.credits >= first * 0.1 else GameData.RED
				c2 = Color.WHITE if game.ore >= second * 0.1 else GameData.RED
			else:
				c1 = cc if game.ore >= first else GameData.RED
				c2 = Color.WHITE if game.credits >= second else GameData.RED
		var items: Array = [
			["icone_epice" if is_unit else "icone_minerai", str(first), c1],
			["icone_minerai" if is_unit else "icone_epice", str(second), c2],
		]
		var d := GameData.def(id)
		if not is_unit and game.is_unlocked(id) and not d.get("wall", false):
			var pw: int = int(d.get("power", 0))
			if pw != 0:
				var pc := Color("6fe0a0") if pw > 0 else GameData.AMBER
				if not avail:
					pc = Color(0.5, 0.52, 0.56)
				items.append(["icone_energie", ("+%d" % pw) if pw > 0 else str(pw), pc])
		return items

	func _row_width(items: Array, fs: int, isz: float) -> float:
		var w := 0.0
		for it in items:
			w += isz + 2.0 + UiStyle.text_width(String(it[1]), fs, true)
		return w + 5.0 * maxi(items.size() - 1, 0)

	func _draw_row(items: Array, center_x: float, base_y: float, fs: int, isz: float, ia: Color) -> void:
		var x := center_x - _row_width(items, fs, isz) * 0.5
		for it in items:
			UiSkin.image(self, String(it[0]), Rect2(x, base_y - isz + 2.0, isz, isz), ia)
			x += isz + 2.0
			UiStyle.text_o(self, Vector2(x, base_y), String(it[1]), fs, it[2], true)
			x += UiStyle.text_width(String(it[1]), fs, true) + 5.0

	func _draw() -> void:
		var d := GameData.def(id)
		var p: Dictionary = game.production_for(id)
		var ready: bool = (not p.is_empty()) and bool(p["ready"])
		var avail: bool = game.is_available(id) or ready
		var busy: bool = (not p.is_empty()) and not bool(p["ready"])
		var t := Time.get_ticks_msec() / 1000.0
		var pulse := 0.5 + 0.5 * sin(t * 5.0)
		var cs := custom_minimum_size

		var tn := "vignette_normal"
		var vtint := Color.WHITE if avail else Color(0.55, 0.55, 0.62)
		if busy:
			vtint = Color(0.8, 1.0, 1.25)
		elif ready or hover_t > 0.5:
			vtint = Color(1.25, 1.2, 1.0)
		UiSkin.panel(self, tn, Rect2(Vector2.ZERO, cs), vtint)

		# Seule l'image du bâtiment / véhicule est dessinée ; les détails sont dans l'infobulle.
		var inn := UiSkin.inner("vignette_normal", Rect2(Vector2.ZERO, cs))
		fit = inn.size * 1.1
		_draw_icon(inn.get_center() - Vector2(0, hover_t * 1.5), avail)

		var fs := 12
		var queued: int = game.queued_count(id)
		if queued > 0:
			var bs := float(fs) + 8.0
			var tag := Rect2(inn.end.x - bs * UiSkin.aspect("badge_quantite") - 1.0, inn.position.y + 1.0, bs * UiSkin.aspect("badge_quantite"), bs)
			UiSkin.panel(self, "badge_quantite", tag)
			UiStyle.text_o(self, Vector2(tag.position.x, tag.position.y + bs * 0.72), "x%d" % queued, maxi(fs - 2, 8),
					Color("f5e9c8"), true, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x)
		if busy:
			UiSkin.bar(self, Rect2(inn.position.x + 2.0, inn.end.y - fs, inn.size.x - 4.0, fs), float(p["progress"]))
		elif ready:
			UiStyle.text_o(self, Vector2(inn.position.x, inn.end.y - 2.0), "Prêt", fs, Color(0.5, 1.0, 0.7, 0.75 + 0.25 * pulse), true,
					HORIZONTAL_ALIGNMENT_CENTER, inn.size.x)

	func _make_custom_tooltip(_for_text: String) -> Object:
		return TipCard.new(id, game)

	## Texte brut de l'infobulle (repli).
	func _get_tooltip(_at: Vector2) -> String:
		var d := GameData.def(id)
		var is_unit := GameData.UNITS.has(id)
		var tip := "%s\nPrix : %s" % [GameData.name_of(id, game.faction_id), game.cost_label(id)]
		if not is_unit and not d.get("wall", false):
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
		if not is_unit and not game.is_unlocked(id):
			tip += "\nVerrouillé : " + ("chantier niv. %d" % game.chantier_needed(id) if game.mission.is_empty() \
					else "mission %d" % Campaign.mission_for_unlock(game.faction_id, int(d.get("unlock", 0))))
		elif String(game.unit_level_block(id)) != "":
			tip += "\n" + String(game.unit_level_block(id))
		elif not is_unit and game.power_block(id) != "":
			tip += "\nÉnergie insuffisante"
		return UiStyle.wrap_text(tip, 14, 360.0)

	func _draw_baked_icon(c: Vector2, avail: bool) -> void:
		var key := "%s|%s" % [id, _fid()]
		var is_unit := GameData.UNITS.has(id)
		var ang := 0.45 if is_unit else 0.0
		var tex = game.bank.frame(key, ang)
		if tex == null:
			return
		var src: Rect2 = game.bank.used_rect(key, ang)
		if src.size.x < 2.0 or src.size.y < 2.0:
			src = Rect2(Vector2.ZERO, tex.get_size())
		# On cadre sur la partie réellement dessinée du modèle, pour qu'elle remplisse l'icône
		var k := minf(minf(fit.x / src.size.x, fit.y / src.size.y), 4.5)
		var dsz := src.size * k
		var col := Color.WHITE if avail else Color(0.5, 0.5, 0.56, 0.85)
		var cc := c + Vector2(0, 2)
		draw_texture_rect_region(tex, Rect2(cc - dsz / 2.0, dsz), src, col)
		# Tourelle d'un véhicule : cuite à part, posée sur le pivot de la coque
		if is_unit:
			if Models.has_turret(id, _fid()):
				var tk := "%s_tete|%s" % [id, _fid()]
				var tt = game.bank.frame(tk, ang)
				if tt != null:
					var hull_c: Vector2 = cc + (game.bank.centre_px(key, ang) - (src.position + src.size * 0.5)) * k
					var po := Models.turret_offset(id, ang, _fid())
					var ps: Vector2 = game.bank.px_scale(key)
					var tcen: Vector2 = hull_c + Vector2(po.x * ps.x, po.y * ps.y) * k
					var hcp: Vector2 = game.bank.centre_px(tk, ang)
					draw_texture_rect(tt, Rect2(tcen - hcp * k, tt.get_size() * k), false, col)
			return
		var d := GameData.def(id)
		var hk := ""
		if id == "radar":
			hk = "radar_tete|%s" % _fid()
		elif d.has("weapon") and not d.get("wall", false):
			hk = "%s_tete|%s" % [id, _fid()]
			if not game.bank.has(hk):
				hk = "tourelle_tete|%s" % _fid()
		if hk != "" and game.bank.has(hk):
			var ha := 0.45
			var ht = game.bank.frame(hk, ha)
			if ht != null:
				var wk: float = k * tex.get_size().x / maxf(game.bank.draw_size(key).x, 1.0)
				var hsz: Vector2 = game.bank.draw_size(hk) * wk
				var tc: Vector2 = cc + (game.bank.centre_px(key, ang) - (src.position + src.size * 0.5)) * k
				draw_texture_rect(ht, Rect2(tc - hsz / 2.0, hsz), false, col)

	func _draw_icon(c: Vector2, avail: bool) -> void:
		var fill := Color("2a3350") if avail else Color("201c2c")
		var line: Color = game.fdata["color"] * 1.6 if avail else Color(0.4, 0.35, 0.5)
		line.a = 1.0
		var role: String = GameData.def(id).get("role", "")
		if game.bank != null and game.bank.has("%s|%s" % [id, _fid()]):
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
