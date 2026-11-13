class_name Guide
extends CanvasLayer
## Guide du joueur : toutes les explications, consultables partout (touche F1, bouton GUIDE
## en jeu, menu pause et menu principal). Les listes de bâtiments et d'unités sont générées
## depuis GameData : elles restent donc toujours à jour.

const TABS := [
	["start", "DÉMARRER"], ["controls", "COMMANDES"], ["economy", "ÉCONOMIE"],
	["buildings", "BÂTIMENTS"], ["units", "UNITÉS"], ["factions", "FACTIONS"],
	["campaign", "CAMPAGNES"], ["dangers", "DANGERS"], ["system", "RÉGLAGES"],
]

var faction := "solis"
var _was_paused := false
var _page: RichTextLabel
var _tab_btns := {}
var _current := "start"
var _title: Label


## Ouvre le guide au-dessus de n'importe quelle scène (jeu ou menu).
static func open(host: Node, p_faction := "solis") -> Guide:
	for c in host.get_tree().root.get_children():
		if c is Guide:
			return c
	var g := Guide.new()
	g.faction = p_faction if GameData.FACTIONS.has(p_faction) else "solis"
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
	dim.color = Color(0.03, 0.015, 0.06, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 70)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	root.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	_title = Label.new()
	_title.text = "GUIDE DU JOUEUR"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", UiStyle.title_font())
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", GameData.FACTIONS[faction]["accent"])
	vb.add_child(_title)

	# Onglets à gauche, page à droite
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(body)
	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tabs.custom_minimum_size = Vector2(210, 0)
	body.add_child(tabs)
	for t in TABS:
		var b := PlateButton.new(t[1], 4)
		b.font_size = 15
		b.custom_minimum_size = Vector2(210, 54)
		b.pressed.connect(_show.bind(t[0]))
		tabs.add_child(b)
		_tab_btns[t[0]] = b

	var scroll := PanelContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.1, 0.97)
	sb.border_color = Color(0.0, 0.8, 1.0, 0.5)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(22)
	scroll.add_theme_stylebox_override("panel", sb)
	body.add_child(scroll)
	_page = RichTextLabel.new()
	_page.bbcode_enabled = true
	_page.scroll_following = false
	_page.add_theme_font_size_override("normal_font_size", 17)
	_page.add_theme_font_size_override("bold_font_size", 17)
	_page.add_theme_font_size_override("bold_italics_font_size", 17)
	_page.add_theme_color_override("default_color", Color(0.9, 0.9, 0.95))
	scroll.add_child(_page)

	var close := PlateButton.new("FERMER  (F1 / Échap)", 1)
	close.font_size = 15
	close.custom_minimum_size = Vector2(290, 60)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(close_guide)
	vb.add_child(close)
	_show("start")


func _show(key: String) -> void:
	_current = key
	for k in _tab_btns:
		_tab_btns[k].active = (k == key)
	_page.text = call("_p_" + key)
	_page.scroll_to_line(0)


func close_guide() -> void:
	get_tree().paused = _was_paused
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F1):
		get_viewport().set_input_as_handled()
		close_guide()


# --- Mise en forme --------------------------------------------------------------

func _h(s: String) -> String:
	return "\n[font_size=24][color=#7fe9ff][b]%s[/b][/color][/font_size]\n" % s


func _k(s: String) -> String:
	return "[color=#ffcc55][b]%s[/b][/color]" % s


func _name(id: String) -> String:
	return GameData.name_of(id, faction)


# --- Pages écrites à la main -----------------------------------------------------

func _p_start() -> String:
	return _h("Le but du jeu") + """Bâtissez une base sur la planète désertique, récoltez l'épice (Solaris) et le minerai, formez une armée puis détruisez vos adversaires. Il existe deux façons de jouer :
• [b]Campagne[/b] : 15 à 18 missions par faction (Solis 15, Kharn 16, Vael 17, Conclave 18), chacune avec ses objectifs, son adversaire et son briefing. Les missions terminées débloquent de nouveaux bâtiments.
• [b]Escarmouche[/b] : une carte aléatoire, de un à trois adversaires menés par l'IA. Tout se débloque en améliorant votre bâtiment « """ + _name("chantier") + """ ». La fenêtre de paramètres de l'escarmouche permet de choisir 1, 2 ou 3 adversaires (dès 2 adversaires, chaque faction attaque toutes les autres : chacun pour soi), la faction adverse, la taille de la carte, les ressources de départ et la difficulté de l'IA.
""" + _h("Vos premières minutes") + """1. Sélectionnez l'[b]engin de chantier[/b] et appuyez sur """ + _k("D") + """ (ou bouton DÉPLOYER) : il devient votre bâtiment « """ + _name("chantier") + """ », le cœur de votre base.
2. Construisez d'abord votre production d'énergie (« """ + _name("centrale") + """ ») : sans énergie, rien ne fonctionne correctement.
3. Posez « """ + _name("raffinerie") + """ » puis « """ + _name("fonderie") + """ » : chacun produit un engin de récolte (épice, minerai) qui travaille seul.
4. Ajoutez « """ + _name("usine") + """ » pour produire vos unités de combat, puis des défenses (par exemple « """ + _name("tourelle") + """ ») pour protéger la base.
5. Gardez toujours un peu d'avance en énergie, étendez vos récoltes et améliorez vos bâtiments.
""" + _h("Gagner et perdre") + """Vous gagnez en détruisant tous les camps adverses (bâtiments et engins de chantier) ou, en campagne, en remplissant tous les objectifs de la mission (bouton OBJECTIFS ou touche """ + _k("O") + """). Vous perdez si toute votre base et vos engins de chantier disparaissent.
"""


func _p_controls() -> String:
	return _h("Souris") + """• [b]Clic gauche[/b] : sélectionner une unité ou un bâtiment ; glisser pour tracer un cadre de sélection. [b]Maj[/b] ajoute à la sélection.
• [b]Clic droit[/b] sur le sol : déplacer. Sur un ennemi : attaquer. Sur un allié transporteur : embarquer. Sur une icône de la file : annuler.
• [b]Molette[/b] : zoom. [b]Bouton central maintenu[/b] : fait glisser la carte. Approcher le curseur du bord de l'écran fait défiler la carte.
• Dans l'encart d'information d'une unité : boutons [b]ARRÊT[/b], [b]DÉPLACER[/b], [b]ATTAQUER[/b] (déplacement en attaquant tout ce qu'on croise) et [b]DÉPLOYER[/b] / [b]DÉCHARGER[/b] selon l'unité.
""" + _h("Clavier") + """• [b]Flèches ou Z Q S D[/b] : déplacer la caméra
• """ + _k("D") + " : déployer l'engin de chantier — " + _k("U") + """ : décharger un transport
• """ + _k("O") + " : afficher / masquer les objectifs — " + _k("M") + """ : couper le son
• """ + _k("Échap") + " ou " + _k("P") + " : menu pause — " + _k("F1") + " : ce guide — " + _k("F2") + """ : journal des versions
• """ + _k("F6") + " : sauvegarde rapide — " + _k("F7") + """ : chargement rapide
• """ + _k("F11") + " : plein écran — " + _k("F10") + """ : retour au menu principal
""" + _h("Interface") + """• [b]Barre du haut[/b] : Solaris, minerai, énergie (produite / consommée), temps de jeu, boutons OBJECTIFS, GUIDE et MENU.
• [b]Colonne de droite[/b] : radar, journal des événements, onglets BÂTIMENTS / UNITÉS. Clic sur une icône pour la mettre en production ; un bâtiment terminé se pose ensuite sur la carte (clic gauche, clic droit pour annuler).
• [b]Encart en bas à gauche[/b] : détails de ce que vous sélectionnez (PV, énergie, état, niveau, améliorations). Pour un bâtiment : AMÉLIORER, RÉPARER, DÉMOLIR.
• [b]Zone de construction[/b] : on ne peut bâtir que dans un rayon d'environ 15 cases autour de votre « """ + _name("chantier") + """ » (un cercle cyan s'affiche pendant la pose). Pour une seconde base, produisez un [b]engin de chantier[/b] dans « """ + _name("usine") + """ » (niveau 2), emmenez-le sur un sol rocheux dégagé et déployez-le (touche D).
• Les fenêtres sont translucides pour laisser voir le champ de bataille.
"""


func _p_economy() -> String:
	return _h("Les ressources") + """• [b]Solaris[/b] : obtenus en livrant l'épice à « """ + _name("raffinerie") + """ ». Servent à produire les unités.
• [b]Minerai[/b] : livré à « """ + _name("fonderie") + """ ». Sert à construire et améliorer les bâtiments.
• Le récolteur et le mineur travaillent automatiquement : ils cherchent la ressource, la récoltent (un nuage de poussière les entoure) puis rentrent au dépôt le plus proche (« """ + _name("raffinerie") + """ » ou « """ + _name("fonderie") + """ »).
• Le nombre d'engins est limité par le niveau du bâtiment « """ + _name("chantier") + """ » : récolteurs 2 / 3 / 5 et mineurs 1 / 2 / 3 aux niveaux 1 / 2 / 3.
• [b]Paiement progressif[/b] : construire, produire une unité, améliorer un bâtiment ou moderniser une unité ne coûte pas tout d'un coup. Il suffit d'avoir 10 % du prix pour lancer l'opération ; le reste est prélevé au fur et à mesure de l'avancement. Si la caisse est vide, l'opération se met en pause jusqu'au retour des fonds. Annuler une production rembourse ce qui a déjà été payé.
• Le stockage est limité ; construisez des silos (Solaris et minerai) et améliorez vos dépôts pour l'agrandir.
""" + _h("L'énergie") + """Chaque bâtiment produit (""" + _name("centrale") + """, """ + _name("reacteur") + """) ou consomme de l'énergie ; la valeur est indiquée sur son icône et dans son encart. Améliorer un bâtiment peut augmenter sa consommation.
En cas de [color=#ff7777][b]manque d'énergie[/b][/color] : plus aucune récolte n'est encaissée (""" + _name("raffinerie") + """, """ + _name("fonderie") + """) ; """ + _name("radar") + """, """ + _name("reparation") + """, """ + _name("aerodrome") + """ et les défenses s'éteignent (« HORS TENSION »). Reconstruisez ou améliorez vite votre production d'énergie (""" + _name("centrale") + """, """ + _name("reacteur") + """).
""" + _h("Améliorer ses bâtiments") + """Un bâtiment s'améliore jusqu'au [b]niveau 3[/b] (bouton AMÉLIORER). Chaque niveau donne +25 % de PV et un bonus propre au bâtiment, et son [b]apparence évolue[/b] : plaques de blindage, antenne, modules de toit, puis bande énergétique et dôme doré au niveau 3. Les niveaux du bâtiment « """ + _name("chantier") + """ » débloquent les bâtiments en escarmouche. Les niveaux du bâtiment « """ + _name("usine") + """ » débloquent de nouvelles unités et permettent la [b]modernisation des unités[/b] (bonus permanents propres à chaque type).
""" + _h("Réparer et démolir") + """• RÉPARER : remet un bâtiment à neuf contre du minerai (au plus la moitié de son prix, proportionnel aux dégâts). Les unités se réparent aussi dans « """ + _name("reparation") + """ ».
• DÉMOLIR : rembourse 40 % du coût.
• « """ + _name("reparation") + """ » soigne les unités amies proches.
"""


func _p_buildings() -> String:
	var s := _h("Bâtiments de " + GameData.FACTIONS[faction]["name"])
	s += "Coût en minerai (et Solaris), énergie : [color=#66ff99]+[/color] produit / [color=#ff9966]−[/color] consomme.\n\n"
	s += "[b]%s[/b] — Cœur de la base (issu de %s). Construit tout le reste ; ses niveaux ajoutent des places dans la file.\n\n" % [GameData.name_of("chantier", faction), GameData.name_of("mcv", faction).to_lower()]
	for id in GameData.buildings_for(faction):
		var d: Dictionary = GameData.BUILDINGS[id]
		var pw := int(d["power"])
		var line := "[b]%s[/b] — %d minerai" % [GameData.name_of(id, faction), int(d["cost"])]
		if GameData.sol_cost(id) > 0:
			line += " + %d Solaris" % GameData.sol_cost(id)
		line += ", énergie " + ("[color=#66ff99]+%d[/color]" % pw if pw > 0 else ("[color=#ff9966]%d[/color]" % pw if pw < 0 else "0"))
		var req := GameData.req_names(d, faction)
		if not req.is_empty():
			line += ", nécessite : " + ", ".join(req)
		if d.get("unlock", 0) > 1 and d.get("unlock", 0) <= 3:
			line += ", débloqué par la campagne (mission %d)" % Campaign.mission_for_unlock(faction, int(d["unlock"]))
		if GameData.desc_of(id, faction) != "":
			line += "\n    " + GameData.desc_of(id, faction)
		if GameData.UPGRADES.has(id):
			line += "\n    À chaque niveau : " + String(GameData.UPGRADES[id])
		if d.has("weapon"):
			line += "\n    Défense : %d dégâts/s, portée %d cases%s" % [int(d["dps"]), int(d["range"]), ", [color=#7fe9ff]touche les unités volantes[/color]" if d.get("aa", false) else ""]
		s += line + "\n\n"
	return s


func _p_units() -> String:
	var s := _h("Unités de " + GameData.FACTIONS[faction]["name"])
	s += "Les unités se produisent dans « %s » (terrestres, mechas compris) ou « %s » (volantes). Certaines exigent le bâtiment « %s » au niveau 2 ou 3. Une fois par type, la [b]modernisation[/b] (« %s » niveau 2) apporte des bonus permanents.\n" % [_name("usine"), _name("aerodrome"), _name("usine"), _name("usine")]
	for id in GameData.units_for(faction):
		var d: Dictionary = GameData.UNITS[id]
		var line := "\n[b]%s[/b]%s — %d Solaris" % [GameData.name_of(id, faction), " (volant)" if d.get("air", false) else (" (mécha)" if ModelsExt.STYLES.get(id, {}).get("k", "") == "mech" else ""), int(d["cost"])]
		line += " + %d minerai" % GameData.unit_ore(id)
		line += "\n    PV %d, vitesse %d" % [int(d["hp"]), int(d["speed"])]
		if d.has("dps"):
			line += ", dégâts %d/s, portée %d" % [int(d["dps"]), int(d["range"])]
		if d.get("aa", false):
			line += ", [color=#7fe9ff]peut toucher les unités volantes[/color]"
			if float(d.get("vs_air", 1.0)) < 1.0:
				line += " (tir réduit)"
		if float(d.get("vs_ground", 1.0)) < 1.0:
			line += ", [color=#ffb36b]peu efficace contre le sol[/color]"
		if float(d.get("vs_air", 1.0)) > 1.0:
			line += ", [color=#7fe9ff]redoutable contre l'air[/color]"
		var ureq := GameData.req_names(d, faction)
		if not ureq.is_empty():
			line += ", nécessite : " + ", ".join(ureq)
		if GameData.desc_of(id, faction) != "":
			line += "\n    " + GameData.desc_of(id, faction)
		if d.has("capacity"):
			line += "\n    Capacité %d, récolte %d/s" % [int(d["capacity"]), int(d["rate"])]
		if GameData.UNIT_TECH.has(id):
			line += "\n    Modernisation : " + GameData.tech_text(id)
		s += line + "\n"
	s += _h("Mechas") + "Chaque maison aligne ses propres [b]mechas[/b], des machines marcheuses produites à l'usine comme les autres unités terrestres : bipèdes blindés (Solis, Kharn), quadrupèdes (Archonte Solis, Mastodonte Kharn), marcheurs de cristal ou géants d'obsidienne (Conclave), arachnides (Vael). Ils franchissent le terrain comme les autres unités terrestres, se balancent en marchant et laissent des empreintes dans le sable.\n"
	s += _h("Unités volantes") + "Elles survolent la roche et le sable, plus haut que les unités terrestres. [b]Seules certaines unités et défenses peuvent les toucher[/b] (indiquées « touche les unités volantes ») ; les autres tirent sans effet sur elles. Un transport volant embarque des unités terrestres et les dépose n'importe où (touche U)."
	return s


func _p_factions() -> String:
	var s := _h("Les quatre maisons")
	for f in GameData.FACTIONS:
		var d: Dictionary = GameData.FACTIONS[f]
		var hexc: String = d["color"].to_html(false)
		s += "\n[color=#%s][font_size=21][b]%s[/b][/font_size][/color] — %s\n%s\n" % [hexc, d["name"], d["tagline"], d["desc"]]
		var names: PackedStringArray = []
		for id in d["units"]:
			names.append(_name(id))
		var an: PackedStringArray = []
		for id in d["air"]:
			an.append(_name(id))
		s += "Unités terrestres et mechas : %s. Volantes : %s.\n" % [", ".join(names), ", ".join(an)]
		for id in GameData.BUILDINGS:
			if GameData.BUILDINGS[id].get("faction", "") == f:
				s += "Bâtiment propre : %s — %s\n" % [_name(id), GameData.BUILDINGS[id].get("desc", "")]
	s += "\nPlusieurs factions peuvent s'affronter dans une même partie : en [b]chacun pour soi[/b], le troisième camp attaque aussi bien vous que l'autre IA. Vous devez alors vaincre tous les adversaires."
	return s


func _p_campaign() -> String:
	var s := _h("Les campagnes")
	s += "Chaque faction a sa propre campagne de %d missions, avec ses adversaires et son style : défense et précision pour Solis, offensive pour Kharn, vitesse et commerce pour Vael, cristal et endurance pour le Conclave. Une mission terminée débloque la suivante et de nouveaux bâtiments.\n" % Campaign.count(faction)
	s += "\n[b]La difficulté monte de 1 à 10[/b] : adversaires plus rapides, plus nombreux et plus agressifs, objectifs plus longs et délais plus exigeants. Les premières missions se jouent en une dizaine de minutes ; les dernières peuvent durer une heure ou plus, et la dixième oppose quatre camps déjà installés (vous et trois adversaires).\n"
	s += "\nTypes d'objectifs : construire, récolter Solaris ou minerai, produire des unités, une flotte aérienne ou de l'énergie, améliorer des bâtiments, survivre, abattre un nombre d'ennemis, détruire des bâtiments précis, des avant-postes ou tout l'ennemi, escorter un convoi.
Certaines missions imposent un [b]temps limite[/b], démarrent avec une [b]base déjà bâtie[/b] (la vôtre, celle de l'ennemi, ou les deux), ou déchaînent les vers de sable.\nCertaines missions ont [b]2, 3 objectifs ou plus[/b], à remplir tous ; d'autres opposent trois ou quatre camps où chacun est l'ennemi de tous.\n"
	s += _h("Missions de " + GameData.FACTIONS[faction]["name"])
	var i := 0
	for m in Campaign.missions(faction):
		var tag := ""
		if m.get("rival", false):
			tag = " [color=#ff9966](%d camps)[/color]" % (Campaign.foe_count(faction, i) + 1)
		s += "\n[b]%d. %s[/b]%s\n    %s\n" % [i + 1, m["title"], tag, m["obj"]]
		i += 1
	return s


func _p_dangers() -> String:
	return _h("Le terrain") + """• Le [b]sable[/b] est praticable partout, mais c'est là que travaillent les récolteurs (et que rôdent les vers). La [b]roche[/b] est sûre et c'est la seule où l'on peut bâtir.
• Les [b]montagnes[/b] sont infranchissables pour toutes les unités terrestres. Les chaînes de montagnes barrent parfois la route directe entre deux camps, mais un passage reste toujours garanti entre les bases et vers chaque champ de ressources. Les unités volantes les survolent.
• Les cartes sont équitables : chaque camp a ses champs de Solaris et de minerai à distance comparable ; des champs neutres sont répartis entre les bases.
""" + _h("Les vers de sable") + """Des vers géants vivent sous le sable. Ils attirent surtout les engins qui travaillent sur le sable (récolteurs), jamais ceux posés sur la roche.
• Quand un ver approche, un message s'affiche et une [color=#ff7777][b]zone de danger rouge[/b][/color] apparaît sur la carte et sur le radar.
• Les récolteurs fuient automatiquement ; vous pouvez aussi les ramener à la raffinerie ou sur la roche.
• Un ver mord au plus deux fois puis replonge, avec une longue pause avant le suivant.
""" + _h("Le brouillard de guerre") + """Seul ce que vos unités et bâtiments voient est affiché. Le bâtiment « """ + _name("radar") + """ » étend fortement la vision. Les zones déjà explorées restent visibles mais sans les mouvements ennemis.
""" + _h("Les armes et les blindages") + """Chaque arme est plus ou moins efficace selon le blindage de la cible (léger, moyen, lourd, bâtiment). Combinez les unités de votre faction. Les défenses sont indispensables contre les assauts réguliers de l'IA : plus la partie avance, plus les vagues sont grosses.
""" + _h("L'adversaire IA") + """L'IA construit comme vous, récolte, produit puis lance des vagues d'assaut après un délai, en défendant sa base quand elle est menacée. En mission, son rythme dépend du briefing (voir la fiche ENNEMI de chaque mission).
"""


func _p_system() -> String:
	return _h("Réglages d'affichage") + """• Menu pause (Échap) : bouton [b]FPS[/b] pour choisir entre images illimitées (écrans à haute fréquence) et synchronisation avec l'écran.
• Menu pause : curseur [b]Gamma (carte)[/b], de 0,50 à 1,50, qui règle la luminosité et le contraste du terrain et du brouillard (réglage mémorisé, 0,50 par défaut). Il n'agit qu'en partie, jamais sur l'écran d'accueil ; le bouton à côté le remet à 0,50.
• Le bouton [b]v0.xx[/b] du menu pause (ou la touche F2) ouvre le journal des versions.
""" + _h("Sauvegarde et chargement") + """• Vous pouvez sauvegarder à [b]tout moment[/b] : menu pause (Échap), bouton MENU en jeu ou touche F6 pour l'emplacement rapide.
• Quatre emplacements sont disponibles ; chacun indique la faction, le mode, le temps de jeu et la date.
• Charger : depuis le menu pause, la touche F7 ou le bouton CHARGER du menu principal.
• La carte est reconstruite à l'identique ; bâtiments, unités, ressources, files de production, brouillard exploré et IA sont restaurés.
""" + _h("Menu principal") + """Choisissez votre faction, puis CAMPAGNE (liste des missions avec briefing détaillé), ESCARMOUCHE (jusqu'à 3 adversaires), CHARGER ou GUIDE. Les emblèmes des factions s'animent lorsque vous les survolez.
""" + _h("Rangs et bilan") + """Vos unités gagnent des [b]rangs[/b] à chaque élimination : gardez-les en vie. À la fin d'une partie, un tableau récapitulatif de la partie s'affiche.
""" + _h("Astuces") + """• Construisez d'abord votre production d'énergie, puis surveillez l'énergie en haut de l'écran.
• Placez les défenses entre votre base et l'ennemi, et des défenses antiaériennes si l'adversaire possède un bâtiment aérien (« """ + _name("aerodrome") + """ »).
• Groupez vos unités avant de lancer un assaut ; ATTAQUER fait avancer le groupe en tirant sur tout ce qu'il croise.
• Surveillez le journal en bas de la colonne de droite : il garde l'historique des alertes.
• Les récolteurs et mineurs sortent d'usine et partent seuls vers leur champ : inutile de leur donner un ordre.
"""
