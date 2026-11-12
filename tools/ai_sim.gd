extends SceneTree
## Simulation longue : escarmouche 4 camps, joueur passif, vérifie l'absence d'erreurs et l'activité des IA.
var main
var frame := 0
func _initialize() -> void:
	GameSession.mode = "skirmish"
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	frame += 1
	if frame == 5:
		Engine.time_scale = 8.0
	if frame % 1200 == 0:
		var s := "t=%d" % int(main.game_time)
		for t in [1, 2, 3]:
			var n := 0
			var hurt := 0
			for u in main.units:
				if u.team == t and u.alive and u.role == "combat":
					n += 1
					if u.has_meta("ai_hurt"):
						hurt += 1
			s += " | IA%d armée=%d blessés=%d mode=%s" % [t, n, hurt, str(main.ais[t].mode) if main.get("ais") and main.ais.has(t) else "?"]
		var a = main.ais[1]
		var st := {}
		for u in a._army(): st[u.state] = int(st.get(u.state, 0)) + 1
		s += " wave=%d grace=%d states=%s tgt=%s" % [a.wave_size, a.wave_grace, str(st), str(a._pick_target() != null)]
		print(s)
		var m := ""
		for u in main.units:
			if u.team == 1 and u.is_worker():
				m += " %s:%s c=%.0f p=%d" % [u.id, u.state, u.cargo, u.path.size()]
		var pick: String = a._pick_ground_unit()
		print("   pick=%s avail=%s cost=%d ore_cost=%d armylim=%d under=%s harv=%d miners=%d" % [pick, str(a._available(pick)) if pick != "" else "-", a._cost(pick) if pick != "" else 0, a._ore_cost(pick) if pick != "" else 0, a._army_limit(), str(a._under_cap()), a._count("recolteur"), a._count("mineur")])
		print("   ore=%d cr=%d%s q=%s goal=%s bq=%s bld=%s" % [a.ore, a.credits, m, str(a.unit_q.get("id", "-")), a.goal_text, str(a.build_q.get("id", "-")), str(main.buildings.filter(func(b): return b.team == 1).map(func(b): return b.id + str(b.level)))])
	return frame >= 3700
