extends SceneTree
## Ordre « vider » : un récolteur à moitié plein retourne au dépôt et décharge.
var main
var f := 0
var h
var credits0 := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		for u in main.units:
			if u.team == 0 and u.id == "recolteur":
				h = u
		if h == null:
			h = main.spawn_for("recolteur", 0)
		h.position += Vector2(260, 0)
		h.cargo = 80.0
		h.state = "harvest"
		credits0 = main.credits
		main.selected.clear(); main.selected.append(h)
		print("avant: cargaison=", h.cargo, " état=", h.state)
		main.on_command("unload")
		print("ordre: état=", h.state)
	if f == 5 + 900:
		print("après: cargaison=", h.cargo, " crédits +", main.credits - credits0, " état=", h.state)
		quit()
	return false
