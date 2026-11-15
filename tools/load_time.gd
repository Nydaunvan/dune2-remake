extends SceneTree
## Mesure : temps jusqu'au démarrage (modèles indispensables) puis jusqu'à la fin de la cuisson en arrière-plan.
## LOAD_DEBUG=1 xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 --path . -s res://tools/load_time.gd
var main
var t0 := 0
var f := 0
var t_core := -1
var t_all := -1
func _initialize() -> void:
	GameSession.faction = "solis"
	GameSession.mode = "skirmish"
	t0 = Time.get_ticks_msec()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	var b = main.bank
	if b == null:
		return false
	if t_core < 0 and b.core_ok and main.loading == null:
		t_core = Time.get_ticks_msec() - t0
		print("PARTIE DÉMARRÉE après %.1f s (images cuites %d/%d)" % [t_core / 1000.0, b.done, b.total])
	if t_all < 0 and b.ready_all:
		t_all = Time.get_ticks_msec() - t0
		print("TOUT CUIT après %.1f s" % [t_all / 1000.0])
		quit(0)
		return true
	return false
