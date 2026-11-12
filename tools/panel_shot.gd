extends SceneTree
## Capture du panneau d'information pour un bâtiment sélectionné (env FACTION, BID, SHOT_OUT).
var main
var f := 0
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION")
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 20:
		for b in main.buildings:
			if b.team == 0 and b.id == OS.get_environment("BID"):
				b.level = 2
				main.selected_building = b
				b.selected = true
				break
	if f == 60:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		return true
	return false
