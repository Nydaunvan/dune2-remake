extends SceneTree
## Équité des cartes : pour chaque camp, longueur du trajet réel base -> champ d'épice / de minerai le plus proche.
## Signale les cartes où un camp doit parcourir bien plus de chemin qu'un autre.
func _init() -> void:
	var worst := 0.0
	var bad := 0
	var n := 0
	for sz in [64, 96, 128]:
		for seed_i in 16:
			var m = load("res://main.gd").new()
			m.map_seed = 4000 + seed_i * 53 + sz
			m.team_factions = {0: "solis", 1: "kharn"} if seed_i % 2 == 0 else {0: "solis", 1: "kharn", 2: "vael", 3: "conclave"}
			GameSession.skirm_size = sz
			m._generate_layout()
			m._setup_noise()
			m._generate_terrain()
			m._build_grid()
			var costs: Array = []
			for base in [m.start_cell, m.enemy_cell, m.ally_cell, m.fourth_cell]:
				if base.x < 0:
					continue
				var c := 0.0
				for fields in [m.spice_fields, m.ore_fields]:
					var best := INF
					for f in fields:
						var a: Vector2i = m._nearest_walkable(Vector2i(base))
						var b: Vector2i = m._nearest_walkable(Vector2i(f))
						var p: PackedVector2Array = m.grid.get_point_path(a, b)
						if p.size() > 1:
							best = minf(best, float(p.size()))
					c += best
				costs.append(c)
			var ratio: float = costs.max() / maxf(costs.min(), 1.0)
			worst = maxf(worst, ratio)
			n += 1
			if ratio > 1.35:
				bad += 1
				print("INÉGALE taille=%d graine=%d trajets=%s" % [sz, m.map_seed, str(costs)])
			m.free()
	print("CARTES=%d inégales=%d pire écart=%.2f" % [n, bad, worst])
	quit()
