class_name LoadingScreen
extends CanvasLayer
## Écran de chargement : carte, modèles 3D et sons sont préparés avant la partie.

const TIPS := [
	"Déployez l'engin de chantier sur un sol rocheux dégagé pour fonder votre base.",
	"Les ouvriers fuient automatiquement quand un ver géant approche.",
	"Améliorez le Chantier pour allonger la file de construction.",
	"Les unités gagnent des rangs à chaque élimination : gardez-les en vie.",
	"Clic droit sur une icône de production pour annuler et être remboursé.",
	"Touche M : couper ou remettre le son. F11 : plein écran.",
]

var _frac := 0.0
var _shown := 0.0
var _text := "Initialisation…"
var _canvas: Control
var _tip: String = TIPS[randi() % TIPS.size()]
var _faction_color := Color(0.4, 0.7, 1.0)
var _has_art := false


func _init(p_color := Color(0.4, 0.7, 1.0), p_faction := "") -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_faction_color = p_color
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.07, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := _art(p_faction)
	if art != null:
		var tr := TextureRect.new()
		tr.texture = art
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(tr)
		_has_art = true
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_ui)
	add_child(_canvas)


## Illustration propre à la faction jouée (assets/loading/<faction>.jpg).
static func _art(faction: String) -> Texture2D:
	if faction == "":
		return null
	var path := "res://assets/loading/%s.jpg" % faction
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if img != null else null


func set_progress(frac: float, text: String) -> void:
	_frac = maxf(_frac, clampf(frac, 0.0, 1.0)) # la barre ne recule jamais
	_text = text


## La barre rattrape la progression réelle en douceur, image par image.
func _process(delta: float) -> void:
	var d := minf(delta, 0.05)
	var gap := _frac - _shown
	if gap > 0.0:
		_shown = minf(_frac, _shown + maxf(gap * (1.0 - exp(-3.2 * d)), 0.02 * d))
	_canvas.queue_redraw()


## Termine proprement : la barre va jusqu'au bout avant la disparition de l'écran.
func finish(text := "Prêt") -> void:
	set_progress(1.0, text)
	var t := 0.0
	while _shown < 0.999 and t < 1.5:
		await get_tree().process_frame
		t += get_process_delta_time()
	await get_tree().create_timer(0.15).timeout


func _draw_ui() -> void:
	var sz := _canvas.size
	var c := sz / 2.0
	if _has_art:
		# Voile sombre progressif derrière le texte pour qu'il reste lisible sur l'illustration
		for i in 14:
			var k := float(i) / 13.0
			var h := 260.0 + 120.0 * (1.0 - k)
			draw_rect_band(c.y + 10.0, h, 0.06 + 0.025 * k)
		_canvas.draw_rect(Rect2(0, sz.y - 120, sz.x, 120), Color(0, 0, 0, 0.6))
	var logo := UiStyle.logo()
	if logo != null:
		var lh := minf(210.0, c.y - 40.0)
		var lw := lh * float(logo.get_width()) / float(logo.get_height())
		_canvas.draw_texture_rect(logo, Rect2(c.x - lw / 2.0, c.y - 60.0 - lh, lw, lh), false)
	else:
		UiStyle.text(_canvas, Vector2(0, c.y - 90), "THE BUILDING OF A DYNASTY", 54, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	_draw_bar(Rect2(c.x - 360, c.y - 26, 720, 22))
	UiStyle.text(_canvas, Vector2(0, c.y + 44), _text, 18, UiStyle.TEXT, false, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	UiStyle.text(_canvas, Vector2(0, c.y + 74), "%d %%" % int(round(_shown * 100.0)), 15, UiStyle.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	UiStyle.text(_canvas, Vector2(0, sz.y - 70), _tip, 16, UiStyle.TEXT if _has_art else UiStyle.TEXT_DIM, false, HORIZONTAL_ALIGNMENT_CENTER, sz.x)


func draw_rect_band(cy: float, h: float, a: float) -> void:
	_canvas.draw_rect(Rect2(0, cy - h / 2.0, _canvas.size.x, h), Color(0, 0, 0, a))


## Contour d'une capsule (extrémités arrondies) tronqué à la largeur w : points du haut puis du bas.
func _capsule(r: Rect2, w: float) -> PackedVector2Array:
	var rad := r.size.y * 0.5
	var pts := PackedVector2Array()
	var x0 := r.position.x
	var cy := r.position.y + rad
	var xmax := x0 + clampf(w, 0.0, r.size.x)
	var left := PackedVector2Array()
	for i in 13: # demi-cercle gauche, de bas en haut
		var a := PI * 0.5 + PI * float(i) / 12.0
		left.append(Vector2(x0 + rad + cos(a) * rad, cy - sin(a) * rad * -1.0))
	for p in left:
		pts.append(Vector2(minf(p.x, xmax), p.y))
	var n := 48
	for i in n + 1: # bord haut
		var x := x0 + rad + (r.size.x - 2.0 * rad) * float(i) / n
		pts.append(Vector2(minf(x, xmax), r.position.y))
	for i in 13: # demi-cercle droit, de haut en bas
		var a := -PI * 0.5 + PI * float(i) / 12.0
		pts.append(Vector2(minf(x0 + r.size.x - rad + cos(a) * rad, xmax), cy + sin(a) * rad))
	for i in n + 1: # bord bas
		var x := x0 + r.size.x - rad - (r.size.x - 2.0 * rad) * float(i) / n
		pts.append(Vector2(minf(x, xmax), r.end.y))
	return pts


func _draw_bar(r: Rect2) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var fc := _faction_color
	var base := Color(minf(fc.r * 1.1, 1.0), minf(fc.g * 1.1, 1.0), minf(fc.b * 1.1, 1.0))
	var hot := base.lerp(Color.WHITE, 0.55)
	# halo, rail sombre et cadre
	_canvas.draw_rect(r.grow(14.0), Color(fc.r, fc.g, fc.b, 0.05))
	_canvas.draw_rect(r.grow(8.0), Color(fc.r, fc.g, fc.b, 0.06))
	_canvas.draw_colored_polygon(_capsule(r.grow(5.0), r.size.x + 10.0), Color(0.02, 0.01, 0.04, 0.82))
	var rim := _capsule(r.grow(5.0), r.size.x + 10.0)
	rim.append(rim[0])
	_canvas.draw_polyline(rim, Color(fc.r, fc.g, fc.b, 0.75), 2.0, true)
	_canvas.draw_colored_polygon(_capsule(r, r.size.x), Color(1, 1, 1, 0.07))
	var w := r.size.x * _shown
	if w > 1.0:
		var poly := _capsule(r, maxf(w, r.size.y))
		var cols := PackedColorArray()
		var sx := r.position.x + fposmod(t * 0.45, 1.4) * r.size.x * 1.3 - r.size.x * 0.15 # reflet qui balaie la barre
		for p in poly:
			var u := clampf((p.x - r.position.x) / maxf(w, 1.0), 0.0, 1.0)
			var k := clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)
			var c := base.darkened(0.45).lerp(base, 0.35 + 0.65 * u) # dégradé sombre → clair vers la tête
			c = c.lerp(Color.WHITE, 0.4 * pow(1.0 - k, 2.0)) # lumière sur le haut (effet tube)
			var g := exp(-pow((p.x - sx) / 46.0, 2.0)) * 0.5
			c = c.lerp(Color.WHITE, g)
			c.a = 1.0
			cols.append(c)
		_canvas.draw_polygon(poly, cols)
		# tête lumineuse + braises
		var hx := r.position.x + maxf(w, r.size.y * 0.5)
		var hy := r.position.y + r.size.y * 0.5
		for k in 5:
			_canvas.draw_circle(Vector2(hx, hy), 22.0 - k * 4.0, Color(hot.r, hot.g, hot.b, 0.05 + 0.04 * k))
		_canvas.draw_circle(Vector2(hx, hy), 4.0, Color(1, 1, 1, 0.95))
		for i in 7:
			var ph := fposmod(t * 0.9 + i * 0.37, 1.0)
			var ex := hx - ph * 70.0 - 4.0
			if ex > r.position.x:
				_canvas.draw_circle(Vector2(ex, hy + sin(t * 3.0 + i * 2.1) * 4.0 - ph * 9.0), 1.6 * (1.0 - ph) + 0.4, Color(hot.r, hot.g, hot.b, 0.8 * (1.0 - ph)))
	# graduations fines par-dessus le rail
	for i in range(1, 10):
		var x := r.position.x + r.size.x * i / 10.0
		_canvas.draw_line(Vector2(x, r.end.y - 3.0), Vector2(x, r.end.y), Color(1, 1, 1, 0.22), 1.0)
