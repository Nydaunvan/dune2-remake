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
