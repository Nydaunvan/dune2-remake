extends SceneTree
## Réparations : bâtiment (minerai, progressif) et unité (retour à l'usine, Solaris).
var main
var f := 0
var cen
var tk
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.ore = 3000
		main.credits = 3000
		main._place_building("usine", Vector2i(main.start_cell) + Vector2i(-8, 6), 0)
		for b in main.buildings:
			if b.team == 0 and b.id == "centrale":
				cen = b
		cen.hp = cen.max_hp * 0.4
		print("coût réparation centrale: ", main.repair_cost_full(cen), " minerai avant: ", main.ore)
		main.toggle_repair(cen)
		for u in main.units:
			if u.team == 0 and u.id == "recolteur":
				tk = u
				break
		tk.hp = tk.max_hp * 0.3
		print("coût unité: ", main.unit_repair_cost(tk), " blocage: [", main.unit_repair_block(tk), "]")
		main.repair_unit(tk)
	if f == 1500:
		print("centrale hp %d/%d repairing=%s minerai=%d" % [cen.hp, cen.max_hp, str(cen.repairing), main.ore])
		print("unité hp %d/%d état=%s solaris=%d" % [tk.hp, tk.max_hp, tk.state, main.credits])
		return true
	return false
