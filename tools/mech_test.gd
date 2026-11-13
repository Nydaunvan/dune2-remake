extends SceneTree
## Mechas : production disponible, marche (phase, empreintes), tir. FACTION=solis|kharn|vael|conclave
## godot --headless --fixed-fps 60 --path . --script tools/mech_test.gd
var main
var frame := 0
var mechs: Array = []
var foes: Array = []
var hp0 := {}


func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = OS.get_environment("FACTION") if OS.has_environment("FACTION") else "kharn"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame == 3:
		var f: String = GameSession.faction
		var ids: Array = ModelsExtIds.mechs(f)
		print("faction ", f, " mechas: ", ids)
		for id in ids:
			var def: Dictionary = GameData.UNITS[id]
			print("  %s kind=%s niv=%d coût=%d pv=%d req=%s" % [id, Models.move_kind(id, f), int(def["level"]), int(def["cost"]), int(def["hp"]), def["requires"]])
		var c: Vector2i = main.start_cell
		var i := 0
		for id in ids:
			var u = main._spawn_unit(id, main._find_free_cell(c + Vector2i(-2 + i * 2, 5)), 0)
			mechs.append(u)
			hp0[u] = u.hp
			i += 1
		for k in 4:
			var e = main._spawn_unit("vipere" if main.enemy_faction == "kharn" else GameData.FACTIONS[main.enemy_faction]["units"][2], main._find_free_cell(c + Vector2i(-3 + k * 2, 14)), 1)
			foes.append(e)
		for u in mechs:
			u.order_amove(main.world_to_cell(foes[0].position))
	if frame == 240 or frame == 900:
		var kinds := {}
		for s in main.tracks._segs:
			kinds[s[5]] = int(kinds.get(s[5], 0)) + 1
		print("segments de traces: ", kinds)
		for u in mechs:
			if is_instance_valid(u):
				print("  %s vivant=%s walk=%.1f pv=%d/%d sable=%s" % [u.id, u.alive, u._walk, int(u.hp), int(u.max_hp), main.is_sand_at(u.position)])
			else:
				print("  mécha détruit")
		var dead := 0
		for e in foes:
			if not is_instance_valid(e) or not e.alive:
				dead += 1
		print("ennemis détruits: ", dead, "/", foes.size())
		if frame == 900:
			quit()
			return true
	return false


class ModelsExtIds:
	static func mechs(f: String) -> Array:
		var out: Array = []
		for id in GameData.FACTIONS[f]["units"]:
			if ModelsExt.STYLES.get(id, {}).get("k", "") == "mech":
				out.append(id)
		return out
