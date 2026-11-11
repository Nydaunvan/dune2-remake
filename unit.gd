class_name Unit
extends Node2D
## Unité : déplacement, et pour les récolteurs / mineurs une boucle de travail
## automatique (chercher une ressource → récolter → rapporter → recommencer).

var id := ""
var role := "combat" # combat | harvester | miner | mcv | convoy
var guard := false   # garde immobile (avant-poste, embuscade) : n'entre pas dans les vagues de l'IA
var convoy := false  # unité de convoi de mission
var faction_color := Color("4aa8ff")
var game # le nœud principal (main.gd)

var speed := 110.0
var turn_speed := 8.0
var radius := 11.0
var hp := 100.0
var max_hp := 100.0
var alive := true

# Combat
var team := 0
var armor := "medium"
var weapon := ""
var dps := 0.0
var w_range := 0.0        # portée en px
var cooldown := 0.0
var target                # Unit | Building | null
var forced := false       # cible imposée par le joueur : on ne la lâche pas
var amove_goal := Vector2i(-1, -1)
var control_timer := 0.0
var special_t := 0.0
var _orig_team := 0
var _orig_color := Color.WHITE
var _scan_t := 0.0
var kills := 0
var rank := 0
var base_max_hp := 100.0
var vision := 7
var seen := true # visible actuellement par le joueur (brouillard de guerre)
var _frame_idx := -1
var _sprite_ready := false
var _repath := 0.0

var cargo := 0.0
var cargo_cap := 0.0
var cargo_kind := "" # "spice" | "ore"
var harvest_rate := 100.0

var state := "idle" # idle | move | amove | attack | seek | harvest | return | flee
var path := PackedVector2Array()
var work_cell := Vector2i(-1, -1)
var _seek_started := false
var _retry := 0.0
var _flee_timer := 0.0
var _dust: CPUParticles2D
var _work_fx: CPUParticles2D

var selected := false:
	set(value):
		selected = value
		queue_redraw()


func setup(p_id: String, p_game, p_color: Color) -> void:
	id = p_id
	game = p_game
	faction_color = p_color
	var d := GameData.def(id)
	role = d.get("role", "combat")
	speed = d.get("speed", 100.0)
	max_hp = float(d.get("hp", 200))
	hp = max_hp
	base_max_hp = max_hp
	vision = int(d.get("vision", 6 if is_worker() else GameData.DEFAULT_VISION))
	cargo_cap = d.get("capacity", 0.0)
	harvest_rate = d.get("rate", 100.0)
	cargo_kind = d.get("resource", "")
	radius = 14.0 if (is_worker() or role == "mcv" or role == "convoy") else 11.0
	armor = d.get("armor", "medium")
	weapon = d.get("weapon", "")
	dps = float(d.get("dps", 0))
	w_range = float(d.get("range", 0)) * 32.0
	_scan_t = randf() * 0.4 # évite que toutes les unités scrutent à la même image
	_dust = Fx.make_dust(Color(0.85, 0.65, 0.5), 10, 0.9, 0.35)
	add_child(_dust)
	if is_worker():
		var c := Color(0.95, 0.5, 0.15) if cargo_kind == "spice" else Color(0.6, 0.75, 1.0)
		_work_fx = Fx.make_dust(c, 14, 0.7, 0.3)
		add_child(_work_fx)
		state = "seek"


func is_worker() -> bool:
	return role == "harvester" or role == "miner"


# --- Ordres -------------------------------------------------------------------

## Ordre du joueur : va quelque part, puis reprend le travail (ouvriers).
func order_path(new_path: PackedVector2Array) -> void:
	target = null
	forced = false
	amove_goal = Vector2i(-1, -1)
	follow(new_path)
	state = "move"
	if _work_fx != null:
		_work_fx.emitting = false


func follow(new_path: PackedVector2Array) -> void:
	path = new_path
	if path.size() > 1:
		path.remove_at(0) # inutile de revenir au centre de la case de départ


func stop() -> void:
	target = null
	forced = false
	amove_goal = Vector2i(-1, -1)
	path = PackedVector2Array()
	state = "idle" # un ordre de déplacement relance ensuite le travail
	_seek_started = false
	if _work_fx != null:
		_work_fx.emitting = false


## Alerte ver : fuit vers la roche la plus proche (ouvriers).
func flee() -> void:
	if not is_worker() or not alive:
		return
	var cell: Vector2i = game.find_safe_cell(game.world_to_cell(position))
	if cell.x < 0:
		return
	follow(game.path_to(position, cell))
	state = "flee"
	_flee_timer = 22.0
	if _work_fx != null:
		_work_fx.emitting = false


## Ordre d'attaque du joueur : poursuit et détruit la cible.
func order_attack(t) -> void:
	if weapon == "" or not alive:
		return
	amove_goal = Vector2i(-1, -1)
	_set_target(t, true)


## Attaque en mouvement : avance vers la case, engage tout ce qui croise sa route.
func order_amove(goal: Vector2i) -> void:
	if weapon == "" or not alive:
		return
	target = null
	forced = false
	amove_goal = goal
	_go_amove()


func _go_amove() -> void:
	var p: PackedVector2Array = game.path_to(position, amove_goal)
	if p.is_empty():
		amove_goal = Vector2i(-1, -1)
		state = "idle"
		return
	follow(p)
	state = "amove"


func _set_target(t, p_forced: bool) -> void:
	target = t
	forced = p_forced
	state = "attack"
	path = PackedVector2Array()
	_repath = 0.0


func _valid(t) -> bool:
	return t != null and is_instance_valid(t) and t.alive


func world_center() -> Vector2:
	return position


func radius_px() -> float:
	return radius


## Dégâts reçus : blindage et type d'arme comptent. Riposte ou fuite.
func take_damage(raw: float, wpn: String, attacker = null) -> void:
	if not alive:
		return
	hp -= raw * GameData.mult(wpn, armor)
	queue_redraw()
	if hp <= 0.0:
		if is_instance_valid(attacker) and attacker is Unit and attacker.alive and attacker.team != team:
			attacker.add_kill()
		_die()
		return
	if _valid(attacker) and attacker.team != team:
		if is_worker():
			if state != "flee":
				flee()
		elif weapon != "" and not forced and (state == "idle" or state == "amove" or (state == "attack" and not _valid(target))):
			_set_target(attacker, false)


## Éliminations -> rang (Recrue, Vétéran, Élite) : +15 % de dégâts et de PV par rang.
func add_kill() -> void:
	kills += 1
	var r := 0
	for i in GameData.RANKS.size():
		if kills >= int(GameData.RANKS[i]["kills"]):
			r = i
	if r > rank:
		rank = r
		var old := max_hp
		max_hp = base_max_hp * (1.0 + GameData.RANK_HP * rank)
		hp += max_hp - old
		Fx.burst(game, position, GameData.GOLD, 14, 0.9)
		if team == 0:
			game.sfx.play_ui("rank", -4.0)
			game.popup(position, "★ %s" % GameData.RANKS[rank]["name"], GameData.GOLD)
	queue_redraw()


func _die() -> void:
	if not alive:
		return
	alive = false
	Fx.explosion(game, position, 1.0)
	game.on_unit_lost(self)
	queue_free()


## Prise de contrôle temporaire (Mirage).
func convert_to(new_team: int, new_color: Color, duration: float) -> void:
	if control_timer > 0.0 or is_worker() or new_team == team:
		return
	_orig_team = team
	_orig_color = faction_color
	team = new_team
	faction_color = new_color
	control_timer = duration
	target = null
	forced = false
	amove_goal = Vector2i(-1, -1)
	path = PackedVector2Array()
	state = "idle"
	if team != 0 and selected:
		selected = false
		game.selected.erase(self)
	Fx.burst(game, position, Color(1.9, 0.4, 2.0), 16, 1.0)
	game.sfx.play("control", position)
	queue_redraw()


func _revert_control() -> void:
	team = _orig_team
	faction_color = _orig_color
	target = null
	state = "idle"
	path = PackedVector2Array()
	Fx.burst(game, position, Color(1.9, 0.4, 2.0), 10, 0.8)
	queue_redraw()


func devour() -> void:
	if not alive:
		return
	alive = false
	Fx.burst(game, position, Color(0.8, 0.55, 0.4), 22, 1.0)
	game.on_unit_lost(self)
	queue_free()


# --- Boucle -------------------------------------------------------------------

func _sprite_key() -> String:
	return "%s|%s" % [id, game.faction_id_of(team)]


func _process(_delta: float) -> void:
	if selected:
		queue_redraw() # anneau de sélection pulsé
	var bank: SpriteBank = game.bank
	if bank != null:
		# Les modèles 3D sont cuits une image par angle : on redessine quand l'angle change
		var idx := bank.frame_index(_sprite_key(), rotation)
		if idx != _frame_idx or (not _sprite_ready and bank.has(_sprite_key())):
			_frame_idx = idx
			_sprite_ready = bank.has(_sprite_key())
			queue_redraw()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_work(delta)
	_combat(delta)
	_move(delta)
	_dust.emitting = not path.is_empty() and game.is_sand_at(position)


func _combat(delta: float) -> void:
	if role != "combat":
		return
	cooldown = maxf(0.0, cooldown - delta)
	special_t = maxf(0.0, special_t - delta)
	if control_timer > 0.0:
		control_timer -= delta
		if control_timer <= 0.0:
			_revert_control()
	match state:
		"attack":
			_attack(delta)
		"move":
			# Tir en mouvement, sans s'arrêter
			_scan_t -= delta
			if _scan_t <= 0.0:
				_scan_t = 0.3
				var t = game.find_enemy(team, position, w_range)
				if t != null and cooldown <= 0.0:
					_shoot(t)
		"idle", "amove":
			_scan_t -= delta
			if _scan_t <= 0.0:
				_scan_t = 0.35
				var t = game.find_enemy(team, position, w_range + 64.0)
				if t != null:
					_set_target(t, false)


func _attack(delta: float) -> void:
	if not _valid(target):
		target = null
		forced = false
		if amove_goal.x >= 0:
			_go_amove()
		else:
			state = "idle"
		return
	var tp: Vector2 = target.world_center()
	var dist: float = position.distance_to(tp) - float(target.radius_px())
	if dist > w_range:
		if not forced and dist > w_range + 192.0:
			target = null # trop loin : on laisse tomber
			state = "idle"
			if amove_goal.x >= 0:
				_go_amove()
			return
		_repath -= delta
		if _repath <= 0.0 or path.is_empty():
			_repath = 0.7
			follow(game.path_to_target(position, target))
		return
	path = PackedVector2Array()
	var want := (tp - position).angle()
	rotation = lerp_angle(rotation, want, clampf(turn_speed * delta, 0.0, 1.0))
	if cooldown <= 0.0 and absf(angle_difference(rotation, want)) < 0.25:
		_shoot(target)


func _shoot(t) -> void:
	var wd: Dictionary = GameData.WEAPONS[weapon]
	cooldown = wd["cd"]
	var ctrl := false
	if weapon == "control" and special_t <= 0.0 and t is Unit and t.role == "combat" and t.control_timer <= 0.0:
		ctrl = true
		special_t = 20.0
	var from := position + Vector2.from_angle(rotation) * 16.0
	game.fire(self, t, weapon, dps * float(wd["cd"]) * (1.0 + GameData.RANK_DMG * rank), from, ctrl)


func _move(delta: float) -> void:
	if path.is_empty():
		return
	var target := path[0]
	var desired := (target - position).angle()
	# Le véhicule tourne d'abord, puis avance (sensation Dune II)
	rotation = lerp_angle(rotation, desired, clampf(turn_speed * delta, 0.0, 1.0))
	if absf(angle_difference(rotation, desired)) < 0.6:
		position = position.move_toward(target, speed * delta)
	if position.distance_to(target) < 1.0:
		path.remove_at(0)
		if path.is_empty():
			_arrived()


func _arrived() -> void:
	match state:
		"move":
			state = "seek" if is_worker() else "idle"
			_seek_started = false
		"amove":
			amove_goal = Vector2i(-1, -1)
			state = "idle"
		"seek":
			state = "harvest"
		"return":
			_unload()


func _work(delta: float) -> void:
	if not is_worker():
		return
	match state:
		"seek":
			_seek(delta)
		"harvest":
			_harvest(delta)
		"flee":
			_flee_timer -= delta
			if _flee_timer <= 0.0 and path.is_empty():
				state = "seek"
				_seek_started = false


func _seek(delta: float) -> void:
	if _seek_started:
		return
	_retry -= delta
	if _retry > 0.0:
		return
	var from: Vector2i = game.world_to_cell(position)
	var c: Vector2i = game.find_resource(cargo_kind, from, 999)
	if c.x < 0:
		_retry = 3.0 # plus rien à récolter : on réessaie plus tard
		return
	work_cell = c
	_seek_started = true
	follow(game.path_to(position, c))
	if path.is_empty():
		path = PackedVector2Array([position])


func _harvest(delta: float) -> void:
	if _work_fx != null:
		_work_fx.emitting = true
	var room := cargo_cap - cargo
	var got: float = game.extract(work_cell, minf(harvest_rate * delta, room))
	cargo += got
	queue_redraw()
	if cargo >= cargo_cap - 0.01:
		_start_return()
	elif got <= 0.0:
		# case épuisée : on cherche une case voisine, sinon on rentre
		var n: Vector2i = game.find_resource(cargo_kind, game.world_to_cell(position), 7)
		if n.x >= 0:
			work_cell = n
			state = "seek"
			_seek_started = true
			follow(game.path_to(position, n))
			if path.is_empty():
				path = PackedVector2Array([position])
		elif cargo > 0.0:
			_start_return()
		else:
			state = "seek"
			_seek_started = false


func _start_return() -> void:
	if _work_fx != null:
		_work_fx.emitting = false
	var from: Vector2i = game.world_to_cell(position)
	var dock = game.find_dock(cargo_kind, from, team)
	if dock == null:
		state = "idle"
		return
	var cell: Vector2i = game.dock_cell(dock, from)
	follow(game.path_to(position, cell))
	if path.is_empty():
		path = PackedVector2Array([position])
	state = "return"


func _unload() -> void:
	if cargo > 0.0:
		game.deposit(cargo_kind, cargo, position, team)
	cargo = 0.0
	queue_redraw()
	state = "seek"
	_seek_started = false


# --- Dessin -------------------------------------------------------------------

func _draw_sprite() -> bool:
	var bank: SpriteBank = game.bank
	if bank == null:
		return false
	var key := _sprite_key()
	var tex = bank.frame(key, rotation)
	if tex == null:
		return false
	var sz := bank.draw_size(key)
	# Ombre portée douce (bas-gauche), puis le modèle sans la rotation du nœud
	draw_set_transform(Vector2(-5, 6), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, radius * 1.25, Color(0.1, 0.03, 0.12, 0.28))
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false)
	return true


func _draw() -> void:
	var body := faction_color.darkened(0.25)
	var hi := faction_color.lightened(0.2)
	if _draw_sprite():
		_draw_overlay()
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	match role:
		"harvester":
			draw_rect(Rect2(-17, -12, 34, 24), body.darkened(0.2))
			draw_rect(Rect2(-17, -12, 34, 24), Color.BLACK, false, 1.5)
			var fill := cargo / cargo_cap if cargo_cap > 0.0 else 0.0
			draw_rect(Rect2(-13, -8, 21, 16), Color(0.1, 0.08, 0.1))
			draw_rect(Rect2(-13, 8.0 - 16.0 * fill, 21, 16.0 * fill), Color("e2762a"))
			draw_rect(Rect2(9, -9, 8, 18), hi)
		"miner":
			draw_rect(Rect2(-15, -11, 28, 22), body.darkened(0.2))
			draw_rect(Rect2(-15, -11, 28, 22), Color.BLACK, false, 1.5)
			var fill := cargo / cargo_cap if cargo_cap > 0.0 else 0.0
			draw_rect(Rect2(-11, -7, 15, 14), Color(0.1, 0.08, 0.1))
			draw_rect(Rect2(-11, 7.0 - 14.0 * fill, 15, 14.0 * fill), GameData.ORE_BLUE)
			draw_colored_polygon(PackedVector2Array([
				Vector2(13, -9), Vector2(26, 0), Vector2(13, 9)]), Color("9aa3b5"))
		"mcv", "convoy":
			draw_rect(Rect2(-20, -13, 40, 26), body.darkened(0.2))
			draw_rect(Rect2(-20, -13, 40, 26), Color.BLACK, false, 1.5)
			draw_rect(Rect2(-14, -9, 22, 18), Color(0.55, 0.58, 0.65))
			draw_rect(Rect2(10, -9, 8, 18), hi)
		_:
			draw_rect(Rect2(-11, -9, 22, 18), body)
			draw_rect(Rect2(-11, -9, 22, 18), Color.BLACK, false, 1.5)
			draw_circle(Vector2.ZERO, 5.5, hi)
			draw_line(Vector2.ZERO, Vector2(16, 0), Color.BLACK, 4.0, true)
	_draw_overlay()


func _draw_overlay() -> void:
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE) # barre de vie toujours horizontale
	if hp < max_hp:
		var w := 26.0
		draw_rect(Rect2(-w / 2.0, -22, w, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2.0, -22, w * hp / max_hp, 4), GameData.GREEN if game.side_of(team) == 0 else GameData.RED)
	for i in rank:
		var o := Vector2(-13 + i * 7, -29)
		draw_polyline(PackedVector2Array([o + Vector2(-3, 2), o + Vector2(0, -1), o + Vector2(3, 2)]), GameData.GOLD, 2.0)
	if control_timer > 0.0:
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 24, Color(1.9, 0.4, 2.0), 2.0, true)
	if selected:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		draw_arc(Vector2.ZERO, radius + 6.0 + pulse * 2.0, 0.0, TAU, 40, GameData.GREEN, 2.0, true)
