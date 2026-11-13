extends SceneTree
var main
var f := 0
var peak := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.mode = "skirmish"
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f < 10 or main.get("loading") != null:
		return false
	main.game_time += 1.5
	for t in main.ais:
		if t == 0: continue
		var n := 0
		for b in main.buildings:
			if b.team == t and b.alive and b.up_left > 0.0: n += 1
		peak = maxi(peak, n)
	if f % 600 == 0: print("t=", int(main.game_time), " peak_up=", peak)
	if f > 3000:
		print("FINAL peak_up=", peak)
		quit()
	return false
