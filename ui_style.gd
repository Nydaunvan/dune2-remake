class_name UiStyle
## Langage visuel de l'interface « sietch-tech » : panneaux obsidienne aux coins
## coupés (haut-gauche et bas-droit), filets dorés, jauges segmentées, typographie
## espacée en capitales. Tout est dessiné par le code.

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
		_title.spacing_glyph = 2
		_title.variation_embolden = 0.35
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


## Polygone dont les coins haut-gauche et bas-droit sont coupés.
static func chamfer(r: Rect2, cut: float, both := false) -> PackedVector2Array:
	var p := r.position
	var e := r.end
	var pts := PackedVector2Array([
		Vector2(p.x + cut, p.y), Vector2(e.x, p.y),
		Vector2(e.x, e.y - cut), Vector2(e.x - cut, e.y),
		Vector2(p.x, e.y), Vector2(p.x, p.y + cut)])
	if both:
		pts = PackedVector2Array([
			Vector2(p.x + cut, p.y), Vector2(e.x - cut, p.y), Vector2(e.x, p.y + cut),
			Vector2(e.x, e.y - cut), Vector2(e.x - cut, e.y), Vector2(p.x + cut, e.y),
			Vector2(p.x, e.y - cut), Vector2(p.x, p.y + cut)])
	return pts


static func closed(pts: PackedVector2Array) -> PackedVector2Array:
	var c := pts.duplicate()
	c.append(pts[0])
	return c


## Cadre complet : fond, filet principal, lueur et petites équerres dorées aux coins.
static func frame(ci: CanvasItem, r: Rect2, cut: float, line: Color, fill: Color = PANEL, glow := 0.0, lit := 0.0) -> void:
	var pts := chamfer(r, cut)
	var fc := fill.lerp(PANEL_HI, lit)
	fc.a *= 0.5 # fond translucide
	ci.draw_colored_polygon(pts, fc)
	if glow > 0.0:
		ci.draw_polyline(closed(pts), Color(line.r, line.g, line.b, 0.18 * glow), 7.0, true)
		ci.draw_polyline(closed(pts), Color(line.r, line.g, line.b, 0.3 * glow), 4.0, true)
	ci.draw_polyline(closed(pts), line, 1.6, true)
	# équerres dorées
	var tl := r.position + Vector2(cut, 0)
	ci.draw_line(tl, tl + Vector2(14, 0), GOLD, 2.4, true)
	ci.draw_line(r.position + Vector2(0, cut), r.position + Vector2(0, cut + 14), GOLD, 2.4, true)
	var br := r.end - Vector2(cut, 0)
	ci.draw_line(br, br - Vector2(14, 0), GOLD, 2.4, true)
	ci.draw_line(r.end - Vector2(0, cut), r.end - Vector2(0, cut + 14), GOLD, 2.4, true)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, title := false,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := title_font() if title else body_font()
	ci.draw_string_outline(f, pos, s, align, width, size, 4, Color(0, 0, 0, 0.75))
	ci.draw_string(f, pos, s, align, width, size, col)


## Texte centré dans un rectangle, horizontalement et verticalement (hauteur de capitales si `caps`).
static func text_center(ci: CanvasItem, r: Rect2, s: String, size: int, col: Color, title := false, caps := false) -> void:
	var f := title_font() if title else body_font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var cy := r.position.y + r.size.y * 0.5
	var base := cy + (size * 0.36 if caps else (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	var pos := Vector2(r.position.x + (r.size.x - w) * 0.5, base)
	ci.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, 4, Color(0, 0, 0, 0.75))
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
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


## Jauge segmentée (cases allumées jusqu'à la valeur).
static func seg_bar(ci: CanvasItem, r: Rect2, frac: float, col: Color, cell := 9.0, gap := 3.0) -> void:
	var n := int(floor((r.size.x + gap) / (cell + gap)))
	var lit := int(round(clampf(frac, 0.0, 1.0) * n))
	for i in n:
		var x := r.position.x + i * (cell + gap)
		var c := col if i < lit else Color(1, 1, 1, 0.08)
		ci.draw_rect(Rect2(x, r.position.y, cell, r.size.y), c)
		if i < lit:
			ci.draw_rect(Rect2(x, r.position.y, cell, 2.0), Color(1, 1, 1, 0.35))


## Titre de section : libellé, filet et losange.
static func section(ci: CanvasItem, pos: Vector2, w: float, label: String, accent: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -5), pos + Vector2(5, 0), pos + Vector2(0, 5), pos + Vector2(-5, 0)]), GOLD)
	var f := title_font()
	var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	text(ci, pos + Vector2(12, 5), label, 13, accent, true)
	ci.draw_line(pos + Vector2(12 + tw + 10, 0), pos + Vector2(w, 0), Color(accent.r, accent.g, accent.b, 0.4), 1.2, true)


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
