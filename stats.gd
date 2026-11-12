class_name GameStats
extends RefCounted
## Statistiques de la partie (récapitulatif de fin).

var units_built := {}     # id -> produites
var units_lost := {}      # id -> perdues (toutes causes)
var units_eaten := {}     # id -> perdues dévorées par un ver
var foes_killed := {}     # id -> unités ennemies abattues par le joueur
var foes_eaten := {}      # id -> unités ennemies dévorées par un ver
var b_built := {}
var b_lost := {}
var b_foe := {}           # bâtiments ennemis détruits par le joueur
var b_demolished := 0
var upgrades := 0
var techs := 0
var promotions := 0
var dmg_dealt := 0.0
var dmg_taken := 0.0
var spent_sol := 0
var spent_ore := 0
var worm_apparitions := 0
var worm_bites := 0
var max_army := 0
var top_id := ""
var top_kills := 0


static func inc(d: Dictionary, k: String, n := 1) -> void:
	d[k] = int(d.get(k, 0)) + n


static func total(d: Dictionary) -> int:
	var s := 0
	for k in d:
		s += int(d[k])
	return s


func to_dict() -> Dictionary:
	var d := {}
	for p in get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			d[p["name"]] = get(p["name"])
	return d


func from_dict(d: Dictionary) -> void:
	for k in d:
		if k in self:
			set(k, d[k])
