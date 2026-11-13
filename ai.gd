class_name SkirmishAI
extends Node
## Adversaire d'escarmouche et de campagne : même économie et mêmes règles que le joueur.
##
## Il suit un PLAN par étapes (économie -> défense -> armée -> expansion -> technologie), choisit ses
## unités selon ce que le joueur aligne (contre-mesures), modernise et améliore, puis conduit la guerre
## de façon organisée :
##   - assaut groupé : rassemblement, approche, attaque d'une cible choisie (valeur / défenses), repli si ça tourne mal ;
##   - raids : petit groupe rapide qui harcèle les récolteurs mal défendus ;
##   - escadrille aérienne : bombardiers contre les cibles sans anti-aérien ;
##   - défense : toute l'armée répond à une attaque sur la base.
## `skill` (0..1) règle la finesse de tout cela : les premières missions restent simples, les dernières jouent bien.

const THINK := 1.0
const BASE_SEQ := ["centrale", "raffinerie", "fonderie", "usine"]

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
var skill := 0.6             # finesse de jeu (0..1)

var build_q := {}
var unit_q := {}
var _since_air := 2   # unités terrestres produites depuis la dernière unité volante
var wave_size := 6
var max_army := 22
var slowdown := 1.4     # l'IA construit et produit un peu plus lentement que le joueur
var wave_grace := 240.0 # pas d'assaut avant 4 minutes de jeu
var wave_pause := 60.0  # répit minimum entre deux assauts
var assaulting := false
var wave_started := 0.0
var wave_ended := 0.0
var goal_text := ""     # objectif courant (lisible dans les tests / le débogage)
var _think_t := 3.0

# Guerre organisée
var mode := "muster"    # muster | stage | attack | retreat
var squad: Array = []
var squad_start := 0
var target_b = null
var stage_cell := Vector2i(-1, -1)
var _mode_t := 0.0
var raid: Array = []
var raid_target = null
var raid_ended := 0.0
var _raid_t := 0.0
var air_wave: Array = []
var air_ended := 0.0
var _hp_seen := {}      # PV de nos bâtiments à la dernière analyse (détecte une attaque)
var earned_spice := 0   # revenus cumulés (statistiques du banc d'essai)
var earned_ore := 0
var _alert_until := 0.0
var _save_since := -1.0 # début de la mise de côté pour une amélioration
var _w_hp := {}         # PV des ouvriers à la dernière analyse (détecte une attaque)
var stage_of := {}      # point d'attente propre à chaque unité (manœuvre de flanc)

## Adoucissement global : l'IA doit laisser le temps de s'organiser.
const EASE_SLOW := 1.3     # construit et produit plus lentement
const EASE_GRACE := 1.4    # premier assaut plus tardif
const EASE_PAUSE := 1.3    # plus de répit entre les vagues
const EASE_ARMY := 0.8     # armée plus petite
const EASE_WAVE := 0.75    # vagues plus petites
const EASE_MONEY := 1.0    # mêmes réserves de départ que le joueur


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


## Réglages de mission (campagne) ou de difficulté (escarmouche).
func configure(p: Dictionary) -> void:
	slowdown = float(p.get("slowdown", slowdown / EASE_SLOW)) * EASE_SLOW
	wave_grace = float(p.get("grace", wave_grace / EASE_GRACE)) * EASE_GRACE
	wave_pause = float(p.get("pause", wave_pause / EASE_PAUSE)) * EASE_PAUSE
	max_army = int(int(p.get("max_army", int(max_army / EASE_ARMY))) * EASE_ARMY)
	wave_size = maxi(int(int(p.get("wave", int(wave_size / EASE_WAVE))) * EASE_WAVE), 3)
	credits = int(int(p.get("credits", int(credits / EASE_MONEY))) * EASE_MONEY)
	ore = int(int(p.get("ore", int(ore / EASE_MONEY))) * EASE_MONEY)
	# Plancher : de quoi bâtir centrale, raffinerie, fonderie et produire un récolteur et un mineur
	var need_sol := 0
	var need_ore := 0
	for bid in ["centrale", "raffinerie", "fonderie"]:
		need_sol += GameData.sol_cost(bid)
		need_ore += int(GameData.def(bid)["cost"])
	for uid in ["recolteur", "mineur"]:
		need_sol += int(GameData.def(uid)["cost"] * float(fdata["unit_cost_mult"]))
		need_ore += int(round(float(GameData.unit_ore(uid)) * float(fdata["unit_cost_mult"])))
	credits = maxi(credits, int(ceil(need_sol * 1.1 / 50.0)) * 50)
	ore = maxi(ore, int(ceil(need_ore * 1.1 / 50.0)) * 50)
	skill = clampf(float(p.get("skill", skill)), 0.0, 1.0)


func add_income(kind: String, amount: int) -> void:
	if kind == "spice":
		earned_spice += amount
	else:
		earned_ore += amount
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
		_think_tech()
		_watch_base()
		_think_army()
		_think_tactics()
		_think_raid()
		_think_air()


## Déploie l'engin de chantier peu après le début (près de sa position de départ).
func _try_deploy() -> void:
	if game.game_time < deploy_at:
		return
	for u in game.units:
		if u.team == team and u.id == "mcv" and u.alive:
			game.deploy_mcv(u, true)
			return


# --- Outils d'analyse -----------------------------------------------------------

func _foe_units() -> Array:
	var out := []
	for u in game.units:
		if u.alive and not u.carried and game.hostile(u.team, team):
			out.append(u)
	return out


func _count(id: String) -> int:
	var n := 0
	for b in game.buildings:
		if b.team == team and b.id == id and b.alive:
			n += 1
	for u in game.units:
		if u.team == team and u.id == id and u.alive:
			n += 1
	return n


func _cost(id: String) -> int:
	var c := float(GameData.def(id)["cost"])
	if GameData.UNITS.has(id):
		c *= float(fdata["unit_cost_mult"])
	return int(round(c))


func _ore_cost(id: String) -> int:
	return int(round(float(GameData.unit_ore(id)) * float(fdata["unit_cost_mult"])))


func _available(id: String) -> bool:
	if game.unit_level_block(id, team) != "":
		return false
	for r in GameData.def(id)["requires"]:
		if not game.has_building(r, team):
			return false
	var fac: String = GameData.def(id).get("faction", "")
	return fac == "" or fac == faction_id


## Puissance de combat d'un groupe (racine du produit PV x dégâts : loi de Lanchester).
func _power(list: Array) -> float:
	var hp := 0.0
	var dps := 0.0
	for e in list:
		hp += float(e.hp)
		if e.weapon != "":
			dps += float(e.dps)
	return sqrt(maxf(hp, 1.0) * maxf(dps, 0.5))


## Défenses ennemies (unités armées + bâtiments armés) autour d'un point, en pixels.
func _defenders_near(pos: Vector2, radius: float) -> Array:
	var out := []
	for u in game.units:
		if u.alive and not u.carried and game.hostile(u.team, team) and u.weapon != "" and u.position.distance_to(pos) < radius:
			out.append(u)
	for b in game.buildings:
		if b.alive and game.hostile(b.team, team) and b.weapon != "" and not b.offline and b.world_center().distance_to(pos) < radius:
			out.append(b)
	return out


func _aa_near(pos: Vector2, radius: float) -> int:
	var n := 0
	for e in _defenders_near(pos, radius):
		if GameData.can_hit_air(e.id):
			n += 1
	return n


func _army() -> Array:
	var out := []
	for u in game.units:
		if u.team == team and u.alive and u.role == "combat" and not u.guard and not u.air and u.control_timer <= 0.0:
			out.append(u)
	return out


func _air_units() -> Array:
	var out := []
	for u in game.units:
		if u.team == team and u.alive and u.role == "combat" and u.air and u.control_timer <= 0.0:
			out.append(u)
	return out


func _enemy_air() -> int:
	var n := 0
	for u in _foe_units():
		if u.air and u.weapon != "":
			n += 1
	return n


# --- Plan d'ensemble --------------------------------------------------------------

## Étape courante du plan, dans l'ordre : on ne passe à la suivante que lorsque la précédente est remplie.
func _plan_goal() -> String:
	var harv := _count("recolteur")
	var miners := _count("mineur")
	if harv < 2 or miners < 1 or not game.has_building("usine", team):
		return "économie"
	if _count_defenses() < mini(2, 1 + int(skill * 2.0)):
		return "défense"
	if _army().size() < wave_size:
		return "armée"
	if skill >= 0.25 and (_count("raffinerie") < 2 or _count("usine") < 2 or harv < 3):
		return "expansion"
	return "technologie"


func _count_defenses() -> int:
	var n := 0
	for b in game.buildings:
		if b.team == team and b.alive and b.weapon != "":
			n += 1
	return n


func _special_tower() -> String:
	for id in GameData.BUILDINGS.keys():
		var d: Dictionary = GameData.BUILDINGS[id]
		if d.get("faction", "") == faction_id and d.has("weapon"):
			return id
	return ""


# --- Construction -------------------------------------------------------------------

func _progress(delta: float) -> void:
	var factor := (1.0 if game.power_produced(team) >= game.power_used(team) else 0.5) / slowdown
	var ufactor: float = factor * game.unit_speed_bonus(team)
	if not build_q.is_empty():
		if not build_q["ready"] and not game.producer_busy("building", "", team):
			var dp := minf(delta * factor / build_q["time"], 1.0 - float(build_q["progress"]))
			if _pay_step(build_q, dp, false):
				build_q["progress"] += dp
				if build_q["progress"] >= 1.0:
					build_q["ready"] = true
		if build_q["ready"] and _place(build_q["id"]):
			build_q = {}
	if not unit_q.is_empty() and not game.producer_busy("unit", unit_q["id"], team):
		var du := minf(delta * ufactor / unit_q["time"], 1.0 - float(unit_q["progress"]))
		if _pay_step(unit_q, du, true):
			unit_q["progress"] += du
			if unit_q["progress"] >= 1.0:
				game.spawn_for(unit_q["id"], team)
				unit_q = {}


## Prélève la part du prix correspondant à l'avancement (comme pour le joueur) ; faux si les fonds manquent
## (la production se met alors en pause). Bâtiment : minerai + Solaris ; unité : Solaris + minerai.
func _pay_step(q: Dictionary, dp: float, is_unit: bool) -> bool:
	var tot_a := float(q.get("cost", 0))
	var tot_b := float(q.get("sol", 0)) if not is_unit else float(q.get("ore_u", 0))
	if tot_a <= 0.0 and tot_b <= 0.0:
		return true # file reprise d'une ancienne sauvegarde : déjà payée
	var ka := "sol" if is_unit else "ore"
	var kb := "ore" if is_unit else "sol"
	var ra: Array = game._pay_part(tot_a, dp, float(q.get("acc", 0.0)), game.funds(team, ka))
	var rb: Array = game._pay_part(tot_b, dp, float(q.get("acc_s", 0.0)), game.funds(team, kb))
	if not (ra[0] and rb[0]):
		return false
	game.spend(team, ka, int(ra[1]))
	game.spend(team, kb, int(rb[1]))
	q["acc"] = ra[2]
	q["acc_s"] = rb[2]
	return true


## Prochain bâtiment voulu selon le plan, l'âge de la partie et la finesse de l'IA.
func _next_building() -> String:
	var t: float = game.game_time
	for id in BASE_SEQ:
		if _count(id) < 1:
			return id
	var defs := _count_defenses()
	var tower := _defense_id()
	if defs < 1:
		return tower
	var harv := _count("recolteur")
	if skill >= 0.2 and _count("raffinerie") < 2 and t > 150.0 and harv >= 2:
		return "raffinerie"
	if defs < 2:
		return tower
	if skill >= 0.4 and _count("radar") < 1 and t > 240.0:
		return "radar"
	if skill >= 0.35 and _count("usine") < 2 and t > 300.0:
		return "usine"
	# Le joueur a des appareils : on s'équipe en anti-aérien
	if skill >= 0.4 and _enemy_air() >= 2 and _count_aa_defenses() < 1 + mini(_enemy_air() / 2, 3):
		return "batterie" if _available("batterie") else "tourelle"
	if skill >= 0.45 and t > 420.0:
		var tb := _tech_building()
		if tb != "":
			return tb
	var tower_goal := mini(1 + int(skill * 3.0 + t / 360.0), 7)
	if defs < tower_goal:
		return tower
	# Comme le joueur, l'IA est plafonnée par ses stocks : elle construit des silos quand elle approche de la limite
	if skill >= 0.3 and _count("silo") < 4 and credits > 0.8 * game.storage_cap("spice", team):
		return "silo"
	if skill >= 0.3 and _count("silo_minerai") < 4 and ore > 0.8 * game.storage_cap("ore", team):
		return "silo_minerai"
	if skill >= 0.6 and t > 780.0:
		for hid in _heavy_ids():
			var cap := 1 if GameData.def(hid)["weapon"] == "orbital" else 2
			if _count(hid) < cap and _available(hid) and (skill >= 0.75 or GameData.def(hid)["weapon"] != "orbital"):
				return hid
	if skill >= 0.5:
		var sb := _support_building()
		if sb != "":
			return sb
	if skill >= 0.55 and t > 540.0 and _count("aerodrome") < 1:
		return "aerodrome"
	if skill >= 0.6 and t > 700.0 and _count("reparation") < 1:
		return "reparation"
	if skill >= 0.7 and t > 900.0 and _count("fonderie") < 2:
		return "fonderie"
	return ""


func _count_aa_defenses() -> int:
	var n := 0
	for b in game.buildings:
		if b.team == team and b.alive and b.weapon != "" and GameData.can_hit_air(b.id):
			n += 1
	return n


func _storage_pressure() -> bool:
	return credits > 0.8 * game.storage_cap("spice", team) or ore > 0.8 * game.storage_cap("ore", team)


## Défenses : on varie les tours disponibles (communes et de faction), en choisissant la moins représentée.
func _defense_id() -> String:
	if skill < 0.45:
		return "tourelle"
	var best := "tourelle"
	var best_n := _count("tourelle") * 1.3
	for id in _tower_ids():
		if id == "tourelle" or not _available(id):
			continue
		var n := float(_count(id)) + randf() * 0.5
		if n < best_n:
			best_n = n
			best = id
	return best


## Tours « ordinaires » : armées, ni artillerie lourde (portée >= 12) ni arme orbitale.
func _tower_ids() -> Array:
	var out: Array = []
	for id in GameData.BUILDINGS.keys():
		var d: Dictionary = GameData.BUILDINGS[id]
		if not d.has("weapon") or id == "batterie":
			continue
		var f: String = d.get("faction", "")
		if f != "" and f != faction_id:
			continue
		if int(d.get("range", 0)) >= 12 or d["weapon"] == "orbital":
			continue
		out.append(id)
	return out


## Artillerie lourde (portée >= 12) et arme orbitale de la faction, quand elles sont disponibles.
func _heavy_ids() -> Array:
	var out: Array = []
	for id in GameData.BUILDINGS.keys():
		var d: Dictionary = GameData.BUILDINGS[id]
		var f: String = d.get("faction", "")
		if d.has("weapon") and (f == faction_id) and (int(d.get("range", 0)) >= 12 or d["weapon"] == "orbital"):
			out.append(id)
	return out


## Bâtiment technologique manquant pour fabriquer une unité de la faction.
func _tech_building() -> String:
	for id in fdata["units"] + fdata["air"]:
		for r in GameData.def(id)["requires"]:
			if game.has_building(r, team) or not GameData.BUILDINGS.has(r):
				continue
			if GameData.def(r).get("faction", "") == "":
				continue
			if _available(r):
				return r
	return ""


## Bâtiments de soutien de la faction (soins, auras, revenus, énergie, détection) : un de chaque, avec le temps.
func _support_building() -> String:
	var t: float = game.game_time
	for id in GameData.BUILDINGS.keys():
		var d: Dictionary = GameData.BUILDINGS[id]
		if d.get("faction", "") != faction_id or d.has("weapon") or d.get("wall", false):
			continue
		if not (d.has("heal") or d.has("aura_regen") or d.has("income") or d.has("ore_income") or int(d.get("vision", 0)) > 12):
			continue
		var delay := 600.0 + 120.0 * float(_count_support())
		if t > delay and _count(id) < 1 and _available(id):
			return id
	return ""


func _count_support() -> int:
	var n := 0
	for b in game.buildings:
		if b.team == team and b.alive and b.id != "reparation" and b.id != "marche" and b.id != "serre":
			var d := GameData.def(b.id)
			if d.get("faction", "") == faction_id and not d.has("weapon") and (d.has("heal") or d.has("aura_regen") or d.has("income") or d.has("ore_income") or int(d.get("vision", 0)) > 12):
				n += 1
	return n


func _think_build() -> void:
	goal_text = _plan_goal()
	if not build_q.is_empty():
		return
	var want := ""
	# Énergie d'abord : jamais en panne
	if game.power_produced(team) - game.power_used(team) < 30:
		want = "centrale"
	else:
		if _priority_upgrade():
			return
		want = _next_building()
	if want == "":
		_try_upgrade()
		return
	# Jamais de bâtiment sans l'énergie nécessaire : on construit d'abord une centrale
	if GameData.BUILDINGS.has(want) and game.power_produced(team) - game.power_used(team) < -int(GameData.BUILDINGS[want]["power"]):
		want = "centrale"
	# Mêmes règles que le joueur : 10 % du prix pour lancer, le reste est prélevé au fil des travaux
	if not _available(want) or ore < _cost(want) * game.START_FRAC or credits < GameData.sol_cost(want) * game.START_FRAC:
		return
	build_q = {"id": want, "progress": 0.0, "ready": false, "cost": _cost(want), "sol": GameData.sol_cost(want),
			"acc": 0.0, "acc_s": 0.0,
			"time": float(GameData.def(want)["time"]) * float(fdata["build_time_mult"])}


## Améliorations qui débloquent des unités et des bâtiments : prioritaires dès que leur heure est venue.
func _priority_upgrade() -> bool:
	var t: float = game.game_time
	if _economy_first():
		return false
	var plan: Array = []
	if skill >= 0.2:
		plan.append(["usine", 2, 150.0])
	if skill >= 0.3:
		plan.append(["chantier", 2, 280.0])
	if skill >= 0.45:
		plan.append(["usine", 3, 520.0])
		plan.append(["centrale", 2, 400.0])
	for step in plan:
		if t < float(step[2]):
			continue
		for b in game.buildings:
			if b.team != team or b.id != step[0] or not b.alive or b.level >= int(step[1]):
				continue
			var why: String = game.upgrade_block(b, ore)
			if why == "" and ore >= game.upgrade_cost(b) + 100:
				game.start_upgrade(b)
				return true
			# faute de minerai : on met de côté plutôt que de le dépenser ailleurs (90 s au plus, pas de blocage)
			var saving: bool = why == "Minerai insuffisant" or (why == "" and ore < game.upgrade_cost(b) + 100)
			if not saving:
				_save_since = -1.0
				return false
			if _save_since < 0.0:
				_save_since = t
			if t - _save_since > 90.0:
				if t - _save_since > 150.0:
					_save_since = -1.0
				return false
			return true
	return false


## Une fois la base construite, l'IA améliore ses bâtiments quand elle a du minerai en réserve.
## Pénurie de minerai : avant d'améliorer quoi que ce soit, assez de mineurs et une armée minimale.
func _economy_first() -> bool:
	if not game.has_building("fonderie", team):
		return false
	var t: float = game.game_time
	var miners := _count("mineur")
	if miners < (1 if t < 200.0 else 2) and game.worker_cap("mineur", team) > miners:
		return true
	return t > 240.0 and _army().size() < 3 and ore < 700


func _try_upgrade() -> void:
	if _economy_first():
		return
	var order := ["usine", "chantier", "centrale", "raffinerie", "fonderie", "tourelle", "radar"]
	var reserve := 400 if skill < 0.5 else 250
	for id in order:
		for b in game.buildings:
			if b.team != team or b.id != id or not b.alive:
				continue
			if game.upgrade_block(b, ore) == "" and ore >= game.upgrade_cost(b) + reserve:
				game.start_upgrade(b)
				return


## Place le bâtiment terminé ; renvoie false s'il n'y a pas de place.
func _place(id: String) -> bool:
	var base: Vector2 = home
	var toward: Vector2 = foe
	var size: Vector2i = GameData.BUILDINGS[id]["size"]
	var armed: bool = GameData.BUILDINGS[id].has("weapon")
	# Raffinerie et fonderie du côté de leur champ : des allers-retours plus courts pour les ouvriers
	var field := Vector2(-1, -1)
	if id == "raffinerie" or id == "fonderie":
		for f in (game.spice_fields if id == "raffinerie" else game.ore_fields):
			if field.x < 0.0 or base.distance_to(f) < base.distance_to(field):
				field = f
	for reach in [11, 16]:
		var best := Vector2i(-1, -1)
		var best_s := INF
		for dx in range(-reach, reach + 1):
			for dy in range(-reach, reach + 1):
				var cell := Vector2i(base) + Vector2i(dx, dy)
				if not game._can_place(id, cell, team) or not _has_gap(cell, size):
					continue
				var center := Vector2(cell) + Vector2(size) / 2.0
				# Défenses vers l'ennemi, silo/radar à l'abri, le reste près de la base
				var s: float
				if armed:
					s = center.distance_to(toward) * 0.5 + center.distance_to(base)
				elif field.x >= 0.0:
					s = center.distance_to(base) + center.distance_to(field) * 0.8
				elif id == "radar" or id == "silo" or id == "silo_minerai":
					s = center.distance_to(base) - center.distance_to(toward) * 0.2
				else:
					s = center.distance_to(base)
				if s < best_s:
					best_s = s
					best = cell
		if best.x >= 0:
			game._place_building(id, best, team)
			return true
	return false


## Garde une case libre autour du bâtiment pour que les unités circulent.
func _has_gap(cell: Vector2i, size: Vector2i) -> bool:
	for x in range(cell.x - 1, cell.x + size.x + 1):
		for y in range(cell.y - 1, cell.y + size.y + 1):
			if game.occupied.has(Vector2i(x, y)):
				return false
	return true


# --- Production d'unités --------------------------------------------------------------

## Montée en puissance progressive : l'IA ne peut pas aligner d'emblée toute son armée.
## La taille autorisée croît avec le temps de jeu (plus vite pour une IA habile).
func _army_limit() -> int:
	var ramp := 4 + int(game.game_time / 80.0 * (0.5 + skill))
	return mini(max_army, ramp)


func _under_cap() -> bool:
	var cap: int = game.army_cap(team)
	return cap <= 0 or game.army_count(team) < cap


func _think_units() -> void:
	var harv := _count("recolteur")
	var miners := _count("mineur")
	var harv_goal := 2 + (1 if _count("raffinerie") >= 2 else 0) + (1 if skill > 0.6 and game.game_time > 600.0 else 0)
	# Le minerai nourrit bâtiments, améliorations ET unités : plus de mineurs, surtout si on en manque
	var miner_goal := 1 + (1 if skill > 0.25 and game.game_time > 120.0 else 0) \
			+ (1 if skill > 0.45 and game.game_time > 420.0 else 0)
	if ore < 150 and credits > 600 and miners >= miner_goal:
		miner_goal += 1
	if unit_q.is_empty():
		var want := ""
		# Un ouvrier plafonné ou indisponible ne doit jamais bloquer la production du reste
		if game.has_building("raffinerie", team) and harv < harv_goal and _available("recolteur") \
				and game.worker_cap("recolteur", team) > harv:
			want = "recolteur"
		elif game.has_building("fonderie", team) and miners < miner_goal and _available("mineur") \
				and game.worker_cap("mineur", team) > miners:
			want = "mineur"
		elif game.has_building("usine", team) and _army().size() < _army_limit() and _under_cap():
			want = _pick_ground_unit()
		# Aérodrome : une unité volante de temps en temps (même file de production que le sol, comme le joueur)
		if want != "recolteur" and want != "mineur" and skill >= 0.5 and game.has_building("aerodrome", team) \
				and _air_units().size() < 3 + int(skill * 6.0) and _since_air >= 2:
			var aid := _pick_air_unit()
			if aid != "" and _available(aid):
				want = aid
		if want != "" and _available(want) and credits >= _cost(want) * game.START_FRAC and ore >= _ore_cost(want) * game.START_FRAC:
			if GameData.UNITS[want].get("air", false):
				_since_air = 0
			else:
				_since_air += 1
			unit_q = {"id": want, "progress": 0.0, "time": float(GameData.def(want)["time"]),
					"cost": _cost(want), "ore_u": _ore_cost(want), "acc": 0.0, "acc_s": 0.0}


## Choisit le prochain char selon ce que le joueur aligne : efficacité de l'arme contre ses blindages,
## anti-aérien s'il a des appareils, rapport efficacité/prix, et un peu de variété.
func _pick_ground_unit() -> String:
	var ids: Array = fdata["units"].filter(func(i: String) -> bool: return _available(i) and GameData.UNITS[i].has("weapon"))
	if ids.is_empty():
		return ""
	if skill < 0.3:
		var r: String = ids[randi() % ids.size()]
		return ids[0] if randf() < 0.3 else r
	var armor_count := {"light": 0, "medium": 0, "heavy": 0, "building": 0}
	var total := 0
	for u in _foe_units():
		if u.weapon != "" and not u.air:
			armor_count[u.armor] = int(armor_count.get(u.armor, 0)) + 1
			total += 1
	var enemy_air := _enemy_air()
	var mine := {}
	for u in _army():
		mine[u.id] = int(mine.get(u.id, 0)) + 1
	var best := ""
	var best_w := -1.0
	for id in ids:
		var d: Dictionary = GameData.UNITS[id]
		var w := 1.0
		var c := float(_cost(id))
		w = sqrt(maxf(float(d["hp"]) * float(d["dps"]) / (c * c) * 1000.0, 1.0))
		if total > 0:
			var eff := 0.0
			for a in armor_count:
				eff += float(armor_count[a]) * GameData.mult(String(d["weapon"]), a)
			w *= pow(eff / total, 2.0)
		if GameData.can_hit_air(id) and d.get("aa", false):
			w *= 3.0 if enemy_air >= 2 else (0.8 if enemy_air == 0 else 1.6)
		w /= 1.0 + 0.18 * float(mine.get(id, 0))
		# en pénurie de minerai, on préfère ce qu'on peut payer tout de suite
		var oc := float(_ore_cost(id))
		if oc > 0.0 and ore < oc * 2.0:
			w *= clampf(float(ore) / (oc * 2.0), 0.15, 1.0)
		w *= 0.75 + randf() * 0.5
		if w > best_w:
			best_w = w
			best = id
	return best


func _pick_air_unit() -> String:
	var ids: Array = []
	for id in fdata["air"]:
		if GameData.UNITS[id].get("role", "") == "combat" and GameData.UNITS[id].has("weapon") and _available(id):
			ids.append(id)
	if ids.is_empty():
		return ""
	var enemy_air := _enemy_air()
	var best := ""
	var best_w := -1.0
	for id in ids:
		var d: Dictionary = GameData.UNITS[id]
		var w := 1.0 + randf()
		if d.get("aa", false) and enemy_air >= 1:
			w *= 3.0       # chasseurs contre les appareils adverses
		elif not d.get("aa", false):
			w *= 1.6       # bombardiers : ils frappent le sol
		if w > best_w:
			best_w = w
			best = id
	return best


## Modernise des unités de combat quand l'Usine niveau 2 est là et qu'il reste de l'argent.
func _think_tech() -> void:
	if skill < 0.4 or game.best_level("usine", team) < 2:
		return
	for u in game.units:
		if u.team != team or not u.alive or u.role != "combat" or u.tech > 0 or u.tech_left > 0.0:
			continue
		if not GameData.UNIT_TECH.has(u.id):
			continue
		var cost := GameData.tech_cost(u.id)
		if credits < cost + 400:
			return
		u.tech_cost = float(cost) # prélevé progressivement, comme pour le joueur
		u.tech_acc = 0.0
		u.tech_total = GameData.tech_time(u.id)
		u.tech_left = u.tech_total
		return


# --- Surveillance de la base ----------------------------------------------------------

## Repère une attaque (bâtiment qui perd des PV ou intrus proche) et mémorise le moment.
func _watch_base() -> void:
	var now: float = game.game_time
	for b in game.buildings:
		if b.team != team or not b.alive:
			continue
		var key: int = b.get_instance_id()
		if _hp_seen.has(key) and b.hp < float(_hp_seen[key]) - 1.0:
			_alert_until = now + 20.0
		_hp_seen[key] = b.hp
	var base_world: Vector2 = home * game.TILE
	for u in _foe_units():
		if u.weapon != "" and u.position.distance_to(base_world) < 13.0 * game.TILE:
			_alert_until = now + 20.0
			return


func _intruder():
	var base_world: Vector2 = home * game.TILE
	var best = null
	var best_d := INF
	for u in _foe_units():
		var d: float = u.position.distance_to(base_world)
		if d < 14.0 * game.TILE and d < best_d and (u.weapon != "" or best == null):
			best_d = d
			best = u
	return best


# --- Armée : assauts organisés ----------------------------------------------------------

func _think_army() -> void:
	var army := _army()
	assaulting = mode == "stage" or mode == "attack"
	if army.is_empty():
		if assaulting:
			wave_ended = game.game_time
		mode = "muster"
		squad.clear()
		assaulting = false
		return
	var now: float = game.game_time
	var base_world: Vector2 = home * game.TILE
	_mode_t += THINK

	# Défense : toute l'armée disponible répond à l'attaque de la base
	var intruder = _intruder()
	if intruder != null or now < _alert_until:
		var tgt := Vector2i(-1, -1)
		if intruder != null:
			tgt = game.world_to_cell(intruder.position)
		var threat := _power(_defenders_near(base_world, 14.0 * game.TILE))
		var mine := _power(army)
		# On ne rappelle un assaut que si la base est vraiment menacée
		var recall := assaulting and threat > 0.7 * _power(squad_alive()) and skill >= 0.3
		if (not assaulting or recall) and tgt.x >= 0:
			for u in army:
				if u.state == "idle" or recall or u.state == "amove":
					u.order_amove(tgt)
			if recall:
				mode = "muster"
				squad.clear()
				wave_ended = now
			return
		if not assaulting:
			return

	match mode:
		"muster":
			_muster(army, now)
		"stage":
			_stage(now)
		"attack":
			_attack(now)
		"retreat":
			_retreat(now)


## Bâtiment allié en service qui soigne les unités (atelier de réparation), ou null.
func _heal_site():
	for b in game.buildings:
		if b.team == team and b.alive and not b.offline and GameData.def(b.id).has("heal"):
			return b
	return null


## Micro-gestion : focalisation des tirs, repli des blessés, secours des ouvriers attaqués.
func _think_tactics() -> void:
	if skill < 0.45:
		return
	var foes := _foe_units().filter(func(u) -> bool: return u.weapon != "")
	var army := _army()
	var home_cell: Vector2i = Vector2i(home.round())
	# 1. Les blessés se replient (et ne rejoignent pas une vague avant d'être réparés) — seulement si
	#    le camp peut les soigner (atelier de réparation, régénération) : sinon ils se battent jusqu'au bout
	var heal_site = _heal_site()
	var can_heal: bool = heal_site != null or float(fdata.get("regen", 0.0)) > 0.0
	if heal_site != null:
		home_cell = game.dock_cell(heal_site, home_cell)
	for u in army:
		if u.has_meta("ai_hurt") and not can_heal:
			u.remove_meta("ai_hurt")
		if not can_heal:
			continue
		var frac: float = u.hp / maxf(u.max_hp, 1.0)
		if u.has_meta("ai_hurt"):
			if frac > 0.6:
				u.remove_meta("ai_hurt")
			continue
		if frac < 0.28 and skill >= 0.5 and (u in squad or u.state == "attack"):
			# on ne fuit que s'il reste de quoi tenir : sinon il vend chèrement sa peau
			var menace := false
			for f in foes:
				if f.position.distance_to(u.position) < 9.0 * game.TILE:
					menace = true
					break
			if menace:
				u.set_meta("ai_hurt", true)
				squad.erase(u)
				stage_of.erase(u)
				u.order_path(game.path_to(u.position, game._find_free_cell(home_cell + Vector2i(0, 0))))
	# 2. Focalisation : tout le monde tire sur l'ennemi le plus fragile à portée
	if skill >= 0.55:
		var fighters := army.filter(func(u: Unit) -> bool: return (u.state == "attack" or u.state == "amove") and not u.has_meta("ai_hurt"))
		for u in fighters:
			var cur = u.target
			if cur != null and is_instance_valid(cur) and cur is Unit and cur.alive and cur.weapon != "":
				continue
			var best = null
			var best_s := INF
			for f in foes:
				if f.air and not GameData.can_hit_air(u.id):
					continue
				var d: float = f.position.distance_to(u.position)
				if d > u.w_range * 1.15:
					continue
				var s: float = f.hp + d * 0.2 - float(f.dps) * 4.0
				if s < best_s:
					best_s = s
					best = f
			if best != null:
				u.order_attack(best)
	# 3. Un ouvrier attaqué : l'armée au repos accourt
	var now: float = game.game_time
	for w in game.units:
		if w.team != team or not w.alive or not w.is_worker():
			continue
		var key: int = w.get_instance_id()
		var hurt: bool = _w_hp.has(key) and w.hp < float(_w_hp[key]) - 1.0
		_w_hp[key] = w.hp
		if not hurt:
			continue
		var att = null
		for f in foes:
			if f.position.distance_to(w.position) < 9.0 * game.TILE:
				att = f
				break
		if att == null:
			continue
		_alert_until = maxf(_alert_until, now + 8.0)
		var sent := 0
		for u in army:
			if sent >= 6:
				break
			if (u.state == "idle" or u.state == "amove") and not (u in squad) and not u.has_meta("ai_hurt"):
				u.order_attack(att) if not att.air or GameData.can_hit_air(u.id) else u.order_amove(game.world_to_cell(w.position))
				sent += 1


func squad_alive() -> Array:
	return squad.filter(func(u) -> bool: return is_instance_valid(u) and u.alive)


## Point de rassemblement : devant la base, côté ennemi, pour grouper les unités avant de partir.
func _rally_cell() -> Vector2i:
	var h: Vector2 = home
	var dir: Vector2 = (foe - h).normalized() if foe.distance_to(h) > 1.0 else Vector2.DOWN
	var c := Vector2i((h + dir * 11.0).round())
	return game._find_free_cell(c)


func _muster(army: Array, now: float) -> void:
	var idle := army.filter(func(u: Unit) -> bool: return u.state == "idle" and not (u in raid) and not u.has_meta("ai_hurt"))
	# Les unités au repos se placent au rassemblement (skill : sinon elles restent où elles sont apparues)
	if skill >= 0.3:
		var rc := _rally_cell()
		for u in idle:
			if u.position.distance_to(game._cell_to_world(rc)) > 7.0 * game.TILE:
				u.order_amove(rc)
	# Disponibles pour une vague : tout ce qui n'est ni en raid ni blessé (une unité qui rejoint le point
	# de rassemblement ou qui échange des tirs à proximité compte aussi, sinon la vague ne part jamais)
	var avail := army.filter(func(u: Unit) -> bool: return not (u in raid) and not u.has_meta("ai_hurt"))
	var need := mini(wave_size, maxi(4, int(_army_limit() * 0.7)))
	var full_need := need
	var pause := wave_pause
	if skill >= 0.5 and now >= wave_grace * 0.7:
		# Contre-attaque : l'adversaire a peu d'armée, on frappe sans attendre
		var fa := _foe_units().filter(func(u) -> bool: return u.weapon != "" and not u.is_worker())
		if _power(avail) > 1.8 * _power(fa) and avail.size() >= 4:
			need = 4
			pause = wave_pause * 0.3
	if now < wave_grace * (0.7 if need < full_need else 1.0) or now - wave_ended < pause or avail.size() < need:
		return
	# Force engagée contre ce que l'on va affronter : on n'attaque pas à perte
	var tgt = _pick_target()
	if tgt == null:
		return
	var defend := _power(_defenders_near(tgt.world_center(), 9.0 * game.TILE))
	var mine := _power(avail)
	if skill >= 0.3 and mine < 0.75 * defend and now - wave_ended < wave_pause * 3.0:
		return # trop faible : on attend du renfort
	squad = avail.duplicate()
	if skill >= 0.4 and squad.size() >= 6:
		squad = squad.slice(0, int(squad.size() * 0.8)) # une réserve reste à la base
	squad_start = squad.size()
	target_b = tgt
	wave_started = now
	wave_size = mini(wave_size + 1, 12 + int(skill * 14.0))
	_mode_t = 0.0
	if skill >= 0.3:
		# Approche groupée jusqu'à un point d'attente avant l'attaque
		var from: Vector2i = game.world_to_cell(home * game.TILE)
		var tc: Vector2i = game.world_to_cell(tgt.world_center())
		var v: Vector2 = (Vector2(from) - Vector2(tc))
		var off := Vector2(tc) + (v.normalized() * 11.0 if v.length() > 0.1 else Vector2.ZERO)
		stage_cell = game._find_free_cell(Vector2i(off.round()))
		stage_of.clear()
		if skill >= 0.7 and squad.size() >= 8:
			# Manœuvre en tenaille : la moitié du groupe se place sur chaque flanc de la cible
			var perp := v.normalized().orthogonal() * 8.0
			var ca: Vector2i = game._find_free_cell(Vector2i((off + perp).round()))
			var cb: Vector2i = game._find_free_cell(Vector2i((off - perp).round()))
			for i in squad.size():
				stage_of[squad[i]] = ca if i % 2 == 0 else cb
		for u in squad:
			u.order_amove(stage_of.get(u, stage_cell))
		mode = "stage"
	else:
		for u in squad:
			u.order_amove(game.dock_cell(tgt, game.world_to_cell(u.position)))
		mode = "attack"
	assaulting = true


## Force adverse armée autour du centre du groupe.
func _squad_threat(alive: Array) -> float:
	var cen := Vector2.ZERO
	for u in alive:
		cen += u.position
	cen /= maxf(float(alive.size()), 1.0)
	return _power(_defenders_near(cen, 11.0 * game.TILE))


func _stage(now: float) -> void:
	var alive := squad_alive()
	if skill >= 0.4 and not alive.is_empty() and _squad_threat(alive) > 1.8 * _power(alive):
		mode = "retreat"
		_mode_t = 0.0
		return
	if alive.size() < squad_start * 0.5:
		mode = "retreat"
		_mode_t = 0.0
		return
	var near := 0
	for u in alive:
		var sc: Vector2 = game._cell_to_world(stage_of.get(u, stage_cell))
		if u.position.distance_to(sc) < 7.0 * game.TILE:
			near += 1
	# Attaque quand la plupart des unités sont groupées (ou après trop d'attente)
	if near >= maxi(int(alive.size() * 0.7), 1) or _mode_t > 70.0:
		mode = "attack"
		_mode_t = 0.0
		_order_attack(alive)


func _order_attack(units: Array) -> void:
	if target_b == null or not is_instance_valid(target_b) or not target_b.alive:
		target_b = _pick_target()
	if target_b == null:
		return
	for u in units:
		u.order_amove(game.dock_cell(target_b, game.world_to_cell(u.position)))


func _attack(now: float) -> void:
	var alive := squad_alive()
	if alive.is_empty() or alive.size() < squad_start * 0.35 and skill >= 0.3:
		mode = "retreat"
		_mode_t = 0.0
		return
	# Cible détruite : on enchaîne sur la suivante la plus intéressante, sinon fin de vague
	if target_b == null or not is_instance_valid(target_b) or not target_b.alive:
		target_b = _pick_target(target_b.world_center() if is_instance_valid(target_b) else Vector2(-1, -1))
		if target_b == null:
			_end_wave(now)
			return
		_order_attack(alive)
		return
	# Rapport de force local défavorable : repli pour se refaire
	if skill >= 0.4 and _mode_t > 6.0 and _squad_threat(alive) > 2.0 * _power(alive):
		mode = "retreat"
		_mode_t = 0.0
		return
	if skill >= 0.4:
		var def := _power(_defenders_near(target_b.world_center(), 9.0 * game.TILE))
		if def > 1.6 * _power(alive) and _mode_t > 15.0:
			mode = "retreat"
			_mode_t = 0.0
			return
	# Les unités redevenues inactives repartent à l'attaque
	var idle := alive.filter(func(u: Unit) -> bool: return u.state == "idle")
	if not idle.is_empty():
		_order_attack(idle)
	if now - wave_started > 240.0 and idle.size() >= alive.size():
		_end_wave(now)


## Décrochage : déplacement simple vers le point de rassemblement (sans s'arrêter pour tirer).
func _fall_back(list: Array) -> void:
	var rc := _rally_cell()
	var slots: Dictionary = game._assign_slots(list.filter(func(u) -> bool: return is_instance_valid(u) and u.alive), rc)
	for u in slots:
		if u.state != "move":
			u.order_path(game.path_to(u.position, slots[u]))


func _retreat(now: float) -> void:
	_fall_back(squad_alive())
	if _mode_t > 25.0:
		_end_wave(now)


func _end_wave(now: float) -> void:
	mode = "muster"
	squad.clear()
	target_b = null
	assaulting = false
	wave_ended = now


## Cible d'assaut : bâtiment ennemi au meilleur rapport valeur / défenses / distance.
func _pick_target(near := Vector2(-1, -1)):
	var best = null
	var best_s := -INF
	var home_px: Vector2 = home * game.TILE
	for b in game.buildings:
		if not b.alive or not game.hostile(b.team, team):
			continue
		var c: Vector2 = b.world_center()
		var value := _value_of(b.id)
		var s: float
		if skill < 0.3:
			s = -c.distance_to(home_px) # niveau simple : le plus proche
		else:
			var def := _power(_defenders_near(c, 9.0 * game.TILE))
			var ref: Vector2 = near if near.x >= 0.0 else home_px
			s = value * 100.0 / (1.0 + def * 0.15) - c.distance_to(ref) * 0.08
		if s > best_s:
			best_s = s
			best = b
	return best


func _value_of(id: String) -> float:
	match id:
		"raffinerie", "fonderie":
			return 3.0
		"centrale", "reacteur", "relais_solaire":
			return 3.0
		"usine", "aerodrome":
			return 2.6
		"chantier":
			return 2.2
		"radar":
			return 1.6
		"mur", "mur_acier", "mur_cristal", "mur_titane", "mur_epines", "mur_obsidienne":
			return 0.2
		"serre":
			return 2.0
	return 1.0


# --- Raids sur les récolteurs ---------------------------------------------------------------

## Petit groupe rapide qui harcèle les ouvriers ennemis mal défendus, puis rentre.
func _think_raid() -> void:
	if skill < 0.3:
		return
	var now: float = game.game_time
	raid = raid.filter(func(u) -> bool: return is_instance_valid(u) and u.alive)
	if not raid.is_empty():
		_run_raid(now)
		return
	if now < wave_grace * 0.6 or now - raid_ended < 80.0 or mode == "attack":
		return
	var idle := _army().filter(func(u: Unit) -> bool: return u.state == "idle" and not (u in squad))
	if idle.size() < 3:
		return
	idle.sort_custom(func(a: Unit, b: Unit) -> bool: return a.speed > b.speed)
	var tgt = _raid_target_pick()
	if tgt == null:
		return
	raid_target = tgt
	raid = idle.slice(0, mini(3 + int(skill * 2.0), idle.size()))
	_raid_t = 0.0
	for u in raid:
		u.order_attack(tgt)


func _raid_target_pick():
	var best = null
	var best_s := INF
	var home_px: Vector2 = home * game.TILE
	for u in _foe_units():
		if not u.is_worker():
			continue
		var def := _power(_defenders_near(u.position, 8.0 * game.TILE))
		if def > 8.0:
			continue # trop bien gardé
		var s: float = u.position.distance_to(home_px) + def * 40.0
		if s < best_s:
			best_s = s
			best = u
	return best


func _run_raid(now: float) -> void:
	_raid_t += THINK
	var done: bool = raid_target == null or not is_instance_valid(raid_target) or not raid_target.alive
	var hurt := false
	for u in raid:
		if u.hp < u.max_hp * 0.4:
			hurt = true
	if done and _raid_t < 60.0 and not hurt:
		# cible suivante dans les environs
		var nxt = _raid_target_pick()
		if nxt != null:
			raid_target = nxt
			for u in raid:
				u.order_attack(nxt)
			return
	# Raid intercepté par plus fort que lui : on décroche au lieu de se faire détruire pour rien
	var outgunned := false
	if not raid.is_empty():
		var cen := Vector2.ZERO
		for u in raid:
			cen += u.position
		cen /= float(raid.size())
		outgunned = _power(_defenders_near(cen, 8.0 * game.TILE)) > 1.1 * _power(raid)
	if done or hurt or outgunned or _raid_t > 90.0:
		_fall_back(raid)
		raid.clear()
		raid_target = null
		raid_ended = now


# --- Escadrille aérienne ------------------------------------------------------------------------

func _think_air() -> void:
	if skill < 0.5:
		return
	var now: float = game.game_time
	air_wave = air_wave.filter(func(u) -> bool: return is_instance_valid(u) and u.alive)
	var air := _air_units()
	if not air_wave.is_empty():
		var hurt := 0
		for u in air_wave:
			if u.hp < u.max_hp * 0.45:
				hurt += 1
		var all_idle := air_wave.all(func(u) -> bool: return u.state == "idle")
		if hurt * 2 >= air_wave.size() or all_idle or now - air_ended > 120.0:
			for u in air_wave:
				u.order_amove(Vector2i(home.round()))
			air_wave.clear()
			air_ended = now
		return
	if now - air_ended < 60.0:
		return
	var idle := air.filter(func(u: Unit) -> bool: return u.state == "idle")
	if idle.size() < 3:
		return
	# Cible : bâtiment de valeur sans anti-aérien à proximité ; sinon un ouvrier isolé
	var best = null
	var best_s := -INF
	for b in game.buildings:
		if not b.alive or not game.hostile(b.team, team):
			continue
		var c: Vector2 = b.world_center()
		if _aa_near(c, 11.0 * game.TILE) > 0:
			continue
		var s := _value_of(b.id) * 100.0 - c.distance_to(home * game.TILE) * 0.05
		if s > best_s:
			best_s = s
			best = b
	if best == null:
		return
	air_wave = idle
	for u in air_wave:
		u.order_amove(game.world_to_cell(best.world_center()))


# --- Sauvegarde -----------------------------------------------------------------------------------

func export_state() -> Dictionary:
	return {"credits": credits, "ore": ore, "build_q": build_q.duplicate(true), "unit_q": unit_q.duplicate(true),
			"skill": skill,
			"wave_size": wave_size, "assaulting": false, "wave_started": wave_started,
			"wave_ended": wave_ended, "think_t": _think_t, "deploy_at": deploy_at, "active": active}


func restore_state(s: Dictionary) -> void:
	credits = int(s["credits"])
	ore = int(s["ore"])
	build_q = s["build_q"]
	unit_q = s["unit_q"]
	if unit_q.is_empty() and not s.get("air_q", {}).is_empty():
		unit_q = s["air_q"] # anciennes sauvegardes : une seule file d'unités
	if unit_q.has("id"):
		unit_q["id"] = GameData.migrate_id(String(unit_q["id"]))
	skill = float(s.get("skill", skill))
	wave_size = int(s["wave_size"])
	assaulting = false
	mode = "muster"
	wave_started = float(s["wave_started"])
	wave_ended = float(s["wave_ended"])
	_think_t = float(s["think_t"])
	deploy_at = float(s["deploy_at"])
	active = bool(s["active"])
