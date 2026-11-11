class_name Building
extends Node2D
## Bâtiment dessiné par le code. `position` = coin haut-gauche de l'emprise.

const SHADOW := Color(0.12, 0.08, 0.30, 0.65)
const HULL_A := Color("8d94a8")
const HULL_B := Color("bcc2d2")
const DARK := Color("2e3446")
const TRIM := Color("e0a040")

var id := ""
var cell := Vector2i.ZERO
var cell_size := Vector2i.ONE
var tile := 32
var power := 0


func setup(p_id: String, p_cell: Vector2i, p_size: Vector2i, p_tile: int, p_power: int) -> void:
	id = p_id
	cell = p_cell
	cell_size = p_size
	tile = p_tile
	power = p_power
	position = Vector2(cell * tile)


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in cell_size.x:
		for dy in cell_size.y:
			out.append(cell + Vector2i(dx, dy))
	return out


func center_cell() -> Vector2:
	return Vector2(cell) + Vector2(cell_size) / 2.0


func _draw() -> void:
	var s := Vector2(cell_size * tile)
	# Ombre portée vers le bas-gauche
	draw_rect(Rect2(Vector2(-14, 8), s), SHADOW)
	var body := Rect2(Vector2(3, 3), s - Vector2(6, 6))
	draw_rect(body, HULL_A)
	draw_rect(Rect2(body.position, Vector2(body.size.x, body.size.y * 0.45)), HULL_B)
	draw_rect(body, DARK, false, 2.0)
	match id:
		"centrale":
			var a := Vector2(s.x * 0.3, s.y * 0.5)
			var b := Vector2(s.x * 0.7, s.y * 0.5)
			draw_circle(a, 13.0, HULL_B)
			draw_circle(b, 13.0, HULL_B)
			draw_arc(a, 13.0, 0.0, TAU, 24, TRIM, 2.0)
			draw_arc(b, 13.0, 0.0, TAU, 24, TRIM, 2.0)
		"raffinerie":
			draw_circle(Vector2(s.x * 0.28, s.y * 0.5), 20.0, HULL_B)
			draw_arc(Vector2(s.x * 0.28, s.y * 0.5), 20.0, 0.0, TAU, 32, TRIM, 2.5)
			draw_rect(Rect2(s.x * 0.55, s.y * 0.22, s.x * 0.36, s.y * 0.56), DARK)
			draw_rect(Rect2(s.x * 0.58, s.y * 0.30, s.x * 0.30, s.y * 0.40), TRIM.darkened(0.3))
		"usine":
			for i in 4:
				draw_rect(Rect2(10 + i * 18, 10, 10, s.y - 20), HULL_A.darkened(0.15))
			draw_rect(Rect2(s.x - 26, 6, 12, 18), DARK)
			draw_rect(Rect2(8, s.y - 16, 30, 8), TRIM)
		_:
			# Chantier : tour centrale
			draw_circle(s / 2.0, 22.0, HULL_B)
			draw_arc(s / 2.0, 22.0, 0.0, TAU, 32, TRIM, 3.0)
			draw_circle(s / 2.0, 9.0, DARK)
			draw_rect(Rect2(6, s.y - 18, 34, 10), TRIM.darkened(0.2))
