extends SceneTree
## Le ver ne marche jamais sur la roche, arrive lentement et engloutit une unité sur le sable.
var main
var f := 0
var victim
var bad := 0
var steps := 0
var started := -1
var first_bite := -1
var n0 := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		var best := Vector2i(-1, -1)
		for x in range(8, main.map_w - 8):
			for y in range(8, main.map_h - 8):
				if main.terrain[x][y] == 0 and Vector2(x - main.start_cell.x, y - main.start_cell.y).length() < 40 and Vector2(x - main.start_cell.x, y - main.start_cell.y).length() > 12:
					var ok := 0
					for dx in range(-3, 4):
						for dy in range(-3, 4):
							if main.worm_ok_cell(Vector2i(x + dx, y + dy)):
								ok += 1
					if ok == 49:
						best = Vector2i(x, y)
		print("sable trouvé: ", best)
		victim = main.spawn_for("recolteur", 0)
		victim.position = main._cell_to_world(best)
		victim.state = "idle"
		n0 = main.units.size()
		main._spawn_worm(victim)
		print("ver apparu: ", main.worm != null, " distance=", int(main.worm.position.distance_to(victim.position) / 32.0), " cases")
		started = f
	if main.worm != null and is_instance_valid(main.worm):
		steps += 1
		if not main.worm_ok(main.worm.position):
			bad += 1
		if first_bite < 0 and main.worm.phase == "erupt":
			first_bite = f - started
	if f > 5 and started > 0 and main.worm == null:
		print("fin: positions hors sable=", bad, " sur ", steps, " ; arrivée après ", first_bite / 60.0, " s ; victime vivante=", is_instance_valid(victim) and victim.alive)
		quit()
	if f > 5000:
		print("temps écoulé phase=", main.worm.phase if main.worm else "-", " bad=", bad)
		quit()
	return false
