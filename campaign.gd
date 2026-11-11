class_name Campaign
## Campagnes : 3 missions par faction, progression sauvegardée.

const SAVE_PATH := "user://campaign.cfg"

## Paramètres communs (IA, ressources) ; les textes dépendent de la faction.
const MISSIONS := [
	{
		"id": "convoi", "title": "Premier convoi",
		"type": "harvest", "amount": 4000,
		"credits": 1200, "ore": 1500,
		"ai": {"slowdown": 2.2, "grace": 600.0, "pause": 120.0, "max_army": 8, "wave": 4, "credits": 1000, "ore": 1000},
		"obj": "Récoltez 4000 Solaris",
	},
	{
		"id": "ligne", "title": "Tenir la ligne",
		"type": "survive", "time": 480.0,
		"credits": 2000, "ore": 2000,
		"ai": {"slowdown": 1.5, "grace": 45.0, "pause": 40.0, "max_army": 16, "wave": 5, "credits": 1500, "ore": 1500},
		"obj": "Survivez 8 minutes",
	},
	{
		"id": "assaut", "title": "L'assaut final",
		"type": "destroy",
		"credits": 2500, "ore": 2500,
		"ai": {"slowdown": 1.15, "grace": 150.0, "pause": 45.0, "max_army": 22, "wave": 6, "credits": 2500, "ore": 2500},
		"obj": "Détruisez toutes les structures ennemies",
	},
]

## Faction adverse de chaque mission, par faction jouée.
const ENEMIES := {
	"solis": ["vael", "kharn", "kharn"],
	"kharn": ["solis", "vael", "vael"],
	"vael": ["kharn", "solis", "solis"],
}

const BRIEFINGS := {
	"solis": [
		"Commandant, la Maison Solis établit un avant-poste sur Arrakis. Le Cartel Vael rôde dans les parages mais reste pour l'instant à distance. Montez une économie solide : l'épice finance toute la suite.",
		"Le Cartel Vael n'a pas apprécié notre prospérité. Les Kharn mènent des raids sur notre position : les vagues vont se succéder. Fortifiez-vous et tenez jusqu'à l'arrivée des renforts.",
		"La Légion Kharn est la dernière force qui s'oppose à nous. Leur citadelle est à portée : rasez chaque structure et Arrakis sera à Solis.",
	],
	"kharn": [
		"La Légion Kharn pose son premier campement. Le Solis, trop confiants, observent de loin. Remplissez les coffres : une armée de fer se paie en épice.",
		"Le Cartel Vael a flairé notre faiblesse et lance ses raiders. Creusez-vous dans la roche, laissez-les s'user sur nos blindés et tenez la position.",
		"Les Solis ne comprennent que la force. Écrasez leur base sous nos chars : qu'il ne reste pas une structure debout.",
	],
	"vael": [
		"Le Cartel Vael s'installe discrètement. La Légion Kharn n'a pas encore remarqué nos convois. Faites fructifier le marché : l'épice est notre seule loyauté.",
		"Les Kharn ont fini par nous trouver. Ils arrivent par vagues entières : usez leur patience, exploitez le terrain et survivez.",
		"Les Solis contrôlent les routes de l'épice. Frappez leurs infrastructures, privez-les de tout : le Cartel prend la place.",
	],
}


static func title_of(m: int) -> String:
	return MISSIONS[m]["title"]


static func briefing(faction: String, m: int) -> String:
	return BRIEFINGS[faction][m]


static func enemy_of(faction: String, m: int) -> String:
	return ENEMIES[faction][m]


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
