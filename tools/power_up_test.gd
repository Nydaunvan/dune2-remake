extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		for id in ["chantier", "centrale", "usine", "raffinerie", "fonderie", "tourelle"]:
			print(id, " niv1/2/3 : ", GameData.power_at(id, 1), " ", GameData.power_at(id, 2), " ", GameData.power_at(id, 3))
		var u = null
		for b in main.buildings:
			if b.id == "raffinerie" and b.team == 0:
				u = b
		print("avant: produit=", main.power_produced(), " utilisé=", main.power_used(), " free=", main.power_free())
		main.ore = 9999
		print("bloc=", main.upgrade_block(u, main.ore))
		u.upgrade()
		print("raffinerie niv", u.level, " power=", u.power, " utilisé=", main.power_used())
		main.credits = 0
		return true
	return false
