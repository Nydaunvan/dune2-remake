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

static var _title: FontVariation
static var _body: FontVariation


## Police des titres : capitales épaisses et espacées.
static func title_font() -> Font:
	if _title == null:
		_title = FontVariation.new()
		_title.base_font = ThemeDB.fallback_font
		_title.spacing_glyph = 2
		_title.variation_embolden = 0.35
	return _title


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
	ci.draw_colored_polygon(pts, fill.lerp(PANEL_HI, lit))
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
