extends SceneTree
## Planche de toutes les icônes d'inventaire d'une faction (env FACTION, SHOT_OUT).
var main
var f := 0
func _initialize() -> void:
	GameSession.faction = OS.get_environment("FACTION")
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 10:
		var fid: String = main.faction_id
		var ids: Array = ["chantier", "mcv", "recolteur", "mineur", "centrale", "raffinerie", "fonderie", "usine", "tourelle"]
		ids += GameData.buildings_for(fid)
		ids += GameData.FACTIONS[fid]["units"] + GameData.FACTIONS[fid]["air"]
		var seen := {}
		var layer := CanvasLayer.new()
		layer.layer = 100
		main.add_child(layer)
		var bg := ColorRect.new()
		bg.color = Color(0.1, 0.07, 0.15)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.add_child(bg)
		var i := 0
		for id in ids:
			if seen.has(id):
				continue
			seen[id] = true
			var ic := GameUI.BuildIcon.new(id, main)
			ic.position = Vector2((i % 12) * 160, (i / 12) * 132)
			layer.add_child(ic)
			i += 1
	if f == 40:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		return true
	return false
