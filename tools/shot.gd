extends SceneTree
## Capture d'écran (nécessite un affichage, ex. xvfb-run) :
## xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility --path . --script tools/shot.gd
## Variables : SHOT_SCENE (main|menu), SHOT_FRAMES, SHOT_OUT, FACTION, SHOT_FOCUS=x,y (cases)
var f := 0
var node
var frames := 90


func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	var sc := OS.get_environment("SHOT_SCENE") if OS.has_environment("SHOT_SCENE") else "main"
	if OS.has_environment("SHOT_FRAMES"):
		frames = int(OS.get_environment("SHOT_FRAMES"))
	if OS.has_environment("SHOT_MISSION"):
		GameSession.mode = "campaign"
		GameSession.mission = int(OS.get_environment("SHOT_MISSION"))
	node = load("res://%s.tscn" % sc).instantiate()
	root.add_child(node)


func _process(_d: float) -> bool:
	f += 1
	if f == 5 and OS.has_environment("SHOT_OVERLAY"):
		node._open_campaign()
	if f == 3 and OS.has_environment("SHOT_FOCUS"):
		var p := OS.get_environment("SHOT_FOCUS").split(",")
		node.camera.zoom = Vector2(float(OS.get_environment("SHOT_ZOOM")), float(OS.get_environment("SHOT_ZOOM"))) if OS.has_environment("SHOT_ZOOM") else node.camera.zoom
		node.center_camera(Vector2(float(p[0]), float(p[1])) * 32.0)
	if f == 3 and OS.has_environment("SHOT_NOBANK") and node.bank != null:
		node.bank.queue_free()
		node.bank = null
	if f == 10 and OS.has_environment("SHOT_SELECT"):
		for b in node.buildings:
			if b.team == 0 and b.id == OS.get_environment("SHOT_SELECT"):
				node.inspected = b
				node.selected_building = b
				b.selected = true
				node.ore = 3000
	if f == frames:
		var out := OS.get_environment("SHOT_OUT") if OS.has_environment("SHOT_OUT") else "/tmp/shots/shot.png"
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		return true
	return false
