extends SceneTree
## Vérifie que chaque bâtiment et chaque unité de chaque faction a une description.
func _initialize() -> void:
	var miss := 0
	var longest := 0
	for f in GameData.FACTIONS:
		var ids: Array = ["chantier", "mcv", "recolteur", "mineur", "centrale", "raffinerie", "fonderie", "usine", "tourelle"]
		ids += GameData.buildings_for(f)
		ids += GameData.FACTIONS[f]["units"] + GameData.FACTIONS[f]["air"]
		for id in ids:
			var s := GameData.desc_of(id, f)
			longest = maxi(longest, s.length())
			if s == "":
				miss += 1
				print("MANQUE ", f, " ", id)
	print("descriptions manquantes: ", miss, " plus longue: ", longest)
	quit()
