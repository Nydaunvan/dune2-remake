extends SceneTree
## Capture de l'interface en jeu : OUT=/tmp/shots/ui.png xvfb-run -a godot --rendering-driver opengl3 --resolution 1920x1080 --path . -s res://tools/ui_shot.gd
var main
var f := 0
var started := -1
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.mode = "skirmish"
	GameSession.instant_bases = OS.has_environment("BASE")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if main.bank == null or main.loading != null:
		return false
	if started < 0:
		started = f
	if OS.has_environment("SELECT") and f - started == 70:
		for b in main.buildings:
			if b.team == 0 and b.id == OS.get_environment("SELECT"):
				main.selected_building = b
				main.camera.position = b.world_center()
				break
	if OS.has_environment("TIP") and f - started == 90:
		var pc := PanelContainer.new()
		pc.theme_type_variation = &""
		pc.add_theme_stylebox_override("panel", UiStyle.theme().get_stylebox("panel", "TooltipPanel"))
		pc.add_child(GameUI.TipCard.new(OS.get_environment("TIP"), main))
		pc.position = Vector2(1000, 500)
		main.ui.add_child(pc)
	if f - started == 110:
		var out := OS.get_environment("OUT") if OS.has_environment("OUT") else "/tmp/shots/ui.png"
		root.get_viewport().get_texture().get_image().save_png(out)
		print("capture ", out)
		quit(0)
		return true
	return false
