extends Node2D
## Point rouge de débogage (bouche de tir).
func _draw() -> void:
	draw_circle(Vector2.ZERO, 1.8, Color(1, 0.1, 0.1))
