extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 25:
		printerr("bat:", main.buildings.map(func(b): return b.id + str(b.team)))
		var r = main.buildings.filter(func(b): return b.team == 0 and b.id == "raffinerie")[0]
		var u = main.buildings.filter(func(b): return b.team == 0 and b.id == "chantier")[0]
		printerr("busy usine avant:", main.producer_busy("building", ""))
		r.up_total = 100.0; r.up_left = 100.0
		u.up_total = 100.0; u.up_left = 100.0
		printerr("busy usine:", main.producer_busy("building", ""), " dock:", main.find_dock("spice", Vector2i(10, 10)) == r)
		var cr: float = main.credits
		var h = main.units.filter(func(x): return x.team == 0 and x.id == "recolteur")[0]
		h.cargo = 100.0
		h.position = r.world_center() + Vector2(0, 60)
		h._unload()
		printerr("encaissé pendant travaux: ", main.credits - cr, " état=", h.state)
		r.up_left = 0.0
		h._unload()
		printerr("encaissé après travaux: ", main.credits - cr)
		return true
	return f > 60
