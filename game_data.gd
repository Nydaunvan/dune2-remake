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
		"units": ["sentinelle", "egide", "resonateur", "pisteur", "brise_mur", "citadelle", "technicien", "cirrus", "diapason"],
		"air": ["libellule", "aigrette", "nacelle", "eclair", "foudre", "orage", "vigie"],
	},
	"kharn": {
		"name": "Légion Kharn",
		"tagline": "Puissance brute",
		"desc": "Unités 5 % moins chères, minerai +10 %.\nBlindés lourds et lents, constructions standard.",
		"color": Color("e8433a"), "accent": Color("ffb199"),
		"build_time_mult": 1.0, "unit_cost_mult": 0.95, "spice_mult": 1.0, "ore_mult": 1.1,
		"units": ["belier", "brute", "salve", "rodeur", "demolisseur", "titan", "brasier", "obusier", "depanneuse"],
		"air": ["faucheur", "marteau", "mule", "vautour", "aigle", "forteresse_vol", "cyclone"],
	},
	"vael": {
		"name": "Cartel Vael",
		"tagline": "Ruse et commerce",
		"desc": "Épice +20 % de Solaris par récolte.\nUnités rapides et fragiles, harcèlement.",
		"color": Color("3ddc97"), "accent": Color("ffe08a"),
		"build_time_mult": 1.0, "unit_cost_mult": 1.0, "spice_mult": 1.2, "ore_mult": 1.0,
		"units": ["faucon", "vipere", "mirage", "rat_sable", "saboteur", "scorpion", "guerisseur", "harpon", "cracheur"],
		"air": ["guepe", "frelon", "pelican", "cigale", "milan", "mante", "cobra"],
	},
	"conclave": {
		"name": "Conclave Obsidien",
		"tagline": "Cristal et résilience",
		"desc": "Minerai +20 %, unités qui se régénèrent.\nÉclats cristallins en zone, constructions un peu plus lentes.",
		"color": Color("b277ff"), "accent": Color("ead6ff"),
		"build_time_mult": 1.1, "unit_cost_mult": 1.0, "spice_mult": 1.0, "ore_mult": 1.2, "regen": 2.0,
		"units": ["ombre", "prisme", "obelisque", "tesson", "fracasseur", "monolithe", "veilleur", "aiguille", "quartz"],
		"air": ["vesper", "eclipse", "passeur", "ephemere", "scintille", "stalactite", "aurore"],
	},
}

# Armes : cd = cadence (s), splash = rayon des dégâts de zone (px)
const WEAPONS := {
	"autocannon": {"cd": 0.35, "speed": 900.0, "color": Color(1.4, 1.2, 0.5), "splash": 0.0, "len": 10.0},
	"cannon": {"cd": 1.1, "speed": 650.0, "color": Color(1.4, 0.9, 0.35), "splash": 0.0, "len": 14.0},
	"rocket": {"cd": 2.0, "speed": 420.0, "color": Color(1.4, 0.55, 0.28), "splash": 56.0, "len": 18.0},
	"sonic": {"cd": 1.6, "speed": 500.0, "color": Color(0.5, 1.2, 1.6), "splash": 64.0, "len": 12.0},
	"acid": {"cd": 1.2, "speed": 560.0, "color": Color(0.4, 1.4, 0.5), "splash": 0.0, "len": 12.0},
	"control": {"cd": 1.4, "speed": 700.0, "color": Color(1.3, 0.4, 1.5), "splash": 0.0, "len": 12.0},
	"shard": {"cd": 0.9, "speed": 780.0, "color": Color(1.1, 0.55, 1.8), "splash": 30.0, "len": 13.0},
	# Armes génériques des nouvelles unités (son emprunté à "snd")
	"mortar": {"cd": 2.4, "speed": 380.0, "color": Color(1.5, 0.7, 0.3), "splash": 70.0, "len": 16.0, "snd": "rocket"},
	"flame": {"cd": 0.22, "speed": 520.0, "color": Color(1.8, 0.8, 0.2), "splash": 0.0, "len": 12.0, "snd": "autocannon"},
	"plasma": {"cd": 1.8, "speed": 460.0, "color": Color(0.5, 1.4, 1.9), "splash": 46.0, "len": 12.0, "snd": "sonic"},
	"orbital": {"cd": 9.0, "speed": 1100.0, "color": Color(1.9, 1.5, 0.6), "splash": 100.0, "len": 40.0, "snd": "boom_big"},
	"laser": {"cd": 0.7, "speed": 1300.0, "color": Color(1.9, 0.4, 0.4), "splash": 0.0, "len": 26.0, "snd": "autocannon"},
}

# Multiplicateur de dégâts : arme -> blindage
const MULT := {
	"autocannon": {"light": 1.3, "medium": 1.0, "heavy": 0.6, "building": 0.5},
	"cannon": {"light": 1.0, "medium": 1.0, "heavy": 1.0, "building": 1.0},
	"rocket": {"light": 0.8, "medium": 1.1, "heavy": 1.3, "building": 1.2},
	"sonic": {"light": 1.1, "medium": 1.0, "heavy": 0.9, "building": 0.7},
	"acid": {"light": 0.8, "medium": 1.2, "heavy": 1.4, "building": 0.9},
	"control": {"light": 1.0, "medium": 1.0, "heavy": 1.0, "building": 1.0},
	"shard": {"light": 1.2, "medium": 1.0, "heavy": 0.9, "building": 0.8},
	"mortar": {"light": 1.0, "medium": 1.0, "heavy": 0.9, "building": 1.3},
	"flame": {"light": 1.5, "medium": 1.0, "heavy": 0.5, "building": 0.6},
	"plasma": {"light": 1.0, "medium": 1.1, "heavy": 1.2, "building": 1.0},
	"laser": {"light": 0.9, "medium": 1.0, "heavy": 1.3, "building": 0.7},
	"orbital": {"light": 1.0, "medium": 1.0, "heavy": 1.0, "building": 0.8},
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
# Solidité des bâtiments : PV de base x BUILD_HP_MULT x "tough" ; +LEVEL_HP par niveau.
const BUILD_HP_MULT := 1.5
const LEVEL_HP := 0.4
# Dégâts concentrés amortis : au-delà de SOAK_FRAC * PV max par seconde, les dégâts reçus
# sont réduits (taux effectif = seuil * (taux/seuil)^SOAK_EXP). Une grosse armée ne rase plus un bâtiment en un instant.
const SOAK_FRAC := 0.025
const SOAK_EXP := 0.65


## Noms propres à chaque faction pour les bâtiments et engins communs (mêmes règles, autre identité).
const FACTION_NAMES := {
	"chantier": {"solis": "Atelier de conception", "kharn": "Forteresse de commandement", "vael": "Camp de base", "conclave": "Noyau cristallin"},
	"centrale": {"solis": "Centrale solaire", "kharn": "Chaudière de guerre", "vael": "Dynamo du désert", "conclave": "Cuve d'énergie vive"},
	"raffinerie": {"solis": "Raffinerie solaire", "kharn": "Raffinerie lourde", "vael": "Comptoir de raffinage", "conclave": "Alambic de cristal"},
	"fonderie": {"solis": "Fonderie de précision", "kharn": "Haut fourneau", "vael": "Forge nomade", "conclave": "Creuset d'obsidienne"},
	"usine": {"solis": "Usine d'assemblage", "kharn": "Arsenal", "vael": "Atelier ambulant", "conclave": "Matrice de cristal"},
	"tourelle": {"solis": "Tourelle de garde", "kharn": "Casemate", "vael": "Poste d'embuscade", "conclave": "Sentinelle de cristal"},
	"mur": {"solis": "Mur de plastacier", "kharn": "Mur de béton", "vael": "Mur de sable", "conclave": "Mur de pierre noire"},
	"silo": {"solis": "Réservoir d'épice", "kharn": "Silo blindé", "vael": "Entrepôt d'épice", "conclave": "Urne d'épice"},
	"silo_minerai": {"solis": "Réservoir de minerai", "kharn": "Soute à minerai", "vael": "Entrepôt de minerai", "conclave": "Géode de stockage"},
	"radar": {"solis": "Centre de veille", "kharn": "Poste d'écoute", "vael": "Vigie nomade", "conclave": "Œil de cristal"},
	"reparation": {"solis": "Baie de réparation", "kharn": "Garage de campagne", "vael": "Rebouteux", "conclave": "Bassin de régénération"},
	"reacteur": {"solis": "Réacteur solaire", "kharn": "Réacteur lourd", "vael": "Réacteur de contrebande", "conclave": "Cœur de cristal"},
	"batterie": {"solis": "Rampe de roquettes", "kharn": "Batterie de roquettes", "vael": "Salve du désert", "conclave": "Batterie d'éclats"},
	"aerodrome": {"solis": "Aérodrome", "kharn": "Piste de guerre", "vael": "Piste de fortune", "conclave": "Plateforme d'envol"},
	"recolteur": {"solis": "Moissonneuse", "kharn": "Récolteur blindé", "vael": "Pilleur d'épice", "conclave": "Collecteur flottant"},
	"mineur": {"solis": "Foreuse", "kharn": "Mineur lourd", "vael": "Fouilleur", "conclave": "Foreur de cristal"},
	"mcv": {"solis": "Engin de déploiement", "kharn": "Engin de siège", "vael": "Chariot de camp", "conclave": "Germe de base"},
	"convoi": {"solis": "Convoi d'épice", "kharn": "Convoi blindé", "vael": "Caravane d'épice", "conclave": "Convoi flottant"},
}


## Nom affiché d'un bâtiment ou d'une unité pour une faction donnée.
static func name_of(id: String, faction: String) -> String:
	if FACTION_NAMES.has(id) and FACTION_NAMES[id].has(faction):
		return FACTION_NAMES[id][faction]
	if BUILDINGS.has(id):
		return BUILDINGS[id]["name"]
	if UNITS.has(id):
		return UNITS[id]["name"]
	return id


## Nom affiché pour la faction jouée (contexte du joueur : messages, info-bulles).
static func dname(id: String) -> String:
	return name_of(id, GameSession.faction)


## Teinte d'un mur (dessiné à plat par Building, icône de l'interface).
static func wall_color(id: String, faction := "") -> Color:
	if id == "mur":
		match faction:
			"solis": return Color(0.6, 0.65, 0.74)
			"kharn": return Color(0.4, 0.4, 0.42)
			"vael": return Color(0.72, 0.6, 0.4)
			"conclave": return Color(0.24, 0.19, 0.34)
	match id:
		"mur_acier": return Color(0.5, 0.52, 0.6)
		"mur_cristal": return Color(0.5, 0.34, 0.78)
		"mur_titane": return Color(0.38, 0.42, 0.5)
		"mur_epines": return Color(0.36, 0.5, 0.3)
		"mur_obsidienne": return Color(0.26, 0.2, 0.42)
	return Color(0.47, 0.4, 0.34)


static func building_hp(id: String) -> float:
	var d := def(id)
	return float(d.get("hp", 500)) * BUILD_HP_MULT * float(d.get("tough", 1.0))
const UPGRADE_COST := 0.6
## Consommation d'énergie ajoutée à chaque niveau (bâtiments consommateurs améliorables).
static func upgrade_power(id: String) -> int:
	if id == "chantier":
		return 10
	var p := int(def(id).get("power", 0))
	if p >= 0:
		return 0
	return maxi(5, int(ceil(-p * 0.3 / 5.0)) * 5)


## Énergie d'un bâtiment à un niveau donné (positif : produit, négatif : consomme).
static func power_at(id: String, level: int) -> int:
	var base: int = int(def(id).get("power", 0))
	if id == "centrale":
		return base + 50 * (level - 1)
	if base > 0:
		return base
	return base - upgrade_power(id) * (level - 1)


const UPGRADES := {
	"chantier": "+2 places dans la file de construction, +40 % PV",
	"centrale": "+50 énergie, +40 % PV",
	"raffinerie": "+12 % de Solaris par récolte, +40 % PV",
	"fonderie": "+12 % de minerai par récolte, +40 % PV",
	"usine": "Débloque de nouvelles unités, +2 places en file, production +25 % plus rapide, +40 % PV",
	"tourelle": "+25 % de dégâts, +40 % PV",
	"radar": "+3 cases de vision et de détection, +40 % PV",
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
	"ombre": {"speed": 1.2, "vision": 3, "hp": 1.2}, "prisme": {"hp": 1.25, "dps": 1.2},
	"obelisque": {"range": 2, "dps": 1.2, "hp": 1.15},
	"vesper": {"speed": 1.15, "dps": 1.25}, "eclipse": {"dps": 1.25, "hp": 1.2},
	"passeur": {"hp": 1.3, "speed": 1.15},
	"pisteur": {"speed": 1.2, "vision": 3},
	"brise_mur": {"hp": 1.2, "dps": 1.25},
	"citadelle": {"hp": 1.3, "dps": 1.15},
	"technicien": {"hp": 1.3, "speed": 1.2},
	"cirrus": {"range": 2, "dps": 1.2},
	"diapason": {"range": 2, "dps": 1.2},
	"eclair": {"speed": 1.15, "dps": 1.25},
	"foudre": {"hp": 1.2, "dps": 1.2},
	"orage": {"dps": 1.25, "hp": 1.2},
	"vigie": {"speed": 1.2, "vision": 3},
	"rodeur": {"speed": 1.2, "dps": 1.25},
	"demolisseur": {"hp": 1.25, "dps": 1.2},
	"titan": {"hp": 1.3, "dps": 1.15},
	"brasier": {"dps": 1.3, "hp": 1.15},
	"obusier": {"range": 2, "dps": 1.2},
	"depanneuse": {"hp": 1.3, "speed": 1.2},
	"vautour": {"dps": 1.25, "hp": 1.2},
	"aigle": {"speed": 1.15, "dps": 1.25},
	"forteresse_vol": {"hp": 1.25, "dps": 1.15},
	"cyclone": {"hp": 1.2, "dps": 1.2},
	"rat_sable": {"speed": 1.2, "dps": 1.25},
	"saboteur": {"hp": 1.2, "dps": 1.25},
	"scorpion": {"hp": 1.2, "dps": 1.25},
	"guerisseur": {"hp": 1.3, "speed": 1.2},
	"harpon": {"range": 2, "dps": 1.2},
	"cracheur": {"range": 2, "dps": 1.2},
	"cigale": {"speed": 1.2, "vision": 3},
	"milan": {"speed": 1.15, "dps": 1.25},
	"mante": {"dps": 1.25, "hp": 1.2},
	"cobra": {"hp": 1.25, "dps": 1.2},
	"tesson": {"speed": 1.2, "dps": 1.25},
	"fracasseur": {"hp": 1.25, "dps": 1.2},
	"monolithe": {"hp": 1.3, "dps": 1.15},
	"veilleur": {"hp": 1.3, "speed": 1.2},
	"aiguille": {"range": 2, "dps": 1.2},
	"quartz": {"range": 2, "dps": 1.2},
	"ephemere": {"speed": 1.2, "vision": 3},
	"scintille": {"speed": 1.15, "dps": 1.25},
	"stalactite": {"hp": 1.25, "dps": 1.2},
	"aurore": {"hp": 1.2, "dps": 1.2},
}
## Stockage : capacité de base, puis bonus par bâtiment [Solaris, minerai].
const STORAGE_BASE := 3000
const STORAGE := {"raffinerie": [1500, 0], "fonderie": [0, 1500], "silo": [2000, 0], "silo_minerai": [0, 2000]}

## Vitesse des véhicules : multiplicateur global (sol / air).
const SPEED_MULT := 0.62
const AIR_SPEED_MULT := 0.72
const CHANTIER_COST := 800 # base de calcul pour l'amélioration du Chantier

# Bâtiment de départ (non constructible par le joueur)
const START_BUILDING := {
	"name": "Chantier", "size": Vector2i(3, 3), "power": 0, "hp": 1500, "tough": 1.4, "armor": "building", "vision": 9,
}

# Bâtiments : coût en MINERAI
const BUILDINGS := {
	"centrale": {
		"name": "Centrale", "cost": 250, "time": 8.4,
		"size": Vector2i(2, 2), "power": 100, "requires": [], "hp": 600, "armor": "building",
	},
	"raffinerie": {
		"name": "Raffinerie", "cost": 450, "time": 12.6,
		"size": Vector2i(3, 2), "power": -30, "requires": ["centrale"], "hp": 900, "tough": 1.2, "armor": "building",
	},
	"fonderie": {
		"name": "Fonderie", "cost": 400, "time": 12.6,
		"size": Vector2i(3, 2), "power": -25, "requires": ["centrale"], "hp": 800, "tough": 1.2, "armor": "building",
	},
	"usine": {
		"name": "Usine", "cost": 500, "time": 12.6,
		"size": Vector2i(3, 2), "power": -20, "requires": ["centrale"], "hp": 1000, "tough": 1.2, "armor": "building",
	},
	"tourelle": {
		"name": "Tourelle", "cost": 350, "time": 11.2,
		"size": Vector2i(2, 2), "power": -15, "requires": ["usine"], "hp": 700, "armor": "building",
		"weapon": "cannon", "dps": 22, "range": 7, "vision": 9,
		"aa": true,
		"vs_air": 0.8,
		"max": 8,
	},
	# --- Bâtiments débloqués par la campagne ("unlock" = mission à terminer avant) ---
	"mur": {
		"name": "Mur", "cost": 40, "time": 2.8, "size": Vector2i(1, 1), "power": 0, "requires": [],
		"hp": 450, "tough": 1.5, "armor": "building", "vision": 3, "unlock": 1, "no_upgrade": true, "wall": true,
		"desc": "Barre le passage",
	},
	"silo": {
		"name": "Silo d'épice", "cost": 300, "time": 9.0, "size": Vector2i(2, 2), "power": -10,
		"requires": ["raffinerie"], "hp": 700, "armor": "building", "unlock": 1, "no_upgrade": true,
		"spice_bonus": 0.10, "desc": "+2000 de stockage de Solaris, +10 % de Solaris par récolte (3 silos max.)",
		"max": 3,
	},
	"silo_minerai": {
		"name": "Silo de minerai", "cost": 300, "time": 9.0, "size": Vector2i(2, 2), "power": -10,
		"requires": ["fonderie"], "hp": 700, "armor": "building", "unlock": 1, "no_upgrade": true,
		"ore_bonus": 0.10, "desc": "+2000 de stockage de minerai, +10 % de minerai par récolte (3 silos max.)",
		"max": 3,
	},
	"radar": {
		"name": "Station radar", "cost": 450, "time": 11.0, "size": Vector2i(2, 2), "power": -30,
		"requires": ["centrale"], "hp": 600, "armor": "building", "vision": 20, "unlock": 2,
		"desc": "Vision étendue : repère les ennemis de loin (+3 cases par niveau)",
		"max": 2,
	},
	"reparation": {
		"name": "Centre de réparation", "cost": 500, "time": 12.0, "size": Vector2i(3, 2), "power": -25,
		"requires": ["usine"], "hp": 800, "armor": "building", "unlock": 2, "no_upgrade": true,
		"heal": 18.0, "heal_range": 5.0, "desc": "Soigne les unités alliées proches",
		"req_level": {"usine": 2}, "max": 2,
	},
	"reacteur": {
		"name": "Réacteur", "cost": 700, "time": 12.0, "size": Vector2i(2, 2), "power": 260,
		"requires": ["centrale", "usine"], "hp": 700, "tough": 1.5, "armor": "building", "unlock": 3,
		"no_upgrade": true, "desc": "Grosse production d'énergie",
		"req_level": {"centrale": 2, "usine": 2}, "max": 2,
	},
	"batterie": {
		"aa": true, "name": "Batterie de roquettes", "cost": 600, "time": 12.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "radar"], "hp": 750, "armor": "building", "unlock": 3, "no_upgrade": true,
		"weapon": "rocket", "dps": 38, "range": 11, "vision": 10, "desc": "Défense longue portée",
		"vs_air": 1.2,
		"req_level": {"usine": 2}, "max": 4,
	},
	"aerodrome": {
		"name": "Aérodrome", "cost": 600, "time": 12.0, "size": Vector2i(3, 2), "power": -30,
		"requires": ["usine"], "hp": 800, "armor": "building", "unlock": 2, "no_upgrade": true,
		"desc": "Construit les unités volantes",
		"req_level": {"usine": 2}, "max": 2,
	},
	# --- Spécifiques à une faction ---
	"tour_sonique": {
		"name": "Tour sonique", "cost": 520, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 650, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "solis", "aa": true, "vs_air": 0.8,
		"weapon": "sonic", "dps": 34, "range": 8, "vision": 9,
		"desc": "Onde de zone (Solis)",
		"req_level": {"usine": 2}, "max": 6,
	},
	"relais_solaire": {
		"name": "Relais solaire", "cost": 450, "time": 10.0, "size": Vector2i(2, 2), "power": 160,
		"requires": ["centrale"], "hp": 500, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "solis", "desc": "Énergie bon marché (Solis)",
		"req_level": {"centrale": 2}, "max": 3,
	},
	"bunker": {
		"name": "Bunker", "cost": 650, "time": 12.0, "size": Vector2i(2, 2), "power": -15,
		"requires": ["usine"], "hp": 2000, "tough": 2.0, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "kharn", "aa": true, "vs_air": 0.8,
		"weapon": "cannon", "dps": 34, "range": 6, "vision": 9,
		"desc": "Fortin ultra-résistant (Kharn)",
		"req_level": {"usine": 2}, "max": 5,
	},
	"mur_acier": {
		"name": "Mur d'acier", "cost": 90, "time": 3.5, "size": Vector2i(1, 1), "power": 0, "requires": [],
		"hp": 1400, "tough": 2.2, "armor": "building", "vision": 3, "unlock": 4, "no_upgrade": true, "wall": true,
		"faction": "kharn", "desc": "Mur renforcé (Kharn)",
	},
	"tour_acide": {
		"name": "Tour acide", "cost": 500, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 600, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "vael", "aa": true, "vs_air": 0.8,
		"weapon": "acid", "dps": 34, "range": 7, "vision": 9,
		"desc": "Perce les blindages (Vael)",
		"req_level": {"usine": 2}, "max": 6,
	},
	"marche": {
		"name": "Marché noir", "cost": 550, "time": 12.0, "size": Vector2i(3, 2), "power": -20,
		"requires": ["raffinerie"], "hp": 700, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "vael", "income": 4.0, "desc": "+4 Solaris par seconde (Vael)",
		"req_level": {"raffinerie": 2}, "max": 2,
	},
	"tour_prisme": {
		"name": "Tour prisme", "cost": 540, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 650, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "conclave", "aa": true, "vs_air": 0.8,
		"weapon": "shard", "dps": 36, "range": 8, "vision": 9,
		"desc": "Éclats de cristal en zone (Conclave)", "req_level": {"usine": 2}, "max": 6,
	},
	"serre": {
		"name": "Serre cristalline", "cost": 500, "time": 12.0, "size": Vector2i(3, 2), "power": -20,
		"requires": ["fonderie"], "hp": 650, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "conclave", "ore_income": 3.0, "desc": "+3 minerai par seconde (Conclave)",
		"req_level": {"fonderie": 2}, "max": 2,
	},
	"mur_cristal": {
		"name": "Mur de cristal", "cost": 70, "time": 3.2, "size": Vector2i(1, 1), "power": 0, "requires": [],
		"hp": 1000, "tough": 2.0, "armor": "building", "vision": 3, "unlock": 4, "no_upgrade": true, "wall": true,
		"faction": "conclave", "desc": "Mur cristallin qui se régénère (Conclave)",
	},
	# --- solis : extension (v2) ---
	"atelier_solis": {
		"name": "Atelier de précision", "cost": 600, "time": 12.0, "size": Vector2i(3, 2), "power": -25,
		"requires": ["usine"], "hp": 900, "tough": 1.2, "armor": "building", "unlock": 2,
		"faction": "solis", "desc": "Débloque les unités avancées Solis", "req_level": {"usine": 2},
		"max": 1,
	},
	"clinique_solis": {
		"name": "Clinique solaire", "cost": 520, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 700, "armor": "building", "unlock": 2, "no_upgrade": true,
		"faction": "solis", "heal": 24.0, "heal_range": 6.0, "needs_power": true,
		"desc": "Soigne vite les unités proches (Solis)", "req_level": {"usine": 2}, "max": 2,
	},
	"tour_laser": {
		"name": "Tour laser", "cost": 600, "time": 12.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "atelier_solis"], "hp": 700, "armor": "building", "unlock": 3,
		"faction": "solis", "aa": true, "vs_air": 0.9, "weapon": "laser", "dps": 42, "range": 8,
		"vision": 9, "desc": "Faisceau précis, efficace contre les blindés (Solis)",
		"req_level": {"usine": 2}, "max": 5,
	},
	"mortier_lourd": {
		"name": "Mortier lourd", "cost": 700, "time": 13.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "radar", "atelier_solis"], "hp": 600, "armor": "building", "unlock": 4,
		"no_upgrade": true, "faction": "solis", "weapon": "mortar", "dps": 30, "range": 13, "vision": 11,
		"desc": "Artillerie longue portée, ne touche que le sol (Solis)", "req_level": {"usine": 3},
		"max": 3,
	},
	"pylone_egide": {
		"name": "Pylône Égide", "cost": 450, "time": 10.0, "size": Vector2i(2, 2), "power": -15,
		"requires": ["centrale"], "hp": 600, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "solis", "aura_regen": 8.0, "aura_range": 7, "needs_power": true,
		"desc": "Répare les bâtiments alliés proches (Solis)", "req_level": {"centrale": 2}, "max": 3,
	},
	"comptoir_solis": {
		"name": "Comptoir technique", "cost": 550, "time": 12.0, "size": Vector2i(3, 2), "power": -15,
		"requires": ["raffinerie"], "hp": 700, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "solis", "income": 3.5, "needs_power": true,
		"desc": "+3,5 Solaris par seconde (Solis)", "req_level": {"raffinerie": 2}, "max": 2,
	},
	"cellule_fusion": {
		"name": "Cellule de fusion", "cost": 800, "time": 13.0, "size": Vector2i(2, 2), "power": 320,
		"requires": ["centrale", "usine"], "hp": 800, "tough": 1.4, "armor": "building", "unlock": 4,
		"no_upgrade": true, "faction": "solis", "desc": "Énergie abondante (Solis)",
		"req_level": {"centrale": 2, "usine": 2}, "max": 2,
	},
	"hangar_solis": {
		"name": "Hangar de précision", "cost": 700, "time": 12.0, "size": Vector2i(3, 2), "power": -30,
		"requires": ["aerodrome"], "hp": 900, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "solis", "desc": "Débloque les appareils avancés Solis", "req_level": {"usine": 2},
		"max": 1,
	},
	"observatoire": {
		"name": "Observatoire", "cost": 420, "time": 10.0, "size": Vector2i(2, 2), "power": -35,
		"requires": ["radar"], "hp": 550, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "solis", "vision": 22, "needs_power": true,
		"desc": "Détection à très longue portée (Solis)", "req_level": {"radar": 2}, "max": 2,
	},
	"canon_solaire": {
		"name": "Canon solaire", "cost": 1800, "time": 22.0, "size": Vector2i(3, 3), "power": -80,
		"requires": ["usine", "radar", "atelier_solis"], "hp": 1800, "tough": 1.3, "armor": "building",
		"unlock": 4, "no_upgrade": true, "faction": "solis", "weapon": "orbital", "dps": 160,
		"range": 18, "vision": 12, "desc": "Frappe orbitale à très longue portée, sol seulement (Solis)",
		"req_level": {"usine": 3}, "max": 1,
	},
	# --- kharn : extension (v2-kharn) ---
	"forge_kharn": {
		"name": "Forge de guerre", "cost": 650, "time": 13.0, "size": Vector2i(3, 2), "power": -25,
		"requires": ["usine"], "hp": 1000, "tough": 1.3, "armor": "building", "unlock": 2,
		"faction": "kharn", "desc": "Débloque les unités avancées Kharn", "req_level": {"usine": 2},
		"max": 1,
	},
	"atelier_kharn": {
		"name": "Atelier de remise en état", "cost": 480, "time": 11.0, "size": Vector2i(3, 2),
		"power": -20, "requires": ["usine"], "hp": 1000, "armor": "building", "unlock": 2,
		"no_upgrade": true, "faction": "kharn", "heal": 20.0, "heal_range": 6.0, "needs_power": true,
		"desc": "Soigne vite les unités proches (Kharn)", "req_level": {"usine": 2}, "max": 2,
	},
	"canon_lourd": {
		"name": "Canon lourd", "cost": 650, "time": 12.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "forge_kharn"], "hp": 1400, "tough": 1.6, "armor": "building", "unlock": 3,
		"faction": "kharn", "aa": true, "vs_air": 0.7, "weapon": "cannon", "dps": 48, "range": 7,
		"vision": 9, "desc": "Tourelle massive aux dégâts élevés (Kharn)", "req_level": {"usine": 2},
		"max": 5,
	},
	"batterie_mortiers": {
		"name": "Batterie de mortiers", "cost": 720, "time": 13.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "radar"], "hp": 900, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "kharn", "weapon": "mortar", "dps": 34, "range": 13, "vision": 11,
		"desc": "Artillerie longue portée, ne touche que le sol (Kharn)", "req_level": {"usine": 3},
		"max": 3,
	},
	"site_missiles": {
		"name": "Site de missiles", "cost": 560, "time": 12.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "radar"], "hp": 800, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "kharn", "aa": true, "vs_air": 1.6, "weapon": "rocket", "dps": 40, "range": 11,
		"vision": 11, "desc": "Missiles sol-air redoutables (Kharn)", "req_level": {"usine": 2},
		"max": 4, "vs_ground": 0.4,
	},
	"turbine_kharn": {
		"name": "Turbine de guerre", "cost": 700, "time": 12.0, "size": Vector2i(2, 2), "power": 300,
		"requires": ["centrale", "usine"], "hp": 1000, "tough": 1.6, "armor": "building", "unlock": 4,
		"no_upgrade": true, "faction": "kharn", "desc": "Énergie abondante et solide (Kharn)",
		"req_level": {"centrale": 2, "usine": 2}, "max": 2,
	},
	"fonderie_lourde": {
		"name": "Fonderie lourde", "cost": 650, "time": 12.0, "size": Vector2i(3, 2), "power": -20,
		"requires": ["fonderie"], "hp": 900, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "kharn", "ore_income": 4.0, "needs_power": true,
		"desc": "+4 minerai par seconde (Kharn)", "req_level": {"fonderie": 2}, "max": 2,
	},
	"hangar_kharn": {
		"name": "Hangar blindé", "cost": 750, "time": 12.0, "size": Vector2i(3, 2), "power": -30,
		"requires": ["aerodrome"], "hp": 1200, "tough": 1.3, "armor": "building", "unlock": 3,
		"no_upgrade": true, "faction": "kharn", "desc": "Débloque les appareils lourds Kharn",
		"req_level": {"usine": 2}, "max": 1,
	},
	"mur_titane": {
		"name": "Mur de titane", "cost": 140, "time": 5.0, "size": Vector2i(1, 1), "power": 0,
		"requires": [], "hp": 2500, "tough": 3.0, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "kharn", "vision": 3, "wall": true, "desc": "Barrière quasi indestructible (Kharn)",
	},
	"marteau_guerre": {
		"name": "Marteau de guerre", "cost": 1900, "time": 22.0, "size": Vector2i(3, 3), "power": -90,
		"requires": ["usine", "radar", "forge_kharn"], "hp": 2000, "tough": 1.5, "armor": "building",
		"unlock": 4, "no_upgrade": true, "faction": "kharn", "weapon": "orbital", "dps": 170,
		"range": 18, "vision": 12, "desc": "Frappe orbitale dévastatrice, sol seulement (Kharn)",
		"req_level": {"usine": 3}, "max": 1,
	},
	# --- vael : extension (v2-vael) ---
	"bureau_vael": {
		"name": "Bureau des contrats", "cost": 600, "time": 12.0, "size": Vector2i(3, 2), "power": -25,
		"requires": ["usine"], "hp": 850, "armor": "building", "unlock": 2, "faction": "vael",
		"desc": "Débloque les unités avancées Vael", "req_level": {"usine": 2}, "max": 1,
	},
	"apothicaire": {
		"name": "Apothicaire", "cost": 500, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 650, "armor": "building", "unlock": 2, "no_upgrade": true,
		"faction": "vael", "heal": 20.0, "heal_range": 6.0, "needs_power": true,
		"desc": "Soigne vite les unités proches (Vael)", "req_level": {"usine": 2}, "max": 2,
	},
	"tour_toxine": {
		"name": "Tour à toxine", "cost": 600, "time": 12.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "bureau_vael"], "hp": 650, "armor": "building", "unlock": 3,
		"faction": "vael", "aa": true, "vs_air": 0.8, "weapon": "acid", "dps": 44, "range": 7,
		"vision": 9, "desc": "Acide corrosif, idéale contre les blindés (Vael)",
		"req_level": {"usine": 2}, "max": 5,
	},
	"lanceur_spores": {
		"name": "Lanceur de spores", "cost": 680, "time": 13.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "radar"], "hp": 600, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "vael", "weapon": "mortar", "dps": 28, "range": 13, "vision": 11,
		"desc": "Artillerie longue portée, ne touche que le sol (Vael)", "req_level": {"usine": 3},
		"max": 3,
	},
	"nid_guepes": {
		"name": "Nid de guêpes", "cost": 480, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 550, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "vael", "aa": true, "vs_air": 1.6, "weapon": "autocannon", "dps": 36, "range": 8,
		"vision": 10, "desc": "Défense anti-aérienne rapide (Vael)", "req_level": {"usine": 2}, "max": 4,
		"vs_ground": 0.5,
	},
	"caravanserail": {
		"name": "Caravansérail", "cost": 620, "time": 12.0, "size": Vector2i(3, 2), "power": -15,
		"requires": ["fonderie"], "hp": 700, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "vael", "ore_income": 3.5, "needs_power": true,
		"desc": "+3,5 minerai par seconde (Vael)", "req_level": {"fonderie": 2}, "max": 2,
	},
	"generateur_vael": {
		"name": "Générateur clandestin", "cost": 750, "time": 12.0, "size": Vector2i(2, 2), "power": 280,
		"requires": ["centrale", "usine"], "hp": 750, "armor": "building", "unlock": 4,
		"no_upgrade": true, "faction": "vael", "desc": "Énergie abondante (Vael)",
		"req_level": {"centrale": 2, "usine": 2}, "max": 2,
	},
	"hangar_vael": {
		"name": "Hangar camouflé", "cost": 700, "time": 12.0, "size": Vector2i(3, 2), "power": -30,
		"requires": ["aerodrome"], "hp": 850, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "vael", "desc": "Débloque les appareils avancés Vael", "req_level": {"usine": 2},
		"max": 1,
	},
	"mur_epines": {
		"name": "Mur d'épines", "cost": 100, "time": 4.0, "size": Vector2i(1, 1), "power": 0,
		"requires": [], "hp": 1600, "tough": 2.4, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "vael", "vision": 3, "wall": true, "desc": "Barrière renforcée (Vael)",
	},
	"pluie_acide": {
		"name": "Pluie acide", "cost": 1700, "time": 22.0, "size": Vector2i(3, 3), "power": -80,
		"requires": ["usine", "radar", "bureau_vael"], "hp": 1700, "tough": 1.3, "armor": "building",
		"unlock": 4, "no_upgrade": true, "faction": "vael", "weapon": "orbital", "dps": 150, "range": 18,
		"vision": 12, "desc": "Frappe orbitale corrosive, sol seulement (Vael)",
		"req_level": {"usine": 3}, "max": 1,
	},
	# --- conclave : extension (v2-conclave) ---
	"sanctuaire": {
		"name": "Sanctuaire", "cost": 620, "time": 12.0, "size": Vector2i(3, 2), "power": -25,
		"requires": ["usine"], "hp": 950, "tough": 1.2, "armor": "building", "unlock": 2,
		"faction": "conclave", "desc": "Débloque les unités avancées du Conclave",
		"req_level": {"usine": 2}, "max": 1,
	},
	"source_vive": {
		"name": "Source vive", "cost": 500, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine"], "hp": 700, "armor": "building", "unlock": 2, "no_upgrade": true,
		"faction": "conclave", "heal": 22.0, "heal_range": 6.0, "needs_power": true,
		"desc": "Soigne vite les unités proches (Conclave)", "req_level": {"usine": 2}, "max": 2,
	},
	"tour_geode": {
		"name": "Tour géode", "cost": 640, "time": 12.0, "size": Vector2i(2, 2), "power": -25,
		"requires": ["usine", "sanctuaire"], "hp": 900, "tough": 1.4, "armor": "building", "unlock": 3,
		"faction": "conclave", "aa": true, "vs_air": 0.8, "weapon": "shard", "dps": 46, "range": 7,
		"vision": 9, "desc": "Tourelle d'éclats à fortes dégâts (Conclave)", "req_level": {"usine": 2},
		"max": 5,
	},
	"tour_aiguille": {
		"name": "Tour aiguille", "cost": 520, "time": 11.0, "size": Vector2i(2, 2), "power": -20,
		"requires": ["usine", "radar"], "hp": 650, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "conclave", "aa": true, "vs_air": 1.6, "weapon": "shard", "dps": 38, "range": 10,
		"vision": 11, "desc": "Défense anti-aérienne de cristal (Conclave)", "req_level": {"usine": 2},
		"max": 4, "vs_ground": 0.4,
	},
	"cairn_cristal": {
		"name": "Cairn de cristal", "cost": 470, "time": 10.0, "size": Vector2i(2, 2), "power": -15,
		"requires": ["centrale"], "hp": 650, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "conclave", "aura_regen": 10.0, "aura_range": 7, "needs_power": true,
		"desc": "Répare les bâtiments alliés proches (Conclave)", "req_level": {"centrale": 2}, "max": 3,
	},
	"filon_vivant": {
		"name": "Filon vivant", "cost": 600, "time": 12.0, "size": Vector2i(3, 2), "power": -15,
		"requires": ["fonderie"], "hp": 750, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "conclave", "ore_income": 4.0, "needs_power": true,
		"desc": "+4 minerai par seconde (Conclave)", "req_level": {"fonderie": 2}, "max": 2,
	},
	"reliquaire": {
		"name": "Reliquaire", "cost": 780, "time": 13.0, "size": Vector2i(2, 2), "power": 300,
		"requires": ["centrale", "usine"], "hp": 850, "tough": 1.4, "armor": "building", "unlock": 4,
		"no_upgrade": true, "faction": "conclave", "desc": "Énergie abondante (Conclave)",
		"req_level": {"centrale": 2, "usine": 2}, "max": 2,
	},
	"hangar_conclave": {
		"name": "Hangar de cristal", "cost": 720, "time": 12.0, "size": Vector2i(3, 2), "power": -30,
		"requires": ["aerodrome"], "hp": 900, "armor": "building", "unlock": 3, "no_upgrade": true,
		"faction": "conclave", "desc": "Débloque les appareils avancés du Conclave",
		"req_level": {"usine": 2}, "max": 1,
	},
	"mur_obsidienne": {
		"name": "Mur d'obsidienne", "cost": 120, "time": 4.0, "size": Vector2i(1, 1), "power": 0,
		"requires": [], "hp": 1800, "tough": 2.6, "armor": "building", "unlock": 4, "no_upgrade": true,
		"faction": "conclave", "vision": 3, "wall": true,
		"desc": "Barrière régénérante, très résistante (Conclave)",
	},
	"nova_cristal": {
		"name": "Nova de cristal", "cost": 1800, "time": 22.0, "size": Vector2i(3, 3), "power": -80,
		"requires": ["usine", "radar", "sanctuaire"], "hp": 1800, "tough": 1.3, "armor": "building",
		"unlock": 4, "no_upgrade": true, "faction": "conclave", "weapon": "orbital", "dps": 160,
		"range": 18, "vision": 12, "desc": "Frappe orbitale de cristal, sol seulement (Conclave)",
		"req_level": {"usine": 3}, "max": 1,
	},
}

# Unités : coût en SOLARIS. role : harvester | miner | combat
# from = bâtiment où l'unité apparaît.
const UNITS := {
	# --- Engins spéciaux (non constructibles) ---
	"mcv": {
		"name": "Engin de chantier", "role": "mcv", "desc": "Se déploie en Chantier : une seconde base", "armor": "heavy",
		"cost": 900, "time": 20.0, "level": 2, "requires": ["usine"], "from": "usine", "hp": 800, "speed": 52.0, "vision": 9,
	},
	"convoi": {
		"name": "Convoi d'épice", "role": "convoy", "desc": "Cargaison à escorter", "armor": "medium",
		"cost": 0, "time": 1.0, "requires": [], "hp": 480, "speed": 58.0, "vision": 8,
	},
	# --- Communes ---
	"recolteur": {
		"name": "Récolteur d'épice", "role": "harvester", "resource": "spice", "armor": "medium",
		"cost": 400, "time": 8.0, "requires": ["raffinerie"], "from": "raffinerie",
		"hp": 300, "speed": 70.0, "capacity": 200.0, "rate": 7.0,
	},
	"mineur": {
		"name": "Mineur", "role": "miner", "resource": "ore", "armor": "medium",
		"cost": 350, "time": 8.0, "requires": ["fonderie"], "from": "fonderie",
		"hp": 260, "speed": 80.0, "capacity": 160.0, "rate": 6.0,
	},
	# --- Unités volantes (Aérodrome) ---
	"libellule": {
		"aa": true, "name": "Libellule", "role": "combat", "desc": "Chasseur de supériorité aérienne (faible contre le sol)", "air": true,
		"armor": "light", "weapon": "autocannon",
		"cost": 360, "time": 7.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 170, "speed": 210.0, "vision": 12, "dps": 20, "range": 4,
		"vs_air": 1.3,
		"vs_ground": 0.5,
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
		"aa": true, "name": "Faucheur", "role": "combat", "desc": "Hélicoptère à roquettes", "air": true,
		"armor": "medium", "weapon": "rocket",
		"cost": 620, "time": 9.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 330, "speed": 150.0, "vision": 10, "dps": 36, "range": 7,
	},
	"marteau": {
		"name": "Marteau", "role": "combat", "desc": "Bombardier lourd (sol)", "air": true,
		"armor": "heavy", "weapon": "cannon",
		"cost": 900, "time": 12.0, "level": 3, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 500, "speed": 110.0, "vision": 9, "dps": 42, "range": 5,
	},
	"mule": {
		"name": "Mule", "role": "transport", "desc": "Transport de 6 unités", "air": true,
		"armor": "heavy",
		"cost": 650, "time": 10.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 600, "speed": 100.0, "vision": 9, "slots": 6,
	},
	"guepe": {
		"aa": true, "name": "Guêpe", "role": "combat", "desc": "Chasseur ultra-rapide (faible contre le sol)", "air": true,
		"armor": "light", "weapon": "autocannon",
		"cost": 340, "time": 6.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 150, "speed": 240.0, "vision": 13, "dps": 22, "range": 4,
		"vs_air": 1.3,
		"vs_ground": 0.5,
	},
	"frelon": {
		"name": "Frelon", "role": "combat", "desc": "Bombardier acide (sol)", "air": true,
		"armor": "light", "weapon": "acid",
		"cost": 620, "time": 10.0, "level": 3, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 230, "speed": 175.0, "vision": 10, "dps": 40, "range": 5,
	},
	"pelican": {
		"name": "Pélican", "role": "transport", "desc": "Transport de 4 unités rapide", "air": true,
		"armor": "medium",
		"cost": 480, "time": 8.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 280, "speed": 190.0, "vision": 10, "slots": 4,
	},
	# --- Maison Solis ---
	"sentinelle": {
		"aa": true, "name": "Sentinelle", "role": "combat", "desc": "Éclaireur rapide, harcèle l'air",
		"armor": "light", "weapon": "autocannon",
		"cost": 220, "time": 5.0, "level": 1, "requires": ["usine"], "from": "usine",
		"hp": 190, "dps": 15, "speed": 160.0, "range": 5, "vision": 11,
		"vs_air": 0.7,
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
		"hp": 250, "dps": 17, "speed": 120.0, "range": 3,
	},
	"brute": {
		"name": "Brute", "role": "combat", "desc": "Char lourd",
		"armor": "heavy", "weapon": "cannon",
		"cost": 760, "time": 11.0, "level": 3, "requires": ["usine", "fonderie"], "from": "usine",
		"hp": 950, "dps": 36, "speed": 65.0, "range": 6,
	},
	"salve": {
		"aa": true, "name": "Salve", "role": "combat", "desc": "Lance-missiles anti-aérien",
		"armor": "light", "weapon": "rocket",
		"cost": 540, "time": 9.0, "level": 2, "requires": ["usine", "radar"], "from": "usine",
		"hp": 260, "dps": 38, "speed": 80.0, "range": 11, "vision": 9,
	},
	# --- Cartel Vael ---
	"faucon": {
		"aa": true, "name": "Faucon", "role": "combat", "desc": "Raider rapide, harcèle l'air",
		"armor": "light", "weapon": "autocannon",
		"cost": 210, "time": 4.0, "level": 1, "requires": ["usine"], "from": "usine",
		"hp": 150, "dps": 15, "speed": 200.0, "range": 4, "vision": 11,
		"vs_air": 0.7,
	},
	"vipere": {
		"name": "Vipère", "role": "combat", "desc": "Char antiblindage (acide)",
		"armor": "medium", "weapon": "acid",
		"cost": 520, "time": 8.0, "level": 2, "requires": ["usine"], "from": "usine",
		"hp": 400, "dps": 36, "speed": 105.0, "range": 6,
	},
	"mirage": {
		"name": "Mirage", "role": "combat", "desc": "Prend le contrôle d'un char ennemi",
		"armor": "light", "weapon": "control",
		"cost": 430, "time": 9.0, "level": 3, "requires": ["usine", "radar"], "from": "usine",
		"hp": 300, "dps": 32, "speed": 85.0, "range": 6,
	},
	# --- Conclave Obsidien ---
	"ombre": {
		"aa": true, "name": "Ombre", "role": "combat", "desc": "Éclaireur furtif, harcèle l'air",
		"armor": "light", "weapon": "autocannon",
		"cost": 230, "time": 5.0, "level": 1, "requires": ["usine"], "from": "usine",
		"hp": 200, "dps": 15, "speed": 155.0, "range": 5, "vision": 11,
		"vs_air": 0.7,
	},
	"prisme": {
		"name": "Prisme", "role": "combat", "desc": "Char à éclats cristallins (dégâts de zone)",
		"armor": "medium", "weapon": "shard",
		"cost": 500, "time": 8.0, "level": 2, "requires": ["usine"], "from": "usine",
		"hp": 500, "dps": 28, "speed": 92.0, "range": 6,
	},
	"obelisque": {
		"name": "Obélisque", "role": "combat", "desc": "Artillerie de cristal longue portée (sol)",
		"armor": "medium", "weapon": "shard",
		"cost": 650, "time": 10.0, "level": 3, "requires": ["usine", "radar"], "from": "usine",
		"hp": 420, "dps": 46, "speed": 60.0, "range": 10, "vision": 9,
	},
	"vesper": {
		"aa": true, "name": "Vesper", "role": "combat", "desc": "Chasseur furtif (faible contre le sol)", "air": true,
		"armor": "light", "weapon": "autocannon",
		"cost": 350, "time": 6.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 160, "speed": 230.0, "vision": 13, "dps": 21, "range": 4,
		"vs_air": 1.3,
		"vs_ground": 0.5,
	},
	"eclipse": {
		"name": "Éclipse", "role": "combat", "desc": "Bombardier à éclats (sol, zone)", "air": true,
		"armor": "light", "weapon": "shard",
		"cost": 640, "time": 10.0, "level": 3, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 250, "speed": 170.0, "vision": 10, "dps": 40, "range": 5,
	},
	"passeur": {
		"name": "Passeur", "role": "transport", "desc": "Transport de 5 unités", "air": true,
		"armor": "medium",
		"cost": 500, "time": 8.0, "level": 2, "requires": ["usine", "aerodrome"], "from": "aerodrome",
		"hp": 330, "speed": 175.0, "vision": 10, "slots": 5,
	},
	# --- solis : extension (v2) ---
	"pisteur": {
		"name": "Pisteur", "role": "combat", "desc": "Éclaireur ultra-rapide, grande vision",
		"armor": "light", "weapon": "autocannon", "cost": 160, "time": 3.5, "level": 1,
		"requires": ["usine"], "from": "usine", "hp": 120, "dps": 9, "speed": 200.0, "range": 4,
		"vision": 15,
	},
	"brise_mur": {
		"name": "Brise-mur", "role": "combat", "desc": "Sapeur sonique : ravage les bâtiments",
		"armor": "light", "weapon": "sonic", "cost": 360, "time": 7.0, "level": 2, "requires": ["usine"],
		"from": "usine", "hp": 300, "dps": 18, "speed": 88.0, "range": 4, "vision": 7, "vs_ground": 0.5,
		"vs_building": 2.2,
	},
	"citadelle": {
		"name": "Citadelle", "role": "combat", "desc": "Char lourd à blindage réactif", "armor": "heavy",
		"weapon": "cannon", "cost": 720, "time": 11.0, "level": 3,
		"requires": ["usine", "atelier_solis"], "from": "usine", "hp": 900, "dps": 33, "speed": 70.0,
		"range": 6,
	},
	"technicien": {
		"name": "Technicien", "role": "combat", "desc": "Soigne les unités alliées proches",
		"armor": "light", "cost": 380, "time": 7.0, "level": 2, "requires": ["usine", "atelier_solis"],
		"from": "usine", "hp": 240, "dps": 0, "speed": 100.0, "range": 0, "vision": 8, "heal": 14.0,
		"heal_range": 4,
	},
	"cirrus": {
		"name": "Cirrus", "role": "combat", "desc": "Lance-missiles anti-aérien", "aa": true,
		"armor": "light", "weapon": "rocket", "cost": 470, "time": 8.0, "level": 2,
		"requires": ["usine", "radar"], "from": "usine", "hp": 250, "dps": 40, "speed": 85.0,
		"range": 11, "vision": 9, "vs_air": 1.5, "vs_ground": 0.35,
	},
	"diapason": {
		"name": "Diapason", "role": "combat", "desc": "Mortier sonique longue portée (sol)",
		"armor": "light", "weapon": "mortar", "cost": 620, "time": 10.0, "level": 3,
		"requires": ["usine", "radar", "atelier_solis"], "from": "usine", "hp": 230, "dps": 30,
		"speed": 60.0, "range": 13, "vision": 9,
	},
	"eclair": {
		"name": "Éclair", "role": "combat", "desc": "Intercepteur supersonique", "air": true, "aa": true,
		"armor": "light", "weapon": "autocannon", "cost": 330, "time": 6.0, "level": 2,
		"requires": ["usine", "aerodrome"], "from": "aerodrome", "hp": 150, "dps": 22, "speed": 260.0,
		"range": 5, "vision": 13, "vs_air": 1.4, "vs_ground": 0.4,
	},
	"foudre": {
		"name": "Foudre", "role": "combat", "desc": "Canonnière laser, vise l'air et le sol",
		"air": true, "aa": true, "armor": "medium", "weapon": "laser", "cost": 600, "time": 9.0,
		"level": 3, "requires": ["usine", "aerodrome", "hangar_solis"], "from": "aerodrome", "hp": 380,
		"dps": 38, "speed": 190.0, "range": 6, "vision": 10, "vs_air": 0.9,
	},
	"orage": {
		"name": "Orage", "role": "combat", "desc": "Bombardier plasma lourd (sol)", "air": true,
		"armor": "medium", "weapon": "plasma", "cost": 700, "time": 12.0, "level": 3,
		"requires": ["usine", "aerodrome", "hangar_solis"], "from": "aerodrome", "hp": 330, "dps": 44,
		"speed": 150.0, "range": 3, "vision": 9, "vs_building": 1.3,
	},
	"vigie": {
		"name": "Vigie", "role": "combat", "desc": "Drone de reconnaissance rapide", "air": true,
		"armor": "light", "weapon": "autocannon", "cost": 140, "time": 3.0, "level": 1,
		"requires": ["usine", "aerodrome"], "from": "aerodrome", "hp": 90, "dps": 6, "speed": 280.0,
		"range": 4, "vision": 18,
	},
	# --- kharn : extension (v2-kharn) ---
	"rodeur": {
		"name": "Rôdeur", "role": "combat", "desc": "Buggy d'assaut rapide et bon marché",
		"armor": "light", "weapon": "autocannon", "cost": 170, "time": 3.5, "level": 1,
		"requires": ["usine"], "from": "usine", "hp": 150, "dps": 10, "speed": 170.0, "range": 3,
		"vision": 10,
	},
	"demolisseur": {
		"name": "Démolisseur", "role": "combat", "desc": "Blindé bélier : détruit les bâtiments",
		"armor": "heavy", "weapon": "cannon", "cost": 400, "time": 8.0, "level": 2,
		"requires": ["usine"], "from": "usine", "hp": 450, "dps": 26, "speed": 75.0, "range": 3,
		"vision": 7, "vs_ground": 0.6, "vs_building": 2.0,
	},
	"titan": {
		"name": "Titan", "role": "combat", "desc": "Char super-lourd, quasi indestructible",
		"armor": "heavy", "weapon": "cannon", "cost": 1150, "time": 15.0, "level": 3,
		"requires": ["usine", "forge_kharn"], "from": "usine", "hp": 1700, "dps": 55, "speed": 55.0,
		"range": 7, "vision": 8,
	},
	"brasier": {
		"name": "Brasier", "role": "combat", "desc": "Lance-flammes : fauche l'infanterie légère",
		"armor": "medium", "weapon": "flame", "cost": 420, "time": 8.0, "level": 2,
		"requires": ["usine"], "from": "usine", "hp": 420, "dps": 48, "speed": 100.0, "range": 3,
		"vision": 7,
	},
	"obusier": {
		"name": "Obusier", "role": "combat", "desc": "Artillerie lourde longue portée (sol)",
		"armor": "light", "weapon": "mortar", "cost": 640, "time": 11.0, "level": 3,
		"requires": ["usine", "radar", "forge_kharn"], "from": "usine", "hp": 260, "dps": 34,
		"speed": 55.0, "range": 14, "vision": 9,
	},
	"depanneuse": {
		"name": "Dépanneuse", "role": "combat", "desc": "Répare les unités alliées proches",
		"armor": "medium", "cost": 360, "time": 7.0, "level": 2, "requires": ["usine", "atelier_kharn"],
		"from": "usine", "hp": 380, "dps": 0, "speed": 85.0, "range": 0, "vision": 8, "heal": 18.0,
		"heal_range": 4,
	},
	"vautour": {
		"name": "Vautour", "role": "combat", "desc": "Bombardier léger (sol)", "air": true,
		"armor": "light", "weapon": "mortar", "cost": 560, "time": 9.0, "level": 2,
		"requires": ["usine", "aerodrome"], "from": "aerodrome", "hp": 280, "dps": 38, "speed": 130.0,
		"range": 4, "vision": 9,
	},
	"aigle": {
		"name": "Aigle", "role": "combat", "desc": "Chasseur lourd de supériorité aérienne", "air": true,
		"aa": true, "armor": "medium", "weapon": "autocannon", "cost": 480, "time": 8.0, "level": 2,
		"requires": ["usine", "aerodrome"], "from": "aerodrome", "hp": 260, "dps": 26, "speed": 200.0,
		"range": 5, "vision": 12, "vs_air": 1.3, "vs_ground": 0.5,
	},
	"forteresse_vol": {
		"name": "Forteresse volante", "role": "combat", "desc": "Bombardier lourd (sol)", "air": true,
		"armor": "heavy", "weapon": "cannon", "cost": 1100, "time": 14.0, "level": 3,
		"requires": ["usine", "aerodrome", "hangar_kharn"], "from": "aerodrome", "hp": 800, "dps": 60,
		"speed": 90.0, "range": 5, "vision": 9, "vs_building": 1.2,
	},
	"cyclone": {
		"name": "Cyclone", "role": "combat", "desc": "Hélicoptère de combat à roquettes", "air": true,
		"aa": true, "armor": "heavy", "weapon": "rocket", "cost": 700, "time": 11.0, "level": 3,
		"requires": ["usine", "aerodrome", "hangar_kharn"], "from": "aerodrome", "hp": 520, "dps": 44,
		"speed": 130.0, "range": 7, "vision": 10, "vs_air": 1.0,
	},
	# --- vael : extension (v2-vael) ---
	"rat_sable": {
		"name": "Rat des sables", "role": "combat", "desc": "Raider ultra-rapide, fragile",
		"armor": "light", "weapon": "autocannon", "cost": 150, "time": 3.5, "level": 1,
		"requires": ["usine"], "from": "usine", "hp": 130, "dps": 10, "speed": 215.0, "range": 4,
		"vision": 12,
	},
	"saboteur": {
		"name": "Saboteur", "role": "combat", "desc": "Sape les structures à l'acide", "armor": "light",
		"weapon": "acid", "cost": 330, "time": 7.0, "level": 2, "requires": ["usine"], "from": "usine",
		"hp": 220, "dps": 20, "speed": 130.0, "range": 3, "vision": 8, "vs_ground": 0.6,
		"vs_building": 1.8,
	},
	"scorpion": {
		"name": "Scorpion", "role": "combat",
		"desc": "Char à l'acide corrosif, redoutable contre les blindés", "armor": "medium",
		"weapon": "acid", "cost": 680, "time": 10.0, "level": 3, "requires": ["usine", "bureau_vael"],
		"from": "usine", "hp": 650, "dps": 40, "speed": 95.0, "range": 6, "vision": 8,
	},
	"guerisseur": {
		"name": "Guérisseur", "role": "combat", "desc": "Soigne les unités alliées proches",
		"armor": "light", "cost": 350, "time": 7.0, "level": 2, "requires": ["usine", "apothicaire"],
		"from": "usine", "hp": 230, "dps": 0, "speed": 110.0, "range": 0, "vision": 8, "heal": 16.0,
		"heal_range": 4,
	},
	"harpon": {
		"name": "Harpon", "role": "combat", "desc": "Lance-missiles anti-aérien", "aa": true,
		"armor": "light", "weapon": "rocket", "cost": 450, "time": 8.0, "level": 2,
		"requires": ["usine", "radar"], "from": "usine", "hp": 230, "dps": 38, "speed": 110.0,
		"range": 11, "vision": 9, "vs_air": 1.5, "vs_ground": 0.35,
	},
	"cracheur": {
		"name": "Cracheur", "role": "combat", "desc": "Mortier à spores, longue portée (sol)",
		"armor": "light", "weapon": "mortar", "cost": 590, "time": 10.0, "level": 3,
		"requires": ["usine", "radar", "bureau_vael"], "from": "usine", "hp": 220, "dps": 30,
		"speed": 65.0, "range": 12, "vision": 9,
	},
	"cigale": {
		"name": "Cigale", "role": "combat", "desc": "Drone d'espionnage", "air": true, "armor": "light",
		"weapon": "autocannon", "cost": 130, "time": 3.0, "level": 1, "requires": ["usine", "aerodrome"],
		"from": "aerodrome", "hp": 80, "dps": 6, "speed": 270.0, "range": 4, "vision": 17,
	},
	"milan": {
		"name": "Milan", "role": "combat", "desc": "Chasseur léger de harcèlement", "air": true,
		"aa": true, "armor": "light", "weapon": "autocannon", "cost": 360, "time": 6.0, "level": 2,
		"requires": ["usine", "aerodrome"], "from": "aerodrome", "hp": 140, "dps": 22, "speed": 250.0,
		"range": 5, "vision": 13, "vs_air": 1.3, "vs_ground": 0.5,
	},
	"mante": {
		"name": "Mante", "role": "combat", "desc": "Bombardier acide lourd (sol)", "air": true,
		"armor": "medium", "weapon": "acid", "cost": 680, "time": 11.0, "level": 3,
		"requires": ["usine", "aerodrome", "hangar_vael"], "from": "aerodrome", "hp": 300, "dps": 46,
		"speed": 140.0, "range": 4, "vision": 9, "vs_building": 1.2,
	},
	"cobra": {
		"name": "Cobra", "role": "combat", "desc": "Hélicoptère acide, vise l'air et le sol",
		"air": true, "aa": true, "armor": "medium", "weapon": "acid", "cost": 620, "time": 10.0,
		"level": 3, "requires": ["usine", "aerodrome", "hangar_vael"], "from": "aerodrome", "hp": 360,
		"dps": 36, "speed": 150.0, "range": 6, "vision": 10, "vs_air": 0.9,
	},
	# --- conclave : extension (v2-conclave) ---
	"tesson": {
		"name": "Tesson", "role": "combat", "desc": "Raider cristallin rapide", "armor": "light",
		"weapon": "shard", "cost": 170, "time": 3.5, "level": 1, "requires": ["usine"], "from": "usine",
		"hp": 150, "dps": 11, "speed": 165.0, "range": 4, "vision": 10,
	},
	"fracasseur": {
		"name": "Fracasseur", "role": "combat", "desc": "Brise les structures à coups d'éclats",
		"armor": "medium", "weapon": "shard", "cost": 380, "time": 8.0, "level": 2,
		"requires": ["usine"], "from": "usine", "hp": 360, "dps": 24, "speed": 85.0, "range": 4,
		"vision": 7, "vs_ground": 0.6, "vs_building": 2.0,
	},
	"monolithe": {
		"name": "Monolithe", "role": "combat", "desc": "Char lourd d'obsidienne", "armor": "heavy",
		"weapon": "shard", "cost": 780, "time": 12.0, "level": 3, "requires": ["usine", "sanctuaire"],
		"from": "usine", "hp": 1000, "dps": 34, "speed": 62.0, "range": 6, "vision": 8,
	},
	"veilleur": {
		"name": "Veilleur", "role": "combat", "desc": "Soigne les unités alliées proches",
		"armor": "light", "cost": 370, "time": 7.0, "level": 2, "requires": ["usine", "sanctuaire"],
		"from": "usine", "hp": 250, "dps": 0, "speed": 95.0, "range": 0, "vision": 8, "heal": 20.0,
		"heal_range": 4,
	},
	"aiguille": {
		"name": "Aiguille", "role": "combat", "desc": "Tourelle mobile anti-aérienne", "aa": true,
		"armor": "light", "weapon": "shard", "cost": 460, "time": 8.0, "level": 2,
		"requires": ["usine", "radar"], "from": "usine", "hp": 240, "dps": 36, "speed": 90.0,
		"range": 10, "vision": 9, "vs_air": 1.5, "vs_ground": 0.35,
	},
	"quartz": {
		"name": "Quartz", "role": "combat", "desc": "Mortier de cristal longue portée (sol)",
		"armor": "light", "weapon": "mortar", "cost": 610, "time": 10.0, "level": 3,
		"requires": ["usine", "radar", "sanctuaire"], "from": "usine", "hp": 230, "dps": 30,
		"speed": 60.0, "range": 13, "vision": 9,
	},
	"ephemere": {
		"name": "Éphémère", "role": "combat", "desc": "Drone d'observation", "air": true,
		"armor": "light", "weapon": "shard", "cost": 130, "time": 3.0, "level": 1,
		"requires": ["usine", "aerodrome"], "from": "aerodrome", "hp": 90, "dps": 6, "speed": 275.0,
		"range": 4, "vision": 18,
	},
	"scintille": {
		"name": "Scintille", "role": "combat", "desc": "Intercepteur de cristal", "air": true,
		"aa": true, "armor": "light", "weapon": "shard", "cost": 350, "time": 6.0, "level": 2,
		"requires": ["usine", "aerodrome"], "from": "aerodrome", "hp": 150, "dps": 22, "speed": 255.0,
		"range": 5, "vision": 13, "vs_air": 1.4, "vs_ground": 0.4,
	},
	"stalactite": {
		"name": "Stalactite", "role": "combat", "desc": "Bombardier lourd d'obsidienne (sol)",
		"air": true, "armor": "heavy", "weapon": "shard", "cost": 860, "time": 13.0, "level": 3,
		"requires": ["usine", "aerodrome", "hangar_conclave"], "from": "aerodrome", "hp": 560, "dps": 52,
		"speed": 100.0, "range": 4, "vision": 9, "vs_building": 1.2,
	},
	"aurore": {
		"name": "Aurore", "role": "combat", "desc": "Canonnière plasma, vise l'air et le sol",
		"air": true, "aa": true, "armor": "medium", "weapon": "plasma", "cost": 640, "time": 10.0,
		"level": 3, "requires": ["usine", "aerodrome", "hangar_conclave"], "from": "aerodrome",
		"hp": 360, "dps": 38, "speed": 170.0, "range": 6, "vision": 10, "vs_air": 0.9,
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
## Seules certaines unités / défenses (drapeau "aa") peuvent toucher une unité volante.
static func can_hit_air(id: String) -> bool:
	return bool(def(id).get("aa", false))


## Modulation des dégâts selon la cible : "vs_air" / "vs_ground" du tireur (1.0 par défaut).
static func aim_mult(shooter_id: String, target_is_air: bool, target_is_building := false) -> float:
	var d := def(shooter_id)
	var m := float(d.get("vs_air" if target_is_air else "vs_ground", 1.0))
	if target_is_building:
		m *= float(d.get("vs_building", 1.0))
	return m


static func mult(weapon: String, armor: String) -> float:
	var row: Dictionary = MULT.get(weapon, {})
	return float(row.get(armor, 1.0))


## Coût en Solaris d'un bâtiment (en plus du minerai) ; 0 pour une unité.
static func sol_cost(id: String) -> int:
	if UNITS.has(id) or not BUILDINGS.has(id):
		return 0
	return int(round(float(BUILDINGS[id]["cost"]) * 0.5 / 5.0)) * 5


## Minerai demandé en plus des Solaris pour produire une unité (environ 8 % de son prix, 5 minimum).
static func unit_ore(id: String) -> int:
	if not UNITS.has(id):
		return 0
	return maxi(5, int(round(float(UNITS[id]["cost"]) * 0.08 / 5.0)) * 5)


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
	var out: Array = ["recolteur", "mineur", "mcv"]
	out.append_array(FACTIONS[faction]["units"])
	out.append_array(FACTIONS[faction]["air"])
	return out


## Texte des prérequis sans doublon : « Usine niveau 3 » remplace « Usine » (une seule mention).
static func req_names(d: Dictionary) -> PackedStringArray:
	var names := PackedStringArray()
	var lvl := int(d.get("level", 1))
	var usine_done := false
	if lvl > 1:
		names.append("Usine niveau %d" % lvl)
		usine_done = true
	for r in d.get("requires", []):
		if r == "usine" and usine_done:
			continue
		names.append(BUILDINGS[r]["name"])
	return names
