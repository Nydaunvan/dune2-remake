class_name Building
extends Node2D
## Bâtiment dessiné par le code. `position` = coin haut-gauche de l'emprise.

const SHADOW := Color(0.12, 0.08, 0.30, 0.65)
const HULL_A := Color("8d94a8")
const HULL_B := Color("bcc2d2")
const DARK := Color("2e3446")

var id := ""
var cell := Vector2i.ZERO
var cell_size := Vector2i.ONE
var tile := 32
var power := 0
var trim := Color("e0a040") # couleur de faction

# Combat
var game
var team := 0
var alive := true
var hp := 500.0
var max_hp := 500.0
var armor := "building"
var weapon := ""
var dps := 0.0
var w_range := 0.0 # px
var cooldown := 0.0
var aim := 0.0
var _scan := 0.0
var _target


func setup(p_id: String, p_cell: Vector2i, p_size: Vector2i, p_tile: int,
		p_power: int, p_trim: Color) -> void:
	id = p_id
	cell = p_cell
	cell_size = p_size
	tile = p_tile
	power = p_power
	trim = p_trim
	position = Vector2(cell * tile)


## Branche le bâtiment à la partie : équipe, points de vie, arme éventuelle.
func init_combat(p_game, p_team: int) -> void:
	game = p_game
	team = p_team
	var d := GameData.def(id)
	max_hp = float(d.get("hp", 500))
	hp = max_hp
	armor = d.get("armor", "building")
	weapon = d.get("weapon", "")
	dps = float(d.get("dps", 0))
	w_range = float(d.get("range", 0)) * tile
	if weapon == "":
		set_physics_process(false)


func world_center() -> Vector2:
	return position + Vector2(cell_size * tile) / 2.0


func radius_px() -> float:
	return maxf(cell_size.x, cell_size.y) * tile * 0.5


func take_damage(raw: float, wpn: String, attacker = null) -> void:
	if not alive:
		return
	hp -= raw * GameData.mult(wpn, armor)
	queue_redraw()
	game.notify_attack(self)
	if weapon != "" and _target == null and is_instance_valid(attacker) and attacker.alive:
		_target = attacker
	if hp <= 0.0:
		alive = false
		Fx.explosion(game, world_center(), 2.2)
		Fx.explosion(game, world_center() + Vector2(10, -8), 1.5)
		game.shake(7.0, 0.5)
		game.on_building_destroyed(self)
		queue_free()


func _physics_process(delta: float) -> void:
	if not alive or weapon == "":
		return
	cooldown = maxf(0.0, cooldown - delta)
	_scan -= delta
	if not _valid(_target) or world_center().distance_to(_target.world_center()) - float(_target.radius_px()) > w_range + 40.0:
		_target = null
		if _scan <= 0.0:
			_scan = 0.4
			_target = game.find_enemy(team, world_center(), w_range + radius_px(), true)
	if _target == null:
		return
	var tp: Vector2 = _target.world_center()
	var want := (tp - world_center()).angle()
	aim = lerp_angle(aim, want, clampf(8.0 * delta, 0.0, 1.0))
	queue_redraw()
	if cooldown <= 0.0 and absf(angle_difference(aim, want)) < 0.2:
		var wd: Dictionary = GameData.WEAPONS[weapon]
		cooldown = wd["cd"]
		game.fire(self, _target, weapon, dps * float(wd["cd"]), world_center() + Vector2.from_angle(aim) * 22.0)


func _valid(t) -> bool:
	return t != null and is_instance_valid(t) and t.alive


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
			draw_arc(a, 13.0, 0.0, TAU, 24, trim, 2.0, true)
			draw_arc(b, 13.0, 0.0, TAU, 24, trim, 2.0, true)
		"raffinerie":
			draw_circle(Vector2(s.x * 0.28, s.y * 0.5), 20.0, HULL_B)
			draw_arc(Vector2(s.x * 0.28, s.y * 0.5), 20.0, 0.0, TAU, 32, trim, 2.5, true)
			draw_rect(Rect2(s.x * 0.55, s.y * 0.22, s.x * 0.36, s.y * 0.56), DARK)
			draw_rect(Rect2(s.x * 0.58, s.y * 0.30, s.x * 0.30, s.y * 0.40), Color("e2762a").darkened(0.2))
		"fonderie":
			draw_rect(Rect2(10, 10, s.x * 0.5, s.y - 20), HULL_B.darkened(0.15))
			draw_rect(Rect2(s.x * 0.62, 8, 12, 22), DARK)
			draw_rect(Rect2(s.x * 0.80, 8, 12, 22), DARK)
			draw_rect(Rect2(s.x * 0.58, s.y - 22, s.x * 0.34, 10), Color(1.9, 0.7, 0.25))
		"usine":
			for i in 4:
				draw_rect(Rect2(10 + i * 18, 10, 10, s.y - 20), HULL_A.darkened(0.15))
			draw_rect(Rect2(s.x - 26, 6, 12, 18), DARK)
			draw_rect(Rect2(8, s.y - 16, 30, 8), trim)
		"tourelle":
			var c := s / 2.0
			draw_circle(c, 20.0, DARK)
			draw_arc(c, 20.0, 0.0, TAU, 32, trim, 2.5, true)
			draw_circle(c, 12.0, HULL_B)
			draw_line(c, c + Vector2.from_angle(aim) * 30.0, DARK, 9.0, true)
			draw_line(c, c + Vector2.from_angle(aim) * 30.0, trim, 4.0, true)
			draw_circle(c + Vector2.from_angle(aim) * 30.0, 3.0, Color(1.9, 1.3, 0.4))
		_:
			# Chantier : tour centrale
			draw_circle(s / 2.0, 22.0, HULL_B)
			draw_arc(s / 2.0, 22.0, 0.0, TAU, 32, trim, 3.0, true)
			draw_circle(s / 2.0, 9.0, DARK)
			draw_rect(Rect2(6, s.y - 18, 34, 10), trim.darkened(0.2))
	if hp < max_hp:
		var w := s.x - 8.0
		draw_rect(Rect2(4, -9, w, 5), Color(0, 0, 0, 0.65))
		draw_rect(Rect2(4, -9, w * clampf(hp / max_hp, 0.0, 1.0), 5),
				GameData.GREEN if team == 0 else GameData.RED)
