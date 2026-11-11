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
		"air": ["libellule", "aigrette", "nacelle"],
	},
	"kharn": {
		"name": "Légion Kharn",
		"tagline": "Puissance brute",
		"desc": "Unités 5 % moins chères, minerai +10 %.\nBlindés lourds et lents, constructions standard.",
		"color": Color("e8433a"), "accent": Color("ffb199"),
		"build_time_mult": 1.0, "unit_cost_mult": 0.95, "spice_mult": 1.0, "ore_mult": 1.1,
		"units": ["belier", "brute", "salve"],
		"air": ["faucheur", "marteau", "mule"],
	},
	"vael": {
		"name": "Cartel Vael",
		"tagline": "Ruse et commerce",
		"desc": "Épice +20 % de Solaris par récolte.\nUnités rapides et fragiles, harcèlement.",
		"color": Color("3ddc97"), "accent": Color("ffe08a"),
		"build_time_mult": 1.0, "unit_cost_mult": 1.0, "spice_mult": 1.2, "ore_mult": 1.0,
		"units": ["faucon", "vipere", "mirage"],
		"air": ["guepe", "frelon", "pelican"],
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

# Vision par défaut (en cases) quand l'entrée n'a pas de "vision"
const DEFAULT_VISION := 7
const BUILDING_VISION := 7

# Rangs d'unité : nombre d'éliminations requis, bonus de dégâts et de PV par rang
const RANKS := [
	{"name": "Recrue", "kills": 0},
	{"name": "Vétéran", "kills": 3},
	{"name": "Élite", "kills": 8},
]
const RANK_DMG := 0.15
const RANK_HP := 0.15

# Niveaux de bâtiment : 1 à MAX_LEVEL. Coût du niveau suivant = coût de base * UPGRADE_COST * niveau.
const MAX_LEVEL := 3
const UPGRADE_COST := 0.6
const UPGRADES := {
	"chantier": "+2 places dans la file de construction, +25 % PV",
	"centrale": "+50 énergie, +25 % PV",
	"raffinerie": "+12 % de Solaris par récolte, +25 % PV",
	"fonderie": "+12 % de minerai par récolte, +25 % PV",
	"usine": "Débloque de nouvelles unités, +2 places en file, production +25 % plus rapide, +25 % PV",
	"tourelle": "+25 % de dégâts, +25 % PV",
}
# Modernisation d'une unité (une fois, à l'Usine niveau 2) : bonus propres à chaque type.
# Clés : hp/dps/speed/cap/rate = multiplicateurs, range/vision = cases en plus.
const UNIT_TECH := {
	"recolteur": {"cap": 1.3, "rate": 1.2, "speed": 1.1},
	"mineur": {"cap": 1.3, "rate": 1.2, "hp": 1.2},
	"sentinelle": {"speed": 1.25, "vision": 3, "hp": 1.15},
	"egide": {"hp": 1.3, "dps": 1.15},
	"resonateur": {"range": 2, "dps": 1.2},
	"belier": {"hp": 1.2, "dps": 1.25},
	"brute": {"hp": 1.35, "dps": 1.1},
	"salve": {"range": 2, "dps": 1.15, "vision": 2},
	"faucon": {"speed": 1.2, "dps": 1.25, "vision": 2},
	"vipere": {"dps": 1.3, "hp": 1.15},
	"mirage": {"range": 2, "hp": 1.25, "dps": 1.2},
	"libellule": {"speed": 1.2, "dps": 1.25}, "aigrette": {"range": 2, "dps": 1.2},
	"nacelle": {"hp": 1.3, "speed": 1.15}, "faucheur": {"hp": 1.2, "dps": 1.2},
	"marteau": {"hp": 1.25, "dps": 1.15}, "mule": {"hp": 1.3, "speed": 1.2},
	"guepe": {"speed": 1.15, "dps": 1.25}, "frelon": {"dps": 1.3, "hp": 1.15},
	"pelican": {"hp": 1.3, "speed": 1.15},
}
## Vitesse des véhicules : multiplicateur global (sol / air).
const SPEED_MULT := 0.62
const AIR_SPEED_MULT := 0.72
const CHANTIER_COST := 800 # base de calcul pour l'amélioration du Chantier

# Bâtiment de départ (non constructible par le joueur)
const START_BUILDING := {
	"name": "Chantier", "size": Vector2i(3, 3), "power": 0, "hp": 1500, "armor": "building", "vision": 9,
}

# Bâtiments : coût en MINERAI
const BUILDINGS := {
	"centrale": {
		"name": "Centrale", "cost": 250, "time": 8.4,
		"size": Vector2i(2, 2), "power": 100, "requires": [], "hp": 600, "armor": "building",
	},
	"raffinerie": {
		"name": "Raffinerie", "cost": 450, "time": 12.6,
		"size": Vector2i(3, 2), "power": -30, "requires": ["centrale"], "hp": 900, "armor": "building",
	},
	"fonderie": {
		"name": "Fonderie", "cost": 400, "time": 12.6,
		"size": Vector2i(3, 2), "power": -25, "requires": ["centrale"], "hp": 800, "armor": "building",
	},
	"usine": {
		"name": "Usine", "cost": 500, "time": 12.6,
		"size": Vector2i(3, 2), "power": -20, "requires": ["centrale"], "hp": 1000, "armor": "building",
	},
	"tourelle": {
		"name": "Tourelle", "cost": 350, "time": 11.2,
		"size": Vector2i(2, 2), "power": -15, "requires": ["usine"], "hp": 700, "armor": "building",
		"weapon": "cannon", "dps": 22, "range": 7, "vision": 9,
	},
	# --- Bâtiments débloqués par la campagne ("unlock" = mission à terminer avant) ---
	"mur": {
		"name": "Mur", "cost": 40, "time": 2.8, "size": Vector2i(1, 1), "power": 0, "requires": [],
		"hp": 450, "armor": "building", "vision": 3, "unlock": 1, "no_upgrade": true, "wall": true,
		"desc": "Barre le passage",
	},
	"silo": {
		"name": "Silo d'épice", "cost": 300, "time": 9.0, "size": Vector2i(2, 2), "power": -10,
		"requires": ["raffinerie"], "hp": 700, "armor": "building", "unlock": 1, "no_upgrade": true,
		"spice_bonus": 0.10, "desc": "+10 % de Solaris par récolte (3 silos max.)",
	},
	"radar": {
		"name": "Station radar", "cost": 450, "time": 11.0, "size": Vector2i(2, 2), "power": -30,
		"requires": ["centrale"], "hp": 600, "armor": "building", "vision": 17, "unlock": 2,
		"no_upgrade": true, "desc": "Vision très étendue",
	},
	"reparation": {
		"name": "Centre de réparation", "cost": 500, "time": 12.0, "size": Vector2i(3, 2), "power": -25,
		"requires": ["usine"], "hp": 800, "armor": "building", "unlock": 2, "no_upgrade": true,
		"heal": 18.0, "heal_range": 5.0, "desc": "Soigne les unités alliées proches",
	},
	"reacteur": {
		"name": "Réacteur", "cost": 700, "time": 12.0, "size": Vector2i(2, 2), "power": 260,
		"requires": ["centrale", "usine"], "hp": 700, "armor": "building", "unlock": 3,
		"no_upgrade": true, "desc": "Grosse production d'énergie",
	},
	"batterie": {
		"name": "Batterie de roquettes", "cost": 600, "time": 12.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "radar"], "hp": 750, "armor": "building", "unlock": 3, "no_upgrade": true,
		"weapon": "rocket", "dps": 40, "range": 11, "vision": 10, "desc": "Défense longue portée",
	},
	"aerodrome": {
		"name": "Aérodrome", "cost": 600, "time": 12.0, "size": Vector2i(3, 2), "power": -30,
		"requires": ["usine"], "hp": 800, "armor": "building", "unlock": 2, "no_upgrade": true,
		"desc": "Construit les unités volantes",
	},
	# --- Spécifiques à une faction ---
	"tour_sonique": {
		"name": "Tour sonique", "cost": 520, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 650, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "solis", "weapon": "sonic", "dps": 34, "range": 8, "vision": 9,
		"desc": "Onde de zone (Solis)",
	},
	"relais_solaire": {
		"name": "Relais solaire", "cost": 450, "time": 10.0, "size": Vector2i(2, 2), "power": 160,
		"requires": ["centrale"], "hp": 500, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "solis", "desc": "Énergie bon marché (Solis)",
	},
	"bunker": {
		"name": "Bunker", "cost": 650, "time": 12.0, "size": Vector2i(2, 2), "power": -15,
		"requires": ["usine"], "hp": 2000, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "kharn", "weapon": "cannon", "dps": 34, "range": 6, "vision": 9,
		"desc": "Fortin ultra-résistant (Kharn)",
	},
	"mur_acier": {
		"name": "Mur d'acier", "cost": 90, "time": 3.5, "size": Vector2i(1, 1), "power": 0, "requires": [],
		"hp": 1400, "armor": "building", "vision": 3, "unlock": 4, "no_upgrade": true, "wall": true,
		"faction": "kharn", "desc": "Mur renforcé (Kharn)",
	},
	"tour_acide": {
		"name": "Tour acide", "cost": 500, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 600, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "vael", "weapon": "acid", "dps": 38, "range": 7, "vision": 9,
		"desc": "Perce les blindages (Vael)",
	},
	"marche": {
		"name": "Marché noir", "cost": 550, "time": 12.0, "size": Vector2i(3, 2), "power": -20,
		"requires": ["raffinerie"], "hp": 700, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "vael", "income": 4.0, "desc": "+4 Solaris par seconde (Vael)",
	},
}

# Unités : coût en SOLARIS. role : harvester | miner | combat
# from = bâtiment où l'unité apparaît.
const UNITS := {
	# --- Engins spéciaux (non constructibles) ---
	"mcv": {
		"name": "Engin de chantier", "role": "mcv", "desc": "Se déploie en Chantier", "armor": "heavy",
		"cost": 0, "time": 1.0, "requires": [], "hp": 800, "speed": 52.0, "vision": 9,
	},
	"convoi": {
		"name": "Convoi d'épice", "role": "convoy", "desc": "Cargaison à escorter", "armor": "medium",
		"cost": 0, "time": 1.0, "requires": [], "hp": 480, "speed": 58.0, "vision": 8,
	},
	# --- Communes ---
	"recolteur": {
		"name": "Récolteur d'épice", "role": "harvester", "resource": "spice", "armor": "medium",
		"cost": 400, "time": 8.0, "requires": ["raffinerie"], "from": "raffinerie",
		"hp": 300, "speed": 70.0, "capacity": 200.0, "rate": 22.0,
	},
	"mineur": {
		"name": "Mineur", "role": "miner", "resource": "ore", "armor": "medium",
		"cost": 350, "time": 8.0, "requires": ["fonderie"], "from": "fonderie",
		"hp": 260, "speed": 80.0, "capacity": 160.0, "rate": 20.0,
	},
	# --- Unités volantes (Aérodrome) ---
	"libellule": {
		"name": "Libellule", "role": "combat", "desc": "Chasseur léger, touche l'air", "air": true,
		"armor": "light", "weapon": "autocannon",
		"cost": 380, "time": 7.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 160, "speed": 210.0, "vision": 12, "dps": 18, "range": 4,
	},
	"aigrette": {
		"name": "Aigrette", "role": "combat", "desc": "Bombardier sonique (zone)", "air": true,
		"armor": "light", "weapon": "sonic",
		"cost": 640, "time": 10.0, "level": 3, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 260, "speed": 150.0, "vision": 10, "dps": 38, "range": 6,
	},
	"nacelle": {
		"name": "Nacelle", "role": "transport", "desc": "Transport de 4 unités", "air": true,
		"armor": "medium",
		"cost": 520, "time": 9.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 320, "speed": 150.0, "vision": 9, "slots": 4,
	},
	"faucheur": {
		"name": "Faucheur", "role": "combat", "desc": "Hélicoptère à roquettes", "air": true,
		"armor": "medium", "weapon": "rocket",
		"cost": 560, "time": 9.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 340, "speed": 150.0, "vision": 10, "dps": 40, "range": 7,
	},
	"marteau": {
		"name": "Marteau", "role": "combat", "desc": "Bombardier lourd (sol)", "air": true,
		"armor": "heavy", "weapon": "cannon",
		"cost": 820, "time": 12.0, "level": 3, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 520, "speed": 110.0, "vision": 9, "dps": 46, "range": 5,
	},
	"mule": {
		"name": "Mule", "role": "transport", "desc": "Transport de 6 unités", "air": true,
		"armor": "heavy",
		"cost": 600, "time": 10.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 600, "speed": 100.0, "vision": 9, "slots": 6,
	},
	"guepe": {
		"name": "Guêpe", "role": "combat", "desc": "Chasseur ultra-rapide", "air": true,
		"armor": "light", "weapon": "autocannon",
		"cost": 330, "time": 6.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 140, "speed": 240.0, "vision": 13, "dps": 17, "range": 4,
	},
	"frelon": {
		"name": "Frelon", "role": "combat", "desc": "Bombardier acide (sol)", "air": true,
		"armor": "light", "weapon": "acid",
		"cost": 580, "time": 10.0, "level": 3, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 230, "speed": 175.0, "vision": 10, "dps": 44, "range": 5,
	},
	"pelican": {
		"name": "Pélican", "role": "transport", "desc": "Transport de 4 unités rapide", "air": true,
		"armor": "medium",
		"cost": 480, "time": 8.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 280, "speed": 190.0, "vision": 10, "slots": 4,
	},
	# --- Maison Solis ---
	"sentinelle": {
		"name": "Sentinelle", "role": "combat", "desc": "Éclaireur rapide",
		"armor": "light", "weapon": "autocannon",
		"cost": 220, "time": 5.0, "level": 1, "requires": ["usine"], "from": "usine",
		"hp": 190, "dps": 15, "speed": 160.0, "range": 5, "vision": 11,
	},
	"egide": {
		"name": "Égide", "role": "combat", "desc": "Char moyen polyvalent",
		"armor": "medium", "weapon": "cannon",
		"cost": 480, "time": 8.0, "level": 2, "requires": ["usine"], "from": "usine",
		"hp": 520, "dps": 27, "speed": 95.0, "range": 6,
	},
	"resonateur": {
		"name": "Résonateur", "role": "combat", "desc": "Artillerie sonique (zone, tir allié)",
		"armor": "light", "weapon": "sonic",
		"cost": 510, "time": 9.0, "level": 3, "requires": ["usine", "radar"], "from": "usine",
		"hp": 300, "dps": 40, "speed": 70.0, "range": 9, "vision": 9,
	},
	# --- Légion Kharn ---
	"belier": {
		"name": "Bélier", "role": "combat", "desc": "Buggy d'assaut bon marché",
		"armor": "light", "weapon": "autocannon",
		"cost": 290, "time": 6.0, "level": 1, "requires": ["usine"], "from": "usine",
		"hp": 230, "dps": 17, "speed": 120.0, "range": 3,
	},
	"brute": {
		"name": "Brute", "role": "combat", "desc": "Char lourd",
		"armor": "heavy", "weapon": "cannon",
		"cost": 760, "time": 11.0, "level": 3, "requires": ["usine", "fonderie"], "from": "usine",
		"hp": 950, "dps": 36, "speed": 65.0, "range": 6,
	},
	"salve": {
		"name": "Salve", "role": "combat", "desc": "Lance-roquettes longue portée",
		"armor": "light", "weapon": "rocket",
		"cost": 540, "time": 9.0, "level": 2, "requires": ["usine", "radar"], "from": "usine",
		"hp": 260, "dps": 46, "speed": 80.0, "range": 11, "vision": 9,
	},
	# --- Cartel Vael ---
	"faucon": {
		"name": "Faucon", "role": "combat", "desc": "Raider ultra-rapide",
		"armor": "light", "weapon": "autocannon",
		"cost": 170, "time": 4.0, "level": 1, "requires": ["usine"], "from": "usine",
		"hp": 170, "dps": 17, "speed": 200.0, "range": 4, "vision": 11,
	},
	"vipere": {
		"name": "Vipère", "role": "combat", "desc": "Char antiblindage (acide)",
		"armor": "medium", "weapon": "acid",
		"cost": 460, "time": 8.0, "level": 2, "requires": ["usine"], "from": "usine",
		"hp": 420, "dps": 41, "speed": 105.0, "range": 6,
	},
	"mirage": {
		"name": "Mirage", "role": "combat", "desc": "Prend le contrôle d'un char ennemi",
		"armor": "light", "weapon": "control",
		"cost": 430, "time": 9.0, "level": 3, "requires": ["usine", "radar"], "from": "usine",
		"hp": 300, "dps": 32, "speed": 85.0, "range": 6,
	},
}


## Coût de base pour calculer l'amélioration d'un bâtiment.
static func base_cost(id: String) -> int:
	if id == "chantier":
		return CHANTIER_COST
	return int(BUILDINGS[id]["cost"])


static func def(id: String) -> Dictionary:
	if BUILDINGS.has(id):
		return BUILDINGS[id]
	if UNITS.has(id):
		return UNITS[id]
	return START_BUILDING


## Multiplicateur de dégâts d'une arme contre un type de blindage.
## Les armes qui peuvent toucher une unité volante.
static func hits_air(weapon: String) -> bool:
	return weapon == "autocannon" or weapon == "rocket" or weapon == "sonic"


static func mult(weapon: String, armor: String) -> float:
	var row: Dictionary = MULT.get(weapon, {})
	return float(row.get(armor, 1.0))


## Coût en Solaris d'un bâtiment (en plus du minerai) ; 0 pour une unité.
static func sol_cost(id: String) -> int:
	if UNITS.has(id) or not BUILDINGS.has(id):
		return 0
	return int(round(float(BUILDINGS[id]["cost"]) * 0.5 / 5.0)) * 5


static func tech_cost(id: String) -> int:
	return int(round(float(UNITS[id]["cost"]) * 0.7))


static func tech_time(id: String) -> float:
	return 10.0 + float(UNITS[id]["cost"]) / 45.0


## Texte des bonus de modernisation d'une unité.
static func tech_text(id: String) -> String:
	var t: Dictionary = UNIT_TECH.get(id, {})
	var parts: PackedStringArray = []
	var labels := {"hp": "PV", "dps": "dégâts", "speed": "vitesse", "cap": "capacité", "rate": "rendement"}
	for k in ["hp", "dps", "speed", "cap", "rate"]:
		if t.has(k):
			parts.append("+%d %% %s" % [int(round((float(t[k]) - 1.0) * 100.0)), labels[k]])
	if t.has("range"):
		parts.append("+%d portée" % int(t["range"]))
	if t.has("vision"):
		parts.append("+%d vision" % int(t["vision"]))
	return ", ".join(parts)


## Bâtiments constructibles par une faction (communs + propres), débloqués ou non.
static func buildings_for(faction: String) -> Array:
	var out: Array = []
	for id in BUILDINGS.keys():
		var f: String = BUILDINGS[id].get("faction", "")
		if f == "" or f == faction:
			out.append(id)
	return out


## Unités constructibles par une faction : communes + propres.
static func units_for(faction: String) -> Array:
	var out: Array = ["recolteur", "mineur"]
	out.append_array(FACTIONS[faction]["units"])
	out.append_array(FACTIONS[faction]["air"])
	return out
