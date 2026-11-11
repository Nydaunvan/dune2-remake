extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "kharn"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		for lv in [1, 2, 3]:
			var c = main.buildings.filter(func(b): return b.team == 0 and b.id == "chantier")[0]
			c.level = lv
			var ok := []
			for id in GameData.buildings_for("kharn"):
				if main.is_unlocked(id):
					ok.append(id)
			print("chantier niv.", lv, " -> ", ok)
		return true
	return false
