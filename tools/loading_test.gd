extends SceneTree
## Chargement : durée et monotonie de la barre (à lancer sous xvfb avec le rendu opengl3).
var main
var last := 0.0
var back := 0
var t0 := 0
var seen := false
func _initialize() -> void:
	GameSession.faction = "solis"
	main = load("res://main.tscn").instantiate()
	t0 = Time.get_ticks_msec()
	root.add_child(main)
func _process(_d: float) -> bool:
	var l = main.get("loading")
	if l != null:
		seen = true
		var f: float = l._shown
		if f < last - 0.0001:
			back += 1
		last = f
		return false
	if seen:
		print("chargement ms:", Time.get_ticks_msec() - t0, " reculs:", back, " dernier:", last, " sons:", Sfx._cache.size())
		return true
	return false
