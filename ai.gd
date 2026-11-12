class_name SkirmishAI
extends Node
## Adversaire d'escarmouche : même économie et mêmes règles que le joueur.
## Il construit sa base, récolte, produit une armée et lance des vagues d'assaut
## de plus en plus grosses, en défendant sa base si elle est menacée.

const THINK := 1.0
const BUILD_ORDER := ["centrale", "raffinerie", "fonderie", "usine", "centrale",
		"tourelle", "usine", "tourelle", "centrale", "tourelle", "tourelle"]

var game # le nœud principal (main.gd)
var team := 1
var home := Vector2(48, 16)  # centre de la base de cette IA (cases)
var foe := Vector2(48, 80)   # base adverse supposée (cases)
var deploy_at := 3.0         # moment du déploiement de l'engin de chantier
var faction_id := ""
var fdata := {}
var credits := 1500
var ore := 1500
var active := true

var build_q := {}
var unit_q := {}
var wave_size := 6
var max_army := 22
var slowdown := 1.4     # l'IA construit et produit un peu plus lentement que le joueur
var wave_grace := 240.0 # pas d'assaut avant 4 minutes de jeu
var wave_pause := 60.0  # répit minimum entre deux assauts
var assaulting := false
var wave_started := 0.0
var wave_ended := 0.0
var _think_t := 3.0


## Adoucissement global : l'IA doit laisser le temps de s'organiser.
const EASE_SLOW := 1.3     # construit et produit plus lentement
const EASE_GRACE := 1.4    # premier assaut plus tardif
const EASE_PAUSE := 1.3    # plus de répit entre les vagues
const EASE_ARMY := 0.8     # armée plus petite
const EASE_WAVE := 0.75    # vagues plus petites
const EASE_MONEY := 0.8    # réserves de départ réduites


func setup(p_game, p_faction: String, p_team := 1) -> void:
	slowdown *= EASE_SLOW
	wave_grace *= EASE_GRACE
	wave_pause *= EASE_PAUSE
	max_army = int(max_army * EASE_ARMY)
	wave_size = int(wave_size * EASE_WAVE)
	credits = int(credits * EASE_MONEY)
	ore = int(ore * EASE_MONEY)
	game = p_game
	team = p_team
	deploy_at = 3.0 + randf() * 4.0
	faction_id = p_faction
	fdata = GameData.FACTIONS[p_faction]


## Réglages de mission (campagne).
func configure(p: Dictionary) -> void:
	slowdown = float(p.get("slowdown", slowdown / EASE_SLOW)) * EASE_SLOW
	wave_grace = float(p.get("grace", wave_grace / EASE_GRACE)) * EASE_GRACE
	wave_pause = float(p.get("pause", wave_pause / EASE_PAUSE)) * EASE_PAUSE
	max_army = int(int(p.get("max_army", int(max_army / EASE_ARMY))) * EASE_ARMY)
	wave_size = maxi(int(int(p.get("wave", int(wave_size / EASE_WAVE))) * EASE_WAVE), 3)
	credits = int(int(p.get("credits", int(credits / EASE_MONEY))) * EASE_MONEY)
	ore = int(int(p.get("ore", int(ore / EASE_MONEY))) * EASE_MONEY)


func add_income(kind: String, amount: int) -> void:
	if kind == "spice":
		credits = mini(credits + amount, maxi(game.storage_cap("spice", team), credits))
	else:
		ore = mini(ore + amount, maxi(game.storage_cap("ore", team), ore))


func _process(delta: float) -> void:
	if not active:
		return
	if not game.has_building("chantier", team):
		_try_deploy()
		return
	_progress(delta)
	_think_t -= delta
	if _think_t <= 0.0:
		_think_t = THINK
		_think_build()
		_think_units()
		_think_army()


## Déploie l'engin de chantier peu après le début (près de sa position de départ).
func _try_deploy() -> void:
	if game.game_time < deploy_at:
		return
	for u in game.units:
		if u.team == team and u.id == "mcv" and u.alive:
			game.deploy_mcv(u, true)
			return


# --- Production ---------------------------------------------------------------

func _progress(delta: float) -> void:
	var factor := (1.0 if game.power_produced(team) >= game.power_used(team) else 0.5) / slowdown
	var ufactor: float = factor * game.unit_speed_bonus(team)
	if not build_q.is_empty():
		if not build_q["ready"] and not game.producer_busy("building", "", team):
			build_q["progress"] += delta * factor / build_q["time"]
			if build_q["progress"] >= 1.0:
				build_q["ready"] = true
		if build_q["ready"] and _place(build_q["id"]):
			build_q = {}
	if not unit_q.is_empty() and not game.producer_busy("unit", unit_q["id"], team):
		unit_q["progress"] += delta * ufactor / unit_q["time"]
		if unit_q["progress"] >= 1.0:
			game.spawn_for(unit_q["id"], team)
			unit_q = {}


func _cost(id: String) -> int:
	var c := float(GameData.def(id)["cost"])
	if GameData.UNITS.has(id):
		c *= float(fdata["unit_cost_mult"])
	return int(round(c))


func _count(id: String) -> int:
	var n := 0
	for b in game.buildings:
		if b.team == team and b.id == id:
			n += 1
	for u in game.units:
		if u.team == team and u.id == id:
			n += 1
	return n


func _available(id: String) -> bool:
	if game.unit_level_block(id, team) != "":
		return false
	for r in GameData.def(id)["requires"]:
		if not game.has_building(r, team):
			return false
	return true


func _think_build() -> void:
	if not build_q.is_empty():
		return
	var want := ""
	# Énergie d'abord : jamais en panne
	if game.power_produced(team) - game.power_used(team) < 30:
		want = "centrale"
	else:
		var seen := {}
		for id in BUILD_ORDER:
			seen[id] = int(seen.get(id, 0)) + 1
			if _count(id) < int(seen[id]):
				want = id
				break
	if want == "":
		_try_upgrade()
		return
	# Jamais de bâtiment sans l'énergie nécessaire : on construit d'abord une centrale
	if GameData.BUILDINGS.has(want) and game.power_produced(team) - game.power_used(team) < -int(GameData.BUILDINGS[want]["power"]):
		want = "centrale"
	if not _available(want) or ore < _cost(want) or credits < GameData.sol_cost(want):
		return
	ore -= _cost(want)
	credits -= GameData.sol_cost(want)
	build_q = {"id": want, "progress": 0.0, "ready": false,
			"time": float(GameData.def(want)["time"]) * float(fdata["build_time_mult"])}


## Une fois la base construite, l'IA améliore ses bâtiments quand elle a du minerai en réserve.
func _try_upgrade() -> void:
	for id in ["usine", "chantier", "centrale", "tourelle", "raffinerie", "fonderie"]:
		for b in game.buildings:
			if b.team != team or b.id != id:
				continue
			if game.upgrade_block(b, ore) == "" and ore >= game.upgrade_cost(b) + 400:
				ore -= game.upgrade_cost(b)
				game.begin_upgrade(b)
				return


func _think_units() -> void:
	if not unit_q.is_empty():
		return
	var want := ""
	var harvesters := _count("recolteur")
	var miners := _count("mineur")
	if game.has_building("raffinerie", team) and harvesters < 2:
		want = "recolteur"
	elif game.has_building("fonderie", team) and miners < 1:
		want = "mineur"
	elif game.has_building("usine", team) and _army().size() < max_army:
		# Armée variée : on prend un type au hasard, légèrement pondéré
		var ids: Array = fdata["units"].filter(func(i: String) -> bool: return _available(i))
		if ids.is_empty():
			return
		want = ids[randi() % ids.size()]
		if randf() < 0.3:
			want = ids[0]
	if want == "" or not _available(want) or credits < _cost(want):
		return
	credits -= _cost(want)
	unit_q = {"id": want, "progress": 0.0, "time": float(GameData.def(want)["time"])}


## Place le bâtiment terminé ; renvoie false s'il n'y a pas de place.
func _place(id: String) -> bool:
	var base: Vector2 = home
	var toward: Vector2 = foe
	var size: Vector2i = GameData.BUILDINGS[id]["size"]
	var best := Vector2i(-1, -1)
	var best_s := INF
	for dx in range(-11, 12):
		for dy in range(-11, 12):
			var cell := Vector2i(base) + Vector2i(dx, dy)
			if not game._can_place(id, cell, team) or not _has_gap(cell, size):
				continue
			var center := Vector2(cell) + Vector2(size) / 2.0
			# Défenses vers l'ennemi, le reste près de la base
			var s := center.distance_to(toward) * 0.5 + center.distance_to(base) if id == "tourelle" \
					else center.distance_to(base)
			if s < best_s:
				best_s = s
				best = cell
	if best.x < 0:
		return false
	game._place_building(id, best, team)
	return true


## Garde une case libre autour du bâtiment pour que les unités circulent.
func _has_gap(cell: Vector2i, size: Vector2i) -> bool:
	for x in range(cell.x - 1, cell.x + size.x + 1):
		for y in range(cell.y - 1, cell.y + size.y + 1):
			if game.occupied.has(Vector2i(x, y)):
				return false
	return true


# --- Armée --------------------------------------------------------------------

func _army() -> Array:
	var out := []
	for u in game.units:
		if u.team == team and u.role == "combat" and not u.guard and u.control_timer <= 0.0:
			out.append(u)
	return out


func _think_army() -> void:
	var army := _army()
	if army.is_empty():
		if assaulting:
			wave_ended = game.game_time
		assaulting = false
		return
	var base_world: Vector2 = home * game.TILE

	# Défense : des unités du joueur près de nos bâtiments
	var intruder = null
	for u in game.units:
		if game.hostile(u.team, team) and u.position.distance_to(base_world) < 12.0 * game.TILE:
			intruder = u
			break
	if intruder != null and not assaulting:
		for u in army:
			if u.state == "idle":
				u.order_amove(game.world_to_cell(intruder.position))
		return

	var idle := army.filter(func(u: Unit) -> bool: return u.state == "idle")
	if not assaulting:
		if game.game_time >= wave_grace and game.game_time - wave_ended >= wave_pause \
				and idle.size() >= wave_size:
			assaulting = true
			wave_started = game.game_time
			wave_size = mini(wave_size + 1, 12)
		else:
			return
	elif game.game_time - wave_started > 150.0 and idle.size() >= army.size():
		assaulting = false # vague terminée
		wave_ended = game.game_time
		return
	var goal := _attack_goal()
	if goal.x < 0:
		return
	for u in idle:
		u.order_amove(goal)


## Case d'assaut : bâtiment du joueur le plus proche de notre base.
func _attack_goal() -> Vector2i:
	var best = null
	var best_d := INF
	for b in game.buildings:
		if not game.hostile(b.team, team):
			continue
		var d: float = b.world_center().distance_to(home * game.TILE)
		if d < best_d:
			best_d = d
			best = b
	if best == null:
		return Vector2i(-1, -1)
	return game.dock_cell(best, game.world_to_cell(home * game.TILE))

# --- Sauvegarde -----------------------------------------------------------------

func export_state() -> Dictionary:
	return {"credits": credits, "ore": ore, "build_q": build_q.duplicate(true), "unit_q": unit_q.duplicate(true),
			"wave_size": wave_size, "assaulting": assaulting, "wave_started": wave_started,
			"wave_ended": wave_ended, "think_t": _think_t, "deploy_at": deploy_at, "active": active}


func restore_state(s: Dictionary) -> void:
	credits = int(s["credits"])
	ore = int(s["ore"])
	build_q = s["build_q"]
	unit_q = s["unit_q"]
	wave_size = int(s["wave_size"])
	assaulting = bool(s["assaulting"])
	wave_started = float(s["wave_started"])
	wave_ended = float(s["wave_ended"])
	_think_t = float(s["think_t"])
	deploy_at = float(s["deploy_at"])
	active = bool(s["active"])
