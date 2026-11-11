class_name GameData
## Données de jeu : factions, bâtiments, unités, armes et palette de l'interface.
##
## Équilibrage : le coût des unités de combat suit une « valeur de combat »
##   P = sqrt(PV * DPS) * (1 + 0,15 * (vitesse-100)/100) * (1 + 0,03 * (portée-5)) * bonus
##   coût ≈ P * 4,2
## ce qui donne le même rapport coût / puissance dans les trois factions.
## Les armes ont des avantages / désavantages selon le blindage (voir MULT).

const CREAM := Color("f3dcb4")
const AMBER := Color("e0a040")
const RED := Color("ff6b5a")
const GOLD := Color("ffd45c")
const ORE_BLUE := Color("8fb2e8")
# Couleurs néon : composantes > 1 = elles « bloomment » avec le glow HDR
const CYAN := Color(0.0, 1.5, 1.9)
const MAGENTA := Color(1.9, 0.25, 1.2)
const GREEN := Color(0.3, 1.8, 0.7)
const AMBER_HDR := Color(1.9, 1.3, 0.3)

const FACTIONS := {
	"solis": {
		"name": "Maison Solis",
		"tagline": "Technologie et polyvalence",
		"desc": "Constructions 20 % plus rapides.\nUnités précises et mobiles, mais peu blindées.",
		"color": Color("4aa8ff"), "accent": Color("bfe3ff"),
		"build_time_mult": 0.8, "unit_cost_mult": 1.0, "spice_mult": 1.0, "ore_mult": 1.0,
		"units": ["sentinelle", "egide", "resonateur"],
	},
	"kharn": {
		"name": "Légion Kharn",
		"tagline": "Puissance brute",
		"desc": "Unités 10 % moins chères, minerai +10 %.\nBlindés lourds et lents, constructions standard.",
		"color": Color("e8433a"), "accent": Color("ffb199"),
		"build_time_mult": 1.0, "unit_cost_mult": 0.9, "spice_mult": 1.0, "ore_mult": 1.1,
		"units": ["belier", "brute", "salve"],
	},
	"vael": {
		"name": "Cartel Vael",
		"tagline": "Ruse et commerce",
		"desc": "Épice +20 % de Solaris par récolte.\nUnités rapides et fragiles, harcèlement.",
		"color": Color("3ddc97"), "accent": Color("ffe08a"),
		"build_time_mult": 1.0, "unit_cost_mult": 1.0, "spice_mult": 1.2, "ore_mult": 1.0,
		"units": ["faucon", "vipere", "mirage"],
	},
}

# Armes : cd = cadence (s), splash = rayon des dégâts de zone (px)
const WEAPONS := {
	"autocannon": {"cd": 0.35, "speed": 900.0, "color": Color(2.0, 1.7, 0.6), "splash": 0.0, "len": 10.0},
	"cannon": {"cd": 1.1, "speed": 650.0, "color": Color(2.0, 1.2, 0.4), "splash": 0.0, "len": 14.0},
	"rocket": {"cd": 2.0, "speed": 420.0, "color": Color(2.0, 0.7, 0.3), "splash": 56.0, "len": 18.0},
	"sonic": {"cd": 1.6, "speed": 500.0, "color": Color(0.6, 1.6, 2.2), "splash": 64.0, "len": 12.0},
	"acid": {"cd": 1.2, "speed": 560.0, "color": Color(0.5, 2.0, 0.6), "splash": 0.0, "len": 12.0},
	"control": {"cd": 1.4, "speed": 700.0, "color": Color(1.8, 0.5, 2.0), "splash": 0.0, "len": 12.0},
}

# Multiplicateur de dégâts : arme -> blindage
const MULT := {
	"autocannon": {"light": 1.3, "medium": 1.0, "heavy": 0.6, "building": 0.5},
	"cannon": {"light": 1.0, "medium": 1.0, "heavy": 1.0, "building": 1.0},
	"rocket": {"light": 0.8, "medium": 1.1, "heavy": 1.3, "building": 1.2},
	"sonic": {"light": 1.1, "medium": 1.0, "heavy": 0.9, "building": 0.7},
	"acid": {"light": 0.8, "medium": 1.2, "heavy": 1.4, "building": 0.9},
	"control": {"light": 1.0, "medium": 1.0, "heavy": 1.0, "building": 1.0},
}

# Bâtiment de départ (non constructible par le joueur)
const START_BUILDING := {
	"name": "Chantier", "size": Vector2i(3, 3), "power": 0, "hp": 1500, "armor": "building",
}

# Bâtiments : coût en MINERAI
const BUILDINGS := {
	"centrale": {
		"name": "Centrale", "cost": 250, "time": 6.0,
		"size": Vector2i(2, 2), "power": 100, "requires": [], "hp": 600, "armor": "building",
	},
	"raffinerie": {
		"name": "Raffinerie", "cost": 450, "time": 9.0,
		"size": Vector2i(3, 2), "power": -30, "requires": ["centrale"], "hp": 900, "armor": "building",
	},
	"fonderie": {
		"name": "Fonderie", "cost": 400, "time": 9.0,
		"size": Vector2i(3, 2), "power": -25, "requires": ["centrale"], "hp": 800, "armor": "building",
	},
	"usine": {
		"name": "Usine", "cost": 500, "time": 9.0,
		"size": Vector2i(3, 2), "power": -20, "requires": ["centrale"], "hp": 1000, "armor": "building",
	},
	"tourelle": {
		"name": "Tourelle", "cost": 350, "time": 8.0,
		"size": Vector2i(2, 2), "power": -15, "requires": ["usine"], "hp": 700, "armor": "building",
		"weapon": "cannon", "dps": 22, "range": 7,
	},
}

# Unités : coût en SOLARIS. role : harvester | miner | combat
# from = bâtiment où l'unité apparaît.
const UNITS := {
	# --- Communes ---
	"recolteur": {
		"name": "Récolteur d'épice", "role": "harvester", "resource": "spice", "armor": "medium",
		"cost": 400, "time": 8.0, "requires": ["raffinerie"], "from": "raffinerie",
		"hp": 300, "speed": 70.0, "capacity": 500.0, "rate": 120.0,
	},
	"mineur": {
		"name": "Mineur", "role": "miner", "resource": "ore", "armor": "medium",
		"cost": 350, "time": 8.0, "requires": ["fonderie"], "from": "fonderie",
		"hp": 260, "speed": 80.0, "capacity": 400.0, "rate": 100.0,
	},
	# --- Maison Solis ---
	"sentinelle": {
		"name": "Sentinelle", "role": "combat", "desc": "Éclaireur rapide",
		"armor": "light", "weapon": "autocannon",
		"cost": 220, "time": 5.0, "requires": ["usine"], "from": "usine",
		"hp": 160, "dps": 14, "speed": 160.0, "range": 5,
	},
	"egide": {
		"name": "Égide", "role": "combat", "desc": "Char moyen polyvalent",
		"armor": "medium", "weapon": "cannon",
		"cost": 480, "time": 8.0, "requires": ["usine"], "from": "usine",
		"hp": 520, "dps": 24, "speed": 95.0, "range": 6,
	},
	"resonateur": {
		"name": "Résonateur", "role": "combat", "desc": "Artillerie sonique (zone, tir allié)",
		"armor": "light", "weapon": "sonic",
		"cost": 510, "time": 9.0, "requires": ["usine"], "from": "usine",
		"hp": 300, "dps": 40, "speed": 70.0, "range": 9,
	},
	# --- Légion Kharn ---
	"belier": {
		"name": "Bélier", "role": "combat", "desc": "Buggy d'assaut bon marché",
		"armor": "light", "weapon": "autocannon",
		"cost": 290, "time": 6.0, "requires": ["usine"], "from": "usine",
		"hp": 280, "dps": 18, "speed": 120.0, "range": 3,
	},
	"brute": {
		"name": "Brute", "role": "combat", "desc": "Char lourd",
		"armor": "heavy", "weapon": "cannon",
		"cost": 760, "time": 11.0, "requires": ["usine"], "from": "usine",
		"hp": 950, "dps": 36, "speed": 65.0, "range": 6,
	},
	"salve": {
		"name": "Salve", "role": "combat", "desc": "Lance-roquettes longue portée",
		"armor": "light", "weapon": "rocket",
		"cost": 540, "time": 9.0, "requires": ["usine"], "from": "usine",
		"hp": 280, "dps": 55, "speed": 80.0, "range": 11,
	},
	# --- Cartel Vael ---
	"faucon": {
		"name": "Faucon", "role": "combat", "desc": "Raider ultra-rapide",
		"armor": "light", "weapon": "autocannon",
		"cost": 190, "time": 4.0, "requires": ["usine"], "from": "usine",
		"hp": 130, "dps": 12, "speed": 200.0, "range": 4,
	},
	"vipere": {
		"name": "Vipère", "role": "combat", "desc": "Char antiblindage (acide)",
		"armor": "medium", "weapon": "acid",
		"cost": 510, "time": 8.0, "requires": ["usine"], "from": "usine",
		"hp": 400, "dps": 34, "speed": 105.0, "range": 6,
	},
	"mirage": {
		"name": "Mirage", "role": "combat", "desc": "Prend le contrôle d'un char ennemi",
		"armor": "light", "weapon": "control",
		"cost": 480, "time": 9.0, "requires": ["usine"], "from": "usine",
		"hp": 260, "dps": 22, "speed": 85.0, "range": 6,
	},
}


static func def(id: String) -> Dictionary:
	if BUILDINGS.has(id):
		return BUILDINGS[id]
	if UNITS.has(id):
		return UNITS[id]
	return START_BUILDING


## Multiplicateur de dégâts d'une arme contre un type de blindage.
static func mult(weapon: String, armor: String) -> float:
	var row: Dictionary = MULT.get(weapon, {})
	return float(row.get(armor, 1.0))


## Unités constructibles par une faction : communes + propres.
static func units_for(faction: String) -> Array:
	var out: Array = ["recolteur", "mineur"]
	out.append_array(FACTIONS[faction]["units"])
	return out
