class_name UiSkin
extends RefCounted
## Habillage graphique de l'interface par faction : kit « ORIGINAL » (res://assets/ui/<faction>/).
## Les cadres sont des illustrations non étirables : on les dessine à la taille voulue et le contenu
## est placé dans leur zone intérieure sombre (fractions mesurées par tools/import_kit.py dans skin.json).

const BASE := "res://assets/ui/"
const FALLBACK := "solis"
const ACCENTS := {
	"solis": "f3d27a", "kharn": "ff9a3c", "vael": "e9c46a", "conclave": "c99bff",
}

static var dir := FALLBACK
static var accent := Color("f3d27a")
static var direction := ""
static var tab_text := Color.WHITE
static var tab_text_off := Color.WHITE
static var inners := {}
static var sizes := {}
static var shapes := {}
static var _tex := {}


## Choisit le skin de la faction (retombe sur Solis si son kit n'est pas importé).
static func use(faction_id: String) -> void:
	dir = faction_id if DirAccess.dir_exists_absolute(BASE + faction_id) else FALLBACK
	_tex.clear()
	accent = Color(String(ACCENTS.get(dir, "f3d27a")))
	tab_text = Color("3b2a0c") if dir == "solis" else Color.WHITE
	tab_text_off = Color("5a4520") if dir == "solis" else Color(0.85, 0.85, 0.85)
	inners = {}
	sizes = {}
	shapes = {}
	var f := FileAccess.open(BASE + dir + "/skin.json", FileAccess.READ)
	if f != null:
		var j = JSON.parse_string(f.get_as_text())
		if j is Dictionary:
			inners = j.get("inner", {})
			sizes = j.get("size", {})
			shapes = j.get("shape", {})


static func tex(n: String) -> Texture2D:
	if not _tex.has(n):
		var path := BASE + dir + "/" + n + ".png"
		_tex[n] = load(path) if ResourceLoader.exists(path) else null
	return _tex[n]


## Dessine l'illustration `n` étirée sur `r`.
static func panel(ci: CanvasItem, n: String, r: Rect2, modulate := Color.WHITE) -> void:
	var t := tex(n)
	if t != null:
		ci.draw_texture_rect(t, r, false, modulate)


static func image(ci: CanvasItem, n: String, r: Rect2, modulate := Color.WHITE) -> void:
	panel(ci, n, r, modulate)


## Fraction [x, y, w, h] de la zone intérieure de `n`.
static func frac(n: String) -> Array:
	return inners.get(n, [0.1, 0.1, 0.8, 0.8])


## Zone intérieure (zone de contenu) quand `n` est dessinée sur `outer`.
static func inner(n: String, outer: Rect2) -> Rect2:
	var f: Array = frac(n)
	return Rect2(outer.position + Vector2(f[0] * outer.size.x, f[1] * outer.size.y),
			Vector2(f[2] * outer.size.x, f[3] * outer.size.y))


## Taille de l'illustration qui laisse une zone intérieure de `content` pixels.
static func outer_for(n: String, content: Vector2) -> Vector2:
	var f: Array = frac(n)
	return Vector2(content.x / maxf(f[2], 0.05), content.y / maxf(f[3], 0.05))


## Rapport largeur/hauteur naturel de l'illustration.
static func aspect(n: String) -> float:
	var s: Array = sizes.get(n, [1, 1])
	return float(s[0]) / maxf(float(s[1]), 1.0)


static func shape(n: String) -> String:
	return String(shapes.get(n, "square"))


## Bandeau horizontal : extrémités et motif central gardent leurs proportions, le reste s'étire.
static func band(ci: CanvasItem, n: String, r: Rect2, cuts := [0.2, 0.36, 0.64, 0.8]) -> void:
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
		ci.draw_texture_rect_region(t, Rect2(x, r.position.y, dw, r.size.y), Rect2(xs[i] * tw, 0.0, sw, th))
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
