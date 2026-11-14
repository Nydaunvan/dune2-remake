extends SceneTree
## Capture du menu avec l'invitation de mise à jour (xvfb-run -a godot --rendering-driver opengl3 --resolution 1920x1080 -s tools/update_shot.gd)
var node
var f := 0
func _initialize() -> void:
	node = load("res://menu.tscn").instantiate()
	root.add_child(node)
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		node._on_update_found({"version": "0.23", "notes": "", "url": "", "size": 1, "name": "x"})
	if f == 120:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/shots/update.png")
		quit()
	return false
