extends SceneTree
## Test campagne : MISSION=0..2, FACTION. Vérifie le démarrage et l'objectif.
var main
var frame := 0
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "solis"
	GameSession.mode = "campaign"
	GameSession.mission = int(OS.get_environment("MISSION")) if OS.has_environment("MISSION") else 0
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	frame += 1
	if frame == 10:
		print("ennemi=%s credits=%d ia(grace=%d max=%d) obj=%s" % [main.enemy_faction, main.credits, main.ai.wave_grace, main.ai.max_army, str(main.objective_progress())])
		if main.mission["type"] == "harvest":
			main.earned = 4000
		if main.mission["type"] == "survive":
			main.game_time = 481.0
		if main.mission["type"] == "destroy":
			for b in main.buildings.duplicate():
				if b.team == 1:
					b.take_damage(999999.0, "cannon")
	if frame == 60:
		print("over=%s cleared=%d" % [main.over, Campaign.cleared(GameSession.faction)])
		return true
	return false
