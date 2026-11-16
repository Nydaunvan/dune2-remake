class_name UiStyle
## Langage visuel de l'interface : panneaux sombres aux coins arrondis, filets fins, une seule couleur
## d'accent (l'or), jauges lisses, libellés en minuscules avec majuscule initiale. Tout est dessiné par le code.

const GOLD := Color("ffcf5a")
const GOLD_DIM := Color("b98a2e")
const INK := Color(0.035, 0.02, 0.07)
const PANEL := Color(0.075, 0.045, 0.13)
const PANEL_HI := Color(0.13, 0.08, 0.2)
const TEXT := Color("f4e6c8")
const TEXT_DIM := Color(0.78, 0.68, 0.58, 0.75)

static var _theme: Theme
static var _title: FontVariation
static var _body: FontVariation


## Thème commun : infobulles, barres de défilement et boutons dans le style de l'interface.
static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font = body_font()
	_theme.default_font_size = 15
	var tip := StyleBoxFlat.new()
	tip.bg_color = Color(0.04, 0.02, 0.09, 0.96)
	tip.set_border_width_all(2)
	tip.border_color = GOLD_DIM
	tip.set_corner_radius_all(6)
	tip.set_content_margin_all(10)
	tip.anti_aliasing = true
	tip.shadow_color = Color(0, 0, 0, 0.5)
	tip.shadow_size = 8
	_theme.set_stylebox("panel", "TooltipPanel", tip)
	_theme.set_color("font_color", "TooltipLabel", TEXT)
	_theme.set_color("font_outline_color", "TooltipLabel", Color(0, 0, 0, 0.8))
	_theme.set_constant("outline_size", "TooltipLabel", 3)
	_theme.set_font_size("font_size", "TooltipLabel", 14)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.05)
	track.set_corner_radius_all(4)
	var grab := StyleBoxFlat.new()
	grab.bg_color = GOLD_DIM
	grab.set_corner_radius_all(4)
	grab.anti_aliasing = true
	var grab_hi := grab.duplicate()
	grab_hi.bg_color = GOLD
	_theme.set_stylebox("scroll", "VScrollBar", track)
	_theme.set_stylebox("grabber", "VScrollBar", grab)
	_theme.set_stylebox("grabber_highlight", "VScrollBar", grab_hi)
	_theme.set_stylebox("grabber_pressed", "VScrollBar", grab_hi)
	return _theme


## Police des titres : capitales épaisses et espacées.
static func title_font() -> Font:
	if _title == null:
		_title = FontVariation.new()
		_title.base_font = ThemeDB.fallback_font
		_title.spacing_glyph = 0
		_title.variation_embolden = 0.28
	return _title


## Les shaders 2D sont écrits pour sortir directement en sRGB. En Forward+ / Mobile le moteur
## reconvertit pourtant leur sortie (rendu délavé) : on la pré-compense (gamma 2.2) pour obtenir
## le même rendu qu'en Compatibilité.
static func fix_gamma(in_game := false) -> void:
	var m := RenderingServer.get_current_rendering_method()
	var g := 2.2 if m == "forward_plus" or m == "mobile" else 1.0
	if in_game:
		g *= DisplayCfg.gamma() # curseur de gamma du menu pause (jamais appliqué à l'accueil)
	RenderingServer.global_shader_parameter_set("gamma_fix", g)


## Logo du jeu (assets/logo.png, fond transparent).
static var _logo: Texture2D
static func logo() -> Texture2D:
	if _logo == null:
		var path := "res://assets/logo.png"
		if ResourceLoader.exists(path):
			_logo = load(path)
		else:
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				img.generate_mipmaps()
				_logo = ImageTexture.create_from_image(img)
	return _logo


## Plaques des boutons du menu d'accueil (assets/ui/btn1..5.png, fond transparent).
static var _btn_tex := {}
static func btn_tex(i: int) -> Texture2D:
	if not _btn_tex.has(i):
		var path := "res://assets/ui/btn%d.png" % i
		if ResourceLoader.exists(path):
			_btn_tex[i] = load(path)
		else:
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				img.generate_mipmaps()
				_btn_tex[i] = ImageTexture.create_from_image(img)
	return _btn_tex.get(i)


static func body_font() -> Font:
	if _body == null:
		_body = FontVariation.new()
		_body.base_font = ThemeDB.fallback_font
		_body.spacing_glyph = 0
		_body.variation_embolden = 0.12
	return _body


## Polygone aux coins arrondis (le nom « chamfer » est conservé : tout le dessin de l'interface l'utilise).
## `cut` donne l'ordre de grandeur du rayon.
static func chamfer(r: Rect2, cut: float, _both := false) -> PackedVector2Array:
	var rad := clampf(cut * 0.55, 3.0, minf(10.0, minf(r.size.x, r.size.y) * 0.5))
	var p := r.position
	var e := r.end
	var pts := PackedVector2Array()
	var cs := [Vector2(e.x - rad, p.y + rad), Vector2(e.x - rad, e.y - rad), Vector2(p.x + rad, e.y - rad), Vector2(p.x + rad, p.y + rad)]
	for k in 4:
		for i in 6:
			var a := -PI * 0.5 + (k + i / 5.0) * PI * 0.5
			pts.append(cs[k] + Vector2.from_angle(a) * rad)
	return pts


static func closed(pts: PackedVector2Array) -> PackedVector2Array:
	var c := pts.duplicate()
	c.append(pts[0])
	return c


## Cadre : fond sombre, filet fin. `lit` (0..1) éclaire le filet au survol ou à la sélection.
static func frame(ci: CanvasItem, r: Rect2, cut: float, line: Color, fill: Color = PANEL, _glow := 0.0, lit := 0.0) -> void:
	var pts := chamfer(r, cut)
	var fc := fill.lerp(PANEL_HI, lit)
	fc.a = 0.9
	ci.draw_colored_polygon(pts, fc)
	var lc := Color(1, 1, 1, 0.14).lerp(Color(line.r, line.g, line.b, 0.95), clampf(lit, 0.0, 1.0))
	ci.draw_polyline(closed(pts), lc, 1.0 + lit * 0.6, true)


## « ATTAQUER » → « Attaquer » : les libellés historiques sont écrits en capitales, on les affiche en minuscules
## avec une majuscule initiale (les sigles de trois lettres ou moins restent tels quels).
static func casef(s: String) -> String:
	return s


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, title := false,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := title_font() if title else body_font()
	if title:
		s = casef(s)
	ci.draw_string(f, pos + Vector2(0, 1.2), s, align, width, size, Color(0, 0, 0, 0.6))
	ci.draw_string(f, pos, s, align, width, size, col)


## Texte centré dans un rectangle, horizontalement et verticalement (hauteur de capitales si `caps`).
static func text_center(ci: CanvasItem, r: Rect2, s: String, size: int, col: Color, title := false, caps := false) -> void:
	var f := title_font() if title else body_font()
	if title:
		s = casef(s)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var cy := r.position.y + r.size.y * 0.5
	var base := cy + (size * 0.36 if caps else (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	var pos := Vector2(r.position.x + (r.size.x - w) * 0.5, base)
	ci.draw_string(f, pos + Vector2(0, 1.2), s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(0, 0, 0, 0.6))
	ci.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)


## Coupe `s` en lignes qui tiennent dans `width` pixels (césure aux espaces, \n respectés).
## Un mot plus long que la largeur est lui-même coupé.
static func wrap_lines(s: String, size: int, width: float, title := false) -> Array:
	var f := title_font() if title else body_font()
	var out: Array = []
	for para in s.split("\n"):
		var cur := ""
		for w in para.split(" ", false):
			var cand: String = w if cur == "" else cur + " " + w
			if f.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x <= width:
				cur = cand
				continue
			if cur != "":
				out.append(cur)
			cur = w
			while f.get_string_size(cur, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > width and cur.length() > 1:
				var n := cur.length() - 1
				while n > 1 and f.get_string_size(cur.substr(0, n), HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > width:
					n -= 1
				out.append(cur.substr(0, n))
				cur = cur.substr(n)
		out.append(cur)
	return out


static func wrap_text(s: String, size: int, width: float, title := false) -> String:
	return "\n".join(PackedStringArray(wrap_lines(s, size, width, title)))


## Paragraphe à la ligne dans `width`. `pos` est la ligne de base de la 1re ligne.
## Renvoie la position y de la ligne de base suivante.
static func para(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float,
		line_h := 0.0, title := false) -> float:
	var lh := line_h if line_h > 0.0 else size * 1.35
	var y := pos.y
	for ln in wrap_lines(s, size, width, title):
		text(ci, Vector2(pos.x, y), ln, size, col, title)
		y += lh
	return y


static func text_width(s: String, size: int, title := false) -> float:
	var f := title_font() if title else body_font()
	if title:
		s = casef(s)
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


## Jauge lisse (barre arrondie remplie jusqu'à la valeur).
static func seg_bar(ci: CanvasItem, r: Rect2, frac: float, col: Color, _cell := 9.0, _gap := 3.0) -> void:
	var rr := Rect2(r.position, Vector2(r.size.x, maxf(r.size.y, 4.0)))
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.12)
	back.set_corner_radius_all(int(rr.size.y * 0.5))
	ci.draw_style_box(back, rr)
	if frac > 0.003:
		var fb := StyleBoxFlat.new()
		fb.bg_color = col
		fb.set_corner_radius_all(int(rr.size.y * 0.5))
		ci.draw_style_box(fb, Rect2(rr.position, Vector2(maxf(rr.size.y, rr.size.x * clampf(frac, 0.0, 1.0)), rr.size.y)))


## Titre de section : libellé et filet fin.
static func section(ci: CanvasItem, pos: Vector2, w: float, label: String, accent: Color) -> void:
	var tw := text_width(label, 13, true)
	text(ci, pos + Vector2(0, 5), label, 13, TEXT_DIM, true)
	ci.draw_line(pos + Vector2(tw + 10, 0), pos + Vector2(w, 0), Color(accent.r, accent.g, accent.b, 0.22), 1.0, true)


## Petits pictogrammes (arrêt, déplacement, attaque, vente, ressources).
static func glyph(ci: CanvasItem, kind: String, c: Vector2, s: float, col: Color) -> void:
	match kind:
		"stop":
			ci.draw_rect(Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), col)
		"move":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s * 0.5, -s * 0.5), c + Vector2(s * 0.6, 0), c + Vector2(-s * 0.5, s * 0.5),
				c + Vector2(-s * 0.2, 0)]), col)
		"attack":
			ci.draw_arc(c, s * 0.5, 0.0, TAU, 20, col, 1.8, true)
			ci.draw_line(c - Vector2(s * 0.8, 0), c - Vector2(s * 0.25, 0), col, 1.8)
			ci.draw_line(c + Vector2(s * 0.8, 0), c + Vector2(s * 0.25, 0), col, 1.8)
			ci.draw_line(c - Vector2(0, s * 0.8), c - Vector2(0, s * 0.25), col, 1.8)
			ci.draw_line(c + Vector2(0, s * 0.8), c + Vector2(0, s * 0.25), col, 1.8)
		"deploy":
			ci.draw_rect(Rect2(c - Vector2(s * 0.7, s * 0.2), Vector2(s * 1.4, s * 0.9)), col, false, 1.8)
			ci.draw_line(c + Vector2(0, -s * 0.9), c + Vector2(0, s * 0.1), col, 1.8)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.35, -s * 0.2), c + Vector2(s * 0.35, -s * 0.2), c + Vector2(0, s * 0.3)]), col)
		"sell":
			ci.draw_arc(c, s * 0.5, 0.0, TAU, 20, col, 1.8, true)
			ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.3), col, 1.8)
		"credit":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -s * 0.6), c + Vector2(s * 0.6, 0), c + Vector2(0, s * 0.6), c + Vector2(-s * 0.6, 0)]), col)
		"ore":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s * 0.3, -s * 0.55), c + Vector2(s * 0.3, -s * 0.55), c + Vector2(s * 0.6, 0),
				c + Vector2(s * 0.3, s * 0.55), c + Vector2(-s * 0.3, s * 0.55), c + Vector2(-s * 0.6, 0)]), col)
		"power":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(s * 0.1, -s * 0.65), c + Vector2(-s * 0.4, s * 0.1), c + Vector2(-s * 0.02, s * 0.1),
				c + Vector2(-s * 0.1, s * 0.65), c + Vector2(s * 0.4, -s * 0.12), c + Vector2(s * 0.02, -s * 0.12)]), col)
