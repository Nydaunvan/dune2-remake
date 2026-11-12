extends SceneTree
# Teste la connexité des cartes générées (graines multiples, toutes tailles)
func _init() -> void:
	var bad := 0
	var mtn_total := 0.0
	var n := 0
	for sz in [64, 96, 128]:
		for seed_i in 12:
			var m = load("res://main.gd").new()
			m.map_seed = 1000 + seed_i * 37
			m.team_factions = {0: "solis", 1: "kharn", 2: "vael", 3: "conclave"} if seed_i % 3 == 0 else ({0: "solis", 1: "kharn"} if seed_i % 3 == 1 else {0: "solis", 1: "kharn", 2: "vael"})
			GameSession.skirm_size = sz
			m._generate_layout()
			m._setup_noise()
			m._generate_terrain()
			# connexité 4-voisins de tous les camps/champs
			var seen := {}
			var q: Array[Vector2i] = [Vector2i(m.start_cell)]
			seen[q[0]] = true
			var i := 0
			while i < q.size():
				var c: Vector2i = q[i]; i += 1
				for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
					var nn: Vector2i = c + d
					if nn.x<0 or nn.y<0 or nn.x>=m.map_w or nn.y>=m.map_h or seen.has(nn): continue
					if m.terrain[nn.x][nn.y] == m.T.MOUNTAIN: continue
					seen[nn] = true; q.append(nn)
			var tg: Array = []
			for pl in m.plateaus: tg.append(pl[0])
			tg.append_array(m.spice_fields); tg.append_array(m.ore_fields)
			for t in tg:
				if not seen.has(Vector2i(t).clamp(Vector2i.ZERO, Vector2i(m.map_w-1,m.map_h-1))):
					bad += 1
			var mt := 0
			for x in m.map_w:
				for y in m.map_h:
					if m.terrain[x][y] == m.T.MOUNTAIN: mt += 1
			mtn_total += float(mt) / (m.map_w * m.map_h); n += 1
			m.free()
	print("INACCESSIBLES=", bad, " montagne moy=", snappedf(mtn_total / n, 0.001))
	quit()
