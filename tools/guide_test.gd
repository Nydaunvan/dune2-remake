extends SceneTree
var f := 0
var g
func _initialize() -> void:
	var m = load("res://menu.tscn").instantiate()
	root.add_child(m)
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		for fac in ["solis", "kharn", "vael"]:
			g = Guide.open(root.get_child(root.get_child_count() - 1), fac) if not is_instance_valid(g) else g
			for t in Guide.TABS:
				g._show(t[0])
				print(fac, " ", t[0], " ", g._page.get_parsed_text().length())
			g.close_guide()
			g = null
		return true
	return false
