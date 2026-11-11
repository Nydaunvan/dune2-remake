class_name SaveGame
## Sauvegardes sur disque : 4 emplacements (0 = sauvegarde rapide, F6 / F7).
## Le fichier contient la graine de la carte et l'état de la partie (voir main.gd).

const VERSION := 1
const SLOTS := 4


static func path(slot: int) -> String:
	return "user://save_%d.dat" % slot


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


static func write(slot: int, data: Dictionary) -> bool:
	data["version"] = VERSION
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var tmp := path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(data)
	f.close()
	# écriture atomique : on ne remplace l'ancienne sauvegarde qu'une fois la nouvelle complète
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if dir.file_exists(path(slot).get_file()):
		dir.remove(path(slot).get_file())
	return dir.rename(tmp.get_file(), path(slot).get_file()) == OK


static func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var f := FileAccess.open(path(slot), FileAccess.READ)
	if f == null:
		return {}
	var v = f.get_var()
	f.close()
	if v is Dictionary and int(v.get("version", 0)) == VERSION:
		return v
	return {}


static func delete(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))


static func slot_name(slot: int) -> String:
	return "Sauvegarde rapide" if slot == 0 else "Emplacement %d" % slot


## Description d'un emplacement (« Solis — Mission 2 — 12:34 — 2026-11-11 23:50 »), ou "" si vide.
static func describe(slot: int) -> String:
	var d := read(slot)
	if d.is_empty():
		return ""
	var fd: Dictionary = GameData.FACTIONS.get(String(d.get("faction", "")), {})
	var t := int(float(d.get("game_time", 0.0)))
	var where := "Mission %d" % (int(d.get("mission", 0)) + 1) if d.get("mode", "") == "campaign" else "Escarmouche"
	return "%s — %s — %d:%02d de jeu — %s" % [fd.get("name", "?"), where, t / 60, t % 60,
			String(d.get("saved_at", "")).replace("T", " ").substr(0, 16)]
