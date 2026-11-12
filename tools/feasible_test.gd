extends SceneTree
## Faisabilité statique des objectifs de toutes les campagnes.
func _chain(id: String, fac: String, tier: int) -> String:
	if id == "chantier": return ""
	if not GameData.BUILDINGS.has(id): return "%s inconnu" % id
	var d: Dictionary = GameData.BUILDINGS[id]
	var f: String = d.get("faction", "")
	if f != "" and f != fac: return "%s réservé à %s" % [id, f]
	if int(d.get("unlock", 0)) > tier: return "%s verrouillé (unlock %d > palier %d)" % [id, d.get("unlock", 0), tier]
	for r in d["requires"]:
		var e := _chain(r, fac, tier)
		if e != "": return e
	return ""
func _init() -> void:
	var bad := 0
	for fac in ["solis", "kharn", "vael", "conclave"]:
		for m in Campaign.count(fac):
			var d: Dictionary = Campaign.mission(fac, m)
			var tier: int = Campaign.needed_tier(fac, m)
			for o in d["objectives"]:
				var errs: Array = []
				match o["type"]:
					"build":
						for id in o["ids"]:
							var e := _chain(id, fac, tier)
							var mx := int(GameData.def(id).get("max", 0)) if GameData.BUILDINGS.has(id) else 0
							if mx > 0 and int(o["ids"][id]) > mx: e += " max %d < %d" % [mx, o["ids"][id]]
							if e != "": errs.append(e)
					"upgrade":
						if o["id"] != "chantier" and not GameData.can_upgrade(o["id"]): errs.append("non évolutif " + o["id"])
						else:
							var e2 := _chain(o["id"], fac, tier)
							if e2 != "": errs.append(e2)
					"air":
						var e3 := _chain("aerodrome", fac, tier)
						if e3 != "": errs.append(e3)
				for e in errs:
					bad += 1
					print("PROBLEME %s/%d (palier %d) %s : %s" % [fac, m, tier, o["type"], e])
	print("TOTAL problemes=", bad)
	quit()
