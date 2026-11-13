extends SceneTree
## Barre de ressources sur un fond de terrain factice. xvfb-run, opengl3, écran 1920x1080.
var f := 0


class FakeGame:
	extends Node
	var credits := 3820
	var ore := 231
	var game_time := 593.0
	func storage_cap(kind: String, _t := 0) -> int:
		return 6500 if kind == "spice" else 4500
	func power_produced() -> int:
		return 250
	func power_used() -> int:
		return 175
	func open_pause_menu() -> void:
		pass
	var faction_id := "solis"


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var bg := ColorRect.new()
	bg.color = Color("a8704f")
	bg.size = Vector2(1920, 1080)
	bg.z_index = -50
	root.add_child(bg)
	for i in 30:
		var r := ColorRect.new()
		r.color = Color(0.6 + (i % 5) * 0.05, 0.35, 0.3, 1)
		r.position = Vector2(i * 70.0, 0)
		r.size = Vector2(80, 300)
		r.z_index = -49
		root.add_child(r)
	var cl := CanvasLayer.new()
	root.add_child(cl)
	var g := FakeGame.new()
	root.add_child(g)
	var bar := GameUI.HudBar.new()
	bar.game = g
	bar.position = Vector2(6, 6)
	bar.size = Vector2(1480, 80)
	cl.add_child(bar)
	for spec in [["GUIDE", 3, 1076, 122], ["OBJECTIFS", 4, 1204, 142], ["MENU", 1, 1352, 112]]:
		var b := PlateButton.new(spec[0], spec[1])
		b.font_size = 16
		b.position = Vector2(spec[2], 12)
		b.size = Vector2(spec[3], 56)
		bar.add_child(b)


func _process(_d: float) -> bool:
	f += 1
	if f == 12:
		var img := root.get_texture().get_image()
		img.save_png("/tmp/shots/hud.png")
		print("size ", img.get_size())
		quit()
		return true
	return false
