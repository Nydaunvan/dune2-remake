class_name Worm
extends Node2D
## Ver géant des sables. Il ne se déplace que sur le sable et dans les champs d'épice ou de minerai
## (jamais sur la roche), file sous la surface en soulevant une bosse, puis jaillit, se
## projette sur sa proie, l'engloutit et replonge. Maximum 2 attaques par apparition.
##
## Phases : approach (sous le sable) -> erupt (sortie) -> lunge (bond) -> swallow (engloutit)
##          -> retract (replonge) -> [approach | fin]

signal finished

const SPEED := 92.0          # lent : le joueur a le temps de réagir
const BITE_RADIUS := 64.0
const MAX_BITES := 2
const HEIGHT := 190.0        # hauteur du corps dressé (px)
const HEAD_R := 64.0

var game # le nœud principal (main.gd)
var target # Unit ou null (peut être libéré en cours de route)
var phase := "approach"
var emerge := 0.0   # 0 = sous le sable, 1 = dressé
var lean := 0.0     # inclinaison du corps vers la proie (0..1)
var open := 0.0     # ouverture de la gueule (0..1)
var bites := 0
var lean_dir := Vector2.RIGHT
var _t := 0.0
var _pt := 0.0      # temps passé dans la phase courante
var _path := PackedVector2Array()
var _path_t := 0.0
var _victims: Array = []
var _bit := false
var _trail: CPUParticles2D
var _seed := randf() * 100.0
# Points de vie : chaque ver est un individu qui garde ses blessures d'une apparition à l'autre
var hp := 8000.0
var max_hp := 8000.0
var idx := 0          # numéro de l'individu dans game.worm_roster
var tint := 0.0       # teinte propre à l'individu (plus clair / plus sombre)
var alive := true
var dying := false
var _hp_show := 0.0   # affichage de la jauge après un coup


func setup(p_game, start: Vector2, p_target, p_idx := 0, p_hp := 8000.0, p_max := 8000.0, p_tint := 0.0) -> void:
	game = p_game
	idx = p_idx
	hp = p_hp
	max_hp = p_max
	tint = p_tint
	position = start
	target = p_target
	z_index = 5
	_trail = Fx.make_dust(Color(0.78, 0.55, 0.42), 30, 1.6, 0.9)
	_trail.emitting = true
	add_child(_trail)


func _set_phase(p: String) -> void:
	phase = p
	_pt = 0.0


func _process(delta: float) -> void:
	_t += delta
	_pt += delta
	_hp_show = maxf(0.0, _hp_show - delta)
	# Abattu : il renonce à toute nouvelle attaque et replonge
	if dying and (phase == "approach" or phase == "erupt" or (phase == "lunge" and not _bit)):
		_trail.emitting = false
		_set_phase("retract")
	match phase:
		"approach":
			_approach(delta)
		"erupt":
			_erupt(delta)
		"lunge":
			_lunge(delta)
		"swallow":
			_swallow(delta)
		"retract":
			_retract(delta)
	queue_redraw()


# --- Cible (les unités peuvent tirer sur le ver, même enfoui) -------------------------------------

func world_center() -> Vector2:
	return position + Vector2(0, -emerge * 70.0)


func radius_px() -> float:
	return 44.0 + emerge * 22.0


func take_damage(raw: float, wpn: String, attacker = null) -> void:
	if not alive:
		return
	var dm: float = raw * GameData.mult(wpn, "heavy")
	hp -= dm
	_hp_show = 3.0
	if is_instance_valid(attacker) and attacker is Unit and attacker.team == 0:
		game.stats.dmg_dealt += minf(dm, hp + dm)
	if hp <= 0.0:
		hp = 0.0
		alive = false
		dying = true
		if is_instance_valid(attacker) and attacker is Unit and attacker.alive:
			attacker.add_kill()
			if attacker.team == 0:
				game.stats.worm_kills += 1
		game.ui.toast("Un ver géant a été abattu !", GameData.GREEN)
		game.shake(8.0, 0.8)
		Fx.burst(game, position, Color(0.85, 0.6, 0.45), 48, 1.8)


func _valid(u) -> bool:
	return u != null and is_instance_valid(u) and u.alive and not u.eaten and not u.convoy and game.worm_ok(u.position)


# --- Phases -------------------------------------------------------------------

func _approach(delta: float) -> void:
	if not _valid(target):
		target = game.nearest_sand_unit(position, 420.0)
		_path = PackedVector2Array()
		if target == null:
			_set_phase("retract")
			_trail.emitting = false
			return
	if position.distance_to(target.position) < 42.0:
		lean_dir = (target.position - position).normalized()
		_trail.emitting = false
		_set_phase("erupt")
		game.shake(5.0, 0.5)
		Fx.burst(game, position, Color(0.8, 0.55, 0.4), 36, 1.4)
		return
	_path_t -= delta
	if _path.is_empty() or _path_t <= 0.0:
		_path_t = 1.2
		_path = game.worm_path(position, target.position)
		if _path.is_empty():
			target = null # inaccessible par le sable : on en cherche une autre ou on abandonne
			return
	var step := SPEED * delta
	while step > 0.0 and not _path.is_empty():
		var to: Vector2 = _path[0] - position
		if to.length() <= step:
			position = _path[0]
			step -= to.length()
			_path.remove_at(0)
		else:
			position += to.normalized() * step
			step = 0.0


func _erupt(delta: float) -> void:
	emerge = move_toward(emerge, 1.0, delta * 0.95)
	if is_instance_valid(target) and target.alive:
		lean_dir = lean_dir.lerp((target.position - position).normalized(), 0.1).normalized()
	if emerge >= 1.0:
		_bit = false
		_set_phase("lunge")


func _lunge(delta: float) -> void:
	lean = move_toward(lean, 1.0, delta * 3.2)
	open = move_toward(open, 1.0, delta * 3.4)
	if lean >= 1.0 and not _bit:
		_bit = true
		bites += 1
		game.stats.worm_bites += 1
		_victims.clear()
		var mouth := position + head_offset()
		for u in game.units.duplicate():
			if not u.alive or u.eaten or u.convoy:
				continue # le convoi de mission est hors de portée des vers
			var near_foot: bool = game.worm_ok(u.position) and u.position.distance_to(position) < BITE_RADIUS + 28.0
			if near_foot or u.position.distance_to(mouth) < BITE_RADIUS * 0.7:
				_victims.append(u)
		for u in _victims:
			u.swallow(mouth + Vector2(0, 4), 0.7)
		game.shake(10.0, 0.7)
		Fx.burst(game, position, Color(0.85, 0.6, 0.45), 44, 1.7)
		_set_phase("swallow")


func _swallow(delta: float) -> void:
	# la gueule se referme en mâchant
	open = 0.35 + 0.35 * absf(sin(_pt * 9.0)) * (1.0 - clampf(_pt / 0.9, 0.0, 1.0)) + 0.0
	if _pt > 0.9:
		var eaten := 0
		for u in _victims:
			if is_instance_valid(u) and u.alive:
				eaten += 1
		if eaten > 0:
			game.ui.toast("Un ver a englouti %d unité(s) !" % eaten, GameData.RED)
		_victims.clear()
		_set_phase("retract")


func _retract(delta: float) -> void:
	open = move_toward(open, 0.0, delta * 2.0)
	lean = move_toward(lean, 0.0, delta * 1.2)
	emerge = move_toward(emerge, 0.0, delta * 0.9)
	if emerge <= 0.0:
		var next = null
		if bites < MAX_BITES and not dying:
			next = game.nearest_sand_unit(position, 320.0)
		if next != null and bites > 0:
			target = next
			_path = PackedVector2Array()
			_trail.emitting = true
			_set_phase("approach")
		else:
			finished.emit()
			queue_free()


# --- Géométrie ----------------------------------------------------------------

## Position (écran, par rapport au pied du ver) du centre de la gueule.
func head_offset() -> Vector2:
	var h := HEIGHT * ease(emerge, 0.4)
	var reach := lean * 78.0
	return Vector2(lean_dir.x * reach, -h * (1.0 - 0.28 * lean) + lean_dir.y * reach * 0.5)


func _bez(a: Vector2, c: Vector2, b: Vector2, u: float) -> Vector2:
	return a.lerp(c, u).lerp(c.lerp(b, u), u)


# --- Dessin -------------------------------------------------------------------

func _draw() -> void:
	if phase == "approach":
		_draw_bulge()
		_draw_hp(Vector2(0, -44))
		return
	if emerge <= 0.001:
		return
	var e := ease(emerge, 0.4)
	_draw_crater(e)
	_draw_body(e)
	_draw_head(e)
	_draw_hp(head_offset() + Vector2(0, -HEAD_R * 0.9 - 22.0))


## Jauge de vie au-dessus du ver : visible dès qu'il est blessé ou juste après un coup.
func _draw_hp(at: Vector2) -> void:
	if not alive or (hp >= max_hp - 0.5 and _hp_show <= 0.0):
		return
	var f := clampf(hp / max_hp, 0.0, 1.0)
	var w := 120.0
	var r := Rect2(at + Vector2(-w * 0.5, 0), Vector2(w, 9))
	var col := Color("5dff9a").lerp(Color("ffb340"), clampf((1.0 - f) * 2.0, 0.0, 1.0)).lerp(Color("ff4a3a"), clampf((0.5 - f) * 2.0, 0.0, 1.0))
	draw_rect(r.grow(2.0), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(r.position, Vector2(w * f, r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(w * f, 2.5)), Color(1, 1, 1, 0.3))
	draw_rect(r.grow(2.0), Color("e2b24a"), false, 1.5)


## Renflement du sable qui avance, avec ondes et petites crêtes.
func _draw_bulge() -> void:
	var s := 0.5 + 0.5 * sin(_t * 5.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 26.0, Color(0.0, 0.0, 0.0, 0.14))
	for i in 3:
		var k := fmod(_t * 0.8 + i / 3.0, 1.0)
		draw_arc(Vector2.ZERO, 22.0 + k * 46.0, 0.0, TAU, 40, Color(1.0, 0.85, 0.7, 0.28 * (1.0 - k)), 2.5, true)
	draw_arc(Vector2.ZERO, 18.0 + s * 3.0, PI * 1.05, PI * 1.95, 18, Color(1.0, 0.9, 0.75, 0.4), 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_crater(e: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	var r := 92.0 * minf(e * 1.6, 1.0)
	draw_circle(Vector2.ZERO, r * 1.18, Color(0.55, 0.32, 0.22, 0.45))      # sable soulevé
	draw_circle(Vector2.ZERO, r, Color(0.16, 0.07, 0.06, 0.9))              # fosse
	draw_circle(Vector2.ZERO, r * 0.62, Color(0.05, 0.015, 0.02, 0.95))
	for i in 3:
		var k := fmod(_t * 0.7 + i / 3.0, 1.0)
		draw_arc(Vector2.ZERO, r * (1.1 + k * 0.9), 0.0, TAU, 48, Color(1.0, 0.85, 0.7, 0.30 * (1.0 - k) * e), 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Corps annelé : anneaux empilés du sol jusqu'à la tête, courbé vers la proie.
func _draw_body(e: float) -> void:
	var head := head_offset()
	var ctrl := Vector2(head.x * 0.15 + sin(_t * 1.3 + _seed) * 6.0, head.y * 0.62)
	var n := 22
	for k in n:
		var u := float(k) / n
		var p := _bez(Vector2.ZERO, ctrl, head, u)
		p.x += sin(_t * 2.0 + u * 5.0 + _seed) * 3.0 * u * e
		var r := lerpf(58.0, 46.0, u) * (0.9 + 0.1 * sin(u * 40.0))
		_ring(p, r, u, k)


func _ring(p: Vector2, r: float, u: float, k: int) -> void:
	draw_set_transform(p, 0.0, Vector2(1.0, 0.55))
	var band := 0.5 + 0.5 * sin(float(k) * 2.2)
	var base := Color("5b3a2e").lerp(Color("7a523f"), band * 0.6)
	base = base.lerp(Color("9b6f55"), u * 0.25)
	base = base.lightened(tint) if tint >= 0.0 else base.darkened(-tint)
	draw_circle(Vector2.ZERO, r, Color("2a150f"))                       # contour sombre
	draw_circle(Vector2.ZERO, r * 0.94, base)
	draw_circle(Vector2(r * 0.22, -r * 0.1), r * 0.6, base.lightened(0.14))  # lumière du couchant (à droite)
	if k % 3 == 0:
		draw_arc(Vector2.ZERO, r * 0.97, 0.15, PI - 0.15, 18, Color("c9a27f", 0.55), 2.0, true)  # plaque chitineuse
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_head(e: float) -> void:
	var c := head_offset()
	var squash := lerpf(0.55, 0.92, clampf(open * 0.6 + lean * 0.5, 0.0, 1.0))
	var r := HEAD_R * (0.85 + 0.15 * e)
	draw_set_transform(c, 0.0, Vector2(1.0, squash))
	# bourrelet extérieur
	draw_circle(Vector2.ZERO, r * 1.06, Color("2a150f"))
	var hc := Color("7a523f")
	hc = hc.lightened(tint) if tint >= 0.0 else hc.darkened(-tint)
	draw_circle(Vector2.ZERO, r, hc)
	draw_circle(Vector2(r * 0.12, -r * 0.08), r * 0.78, hc.lightened(0.1))
	# gueule : gorge sombre qui rougeoie
	var m := r * (0.55 + 0.30 * open)
	draw_circle(Vector2.ZERO, m, Color("1a0509"))
	draw_circle(Vector2.ZERO, m * 0.62, Color("3a0710"))
	var glow := 0.5 + 0.5 * sin(_t * 6.0)
	draw_circle(Vector2.ZERO, m * 0.30, Color(2.0, 0.5, 0.2, 0.55 + 0.3 * glow))
	# spirale dans la gorge
	for i in 4:
		var a := _t * 1.8 + i * TAU / 4.0
		draw_arc(Vector2.ZERO, m * (0.35 + 0.1 * i), a, a + 1.0, 8, Color(0.9, 0.3, 0.2, 0.35), 2.0, true)
	# trois couronnes de dents, tournant lentement en sens inverse
	var rings := [[22, 0.96, 0.60, 0.075, 0.5], [16, 0.80, 0.46, 0.07, -0.7], [10, 0.62, 0.34, 0.06, 0.9]]
	for ring in rings:
		var cnt: int = ring[0]
		for i in cnt:
			var a := TAU * i / cnt + _t * float(ring[4]) * 0.25 + (0.0 if ring[4] > 0 else 0.15)
			var nrm := Vector2.from_angle(a)
			var tg := Vector2.from_angle(a + PI / 2.0)
			var rb: float = m * float(ring[1]) * 1.15
			var rt: float = m * float(ring[2])
			var w: float = r * float(ring[3])
			draw_colored_polygon(PackedVector2Array([nrm * rb + tg * w, nrm * rt, nrm * rb - tg * w]), Color("efe3c8"))
			draw_polyline(PackedVector2Array([nrm * rb + tg * w, nrm * rt, nrm * rb - tg * w]), Color("a8926f"), 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# sable qui ruisselle de la tête
	if emerge > 0.2:
		for i in 6:
			var k := fmod(_t * 1.3 + i * 0.37, 1.0)
			draw_circle(c + Vector2(sin(i * 3.1 + _seed) * r * 0.8, r * 0.3 + k * 60.0), 2.0 * (1.0 - k) + 0.5, Color(0.9, 0.7, 0.5, 0.6 * (1.0 - k)))
