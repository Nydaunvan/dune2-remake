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
var offline := false # défense hors tension (énergie insuffisante)
var outpost := -1 # indice d'avant-poste de mission (-1 : aucun)
var team := 0
var alive := true
var hp := 500.0
var repairing := false
var up_left := 0.0  # amélioration en cours : secondes restantes
var up_total := 0.0
var up_cost := 0.0   # prix restant à prélever progressivement (joueur) ; 0 : déjà payé
var up_acc := 0.0
var max_hp := 500.0
var armor := "building"
var weapon := ""
var dps := 0.0
var w_range := 0.0 # px
var _muzzle_i := 0
var cooldown := 0.0
var aim := 0.0
var _scan := 0.0
var _sprite_ok := false
var level := 1
var base_hp := 500.0
var _soak_acc := 0.0 # dégâts récents (décroissance ~1 s)
var _soak_t := 0.0
var base_power := 0
var base_dps := 0.0
var vision := 7
var seen := true # visible actuellement par le joueur (brouillard de guerre)
var selected := false:
	set(value):
		selected = value
		queue_redraw()
var _target
var dock_user = null # véhicule actuellement sur la rampe (déchargement / réparation)
var door_t := 0.0   # porte de production ouverte (secondes restantes)
var door_dur := 1.7
var shot_t := 0.0   # éclat de tir récent (toutes les défenses)
var shot_at := Vector2.ZERO # position locale du bout de canon lors du dernier tir
var fx_t := 0.0     # éclat de tir (tour sonique)
var _phase := randf() * 20.0


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
	if get_node_or_null("Bars") == null:
		var bars := BarsLayer.new(self)
		bars.name = "Bars"
		add_child(bars)
	var d := GameData.def(id)
	max_hp = GameData.building_hp(id)
	hp = max_hp
	base_hp = max_hp
	base_power = power
	vision = int(d.get("vision", GameData.BUILDING_VISION))
	armor = d.get("armor", "building")
	weapon = d.get("weapon", "")
	dps = float(d.get("dps", 0))
	base_dps = dps
	w_range = float(d.get("range", 0)) * tile
	if weapon == "":
		set_physics_process(false)


## De nouveaux modèles 3D viennent d'être cuits : on retente le dessin 3D (niveaux, têtes de tourelle…).
func refresh_sprites() -> void:
	_sprite_ok = false
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if GameData.def(id).get("wall", false):
		set_process(false)
		return
	# Redessine une fois les modèles 3D cuits
	if not _sprite_ok and game != null and game.bank != null and game.bank.has("%s|%s" % [id, game.faction_id_of(team)]):
		_sprite_ok = true
		queue_redraw()
	if not _sprite_ok:
		return
	if not _animated():
		set_process(false)
		return
	door_t = maxf(0.0, door_t - delta)
	fx_t = maxf(0.0, fx_t - delta)
	shot_t = maxf(0.0, shot_t - delta)
	if visible and _on_screen():
		queue_redraw() # animations : radar, tour sonique, énergie, fonderie, portes


## Bâtiments dont le dessin est animé en continu.
func _animated() -> bool:
	return id in ["radar", "tour_sonique", "tour_prisme", "serre", "mur_cristal", "centrale", "reacteur", "fonderie", "raffinerie",
			"chantier", "marche", "reparation", "aerodrome", "usine", "silo", "silo_minerai", "comptoir_solis", "caravanserail",
			"fonderie_lourde", "bunker", "tour_acide", "batterie", "mortier_lourd", "batterie_mortiers", "lanceur_spores", "canon_solaire",
			"marteau_guerre", "pluie_acide", "nova_cristal", "tourelle"]


## Animations des autres bâtiments : jauges de silo, étincelles de revenu, fumées, lueurs d'armes, charge des armes orbitales,
## éclat de tir. Plus le niveau est haut, plus c'est dense ; hors tension, tout s'éteint.
func _draw_anim_more(c: Vector2, t: float, powered: bool, acc: Color) -> void:
	var k := 1.0 if powered else 0.25
	match id:
		"silo", "silo_minerai":
			var spice := id == "silo"
			var fill := clampf(float(game.credits if spice else game.ore) / maxf(float(game.storage_cap("spice" if spice else "ore", team)), 1.0), 0.0, 1.0)
			var xs: Array = [-14.0, 14.0] if spice else [0.0]
			for x in xs:
				var base: Vector2 = c + Models.project(Vector3(x, 12.0, 0.0), 0.0)
				var hgt := 22.0 * fill
				var col := Color(1.0, 0.7, 0.25) if spice else Color(0.45, 0.8, 1.0)
				draw_rect(Rect2(base + Vector2(-2, -hgt * 0.55), Vector2(4, hgt * 0.55)), Color(col.r, col.g, col.b, 0.35 + 0.3 * k))
				draw_circle(base + Vector2(0, -hgt * 0.55), 2.2, Color(col.r, col.g, col.b, 0.9))
			var top := c + Models.project(Vector3(0, 36.0, 0.0), 0.0)
			var bl := 0.5 + 0.5 * sin(t * 2.2)
			draw_circle(top, 3.0 + bl, Color(1.0, 0.4, 0.2, 0.3 + 0.4 * bl * k))
		"comptoir_solis", "marche", "caravanserail", "serre", "fonderie_lourde":
			# pièces / étincelles qui montent du toit : le revenu se voit
			var ore := id in ["caravanserail", "serre", "fonderie_lourde"]
			var col2 := Color(0.6, 0.85, 1.0) if ore else Color(1.0, 0.85, 0.3)
			var n := 3 + level
			for i in n:
				var ph := fmod(t * 0.5 + i / float(n), 1.0)
				var p := c + Models.project(Vector3(-20.0 + i * (40.0 / maxf(n - 1, 1.0)), 24.0 + ph * 22.0, 4.0), 0.0)
				draw_circle(p, 2.0 + (1.0 - ph) * 1.4, Color(col2.r, col2.g, col2.b, (1.0 - ph) * 0.85 * k))
			if id == "fonderie_lourde":
				for i in 3:
					var ph2 := fmod(t * 0.4 + i * 0.33, 1.0)
					draw_circle(c + Models.project(Vector3(18.0 + i * 8.0, 40.0 + ph2 * 30.0, -12.0), 0.0) + Vector2(ph2 * 10.0, 0),
							4.0 + ph2 * 8.0, Color(0.34, 0.32, 0.36, (1.0 - ph2) * 0.3 * k))
		"bunker", "tour_acide", "batterie", "mortier_lourd", "batterie_mortiers", "lanceur_spores":
			var ph3 := 0.5 + 0.5 * sin(t * (3.0 if _target != null else 1.4))
			var top2 := c + Models.project(Vector3(0, 30.0, 0), 0.0)
			var col3 := Color(0.5, 1.0, 0.4) if id in ["tour_acide", "lanceur_spores"] else Color(1.0, 0.35, 0.25)
			draw_circle(top2 + Vector2(10, -4), 2.0 + ph3, Color(col3.r, col3.g, col3.b, (0.35 + 0.5 * ph3) * k))
			if id in ["tour_acide", "lanceur_spores"]: # bulles qui montent de la cuve
				for i in 3:
					var ph4 := fmod(t * 0.6 + i * 0.33, 1.0)
					draw_circle(c + Models.project(Vector3(-6.0 + i * 6.0, 18.0 + ph4 * 14.0, 2.0), 0.0), 1.6, Color(0.6, 1.0, 0.45, (1.0 - ph4) * 0.7 * k))
		"canon_solaire", "marteau_guerre", "pluie_acide", "nova_cristal":
			# arme orbitale : anneaux de charge, plus vifs quand elle est prête
			var ready := 1.0 if cooldown <= 0.0 else 0.35
			var col4 := Color(1.0, 0.8, 0.3)
			match id:
				"marteau_guerre": col4 = Color(1.0, 0.3, 0.2)
				"pluie_acide": col4 = Color(0.5, 1.0, 0.35)
				"nova_cristal": col4 = Color(0.8, 0.5, 1.0)
			var cc := c + Models.project(Vector3(0, 30.0, 0), 0.0)
			for i in 3:
				var a0 := t * (1.4 + i * 0.5) + i * 2.1
				draw_arc(cc, 14.0 + i * 7.0, a0, a0 + 1.7, 20, Color(col4.r, col4.g, col4.b, 0.55 * ready * k), 2.0, true)
			var pu := 0.5 + 0.5 * sin(t * 4.0)
			draw_circle(cc, 5.0 + 3.0 * pu * ready, Color(col4.r, col4.g, col4.b, (0.3 + 0.4 * pu) * ready * k))
		"usine", "chantier":
			if _anim_busy():
				# voyants chenillards sur le toit et vapeur : on produit
				for i in 5:
					var on := int(t * 6.0) % 5 == i
					var p2 := c + Models.project(Vector3(-32.0 + i * 16.0, 22.0, 10.0), 0.0)
					draw_circle(p2, 2.0, Color(acc.r, acc.g, acc.b, 0.9 if on else 0.25))
				for i in 2:
					var ph5 := fmod(t * 0.7 + i * 0.5, 1.0)
					draw_circle(c + Models.project(Vector3(32.0, 36.0 + ph5 * 22.0, -18.0), 0.0) + Vector2(ph5 * 8.0, 0), 3.0 + ph5 * 6.0, Color(0.85, 0.85, 0.9, (1.0 - ph5) * 0.3 * k))
	# Éclat de tir (toutes les défenses)
	if shot_t > 0.0 and weapon != "":
		var f := shot_t / 0.2
		var mp := c + shot_at
		draw_circle(mp, 6.0 * f + 2.0, Color(1.0, 0.9, 0.55, 0.85 * f))
		for i in 4:
			var a5 := aim + (i - 1.5) * 0.35
			draw_line(mp, mp + Vector2.from_angle(a5) * 11.0 * f, Color(1.0, 0.8, 0.4, 0.8 * f), 1.6)


func _anim_busy() -> bool:
	if game == null:
		return false
	for cat in ["building", "unit"]:
		var q: Array = game.production[cat]
		if not q.is_empty() and String(GameData.def(q[0]["id"]).get("from", "chantier" if cat == "building" else "usine")) == id and not q[0]["ready"]:
			return true
	return false


## Véhicule en cours de déchargement : flot de particules de la benne vers la trémie, lueur du bec de déversement.
func _draw_unload_fx(c: Vector2, t: float) -> void:
	var u = dock_user
	if u == null or not is_instance_valid(u) or u._dk != "work" or u._dk_kind != "unload":
		return
	var q: Dictionary = Models.ramp_of(id)
	if q.is_empty():
		return
	var from: Vector2 = c + (u.position - world_center()) + Vector2(0, -u.ramp_lift - 8.0)
	var hop: Vector2 = c + Models.project(Vector3(float(q["x"]), 16.0, -2.0), 0.0)
	var col := Color(1.0, 0.62, 0.2) if id == "raffinerie" else Color(0.55, 0.8, 1.0)
	var pulse := 0.5 + 0.5 * sin(t * 14.0)
	draw_circle(hop, 9.0 + 3.0 * pulse, Color(col.r, col.g, col.b, 0.16 + 0.16 * pulse))
	for i in 9:
		var k := fmod(t * 1.3 + i / 9.0, 1.0)
		var p := from.lerp(hop, k) + Vector2(0, -sin(k * PI) * 14.0) + Vector2(sin(i * 7.3 + t * 4.0) * 3.0, 0)
		draw_circle(p, 2.4 - k * 0.8, Color(col.r, col.g, col.b, 0.85 * (1.0 - k * 0.4)))


## Véhicule sur la plateforme de réparation : deux bras articulés du portique, étincelles de soudure et faisceau.
func _draw_repair_fx(c: Vector2, t: float) -> void:
	var u = dock_user
	if u == null or not is_instance_valid(u) or u._dk != "work" or u._dk_kind != "repair":
		# au repos : le chariot du portique balaie lentement la plateforme
		var sw := sin(t * 1.6)
		var p := c + Models.project(Vector3(sw * 28.0, 33.5, -6.0), 0.0)
		draw_rect(Rect2(p - Vector2(5, 3), Vector2(10, 6)), Color(0.5, 1.0, 0.7, 0.55))
		return
	var up: Vector2 = c + (u.position - world_center()) + Vector2(0, -u.ramp_lift)
	for side in [-1.0, 1.0]:
		var base := c + Models.project(Vector3(side * 30.0, 31.0, -6.0), 0.0)
		var wob := sin(t * 3.0 + side * 1.7)
		var tip := up + Vector2(side * (7.0 + 5.0 * wob), -4.0 + 3.0 * sin(t * 2.3 + side))
		var elbow := base.lerp(tip, 0.5) + Vector2(0, -14.0)
		draw_line(base, elbow, Color(0.75, 0.78, 0.85), 3.0, true)
		draw_line(elbow, tip, Color(0.6, 0.64, 0.72), 2.4, true)
		draw_circle(elbow, 2.6, Color(0.9, 0.92, 1.0))
		var fl := 0.5 + 0.5 * sin(t * 40.0 + side * 9.0)
		draw_circle(tip, 3.5 + 2.0 * fl, Color(0.7, 1.0, 0.85, 0.5 + 0.4 * fl))
		for i in 3:
			var a: float = t * 23.0 + i * 2.1 + side
			draw_line(tip, tip + Vector2(cos(a), sin(a) - 0.4) * (4.0 + 5.0 * fl), Color(1.0, 0.95, 0.6, 0.9), 1.2)
	var bp := 0.5 + 0.5 * sin(t * 5.0)
	draw_rect(Rect2(up + Vector2(-13, -20), Vector2(26, 26)), Color(0.4, 1.0, 0.6, 0.06 + 0.07 * bp))


func _on_screen() -> bool:
	if game == null or game.camera == null:
		return true
	var half: Vector2 = get_viewport_rect().size / game.camera.zoom * 0.5 + Vector2(160, 160)
	var d: Vector2 = (world_center() - game.camera.get_screen_center_position()).abs()
	return d.x < half.x and d.y < half.y


## Ouvre la porte de production : une unité va en sortir.
func open_door(dur := 1.7) -> void:
	door_t = dur
	door_dur = dur
	if _sprite_ok:
		set_process(true)
		queue_redraw()


## Monte d'un niveau : plus de PV, et un bonus propre au bâtiment (voir GameData.UPGRADES).
func upgrade() -> void:
	if level >= GameData.MAX_LEVEL:
		return
	level += 1
	var old := max_hp
	max_hp = base_hp * (1.0 + GameData.LEVEL_HP * (level - 1))
	hp += max_hp - old
	power = GameData.power_at(id, level)
	if weapon != "":
		dps = base_dps * (1.0 + 0.25 * (level - 1))
	_apply_vision()
	Fx.burst(game, world_center(), GameData.GOLD, 24, 1.3)
	queue_redraw()


## La Station radar voit plus loin à chaque niveau.
func _apply_vision() -> void:
	if id == "radar":
		vision = int(GameData.def(id).get("vision", GameData.BUILDING_VISION)) + 3 * (level - 1)


func world_center() -> Vector2:
	return position + Vector2(cell_size * tile) / 2.0


func radius_px() -> float:
	return maxf(cell_size.x, cell_size.y) * tile * 0.5


var last_attacker_team := -1
var demolished := false


func take_damage(raw: float, wpn: String, attacker = null) -> void:
	if not alive:
		return
	if is_instance_valid(attacker) and attacker.team != team:
		last_attacker_team = attacker.team
	var dmg := raw * GameData.mult(wpn, armor)
	# Amortissement des dégâts concentrés (voir GameData.SOAK_*) : estimation du taux sur ~1 s
	var now: float = game.game_time
	_soak_acc *= exp(-(now - _soak_t))
	_soak_t = now
	var thr := maxf(max_hp * GameData.SOAK_FRAC, 1.0)
	if _soak_acc > thr:
		dmg *= pow(_soak_acc / thr, GameData.SOAK_EXP - 1.0)
	_soak_acc += dmg
	hp -= dmg
	if is_instance_valid(attacker) and attacker.team == 0 and team != 0:
		game.stats.dmg_dealt += minf(dmg, hp + dmg)
	elif team == 0:
		game.stats.dmg_taken += minf(dmg, hp + dmg)
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
	# Sans énergie suffisante, les défenses sont hors tension
	var ok: bool = game.power_ok(team)
	if ok == offline:
		offline = not ok
		queue_redraw()
	if offline or up_left > 0.0:
		return # hors tension ou en travaux
	cooldown = maxf(0.0, cooldown - delta)
	_scan -= delta
	if not _valid(_target) or world_center().distance_to(_target.world_center()) - float(_target.radius_px()) > w_range + 40.0:
		_target = null
		if _scan <= 0.0:
			_scan = 0.4
			_target = game.find_enemy(team, world_center(), w_range + radius_px(), true, id)
	if _target == null:
		return
	var tp: Vector2 = _target.world_center()
	var want := (tp - world_center()).angle()
	aim = lerp_angle(aim, want, clampf(8.0 * delta, 0.0, 1.0))
	queue_redraw()
	if cooldown <= 0.0 and absf(angle_difference(aim, want)) < 0.2:
		var wd: Dictionary = GameData.WEAPONS[weapon]
		cooldown = wd["cd"]
		var from := world_center() + Vector2.from_angle(aim) * 22.0
		var hk := "%s_tete" % id
		if not Models.has_muzzle(hk):
			hk = "tourelle_tete"
		if game.bank != null and game.bank.has("%s|%s" % [hk, game.faction_id_of(team)]):
			# bout du canon de la tête de tourelle, à l'angle exact de l'image affichée
			var snapped: float = game.bank.snap_angle("%s|%s" % [hk, game.faction_id_of(team)], aim)
			from = world_center() + Models.muzzle_offset(hk, snapped, _muzzle_i)
			_muzzle_i = (_muzzle_i + 1) % Models.muzzle_count(hk)
		fx_t = 0.6 if id == "tour_sonique" else (0.25 if id == "tour_prisme" else 0.0)
		shot_t = 0.2
		shot_at = from - position
		game.fire(self, _target, weapon, dps * float(wd["cd"]), from)


func _draw_sprite(s: Vector2) -> bool:
	var bank: SpriteBank = game.bank if game != null else null
	if bank == null:
		return false
	var fid: String = game.faction_id_of(team)
	var key := "%s|%s" % [id, fid]
	var tiered := false
	if level > 1 and bank.has("%s|L%d" % [key, level]):
		key = "%s|L%d" % [key, level] # modèle propre à ce niveau d'évolution
		tiered = true
	var tex = bank.frame(key)
	if tex == null:
		return false
	var sz := bank.draw_size(key)
	var c := s / 2.0
	# Ombre portée (bas-gauche)
	draw_rect(Rect2(Vector2(-10, 8), s - Vector2(4, 4)), Color(0.1, 0.03, 0.12, 0.25))
	var tint := Color(1, 1, 1) if (level < 3 or tiered) else Color(1.1, 1.08, 1.14)
	draw_texture_rect(tex, Rect2(c - sz / 2.0, sz), false, tint)
	if level > 1 and not tiered:
		_draw_upgrade(s, fid)
	_draw_anim(s, fid, bank)
	if weapon != "":
		var hk := "%s_tete|%s" % [id, fid]
		if not bank.has(hk):
			hk = "tourelle_tete|%s" % fid
		if level > 1 and bank.has("%s|L%d" % [hk, level]):
			hk = "%s|L%d" % [hk, level]
		var ht = bank.frame(hk, aim)
		if ht != null:
			var hs := bank.draw_size(hk)
			draw_texture_rect(ht, Rect2(c - hs / 2.0, hs), false)
	return true


## Animations par-dessus le sprite cuit : plateau radar tournant, ondes de la tour sonique,
## lueurs d'énergie, fumées de fonderie, portes de production qui s'ouvrent.
func _draw_anim(s: Vector2, fid: String, bank) -> void:
	var c := s / 2.0
	var t := Time.get_ticks_msec() / 1000.0 + _phase
	var powered: bool = game.power_ok(team)
	var acc: Color = GameData.FACTIONS[fid]["color"] if GameData.FACTIONS.has(fid) else Color.WHITE
	match id:
		"radar":
			var ang := t * (1.15 if powered else 0.2)
			var hk := "radar_tete|%s" % fid
			var ht = bank.frame(hk, ang)
			if ht != null:
				var hs: Vector2 = bank.draw_size(hk)
				draw_texture_rect(ht, Rect2(c - hs / 2.0, hs), false)
			if powered:
				# écho : onde qui s'élargit depuis le plateau, et balayage lumineux
				var k := fmod(t / 3.2, 1.0)
				draw_arc(c, lerpf(18.0, 86.0, k), 0.0, TAU, 48, Color(0.4, 1.0, 0.6, (1.0 - k) * 0.30), 2.0, true)
				var tip := c + Models.project(Vector3(0, 40, 0), 0.0)
				draw_line(tip, tip + Vector2.from_angle(ang) * 30.0, Color(0.5, 1.0, 0.7, 0.18), 3.0, true)
			var blink := 0.5 + 0.5 * sin(t * 6.0)
			draw_circle(c + Models.project(Vector3(0, 31.5, 0), 0.0), 3.0 + blink, Color(1.0, 0.3, 0.25, 0.35 + 0.4 * blink))
		"tour_sonique":
			var em := c + Models.muzzle_offset("tour_sonique_tete", aim, 0)
			var pulse := 0.5 + 0.5 * sin(t * 3.0)
			var sc := Color(0.45, 0.85, 1.0)
			draw_circle(em, 5.0 + 2.5 * pulse, Color(sc.r, sc.g, sc.b, 0.20 + 0.20 * pulse))
			# ondes lentes au repos
			if not offline:
				var k := fmod(t / 2.4, 1.0)
				draw_arc(em, 6.0 + 22.0 * k, aim - 0.9, aim + 0.9, 18, Color(sc.r, sc.g, sc.b, (1.0 - k) * 0.35), 2.0, true)
			# tir : trois ondes de choc successives dans la direction visée
			if fx_t > 0.0:
				var p := 1.0 - fx_t / 0.6
				for i in 3:
					var rr := 12.0 + p * 70.0 + i * 15.0
					var a := clampf(1.0 - p, 0.0, 1.0) * (1.0 - i * 0.28)
					draw_arc(em, rr, aim - 0.55, aim + 0.55, 20, Color(0.6, 0.95, 1.0, a * 0.8), 3.0 - i * 0.6, true)
				draw_circle(em, 10.0 * (1.0 - p) + 3.0, Color(0.8, 1.0, 1.0, (1.0 - p) * 0.8))
		"tour_prisme":
			var em := c + Models.muzzle_offset("tour_prisme_tete", aim, 0)
			var pu := 0.5 + 0.5 * sin(t * 3.4)
			draw_circle(em, 4.0 + 2.0 * pu, Color(0.8, 0.5, 1.0, 0.25 + 0.25 * pu))
			if fx_t > 0.0:
				draw_circle(em, 9.0 * (fx_t / 0.25), Color(1.0, 0.8, 1.0, 0.7 * (fx_t / 0.25)))
		"serre":
			for i in 3:
				var ph := 0.5 + 0.5 * sin(t * 2.2 + i * 2.0)
				var p := c + Models.project(Vector3(-24.0 + i * 24.0, 19.0, -2.0), 0.0)
				draw_circle(p, 6.0 + 2.0 * ph, Color(0.75, 0.5, 1.0, 0.14 + 0.2 * ph))
				draw_circle(p, 2.2, Color(1.0, 0.9, 1.0, 0.5 + 0.3 * ph))
		"centrale":
			for x in [-15.0, 15.0]:
				var ph := 0.5 + 0.5 * sin(t * 2.4 + x)
				var p := c + Models.project(Vector3(x, 25.0, -2.0), 0.0)
				draw_circle(p, 7.0 + 3.0 * ph, Color(0.3, 0.85, 1.0, 0.16 + 0.22 * ph))
				draw_circle(p, 3.0, Color(0.8, 1.0, 1.0, 0.45 + 0.3 * ph))
		"reacteur":
			var ph := 0.5 + 0.5 * sin(t * 3.2)
			var p := c + Models.project(Vector3(0, 28.0, 0), 0.0)
			draw_circle(p, 16.0 + 4.0 * ph, Color(0.3, 0.8, 1.0, 0.12 + 0.12 * ph))
			draw_circle(p, 8.0, Color(0.7, 0.95, 1.0, 0.25 + 0.25 * ph))
			for i in 3:
				var a := t * 2.0 + i * TAU / 3.0
				draw_circle(p + Vector2(cos(a), sin(a) * 0.6) * 15.0, 2.0, Color(0.8, 1.0, 1.0, 0.8))
		"chantier":
			var ph := 0.5 + 0.5 * sin(t * 2.2)
			draw_circle(c + Models.project(Vector3(0, 56.0, 0), 0.0), 5.0 + 2.0 * ph, Color(0.3, 0.8, 1.0, 0.2 + 0.3 * ph))
		"fonderie", "raffinerie":
			if id == "fonderie":
				for x in [16.0, 30.0]:
					var top := c + Models.project(Vector3(x, 38.0, -14.0), 0.0)
					var fl := 0.5 + 0.5 * sin(t * 9.0 + x * 3.0)
					draw_circle(top, 5.0 + 2.0 * fl, Color(1.0, 0.5, 0.15, 0.25 + 0.25 * fl))
					for i in 4:
						var ph := fmod(t * 0.45 + i * 0.25 + x * 0.013, 1.0)
						draw_circle(top + Vector2(ph * 14.0, -ph * 46.0), 3.0 + ph * 8.0,
								Color(0.34, 0.32, 0.36, (1.0 - ph) * 0.30))
				var gl := 0.5 + 0.5 * sin(t * 5.0)
				draw_rect(Rect2(c + Models.project(Vector3(-29, 11, 19.5), 0.0) - Vector2(0, 2), Vector2(30, 4)), Color(1.0, 0.55, 0.2, 0.18 + 0.22 * gl))
			else:
				var ph := 0.5 + 0.5 * sin(t * 2.6)
				var p := c + Models.project(Vector3(22, 19.0, -8), 0.0)
				draw_rect(Rect2(p - Vector2(13, 11), Vector2(26, 22)), Color(1.0, 0.6, 0.2, 0.08 + 0.14 * ph))
			_draw_unload_fx(c, t)
		"marche":
			for x in [-24.0, 0.0, 24.0]:
				var ph := 0.5 + 0.5 * sin(t * 4.0 + x * 0.2)
				var p := c + Models.project(Vector3(x, 14.0, 17.5), 0.0)
				draw_rect(Rect2(p - Vector2(8, 2), Vector2(16, 4)), Color(1.0, 0.3, 0.9, 0.18 + 0.3 * ph))
		"reparation":
			_draw_repair_fx(c, t)
	_draw_anim_more(c, t, powered, acc)
	# Porte de production : s'ouvre quand une unité sort
	if door_t > 0.0 and Models.DOORS.has(id):
		var d: Dictionary = Models.DOORS[id]
		var op := sin(clampf(1.0 - door_t / door_dur, 0.0, 1.0) * PI)
		if d.has("pad"):
			var pp: Vector3 = d["pad"]
			var pc := c + Vector2(pp.x, pp.z)
			var fl := 0.5 + 0.5 * sin(t * 18.0)
			draw_arc(pc, 17.0, 0.0, TAU, 32, Color(1.0, 0.7, 0.25, 0.5 * op + 0.2 * fl * op), 3.0, true)
			draw_arc(pc, 11.0, 0.0, TAU, 28, Color(acc.r, acc.g, acc.b, 0.6 * op), 2.0, true)
			for i in 4:
				var a := TAU * i / 4.0 + t * 3.0
				draw_circle(pc + Vector2.from_angle(a) * 17.0, 2.2, Color(1.0, 0.9, 0.5, 0.9 * op))
		else:
			var w: float = d["w"]
			var dc := c + Models.project(Vector3(float(d["x"]), float(d["y"]), float(d["z"])), 0.0)
			var h := 6.4 * op + 0.5
			draw_rect(Rect2(dc + Vector2(-w / 2.0, -h / 2.0 - 1.0), Vector2(w, h + 2.0)), Color(0.05, 0.04, 0.06, 0.9 * op))
			draw_rect(Rect2(dc + Vector2(-w / 2.0 + 2.0, h / 2.0 - 2.0), Vector2(w - 4.0, 2.0)), Color(1.0, 0.75, 0.35, 0.8 * op))
			# lumière qui s'écoule devant la porte
			var base := dc + Vector2(0, h / 2.0 + 1.0)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-w / 2.0, 0), base + Vector2(w / 2.0, 0),
					base + Vector2(w / 2.0 + 8.0, 22.0), base + Vector2(-w / 2.0 - 8.0, 22.0)]), Color(1.0, 0.8, 0.45, 0.18 * op))


## Améliorations visibles : plus un bâtiment est modernisé, plus il s'orne de blindages,
## d'antennes et de bandes lumineuses aux couleurs de la faction.
func _draw_upgrade(s: Vector2, fid: String) -> void:
	var acc: Color = GameData.FACTIONS[fid]["color"] if GameData.FACTIONS.has(fid) else Color.WHITE
	var dark := acc.darkened(0.55)
	var arm := minf(minf(s.x, s.y) * 0.22, 16.0)
	var t := 4.0 if level == 2 else 5.0
	# Plaques de blindage aux quatre coins (niveau 2 et plus)
	for corner in 4:
		var px := 0.0 if corner % 2 == 0 else s.x
		var py := 0.0 if corner < 2 else s.y
		var sx := 1.0 if corner % 2 == 0 else -1.0
		var sy := 1.0 if corner < 2 else -1.0
		var o := Vector2(px, py)
		draw_rect(Rect2(o + Vector2(minf(0.0, sx * arm), minf(0.0, sy * t)), Vector2(arm, t)), dark)
		draw_rect(Rect2(o + Vector2(minf(0.0, sx * t), minf(0.0, sy * arm)), Vector2(t, arm)), dark)
		draw_rect(Rect2(o + Vector2(minf(0.0, sx * arm), minf(0.0, sy * t)), Vector2(arm, t)), acc, false, 1.0)
		draw_rect(Rect2(o + Vector2(minf(0.0, sx * t), minf(0.0, sy * arm)), Vector2(t, arm)), acc, false, 1.0)
	if weapon != "":
		# Défenses : anneau de blindage autour de l'embase
		var rr := minf(s.x, s.y) * 0.5
		draw_arc(s / 2.0, rr - 1.0, 0.0, TAU, 40, acc * 1.2, 2.0 + level, true)
		if level >= 3:
			draw_arc(s / 2.0, rr - 6.0, 0.0, TAU, 40, GameData.GOLD, 1.5, true)
		return
	# Antenne de toit
	var base := Vector2(s.x * 0.82, s.y * 0.2)
	draw_line(base, base + Vector2(0, -16.0 - 4.0 * level), dark, 3.0)
	draw_circle(base + Vector2(0, -16.0 - 4.0 * level), 3.0, acc * 1.6)
	# Module de toiture supplémentaire
	draw_rect(Rect2(s.x * 0.12, s.y * 0.1, s.x * 0.2, s.y * 0.12), dark)
	draw_rect(Rect2(s.x * 0.12, s.y * 0.1, s.x * 0.2, s.y * 0.12), acc, false, 1.0)
	if level >= 3:
		# Bande énergétique le long de la façade et dôme doré
		draw_rect(Rect2(s.x * 0.08, s.y - 10.0, s.x * 0.84, 3.0), acc * 1.9)
		draw_rect(Rect2(s.x * 0.08, s.y - 11.0, s.x * 0.84, 5.0), Color(acc.r, acc.g, acc.b, 0.25))
		draw_circle(Vector2(s.x * 0.5, s.y * 0.14), 6.0, GameData.GOLD.darkened(0.2))
		draw_arc(Vector2(s.x * 0.5, s.y * 0.14), 6.0, 0.0, TAU, 20, GameData.GOLD.lightened(0.3), 1.5, true)


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


## Mur : dessiné à plat dans sa case, pour que les segments s'alignent parfaitement.
func _draw_wall(s: Vector2) -> void:
	var fid: String = game.faction_id_of(team) if game != null else ""
	var steel: bool = id == "mur" and (fid == "kharn" or level >= 2)
	var crystal: bool = id == "mur" and fid == "conclave"
	var base := GameData.wall_color(id, fid)
	var acc: Color = GameData.FACTIONS[fid]["color"] if GameData.FACTIONS.has(fid) else Color.WHITE
	draw_rect(Rect2(Vector2.ZERO, s), base.darkened(0.35))                       # flanc
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, s.y - 7.0)), base)                 # dessus
	draw_rect(Rect2(Vector2(2, 2), Vector2(s.x - 4.0, s.y - 13.0)), base.lightened(0.14))
	draw_rect(Rect2(Vector2(0, s.y - 7.0), Vector2(s.x, 2.0)), acc * 1.3)         # liseré de faction
	draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.35), false, 1.0)
	if crystal:
		var t := Time.get_ticks_msec() / 1000.0 + _phase
		var sh := 0.5 + 0.5 * sin(t * 2.0 + float(cell.x + cell.y))
		draw_colored_polygon(PackedVector2Array([Vector2(4, s.y - 12.0), Vector2(s.x * 0.35, 4), Vector2(s.x * 0.55, s.y - 12.0)]), Color(0.8, 0.6, 1.0, 0.45 + 0.25 * sh))
		draw_colored_polygon(PackedVector2Array([Vector2(s.x * 0.5, s.y - 12.0), Vector2(s.x * 0.72, 2), Vector2(s.x - 4.0, s.y - 12.0)]), Color(0.65, 0.4, 0.95, 0.5))
	if steel:
		for p in [Vector2(6, 6), Vector2(s.x - 6.0, 6), Vector2(6, s.y - 14.0), Vector2(s.x - 6.0, s.y - 14.0)]:
			draw_circle(p, 1.8, base.darkened(0.4))


func _draw() -> void:
	var s := Vector2(cell_size * tile)
	if GameData.def(id).get("wall", false):
		_draw_wall(s)
		_draw_hp(s)
		return
	if _draw_sprite(s):
		_draw_hp(s)
		return
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
	_draw_hp(s)


func _draw_hp(s: Vector2) -> void:
	if selected:
		draw_rect(Rect2(Vector2(-2, -2), s + Vector2(4, 4)), GameData.GREEN, false, 2.5)


## Calque des barres (amélioration, PV, niveau, états) : toujours au-dessus du reste,
## y compris des unités et du brouillard.
class BarsLayer extends Node2D:
	var b

	func _init(p_b) -> void:
		b = p_b
		z_as_relative = false
		z_index = 46

	func _process(_d: float) -> void:
		if b.up_left > 0.0 or _sig() != _last:
			_last = _sig()
			queue_redraw()

	var _last := ""

	func _sig() -> String:
		return "%d|%d|%d|%d|%d|%d" % [int(b.hp), b.level, int(b.offline), int(b.repairing), int(b.hp < b.max_hp), int(b.up_left > 0.0)]

	func _draw() -> void:
		var s := Vector2(b.cell_size * b.tile)
		if GameData.def(b.id).get("wall", false):
			if b.hp < b.max_hp:
				draw_rect(Rect2(4, -9, s.x - 8.0, 5), Color(0, 0, 0, 0.65))
				draw_rect(Rect2(4, -9, (s.x - 8.0) * clampf(b.hp / b.max_hp, 0.0, 1.0), 5), GameData.GREEN)
			return
		for i in b.level - 1:
			draw_rect(Rect2(8 + i * 11, s.y - 14, 8, 8), GameData.GOLD)
			draw_rect(Rect2(8 + i * 11, s.y - 14, 8, 8), Color.BLACK, false, 1.0)
		if b.offline:
			UiStyle.text(self, Vector2(2, s.y * 0.5), "HORS TENSION", 11, GameData.RED, true, HORIZONTAL_ALIGNMENT_CENTER, s.x)
		if b.repairing:
			UiStyle.text(self, Vector2(2, s.y * 0.5 + 16.0), "RÉPARATION", 11, GameData.GREEN, true, HORIZONTAL_ALIGNMENT_CENTER, s.x)
		if b.up_left > 0.0:
			var uw := s.x - 8.0
			draw_rect(Rect2(3, -17, uw + 2.0, 6), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(4, -16, uw * (1.0 - b.up_left / maxf(b.up_total, 0.1)), 4), GameData.AMBER_HDR)
		if b.hp < b.max_hp:
			var w := s.x - 8.0
			draw_rect(Rect2(4, -9, w, 5), Color(0, 0, 0, 0.65))
			draw_rect(Rect2(4, -9, w * clampf(b.hp / b.max_hp, 0.0, 1.0), 5),
					GameData.GREEN if b.game.side_of(b.team) == 0 else GameData.RED)

# --- Sauvegarde -----------------------------------------------------------------

func export_state() -> Dictionary:
	return {"id": id, "cell": cell, "team": team, "hp": hp, "level": level, "up_left": up_left,
			"up_total": up_total, "up_cost": up_cost, "up_acc": up_acc, "repairing": repairing, "outpost": outpost}


func restore_state(s: Dictionary) -> void:
	level = int(s["level"])
	max_hp = base_hp * (1.0 + GameData.LEVEL_HP * (level - 1))
	power = GameData.power_at(id, level)
	if weapon != "":
		dps = base_dps * (1.0 + 0.25 * (level - 1))
	_apply_vision()
	hp = minf(float(s["hp"]), max_hp)
	up_left = float(s["up_left"])
	up_total = float(s["up_total"])
	up_cost = float(s.get("up_cost", 0.0))
	up_acc = float(s.get("up_acc", 0.0))
	repairing = bool(s["repairing"])
	outpost = int(s["outpost"])
	queue_redraw()
