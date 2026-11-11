class_name Campaign
## Campagnes : 5 missions par faction, objectifs variés, progression sauvegardée.
## Tous les camps démarrent avec un simple engin de chantier à déployer.

const SAVE_PATH := "user://campaign.cfg"

## Types d'objectifs : build, harvest, train, survive, destroy_all, outposts,
## escort, hold, protect_ally (contrainte : la base alliée ne doit pas tomber).
const MISSIONS := [
	{
		"id": "camp", "title": "Premier camp", "size": 80,
		"credits": 1500, "ore": 1800,
		"objectives": [
			{"type": "build", "label": "la base", "ids": {"centrale": 1, "raffinerie": 1, "fonderie": 1, "usine": 1}},
			{"type": "harvest", "amount": 2500},
		],
		"ai": {"slowdown": 2.4, "grace": 900.0, "pause": 120.0, "max_army": 6, "wave": 4, "credits": 1000, "ore": 1200},
		"obj": "Établissez votre base et récoltez 2500 Solaris",
	},
	{
		"id": "convoi", "title": "Convoi d'épice", "size": 96,
		"credits": 1500, "ore": 1800,
		"start_units": ["@0", "@1"],
		"convoy": {"count": 4, "need": 3, "ambushes": 3},
		"objectives": [
			{"type": "escort"},
			{"type": "train", "count": 4},
		],
		"ai": {"slowdown": 2.0, "grace": 480.0, "pause": 90.0, "max_army": 8, "wave": 4, "credits": 1200, "ore": 1500},
		"obj": "Escortez le convoi jusqu'au point de livraison",
	},
	{
		"id": "ligne", "title": "Tenir la ligne", "size": 96, "ally": true,
		"credits": 2000, "ore": 2200,
		"start_units": ["@0", "@1"], "ally_units": 2,
		"objectives": [
			{"type": "survive", "time": 480.0},
			{"type": "protect_ally"},
		],
		"ai": {"slowdown": 1.4, "grace": 60.0, "pause": 40.0, "max_army": 16, "wave": 5, "credits": 1800, "ore": 2000},
		"ally_ai": {"slowdown": 1.8, "grace": 600.0, "pause": 90.0, "max_army": 8, "wave": 5, "credits": 1200, "ore": 1500},
		"obj": "Survivez 8 minutes sans perdre la base alliée",
	},
	{
		"id": "postes", "title": "Les avant-postes", "size": 112, "outposts": 3,
		"credits": 2000, "ore": 2200,
		"start_units": ["@0", "@0", "@1"],
		"objectives": [
			{"type": "outposts"},
			{"type": "train", "count": 6},
		],
		"ai": {"slowdown": 1.7, "grace": 300.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1500, "ore": 1800},
		"obj": "Détruisez les 3 avant-postes ennemis",
	},
	{
		"id": "assaut", "title": "L'assaut final", "size": 112, "ally": true,
		"credits": 2500, "ore": 2500,
		"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 3,
		"zone": {"units": 4, "time": 60.0},
		"objectives": [
			{"type": "hold"},
			{"type": "destroy_all"},
		],
		"ai": {"slowdown": 1.15, "grace": 200.0, "pause": 45.0, "max_army": 22, "wave": 6, "credits": 2500, "ore": 2800},
		"ally_ai": {"slowdown": 1.3, "grace": 240.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 2000, "ore": 2200},
		"obj": "Tenez la zone centrale, puis détruisez l'ennemi",
	},
]

## Faction adverse de chaque mission, par faction jouée.
const ENEMIES := {
	"solis": ["vael", "kharn", "kharn", "vael", "kharn"],
	"kharn": ["solis", "vael", "vael", "solis", "solis"],
	"vael": ["kharn", "solis", "solis", "kharn", "kharn"],
}

const FLAVOR := {
	"solis": "La Maison Solis mise sur la technologie et la précision.",
	"kharn": "La Légion Kharn mise sur la puissance brute et le blindage.",
	"vael": "Le Cartel Vael mise sur la vitesse et la ruse.",
}

## {ENEMY} et {ALLY} sont remplacés par le nom des factions.
const BRIEFINGS := [
	"Un engin de chantier vous a déposé en terrain inconnu. Trouvez un sol rocheux dégagé, déployez-le, puis bâtissez centrale, raffinerie, fonderie et usine. {ENEMY} s'installe aussi quelque part sur la carte, mais pas avant un bon moment.",
	"Un convoi d'épice doit traverser le désert jusqu'au point de livraison. {ENEMY} a posté des groupes d'embuscade sur la route : éclairez, escortez et gardez au moins trois camions en vie. Pensez à monter une armée en parallèle.",
	"{ALLY} installe sa base à vos côtés, mais elle est fragile. {ENEMY} lance des assauts dès les premières minutes. Tenez huit minutes et ne laissez pas tomber votre allié.",
	"{ENEMY} a fortifié trois avant-postes autour de la zone. Chacun est gardé par des tourelles et des patrouilles. Montez une armée solide et rasez-les un par un.",
	"La bataille décisive. Avec l'appui de {ALLY}, prenez la zone centrale et tenez-la avec au moins quatre unités pendant une minute, puis anéantissez {ENEMY}. Il ne doit rien rester debout.",
]


static func count() -> int:
	return MISSIONS.size()


static func title_of(m: int) -> String:
	return MISSIONS[m]["title"]


static func enemy_of(faction: String, m: int) -> String:
	return ENEMIES[faction][m]


static func ally_of(faction: String, m: int) -> String:
	if not MISSIONS[m].get("ally", false):
		return ""
	for k in GameData.FACTIONS.keys():
		if k != faction and k != enemy_of(faction, m):
			return k
	return ""


static func briefing(faction: String, m: int) -> String:
	var t: String = BRIEFINGS[m]
	t = t.replace("{ENEMY}", GameData.FACTIONS[enemy_of(faction, m)]["name"])
	var ally := ally_of(faction, m)
	t = t.replace("{ALLY}", GameData.FACTIONS[ally]["name"] if ally != "" else "")
	return FLAVOR[faction] + "\n\n" + t


## Unités de départ : "@i" = i-ième unité de combat de la faction jouée.
static func resolve_units(faction: String, ids: Array) -> Array:
	var out: Array = []
	var fu: Array = GameData.FACTIONS[faction]["units"]
	for id in ids:
		if String(id).begins_with("@"):
			out.append(fu[int(String(id).substr(1)) % fu.size()])
		else:
			out.append(id)
	return out


static func cleared(faction: String) -> int:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return 0
	return int(cf.get_value("progress", faction, 0))


static func mark_cleared(faction: String, m: int) -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	var cur := int(cf.get_value("progress", faction, 0))
	if m + 1 > cur:
		cf.set_value("progress", faction, m + 1)
		cf.save(SAVE_PATH)
