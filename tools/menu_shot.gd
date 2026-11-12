extends SceneTree
## Captures du fond du menu à plusieurs instants (événements de passage, antialiasing des dunes).
## xvfb-run -a godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --script tools/menu_shot.gd
## Variables : SHOT_TIMES="14,54,94" (secondes), SHOT_OUT="/tmp/shots/menu_t%d.png"
var node
var f := 0
var times: Array = [14.0]
var idx := 0
var mat: ShaderMaterial


func _initialize() -> void:
	if OS.has_environment("SHOT_TIMES"):
		times = []
		for s in OS.get_environment("SHOT_TIMES").split(","):
			times.append(float(s))
	node = load("res://menu.tscn").instantiate()
	root.add_child(node)


func _find(n: Node) -> void:
	if n is CanvasItem and n.material is ShaderMaterial and mat == null:
		mat = n.material
	for c in n.get_children():
		_find(c)


func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		_find(node)
		print("mat=", mat != null)
	if f < 8 or mat == null:
		return false
	var k := (f - 8) / 6
	if k >= times.size():
		quit()
		return true
	var step := (f - 8) % 6
	if step == 0:
		mat.set_shader_parameter("time_offset", float(times[k]) - Time.get_ticks_msec() / 1000.0 * 0.0)
	if step == 5:
		var out := (OS.get_environment("SHOT_OUT") if OS.has_environment("SHOT_OUT") else "/tmp/shots/menu_t%d.png") % int(times[k])
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
	return false
