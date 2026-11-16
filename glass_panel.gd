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


## Remplace le fond sombre par un panneau texturé du skin de faction (NinePatch).
func set_skin(skin_name: String) -> void:
	bg.visible = false
	var np := NinePatchRect.new()
	np.texture = UiSkin.tex(skin_name)
	var m: Array = UiSkin.MARGINS.get(skin_name, [24, 24, 24, 24])
	np.patch_margin_left = m[0]
	np.patch_margin_top = m[1]
	np.patch_margin_right = m[2]
	np.patch_margin_bottom = m[3]
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	np.show_behind_parent = true
	add_child(np)
	move_child(np, 0)
	np.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
