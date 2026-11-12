extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		for i in 3:
			main.spawn_for("recolteur", 0)
			main.spawn_for("mineur", 0)
	if f == 1500:
		var cells := {}
		var dup := 0
		for u in main.units:
			if u.team == 0 and u.is_worker() and (u.state == "harvest" or u.state == "seek") and u.work_cell.x >= 0:
				if cells.has(u.work_cell):
					dup += 1
				cells[u.work_cell] = true
				print(u.id, " ", u.state, " ", u.work_cell)
		print("doublons:", dup)
		return true
	return false
