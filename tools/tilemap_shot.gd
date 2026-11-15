extends SceneTree
func _initialize() -> void:
	var s = load("res://experiments/tilemap/tilemap_demo.tscn").instantiate()
	root.add_child(s)
func _process(_d: float) -> bool:
	if Engine.get_process_frames() == 30:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/shots/tilemap.png")
		quit()
	return false
