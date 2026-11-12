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
	return frame >= 5000
