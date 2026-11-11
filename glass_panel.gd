class_name GlassPanel
extends Control
## Panneau en verre dépoli (shader ui_glass). Le contenu dessiné par les
## classes filles apparaît au-dessus du fond.

var bg := ColorRect.new()
var mat := ShaderMaterial.new()


func _init(margin := 0.0, radius := 20.0,
		accent_a := Color("00d9ff"), accent_b := Color("ff2fa6")) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mat.shader = load("res://shaders/ui_glass.gdshader")
	mat.set_shader_parameter("margin", margin)
	mat.set_shader_parameter("radius", radius)
	mat.set_shader_parameter("accent_a", accent_a)
	mat.set_shader_parameter("accent_b", accent_b)
	bg.color = Color.WHITE
	bg.material = mat
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.show_behind_parent = true
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resized)


func _on_resized() -> void:
	mat.set_shader_parameter("rect_size", size)
