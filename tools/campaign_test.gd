extends SceneTree
## Test campagne (FACTION, MISSION) : la mission démarre, ses objectifs s'affichent, et la victoire
## n'est accordée que lorsque TOUS les objectifs sont remplis.
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
		var st: Array = main.objectives_status()
		print("ennemi=%s Solaris=%d minerai=%d palier=%d objectifs=%s" % [main.enemy_faction, main.credits, main.ore, main.tier, str(st.map(func(x): return x["text"]))])
		if st.is_empty():
			print("CAMPAGNE ÉCHEC : aucun objectif")
	if frame == 40:
		# rien n'est accompli : la partie ne doit pas être gagnée
		print("CAMPAGNE %s (fini=%s)" % ["OK" if not main.over else "ÉCHEC : terminée sans rien faire", main.over])
		return true
	return false
