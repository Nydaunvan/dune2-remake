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


func _init(p_color := Color(0.4, 0.7, 1.0)) -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_faction_color = p_color
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.07, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_ui)
	add_child(_canvas)


func set_progress(frac: float, text: String) -> void:
	_frac = maxf(_frac, clampf(frac, 0.0, 1.0)) # la barre ne recule jamais
	_text = text
	_shown = lerpf(_shown, _frac, 0.6)
	_canvas.queue_redraw()


func _draw_ui() -> void:
	var sz := _canvas.size
	var c := sz / 2.0
	UiStyle.text(_canvas, Vector2(0, c.y - 90), "THE BUILDING OF A DYNASTY", 54, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	var bar := Rect2(c.x - 340, c.y - 20, 680, 18)
	UiStyle.frame(_canvas, bar.grow(8), 12.0, Color(_faction_color.r, _faction_color.g, _faction_color.b, 0.7), UiStyle.PANEL, 0.2, 0.3)
	UiStyle.seg_bar(_canvas, bar, _shown, _faction_color * 1.3, 14.0, 4.0)
	UiStyle.text(_canvas, Vector2(0, c.y + 44), _text, 18, UiStyle.TEXT, false, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	UiStyle.text(_canvas, Vector2(0, c.y + 74), "%d %%" % int(round(_shown * 100.0)), 15, UiStyle.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	UiStyle.text(_canvas, Vector2(0, sz.y - 70), _tip, 16, UiStyle.TEXT_DIM, false, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
