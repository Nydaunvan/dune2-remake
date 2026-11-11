extends SceneTree
var main
var f := 0
var h
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		for u in main.units:
			if u.team == 0 and u.role == "harvester":
				h = u
		print("énergie ok=", main.power_ok(), " produit=", main.power_produced())
		# panne : on détruit la centrale
		for b in main.buildings:
			if b.id == "centrale" and b.team == 0:
				b.power = 0
		main._update_power_state()
		for b in main.buildings:
			if b.team == 0:
				print(b.id, " offline=", b.offline)
		h.cargo = 100.0
		h.global_position = main.buildings[0].world_center()
		main.credits = 0
		h._unload()
		print("pendant la panne : crédits=", main.credits, " cargaison=", h.cargo, " état=", h.state)
	if f == 8:
		for b in main.buildings:
			if b.id == "centrale" and b.team == 0:
				b.power = 100
		main._update_power_state()
		h._unload()
		print("après retour du courant : crédits=", main.credits, " cargaison=", h.cargo)
		return true
	return false
