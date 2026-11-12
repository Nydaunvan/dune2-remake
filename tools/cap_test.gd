extends SceneTree
var main
var f := 0
func _initialize() -> void:
	GameSession.instant_bases = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		print("niv chantier ", main.best_level("chantier"), " cap récolteur ", main.worker_cap("recolteur"), " mineur ", main.worker_cap("mineur"))
		print("block récolteur: '", main.worker_block("recolteur"), "' mineur: '", main.worker_block("mineur"), "'")
		main.spawn_for("recolteur", 0)
		print("après +1 récolteur: '", main.worker_block("recolteur"), "'")
		return true
	return false
