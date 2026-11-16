class_name GlassPanel
extends Control
## Panneau sombre aux coins arrondis (shader ui_panel). Le contenu dessiné par les
## classes filles apparaît au-dessus du fond.

var bg := ColorRect.new()
var mat := ShaderMaterial.new()


func _init(margin := 0.0, radius := 20.0,
		_accent_a := Color("00d9ff"), _accent_b := Color("ff2fa6"), _cut := 0.0) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mat.shader = load("res://shaders/ui_panel.gdshader")
	mat.set_shader_parameter("margin", margin)
	mat.set_shader_parameter("radius", clampf(radius, 8.0, 12.0))
	bg.color = Color.WHITE
	bg.material = mat
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.show_behind_parent = true
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resized)


func _on_resized() -> void:
	mat.set_shader_parameter("rect_size", size)


## Remplace le fond sombre par l'illustration du kit de faction (étirée sur tout le panneau).
func set_skin(skin_name: String) -> void:
	bg.visible = false
	var tr := TextureRect.new()
	tr.texture = UiSkin.tex(skin_name)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.show_behind_parent = true
	add_child(tr)
	move_child(tr, 0)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
