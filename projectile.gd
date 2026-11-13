class_name Projectile
extends Node2D
## Projectile : file droit vers sa cible (à tête chercheuse légère), explose à l'impact.
## Les dégâts de zone (roquettes, ondes soniques) touchent aussi les unités alliées
## pour l'arme sonique.

var game
var weapon := "cannon"
var team := 0
var damage := 10.0
var target # Unit | Building | null
var aim := Vector2.ZERO
var shooter # pour la riposte
var control := false # tir de contrôle du Mirage
var speed := 600.0
var color := Color.WHITE
var life := 4.0


func setup(p_game, p_weapon: String, p_team: int, from: Vector2, p_target, p_damage: float,
		p_shooter, p_control := false) -> void:
	game = p_game
	weapon = p_weapon
	team = p_team
	position = from
	target = p_target
	damage = p_damage
	shooter = p_shooter
	control = p_control
	var wd: Dictionary = GameData.WEAPONS[weapon]
	speed = wd["speed"]
	color = Color(1.0, 0.4, 1.0) * 1.9 if control else wd["color"]
	aim = p_target.world_center()
	z_index = 12
	rotation = (aim - from).angle()


func _physics_process(delta: float) -> void:
	life -= delta
	if is_instance_valid(target) and target.alive:
		aim = target.world_center()
	var to := aim - position
	var step := speed * delta
	if to.length() <= step + 4.0 or life <= 0.0:
		# Le projectile atteint sa cible pendant cette image : on le place dessus avant l'impact.
		# (Sinon, à faible fréquence d'images, le tir « touchait » de trop loin et ne faisait aucun dégât.)
		if life > 0.0:
			position = aim
		_hit()
		return
	rotation = to.angle()
	position += to.normalized() * step
	queue_redraw()


func _hit() -> void:
	var wd: Dictionary = GameData.WEAPONS[weapon]
	var splash: float = wd["splash"]
	if splash > 0.0:
		_splash(splash)
	elif is_instance_valid(target) and target.alive and position.distance_to(target.world_center()) < target.radius_px() + 24.0:
		if control and target is Unit:
			target.convert_to(team, game.faction_color(team), 15.0)
		else:
			target.take_damage(damage, weapon, shooter)
	match weapon:
		"rocket":
			Fx.impact(game, position, Color(1.2, 0.6, 0.3), 5, 0.4)
		"sonic":
			Fx.impact(game, position, Color(0.5, 1.2, 1.6), 5, 0.4)
		"acid":
			Fx.impact(game, position, Color(0.5, 1.4, 0.6), 3, 0.28)
		"shard":
			Fx.impact(game, position, Color(1.1, 0.6, 1.8), 5, 0.34)
		_:
			Fx.impact(game, position, color, 2, 0.18)
	queue_free()


func _splash(radius: float) -> void:
	var friendly := weapon == "sonic" # l'onde sonique n'épargne personne
	for u in game.units.duplicate():
		if not is_instance_valid(u) or not u.alive:
			continue
		if not game.hostile(u.team, team) and not friendly:
			continue
		var d: float = u.position.distance_to(position) - u.radius
		if d < radius:
			u.take_damage(damage * (1.0 - 0.5 * clampf(d / radius, 0.0, 1.0)), weapon, shooter)
	for b in game.buildings.duplicate():
		if not is_instance_valid(b) or not b.alive or not game.hostile(b.team, team):
			continue
		var d: float = b.world_center().distance_to(position) - b.radius_px()
		if d < radius:
			b.take_damage(damage * (1.0 - 0.5 * clampf(d / radius, 0.0, 1.0)), weapon, shooter)
	var w = game.worm
	if w != null and is_instance_valid(w) and w.alive:
		var dw: float = w.world_center().distance_to(position) - w.radius_px()
		if dw < radius:
			w.take_damage(damage * (1.0 - 0.5 * clampf(dw / radius, 0.0, 1.0)), weapon, shooter)


func _draw() -> void:
	var l: float = GameData.WEAPONS[weapon]["len"]
	var halo := Color(color.r, color.g, color.b, 0.12)
	match weapon:
		"sonic":
			draw_arc(Vector2.ZERO, 6.0, -1.0, 1.0, 10, color, 3.0, true)
			draw_arc(Vector2.ZERO, 11.0, -0.8, 0.8, 10, halo, 3.0, true)
		"shard":
			# éclat de cristal : losange effilé
			var pts := PackedVector2Array([Vector2(7, 0), Vector2(0, -3.2), Vector2(-9, 0), Vector2(0, 3.2)])
			draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(0, -5.5), Vector2(-12, 0), Vector2(0, 5.5)]), halo)
			draw_colored_polygon(pts, color)
			draw_circle(Vector2(2, 0), 1.6, Color(2.0, 1.8, 2.2))
		"acid":
			draw_circle(Vector2.ZERO, 5.0, halo)
			draw_circle(Vector2.ZERO, 3.0, color)
		"rocket":
			draw_line(Vector2(-l, 0), Vector2.ZERO, halo, 7.0, true)
			draw_line(Vector2(-l, 0), Vector2.ZERO, color, 3.5, true)
			draw_circle(Vector2.ZERO, 3.0, Color(2.2, 2.0, 1.5))
		_:
			draw_line(Vector2(-l, 0), Vector2.ZERO, halo, 6.0, true)
			draw_line(Vector2(-l, 0), Vector2.ZERO, color, 2.5, true)
