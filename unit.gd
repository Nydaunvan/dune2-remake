class_name Unit
extends Node2D
## Unité : déplacement, et pour les récolteurs / mineurs une boucle de travail
## automatique (chercher une ressource → récolter → rapporter → recommencer).

var id := ""
var role := "combat" # combat | harvester | miner | mcv | convoy
const AIR_LIFT := 46.0 # hauteur de vol : l'unité se voit nettement au-dessus de son ombre
var air := false     # unité volante : ignore le terrain, ombre au sol
var repair_acc := 0.0
var repair_site = null
var carried := false # transportée (cachée, suit son transport)
var eaten := false   # en train d'être englouti par un ver
var cargo_units: Array = []
var slots := 0
var load_target = null
var guard := false   # garde immobile (avant-poste, embuscade) : n'entre pas dans les vagues de l'IA
var convoy := false  # unité de convoi de mission
var faction_color := Color("4aa8ff")
var game # le nœud principal (main.gd)

var speed := 110.0
var turn_speed := 10.0
var _last_rot := 0.0
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
var tech := 0        # modernisation faite (0/1)
var tech_left := 0.0 # modernisation en cours : secondes restantes
var tech_total := 0.0
var tech_cost := 0.0 # prix restant à prélever progressivement ; 0 : déjà payé
var tech_acc := 0.0
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
var _blocked_t := 0.0 # temps passé bloqué derrière un autre véhicule
var _muzzle_i := 0   # canon utilisé au prochain tir
var _detours := 0     # contournements récents (pour ne pas se battre avec le même voisin)
var _detour_clock := 0.0
var _pause_t := 0.0   # courte pause après plusieurs contournements : on laisse l'autre passer
var _seek_started := false
var _retry := 0.0
var _flee_timer := 0.0
var _dust: CPUParticles2D
var _work_fx: CPUParticles2D
var _work_fx2: CPUParticles2D # éclats d'épice / de minerai au-dessus du nuage

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
	air = d.get("air", false)
	slots = int(d.get("slots", 0))
	speed = float(d.get("speed", 100.0)) * (GameData.AIR_SPEED_MULT if d.get("air", false) else GameData.SPEED_MULT)
	max_hp = float(d.get("hp", 200))
	hp = max_hp
	base_max_hp = max_hp
	vision = int(d.get("vision", 6 if is_worker() else GameData.DEFAULT_VISION))
	cargo_cap = d.get("capacity", 0.0)
	harvest_rate = d.get("rate", 100.0)
	cargo_kind = d.get("resource", "")
	radius = 14.0 if (is_worker() or role == "mcv" or role == "convoy" or air) else 11.0
	armor = d.get("armor", "medium")
	weapon = d.get("weapon", "")
	dps = float(d.get("dps", 0))
	w_range = float(d.get("range", 0)) * 32.0
	_scan_t = randf() * 0.4 # évite que toutes les unités scrutent à la même image
	_dust = Fx.make_dust(Color(0.85, 0.65, 0.5), 10, 0.9, 0.35)
	add_child(_dust)
	if is_worker():
		var c := Color(0.95, 0.5, 0.15) if cargo_kind == "spice" else Color(0.6, 0.75, 1.0)
		# Nuage de poussière qui monte devant l'engin (derrière lui : il reste bien visible)
		_work_fx = Fx.make_dust(Color(0.88, 0.7, 0.5) if cargo_kind == "spice" else Color(0.7, 0.72, 0.8), 26, 1.5, 0.9)
		_work_fx.position = Vector2(16, 0)
		_work_fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		_work_fx.emission_sphere_radius = 12.0
		_work_fx.direction = Vector2(0, -1)
		_work_fx.spread = 70.0
		_work_fx.initial_velocity_min = 14.0
		_work_fx.initial_velocity_max = 38.0
		_work_fx.scale_amount_max = 2.2
		_work_fx.damping_min = 10.0
		_work_fx.damping_max = 22.0
		_work_fx.color_ramp.colors = PackedColorArray([Color(0.88, 0.72, 0.52, 0.5), Color(0.88, 0.72, 0.52, 0.0)])
		add_child(_work_fx)
		# Éclats lumineux (épice orangée / minerai bleuté)
		_work_fx2 = Fx.make_dust(c, 16, 0.8, 0.22)
		_work_fx2.position = Vector2(16, 0)
		_work_fx2.initial_velocity_min = 30.0
		_work_fx2.initial_velocity_max = 70.0
		_work_fx2.gravity = Vector2(0, 60)
		_work_fx2.color_ramp.colors = PackedColorArray([Color(c.r * 1.6, c.g * 1.6, c.b * 1.6, 0.9), Color(c.r, c.g, c.b, 0.0)])
		_work_fx2.show_behind_parent = false
		add_child(_work_fx2)
		state = "seek"


func _set_work_fx(on: bool) -> void:
	if _work_fx != null:
		_work_fx.emitting = on
	if _work_fx2 != null:
		_work_fx2.emitting = on


func is_worker() -> bool:
	return role == "harvester" or role == "miner"


# --- Ordres -------------------------------------------------------------------

## Ordre « vider » : retourne tout de suite au dépôt décharger, même sans être plein, puis reprend la récolte.
func force_return() -> bool:
	if not is_worker() or not alive or cargo <= 0.0:
		return false
	_seek_started = false
	_start_return()
	return state == "return"


## Ordre du joueur : va quelque part, puis reprend le travail (ouvriers).
func order_path(new_path: PackedVector2Array) -> void:
	load_target = null
	target = null
	forced = false
	amove_goal = Vector2i(-1, -1)
	follow(new_path)
	state = "move"
	if _work_fx != null:
		_set_work_fx(false)


func follow(new_path: PackedVector2Array) -> void:
	path = new_path
	if path.size() > 1:
		path.remove_at(0) # inutile de revenir au centre de la case de départ


func stop() -> void:
	repair_site = null
	load_target = null
	target = null
	forced = false
	amove_goal = Vector2i(-1, -1)
	path = PackedVector2Array()
	state = "idle" # un ordre de déplacement relance ensuite le travail
	_seek_started = false
	if _work_fx != null:
		_set_work_fx(false)


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
		_set_work_fx(false)


## Ordre d'attaque du joueur : poursuit et détruit la cible.
func order_attack(t) -> void:
	if weapon == "" or not alive:
		return
	if t is Unit and t.air and not GameData.can_hit_air(id):
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
	var p: PackedVector2Array
	if air:
		p = PackedVector2Array([position, game._cell_to_world(amove_goal)])
	else:
		p = game.path_to(position, amove_goal)
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
	return position + Vector2(0, -AIR_LIFT) if air else position


func radius_px() -> float:
	return radius


## Centre visuel (écran) de l'unité : sa position, relevée si elle vole, et recentrée sur le modèle.
func visual_center() -> Vector2:
	var c := position
	if air:
		c.y -= AIR_LIFT
	if game != null and game.bank != null:
		var vb: Rect2 = game.bank.visual_box(_sprite_key(), rotation)
		if vb.size != Vector2.ZERO:
			c += vb.get_center().limit_length(radius)
	return c


## Rayon de sélection (clic et anneau) : couvre tout le modèle.
func pick_radius() -> float:
	return radius + 12.0


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


## Applique les bonus de modernisation propres à ce type d'unité.
func apply_tech() -> void:
	tech = 1
	tech_left = 0.0
	var t: Dictionary = GameData.UNIT_TECH.get(id, {})
	var old := max_hp
	base_max_hp *= float(t.get("hp", 1.0))
	max_hp = base_max_hp * (1.0 + GameData.RANK_HP * rank)
	hp += max_hp - old
	dps *= float(t.get("dps", 1.0))
	speed *= float(t.get("speed", 1.0))
	w_range += float(t.get("range", 0)) * 32.0
	vision += int(t.get("vision", 0))
	cargo_cap *= float(t.get("cap", 1.0))
	harvest_rate *= float(t.get("rate", 1.0))
	Fx.burst(game, position, GameData.GOLD, 16, 1.0)
	queue_redraw()


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
	for c in cargo_units:
		if is_instance_valid(c) and c.alive:
			c.carried = false
			c._die()
	cargo_units.clear()
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


## Englouti par un ver : l'unité est aspirée vers la gueule en rétrécissant, puis dévorée.
func swallow(mouth: Vector2, dur: float) -> void:
	if not alive or eaten:
		return
	eaten = true
	stop()
	selected = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position", mouth, dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2(0.15, 0.15), dur).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "rotation", rotation + 2.5, dur)
	tw.chain().tween_callback(devour)


func devour() -> void:
	if not alive:
		return
	alive = false
	Fx.burst(game, position, Color(0.8, 0.55, 0.4), 22, 1.0)
	game.on_unit_lost(self)
	queue_free()


# --- Réparation -----------------------------------------------------------------

## Rentre à l'atelier (Usine ou Centre de réparation) pour être soigné contre des Solaris.
func order_repair(site) -> void:
	if site == null:
		return
	repair_site = site
	target = null
	forced = false
	amove_goal = Vector2i(-1, -1)
	load_target = null
	if air:
		follow(PackedVector2Array([position, site.world_center()]))
	else:
		follow(game.path_to(position, game.dock_cell(site, game.world_to_cell(position))))
	state = "repair"
	if _work_fx != null:
		_set_work_fx(false)


func _repair(delta: float) -> void:
	if state != "repair":
		return
	if not _valid(repair_site):
		state = "seek" if is_worker() else "idle"
		return
	if not path.is_empty() and position.distance_to(repair_site.world_center()) > 90.0:
		return
	path = PackedVector2Array()
	if not game.repair_unit_tick(self, delta):
		state = "seek" if is_worker() else "idle"
		_seek_started = false
		repair_site = null
		if hp >= max_hp - 0.5 and team == 0:
			game.popup(position, "Réparé", GameData.GREEN)


# --- Transport aérien ---------------------------------------------------------

## Ordre : va chercher cette unité terrestre alliée et l'embarque.
func order_load(t) -> void:
	if role != "transport" or not _valid(t) or t.air or t.carried or t == self:
		return
	if cargo_units.size() >= slots:
		game.ui.toast("%s : soute pleine" % GameData.def(id)["name"], GameData.AMBER)
		return
	target = null
	forced = false
	load_target = t
	state = "load"


func _transport(delta: float) -> void:
	if role != "transport" or state != "load":
		return
	if not _valid(load_target) or load_target.carried or cargo_units.size() >= slots:
		load_target = null
		state = "idle"
		return
	_repath -= delta
	if _repath <= 0.0:
		_repath = 0.25
		follow(PackedVector2Array([position, load_target.position]))
	if position.distance_to(load_target.position) < 22.0:
		var t = load_target
		load_target = null
		path = PackedVector2Array()
		state = "idle"
		load_unit(t)


func load_unit(t) -> void:
	if cargo_units.size() >= slots or t.carried:
		return
	t.stop()
	t.carried = true
	t.visible = false
	t.selected = false
	game.selected.erase(t)
	cargo_units.append(t)
	if team == 0:
		game.popup(position, "Embarqué %d/%d" % [cargo_units.size(), slots], GameData.GREEN)
	queue_redraw()


## Dépose toute la cargaison autour du transport (les ouvriers reprennent le travail).
func unload_all() -> void:
	if cargo_units.is_empty():
		return
	var n := 0
	for c in cargo_units:
		if not is_instance_valid(c) or not c.alive:
			continue
		var cell: Vector2i = game._find_free_cell(game.world_to_cell(position) + Vector2i(n % 3 - 1, n / 3))
		c.position = game._cell_to_world(cell)
		c.carried = false
		c.visible = true
		c.state = "seek" if c.is_worker() else "idle"
		c._seek_started = false
		n += 1
	cargo_units.clear()
	if team == 0:
		game.popup(position, "Cargaison déposée", GameData.GREEN)
		game.sfx.play_ui("unit_ready", -6.0)
	queue_redraw()


# --- Boucle -------------------------------------------------------------------

func _sprite_key() -> String:
	return "%s|%s" % [id, game.faction_id_of(team)]


func _process(_delta: float) -> void:
	if selected or (air and alive and Models.rotors(id).size() > 0):
		queue_redraw() # anneau de sélection pulsé / pales en rotation
	var bank: SpriteBank = game.bank
	if bank != null:
		# Les modèles 3D sont cuits une image par angle : on redessine quand l'angle change
		var idx := bank.frame_index(_sprite_key(), rotation)
		if absf(angle_difference(rotation, _last_rot)) > 0.02:
			_last_rot = rotation
			queue_redraw() # écart résiduel du modèle par rapport à l'image cuite
		if idx != _frame_idx or (not _sprite_ready and bank.has(_sprite_key())):
			_frame_idx = idx
			_sprite_ready = bank.has(_sprite_key())
			queue_redraw()


func _physics_process(delta: float) -> void:
	if not alive or eaten:
		return
	if carried:
		return
	_work(delta)
	_combat(delta)
	_transport(delta)
	_repair(delta)
	_move(delta)
	_dust.emitting = not air and not path.is_empty() and game.is_sand_at(position)
	for c in cargo_units:
		if is_instance_valid(c):
			c.position = position


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
				var t = game.find_enemy(team, position, w_range, false, id)
				if t != null and cooldown <= 0.0:
					_shoot(t)
		"idle", "amove":
			_scan_t -= delta
			if _scan_t <= 0.0:
				_scan_t = 0.35
				var t = game.find_enemy(team, position, w_range + 64.0, false, id)
				if t != null:
					_set_target(t, false)


func _attack(delta: float) -> void:
	if not _valid(target) or (target is Unit and (target.carried or (target.air and not GameData.can_hit_air(id)))):
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
			if air:
				follow(PackedVector2Array([position, tp]))
			else:
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
	# Le projectile part du bout du canon dessiné (alterné entre les canons s'il y en a plusieurs)
	var mo := Models.muzzle_offset(id, rotation, _muzzle_i)
	if mo != Vector2.INF and game.bank != null and game.bank.has(_sprite_key()):
		from = position + mo + (Vector2(0, -AIR_LIFT) if air else Vector2.ZERO)
		_muzzle_i = (_muzzle_i + 1) % Models.muzzle_count(id)
	game.fire(self, t, weapon, dps * float(wd["cd"]) * (1.0 + GameData.RANK_DMG * rank), from, ctrl)


func _move(delta: float) -> void:
	if path.is_empty():
		return
	if _pause_t > 0.0:
		_pause_t -= delta
		return
	_detour_clock -= delta
	if _detour_clock <= 0.0:
		_detours = 0
	var target := path[0]
	var desired := (target - position).angle()
	# Le véhicule tourne d'abord, puis avance (sensation jeu de stratégie classique)
	rotation = lerp_angle(rotation, desired, clampf(turn_speed * delta, 0.0, 1.0))
	if air or absf(angle_difference(rotation, desired)) < 0.12:
		var step_pos := position.move_toward(target, speed * delta)
		if not air and _blocked_t < 3.0:
			var blocker = game.unit_blocking(self, step_pos)
			if blocker != null:
				_blocked_t += delta
				var moving: bool = not blocker.path.is_empty()
				var limit := 0.12 # voisin à l'arrêt : on le contourne tout de suite
				if moving:
					# voisin en mouvement : on lui laisse le temps de dégager, sauf face à face
					# où seul l'un des deux (identifiant le plus bas) contourne
					var head_on: bool = (blocker.path[0] - blocker.position).dot(target - position) < 0.0
					limit = 0.12 if (head_on and get_instance_id() < blocker.get_instance_id()) else 0.9
				if _blocked_t > limit:
					_blocked_t_detour(blocker)
				return # on n'avance pas sur un autre véhicule : on attend ou on contourne
		if _blocked_t > 0.0 and _blocked_t < 3.0:
			_blocked_t = maxf(_blocked_t - delta * 2.0, 0.0)
		elif _blocked_t >= 3.0:
			_blocked_t += delta
			if _blocked_t > 4.0:
				_blocked_t = 0.0 # après une courte poussée, on retente de contourner
		position = step_pos
	if position.distance_to(target) < 1.0:
		path.remove_at(0)
		if path.is_empty():
			_arrived()


## Un véhicule bloque la route : on cherche un chemin qui le contourne.
func _blocked_t_detour(blocker: Unit) -> void:
	var goal: Vector2 = path[path.size() - 1]
	if path.size() <= 2 and blocker.position.distance_to(goal) < (radius + blocker.radius):
		# la destination est occupée : on s'arrête là
		path = PackedVector2Array()
		_blocked_t = 0.0
		_arrived()
		return
	_detours += 1
	_detour_clock = 8.0
	if _detours >= 3:
		# on se gêne mutuellement depuis un moment : courte pause aléatoire, l'autre passera
		_pause_t = randf_range(0.5, 1.2)
		_detours = 0
		_blocked_t = 0.0
		return
	var np: PackedVector2Array = game.detour_path(self, blocker, goal)
	if np.size() > 0:
		follow(np)
		_blocked_t = 0.0


func _arrived() -> void:
	match state:
		"move":
			state = "seek" if is_worker() else "idle"
			_seek_started = false
			if role == "transport" and not cargo_units.is_empty():
				unload_all()
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
	# Plein : on va toujours se vider avant de repartir en récolte
	if cargo >= cargo_cap - 0.01 and (state == "seek" or state == "harvest" or (state == "idle" and path.is_empty())):
		_start_return()
		return
	match state:
		"seek":
			_seek(delta)
		"harvest":
			_harvest(delta)
		"return":
			if path.is_empty() and cargo > 0.0:
				_retry -= delta
				if _retry <= 0.0:
					_start_return()
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
	var c: Vector2i = game.find_resource(cargo_kind, from, 999, self)
	if c.x < 0:
		_retry = 3.0 # plus rien à récolter : on réessaie plus tard
		if cargo > 0.0:
			_start_return() # en attendant, on va vider ce qu'on porte
		return
	work_cell = c
	_seek_started = true
	follow(game.path_to(position, c))
	if path.is_empty():
		path = PackedVector2Array([position])


func _harvest(delta: float) -> void:
	if _work_fx != null:
		_set_work_fx(true)
	var room := cargo_cap - cargo
	var got: float = game.extract(work_cell, minf(harvest_rate * delta, room))
	cargo += got
	if cargo >= cargo_cap - 0.01:
		cargo = cargo_cap # évite 159,999… à l'affichage et au dépôt
	queue_redraw()
	if cargo >= cargo_cap - 0.01:
		_start_return()
	elif got <= 0.0:
		# case épuisée : on cherche une case voisine, sinon on rentre
		var n: Vector2i = game.find_resource(cargo_kind, game.world_to_cell(position), 7, self)
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
		_set_work_fx(false)
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
	var dock = game.find_dock(cargo_kind, position, team)
	if cargo > 0.0 and dock != null and (dock.offline or dock.up_left > 0.0):
		# Raffinerie / fonderie hors tension : impossible d'encaisser, on attend le retour du courant
		state = "return"
		path = PackedVector2Array()
		_retry = 1.0
		if team == 0 and game.game_time - game._full_warn > 6.0:
			game._full_warn = game.game_time
			game.popup(position, "Hors tension", GameData.RED)
		return
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
	# Les décalages sont donnés à l'écran : on les contre-tourne car le nœud est tourné.
	var unrot := -rotation
	# L'image cuite la plus proche est tournée de l'écart résiduel : le modèle suit exactement le cap
	var model_rot := -bank.snap_angle(key, rotation)
	# Ombre portée douce (bas-gauche, au sol), puis le modèle sans la rotation du nœud
	if air:
		draw_set_transform(Vector2(-6, 8).rotated(unrot), unrot, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius * 1.3, Color(0.1, 0.03, 0.12, 0.34))
		# fine ligne verticale entre l'ombre et l'appareil : lecture immédiate de l'altitude
		draw_set_transform(Vector2.ZERO, unrot, Vector2.ONE)
		draw_dashed_line(Vector2(0, 0).rotated(unrot), Vector2(0, -AIR_LIFT + 8.0).rotated(unrot), Color(1, 1, 1, 0.12), 1.0, 3.0)
		draw_set_transform(Vector2(0, -AIR_LIFT).rotated(unrot), model_rot, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false)
		_draw_rotors(unrot)
		return true
	draw_set_transform(Vector2(-5, 6).rotated(unrot), unrot, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, radius * 1.25, Color(0.1, 0.03, 0.12, 0.28))
	draw_set_transform(Vector2.ZERO, model_rot, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false)
	return true


## Pales tournantes des hélicoptères et transports : dessinées chaque image par-dessus le sprite.
func _draw_rotors(unrot: float) -> void:
	var rs := Models.rotors(id)
	if rs.is_empty():
		return
	draw_set_transform(Vector2(0, -AIR_LIFT).rotated(unrot), unrot, Vector2.ONE)
	var t := Time.get_ticks_msec() / 1000.0 + float(get_instance_id() % 97)
	for ro in rs:
		var hub: Vector3 = ro["hub"]
		var r: float = ro["r"]
		var ang: float = t * float(ro["w"])
		var c := Models.project(hub, rotation)
		if ro["h"]:
			draw_circle(c, r, Color(0.9, 0.92, 1.0, 0.10))
		for b in int(ro["n"]):
			var a := ang + TAU * b / float(ro["n"])
			var tip: Vector2
			var tail: Vector2
			if ro["h"]:
				tip = c + Vector2.from_angle(a) * r
				tail = c - Vector2.from_angle(a) * r * (1.0 if int(ro["n"]) % 2 == 0 else 0.0)
			else:
				var d := Vector3(cos(a) * r, sin(a) * r, 0.0)
				tip = Models.project(hub + d, rotation)
				tail = Models.project(hub - d, rotation)
			draw_line(tail, tip, Color(0.88, 0.9, 0.96, 0.92), 2.4 if ro["h"] else 1.6, true)
		draw_circle(c, 2.2, Color(0.15, 0.16, 0.2))


func _draw() -> void:
	var body := faction_color.darkened(0.25)
	var hi := faction_color.lightened(0.2)
	if _draw_sprite():
		_draw_overlay()
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if air:
		draw_circle(Vector2(-4, 14), 11.0, Color(0, 0, 0, 0.25))
		var fwd := Vector2.from_angle(rotation)
		var side := fwd.orthogonal()
		draw_colored_polygon(PackedVector2Array([fwd * 16.0 + Vector2(0, -AIR_LIFT), side * 12.0 - fwd * 10.0 + Vector2(0, -AIR_LIFT),
				-fwd * 6.0 + Vector2(0, -AIR_LIFT), -side * 12.0 - fwd * 10.0 + Vector2(0, -AIR_LIFT)]), body)
		_draw_overlay()
		return
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
	# Tout est centré sur le modèle (relevé pour les volants) ; barre de vie toujours horizontale
	var oc := to_local(visual_center())
	draw_set_transform(oc, -rotation, Vector2.ONE)
	if hp < max_hp:
		var w := 26.0
		draw_rect(Rect2(-w / 2.0, -22, w, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2.0, -22, w * hp / max_hp, 4), GameData.GREEN if game.side_of(team) == 0 else GameData.RED)
	if tech_left > 0.0:
		draw_rect(Rect2(-13, -27, 26, 3), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-13, -27, 26.0 * (1.0 - tech_left / maxf(tech_total, 0.1)), 3), GameData.AMBER_HDR)
	if tech > 0:
		draw_circle(Vector2(15, -22), 2.5, GameData.GOLD)
	for i in rank:
		var o := Vector2(-13 + i * 7, -29)
		draw_polyline(PackedVector2Array([o + Vector2(-3, 2), o + Vector2(0, -1), o + Vector2(3, 2)]), GameData.GOLD, 2.0)
	if control_timer > 0.0:
		draw_arc(Vector2.ZERO, pick_radius() - 2.0, 0.0, TAU, 24, Color(1.9, 0.4, 2.0), 2.0, true)
	if selected:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		draw_arc(Vector2.ZERO, pick_radius() + pulse * 2.0, 0.0, TAU, 40, GameData.GREEN, 2.0, true)

# --- Sauvegarde -----------------------------------------------------------------

func export_state(idx: Dictionary) -> Dictionary:
	var cl: Array = []
	for c in cargo_units:
		if idx.has(c):
			cl.append(idx[c])
	return {
		"id": id, "team": _orig_team if control_timer > 0.0 else team, "pos": position, "rot": rotation,
		"hp": hp, "max_hp": max_hp, "base_max_hp": base_max_hp, "dps": dps, "speed": speed, "w_range": w_range,
		"vision": vision, "cargo_cap": cargo_cap, "harvest_rate": harvest_rate,
		"tech": tech, "tech_left": tech_left, "tech_total": tech_total, "tech_cost": tech_cost, "tech_acc": tech_acc, "rank": rank, "kills": kills,
		"cargo": cl, "cargo_amount": cargo, "guard": guard, "convoy": convoy,
		"state": state, "path": path, "amove_goal": amove_goal,
	}


## Rétablit l'unité (créée par setup) ; les ordres en cours sont repris quand c'est possible.
func restore_state(s: Dictionary) -> void:
	position = s["pos"]
	rotation = float(s["rot"])
	base_max_hp = float(s["base_max_hp"])
	max_hp = float(s["max_hp"])
	hp = minf(float(s["hp"]), max_hp)
	dps = float(s["dps"])
	speed = float(s["speed"])
	w_range = float(s["w_range"])
	vision = int(s["vision"])
	cargo_cap = float(s["cargo_cap"])
	harvest_rate = float(s["harvest_rate"])
	tech = int(s["tech"])
	tech_left = float(s["tech_left"])
	tech_total = float(s["tech_total"])
	tech_cost = float(s.get("tech_cost", 0.0))
	tech_acc = float(s.get("tech_acc", 0.0))
	rank = int(s["rank"])
	kills = int(s["kills"])
	cargo = float(s["cargo_amount"])
	guard = bool(s["guard"])
	convoy = bool(s["convoy"])
	var st := String(s["state"])
	var p: PackedVector2Array = s["path"]
	match st:
		"move":
			path = p
			state = "move" if not p.is_empty() else ("seek" if is_worker() else "idle")
		"amove":
			amove_goal = s["amove_goal"]
			if amove_goal.x >= 0:
				order_amove(amove_goal)
		"return":
			if is_worker() and cargo > 0.0:
				_start_return()
		_:
			state = "seek" if is_worker() else "idle"
	if is_worker() and state == "idle":
		state = "seek"
	queue_redraw()
