extends SceneTree
## Test sans affichage : file d'attente, améliorations, brouillard, rangs.
var main
var f := 0


func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _chantier() -> Building:
	for b in main.buildings:
		if b.team == 0 and b.id == "chantier":
			return b
	return null


func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.ore = 5000
		main.credits = 5000
		for i in 4:
			main.on_item_clicked("centrale", MOUSE_BUTTON_LEFT)
		print("file bât. après 4 clics : %d (max %d) — attendu 2/2, minerai=%d" % [
				main.production["building"].size(), main.queue_max("building"), main.ore])
		main.on_item_clicked("centrale", MOUSE_BUTTON_RIGHT)
		print("après annulation : %d, minerai=%d" % [main.production["building"].size(), main.ore])
		var c := _chantier()
		var ok1: bool = main.upgrade_building(c)
		print("amélioration lancée: %s, niveau avant fin=%d, reste %.0f s, 2e clic bloqué: [%s]" % [str(ok1), c.level, c.up_left, main.upgrade_block(c, 9999)])
		main._tick_upgrades(9999.0)
		print("après délai: niveau %d, max file %d" % [c.level, main.queue_max("building")])
		main.upgrade_building(c); main._tick_upgrades(9999.0)
		print("niveau 3 : max file %d, hp %d/%d" % [main.queue_max("building"), int(c.hp), int(c.max_hp)])
		print("raffinerie niv2 possible ? %s" % main.upgrade_block(_find("raffinerie"), 5000))
		_find("raffinerie").upgrade()
		var uu = main.units.filter(func(x): return x.team == 0 and x.id == "recolteur")
		if not uu.is_empty():
			var hv = uu[0]
			main.credits = 2000
			print("sans usine niv.2: [%s]" % main.unit_upgrade_block(hv))
			main._place_building("usine", Vector2i(main.start_cell) + Vector2i(-8, 6), 0)
			_find("usine").upgrade()
			print("modernisation récolteur: %s cap %d -> " % [str(main.upgrade_unit(hv)), int(hv.cargo_cap)], "")
			main._tick_upgrades(9999.0)
			print("  tech=%d cap=%d rate=%d" % [hv.tech, int(hv.cargo_cap), int(hv.harvest_rate)])
		print("bonus Solaris : x%.2f" % main.income_bonus("spice", 0))
		for u in main.units:
			if u.team == 0 and u.role == "combat":
				u.add_kill()
				u.add_kill()
				u.add_kill()
				print("rang après 3 kills : %s hp %d/%d" % [GameData.RANKS[u.rank]["name"], int(u.hp), int(u.max_hp)])
				break
	if f == 40:
		var vis := 0
		var seen := 0
		for i in main.fog_vis.size():
			vis += main.fog_vis[i]
			seen += main.fog_seen[i]
		var hidden_enemies := 0
		for u in main.units:
			if u.team == 1 and not u.visible:
				hidden_enemies += 1
		var hidden_b := 0
		for b in main.buildings:
			if b.team == 1 and not b.visible:
				hidden_b += 1
		print("brouillard : %d cases visibles / %d explorées sur %d ; ennemis cachés=%d, bâtiments ennemis cachés=%d" % [
				vis, seen, main.fog_vis.size(), hidden_enemies, hidden_b])
	if f == 1200:
		print("files après 20 s : bât=%d unités=%d, bâtiments joueur=%d" % [
				main.production["building"].size(), main.production["unit"].size(),
				main.buildings.filter(func(b): return b.team == 0).size()])
		return true
	return false


func _find(id: String) -> Building:
	for b in main.buildings:
		if b.team == 0 and b.id == id:
			return b
	return null
