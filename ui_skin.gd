class_name UiSkin
extends RefCounted
## Habillage graphique de l'interface par faction : kit « ORIGINAL » (res://assets/ui/<faction>/).
## Les cadres sont des illustrations non étirables : on les dessine à la taille voulue et le contenu
## est placé dans leur zone intérieure sombre (fractions mesurées par tools/import_kit.py dans skin.json).

const BASE := "res://assets/ui/"
const FALLBACK := "solis"
## Maison Solis garde l'interface classique (cadres plats, sans kit illustré).
const CLASSIC_SOLIS := false
const ACCENTS := {
	"solis": "f3d27a", "kharn": "ff9a3c", "vael": "e9c46a", "conclave": "c99bff",
}

static var dir := FALLBACK
static var accent := Color("f3d27a")
static var direction := ""
static var tab_text := Color.WHITE
static var tab_text_off := Color.WHITE
static var flat := false # interface classique : cadres dessinés en code, sans illustrations
static var inners := {}
static var sizes := {}
static var shapes := {}
static var _tex := {}
static var card_w := 150.0 # largeur réelle d'une carte de production (fixée par la colonne)


## Choisit le skin de la faction (retombe sur Solis si son kit n'est pas importé).
static func use(faction_id: String) -> void:
	dir = faction_id if DirAccess.dir_exists_absolute(BASE + faction_id) else FALLBACK
	_tex.clear()
	accent = Color(String(ACCENTS.get(dir, "f3d27a")))
	flat = dir == "solis" and CLASSIC_SOLIS
	tab_text = Color("3b2a0c") if (dir == "solis" and not flat) else Color.WHITE
	tab_text_off = Color("5a4520") if (dir == "solis" and not flat) else Color(0.85, 0.85, 0.85)
	inners = {}
	sizes = {}
	shapes = {}
	if flat:
		_load_flat()
		return
	var f := FileAccess.open(BASE + dir + "/skin.json", FileAccess.READ)
	if f != null:
		var j = JSON.parse_string(f.get_as_text())
		if j is Dictionary:
			inners = j.get("inner", {})
			sizes = j.get("size", {})
			shapes = j.get("shape", {})


## Tailles et zones intérieures de l'interface classique (aucune image de cadre).
static func _load_flat() -> void:
	sizes = {"panneau_construction": [440, 1080], "panneau_construction_compact": [440, 1080],
			"onglet_actif": [220, 58], "onglet_inactif": [220, 58], "bouton_normal": [240, 60], "bouton_actif": [240, 60],
			"bouton_presse": [240, 60], "radar": [260, 260], "cadre_portrait": [200, 200], "panneau_selection": [1200, 380],
			"panneau_selection_compact": [1200, 380], "vignette_normal": [190, 200], "vignette_verrouillee": [190, 200],
			"slot_production": [100, 110], "badge_quantite": [60, 38], "entete_faction": [380, 110],
			"panneau_objectifs": [300, 150], "panneau_journal": [300, 200], "barre_ressources": [880, 100],
			"panneau_alerte": [400, 90], "progression_fond": [300, 30]}
	var std := [0.05, 0.07, 0.90, 0.86]
	for n in sizes:
		inners[n] = std
	inners["panneau_construction"] = [0.07, 0.10, 0.86, 0.84]
	inners["panneau_construction_compact"] = inners["panneau_construction"]
	inners["entete_faction"] = [0.05, 0.1, 0.9, 0.8]
	inners["barre_ressources"] = [0.02, 0.1, 0.96, 0.8]
	inners["panneau_selection"] = [0.19, 0.07, 0.79, 0.86]
	inners["panneau_selection_compact"] = inners["panneau_selection"]
	inners["selection_portrait"] = [0.02, 0.07, 0.16, 0.86]
	inners["radar"] = [0.04, 0.04, 0.92, 0.92]
	inners["cadre_portrait"] = [0.04, 0.04, 0.92, 0.92]
	inners["vignette_normal"] = [0.06, 0.06, 0.88, 0.88]
	inners["slot_production"] = [0.08, 0.08, 0.84, 0.84]
	shapes = {"radar": "square", "cadre_portrait": "square"}


static func _is_icon(n: String) -> bool:
	return n.begins_with("icone_") or n == "embleme" or n == "progression_remplissage"


## Cadre plat de l'interface classique : fond sombre, filet de la couleur de faction.
static func _flat(ci: CanvasItem, n: String, r: Rect2, modulate: Color) -> void:
	var lit := clampf((maxf(modulate.r, modulate.b) - 1.0) * 2.5, 0.0, 1.0)
	var dim := maxf(modulate.r, modulate.g) < 0.9
	var fill := Color(0.045, 0.06, 0.09)
	var line := accent
	if n == "onglet_actif" or n == "bouton_actif":
		fill = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35)
		lit = maxf(lit, 0.6)
	elif n == "bouton_presse":
		lit = 1.0
	if dim:
		line = Color(0.4, 0.42, 0.48)
	UiStyle.frame(ci, r.grow(-1.0), 8.0, line, fill, 0.0, lit)


static func tex(n: String) -> Texture2D:
	if flat and not _is_icon(n):
		return null
	if not _tex.has(n):
		var path := BASE + dir + "/" + n + ".png"
		_tex[n] = load(path) if ResourceLoader.exists(path) else null
	return _tex[n]


## Pièces à extrémités fixes : seul le milieu s'étire (fractions de coupe).
const BANDED := {
	"barre_ressources": [0.2, 0.36, 0.64, 0.8],
	"bouton_normal": [0.18, 0.38, 0.62, 0.82], "bouton_actif": [0.18, 0.38, 0.62, 0.82], "bouton_presse": [0.18, 0.38, 0.62, 0.82],
	"onglet_actif": [0.18, 0.38, 0.62, 0.82], "onglet_inactif": [0.18, 0.38, 0.62, 0.82],
}


## Rectangle de l'illustration `n` dans `r` : proportions d'origine conservées (centrée dans `r`).
static func fit(n: String, r: Rect2) -> Rect2:
	if flat and not _is_icon(n) and not (n in ["panneau_construction", "radar", "panneau_selection", "vignette_normal", "slot_production", "cadre_portrait"]):
		return r
	if BANDED.has(n) or not sizes.has(n):
		return r
	var a := aspect(n)
	var w := minf(r.size.x, r.size.y * a)
	var h := w / a
	return Rect2(r.position + (r.size - Vector2(w, h)) * 0.5, Vector2(w, h))


## Dessine l'illustration `n` dans `r` sans la déformer.
static func panel(ci: CanvasItem, n: String, r: Rect2, modulate := Color.WHITE) -> void:
	if flat and not _is_icon(n):
		_flat(ci, n, r, modulate)
		return
	var t := tex(n)
	if t == null:
		return
	if BANDED.has(n):
		band(ci, n, r, BANDED[n], modulate)
	else:
		ci.draw_texture_rect(t, fit(n, r), false, modulate)


static func image(ci: CanvasItem, n: String, r: Rect2, modulate := Color.WHITE) -> void:
	panel(ci, n, r, modulate)


## Fraction [x, y, w, h] de la zone intérieure de `n`.
static func frac(n: String) -> Array:
	return inners.get(n, [0.1, 0.1, 0.8, 0.8])


## Zone intérieure (zone de contenu) quand `n` est dessinée dans `outer`.
static func inner(n: String, outer: Rect2) -> Rect2:
	var f: Array = frac(n)
	var o := fit(n, outer)
	return Rect2(o.position + Vector2(f[0] * o.size.x, f[1] * o.size.y), Vector2(f[2] * o.size.x, f[3] * o.size.y))


## Taille (aux proportions d'origine) de l'illustration dont la zone intérieure contient `content`.
static func outer_for(n: String, content: Vector2) -> Vector2:
	var f: Array = frac(n)
	var w := content.x / maxf(f[2], 0.05)
	var h := content.y / maxf(f[3], 0.05)
	var a := aspect(n)
	if w / h > a:
		return Vector2(w, w / a)
	return Vector2(h * a, h)


## Rapport largeur/hauteur naturel de l'illustration.
static func aspect(n: String) -> float:
	var s: Array = sizes.get(n, [1, 1])
	return float(s[0]) / maxf(float(s[1]), 1.0)


static func shape(n: String) -> String:
	return String(shapes.get(n, "square"))


## Bandeau horizontal : extrémités et motif central gardent leurs proportions, le reste s'étire.
static func band(ci: CanvasItem, n: String, r: Rect2, cuts := [0.2, 0.36, 0.64, 0.8], modulate := Color.WHITE) -> void:
	if flat:
		_flat(ci, n, r, modulate)
		return
	var t := tex(n)
	if t == null:
		return
	var tw := float(t.get_width())
	var th := float(t.get_height())
	var k := r.size.y / th
	var xs := [0.0, cuts[0], cuts[1], cuts[2], cuts[3], 1.0]
	var fixed := [true, false, true, false, true]
	var fixed_w := 0.0
	var stretch_src := 0.0
	for i in 5:
		var w: float = (xs[i + 1] - xs[i]) * tw
		if fixed[i]:
			fixed_w += w * k
		else:
			stretch_src += w
	var free := maxf(r.size.x - fixed_w, 0.0)
	var x := r.position.x
	for i in 5:
		var sw: float = (xs[i + 1] - xs[i]) * tw
		var dw: float = sw * k if fixed[i] else free * sw / maxf(stretch_src, 1.0)
		ci.draw_texture_rect_region(t, Rect2(x, r.position.y, dw, r.size.y), Rect2(xs[i] * tw, 0.0, sw, th), modulate)
		x += dw


## Barre de progression : fond de kit puis remplissage coloré dans sa zone intérieure.
static func bar(ci: CanvasItem, r: Rect2, frac_v: float, tint := Color.WHITE, _fill := "") -> void:
	var inn := Rect2(r.position + Vector2(r.size.x * 0.04, r.size.y * 0.2), Vector2(r.size.x * 0.92, r.size.y * 0.6))
	ci.draw_rect(inn, Color(0.02, 0.02, 0.03, 0.85))
	var f := clampf(frac_v, 0.0, 1.0)
	if f > 0.004:
		var c := accent if tint == Color.WHITE else tint
		var fr := Rect2(inn.position, Vector2(maxf(inn.size.y, inn.size.x * f), inn.size.y))
		ci.draw_rect(fr, c)
		ci.draw_rect(Rect2(fr.position, Vector2(fr.size.x, fr.size.y * 0.4)), Color(1, 1, 1, 0.22))


## Boîte plate (infobulles, alertes) aux couleurs du kit.
static func flat_box(border: Color, bg := Color(0.04, 0.035, 0.05, 0.96)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	return sb
