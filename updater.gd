class_name Updater
extends Node
## Mise à jour automatique depuis GitHub : interroge la dernière release publiée, télécharge l'installateur
## (TheBuildingOfADynasty-Setup.exe) puis le lance en mode /update et ferme le jeu : l'installateur remplace
## les fichiers puis relance le jeu. Réservé à la version Windows exportée (installée ou non).

signal found(info: Dictionary)   # {version, notes, url, size, name}
signal uptodate()
signal failed(msg: String)
signal progress(done: int, total: int)
signal downloaded()

const REPO := "Nydaunvan/dune2-remake"
const API_URL := "https://api.github.com/repos/" + REPO + "/releases/latest"
const ASSET_SUFFIX := "-Setup.exe"
const DEST := "user://update/TheBuildingOfADynasty-Setup.exe"

## Dernier résultat connu (partagé entre les écrans) et vérification déjà faite pendant cette session.
static var last_info := {}
static var checked := false

var info := {}
var _req: HTTPRequest
var _dl: HTTPRequest
var _total := 0


## Mise à jour appliquée seulement par le jeu exporté sous Windows (l'installateur est un programme Windows).
static func can_apply() -> bool:
	return OS.get_name() == "Windows" and not OS.has_feature("editor")


## « 0.23 » → [0, 23] ; tolère un « v » initial et des suffixes (« 0.23.1 »).
static func version_parts(v: String) -> Array:
	var out: Array = []
	for p in v.strip_edges().trim_prefix("v").trim_prefix("V").split("."):
		out.append(int(p))
	return out


static func is_newer(candidate: String, current: String) -> bool:
	var a := version_parts(candidate)
	var b := version_parts(current)
	for i in maxi(a.size(), b.size()):
		var x: int = a[i] if i < a.size() else 0
		var y: int = b[i] if i < b.size() else 0
		if x != y:
			return x > y
	return false


## Réponse de l'API GitHub (release) → infos de mise à jour, ou {} si la release n'a pas d'installateur.
static func parse_release(rel: Dictionary) -> Dictionary:
	if rel.get("draft", false) or rel.get("prerelease", false):
		return {}
	for a in rel.get("assets", []):
		var n := String(a.get("name", ""))
		if n.ends_with(ASSET_SUFFIX):
			return {"version": String(rel.get("tag_name", "")).trim_prefix("v").trim_prefix("V"),
					"notes": String(rel.get("body", "")), "url": String(a.get("browser_download_url", "")),
					"size": int(a.get("size", 0)), "name": n}
	return {}


func check() -> void:
	checked = true
	_req = HTTPRequest.new()
	_req.timeout = 12.0
	add_child(_req)
	_req.request_completed.connect(_on_checked)
	var err := _req.request(API_URL, ["User-Agent: TheBuildingOfADynasty-Updater", "Accept: application/vnd.github+json"])
	if err != OK:
		failed.emit("Connexion impossible")


func _on_checked(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Connexion impossible" if result != HTTPRequest.RESULT_SUCCESS else "Aucune version publiée")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data is Dictionary:
		failed.emit("Réponse illisible")
		return
	var i := parse_release(data)
	if i.is_empty() or not is_newer(String(i["version"]), ChangelogData.current()):
		uptodate.emit()
		return
	info = i
	last_info = i
	found.emit(i)


func download() -> void:
	if info.is_empty():
		return
	var path := ProjectSettings.globalize_path(DEST)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_dl = HTTPRequest.new()
	_dl.download_file = path
	_dl.timeout = 0.0
	add_child(_dl)
	_dl.request_completed.connect(_on_downloaded)
	_total = int(info.get("size", 0))
	if _dl.request(String(info["url"]), ["User-Agent: TheBuildingOfADynasty-Updater"]) != OK:
		failed.emit("Téléchargement impossible")
		return
	set_process(true)


func _process(_d: float) -> void:
	if _dl != null and is_instance_valid(_dl):
		var tot := _dl.get_body_size()
		progress.emit(_dl.get_downloaded_bytes(), tot if tot > 0 else _total)


func _on_downloaded(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	set_process(false)
	var path := ProjectSettings.globalize_path(DEST)
	var ok := result == HTTPRequest.RESULT_SUCCESS and code == 200 and FileAccess.file_exists(path)
	if ok and _total > 0:
		var f := FileAccess.open(path, FileAccess.READ)
		ok = f != null and f.get_length() == _total
	if not ok:
		failed.emit("Téléchargement interrompu")
		return
	downloaded.emit()


## Lance l'installateur en mode mise à jour puis ferme le jeu (il attend la fermeture pour remplacer les fichiers).
func install_and_quit() -> void:
	var path := ProjectSettings.globalize_path(DEST)
	if OS.create_process(path, ["/update"]) <= 0:
		failed.emit("Impossible de lancer l'installateur")
		return
	get_tree().quit()
