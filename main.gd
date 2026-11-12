extends Node2D
## Scène principale : terrain (shader), ressources, caméra, sélection,
## production, placement de bâtiments et vers géants. Interface : ui.gd.

const TILE := 32
const MINIMAP_RES := 192
const SIDEBAR_EXTRA := 390.0 # la caméra peut défiler sous le panneau latéral
const CAM_SPEED := 800.0
const EDGE_SCROLL := true
const EDGE_MARGIN := 12
const FOG := true       # brouillard de guerre
const FX_GLOW := true # HDR 2D + bloom (Forward+). Mettre false en cas de souci d'affichage.

# Terrain
const ROCK_H := 0.12
const MOUNTAIN_H := 0.5
const SPICE_T := 0.35
const ORE_T := 0.35
const SPICE_PER_CELL := 600.0
const ORE_PER_CELL := 500.0

# Ver géant : rare et aléatoire
const WORM_GRACE := 150.0    # aucune apparition avant (secondes)
const WORM_RATE := 0.0012    # probabilité par seconde et par récolteur en activité sur le sable
const WORM_COOLDOWN := 240.0 # pause après chaque apparition

# Couleurs de la mini-carte
const MM_SAND := Color("d89580")
const MM_SPICE := Color("e2762a")
const MM_ROCK := Color("6e3329")
const MM_ORE := Color("8fb2e8")
const MM_MOUNTAIN := Color("2a100e")

enum T { SAND, ROCK, MOUNTAIN, SPICE, ORE }

var map_w := 96
var map_h := 96
var field_scale := 3        # échantillons de relief par case (texture envoyée au shader)
var world_size := Vector2(96, 96) * TILE
var start_cell := Vector2(48, 80)      # case de départ du joueur
var enemy_cell := Vector2(48, 16)      # case de départ de l'adversaire
var ally_cell := Vector2(-1, -1)       # case de départ du 3e camp (-1 : absent)
var third_hostile := false             # le 3e camp est un second adversaire (chacun pour soi)
var spice_fields: Array = []           # bassins de sable à épice (cases)
var ore_fields: Array = []             # filons sur plateaux rocheux
var corridor_w := 5.5
var corridors: Array = []              # couloirs garantis (sans montagne)
var plateaus: Array = []               # [centre, rayon] des plateaux rocheux
var team_factions := {}                # équipe -> faction
var ais := {}                          # équipe -> IA
var faction_id := "solis"
var fdata := {}
var terrain: Array = []
var resource := {} # Vector2i -> {kind, amount, max}
var dirty := {}    # cases dont la texture doit être rafraîchie
var grid := AStarGrid2D.new()
var camera := Camera2D.new()
var map_texture: ImageTexture # mini-carte du radar
var field_img: Image
var field_tex: ImageTexture
var ui: GameUI
var ai: SkirmishAI
var sfx: Sfx
var bank: SpriteBank # modèles 3D cuits en sprites (absent sans affichage)
var enemy_faction := ""
var over := false
var mission := {}          # mission de campagne en cours (vide en escarmouche)
var earned := 0            # Solaris récoltés par le joueur
var ore_earned := 0        # minerai récolté par le joueur
var kills := 0             # unités hostiles détruites
var destroyed := {}        # id de bâtiment hostile -> nombre détruit
var _obj_t := 0.0
var map_seed := 0          # graine de la carte (sauvegarde : la carte est régénérée à l'identique)
var _save := {}            # sauvegarde en cours de chargement (vide : partie neuve)
var pause_menu: PauseMenu = null
var obj_state: Array = []
var arrived := 0
var convoy_total := 0
var hold_t := 0.0
var hold_ok := false
var zone_done := false
var escort_done := false
var convoy_started := false
const ZONE_RADIUS := 5.0
var mission_points := {}   # points clés de la mission (cases)
var markers: MissionMarkers
var selected_building: Building = null
var inspected = null # unité ou bâtiment (ami ou ennemi) examiné par un clic
var fog_vis := PackedByteArray()  # 1 = visible maintenant
var fog_seen := PackedByteArray() # 1 = déjà exploré
var fog_img: Image
var fog_tex: ImageTexture
var fog_radar_img: Image
var fog_radar_tex: ImageTexture # même brouillard en RGBA pour le radar
var _fog_t := 0.0
var _alert_cd := -100.0

var units: Array[Unit] = []
var selected: Array[Unit] = []
var buildings: Array[Building] = []
var occupied := {} # Vector2i -> true (cases prises par un bâtiment)

var _full_warn := -99.0
var _rep_acc := 0.0
var tier := 0 # missions de campagne terminées : débloque les bâtiments
var _ore_acc := {}
var _inc_acc := {0: 0.0, 1: 0.0, 2: 0.0}
var credits := 1000 # Solaris (épice raffinée) : payent les unités
var ore := 1500     # Minerai : paye les bâtiments
var game_time := 0.0
var production := {"building": [], "unit": []} # files d'attente (le premier élément est en cours)
## Rayon (en cases) de la zone de construction autour d'un Chantier.
const BUILD_RADIUS := 15.0
var placing_id := ""
var command_mode := ""

var worm: Worm
var worm_cooldown := 0.0
var _field_timer := 0.0
var _shake_t := 0.0
var _shake_dur := 0.01
var _shake_amp := 0.0

var drag_start := Vector2.ZERO
var dragging := false

var noise_h := FastNoiseLite.new()
var noise_s := FastNoiseLite.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1c0f20"))
	Fx.setup_display(self, FX_GLOW)
	_save = {}
	if GameSession.load_slot >= 0:
		_save = SaveGame.read(GameSession.load_slot)
		GameSession.load_slot = -1
		if not _save.is_empty():
			GameSession.faction = String(_save["faction"])
			GameSession.mode = String(_save["mode"])
			GameSession.mission = int(_save["mission"])
	map_seed = int(_save["seed"]) if not _save.is_empty() else randi()
	faction_id = GameSession.faction
	fdata = GameData.FACTIONS[faction_id]
	if GameSession.mode == "campaign":
		mission = Campaign.mission(faction_id, GameSession.mission)
		credits = int(mission["credits"])
		ore = int(mission["ore"])
	elif _save.is_empty():
		credits = int(credits * GameSession.skirm_res)
		ore = int(ore * GameSession.skirm_res)
	tier = GameSession.mission if GameSession.mode == "campaign" else Campaign.cleared(faction_id)
	# Écran de chargement (la partie est en pause tant que tout n'est pas prêt)
	if DisplayServer.get_name() != "headless":
		loading = LoadingScreen.new(fdata["color"])
		add_child(loading)
		get_tree().paused = true
	await _load_step(0.0, "Préparation des camps…")
	_setup_factions()
	# Les modèles 3D sont cuits en parallèle de la génération de la carte
	if loading != null:
		bank = SpriteBank.new()
		bank.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(bank)
		var facs: Array = []
		for t in team_factions.values():
			if t not in facs:
				facs.append(t)
		bank.setup(self, facs)
	await _load_step(0.05, "Tracé de la carte…")
	_generate_layout()
	_setup_noise()
	await _load_step(0.15, "Modelage du relief…")
	_generate_terrain()
	_init_resources()
	_build_grid()
	await _load_step(0.3, "Dépôts d'épice et de minerai…")
	await _build_terrain()
	await _load_step(0.9, "Radar et brouillard de guerre…")
	_build_minimap()
	camera.position = start_cell * TILE
	camera.zoom = Vector2(1.3, 1.3)
	add_child(camera)
	_clamp_camera()
	if FOG:
		_setup_fog()
	await _load_step(0.95, "Installation des camps…")
	_setup_sides()
	sfx = Sfx.new()
	add_child(sfx)
	markers = MissionMarkers.new(self)
	add_child(markers)
	ui = GameUI.new()
	add_child(ui)
	ui.setup(self)
	if not mission.is_empty():
		_setup_mission()
	if not _save.is_empty():
		_apply_state()
	_update_fog() # les bases non découvertes restent cachées dès la 1re image
	_load_terrain = 1.0
	if loading != null:
		while not bank.ready_all:
			loading.set_progress(_overall(), "Préparation des modèles 3D…")
			await get_tree().process_frame
		await sfx.warm_up(func(f: float, n: String) -> void:
			loading.set_progress(0.97 + 0.03 * f, "Génération des sons…")
			await get_tree().process_frame)
		loading.queue_free()
		loading = null
		get_tree().paused = false
	sfx.start_music()
	if not mission.is_empty():
		ui.toast("Mission %d — %s" % [GameSession.mission + 1, mission["title"]], fdata["accent"])
	elif ai != null:
		ui.toast("%s — face à la %s" % [fdata["name"], ai.fdata["name"]], fdata["accent"])
	ui.toast("Sélectionnez l'engin de chantier, placez-le puis DÉPLOYER", GameData.GOLD)


var loading: LoadingScreen
var _load_terrain := 0.0


func _overall() -> float:
	var bf := 1.0
	if bank != null and bank.total > 0:
		bf = float(bank.done) / float(bank.total)
	return 0.45 * _load_terrain + 0.55 * bf


## Avance l'écran de chargement et laisse une image s'afficher.
func _load_step(frac: float, text: String) -> void:
	_load_terrain = frac
	if loading == null:
		return
	loading.set_progress(_overall(), text)
	await get_tree().process_frame


# --- Camps, carte procédurale ------------------------------------------------

## Factions de chaque équipe : 0 = joueur, 1 = adversaire, 2 = second adversaire.
func _setup_factions() -> void:
	var others: Array = GameData.FACTIONS.keys().filter(func(k: String) -> bool: return k != faction_id)
	others.shuffle()
	var enemy: String = others[0]
	if mission.is_empty() and GameSession.opponents < 2 and others.has(GameSession.skirm_foe):
		enemy = GameSession.skirm_foe
	if not mission.is_empty():
		enemy = Campaign.enemy_of(faction_id, GameSession.mission)
	team_factions = {0: faction_id, 1: enemy}
	enemy_faction = enemy
	third_hostile = false
	if not mission.is_empty() and mission.get("rival", false):
		third_hostile = true
		team_factions[2] = Campaign.third_of(faction_id, GameSession.mission)
	elif mission.is_empty() and GameSession.opponents >= 2:
		third_hostile = true
		for k in others:
			if k != enemy:
				team_factions[2] = k
	if not _save.is_empty():
		third_hostile = bool(_save.get("third_hostile", third_hostile))
		team_factions = {}
		for t in _save["team_factions"]:
			team_factions[int(t)] = String(_save["team_factions"][t])
		enemy_faction = String(team_factions[1])


## Place bases, champs et couloirs de façon aléatoire (carte carrée).
func _generate_layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var size := GameSession.skirm_size if _save.is_empty() else 96
	if not mission.is_empty():
		size = int(mission.get("size", 96))
	map_w = size
	map_h = size
	field_scale = 3 if size >= 96 else 4
	world_size = Vector2(map_w, map_h) * TILE
	var c := Vector2(map_w, map_h) / 2.0
	var radius := size * 0.34
	var a0 := rng.randf() * TAU
	start_cell = (c + Vector2.from_angle(a0) * radius).round()
	enemy_cell = (c - Vector2.from_angle(a0) * (radius + rng.randf_range(-2.0, 2.0))).round()
	plateaus = [[start_cell, 9.0], [enemy_cell, 9.0]]
	var keys: Array = [start_cell, enemy_cell]
	ally_cell = Vector2(-1, -1)
	if team_factions.has(2):
		var da := rng.randf_range(1.0, 1.4) * (1.0 if rng.randf() < 0.5 else -1.0)
		ally_cell = (c + Vector2.from_angle(a0 + da) * radius * 0.95).round()
		plateaus.append([ally_cell, 9.0])
		keys.append(ally_cell)
	corridor_w = 8.0 if mission.has("convoy") else 5.5
	# Avant-postes, destination de convoi, zone à tenir : points d'intérêt
	mission_points = {}
	var pts := int(mission.get("outposts", 0))
	for i in pts:
		var p := _free_point(rng, keys, size, 0.22, 0.42, 20.0)
		mission_points["outpost%d" % i] = p
		plateaus.append([p, 6.0])
		keys.append(p)
	if mission.has("convoy"):
		var dest := (c - Vector2.from_angle(a0) * (radius * 0.9) + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3))).round()
		mission_points["dest"] = dest
		plateaus.append([dest, 6.0])
		keys.append(dest)
	if mission.has("zone"):
		mission_points["zone"] = c.round()
		plateaus.append([c.round(), 6.0])
		keys.append(c.round())
	# Champs : un d'épice et un de minerai par base (assez loin), puis des champs neutres
	spice_fields = []
	ore_fields = []
	for base in [start_cell, enemy_cell, ally_cell]:
		if base.x < 0:
			continue
		var p1 := _field_near(rng, base, 15.0, 19.0, spice_fields + ore_fields, size)
		spice_fields.append(p1)
		var p2 := _field_near(rng, base, 11.0, 14.0, spice_fields + ore_fields, size)
		ore_fields.append(p2)
	var extra := 1 + size / 48
	for i in extra:
		spice_fields.append(_free_point(rng, spice_fields + ore_fields + keys, size, 0.0, 0.45, 12.0))
		ore_fields.append(_free_point(rng, spice_fields + ore_fields + keys, size, 0.0, 0.45, 12.0))
	# Couloirs : chaque point clé relié à la base la plus proche et aux champs
	corridors = []
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			corridors.append([keys[i], keys[j]])
	for f in spice_fields + ore_fields:
		var best: Vector2 = keys[0]
		for k in keys:
			if f.distance_to(k) < f.distance_to(best):
				best = k
		corridors.append([best, f])


## Point aléatoire éloigné des autres (distance en fraction de la demi-carte autour du centre).
func _free_point(rng: RandomNumberGenerator, avoid: Array, size: int, rmin: float, rmax: float, gap: float) -> Vector2:
	var c := Vector2(size, size) / 2.0
	var best := c
	for t in 60:
		var p := c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(rmin, rmax) * size
		p = p.clamp(Vector2(10, 10), Vector2(size - 10, size - 10)).round()
		var ok := true
		for q in avoid:
			if p.distance_to(q) < gap:
				ok = false
				break
		if ok:
			return p
		best = p
	return best


func _field_near(rng: RandomNumberGenerator, base: Vector2, dmin: float, dmax: float, avoid: Array, size: int) -> Vector2:
	var best := base + Vector2(dmin, 0.0)
	for t in 40:
		var p := base + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(dmin, dmax)
		p = p.clamp(Vector2(9, 9), Vector2(size - 9, size - 9)).round()
		var ok := true
		for q in avoid:
			if p.distance_to(q) < 10.0:
				ok = false
				break
		if ok and p.distance_to(Vector2(size, size) / 2.0) < size * 0.45:
			return p
		best = p
	return best


# --- Terrain ------------------------------------------------------------------

func _setup_noise() -> void:
	var base := map_seed
	noise_h.seed = base
	noise_h.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_h.frequency = 0.07
	noise_h.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_h.fractal_octaves = 3
	noise_s.seed = base + 101
	noise_s.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_s.frequency = 0.09
	noise_s.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_s.fractal_octaves = 2


## Hauteur du terrain en un point (coordonnées en cases, flottantes).
func _height(p: Vector2) -> float:
	var h := noise_h.get_noise_2d(p.x, p.y) * 0.8
	for pl in plateaus:
		var r: float = pl[1]
		h = lerpf(h, 0.28, smoothstep(r, r * 0.5, p.distance_to(pl[0])))   # plateaux (bases, points d'intérêt)
	for sf in spice_fields:
		h = lerpf(h, -0.4, smoothstep(8.0, 4.0, p.distance_to(sf)))     # bassins de sable
	for orf in ore_fields:
		h = lerpf(h, 0.28, smoothstep(7.0, 3.5, p.distance_to(orf)))     # plateaux à minerai
	for cor in corridors:
		h = lerpf(h, minf(h, 0.2), smoothstep(corridor_w, corridor_w * 0.55, _seg_dist(p, cor[0], cor[1])))
	var edge := minf(minf(p.x, map_w - p.x), minf(p.y, map_h - p.y))
	h = lerpf(h, 0.7, smoothstep(3.0, 0.5, edge))                       # chaîne de bord de carte
	return h


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _spice(p: Vector2) -> float:
	var best := 0.0
	for sf in spice_fields:
		best = maxf(best, smoothstep(7.0, 1.0, p.distance_to(sf)))
	return noise_s.get_noise_2d(p.x, p.y) * 0.8 + 0.7 * best


func _ore(p: Vector2) -> float:
	var best := 0.0
	for orf in ore_fields:
		best = maxf(best, smoothstep(5.5, 1.0, p.distance_to(orf)))
	for pl in plateaus:
		if p.distance_to(pl[0]) < float(pl[1]) * 0.85:
			return -1.0 # pas de minerai sur les plateaux de construction
	return noise_s.get_noise_2d(p.x + 100.0, p.y + 100.0) * 0.5 + 0.75 * best


func _cell_type(c: Vector2i) -> int:
	var p := Vector2(c) + Vector2(0.5, 0.5)
	var h := _height(p)
	if h > MOUNTAIN_H:
		return T.MOUNTAIN
	if h > ROCK_H:
		return T.ORE if _ore(p) > ORE_T else T.ROCK
	if _spice(p) > SPICE_T:
		return T.SPICE
	return T.SAND


func _generate_terrain() -> void:
	for x in map_w:
		terrain.append([])
		for y in map_h:
			terrain[x].append(_cell_type(Vector2i(x, y)))


func _init_resources() -> void:
	for x in map_w:
		for y in map_h:
			var t: int = terrain[x][y]
			if t == T.SPICE:
				resource[Vector2i(x, y)] = {"kind": "spice", "amount": SPICE_PER_CELL, "max": SPICE_PER_CELL}
			elif t == T.ORE:
				resource[Vector2i(x, y)] = {"kind": "ore", "amount": ORE_PER_CELL, "max": ORE_PER_CELL}


func _build_grid() -> void:
	grid.region = Rect2i(0, 0, map_w, map_h)
	grid.cell_size = Vector2(TILE, TILE)
	grid.offset = Vector2(TILE, TILE) / 2.0 # les chemins passent par le centre des cases
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in map_w:
		for y in map_h:
			if terrain[x][y] == T.MOUNTAIN:
				grid.set_point_solid(Vector2i(x, y))


## Envoie le relief au shader : texture R = hauteur, G = épice, B = minerai.
func _build_terrain() -> void:
	var fw := map_w * field_scale
	var fh := map_h * field_scale
	field_img = Image.create(fw, fh, false, Image.FORMAT_RGBAH)
	for y in fh:
		for x in fw:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / field_scale
			field_img.set_pixel(x, y, Color(_height(p), _spice(p), _ore(p), 1.0))
		if y % 24 == 0:
			await _load_step(0.3 + 0.6 * float(y) / fh, "Génération du terrain…")
	field_tex = ImageTexture.create_from_image(field_img)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("field", field_tex)
	mat.set_shader_parameter("world_size", world_size)
	mat.set_shader_parameter("tile", float(TILE))
	mat.set_shader_parameter("rock_h", ROCK_H)
	mat.set_shader_parameter("mountain_h", MOUNTAIN_H)
	mat.set_shader_parameter("spice_t", SPICE_T)
	mat.set_shader_parameter("ore_t", ORE_T)
	var rect := ColorRect.new()
	rect.size = world_size
	rect.color = Color.WHITE
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = -10
	add_child(rect)


func _build_minimap() -> void:
	var img := Image.create(MINIMAP_RES, MINIMAP_RES, false, Image.FORMAT_RGB8)
	var k := float(map_w) / MINIMAP_RES
	for y in MINIMAP_RES:
		for x in MINIMAP_RES:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) * k
			var h := _height(p)
			var col := MM_SAND
			if h > MOUNTAIN_H:
				col = MM_MOUNTAIN
			elif h > ROCK_H:
				col = MM_ORE if _ore(p) > ORE_T else MM_ROCK
			elif _spice(p) > SPICE_T:
				col = MM_SPICE
			img.set_pixel(x, y, col)
	map_texture = ImageTexture.create_from_image(img)


## Réécrit dans la texture les cases dont la quantité a changé (la tache rétrécit).
func _refresh_field() -> void:
	for c in dirty.keys():
		var info: Dictionary = dirty[c]
		var frac: float = info["frac"]
		for dx in field_scale:
			for dy in field_scale:
				var tx: int = c.x * field_scale + dx
				var ty: int = c.y * field_scale + dy
				var p := (Vector2(tx, ty) + Vector2(0.5, 0.5)) / field_scale
				var col := field_img.get_pixel(tx, ty)
				if info["kind"] == "spice":
					col.g = _spice(p) * pow(frac, 0.7) if frac > 0.0 else -1.0
				else:
					col.b = _ore(p) * pow(frac, 0.7) if frac > 0.0 else -1.0
				field_img.set_pixel(tx, ty, col)
	dirty.clear()
	field_tex.update(field_img)


# --- Ressources ---------------------------------------------------------------

## Retire de la ressource d'une case ; renvoie la quantité réellement obtenue.
func extract(cell: Vector2i, amount: float) -> float:
	var r = resource.get(cell)
	if r == null:
		return 0.0
	var got := minf(amount, float(r["amount"]))
	r["amount"] = float(r["amount"]) - got
	var frac := float(r["amount"]) / float(r["max"])
	dirty[cell] = {"kind": r["kind"], "frac": frac}
	if r["amount"] <= 0.5:
		resource.erase(cell)
		terrain[cell.x][cell.y] = T.SAND if r["kind"] == "spice" else T.ROCK
		dirty[cell] = {"kind": r["kind"], "frac": 0.0}
	return got


## Case de ressource la plus proche (de ce type), ou (-1, -1).
func find_resource(kind: String, from: Vector2i, max_dist := 999, me = null) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	# Cases déjà visées par un autre récolteur / mineur : une case = un engin
	var claimed := {}
	for u in units:
		if u != me and u.alive and u.is_worker() and (u.state == "seek" or u.state == "harvest") and u.work_cell.x >= 0:
			claimed[u.work_cell] = true
	for c in resource:
		var r: Dictionary = resource[c]
		if r["kind"] != kind or occupied.has(c) or claimed.has(c):
			continue
		var d := Vector2(c - from).length()
		if d < best_d and d <= max_dist:
			best_d = d
			best = c
	return best


## Raffinerie (épice) ou fonderie (minerai) la plus proche.
func find_dock(kind: String, from: Vector2i, team := 0) -> Building:
	var want := "raffinerie" if kind == "spice" else "fonderie"
	var best: Building = null
	var best_d := INF
	# 1) en état de marche, 2) hors tension mais pas en travaux, 3) n'importe laquelle (on attend)
	for pass_i in 3:
		for b in buildings:
			if b.id != want or b.team != team:
				continue
			if pass_i == 0 and (b.offline or b.up_left > 0.0):
				continue
			if pass_i == 1 and b.up_left > 0.0:
				continue
			var d := Vector2(from).distance_to(b.center_cell())
			if d < best_d:
				best_d = d
				best = b
		if best != null:
			break
	return best


## Toutes les usines de ce type (ou tous les chantiers) sont en cours d'amélioration : production à l'arrêt.
func producer_busy(cat: String, unit_id: String, team := 0) -> bool:
	var want := "chantier" if cat == "building" else String(GameData.def(unit_id).get("from", "usine"))
	var found := false
	for b in buildings:
		if b.team == team and b.alive and b.id == want:
			found = true
			if b.up_left <= 0.0:
				return false
	return found


## Case libre contre le bâtiment, la plus proche de `from`.
func dock_cell(b: Building, from: Vector2i) -> Vector2i:
	var best := b.cell
	var best_d := INF
	for x in range(b.cell.x - 1, b.cell.x + b.cell_size.x + 1):
		for y in range(b.cell.y - 1, b.cell.y + b.cell_size.y + 1):
			var c := Vector2i(x, y)
			if _is_walkable(c):
				var d := Vector2(c - from).length()
				if d < best_d:
					best_d = d
					best = c
	return best


## Dépôt d'une cargaison : épice → Solaris, minerai → minerai (bonus de faction).
## Capacité de stockage de Solaris ("spice") ou de minerai ("ore") d'un camp.
func storage_cap(kind: String, team := 0) -> int:
	var idx := 0 if kind == "spice" else 1
	var cap: int = GameData.STORAGE_BASE
	for b in buildings:
		if b.team == team and b.alive and GameData.STORAGE.has(b.id):
			cap += int(GameData.STORAGE[b.id][idx])
	return cap


func deposit(kind: String, amount: float, world_pos: Vector2, team := 0) -> void:
	var fd := fdata_of(team)
	var gain := roundi(amount * float(fd["spice_mult" if kind == "spice" else "ore_mult"]) * income_bonus(kind, team))
	if team == 0:
		var room := storage_cap(kind) - (credits if kind == "spice" else ore)
		if gain > room:
			gain = maxi(room, 0)
			if game_time - _full_warn > 6.0:
				_full_warn = game_time
				ui.toast("Stockage de %s plein : construisez un %s" % ["Solaris" if kind == "spice" else "minerai", "Silo d'épice" if kind == "spice" else "Silo de minerai"], GameData.RED)
	if team == 0:
		if kind == "spice":
			credits += gain
			earned += gain
		else:
			ore += gain
			ore_earned += gain
		sfx.play("coin", world_pos, -8.0)
		popup(world_pos, ("+%d $" if kind == "spice" else "+%d min.") % gain,
				GameData.GOLD if kind == "spice" else GameData.ORE_BLUE)
	else:
		ais[team].add_income(kind, gain)


## Texte flottant dans le monde.
func popup(world_pos: Vector2, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = world_pos - Vector2(30, 34)
	l.z_index = 20
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 40.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


# --- Vers géants --------------------------------------------------------------

func _update_worm(delta: float) -> void:
	if worm != null:
		return
	worm_cooldown -= delta
	if worm_cooldown > 0.0 or game_time < float(mission.get("worm_grace", WORM_GRACE)):
		return
	var workers := _harvesters_on_sand()
	if workers.is_empty():
		return
	# Très rare : probabilité proportionnelle au nombre de récolteurs en activité
	if randf() < WORM_RATE * float(mission.get("worm_rate", 1.0)) * workers.size() * delta:
		_spawn_worm(workers.pick_random())


func _harvesters_on_sand() -> Array:
	var out := []
	for u in units:
		if u.is_worker() and u.state == "harvest" and not u.carried and worm_ok(u.position):
			out.append(u)
	return out


func _spawn_worm(target) -> void:
	# Le ver apparaît loin sur le sable (accessible par le sable uniquement) : plusieurs secondes de préavis
	var start := worm_spawn_point(target.position, 20, 36)
	if start.x < 0.0:
		start = worm_spawn_point(target.position, 10, 20)
	if start.x < 0.0:
		worm_cooldown = 30.0 # la proie est isolée sur une zone de sable trop petite : le ver ne peut pas venir
		return
	sfx.play_ui("worm", -2.0)
	worm = Worm.new()
	worm.setup(self, start, target)
	add_child(worm)
	_worm_zone = WormZone.new()
	_worm_zone.game = self
	add_child(_worm_zone)
	worm.finished.connect(_on_worm_finished)
	alert_worm()


## Le ver ne circule que sur le sable et dans les champs d'épice ou de minerai, jamais sur la roche.
func worm_ok_cell(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= map_w or c.y >= map_h:
		return false
	var t: int = terrain[c.x][c.y]
	return t == T.SAND or t == T.SPICE or t == T.ORE


func worm_ok(world: Vector2) -> bool:
	return worm_ok_cell(_world_to_cell(world))


const _N8 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]


## Chemin du ver entre deux points, uniquement sur du terrain praticable pour lui (vide si inaccessible).
func worm_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _world_to_cell(from)
	var b := _world_to_cell(to)
	var out := PackedVector2Array()
	if not worm_ok_cell(a) or not worm_ok_cell(b):
		return out
	var prev := {a: a}
	var queue: Array[Vector2i] = [a]
	var qi := 0
	var found := false
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		if c == b:
			found = true
			break
		for d in _N8:
			var n: Vector2i = c + d
			if prev.has(n) or not worm_ok_cell(n):
				continue
			if d.x != 0 and d.y != 0 and not (worm_ok_cell(c + Vector2i(d.x, 0)) and worm_ok_cell(c + Vector2i(0, d.y))):
				continue # pas de coupe en diagonale à travers un coin de roche
			prev[n] = c
			queue.append(n)
	if not found:
		return out
	var cur := b
	while cur != a:
		out.append(_cell_to_world(cur))
		cur = prev[cur]
	out.reverse()
	return out


## Point de sable à une distance de marche de `min_c` à `max_c` cases de `pos` (INF/-1 si aucun).
func worm_spawn_point(pos: Vector2, min_c: int, max_c: int) -> Vector2:
	var a := _world_to_cell(pos)
	if not worm_ok_cell(a):
		return Vector2(-1, -1)
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var qi := 0
	var cands: Array[Vector2i] = []
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		var dc: int = dist[c]
		if dc >= min_c:
			cands.append(c)
		if dc >= max_c:
			continue
		for d in _N8:
			var n: Vector2i = c + d
			if dist.has(n) or not worm_ok_cell(n):
				continue
			dist[n] = dc + 1
			queue.append(n)
	if cands.is_empty():
		return Vector2(-1, -1)
	return _cell_to_world(cands.pick_random())


## Zone de danger du ver : centre approximatif (calé sur une grille de 6 cases, pas la position exacte)
## et rayon assez grand pour toujours contenir le ver.
const WORM_ZONE_SNAP := 6.0
const WORM_ZONE_RADIUS := 9.0
var _worm_zone: Node2D = null


func worm_zone() -> Dictionary:
	if worm == null:
		return {}
	var snap := WORM_ZONE_SNAP * TILE
	var c := (worm.position / snap).round() * snap
	return {"center": c, "radius": WORM_ZONE_RADIUS * TILE}


class WormZone extends Node2D:
	var game
	var _t := 0.0

	func _init() -> void:
		z_index = 45 # au-dessus du brouillard : toujours visible

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var z: Dictionary = game.worm_zone()
		if z.is_empty():
			return
		var c: Vector2 = z["center"]
		var r: float = z["radius"]
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_circle(c, r, Color(1.0, 0.15, 0.1, 0.07 + 0.06 * pulse))
		draw_circle(c, r * 0.6, Color(1.0, 0.15, 0.1, 0.05 + 0.04 * pulse))
		# anneau en tirets qui tourne
		var n := 28
		for i in n:
			var a0 := TAU * i / n + _t * 0.35
			draw_arc(c, r, a0, a0 + TAU / n * 0.55, 6, Color(1.0, 0.3, 0.2, 0.55 + 0.35 * pulse), 4.0, true)
		draw_arc(c, r * (0.55 + 0.45 * fposmod(_t * 0.6, 1.0)), 0.0, TAU, 48,
				Color(1.0, 0.3, 0.2, 0.35 * (1.0 - fposmod(_t * 0.6, 1.0))), 3.0, true)


func _on_worm_finished() -> void:
	if _worm_zone != null:
		_worm_zone.queue_free()
		_worm_zone = null
	worm = null
	worm_cooldown = WORM_COOLDOWN / maxf(float(mission.get("worm_rate", 1.0)), 1.0)


## Alerte : les ouvriers proches, sur le sable, se réfugient sur la roche.
func alert_worm() -> void:
	ui.toast("ALERTE : vibrations détectées, un ver approche !", GameData.RED)
	for u in units:
		if u.is_worker() and worm_ok(u.position) and u.position.distance_to(worm.position) < 900.0:
			u.flee()


func nearest_sand_unit(pos: Vector2, max_d: float) -> Unit:
	var best: Unit = null
	var best_d := max_d
	for u in units:
		if u.alive and not u.eaten and worm_ok(u.position):
			var d := u.position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = u
	return best


func find_safe_cell(from: Vector2i) -> Vector2i:
	for r in range(1, 40):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := from + Vector2i(dx, dy)
				if c.x < 0 or c.y < 0 or c.x >= map_w or c.y >= map_h:
					continue
				var t: int = terrain[c.x][c.y]
				if (t == T.ROCK or t == T.ORE) and _is_walkable(c):
					var d := Vector2(dx, dy).length()
					if d < best_d:
						best_d = d
						best = c
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)


func shake(amp: float, dur: float) -> void:
	_shake_amp = amp
	_shake_dur = dur
	_shake_t = dur


func on_unit_lost(u: Unit) -> void:
	if hostile(u.team, 0) and u.id != "mcv":
		kills += 1
	units.erase(u)
	selected.erase(u)


# --- Brouillard de guerre -----------------------------------------------------

func _setup_fog() -> void:
	fog_vis.resize(map_w * map_h)
	fog_seen.resize(map_w * map_h)
	var data := PackedByteArray()
	data.resize(map_w * map_h)
	data.fill(255)
	fog_img = Image.create_from_data(map_w, map_h, false, Image.FORMAT_R8, data)
	fog_tex = ImageTexture.create_from_image(fog_img)
	var rdata := PackedByteArray()
	rdata.resize(map_w * map_h * 4)
	fog_radar_img = Image.create_from_data(map_w, map_h, false, Image.FORMAT_RGBA8, rdata)
	fog_radar_tex = ImageTexture.create_from_image(fog_radar_img)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/fog.gdshader")
	mat.set_shader_parameter("fog", fog_tex)
	var rect := ColorRect.new()
	rect.size = world_size
	rect.color = Color.WHITE
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 40
	add_child(rect)


func _reveal(world_pos: Vector2, radius: int) -> void:
	var c := _world_to_cell(world_pos)
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var x := c.x + dx
			var y := c.y + dy
			if x < 0 or y < 0 or x >= map_w or y >= map_h:
				continue
			var i := y * map_w + x
			fog_vis[i] = 1
			fog_seen[i] = 1


func is_visible_cell(c: Vector2i) -> bool:
	return fog_vis[c.y * map_w + c.x] == 1


func _update_fog() -> void:
	fog_vis.fill(0)
	for u in units:
		if u.team == 0 and u.alive: # brouillard propre au joueur : alliés exclus
			_reveal(u.position, u.vision)
	for b in buildings:
		if b.team == 0 and b.alive:
			_reveal(b.world_center(), GameData.BUILDING_VISION if (b.offline and b.id == "radar") else b.vision)
	var data := PackedByteArray()
	data.resize(map_w * map_h)
	for i in data.size():
		data[i] = 0 if fog_vis[i] == 1 else (140 if fog_seen[i] == 1 else 255)
	fog_img.set_data(map_w, map_h, false, Image.FORMAT_R8, data)
	fog_tex.update(fog_img)
	var rdata := PackedByteArray()
	rdata.resize(map_w * map_h * 4)
	for i in data.size():
		rdata[i * 4] = 8
		rdata[i * 4 + 1] = 3
		rdata[i * 4 + 2] = 20
		rdata[i * 4 + 3] = int(data[i] * 0.92)
	fog_radar_img.set_data(map_w, map_h, false, Image.FORMAT_RGBA8, rdata)
	fog_radar_tex.update(fog_radar_img)
	# Les ennemis n'apparaissent que dans les zones visibles ; leurs bâtiments restent une fois repérés
	for u in units:
		if u.team == 0:
			u.seen = true
		else:
			u.seen = is_visible_cell(_world_to_cell(u.position))
		u.visible = u.seen and not u.carried
	for b in buildings:
		if b.team == 0:
			b.seen = true
			b.visible = true
			continue
		var vis := false
		var known := false
		for c in b.cells():
			var i: int = c.y * map_w + c.x
			vis = vis or fog_vis[i] == 1
			known = known or fog_seen[i] == 1
		b.seen = vis
		b.visible = known
	if worm != null:
		worm.visible = is_visible_cell(_world_to_cell(worm.position))


# --- Équipes & combat ---------------------------------------------------------

func fdata_of(team: int) -> Dictionary:
	return GameData.FACTIONS[team_factions.get(team, faction_id)]


func faction_id_of(team: int) -> String:
	return team_factions.get(team, faction_id)


## Camp : 0 = joueur, 1 = adversaire, 2 = 3e faction hostile (chacun pour soi).
func side_of(team: int) -> int:
	if team == 2 and third_hostile:
		return 2
	return 1 if team == 1 else 0


func hostile(a: int, b: int) -> bool:
	return side_of(a) != side_of(b)


## Reste-t-il au moins un camp hostile au joueur ?
func _foes_alive() -> bool:
	for t in team_factions.keys():
		if hostile(t, 0) and _team_alive(t):
			return true
	return false


## Base hostile vivante la plus proche d'une équipe (cible des IA).
func nearest_foe_home(team: int) -> Vector2:
	var best := Vector2(-1, -1)
	var bd := INF
	var me := Vector2(home_of(team))
	for t in team_factions.keys():
		if t == team or not hostile(t, team) or not _team_alive(t):
			continue
		var h := Vector2(home_of(t))
		if me.distance_to(h) < bd:
			bd = me.distance_to(h)
			best = h
	return best


func home_of(team: int) -> Vector2i:
	match team:
		0:
			return Vector2i(start_cell)
		1:
			return Vector2i(enemy_cell)
	return Vector2i(ally_cell)


func faction_color(team: int) -> Color:
	return fdata_of(team)["color"]


## Ennemi le plus intéressant autour d'un point : unités armées d'abord.
func find_enemy(team: int, pos: Vector2, max_d: float, units_only := false, shooter_id := ""):
	var best = null
	var best_s := INF
	for u in units:
		if not hostile(u.team, team) or not u.alive or u.carried or (team == 0 and not u.seen):
			continue
		if u.air and shooter_id != "" and not GameData.can_hit_air(shooter_id):
			continue
		var d := u.position.distance_to(pos) - u.radius
		if d > max_d:
			continue
		var s := d - (50.0 if u.weapon != "" else 0.0)
		if s < best_s:
			best_s = s
			best = u
	if not units_only:
		for b in buildings:
			if not hostile(b.team, team) or not b.alive or (team == 0 and not b.seen):
				continue
			var d := b.world_center().distance_to(pos) - b.radius_px()
			if d > max_d:
				continue
			var s := d + (0.0 if b.weapon != "" else 40.0)
			if s < best_s:
				best_s = s
				best = b
	return best


## Ennemi (du point de vue du joueur) sous le curseur.
func enemy_at(world_pos: Vector2):
	for u in units:
		if hostile(u.team, 0) and u.alive and u.seen and not u.carried \
				and u.visual_center().distance_to(world_pos) < u.pick_radius():
			return u
	for b in buildings:
		if hostile(b.team, 0) and b.alive and b.visible and Rect2(b.position, Vector2(b.cell_size * TILE)).has_point(world_pos):
			return b
	return null


func fire(shooter, target, weapon: String, damage: float, from: Vector2, control := false) -> void:
	var p := Projectile.new()
	damage *= GameData.aim_mult(shooter.id, target is Unit and target.air, target is Building)
	p.setup(self, weapon, shooter.team, from, target, damage, shooter, control)
	add_child(p)
	Fx.impact(self, from, GameData.WEAPONS[weapon]["color"], 2, 0.16)
	sfx.play(String(GameData.WEAPONS[weapon].get("snd", weapon)), from, -4.0)


## Chemin jusqu'à une cible (case voisine d'un bâtiment, ou case de l'unité).
func path_to_target(from_world: Vector2, target) -> PackedVector2Array:
	var from := _world_to_cell(from_world)
	var cell: Vector2i
	if target is Building:
		cell = dock_cell(target, from)
	else:
		cell = _world_to_cell(target.position)
	if not _is_walkable(cell):
		return PackedVector2Array()
	return grid.get_point_path(from, cell)


func notify_attack(b: Building) -> void:
	if b.team == 0 and game_time - _alert_cd > 12.0 and ui != null:
		_alert_cd = game_time
		sfx.play_ui("alert")
		ui.toast("Votre base est attaquée !", GameData.RED)


func on_building_destroyed(b: Building) -> void:
	if hostile(b.team, 0):
		destroyed[b.id] = int(destroyed.get(b.id, 0)) + 1
	buildings.erase(b)
	for c in b.cells():
		occupied.erase(c)
		grid.set_point_solid(c, false)
	_check_end()


func _check_end() -> void:
	if over:
		return
	var lost := not _team_alive(0)
	var reason := ""
	if lost:
		reason = "Votre base est tombée."
	if not mission.is_empty() and not lost:
		var types := []
		for o in mission["objectives"]:
			types.append(o["type"])
		if "escort" in types and not escort_done and _convoy_alive() + arrived < int(mission["convoy"]["need"]):
			lost = true
			reason = "Le convoi a été détruit."
	var won := false
	if not lost:
		if mission.is_empty():
			won = not _foes_alive()
		else:
			_update_objectives(0.0)
			# Mission : TOUS les objectifs doivent être remplis (détruire l'adversaire ne suffit pas).
			# Seule exception : « victimes » / « structure ciblée » ne peuvent plus progresser
			# quand il ne reste plus aucun ennemi, ils sont alors considérés comme remplis.
			var foes_left := _foes_alive()
			won = true
			for i in mission["objectives"].size():
				var ty: String = mission["objectives"][i]["type"]
				if obj_state[i]["done"]:
					continue
				if not foes_left and (ty == "kills" or ty == "destroy_type"):
					continue
				won = false
	if not lost and not won and not mission.is_empty() and mission.has("time_limit") \
			and game_time >= float(mission["time_limit"]):
		lost = true
		reason = "Le temps est écoulé."
	if lost or won:
		over = true
		for a in ais.values():
			a.active = false
		sfx.play_ui("victory" if won else "defeat")
		if won and not mission.is_empty():
			Campaign.mark_cleared(faction_id, GameSession.mission)
		ui.show_end(won, "L'adversaire est vaincu." if (won and mission.is_empty()) else reason)


# --- Boucle -------------------------------------------------------------------

func _process(delta: float) -> void:
	game_time += delta
	if not over:
		_obj_t -= delta
		if _obj_t <= 0.0:
			_obj_t = 0.5
			if not mission.is_empty():
				_update_objectives(0.5)
			_building_effects(0.5)
			_check_end()
	_separate_units()
	_update_production(delta)
	_tick_upgrades(delta)
	_tick_repairs(delta)
	_update_worm(delta)
	if FOG:
		_fog_t -= delta
		if _fog_t <= 0.0:
			_fog_t = 0.2
			_update_fog()
	_move_camera(delta)

	_field_timer += delta
	if _field_timer > 0.3 and not dirty.is_empty():
		_field_timer = 0.0
		_refresh_field()
	if _shake_t > 0.0:
		_shake_t -= delta
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) \
				* _shake_amp * clampf(_shake_t / _shake_dur, 0.0, 1.0)
	else:
		camera.offset = Vector2.ZERO

	if panning and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		panning = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = false # relâché au-dessus de l'interface
		_finish_selection(get_global_mouse_position())
	var mcv_sel := false
	for u in selected:
		if u.role == "mcv":
			mcv_sel = true
	if dragging or placing_id != "" or mcv_sel:
		queue_redraw()
	Input.set_default_cursor_shape(
			Input.CURSOR_CROSS if (placing_id != "" or command_mode != "") else Input.CURSOR_ARROW)


func _move_camera(delta: float) -> void:
	# Flèches + ZQSD (touches physiques : fonctionne en AZERTY)
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right") + _key(KEY_D) - _key(KEY_A),
		Input.get_axis("ui_up", "ui_down") + _key(KEY_S) - _key(KEY_W))
	if EDGE_SCROLL and get_window().has_focus() and not ui.is_mouse_over_ui():
		var m := get_viewport().get_mouse_position()
		var vp := get_viewport_rect().size
		if m.x < EDGE_MARGIN: dir.x -= 1
		if m.x > vp.x - EDGE_MARGIN: dir.x += 1
		if m.y < EDGE_MARGIN: dir.y -= 1
		if m.y > vp.y - EDGE_MARGIN: dir.y += 1
	camera.position += dir.limit_length(1.0) * CAM_SPEED / camera.zoom.x * delta
	_clamp_camera()


## Garde la caméra dans le monde, quelle que soit la taille de la fenêtre.
func _clamp_camera() -> void:
	var vp := get_viewport_rect().size
	var min_z := maxf(vp.x / (world_size.x + SIDEBAR_EXTRA), vp.y / world_size.y)
	if camera.zoom.x < min_z:
		camera.zoom = Vector2(min_z, min_z)
	var half := vp / camera.zoom / 2.0
	camera.position.x = clampf(camera.position.x, half.x, world_size.x + SIDEBAR_EXTRA - half.x)
	camera.position.y = clampf(camera.position.y, half.y, world_size.y - half.y)


func center_camera(world_pos: Vector2) -> void:
	camera.position = world_pos
	_clamp_camera()


func _key(k: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(k) else 0.0


func _zoom(factor: float) -> void:
	var z := clampf(camera.zoom.x * factor, 0.4, 2.5)
	camera.zoom = Vector2(z, z)
	_clamp_camera()


# --- Entrées ------------------------------------------------------------------

var panning := false
const SKIRMISH_DIFF := [
	{"slowdown": 2.0, "grace": 600.0, "pause": 120.0, "max_army": 14, "wave": 4, "skill": 0.25},
	{"grace": 430.0, "pause": 90.0, "skill": 0.6},
	{"slowdown": 1.1, "grace": 300.0, "pause": 60.0, "max_army": 30, "wave": 8, "skill": 0.95},
]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if placing_id == "" and command_mode == "" and selected_building == null and inspected == null:
					open_pause_menu()
				placing_id = ""
				command_mode = ""
				_clear_focus()
			KEY_F1:
				Guide.open(self, faction_id)
			KEY_F2:
				Changelog.open(self)
			KEY_O:
				ui.toggle_objectives()
			KEY_P:
				open_pause_menu()
			KEY_F6:
				save_game(0)
			KEY_F7:
				load_game(0)
			KEY_F11:
				var w := get_window()
				w.mode = Window.MODE_MAXIMIZED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_D:
				on_command("deploy")
			KEY_U:
				on_command("unload")
			KEY_M:
				var off := sfx.toggle_mute()
				ui.toast("Son coupé" if off else "Son activé", GameData.AMBER)
			KEY_F10:
				get_tree().change_scene_to_file("res://menu.tscn")
			KEY_F9: # test : fait surgir un ver tout de suite
				if worm == null and not units.is_empty():
					var sand := _harvesters_on_sand()
					_spawn_worm(sand.pick_random() if not sand.is_empty() else units.pick_random())
	elif event is InputEventMouseMotion and panning:
		camera.position -= event.relative / camera.zoom.x
		_clamp_camera()
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_left_pressed()
				elif dragging:
					dragging = false
					_finish_selection(get_global_mouse_position())
					queue_redraw()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					if placing_id != "" or command_mode != "":
						placing_id = ""
						command_mode = ""
					else:
						order_context(get_global_mouse_position())
			MOUSE_BUTTON_MIDDLE:
				panning = event.pressed # molette maintenue : on fait glisser la carte
				Input.set_default_cursor_shape(Input.CURSOR_DRAG if panning else Input.CURSOR_ARROW)
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed: _zoom(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed: _zoom(1.0 / 1.1)


func _left_pressed() -> void:
	if placing_id != "":
		var cell := _ghost_cell()
		if _can_place(placing_id, cell):
			_place_building(placing_id, cell)
			production["building"].pop_front()
			placing_id = ""
		else:
			ui.toast("Emplacement invalide : roche libre, dans la zone du Chantier (une seconde base demande un engin de chantier)", GameData.RED)
	elif command_mode == "move":
		order_move(get_global_mouse_position())
		command_mode = ""
	elif command_mode == "attack":
		order_amove(get_global_mouse_position())
		command_mode = ""
	else:
		dragging = true
		drag_start = get_global_mouse_position()


# --- Sélection & ordres -------------------------------------------------------

func _clear_focus() -> void:
	if selected_building != null and is_instance_valid(selected_building):
		selected_building.selected = false
	selected_building = null
	inspected = null


## Entité (ami ou ennemi, visible) sous le curseur : unité d'abord, puis bâtiment.
func entity_at(world_pos: Vector2):
	for u in units:
		if u.alive and u.seen and not u.carried and u.visual_center().distance_to(world_pos) < u.pick_radius():
			return u
	for b in buildings:
		if b.alive and b.visible and Rect2(b.position, Vector2(b.cell_size * TILE)).has_point(world_pos):
			return b
	return null


func _finish_selection(end: Vector2) -> void:
	if not Input.is_key_pressed(KEY_SHIFT):
		for u in selected:
			u.selected = false
		selected.clear()
		_clear_focus()
	var rect := Rect2(drag_start, end - drag_start).abs()
	var is_click := rect.size.length() < 6.0
	for u in units:
		if u.team != 0 or u.carried or u.convoy or u.role == "convoy":
			continue # le convoi de mission avance seul : on ne le commande pas
		var up: Vector2 = u.visual_center()
		var hit := up.distance_to(end) < u.pick_radius() if is_click \
				else rect.has_point(up)
		if hit and u not in selected:
			u.selected = true
			selected.append(u)
	# Clic sans unité amie : on examine le bâtiment ou l'ennemi visé
	if is_click and selected.is_empty():
		var e = entity_at(end)
		if e != null:
			inspected = e
			if e is Building and e.team == 0:
				selected_building = e
				e.selected = true


## Clic droit : attaque si un ennemi est sous le curseur, sinon déplacement.
func order_context(world_pos: Vector2) -> void:
	if not selected.is_empty():
		sfx.play_ui("ack", -8.0)
	var e = enemy_at(world_pos)
	if e == null:
		var friend = _friendly_ground_at(world_pos)
		if friend != null:
			var loaded := false
			for u in selected:
				if u.role == "transport":
					u.order_load(friend)
					loaded = true
			if loaded:
				return
		order_move(world_pos)
		return
	for u in selected:
		u.order_attack(e)
	Fx.impact(self, e.world_center(), GameData.RED, 3, 0.25)


## Unité terrestre alliée sous le curseur (pour l'embarquement).
func _friendly_ground_at(world_pos: Vector2):
	for u in units:
		if u.team == 0 and u.alive and not u.air and not u.carried and u not in selected \
				and u.visual_center().distance_to(world_pos) < u.pick_radius():
			return u
	return null


func order_amove(world_pos: Vector2) -> void:
	var target := _world_to_cell(world_pos)
	for i in selected.size():
		var cell := target + _formation_offset(i, selected.size())
		if not _is_walkable(cell) and not selected[i].air:
			cell = target
		if _is_walkable(cell) or selected[i].air:
			selected[i].order_amove(cell)


func order_move(world_pos: Vector2) -> void:
	var target := _world_to_cell(world_pos)
	for i in selected.size():
		var cell := target + _formation_offset(i, selected.size())
		if selected[i].air:
			selected[i].order_path(PackedVector2Array([selected[i].position, _cell_to_world(cell)]))
			continue
		if not _is_walkable(cell):
			cell = target
		if not _is_walkable(cell):
			continue
		selected[i].order_path(path_to(selected[i].position, cell))


@warning_ignore("integer_division")
func _formation_offset(i: int, n: int) -> Vector2i:
	var w := ceili(sqrt(n))
	return Vector2i(i % w - w / 2, i / w - w / 2)


func on_command(cmd: String) -> void:
	match cmd:
		"deploy":
			var any := false
			for u in selected.duplicate():
				if u.role == "mcv":
					any = true
					deploy_mcv(u)
			if not any:
				ui.toast("Sélectionnez l'engin de chantier", GameData.AMBER)
		"unload":
			# Transport chargé : dépose ses passagers ; récolteur / mineur : retourne vider sa cargaison
			var any2 := false
			var empty_workers := 0
			for u in selected:
				if u.role == "transport" and not u.cargo_units.is_empty():
					u.unload_all()
					any2 = true
				elif u.is_worker():
					if u.force_return():
						any2 = true
					else:
						empty_workers += 1
			if not any2:
				ui.toast("Déjà vide" if empty_workers > 0 else "Sélectionnez un transport chargé ou un ouvrier", GameData.AMBER)
		"stop":
			for u in selected:
				u.stop()
		"move":
			placing_id = ""
			command_mode = "move"
		"attack":
			var armed := false
			for u in selected:
				if u.weapon != "":
					armed = true
			if not armed:
				ui.toast("Aucune unité armée sélectionnée", GameData.AMBER)
				return
			placing_id = ""
			command_mode = "attack"


# --- Production & construction ------------------------------------------------

func is_unlocked(id: String) -> bool:
	if not GameData.BUILDINGS.has(id):
		return true
	var d: Dictionary = GameData.BUILDINGS[id]
	var f: String = d.get("faction", "")
	if f != "" and f != faction_id:
		return false
	if mission.is_empty():
		return best_level("chantier") >= chantier_needed(id)  # escarmouche : tout se débloque en montant le Chantier
	return int(d.get("unlock", 0)) <= tier


## Escarmouche : niveau de Chantier nécessaire pour un bâtiment (selon son palier de déblocage).
func chantier_needed(id: String) -> int:
	var u := int(GameData.def(id).get("unlock", 0))
	return 1 if u <= 1 else (2 if u <= 3 else 3)


func is_available(id: String) -> bool:
	if not is_unlocked(id):
		return false
	if unit_level_block(id) != "":
		return false
	for r in GameData.def(id)["requires"]:
		if not has_building(r):
			return false
	return true


## Niveau d'Usine manquant pour produire cette unité ("" si suffisant).
## Nombre maximal de récolteurs / mineurs selon le niveau du Chantier (0 : pas de limite).
func worker_cap(id: String, team := 0) -> int:
	var lvl := best_level("chantier", team)
	if id == "recolteur":
		return 1 + lvl + (1 if lvl >= 3 else 0)   # 2, 3, 5
	if id == "mineur":
		return lvl   # 1, 2, 3
	return 0


func worker_block(id: String, team := 0) -> String:
	var cap := worker_cap(id, team)
	if cap <= 0:
		return ""
	var n := 0
	for u in units:
		if u.team == team and u.id == id and u.alive:
			n += 1
	if team == 0:
		for it in production["unit"]:
			if it["id"] == id:
				n += 1
	if n >= cap:
		return "Limite %d (Chantier)" % cap
	return ""


## Contraintes des bâtiments évolués : niveau de bâtiments requis et nombre maximal.
func building_block(id: String, team := 0) -> String:
	var d: Dictionary = GameData.def(id)
	var rl: Dictionary = d.get("req_level", {})
	for rid in rl:
		if best_level(rid, team) < int(rl[rid]):
			return "%s niv. %d" % [GameData.def(rid)["name"], int(rl[rid])]
	var mx := int(d.get("max", 0))
	if mx > 0:
		var n := count_buildings(id, team)
		if team == 0:
			n += queued_count(id)
		if n >= mx:
			return "Maximum %d" % mx
	return ""


## Escarmouche : nombre maximal d'unités de combat selon les niveaux de Chantier et d'Usine
## (0 : pas de limite — campagne). Empêche de submerger l'adversaire sans investir dans sa base.
func army_cap(team := 0) -> int:
	if not mission.is_empty():
		return 0
	return 8 + 5 * best_level("chantier", team) + 3 * (best_level("usine", team) - 1)


func army_count(team := 0) -> int:
	var n := 0
	for u in units:
		if u.team == team and u.alive and u.role == "combat" and not u.convoy:
			n += 1
	if team == 0:
		for it in production["unit"]:
			if GameData.def(it["id"]).get("role", "combat") == "combat":
				n += 1
	return n


func unit_level_block(id: String, team := 0) -> String:
	if GameData.BUILDINGS.has(id):
		return building_block(id, team)
	var cap := army_cap(team)
	if cap > 0 and GameData.UNITS.has(id) and GameData.def(id).get("role", "combat") == "combat" and army_count(team) >= cap:
		return "Armée max. %d" % cap
	if worker_block(id, team) != "":
		return worker_block(id, team)
	var need: int = int(GameData.def(id).get("level", 1))
	if GameData.UNITS.has(id) and best_level("usine", team) < need:
		return "Usine niveau %d" % need
	return ""


func has_building(id: String, team := 0) -> bool:
	for b in buildings:
		if b.id == id and b.team == team:
			return true
	return false


func power_produced(team := 0) -> int:
	var total := 0
	for b in buildings:
		if b.team == team and b.power > 0:
			total += b.power
	return total


func power_used(team := 0) -> int:
	var total := 0
	for b in buildings:
		if b.team == team and b.power < 0:
			total -= b.power
	return total


## Énergie disponible : production - consommation - bâtiments consommateurs déjà en file.
func power_free(team := 0) -> int:
	var free := power_produced(team) - power_used(team)
	if team == 0:
		for it in production["building"]:
			var p: int = int(GameData.def(it["id"]).get("power", 0))
			if p < 0:
				free += p
	return free


## Raison pour laquelle un bâtiment ne peut pas être lancé faute d'énergie ("" si possible).
func power_block(id: String, team := 0) -> String:
	var need: int = -int(GameData.def(id).get("power", 0)) if GameData.BUILDINGS.has(id) else 0
	if need <= 0:
		return ""
	var free := power_free(team)
	if free >= need:
		return ""
	return "Énergie insuffisante (%d de plus requis) : construisez ou améliorez une centrale" % (need - free)


## Vrai si la production d'énergie couvre la consommation.
func power_ok(team := 0) -> bool:
	return power_produced(team) >= power_used(team)


## Élément en cours de production s'il s'agit de `id`, sinon {}.
func production_for(id: String) -> Dictionary:
	var q: Array = production["unit" if GameData.UNITS.has(id) else "building"]
	if not q.is_empty() and q[0]["id"] == id:
		return q[0]
	return {}


func queued_count(id: String) -> int:
	var n := 0
	for p in production["unit" if GameData.UNITS.has(id) else "building"]:
		if p["id"] == id:
			n += 1
	return n


## Niveau le plus haut d'un type de bâtiment pour une équipe (1 s'il n'y en a pas).
func best_level(id: String, team := 0) -> int:
	var lvl := 1
	for b in buildings:
		if b.team == team and b.id == id:
			lvl = maxi(lvl, b.level)
	return lvl


func count_buildings(id: String, team := 0) -> int:
	var n := 0
	for b in buildings:
		if b.team == team and b.id == id:
			n += 1
	return n


## Taille maximale d'une file d'attente : petite au départ, grandit avec le Chantier (bâtiments)
## ou l'Usine et ses niveaux (unités).
func queue_max(cat: String) -> int:
	if cat == "building":
		return 2 + 2 * (best_level("chantier") - 1)
	return mini(8, 2 + 2 * (best_level("usine") - 1) + maxi(0, count_buildings("usine") - 1))


## Production d'unités plus rapide avec le niveau de l'Usine.
func unit_speed_bonus(team := 0) -> float:
	return 1.0 + 0.25 * (best_level("usine", team) - 1)


func income_bonus(kind: String, team := 0) -> float:
	var bonus := 1.0 + 0.12 * (best_level("raffinerie" if kind == "spice" else "fonderie", team) - 1)
	if kind == "spice":
		bonus += 0.10 * minf(float(count_buildings("silo", team)), 3.0)
	else:
		bonus += 0.10 * minf(float(count_buildings("silo_minerai", team)), 3.0)
	return bonus


## Effets des bâtiments spéciaux, toutes les 0,5 s : revenus passifs et soins.
func _building_effects(dt: float) -> void:
	_update_power_state()
	for b in buildings:
		if not b.alive or b.offline or b.up_left > 0.0:
			continue
		var d := GameData.def(b.id)
		if d.has("income"):
			_inc_acc[b.team] = float(_inc_acc.get(b.team, 0.0)) + float(d["income"]) * dt
		if d.has("ore_income"):
			_ore_acc[b.team] = float(_ore_acc.get(b.team, 0.0)) + float(d["ore_income"]) * dt
		if (b.id == "mur_cristal" or b.id == "mur_obsidienne") and b.hp < b.max_hp:
			b.hp = minf(b.max_hp, b.hp + 12.0 * dt) # le cristal se régénère
		if d.has("aura_regen"):
			# Aura de réparation : les bâtiments alliés proches regagnent des PV
			var ar: float = float(d.get("aura_range", 6)) * TILE
			for o in buildings:
				if o.alive and o != b and o.team == b.team and o.hp < o.max_hp \
						and o.world_center().distance_to(b.world_center()) < ar + o.radius_px():
					o.hp = minf(o.max_hp, o.hp + float(d["aura_regen"]) * dt)
					o.queue_redraw()
		if d.has("heal"):
			var r: float = float(d["heal_range"]) * TILE
			for u in units:
				if u.alive and side_of(u.team) == side_of(b.team) and u.hp < u.max_hp \
						and u.position.distance_to(b.world_center()) < r + b.radius_px():
					u.hp = minf(u.max_hp, u.hp + float(d["heal"]) * dt)
					u.queue_redraw()
	for t in _ore_acc.keys():
		var ow := int(_ore_acc[t])
		if ow > 0:
			_ore_acc[t] = float(_ore_acc[t]) - ow
			if t == 0:
				ore = mini(ore + ow, maxi(storage_cap("ore"), ore))
			elif ais.has(t):
				ais[t].add_income("ore", ow)
	for t in _inc_acc.keys():
		var whole := int(_inc_acc[t])
		if whole > 0:
			_inc_acc[t] = float(_inc_acc[t]) - whole
			if t == 0:
				credits = mini(credits + whole, maxi(storage_cap("spice"), credits))
			elif ais.has(t):
				ais[t].add_income("spice", whole)


## Bâtiments qui s'arrêtent quand l'énergie ne couvre plus la consommation de leur camp.
const NEEDS_POWER := ["raffinerie", "fonderie", "radar", "reparation", "marche", "tourelle", "batterie",
		"tour_sonique", "bunker", "tour_acide", "aerodrome", "tour_prisme", "serre"]
var _power_was_ok := {}


func _update_power_state() -> void:
	for t in team_factions.keys():
		var ok := power_ok(t)
		for b in buildings:
			if b.team == t and b.alive:
				var bd := GameData.def(b.id)
				var off: bool = not ok and (NEEDS_POWER.has(b.id) or bd.has("weapon") or bd.get("needs_power", false))
				if off != b.offline:
					b.offline = off
					b.queue_redraw()
		if t == 0 and ok != bool(_power_was_ok.get(0, true)) and ui != null:
			if ok:
				ui.toast("Énergie rétablie : les installations redémarrent", GameData.GREEN)
			else:
				ui.toast("PANNE D'ÉNERGIE : récolte, radar, soins et défenses à l'arrêt — construisez une centrale", GameData.RED)
				sfx.play_ui("alert")
		_power_was_ok[t] = ok


func upgrade_cost(b: Building) -> int:
	return int(round(GameData.base_cost(b.id) * GameData.UPGRADE_COST * b.level))


## Durée de l'amélioration au niveau suivant (s).
func upgrade_time(b: Building) -> float:
	return float(GameData.def(b.id).get("time", 14.0)) * 2.0 * b.level


## Raison pour laquelle on ne peut pas améliorer le bâtiment ("" si c'est possible).
func upgrade_block(b: Building, money: int) -> String:
	if GameData.def(b.id).get("no_upgrade", false):
		return "Non améliorable"
	if b.up_left > 0.0:
		return "Amélioration en cours"
	if b.level >= GameData.MAX_LEVEL:
		return "Niveau maximum atteint"
	if b.id != "chantier" and b.level + 1 >= 3 and best_level("chantier", b.team) < 2:
		return "Améliorez d'abord le Chantier (niveau 2)"
	if money < upgrade_cost(b) * (START_FRAC if b.team == 0 else 1.0):
		return "Minerai insuffisant"
	var extra := -(GameData.power_at(b.id, b.level + 1) - GameData.power_at(b.id, b.level))
	if extra > 0 and power_free(b.team) < extra:
		return "Énergie insuffisante (+%d requis) : améliorez une centrale" % (extra - power_free(b.team))
	return ""


## Lance le chronomètre d'amélioration (le coût est déjà payé).
func begin_upgrade(b: Building) -> void:
	b.up_cost = 0.0
	b.up_total = upgrade_time(b)
	b.up_left = b.up_total
	b.queue_redraw()


func upgrade_building(b: Building) -> bool:
	if b.team != 0:
		return false
	var why := upgrade_block(b, ore)
	if why != "":
		ui.toast(why, GameData.RED)
		sfx.play_ui("error")
		return false
	begin_upgrade(b)
	b.up_cost = float(upgrade_cost(b)) # prélevé progressivement pendant les travaux
	b.up_acc = 0.0
	sfx.play_ui("click")
	ui.toast("%s : amélioration en cours (%d s)" % [GameData.def(b.id)["name"], int(b.up_total)], GameData.AMBER)
	return true


func unit_upgrade_block(u: Unit) -> String:
	if u.team != 0 or not GameData.UNIT_TECH.has(u.id):
		return "Non modernisable"
	if u.tech > 0:
		return "Déjà modernisée"
	if u.tech_left > 0.0:
		return "Modernisation en cours"
	if best_level("usine", u.team) < 2:
		return "Usine niveau 2 requise"
	if credits < GameData.tech_cost(u.id) * START_FRAC:
		return "Solaris insuffisants"
	return ""


func upgrade_unit(u: Unit) -> bool:
	var why := unit_upgrade_block(u)
	if why != "":
		ui.toast(why, GameData.RED)
		sfx.play_ui("error")
		return false
	u.tech_cost = float(GameData.tech_cost(u.id))
	u.tech_acc = 0.0
	u.tech_total = GameData.tech_time(u.id)
	u.tech_left = u.tech_total
	u.queue_redraw()
	sfx.play_ui("click")
	ui.toast("%s : modernisation en cours (%d s)" % [GameData.def(u.id)["name"], int(u.tech_total)], GameData.AMBER)
	return true


## Démolit un de ses bâtiments : remboursement de 40 % du prix de base (minerai).
func demolish_building(b: Building) -> void:
	if b.team != 0 or not b.alive:
		return
	var refund := int(round(float(GameData.base_cost(b.id)) * 0.4))
	ore += refund
	var refund_sol := int(round(GameData.sol_cost(b.id) * 0.4))
	credits += refund_sol
	b.alive = false
	b.repairing = false
	Fx.explosion(self, b.world_center(), 1.4)
	sfx.play_ui("error", -8.0)
	ui.toast("%s démoli (+%d minerai, +%d Solaris)" % [GameData.def(b.id)["name"], refund, refund_sol], GameData.AMBER)
	if selected_building == b:
		selected_building = null
	if inspected == b:
		inspected = null
	on_building_destroyed(b)
	b.queue_free()


# --- Réparations ----------------------------------------------------------------

## Coût (minerai) d'une réparation complète d'un bâtiment : la moitié de son prix.
func repair_cost_full(b: Building) -> int:
	return int(round(float(GameData.base_cost(b.id)) * 0.5 * (b.max_hp - b.hp) / b.max_hp))


func repair_block(b: Building) -> String:
	if b.team != 0:
		return "Non réparable"
	if b.hp >= b.max_hp - 0.5:
		return "Intégrité complète"
	if b.repairing:
		return ""
	if ore < 10:
		return "Minerai insuffisant"
	return ""


func toggle_repair(b: Building) -> void:
	var why := repair_block(b)
	if why != "":
		ui.toast(why, GameData.RED)
		sfx.play_ui("error")
		return
	b.repairing = not b.repairing
	sfx.play_ui("click")
	ui.toast("Réparation en cours : %s" % GameData.def(b.id)["name"] if b.repairing else "Réparation interrompue", GameData.AMBER)
	b.queue_redraw()


## Coût (Solaris) d'une réparation complète d'une unité : 40 % de son prix.
func unit_repair_cost(u: Unit) -> int:
	return int(round(float(GameData.def(u.id).get("cost", 300)) * 0.4 * (u.max_hp - u.hp) / u.max_hp))


## Bâtiment de réparation le plus proche : Centre de réparation, sinon Usine.
func find_repair_site(team: int, pos: Vector2) -> Building:
	var best: Building = null
	var best_d := INF
	for b in buildings:
		if b.team != team or not b.alive or b.offline or b.up_left > 0.0 or (b.id != "usine" and b.id != "reparation"):
			continue
		var d := b.world_center().distance_to(pos) - (60.0 if b.id == "reparation" else 0.0)
		if d < best_d:
			best_d = d
			best = b
	return best


func unit_repair_block(u: Unit) -> String:
	if u.team != 0:
		return "Non réparable"
	if u.hp >= u.max_hp - 0.5:
		return "Intégrité complète"
	if u.state == "repair":
		return "Réparation en cours"
	if find_repair_site(0, u.position) == null:
		return "Il faut une Usine ou un Centre de réparation"
	if credits < 10:
		return "Solaris insuffisants"
	return ""


func repair_unit(u: Unit) -> bool:
	var why := unit_repair_block(u)
	if why != "":
		ui.toast(why, GameData.RED)
		sfx.play_ui("error")
		return false
	u.order_repair(find_repair_site(0, u.position))
	sfx.play_ui("click")
	ui.toast("%s : retour à l'atelier" % GameData.def(u.id)["name"], GameData.AMBER)
	return true


## Soin d'une unité à l'atelier ; renvoie false quand c'est terminé ou impossible.
func repair_unit_tick(u: Unit, dt: float) -> bool:
	var amount := minf(u.max_hp / 12.0 * dt, u.max_hp - u.hp)
	var cost := amount * float(GameData.def(u.id).get("cost", 300)) * 0.4 / u.max_hp
	u.repair_acc += cost
	var whole := int(u.repair_acc)
	if whole > 0:
		if credits < whole:
			ui.toast("Réparation interrompue : Solaris insuffisants", GameData.RED)
			return false
		credits -= whole
		u.repair_acc -= whole
	u.hp += amount
	u.queue_redraw()
	return u.hp < u.max_hp - 0.5


func _tick_repairs(dt: float) -> void:
	for b in buildings:
		if not b.alive or not b.repairing:
			continue
		var amount := minf(b.max_hp / 20.0 * dt, b.max_hp - b.hp)
		_rep_acc += amount * float(GameData.base_cost(b.id)) * 0.5 / b.max_hp
		var whole := int(_rep_acc)
		if whole > 0:
			if ore < whole:
				b.repairing = false
				ui.toast("Réparation interrompue : minerai insuffisant", GameData.RED)
				continue
			ore -= whole
			_rep_acc -= whole
		b.hp += amount
		b.queue_redraw()
		if b.hp >= b.max_hp - 0.5:
			b.hp = b.max_hp
			b.repairing = false
			sfx.play_ui("ready", -4.0)
			ui.toast("%s réparé" % GameData.def(b.id)["name"], GameData.GREEN)


## Collisions entre unités terrestres : elles ne se superposent pas et ne se traversent pas.
## Une unité immobile cède la place à celle qui avance ; deux unités qui avancent se contournent.
func _separate_units() -> void:
	var grid_u := {}
	var ground: Array = []
	for u in units:
		if not u.alive or u.air or u.carried:
			continue
		ground.append(u)
		var k := Vector2i(int(u.position.x / 32.0), int(u.position.y / 32.0))
		if not grid_u.has(k):
			grid_u[k] = []
		grid_u[k].append(u)
	for u in ground:
		var k := Vector2i(int(u.position.x / 32.0), int(u.position.y / 32.0))
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var bucket: Array = grid_u.get(k + Vector2i(dx, dy), [])
				for v in bucket:
					if v == u or v.get_instance_id() < u.get_instance_id():
						continue # chaque paire une seule fois
					_push_apart(u, v)


## Véhicule terrestre qui gênerait `u` s'il avançait en `step_pos` (null si la voie est libre).
func unit_blocking(u: Unit, step_pos: Vector2):
	var dir := (step_pos - u.position).normalized()
	# on regarde aussi un peu devant soi pour anticiper plutôt que de coller l'autre véhicule
	var probes := [step_pos, step_pos + dir * u.radius * 1.1]
	for v in units:
		if v == u or not v.alive or v.air or v.carried:
			continue
		var min_d := (u.radius + v.radius) * 0.92
		var dnow := v.position.distance_to(u.position)
		for p in probes:
			var d := v.position.distance_to(p)
			if d < min_d and d < dnow - 0.01:
				return v
	return null


## Chemin vers `goal` qui contourne `blocker` et les autres véhicules proches ; vide s'il n'existe pas.
func detour_path(u: Unit, blocker: Unit, goal: Vector2) -> PackedVector2Array:
	var bc := _world_to_cell(blocker.position)
	var gc := _world_to_cell(goal)
	var uc := _world_to_cell(u.position)
	if bc == gc or bc == uc or grid.is_point_solid(bc):
		return PackedVector2Array()
	# 1re tentative : tous les véhicules proches sont des obstacles
	var marked: Array = []
	for v in units:
		if v == u or not v.alive or v.air or v.carried:
			continue
		if v.position.distance_to(u.position) > 4.0 * TILE and v != blocker:
			continue
		var vc := _world_to_cell(v.position)
		if vc == gc or vc == uc or grid.is_point_solid(vc) or marked.has(vc):
			continue
		grid.set_point_solid(vc, true)
		marked.append(vc)
	var p := grid.get_point_path(uc, gc)
	for c in marked:
		grid.set_point_solid(c, false)
	if p.size() > 0:
		return p
	# 2e tentative : seulement le véhicule qui bloque
	grid.set_point_solid(bc, true)
	p = grid.get_point_path(uc, gc)
	grid.set_point_solid(bc, false)
	return p


func _push_apart(a: Unit, b: Unit) -> void:
	var d := b.position - a.position
	var min_d := (a.radius + b.radius) * 0.92
	var dist := d.length()
	if dist >= min_d:
		return
	var n := d / dist if dist > 0.01 else Vector2.from_angle(randf() * TAU)
	var overlap := min_d - dist
	var a_moving := not a.path.is_empty()
	var b_moving := not b.path.is_empty()
	var wa := 0.5
	if a_moving and not b_moving:
		wa = 0.03 # le véhicule à l'arrêt ne bouge presque pas : c'est l'autre qui contourne
	elif b_moving and not a_moving:
		wa = 0.97
	var side := n.orthogonal() * overlap * 0.25 * (1.0 if a.get_instance_id() % 2 == 0 else -1.0)
	_nudge(a, -n * overlap * (1.0 - wa) - side * (1.0 - wa))
	_nudge(b, n * overlap * wa + side * wa)


func _nudge(u: Unit, off: Vector2) -> void:
	var np := u.position + off
	var c := _world_to_cell(np)
	if _is_walkable(c):
		u.position = np


## Fait avancer les améliorations de bâtiments et les modernisations d'unités.
func _tick_upgrades(delta: float) -> void:
	for b in buildings:
		if b.alive and b.up_left > 0.0:
			var dtu := minf(delta * (1.0 if power_ok(b.team) else 0.5), b.up_left)
			if b.team == 0 and b.up_cost > 0.0:
				var r := _pay_part(b.up_cost, dtu / maxf(b.up_total, 0.1), b.up_acc, ore)
				if not r[0]:
					_warn_funds("Amélioration")
					continue
				ore -= int(r[1])
				b.up_acc = r[2]
			b.up_left -= dtu
			if b.up_left <= 0.0:
				b.up_left = 0.0
				b.upgrade()
				if b.team == 0:
					sfx.play_ui("upgrade")
					ui.toast("%s — niveau %d" % [GameData.def(b.id)["name"], b.level], GameData.GOLD)
			else:
				b.queue_redraw()
	for u in units:
		if u.alive and u.tech_left > 0.0:
			var dtt := minf(delta, u.tech_left)
			if u.team == 0 and u.tech_cost > 0.0:
				var r2 := _pay_part(u.tech_cost, dtt / maxf(u.tech_total, 0.1), u.tech_acc, credits)
				if not r2[0]:
					_warn_funds("Modernisation")
					continue
				credits -= int(r2[1])
				u.tech_acc = r2[2]
			u.tech_left -= dtt
			if u.tech_left <= 0.0:
				u.apply_tech()
				if u.team == 0:
					sfx.play_ui("upgrade")
					popup(u.position, "▲ Modernisée", GameData.GOLD)
			else:
				u.queue_redraw()


## Coût réel (bonus de faction inclus). Unités : Solaris. Bâtiments : minerai.
func item_cost(id: String) -> int:
	var c := float(GameData.def(id)["cost"])
	if GameData.UNITS.has(id):
		c *= float(fdata["unit_cost_mult"])
	return int(round(c))


func cost_label(id: String) -> String:
	if GameData.UNITS.has(id):
		return "%d $" % item_cost(id)
	return "%d min. + %d $" % [item_cost(id), GameData.sol_cost(id)]


## Part du prix à avoir en caisse pour lancer une production / une amélioration :
## le reste est prélevé au fur et à mesure de l'avancement.
const START_FRAC := 0.1


func can_afford(id: String) -> bool:
	if GameData.UNITS.has(id):
		return credits >= item_cost(id) * START_FRAC
	return ore >= item_cost(id) * START_FRAC and credits >= GameData.sol_cost(id) * START_FRAC


## Prélèvement progressif : `total` * `frac` + reliquat. Renvoie [possible, somme entière à prélever, nouveau reliquat].
func _pay_part(total: float, frac: float, acc: float, avail: int) -> Array:
	var need := acc + total * frac
	var whole := int(floor(need))
	if whole > avail:
		return [false, 0, acc]
	return [true, whole, need - whole]


var _fund_warn := -99.0


func _warn_funds(what: String) -> void:
	if game_time - _fund_warn > 8.0:
		_fund_warn = game_time
		ui.toast("%s en pause : fonds insuffisants" % what, GameData.AMBER)


func _add_money(id: String, amount: int) -> void:
	if GameData.UNITS.has(id):
		credits += amount
	else:
		ore += amount


func on_item_clicked(id: String, button: int) -> void:
	sfx.play_ui("click", -6.0)
	var cat := "unit" if GameData.UNITS.has(id) else "building"
	var q: Array = production[cat]
	var d := GameData.def(id)
	if button == MOUSE_BUTTON_RIGHT:
		# Annule le dernier exemplaire en file (remboursement intégral)
		for i in range(q.size() - 1, -1, -1):
			if q[i]["id"] == id:
				_add_money(id, int(q[i]["paid"]))
				credits += int(q[i].get("paid_sol", 0))
				q.remove_at(i)
				if i == 0 and placing_id == id:
					placing_id = ""
				ui.toast("%s annulé — remboursé" % d["name"], GameData.AMBER)
				return
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	if cat == "building" and not q.is_empty() and q[0]["id"] == id and q[0]["ready"]:
		command_mode = ""
		placing_id = id
		return
	if not is_unlocked(id):
		if mission.is_empty():
			ui.toast("%s : améliorez le Chantier au niveau %d" % [d["name"], chantier_needed(id)], GameData.AMBER)
		else:
			ui.toast("%s : débloqué après la mission %d de la campagne" % [d["name"], int(d.get("unlock", 0))], GameData.AMBER)
		return
	if worker_block(id) != "":
		ui.toast("%s : %d maximum avec ce niveau de Chantier — améliorez le Chantier pour en avoir plus" % [d["name"], worker_cap(id)], GameData.AMBER)
		return
	if unit_level_block(id) != "":
		if GameData.BUILDINGS.has(id):
			ui.toast("%s : %s requis" % [d["name"], unit_level_block(id)], GameData.AMBER)
		else:
			ui.toast("%s : améliorez l'Usine au niveau %d" % [d["name"], int(d["level"])], GameData.AMBER)
		return
	if not is_available(id):
		ui.toast("Prérequis manquant", GameData.RED)
		return
	if q.size() >= queue_max(cat):
		ui.toast("File d'attente pleine (%d) — améliorez %s" % [q.size(), "le Chantier" if cat == "building" else "l'Usine"], GameData.AMBER)
		return
	if not can_afford(id):
		var lack := "Solaris insuffisants"
		if cat == "building" and ore < item_cost(id):
			lack = "Minerai insuffisant" if credits >= GameData.sol_cost(id) else "Minerai et Solaris insuffisants"
		ui.toast(lack, GameData.RED)
		return
	var pwr := power_block(id) if cat == "building" else ""
	if pwr != "":
		ui.toast(pwr, GameData.RED)
		sfx.play_ui("error")
		return
	var cost := item_cost(id)
	var sol := GameData.sol_cost(id) if cat == "building" else 0
	var t := float(d["time"])
	if cat == "building":
		t *= float(fdata["build_time_mult"])
	# Le prix est prélevé progressivement pendant la production (voir _update_production)
	q.append({"id": id, "progress": 0.0, "time": t, "ready": false, "paid": 0, "paid_sol": 0,
			"cost": cost, "sol": sol, "acc": 0.0, "acc_s": 0.0})


func _update_production(delta: float) -> void:
	# Énergie insuffisante : production deux fois plus lente
	var factor := 1.0 if power_produced() >= power_used() else 0.5
	for cat in ["building", "unit"]:
		var q: Array = production[cat]
		if q.is_empty() or q[0]["ready"]:
			continue
		var p: Dictionary = q[0]
		if producer_busy(cat, p["id"]):
			continue # le bâtiment producteur est en travaux
		var f := factor * (unit_speed_bonus() if cat == "unit" else 1.0)
		var dp := minf(delta * f / p["time"], 1.0 - float(p["progress"]))
		var cost_t := float(p.get("cost", 0))
		var sol_t := float(p.get("sol", 0))
		if cost_t > 0.0 or sol_t > 0.0:
			var ro: Array
			var rs := [true, 0, 0.0]
			if cat == "unit":
				ro = _pay_part(cost_t, dp, float(p["acc"]), credits)
			else:
				ro = _pay_part(cost_t, dp, float(p["acc"]), ore)
				rs = _pay_part(sol_t, dp, float(p["acc_s"]), credits)
			if not (ro[0] and rs[0]):
				_warn_funds(String(GameData.def(p["id"])["name"]))
				continue
			if cat == "unit":
				credits -= int(ro[1])
			else:
				ore -= int(ro[1])
				credits -= int(rs[1])
				p["paid_sol"] = int(p["paid_sol"]) + int(rs[1])
				p["acc_s"] = rs[2]
			p["paid"] = int(p["paid"]) + int(ro[1])
			p["acc"] = ro[2]
		p["progress"] += dp
		if p["progress"] >= 1.0:
			p["progress"] = 1.0
			var item_name: String = GameData.def(p["id"])["name"]
			if cat == "unit":
				q.pop_front()
				if has_building(GameData.def(p["id"])["from"]):
					_spawn_produced_unit(p["id"])
					sfx.play_ui("unit_ready")
					ui.toast("%s prêt !" % item_name, GameData.GREEN)
				else:
					credits += int(p["paid"]) # le bâtiment a été détruit : remboursé
					ui.toast("%s annulé — bâtiment perdu" % item_name, GameData.RED)
			else:
				p["ready"] = true
				sfx.play_ui("ready")
				ui.toast("%s prêt — cliquez sur l'icône pour le poser" % item_name, GameData.GREEN)


func _ghost_cell() -> Vector2i:
	var size: Vector2i = GameData.BUILDINGS[placing_id]["size"]
	return _world_to_cell(get_global_mouse_position()) - size / 2


## Un bâtiment se pose sur la roche, sans chevauchement, près de la base.
func _can_place(id: String, cell: Vector2i, team := 0) -> bool:
	var size: Vector2i = GameData.BUILDINGS[id]["size"]
	for dx in size.x:
		for dy in size.y:
			var c := cell + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0 or c.x >= map_w or c.y >= map_h:
				return false
			if terrain[c.x][c.y] != T.ROCK or occupied.has(c):
				return false
	# Zone de construction : autour d'un Chantier. Une seconde base exige un nouvel engin de chantier.
	var center := Vector2(cell) + Vector2(size) / 2.0
	for b in buildings:
		if b.team == team and b.alive and b.id == "chantier" and center.distance_to(b.center_cell()) <= BUILD_RADIUS:
			return true
	return false


func _place_building(id: String, cell: Vector2i, team := 0, with_worker := true) -> Building:
	var d: Dictionary = GameData.BUILDINGS.get(id, GameData.START_BUILDING)
	var b := Building.new()
	b.setup(id, cell, d["size"], TILE, d["power"], faction_color(team))
	b.init_combat(self, team)
	add_child(b)
	buildings.append(b)
	if team != 0: # jamais visible avant d'être repéré (brouillard)
		b.visible = false
		b.seen = false
	if sfx != null and game_time > 1.0:
		sfx.play("place", b.world_center(), -3.0)
	for c in b.cells():
		occupied[c] = true
		grid.set_point_solid(c, true)
	# La raffinerie et la fonderie livrent leur premier ouvrier
	if not with_worker:
		return b
	if id == "raffinerie":
		_spawn_unit("recolteur", _find_free_cell(dock_cell(b, home_of(team))), team)
	elif id == "fonderie":
		_spawn_unit("mineur", _find_free_cell(dock_cell(b, home_of(team))), team)
	return b


## Crée l'engin de chantier de chaque camp (et les IA adverses).
func _setup_sides() -> void:
	for t in team_factions.keys():
		var home := home_of(t)
		if not _save.is_empty():
			pass # les bâtiments et unités viennent de la sauvegarde
		elif GameSession.instant_bases or (not mission.is_empty() and mission.get(["start_base", "enemy_base", "third_base"][t], false)):
			_place_base(Vector2(home), t)
			_spawn_base_units(Vector2(home), t)
		else:
			_spawn_unit("mcv", _find_free_cell(home), t)
		if t == 0:
			continue
		var a := SkirmishAI.new()
		a.setup(self, team_factions[t], t)
		a.home = Vector2(home)
		a.foe = nearest_foe_home(t) if nearest_foe_home(t).x >= 0 else start_cell
		if not mission.is_empty():
			a.configure(mission["ai"] if t == 1 else mission.get("third_ai", mission["ai"]))
		elif _save.is_empty():
			a.configure(SKIRMISH_DIFF[GameSession.skirm_diff])
		add_child(a)
		ais[t] = a
	ai = ais.get(1)


## Base complète instantanée (tests automatisés uniquement).
func _place_base(origin: Vector2, team: int) -> void:
	var o := Vector2i(origin)
	_place_building("chantier", o + Vector2i(-1, -2), team)
	_place_building("centrale", o + Vector2i(-4, -2), team)
	_place_building("raffinerie", o + Vector2i(3, -1), team)
	_place_building("fonderie", o + Vector2i(-4, 1), team)


func _spawn_base_units(origin: Vector2, team: int) -> void:
	var o := Vector2i(origin)
	var ids: Array = fdata_of(team)["units"]
	for i in 2:
		_spawn_unit(ids[i], _find_free_cell(o + Vector2i(-1 + i * 2, 3)), team)


# --- Engin de chantier ----------------------------------------------------------

func _deploy_ok(cell: Vector2i) -> bool:
	var size: Vector2i = GameData.START_BUILDING["size"]
	for dx in size.x:
		for dy in size.y:
			var c := cell + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0 or c.x >= map_w or c.y >= map_h:
				return false
			if terrain[c.x][c.y] != T.ROCK or occupied.has(c):
				return false
	return true


## Case (coin haut-gauche) où l'engin se déploierait, ou (-1, -1).
func deploy_cell_for(u: Unit, search := false) -> Vector2i:
	var base := _world_to_cell(u.position) - Vector2i(1, 1)
	if _deploy_ok(base):
		return base
	if search:
		for r in range(1, 9):
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					if maxi(absi(dx), absi(dy)) == r and _deploy_ok(base + Vector2i(dx, dy)):
						return base + Vector2i(dx, dy)
	return Vector2i(-1, -1)


func deploy_mcv(u: Unit, search := false) -> bool:
	var cell := deploy_cell_for(u, search)
	if cell.x < 0:
		if u.team == 0 and ui != null:
			ui.toast("Déploiement impossible : il faut un terrain rocheux dégagé", GameData.RED)
			sfx.play_ui("error")
		return false
	var team := u.team
	u.alive = false
	units.erase(u)
	selected.erase(u)
	if inspected == u:
		inspected = null
	u.queue_free()
	var b := _place_building("chantier", cell, team)
	Fx.burst(self, b.world_center(), Color(0.85, 0.65, 0.5), 30, 1.4)
	if team == 0 and ui != null:
		ui.toast("Chantier déployé — vous pouvez construire", GameData.GREEN)
		sfx.play_ui("ready")
	return true


# --- Missions -------------------------------------------------------------------

func _setup_mission() -> void:
	if not _save.is_empty():
		obj_state = []
		for o in mission["objectives"]:
			obj_state.append({"done": false})
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for id in Campaign.resolve_units(faction_id, mission.get("start_units", [])):
		_spawn_unit(id, _find_free_cell(Vector2i(start_cell) + Vector2i(rng.randi_range(-3, 3), 3)), 0)
	if ally_cell.x >= 0:
		var ids: Array = fdata_of(2)["units"]
		for i in int(mission.get("ally_units", 0)):
			_spawn_unit(ids[i % ids.size()], _find_free_cell(Vector2i(ally_cell) + Vector2i(rng.randi_range(-3, 3), 3)), 2)
	var foe_ids: Array = fdata_of(1)["units"]
	for i in int(mission.get("outposts", 0)):
		var p: Vector2 = mission_points["outpost%d" % i]
		var offs := [Vector2i(-3, -1), Vector2i(2, -1), Vector2i(-1, 2)]
		for o in offs:
			var cell: Vector2i = Vector2i(p) + o
			if _can_place_free("tourelle", cell):
				var b := _place_building("tourelle", cell, 1)
				b.outpost = i
		for g in 3:
			var u := _spawn_unit(foe_ids[g % foe_ids.size()], _find_free_cell(Vector2i(p) + Vector2i(g - 1, 4)), 1)
			u.guard = true
	if mission.has("convoy"):
		var dest := Vector2i(mission_points["dest"])
		var n := int(mission["convoy"]["count"])
		for i in n:
			var u := _spawn_unit("convoi", _find_free_cell(Vector2i(start_cell) + Vector2i(i - n / 2, 5)), 0)
			u.convoy = true
		convoy_total = n
		# Embuscades : groupes ennemis immobiles le long de la route
		var amb := int(mission["convoy"].get("ambushes", 0))
		for k in amb:
			var f := lerpf(0.4, 0.85, float(k) / maxf(amb - 1, 1.0))
			var pos := start_cell.lerp(Vector2(dest), f) + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4))
			for g in int(mission["convoy"].get("ambush_size", 3)):
				var u := _spawn_unit(foe_ids[g % foe_ids.size()], _find_free_cell(Vector2i(pos) + Vector2i(g - 1, 0)), 1)
				u.guard = true
	obj_state = []
	for o in mission["objectives"]:
		obj_state.append({"done": false})
	_update_objectives(0.0)


func _can_place_free(id: String, cell: Vector2i) -> bool:
	var size: Vector2i = GameData.BUILDINGS[id]["size"]
	for dx in size.x:
		for dy in size.y:
			var c := cell + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0 or c.x >= map_w or c.y >= map_h:
				return false
			if terrain[c.x][c.y] != T.ROCK or occupied.has(c):
				return false
	return true


func _team_alive(t: int) -> bool:
	for b in buildings:
		if b.team == t and b.alive:
			return true
	for u in units:
		if u.team == t and u.alive and u.id == "mcv":
			return true
	return false


func _side_alive(side: int) -> bool:
	for t in team_factions.keys():
		if side_of(t) == side and _team_alive(t):
			return true
	return false


func _count_combat(team := 0) -> int:
	var n := 0
	for u in units:
		if u.team == team and u.alive and u.role == "combat":
			n += 1
	return n


## Met à jour la progression des objectifs (appelée toutes les 0,5 s).
func _update_objectives(dt: float) -> void:
	if mission.is_empty():
		return
	var objs: Array = mission["objectives"]
	var tile := float(TILE)
	# Convoi : départ différé pour laisser le temps de s'organiser
	if mission_points.has("dest") and not convoy_started and game_time >= float(mission["convoy"].get("start", 150.0)):
		convoy_started = true
		var dcell := _find_free_cell(Vector2i(mission_points["dest"]))
		for u in units:
			if u.convoy and u.alive:
				u.order_path(path_to(u.position, dcell))
		ui.toast("Le convoi se met en route : escortez-le !", GameData.GOLD)
		sfx.play_ui("alert")
	# Convoi : arrivées
	if mission_points.has("dest"):
		var dpos: Vector2 = mission_points["dest"] * tile + Vector2(tile, tile) * 0.5
		for u in units.duplicate():
			if u.convoy and u.alive and u.position.distance_to(dpos) < 3.5 * tile:
				arrived += 1
				popup(u.position, "Convoi arrivé", GameData.GREEN)
				sfx.play_ui("unit_ready")
				u.alive = false
				units.erase(u)
				selected.erase(u)
				u.queue_free()
	# Zone à tenir
	if mission_points.has("zone"):
		var zpos: Vector2 = mission_points["zone"] * tile + Vector2(tile, tile) * 0.5
		var mine := 0
		var foes := 0
		for u in units:
			if u.alive and u.role == "combat" and u.position.distance_to(zpos) < ZONE_RADIUS * tile:
				if side_of(u.team) == 0:
					mine += 1
				else:
					foes += 1
		hold_ok = mine >= int(mission["zone"]["units"]) and foes == 0
		if hold_ok:
			hold_t += dt
	for i in objs.size():
		if obj_state[i]["done"]:
			continue
		obj_state[i]["done"] = float(objective_info(i)["frac"]) >= 1.0
	zone_done = mission_points.has("zone") and hold_t >= float(mission["zone"]["time"])
	escort_done = mission_points.has("dest") and arrived >= int(mission["convoy"]["need"])


## Texte et avancement (0..1) de l'objectif i.
func objective_info(i: int) -> Dictionary:
	var o: Dictionary = mission["objectives"][i]
	match o["type"]:
		"build":
			var need := 0
			var have := 0
			for id in o["ids"]:
				need += int(o["ids"][id])
				have += mini(count_buildings(id), int(o["ids"][id]))
			return {"text": "Construire %s : %d/%d" % [o["label"], have, need], "frac": float(have) / need}
		"harvest":
			var a: int = o["amount"]
			return {"text": "Récolter %d Solaris : %d" % [a, mini(earned, a)], "frac": clampf(float(earned) / a, 0.0, 1.0)}
		"train":
			var n: int = o["count"]
			var c := _count_combat()
			return {"text": "Armée de %d unités : %d" % [n, mini(c, n)], "frac": clampf(float(c) / n, 0.0, 1.0)}
		"survive":
			var t: float = o["time"]
			var left := maxf(t - game_time, 0.0)
			return {"text": "Tenir encore %d:%02d" % [int(left / 60.0), int(left) % 60], "frac": clampf(game_time / t, 0.0, 1.0)}
		"destroy_all":
			var n := 0
			for b in buildings:
				if b.alive and hostile(b.team, 0):
					n += 1
			var alive := _foes_alive()
			return {"text": ("Détruire les ennemis : %d structure(s)" if third_hostile else "Détruire l'ennemi : %d structure(s)") % n, "frac": 0.0 if alive else 1.0}
		"outposts":
			var total := int(mission.get("outposts", 0))
			var left := 0
			for k in total:
				for b in buildings:
					if b.alive and b.outpost == k:
						left += 1
						break
			return {"text": "Avant-postes détruits : %d/%d" % [total - left, total], "frac": float(total - left) / maxf(total, 1)}
		"escort":
			var need: int = mission["convoy"]["need"]
			if not convoy_started:
				var wait := int(maxf(float(mission["convoy"].get("start", 150.0)) - game_time, 0.0))
				return {"text": "Le convoi part dans %d:%02d" % [wait / 60, wait % 60], "frac": 0.0}
			return {"text": "Convoi arrivé : %d/%d (%d en route)" % [arrived, need, _convoy_alive()],
					"frac": clampf(float(arrived) / need, 0.0, 1.0)}
		"hold":
			var t: float = mission["zone"]["time"]
			return {"text": "Tenir la zone : %d/%d s" % [int(minf(hold_t, t)), int(t)] + ("" if hold_ok or hold_t >= t else "  (en attente)"),
					"frac": clampf(hold_t / t, 0.0, 1.0)}
		"upgrade":
			var lv: int = best_level(o["id"]) if has_building(o["id"]) else 0
			var need_l: int = o["level"]
			return {"text": "%s niveau %d : %d/%d" % [GameData.def(o["id"])["name"], need_l, mini(lv, need_l), need_l],
					"frac": clampf(float(lv) / need_l, 0.0, 1.0)}
		"kills":
			var nk: int = o["count"]
			return {"text": "Unités ennemies détruites : %d/%d" % [mini(kills, nk), nk], "frac": clampf(float(kills) / nk, 0.0, 1.0)}
		"destroy_type":
			var nd: int = o["count"]
			var got := int(destroyed.get(o["id"], 0))
			return {"text": "Structure ennemie « %s » détruite : %d/%d" % [GameData.def(o["id"])["name"], mini(got, nd), nd],
					"frac": clampf(float(got) / nd, 0.0, 1.0)}
		"ore":
			var ao: int = o["amount"]
			return {"text": "Récolter %d minerai : %d" % [ao, mini(ore_earned, ao)], "frac": clampf(float(ore_earned) / ao, 0.0, 1.0)}
		"power":
			var ap: int = o["amount"]
			var pp := power_produced()
			return {"text": "Produire %d d'énergie : %d" % [ap, mini(pp, ap)], "frac": clampf(float(pp) / ap, 0.0, 1.0)}
		"air":
			var na: int = o["count"]
			var ca := 0
			for u in units:
				if u.team == 0 and u.alive and u.air and u.role == "combat":
					ca += 1
			return {"text": "Flotte aérienne : %d/%d" % [mini(ca, na), na], "frac": clampf(float(ca) / na, 0.0, 1.0)}
	return {"text": "", "frac": 0.0}


func _convoy_alive() -> int:
	var n := 0
	for u in units:
		if u.convoy and u.alive:
			n += 1
	return n


func objectives_status() -> Array:
	var out: Array = []
	if mission.is_empty():
		return out
	for i in mission["objectives"].size():
		var info := objective_info(i)
		info["done"] = obj_state[i]["done"]
		out.append(info)
	if mission.has("time_limit"):
		var lim := float(mission["time_limit"])
		var left := maxf(lim - game_time, 0.0)
		out.append({"text": "Temps limite : %d:%02d" % [int(left / 60.0), int(left) % 60],
				"frac": clampf(game_time / lim, 0.0, 1.0), "done": false})
	return out


func _spawn_produced_unit(id: String) -> void:
	spawn_for(id, 0)


## Fait apparaître une unité produite par un camp, devant son bâtiment de production.
func spawn_for(id: String, team: int) -> Unit:
	var from_id: String = GameData.def(id)["from"]
	var dock := _find_free_cell(_dock_of(from_id, team))
	var u := _spawn_unit(id, dock, team)
	var b: Building = null
	for bb in buildings:
		if bb.id == from_id and bb.team == team and bb.alive:
			b = bb
			break
	if b == null or not Models.DOORS.has(from_id):
		return u
	var door: Dictionary = Models.DOORS[from_id]
	var c := b.world_center()
	b.open_door(1.7)
	if door.has("pad"):
		# Appareil : décolle de la piste et rejoint son point de ralliement
		var pad: Vector3 = door["pad"]
		u.begin_emerge(c + Vector2(pad.x, pad.z), _cell_to_world(dock), 1.5)
		return u
	var edge_y := c.y + float(b.cell_size.y * TILE) * 0.5
	var front := _world_to_cell(Vector2(c.x + float(door["x"]), edge_y + 8.0))
	if not _is_walkable(front) or _cell_has_unit(front):
		return u # devant la porte, c'est bouché : apparition directe
	u.begin_emerge(Vector2(c.x + float(door["x"]), c.y + float(door["z"]) - 20.0), _cell_to_world(front), 1.3, _cell_to_world(dock))
	return u


## Ordre de déplacement pour une unité isolée (sortie d'usine...).
func order_unit_move(u: Unit, world_pos: Vector2) -> void:
	var cell := _world_to_cell(world_pos)
	if u.air:
		u.order_path(PackedVector2Array([u.position, world_pos]))
	elif _is_walkable(cell):
		u.order_path(path_to(u.position, cell))


func _dock_of(building_id: String, team := 0) -> Vector2i:
	var s := home_of(team)
	for b in buildings:
		if b.id == building_id and b.team == team:
			return dock_cell(b, s)
	return s


func _spawn_unit(id: String, cell: Vector2i, team := 0) -> Unit:
	var u := Unit.new()
	u.team = team
	u.setup(id, self, faction_color(team))
	u.position = _cell_to_world(cell)
	add_child(u)
	units.append(u)
	if team != 0:
		u.visible = false
		u.seen = false
	return u


func _find_free_cell(start: Vector2i) -> Vector2i:
	for r in 8:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := start + Vector2i(dx, dy)
				if _is_walkable(c) and not _cell_has_unit(c):
					return c
	return start


func _cell_has_unit(c: Vector2i) -> bool:
	for u in units:
		if _world_to_cell(u.position) == c:
			return true
	return false


# --- Utilitaires --------------------------------------------------------------

func _is_walkable(c: Vector2i) -> bool:
	return grid.is_in_boundsv(c) and not grid.is_point_solid(c)


func is_sand_at(world: Vector2) -> bool:
	var c := _world_to_cell(world)
	var t: int = terrain[c.x][c.y]
	return t == T.SAND or t == T.SPICE


func path_to(from_world: Vector2, to_cell: Vector2i) -> PackedVector2Array:
	return grid.get_point_path(_world_to_cell(from_world), to_cell)


func world_to_cell(p: Vector2) -> Vector2i:
	return _world_to_cell(p)


func _world_to_cell(p: Vector2) -> Vector2i:
	var c := Vector2i((p / TILE).floor())
	return c.clamp(Vector2i.ZERO, Vector2i(map_w - 1, map_h - 1))


func _cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c) * TILE + Vector2(TILE, TILE) / 2.0


# --- Rendu --------------------------------------------------------------------

func _draw() -> void:
	if dragging:
		var r := Rect2(drag_start, get_global_mouse_position() - drag_start).abs()
		draw_rect(r, Color(0.3, 1.0, 0.6, 0.12))
		draw_rect(r, GameData.GREEN, false, 1.5)
	for u in selected:
		if u.role == "mcv":
			var dc := _world_to_cell(u.position) - Vector2i(1, 1)
			var ok_d := _deploy_ok(dc)
			var col_d := Color(0.3, 1.0, 0.5, 0.28) if ok_d else Color(1.0, 0.25, 0.25, 0.28)
			for dx in 3:
				for dy in 3:
					draw_rect(Rect2(Vector2(dc + Vector2i(dx, dy)) * TILE, Vector2(TILE, TILE)), col_d)
	if placing_id != "":
		# Zones de construction des Chantiers
		for b in buildings:
			if b.team == 0 and b.alive and b.id == "chantier":
				var zc := b.center_cell() * TILE
				draw_circle(zc, BUILD_RADIUS * TILE, Color(0.3, 0.9, 1.0, 0.05))
				draw_arc(zc, BUILD_RADIUS * TILE, 0.0, TAU, 96, Color(0.4, 0.95, 1.0, 0.6), 3.0, true)
		var size: Vector2i = GameData.BUILDINGS[placing_id]["size"]
		var cell := _ghost_cell()
		var ok := _can_place(placing_id, cell)
		var col := Color(0.3, 1.0, 0.5, 0.35) if ok else Color(1.0, 0.25, 0.25, 0.35)
		for dx in size.x:
			for dy in size.y:
				var rect := Rect2(Vector2(cell + Vector2i(dx, dy)) * TILE, Vector2(TILE, TILE))
				draw_rect(rect, col)
				draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)


# --- Sauvegarde / chargement --------------------------------------------------

func open_pause_menu() -> void:
	if pause_menu != null or loading != null:
		return
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.setup(self)


## État complet de la partie (la carte est régénérée à partir de sa graine).
func _collect_state() -> Dictionary:
	var ulist: Array = []
	var idx := {}
	for u in units:
		if is_instance_valid(u) and u.alive:
			idx[u] = ulist.size()
			ulist.append(u)
	var us: Array = []
	for u in ulist:
		us.append(u.export_state(idx))
	var bs: Array = []
	for b in buildings:
		if is_instance_valid(b) and b.alive:
			bs.append(b.export_state())
	var res := {}
	for c in resource:
		res[c] = float(resource[c]["amount"])
	var ai_state := {}
	for t in ais:
		ai_state[t] = ais[t].export_state()
	return {
		"seed": map_seed, "faction": faction_id, "mode": GameSession.mode, "mission": GameSession.mission,
		"team_factions": team_factions, "third_hostile": third_hostile, "game_time": game_time,
		"credits": credits, "ore": ore, "earned": earned, "ore_earned": ore_earned, "kills": kills, "destroyed": destroyed,
		"production": production.duplicate(true),
		"units": us, "buildings": bs, "resource": res, "ais": ai_state,
		"fog_seen": fog_seen, "worm_cooldown": worm_cooldown,
		"inc_acc": _inc_acc.duplicate(), "obj_state": obj_state.duplicate(true),
		"arrived": arrived, "convoy_total": convoy_total, "hold_t": hold_t, "hold_ok": hold_ok,
		"zone_done": zone_done, "escort_done": escort_done, "convoy_started": convoy_started,
		"cam_pos": camera.position, "cam_zoom": camera.zoom,
	}


func save_game(slot: int, announce := true) -> bool:
	if over or loading != null or ui == null:
		return false
	var ok := SaveGame.write(slot, _collect_state())
	if announce:
		ui.toast("Partie sauvegardée — %s" % SaveGame.slot_name(slot) if ok else "Échec de la sauvegarde",
				GameData.GREEN if ok else GameData.RED)
		sfx.play_ui("ready" if ok else "error", -4.0)
	return ok


func load_game(slot: int) -> void:
	if not SaveGame.exists(slot) or SaveGame.read(slot).is_empty():
		if ui != null:
			ui.toast("Aucune sauvegarde dans cet emplacement", GameData.RED)
		return
	GameSession.load_slot = slot
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")


## Reconstruit la partie sauvegardée par-dessus la carte régénérée.
func _apply_state() -> void:
	var d := _save
	# Gisements : cases épuisées ou entamées
	var saved_res: Dictionary = d["resource"]
	for c in resource.keys():
		if not saved_res.has(c):
			extract(c, 1.0e9)
		else:
			var r: Dictionary = resource[c]
			var a := float(saved_res[c])
			if absf(a - float(r["amount"])) > 0.01:
				r["amount"] = a
				dirty[c] = {"kind": r["kind"], "frac": a / float(r["max"])}
	# Bâtiments (de gros bâtiments d'abord : ordre sans importance, les cases sont disjointes)
	for bd in d["buildings"]:
		var b := _place_building(String(bd["id"]), bd["cell"], int(bd["team"]), false)
		b.restore_state(bd)
	# Unités
	var made: Array = []
	for ud in d["units"]:
		var u := _spawn_unit(String(ud["id"]), Vector2i.ZERO, int(ud["team"]))
		u.restore_state(ud)
		made.append(u)
	for i in made.size():
		for k in d["units"][i].get("cargo", []):
			var c: Unit = made[int(k)]
			c.carried = true
			c.visible = false
			made[i].cargo_units.append(c)
	# Camps adverses
	for t in d["ais"]:
		if ais.has(int(t)):
			ais[int(t)].restore_state(d["ais"][t])
	# Économie et files
	credits = int(d["credits"])
	ore = int(d["ore"])
	earned = int(d["earned"])
	ore_earned = int(d.get("ore_earned", 0))
	kills = int(d.get("kills", 0))
	destroyed = d.get("destroyed", {})
	production = d["production"]
	game_time = float(d["game_time"])
	worm_cooldown = float(d["worm_cooldown"])
	for k in d["inc_acc"]:
		_inc_acc[int(k)] = float(d["inc_acc"][k])
	# Mission
	obj_state = d["obj_state"]
	arrived = int(d["arrived"])
	convoy_total = int(d["convoy_total"])
	hold_t = float(d["hold_t"])
	hold_ok = bool(d["hold_ok"])
	zone_done = bool(d["zone_done"])
	escort_done = bool(d["escort_done"])
	convoy_started = bool(d["convoy_started"])
	# Brouillard et caméra
	var fs: PackedByteArray = d["fog_seen"]
	if FOG and fs.size() == fog_seen.size():
		fog_seen = fs
	camera.position = d["cam_pos"]
	camera.zoom = d["cam_zoom"]
	_clamp_camera()
	_save = {}
	_obj_t = 0.0
	ui.toast("Partie chargée", GameData.GREEN)
