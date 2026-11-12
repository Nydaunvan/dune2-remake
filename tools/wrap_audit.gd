extends SceneTree
# Audit des textes : combien de lignes pour chaque description / mention.
func _initialize() -> void:
	var worst := 0
	for id in GameData.UNITS.keys() + GameData.BUILDINGS.keys():
		var d := GameData.def(id)
		var sub := String(d.get("desc", ""))
		var n := UiStyle.wrap_lines(sub, 13, 730.0).size()
		var tip := UiStyle.wrap_lines(sub, 14, 360.0).size()
		if n > 2:
			print("DESC >2 lignes: ", id, " ", n, " : ", sub)
		worst = maxi(worst, n)
		for l in UiStyle.wrap_lines(sub, 13, 730.0):
			if UiStyle.text_width(l, 13) > 730.0:
				print("LIGNE trop large ", id)
	for pair in [["Mission 9 requise ARMÉE MAX. 23", 11], ["CHANTIER NIV. 4 REQUIS", 12], ["USINE NIV. 2 REQUISE", 11], ["ARMÉE MAX. 13", 11]]:
		var wl := UiStyle.wrap_lines(pair[0], pair[1], 144.0, true)
		print(pair[0], " -> ", wl.size(), " lignes")
	var t := "Cliquez à nouveau sur DÉMOLIR pour confirmer et valider la destruction du bâtiment sélectionné"
	print("toast ", UiStyle.wrap_lines(t, 22, 620.0, true).size())
	print("worst desc lines=", worst, "  largeur sample=", UiStyle.text_width("Abcdefghij klmnop", 13))
	quit()
