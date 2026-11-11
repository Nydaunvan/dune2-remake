extends SceneTree
## Gestion de l'énergie : blocage des constructions, hors tension des tourelles.
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.ore = 5000
		print("énergie libre départ: ", main.power_free(), " (prod ", main.power_produced(), " conso ", main.power_used(), ")")
		main._place_building("usine", Vector2i(main.start_cell) + Vector2i(-8, 6), 0)
		main._place_building("tourelle", Vector2i(main.start_cell) + Vector2i(6, 6), 0)
		print("après usine+tourelle libre=", main.power_free(), " block usine=[", main.power_block("usine"), "] centrale=[", main.power_block("centrale"), "]")
		main.on_item_clicked("usine", MOUSE_BUTTON_LEFT)
		print("file après tentative usine: ", main.production["building"].size())
		main.on_item_clicked("centrale", MOUSE_BUTTON_LEFT)
		print("file après centrale: ", main.production["building"].size())
		for b in main.buildings:
			if b.team == 0 and b.id == "centrale":
				b.take_damage(99999.0, "cannon")
				break
		print("après perte centrale ok=", main.power_ok(), " libre=", main.power_free())
	if f == 40:
		for b in main.buildings:
			if b.team == 0 and b.id == "tourelle":
				print("tourelle hors tension: ", b.offline)
		return true
	return false
