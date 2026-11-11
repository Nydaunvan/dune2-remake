class_name Unit
extends Node2D

@export var speed := 110.0
@export var turn_speed := 8.0

var radius := 11.0
var path := PackedVector2Array()
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func follow(new_path: PackedVector2Array) -> void:
	path = new_path
	if path.size() > 1:
		path.remove_at(0) # inutile de revenir au centre de la case de départ


func _physics_process(delta: float) -> void:
	if path.is_empty():
		return
	var target := path[0]
	var desired := (target - position).angle()
	# Le char tourne d'abord, puis avance (sensation Dune II)
	rotation = lerp_angle(rotation, desired, clampf(turn_speed * delta, 0.0, 1.0))
	if absf(angle_difference(rotation, desired)) < 0.6:
		position = position.move_toward(target, speed * delta)
	if position.distance_to(target) < 1.0:
		path.remove_at(0)


func _draw() -> void:
	draw_rect(Rect2(-11, -9, 22, 18), Color("6f7f9e"))
	draw_rect(Rect2(-11, -9, 22, 18), Color.BLACK, false, 1.5)
	draw_circle(Vector2.ZERO, 5.0, Color("4a5875"))
	draw_line(Vector2.ZERO, Vector2(16, 0), Color.BLACK, 4.0)
	if selected:
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color(0.3, 1.0, 0.3), 1.5)
