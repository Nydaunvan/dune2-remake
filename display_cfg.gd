class_name DisplayCfg
extends RefCounted
## Réglage d'affichage : FPS illimités (pour les écrans à haut taux de rafraîchissement, 165 Hz…)
## ou synchronisation verticale. Mémorisé dans user://display.cfg.

const PATH := "user://display.cfg"


static func uncapped() -> bool:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return true
	return bool(c.get_value("display", "uncapped", true))


static func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED if uncapped() else DisplayServer.VSYNC_ENABLED)


static func toggle() -> bool:
	var c := ConfigFile.new()
	c.load(PATH)
	var v := not uncapped()
	c.set_value("display", "uncapped", v)
	c.save(PATH)
	apply()
	return v


static func label() -> String:
	return "FPS : ILLIMITÉS" if uncapped() else "FPS : SYNCHRO ÉCRAN"


## Gamma en jeu (carte et brouillard seulement, jamais le menu) : 0.5 par défaut (réglage choisi) ;
## plus petit = plus clair et plus doux, plus grand = plus sombre et plus contrasté.
static func gamma() -> float:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return 0.5
	return clampf(float(c.get_value("display", "game_gamma", 0.5)), 0.5, 1.5)


static func set_gamma(v: float) -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value("display", "game_gamma", clampf(v, 0.5, 1.5))
	c.save(PATH)


## Qualité du terrain : PHOTO (matériaux photographiques), HD (détails procéduraux fins) ou STANDARD (ancien rendu, léger).
const TERRAIN_MODES := ["photo", "hd", "standard"]


static func terrain_mode() -> String:
	var env := OS.get_environment("TERRAIN") # sert aux captures d'essai
	if env in TERRAIN_MODES:
		return env
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return "photo"
	var m := String(c.get_value("display", "terrain_mode", "photo"))
	return m if m in TERRAIN_MODES else "photo"


static func terrain_hd() -> bool:
	return terrain_mode() != "standard"


static func toggle_terrain() -> bool:
	var c := ConfigFile.new()
	c.load(PATH)
	var next: String = TERRAIN_MODES[(TERRAIN_MODES.find(terrain_mode()) + 1) % TERRAIN_MODES.size()]
	c.set_value("display", "terrain_mode", next)
	c.save(PATH)
	return next != "standard"


static func terrain_label() -> String:
	return "TERRAIN : " + terrain_mode().to_upper()


static func terrain_shader() -> Shader:
	match terrain_mode():
		"photo":
			return load("res://shaders/terrain_photo.gdshader")
		"hd":
			return load("res://shaders/terrain.gdshader")
	return load("res://shaders/terrain_classic.gdshader")


## Textures des matériaux du mode PHOTO (albédo+AO et normale+hauteur), liées au shader.
static func bind_terrain_textures(mat: ShaderMaterial) -> void:
	if terrain_mode() != "photo":
		return
	for n in ["sand_fine", "sand_crust", "rock_strata", "rock_dark", "spice", "ore"]:
		mat.set_shader_parameter(n + "_a", load("res://assets/terrain/%s_a.png" % n))
		mat.set_shader_parameter(n + "_n", load("res://assets/terrain/%s_n.png" % n))


## Véhicules ultra HD : sprites cuits en haute résolution avec détails de coque (appliqué à la prochaine partie, car cuit au chargement).
static func vehicles_hd() -> bool:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return true
	return bool(c.get_value("display", "vehicles_hd", true))


static func toggle_vehicles() -> bool:
	var c := ConfigFile.new()
	c.load(PATH)
	var v := not vehicles_hd()
	c.set_value("display", "vehicles_hd", v)
	c.save(PATH)
	return v


static func vehicles_label() -> String:
	return "VÉHICULES : HD (prochaine partie)" if vehicles_hd() else "VÉHICULES : STANDARD (prochaine partie)"
