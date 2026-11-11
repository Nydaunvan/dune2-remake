class_name Worm
extends Node2D
## Ver géant : se déplace sous le sable en laissant une traînée de poussière,
## surgit pour dévorer les unités posées sur le sable (jamais sur la roche),
## puis replonge. Maximum 2 morsures par apparition.

signal finished

const SPEED := 150.0
const BITE_RADIUS := 64.0
const MAX_BITES := 2

var game # le nœud principal (main.gd)
var target # Unit ou null (peut être libéré en cours de route)
var phase := "approach" # approach | strike | dive
var emerge := 0.0       # 0 = sous le sable, 1 = gueule grande ouverte
var bites := 0
var _t := 0.0
var _bit_this_strike := false
var _trail: CPUParticles2D


func setup(p_game, start: Vector2, p_target) -> void:
	game = p_game
	position = start
	target = p_target
	z_index = 5
	_trail = Fx.make_dust(Color(0.78, 0.55, 0.42), 26, 1.5, 0.8)
	_trail.emitting = true
	add_child(_trail)


func _process(delta: float) -> void:
	_t += delta
	match phase:
		"approach":
			_approach(delta)
		"strike":
			_strike(delta)
		"dive":
			emerge = move_toward(emerge, 0.0, delta * 1.6)
			if emerge <= 0.0:
				finished.emit()
				queue_free()
	queue_redraw()


func _valid(u) -> bool:
	return u != null and is_instance_valid(u) and u.alive and game.is_sand_at(u.position)


func _approach(delta: float) -> void:
	if not _valid(target):
		target = game.nearest_sand_unit(position, 420.0)
		if target == null:
			phase = "dive"
			return
	var to: Vector2 = target.position - position
	if to.length() < 42.0:
		phase = "strike"
		_bit_this_strike = false
		_trail.emitting = false
		return
	position += to.normalized() * SPEED * delta


func _strike(delta: float) -> void:
	emerge = move_toward(emerge, 1.0, delta * 1.7)
	if emerge >= 1.0 and not _bit_this_strike:
		_bit_this_strike = true
		bites += 1
		var eaten := 0
		for u in game.units.duplicate():
			if u.position.distance_to(position) < BITE_RADIUS and game.is_sand_at(u.position):
				u.devour()
				eaten += 1
		game.shake(9.0, 0.7)
		Fx.burst(game, position, Color(0.8, 0.55, 0.4), 40, 1.6)
		if eaten > 0:
			game.ui.toast("Un ver a dévoré %d unité(s) !" % eaten, GameData.RED)
		_t = 0.0
	elif _bit_this_strike and _t > 0.9:
		var next = game.nearest_sand_unit(position, 320.0)
		if bites < MAX_BITES and next != null:
			target = next
			phase = "approach"
			_trail.emitting = true
			emerge = 0.0
		else:
			phase = "dive"


func _draw() -> void:
	if phase == "approach":
		# renflement du sable au-dessus du ver
		draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.10))
		draw_arc(Vector2.ZERO, 22.0 + sin(_t * 8.0) * 3.0, 0.0, TAU, 32, Color(1, 0.85, 0.7, 0.18), 2.0, true)
		return
	if emerge <= 0.0:
		return
	var e := ease(emerge, 0.35)
	var r := 46.0 * e
	# Ondes dans le sable
	for i in 3:
		var k := fmod(_t * 0.9 + i / 3.0, 1.0)
		draw_arc(Vector2.ZERO, r * (1.1 + k * 1.1), 0.0, TAU, 48,
				Color(1.0, 0.85, 0.7, 0.3 * (1.0 - k) * e), 3.0, true)
	# Tête et dents
	draw_circle(Vector2.ZERO, r, Color("5b3a2e"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color("2e1a14"), 3.0, true)
	var teeth := 16
	for i in teeth:
		var a := TAU * i / teeth + _t * 0.6
		var n := Vector2.from_angle(a)
		var tang := Vector2.from_angle(a + PI / 2.0)
		var base := n * r * 0.86
		var tip := n * r * 0.46
		draw_colored_polygon(PackedVector2Array([
			base + tang * r * 0.09, tip, base - tang * r * 0.09]), Color("eadfc6"))
	draw_circle(Vector2.ZERO, r * 0.42, Color("1a0509"))
	draw_circle(Vector2.ZERO, r * 0.24, Color(2.0, 0.5, 0.2, 0.85))
