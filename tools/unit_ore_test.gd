extends SceneTree
## Les unités coûtent des Solaris et un peu de minerai, prélevés progressivement ; annulation = remboursement.
var main
var f := 0
var c0 := 0
var o0 := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	GameSession.faction = "kharn"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		c0 = main.credits
		o0 = main.ore
		print("coût brute:", main.cost_label("brute"), " ore_u:", GameData.unit_ore("brute"))
		main.on_item_clicked("brute", MOUSE_BUTTON_LEFT)
	if f == 40:
		main.on_item_clicked("brute", MOUSE_BUTTON_RIGHT)
		print("après annulation: credits ", main.credits - c0, " ore ", main.ore - o0, " (attendu ~0 avec dépenses partielles remboursées)")
	if f == 60:
		main.on_item_clicked("brute", MOUSE_BUTTON_LEFT)
	if f == 3000:
		print("fin: credits ", main.credits - c0, " ore ", main.ore - o0, " file:", main.production["unit"].size())
		return true
	return false
