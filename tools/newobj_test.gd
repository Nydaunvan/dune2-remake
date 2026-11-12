extends SceneTree
## Missions Solis n°8 (Frappe chirurgicale) : compteurs de destruction et temps limite.
var main
var f := 0
func _initialize() -> void:
	GameSession.mode = "campaign"
	GameSession.mission = 7
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 10:
		var c = main.buildings.filter(func(b): return b.team == 1 and b.id == "centrale")[0]
		c.take_damage(999999.0, "cannon")
	if f == 20:
		printerr("OBJ ", main.objectives_status().map(func(o): return o["text"] + ":" + str(o["done"])))
		main.kills += 5
		var k = main.units.filter(func(u): return u.team == 1)
		if k.size() > 0:
			k[0]._die()
		printerr("kills=", main.kills)
		main.game_time = 901.0
		main._check_end()
		printerr("over=", main.over)
	return f > 40
