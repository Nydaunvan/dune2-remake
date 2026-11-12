extends SceneTree
## Récap de fin : vérifie les compteurs sur de vrais événements, puis affiche l'écran (SHOT_OUT = capture).
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 30:
		var st: GameStats = main.stats
		var mine: Array = main.units.filter(func(u): return u.team == 0 and u.id != "mcv")
		var ids: Array = ["fantassin_x", "brute", "trike"].map(func(x): return x)
		ids = ["x", "brute", "belier"]
		var u1 = main.spawn_for(ids[1], 0)
		var u2 = main.spawn_for(ids[1], 0)
		var foe = main.spawn_for(ids[1], 1)
		var foe2 = main.spawn_for(ids[2], 1)
		foe.take_damage(99999.0, "bullet", u1)
		u2.eaten = true
		u2.devour()
		foe2.eaten = true
		foe2.devour()
		var fb = null
		for b in main.buildings:
			if b.team == 1 and b.alive:
				fb = b
				break
		if fb != null:
			fb.take_damage(999999.0, "bullet", u1)
		print("built:", st.units_built, " lost:", st.units_lost, " eaten:", st.units_eaten, " foes:", st.foes_killed, " foes_eaten:", st.foes_eaten, " b_foe:", st.b_foe, " dmg:", st.dmg_dealt)
		st.worm_apparitions = 3
		st.worm_bites = 5
		st.promotions = 2
		st.top_id = ids[1]
		st.top_kills = 7
		st.max_army = 14
		st.b_built = {"chantier": 1, "raffinerie": 2}
		main.game_time = 1234.0
		var d: Dictionary = st.to_dict()
		var s2 := GameStats.new()
		s2.from_dict(d)
		print("roundtrip ok:", s2.units_eaten == st.units_eaten, s2.max_army == 14)
	if f == 40:
		main.over = false
		main.ui.show_end(true, "Test")
	if f == 150:
		var out := OS.get_environment("SHOT_OUT")
		if out != "":
			root.get_viewport().get_texture().get_image().save_png(out)
		return true
	return false
