extends SceneTree
## Sans Chantier déployé : aucun bâtiment n'est disponible ; après déploiement, oui.
var main
var f := 0
func _initialize() -> void:
	GameSession.faction = "kharn"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		var n := 0
		for id in GameData.buildings_for("kharn"):
			if main.is_available(id):
				n += 1
		print("dispo sans chantier:", n, " bloc centrale:", main.building_block("centrale"))
		var mcv = null
		for u in main.units:
			if u.team == 0 and u.id == "mcv":
				mcv = u
		print("mcv:", mcv != null)
		main.deploy_mcv(mcv) if main.has_method("deploy_mcv") else print("pas de deploy_mcv")
	if f == 60:
		print("chantier présent:", main.has_building("chantier"), " centrale dispo:", main.is_available("centrale"))
		return true
	return false
