extends SceneTree
## Unités volantes : production, vol direct, anti-aérien, transport (embarquer / déposer).
var main
var f := 0
var tr
var hv
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.tier = 9
		main.ore = 9000
		main.credits = 9000
		var placed := false
		for dx in range(-12, 12):
			for dy in range(-12, 12):
				var cc := Vector2i(main.start_cell) + Vector2i(dx, dy)
				if not placed and main._can_place("aerodrome", cc, 0):
					main._place_building("aerodrome", cc, 0)
					placed = true
		main._place_building("usine", Vector2i(main.start_cell) + Vector2i(-8, 6), 0)
		print("aérodrome posé: ", placed, " has: ", main.has_building("aerodrome"))
		print("nacelle dispo (usine niv1): ", main.is_available("nacelle"), " raison: ", main.unit_level_block("nacelle"))
		for b in main.buildings:
			if b.team == 0 and b.id == "usine":
				b.up_left = 0.0
				b.upgrade()
		print("niveau usine=", main.best_level("usine"), " blocage=[", main.unit_level_block("nacelle"), "] usine?", main.has_building("usine"), " aero?", main.has_building("aerodrome"))
		print("nacelle dispo (niv2): ", main.is_available("nacelle"), " libellule: ", main.is_available("libellule"))
		tr = main.spawn_for("nacelle", 0)
		var lib = main.spawn_for("libellule", 0)
		print("air: ", tr.air, " slots ", tr.slots, " libellule hits_air ", GameData.can_hit_air(lib.id))
		for u in main.units:
			if u.team == 0 and u.id == "recolteur":
				hv = u
				break
		tr._end_emerge()
		tr.position = hv.position + Vector2(120, 0)
		tr.order_load(hv)
	if f == 120:
		print("embarqué: ", hv.carried, " soute ", tr.cargo_units.size(), " visible ", hv.visible)
		var dst: Vector2 = tr.position + Vector2(400, 0)
		tr.order_path(PackedVector2Array([tr.position, dst]))
	if f == 600:
		print("après trajet: carried=", hv.carried, " position ok=", hv.position.distance_to(tr.position) < 80.0, " état=", hv.state, " soute ", tr.cargo_units.size())
		var foe = main._spawn_unit("egide", main._find_free_cell(Vector2i(main.start_cell) + Vector2i(20, 0)), 1)
		print("egide peut cibler la nacelle: ", main.find_enemy(1, tr.position, 99999.0, true, foe.id) != tr, " | autocannon peut: ", main.find_enemy(1, tr.position, 99999.0, true, "libellule") == tr)
		return true
	return false
