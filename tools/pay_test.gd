extends SceneTree
## Paiement progressif : unités, bâtiments, améliorations.
var main
var f := 0
var c0 := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if main.get("loading") != null:
		return false
	f += 1
	if f == 5:
		main.credits = 1000; main.ore = 1000
		c0 = main.credits
		main.on_item_clicked("centrale", MOUSE_BUTTON_LEFT)
		printerr("après clic: ore=", main.ore, " cr=", main.credits)
	if f == 60:
		printerr("après 1 s: ore=", main.ore, " cr=", main.credits, " prog=", main.production["building"][0]["progress"])
	if f == 400:
		var q: Array = main.production["building"]
		printerr("fin: ore=", main.ore, " cr=", main.credits, " items=", q.size(), " ready=", (q[0]["ready"] if q.size() else null))
		# fonds insuffisants : on vide la caisse, puis on annule
		main.ore = 0
		main.on_item_clicked("raffinerie", MOUSE_BUTTON_LEFT)
		printerr("clic sans minerai -> file=", main.production["building"].size())
		main.ore = 60
		main.on_item_clicked("raffinerie", MOUSE_BUTTON_LEFT)
		printerr("clic avec 60 -> file=", main.production["building"].size())
		var b = main.buildings.filter(func(x): return x.team == 0 and x.id == "centrale")[0]
		main.ore = 1000
		main.upgrade_building(b)
		printerr("amélioration: ore=", main.ore, " up_cost=", b.up_cost)
	if f == 500:
		var b2 = main.buildings.filter(func(x): return x.team == 0 and x.id == "centrale")[0]
		printerr("pendant amélioration: ore=", main.ore, " up_left=", b2.up_left)
	return f > 520
