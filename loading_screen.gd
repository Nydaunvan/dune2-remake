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
	_shown = lerpf(_shown, _frac, 0.6)
	_canvas.queue_redraw()


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
	UiStyle.text(_canvas, Vector2(0, c.y - 90), "THE BUILDING OF A DYNASTY", 54, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	var bar := Rect2(c.x - 340, c.y - 20, 680, 18)
	UiStyle.frame(_canvas, bar.grow(8), 12.0, Color(_faction_color.r, _faction_color.g, _faction_color.b, 0.7), UiStyle.PANEL, 0.2, 0.3)
	UiStyle.seg_bar(_canvas, bar, _shown, _faction_color * 1.3, 14.0, 4.0)
	UiStyle.text(_canvas, Vector2(0, c.y + 44), _text, 18, UiStyle.TEXT, false, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	UiStyle.text(_canvas, Vector2(0, c.y + 74), "%d %%" % int(round(_shown * 100.0)), 15, UiStyle.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	UiStyle.text(_canvas, Vector2(0, sz.y - 70), _tip, 16, UiStyle.TEXT if _has_art else UiStyle.TEXT_DIM, false, HORIZONTAL_ALIGNMENT_CENTER, sz.x)


func draw_rect_band(cy: float, h: float, a: float) -> void:
	_canvas.draw_rect(Rect2(0, cy - h / 2.0, _canvas.size.x, h), Color(0, 0, 0, a))
