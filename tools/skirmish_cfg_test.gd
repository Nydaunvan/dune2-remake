extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "solis"
	GameSession.mode = "skirmish"
	GameSession.opponents = 1
	GameSession.skirm_foe = "vael"
	GameSession.skirm_size = 80
	GameSession.skirm_res = 1.6
	GameSession.skirm_diff = 2
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if main.get("loading") != null or f < 20: return false
	print("ennemi=", main.enemy_faction, " carte=", main.map_w, " crédits=", main.credits, " minerai=", main.ore, " équipes=", main.team_factions.size(), " vagues=", main.ais[1].wave_size, " grâce=", main.ais[1].wave_grace)
	return true
