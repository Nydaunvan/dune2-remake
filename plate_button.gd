class_name PlateButton
extends Control
## Bouton illustré : plaque (assets/ui/btnN.png) avec le texte par-dessus.
## Utilisable partout : `active` = option sélectionnée, `enabled` = grisé et inactif.

signal pressed

var text := ""
var tex_id := 1
var enabled := true
var active := false
var font_size := 17
var hover_t := 0.0
var press_t := 0.0
var _hover := false


func _init(p_text := "", p_tex := 1) -> void:
	text = p_text
	tex_id = p_tex
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_entered.connect(func() -> void: _hover = true)
	mouse_exited.connect(func() -> void: _hover = false)


func _process(delta: float) -> void:
	hover_t = move_toward(hover_t, 1.0 if (_hover and enabled) else 0.0, delta * 8.0)
	press_t = move_toward(press_t, 0.0, delta * 5.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if enabled:
			press_t = 1.0
			pressed.emit()
		accept_event()


func _draw() -> void:
	var tex := UiStyle.btn_tex(tex_id)
	var grow := 3.0 * hover_t - 2.0 * press_t
	var r := Rect2(Vector2(-grow, -grow * 0.3), Vector2(size.x + grow * 2.0, size.y + grow * 0.6))
	var t := Time.get_ticks_msec() / 1000.0
	if tex != null:
		var k := 1.0 + 0.28 * hover_t - 0.25 * press_t
		if not enabled:
			k = 0.38
		elif active:
			k = 1.3 + 0.08 * sin(t * 3.0) # option choisie : plaque éclatante
		draw_texture_rect(tex, r, false, Color(k, k, k, 1.0))
	var col := Color(1.0, 0.97, 0.9).lerp(Color.WHITE, hover_t) if enabled else Color(0.7, 0.66, 0.62)
	if active:
		col = Color(1.0, 0.93, 0.6)
	# Le texte rétrécit pour tenir dans la plaque
	var fs := font_size
	var avail := size.x * 0.8
	while fs > 9 and UiStyle.text_width(text, fs, true) > avail:
		fs -= 1
	UiStyle.text(self, Vector2(0, size.y * 0.56 + fs * 0.36), text, fs, col, true, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	if active: # losanges de part et d'autre du texte : option choisie
		var hw := UiStyle.text_width(text, fs, true) * 0.5 + 16.0
		var cy := size.y * 0.56
		for sd in [-1.0, 1.0]:
			var q := Vector2(size.x * 0.5 + sd * hw, cy)
			draw_colored_polygon(PackedVector2Array([q + Vector2(0, -5), q + Vector2(5, 0), q + Vector2(0, 5), q + Vector2(-5, 0)]), Color(1.0, 0.88, 0.45))
