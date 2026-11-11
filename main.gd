extends Node2D
## Scène principale : terrain (shader), ressources, caméra, sélection,
## production, placement de bâtiments et vers géants. Interface : ui.gd.

const TILE := 32
const MINIMAP_RES := 128
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
var ally_cell := Vector2(-1, -1)       # case de départ de l'allié (-1 : pas d'allié)
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
var _obj_t := 0.0
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

var tier := 0 # missions de campagne terminées : débloque les bâtiments
var _inc_acc := {0: 0.0, 1: 0.0, 2: 0.0}
var credits := 1000 # Solaris (épice raffinée) : payent les unités
var ore := 1500     # Minerai : paye les bâtiments
var game_time := 0.0
var production := {"building": [], "unit": []} # files d'attente (le premier élément est en cours)
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
	faction_id = GameSession.faction
	fdata = GameData.FACTIONS[faction_id]
	if GameSession.mode == "campaign":
		mission = Campaign.mission(faction_id, GameSession.mission)
		credits = int(mission["credits"])
		ore = int(mission["ore"])
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

## Factions de chaque équipe : 0 = joueur, 1 = adversaire, 2 = allié (missions).
func _setup_factions() -> void:
	var others: Array = GameData.FACTIONS.keys().filter(func(k: String) -> bool: return k != faction_id)
	others.shuffle()
	var enemy: String = others[0]
	if not mission.is_empty():
		enemy = Campaign.enemy_of(faction_id, GameSession.mission)
	team_factions = {0: faction_id, 1: enemy}
	enemy_faction = enemy
	if not mission.is_empty() and mission.get("ally", false):
		for k in others:
			if k != enemy:
				team_factions[2] = k


## Place bases, champs et couloirs de façon aléatoire (carte carrée).
func _generate_layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var size := 96
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
	if mission.get("ally", false):
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
	var base := randi()
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
func find_resource(kind: String, from: Vector2i, max_dist := 999) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for c in resource:
		var r: Dictionary = resource[c]
		if r["kind"] != kind or occupied.has(c):
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
	for b in buildings:
		if b.id == want and b.team == team:
			var d := Vector2(from).distance_to(b.center_cell())
			if d < best_d:
				best_d = d
				best = b
	return best


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
func deposit(kind: String, amount: float, world_pos: Vector2, team := 0) -> void:
	var fd := fdata_of(team)
	var gain := int(amount * float(fd["spice_mult" if kind == "spice" else "ore_mult"]) * income_bonus(kind, team))
	if team == 0:
		if kind == "spice":
			credits += gain
			earned += gain
		else:
			ore += gain
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
	if worm_cooldown > 0.0 or game_time < WORM_GRACE:
		return
	var workers := _harvesters_on_sand()
	if workers.is_empty():
		return
	# Très rare : probabilité proportionnelle au nombre de récolteurs en activité
	if randf() < WORM_RATE * workers.size() * delta:
		_spawn_worm(workers.pick_random())


func _harvesters_on_sand() -> Array:
	var out := []
	for u in units:
		if u.is_worker() and u.state == "harvest" and is_sand_at(u.position):
			out.append(u)
	return out


func _spawn_worm(target) -> void:
	sfx.play_ui("worm", -2.0)
	var start: Vector2 = target.position + Vector2.RIGHT * 640.0
	for i in 16:
		var p: Vector2 = target.position + Vector2.from_angle(randf() * TAU) * 640.0
		p = p.clamp(Vector2(40, 40), world_size - Vector2(40, 40))
		if is_sand_at(p):
			start = p
			break
	start = start.clamp(Vector2(40, 40), world_size - Vector2(40, 40))
	worm = Worm.new()
	worm.setup(self, start, target)
	add_child(worm)
	worm.finished.connect(_on_worm_finished)
	alert_worm()


func _on_worm_finished() -> void:
	worm = null
	worm_cooldown = WORM_COOLDOWN


## Alerte : les ouvriers proches, sur le sable, se réfugient sur la roche.
func alert_worm() -> void:
	ui.toast("ALERTE : vibrations détectées, un ver approche !", GameData.RED)
	for u in units:
		if u.is_worker() and is_sand_at(u.position) and u.position.distance_to(worm.position) < 700.0:
			u.flee()


func nearest_sand_unit(pos: Vector2, max_d: float) -> Unit:
	var best: Unit = null
	var best_d := max_d
	for u in units:
		if is_sand_at(u.position):
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
		if side_of(u.team) == 0 and u.alive:
			_reveal(u.position, u.vision)
	for b in buildings:
		if side_of(b.team) == 0 and b.alive:
			_reveal(b.world_center(), b.vision)
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
		if side_of(u.team) == 0:
			u.seen = true
		else:
			u.seen = is_visible_cell(_world_to_cell(u.position))
		u.visible = u.seen
	for b in buildings:
		if side_of(b.team) == 0:
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


## Camp : 0 = joueur et allié (équipes 0 et 2), 1 = adversaire.
func side_of(team: int) -> int:
	return 1 if team == 1 else 0


func hostile(a: int, b: int) -> bool:
	return side_of(a) != side_of(b)


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
func find_enemy(team: int, pos: Vector2, max_d: float, units_only := false):
	var best = null
	var best_s := INF
	for u in units:
		if not hostile(u.team, team) or not u.alive or (side_of(team) == 0 and not u.seen):
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
			if not hostile(b.team, team) or not b.alive or (side_of(team) == 0 and not b.seen):
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
		if hostile(u.team, 0) and u.alive and u.seen and u.position.distance_to(world_pos) < u.radius + 8.0:
			return u
	for b in buildings:
		if hostile(b.team, 0) and b.alive and b.visible and Rect2(b.position, Vector2(b.cell_size * TILE)).has_point(world_pos):
			return b
	return null


func fire(shooter, target, weapon: String, damage: float, from: Vector2, control := false) -> void:
	var p := Projectile.new()
	p.setup(self, weapon, shooter.team, from, target, damage, shooter, control)
	add_child(p)
	Fx.burst(self, from, GameData.WEAPONS[weapon]["color"], 4, 0.35)
	sfx.play(weapon, from, -4.0)


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
		if "protect_ally" in types and not _team_alive(2):
			lost = true
			reason = "Votre allié est tombé."
		if "escort" in types and not escort_done and _convoy_alive() + arrived < int(mission["convoy"]["need"]):
			lost = true
			reason = "Le convoi a été détruit."
	var won := false
	if not lost:
		if mission.is_empty():
			won = not _side_alive(1)
		else:
			_update_objectives(0.0)
			won = not _side_alive(1)
			if not won:
				won = true
				for i in mission["objectives"].size():
					if not obj_state[i]["done"] and mission["objectives"][i]["type"] != "protect_ally":
						won = false
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
	_update_production(delta)
	_tick_upgrades(delta)
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				placing_id = ""
				command_mode = ""
				_clear_focus()
			KEY_F11:
				var w := get_window()
				w.mode = Window.MODE_MAXIMIZED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_D:
				on_command("deploy")
			KEY_M:
				var off := sfx.toggle_mute()
				ui.toast("Son coupé" if off else "Son activé", GameData.AMBER)
			KEY_F10:
				get_tree().change_scene_to_file("res://menu.tscn")
			KEY_F9: # test : fait surgir un ver tout de suite
				if worm == null and not units.is_empty():
					var sand := _harvesters_on_sand()
					_spawn_worm(sand.pick_random() if not sand.is_empty() else units.pick_random())
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
			ui.toast("Emplacement invalide : roche libre, près de la base", GameData.RED)
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
		if u.alive and u.seen and u.position.distance_to(world_pos) < u.radius + 6.0:
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
		if u.team != 0:
			continue
		var hit := u.position.distance_to(end) < u.radius + 4.0 if is_click \
				else rect.has_point(u.position)
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
		order_move(world_pos)
		return
	for u in selected:
		u.order_attack(e)
	Fx.burst(self, e.world_center(), GameData.RED, 6, 0.5)


func order_amove(world_pos: Vector2) -> void:
	var target := _world_to_cell(world_pos)
	for i in selected.size():
		var cell := target + _formation_offset(i, selected.size())
		if not _is_walkable(cell):
			cell = target
		if _is_walkable(cell):
			selected[i].order_amove(cell)


func order_move(world_pos: Vector2) -> void:
	var target := _world_to_cell(world_pos)
	for i in selected.size():
		var cell := target + _formation_offset(i, selected.size())
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
		"stop":
			for u in selected:
				u.stop()
		"move":
			placing_id = ""
			command_mode = "move"
		"attack":
			placing_id = ""
			command_mode = "attack"


# --- Production & construction ------------------------------------------------

func is_unlocked(id: String) -> bool:
	if not GameData.BUILDINGS.has(id):
		return true
	var d: Dictionary = GameData.BUILDINGS[id]
	var f: String = d.get("faction", "")
	return int(d.get("unlock", 0)) <= tier and (f == "" or f == faction_id)


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
func unit_level_block(id: String, team := 0) -> String:
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
	return bonus


## Effets des bâtiments spéciaux, toutes les 0,5 s : revenus passifs et soins.
func _building_effects(dt: float) -> void:
	for b in buildings:
		if not b.alive:
			continue
		var d := GameData.def(b.id)
		if d.has("income"):
			_inc_acc[b.team] = float(_inc_acc.get(b.team, 0.0)) + float(d["income"]) * dt
		if d.has("heal"):
			var r: float = float(d["heal_range"]) * TILE
			for u in units:
				if u.alive and side_of(u.team) == side_of(b.team) and u.hp < u.max_hp \
						and u.position.distance_to(b.world_center()) < r + b.radius_px():
					u.hp = minf(u.max_hp, u.hp + float(d["heal"]) * dt)
					u.queue_redraw()
	for t in _inc_acc.keys():
		var whole := int(_inc_acc[t])
		if whole > 0:
			_inc_acc[t] = float(_inc_acc[t]) - whole
			if t == 0:
				credits += whole
			elif ais.has(t):
				ais[t].credits += whole


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
	if money < upgrade_cost(b):
		return "Minerai insuffisant"
	return ""


## Lance le chronomètre d'amélioration (le coût est déjà payé).
func begin_upgrade(b: Building) -> void:
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
	ore -= upgrade_cost(b)
	begin_upgrade(b)
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
	if credits < GameData.tech_cost(u.id):
		return "Solaris insuffisants"
	return ""


func upgrade_unit(u: Unit) -> bool:
	var why := unit_upgrade_block(u)
	if why != "":
		ui.toast(why, GameData.RED)
		sfx.play_ui("error")
		return false
	credits -= GameData.tech_cost(u.id)
	u.tech_total = GameData.tech_time(u.id)
	u.tech_left = u.tech_total
	u.queue_redraw()
	sfx.play_ui("click")
	ui.toast("%s : modernisation en cours (%d s)" % [GameData.def(u.id)["name"], int(u.tech_total)], GameData.AMBER)
	return true


## Fait avancer les améliorations de bâtiments et les modernisations d'unités.
func _tick_upgrades(delta: float) -> void:
	for b in buildings:
		if b.alive and b.up_left > 0.0:
			b.up_left -= delta * (1.0 if power_ok(b.team) else 0.5)
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
			u.tech_left -= delta
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
	return ("%d $" if GameData.UNITS.has(id) else "%d min.") % item_cost(id)


func can_afford(id: String) -> bool:
	return (credits if GameData.UNITS.has(id) else ore) >= item_cost(id)


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
		ui.toast("%s : débloqué après la mission %d de la campagne" % [d["name"], int(d.get("unlock", 0))], GameData.AMBER)
		return
	if unit_level_block(id) != "":
		ui.toast("%s : améliorez l'Usine au niveau %d" % [d["name"], int(d["level"])], GameData.AMBER)
		return
	if not is_available(id):
		ui.toast("Prérequis manquant", GameData.RED)
		return
	if q.size() >= queue_max(cat):
		ui.toast("File d'attente pleine (%d) — améliorez %s" % [q.size(), "le Chantier" if cat == "building" else "l'Usine"], GameData.AMBER)
		return
	if not can_afford(id):
		ui.toast("Minerai insuffisant" if cat == "building" else "Solaris insuffisants", GameData.RED)
		return
	var pwr := power_block(id) if cat == "building" else ""
	if pwr != "":
		ui.toast(pwr, GameData.RED)
		sfx.play_ui("error")
		return
	var cost := item_cost(id)
	_add_money(id, -cost)
	var t := float(d["time"])
	if cat == "building":
		t *= float(fdata["build_time_mult"])
	q.append({"id": id, "progress": 0.0, "time": t, "ready": false, "paid": cost})


func _update_production(delta: float) -> void:
	# Énergie insuffisante : production deux fois plus lente
	var factor := 1.0 if power_produced() >= power_used() else 0.5
	for cat in ["building", "unit"]:
		var q: Array = production[cat]
		if q.is_empty() or q[0]["ready"]:
			continue
		var p: Dictionary = q[0]
		var f := factor * (unit_speed_bonus() if cat == "unit" else 1.0)
		p["progress"] += delta * f / p["time"]
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
	var center := Vector2(cell) + Vector2(size) / 2.0
	for b in buildings:
		if b.team == team and center.distance_to(b.center_cell()) <= 9.0:
			return true
	return false


func _place_building(id: String, cell: Vector2i, team := 0) -> Building:
	var d: Dictionary = GameData.BUILDINGS.get(id, GameData.START_BUILDING)
	var b := Building.new()
	b.setup(id, cell, d["size"], TILE, d["power"], faction_color(team))
	b.init_combat(self, team)
	add_child(b)
	buildings.append(b)
	if sfx != null and game_time > 1.0:
		sfx.play("place", b.world_center(), -3.0)
	for c in b.cells():
		occupied[c] = true
		grid.set_point_solid(c, true)
	# La raffinerie et la fonderie livrent leur premier ouvrier
	if id == "raffinerie":
		_spawn_unit("recolteur", _find_free_cell(dock_cell(b, home_of(team))), team)
	elif id == "fonderie":
		_spawn_unit("mineur", _find_free_cell(dock_cell(b, home_of(team))), team)
	return b


## Crée l'engin de chantier de chaque camp (et les IA adverse / alliée).
func _setup_sides() -> void:
	for t in team_factions.keys():
		var home := home_of(t)
		if GameSession.instant_bases:
			_place_base(Vector2(home), t)
			_spawn_base_units(Vector2(home), t)
		else:
			_spawn_unit("mcv", _find_free_cell(home), t)
		if t == 0:
			continue
		var a := SkirmishAI.new()
		a.setup(self, team_factions[t], t)
		a.home = Vector2(home)
		a.foe = enemy_cell if t == 2 else start_cell
		if not mission.is_empty():
			a.configure(mission["ai"] if t == 1 else mission.get("ally_ai", mission["ai"]))
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
			var alive := _side_alive(1)
			return {"text": "Détruire l'ennemi : %d structure(s)" % n, "frac": 0.0 if alive else 1.0}
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
		"protect_ally":
			var ok := _team_alive(2)
			return {"text": "Base alliée intacte" if ok else "Base alliée détruite", "frac": 1.0 if ok else 0.0}
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
		info["done"] = obj_state[i]["done"] and mission["objectives"][i]["type"] != "protect_ally"
		out.append(info)
	return out


func _spawn_produced_unit(id: String) -> void:
	spawn_for(id, 0)


## Fait apparaître une unité produite par un camp, devant son bâtiment de production.
func spawn_for(id: String, team: int) -> Unit:
	var from_id: String = GameData.def(id)["from"]
	return _spawn_unit(id, _find_free_cell(_dock_of(from_id, team)), team)


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
		var size: Vector2i = GameData.BUILDINGS[placing_id]["size"]
		var cell := _ghost_cell()
		var ok := _can_place(placing_id, cell)
		var col := Color(0.3, 1.0, 0.5, 0.35) if ok else Color(1.0, 0.25, 0.25, 0.35)
		for dx in size.x:
			for dy in size.y:
				var rect := Rect2(Vector2(cell + Vector2i(dx, dy)) * TILE, Vector2(TILE, TILE))
				draw_rect(rect, col)
				draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)
