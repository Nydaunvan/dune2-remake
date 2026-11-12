extends SceneTree
## Temps pour qu'une armée détruise un bâtiment : N unités de rang R contre une cible.
##   N=20 RANK=3 TARGET=usine UNIT=belier
var main
var f := 0
var tgt
var t0 := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "kharn"
	GameSession.mode = "skirmish"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _env(k: String, d: String) -> String:
	return OS.get_environment(k) if OS.has_environment(k) else d
func _process(_d: float) -> bool:
	f += 1
	if f == 4:
		main.ai.active = false
		for u in main.units.duplicate():
			if u.team == 1:
				u._die()
		for b in main.buildings:
			if b.team == 1 and b.id == _env("TARGET", "usine"):
				tgt = b
				break
		if tgt == null:
			tgt = main.buildings.filter(func(x): return x.team == 1)[0]
		print("cible ", tgt.id, " PV ", int(tgt.max_hp))
		var n := int(_env("N", "20"))
		for i in n:
			var u = main._spawn_unit(_env("UNIT", "belier"), main._find_free_cell(Vector2i(tgt.cell) + Vector2i(-5 + i % 5, 4 + i / 5)), 0)
			u.rank = int(_env("RANK", "3"))
			u.max_hp *= 1.0 + 0.15 * u.rank; u.hp = u.max_hp
			u.dps *= 1.0 + 0.15 * u.rank
			u.order_attack(tgt)
		for b in main.buildings:
			if b.team == 1 and b.weapon != "":
				b.hp = 0.0; b.take_damage(1.0, "cannon", null)
	if f > 4 and (not is_instance_valid(tgt) or not tgt.alive):
		print("détruit en %.1f s" % ((f - 4) / 60.0))
		return true
	if f > 60 * 120:
		print("pas détruit en 120 s : PV ", int(tgt.hp), "/", int(tgt.max_hp))
		return true
	return false
