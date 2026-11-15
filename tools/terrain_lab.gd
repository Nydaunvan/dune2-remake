extends SceneTree
## Banc d'essai du shader de terrain, sans charger le jeu : relief par bruit, mêmes paramètres que main.gd.
## SH=terrain xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x800 --path . -s res://tools/terrain_lab.gd
## Sorties : /tmp/shots/lab_<SH>_<zone>.png ; affiche aussi le temps par image.
const MAP := 96
const FS := 3
var rect: ColorRect
var cam: Camera2D
func _initialize() -> void:
	RenderingServer.global_shader_parameter_set("gamma_fix", 0.5)
	var nh := FastNoiseLite.new()
	nh.seed = 7
	nh.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nh.frequency = 0.07
	nh.fractal_type = FastNoiseLite.FRACTAL_FBM
	nh.fractal_octaves = 3
	var ns := FastNoiseLite.new()
	ns.seed = 108
	ns.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ns.frequency = 0.09
	ns.fractal_type = FastNoiseLite.FRACTAL_FBM
	ns.fractal_octaves = 2
	var img := Image.create(MAP * FS, MAP * FS, false, Image.FORMAT_RGBAH)
	for y in MAP * FS:
		for x in MAP * FS:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / FS
			var h := nh.get_noise_2d(p.x, p.y) * 1.25
			var s := ns.get_noise_2d(p.x, p.y) * 0.8 + 0.25
			var o := ns.get_noise_2d(p.x + 100.0, p.y + 100.0) * 0.9 + 0.2
			img.set_pixel(x, y, Color(h, s, o, 1.0))
	var tex := ImageTexture.create_from_image(img)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/%s.gdshader" % (OS.get_environment("SH") if OS.get_environment("SH") != "" else "terrain"))
	mat.set_shader_parameter("field", tex)
	mat.set_shader_parameter("world_size", Vector2(MAP, MAP) * 32.0)
	mat.set_shader_parameter("tile", 32.0)
	mat.set_shader_parameter("rock_h", 0.12)
	mat.set_shader_parameter("mountain_h", 0.5)
	mat.set_shader_parameter("spice_t", 0.35)
	mat.set_shader_parameter("ore_t", 0.35)
	rect = ColorRect.new()
	rect.size = Vector2(MAP, MAP) * 32.0
	rect.material = mat
	root.add_child(rect)
	cam = Camera2D.new()
	root.add_child(cam)
	_run()
func _run() -> void:
	var tag := OS.get_environment("SH") if OS.get_environment("SH") != "" else "terrain"
	var spots := [["a", Vector2(1100, 1500), 1.3], ["b", Vector2(1100, 1500), 2.5], ["c", Vector2(2000, 900), 2.5], ["d", Vector2(1536, 1536), 0.6], ["e", Vector2(900, 700), 4.0]]
	for s in spots:
		cam.position = s[1]
		cam.zoom = Vector2(s[2], s[2])
		for i in 4:
			await process_frame
		var t0 := Time.get_ticks_usec()
		for i in 5:
			await RenderingServer.frame_post_draw
		print("%s %s : %.0f ms/image" % [tag, s[0], (Time.get_ticks_usec() - t0) / 5000.0])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/shots/lab_%s_%s.png" % [tag, s[0]])
	quit()
