extends SceneTree
## Capture de l'interface en jeu : OUT=/tmp/shots/ui.png xvfb-run -a godot --rendering-driver opengl3 --resolution 1920x1080 --path . -s res://tools/ui_shot.gd
var main
var f := 0
var started := -1
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if main.bank == null or main.loading != null:
		return false
	if started < 0:
		started = f
	if f - started == 90:
		var out := OS.get_environment("OUT") if OS.has_environment("OUT") else "/tmp/shots/ui.png"
		root.get_viewport().get_texture().get_image().save_png(out)
		print("capture ", out)
		quit(0)
		return true
	return false
