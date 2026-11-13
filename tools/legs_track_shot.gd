extends SceneTree
## Empreintes de mechas sur fond de sable (synthétique). xvfb-run, opengl3.
var f := 0
var tl: TrackLayer


func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color("c98f78")
	bg.size = Vector2(1152, 648)
	bg.z_index = -20
	root.add_child(bg)
	tl = TrackLayer.new()
	tl.scale = Vector2(3.5, 3.5)
	root.add_child(tl)
	var kinds := ["tracks", "wheels", "hover", "legs_biped", "legs_crystal", "legs_spider"]
	for k in kinds.size():
		var y := 20.0 + k * 20.0
		var x := 10.0
		while x < 280.0:
			var step := 15.0 if String(kinds[k]).begins_with("legs") else 7.0
			tl.add(Vector2(x, y), Vector2(x + step, y), 11 * 0.42 * (1.2 if k == 5 else 1.0), kinds[k])
			x += step


func _process(_d: float) -> bool:
	f += 1
	if f == 8:
		root.get_texture().get_image().save_png("/tmp/shots/legs.png")
		quit()
		return true
	return false
