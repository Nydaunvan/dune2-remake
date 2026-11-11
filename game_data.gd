class_name GameData
## Données de jeu : bâtiments, unités et palette de l'interface.

const CREAM := Color("f3dcb4")
const AMBER := Color("e0a040")
const RED := Color("ff6b5a")

# Bâtiment de départ (non constructible par le joueur)
const START_BUILDING := {
	"name": "Chantier", "size": Vector2i(3, 3), "power": 0,
}

const BUILDINGS := {
	"centrale": {
		"name": "Centrale", "cost": 300, "time": 6.0,
		"size": Vector2i(2, 2), "power": 100, "requires": [],
	},
	"raffinerie": {
		"name": "Raffinerie", "cost": 600, "time": 9.0,
		"size": Vector2i(3, 2), "power": -30, "requires": ["centrale"],
	},
	"usine": {
		"name": "Usine", "cost": 500, "time": 9.0,
		"size": Vector2i(3, 2), "power": -20, "requires": ["centrale"],
	},
}

const UNITS := {
	"char": {
		"name": "Char léger", "cost": 300, "time": 7.0, "requires": ["usine"],
	},
}


static func def(id: String) -> Dictionary:
	if BUILDINGS.has(id):
		return BUILDINGS[id]
	if UNITS.has(id):
		return UNITS[id]
	return START_BUILDING
