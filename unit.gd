class_name Unit
extends Node2D
## Unité : déplacement, et pour les récolteurs / mineurs une boucle de travail
## automatique (chercher une ressource → récolter → rapporter → recommencer).

var id := ""
var role := "combat" # combat | harvester | miner
var faction_color := Color("4aa8ff")
var game # le nœud principal (main.gd)

var speed := 110.0
var turn_speed := 8.0
var radius := 11.0
var hp := 100.0
var max_hp := 100.0
var alive := true

var cargo := 0.0
var cargo_cap := 0.0
var cargo_kind := "" # "spice" | "ore"
var harvest_rate := 100.0

var state := "idle" # idle | move | seek | harvest | return | flee
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
	cargo_cap = d.get("capacity", 0.0)
	harvest_rate = d.get("rate", 100.0)
	cargo_kind = d.get("resource", "")
	radius = 14.0 if is_worker() else 11.0
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
	follow(new_path)
	state = "move"
	if _work_fx != null:
		_work_fx.emitting = false


func follow(new_path: PackedVector2Array) -> void:
	path = new_path
	if path.size() > 1:
		path.remove_at(0) # inutile de revenir au centre de la case de départ


func stop() -> void:
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


func devour() -> void:
	if not alive:
		return
	alive = false
	Fx.burst(game, position, Color(0.8, 0.55, 0.4), 22, 1.0)
	game.on_unit_lost(self)
	queue_free()


# --- Boucle -------------------------------------------------------------------

func _process(_delta: float) -> void:
	if selected:
		queue_redraw() # anneau de sélection pulsé


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_work(delta)
	_move(delta)
	_dust.emitting = not path.is_empty() and game.is_sand_at(position)


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
	var dock = game.find_dock(cargo_kind, from)
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
		game.deposit(cargo_kind, cargo, position)
	cargo = 0.0
	queue_redraw()
	state = "seek"
	_seek_started = false


# --- Dessin -------------------------------------------------------------------

func _draw() -> void:
	var body := faction_color.darkened(0.25)
	var hi := faction_color.lightened(0.2)
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
		_:
			draw_rect(Rect2(-11, -9, 22, 18), body)
			draw_rect(Rect2(-11, -9, 22, 18), Color.BLACK, false, 1.5)
			draw_circle(Vector2.ZERO, 5.5, hi)
			draw_line(Vector2.ZERO, Vector2(16, 0), Color.BLACK, 4.0, true)
	if hp < max_hp:
		var w := 26.0
		draw_rect(Rect2(-w / 2.0, -22, w, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2.0, -22, w * hp / max_hp, 4), GameData.GREEN)
	if selected:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		draw_arc(Vector2.ZERO, radius + 6.0 + pulse * 2.0, 0.0, TAU, 40, GameData.GREEN, 2.0, true)
