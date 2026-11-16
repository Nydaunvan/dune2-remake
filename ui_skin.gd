class_name UiSkin
extends RefCounted
## Habillage graphique de l'interface par faction : textures du pack HUD (res://assets/ui/<faction>/).
## Les panneaux sont des NinePatch : les bordures gardent leur taille, le centre s'étire.

const BASE := "res://assets/ui/"
const FALLBACK := "solis"

## Marges NinePatch (pixels de texture) : gauche, haut, droite, bas.
const MARGINS := {
	"barre_ressources": [18, 18, 18, 18],
	"compteur_ressource": [30, 30, 30, 30],
	"compteur_temps": [30, 30, 30, 30],
	"compteur_fps": [30, 30, 30, 30],
	"bouton_menu_normal": [26, 26, 26, 26],
	"bouton_menu_survol": [26, 26, 26, 26],
	"bouton_menu_presse": [26, 26, 26, 26],
	"bouton_menu_desactive": [26, 26, 26, 26],
	"panneau_objectifs": [36, 36, 36, 36],
	"panneau_journal": [36, 36, 36, 36],
	"panneau_construction": [40, 44, 40, 44],
	"entete_faction": [36, 36, 36, 36],
	"onglet_normal": [26, 26, 26, 26],
	"onglet_actif": [26, 26, 26, 26],
	"vignette_normal": [22, 22, 22, 22],
	"vignette_survol": [22, 22, 22, 22],
	"vignette_selection": [22, 22, 22, 22],
	"vignette_verrouillee": [22, 22, 22, 22],
	"vignette_production": [22, 22, 22, 22],
	"panneau_selection": [44, 44, 44, 44],
	"bouton_action": [26, 26, 26, 26],
	"bouton_action_survol": [26, 26, 26, 26],
	"bouton_action_danger": [26, 26, 26, 26],
	"panneau_file_production": [40, 40, 40, 40],
	"slot_file_production": [14, 14, 14, 14],
	"barre_progression_fond": [14, 14, 14, 14],
	"barre_progression_remplissage": [14, 14, 14, 14],
	"badge_quantite": [20, 20, 20, 20],
	"panneau_infobulle": [34, 34, 34, 34],
	"barre_vie_remplissage": [10, 10, 10, 10],
}

static var dir := FALLBACK
static var accent := Color("39dfff")
static var direction := ""
static var _tex := {}
static var _box := {}


## Choisit le skin de la faction (retombe sur Solis si son pack n'est pas encore importé).
static func use(faction_id: String) -> void:
	dir = faction_id if DirAccess.dir_exists_absolute(BASE + faction_id) else FALLBACK
	_tex.clear()
	_box.clear()
	var f := FileAccess.open(BASE + dir + "/skin.json", FileAccess.READ)
	if f != null:
		var j = JSON.parse_string(f.get_as_text())
		if j is Dictionary and j.has("accent"):
			accent = Color(String(j["accent"]))
		direction = String(j.get("direction", "")) if j is Dictionary else ""


static func tex(n: String) -> Texture2D:
	if not _tex.has(n):
		var path := BASE + dir + "/" + n + ".png"
		_tex[n] = load(path) if ResourceLoader.exists(path) else null
	return _tex[n]


static func box(n: String) -> StyleBoxTexture:
	if not _box.has(n):
		var sb := StyleBoxTexture.new()
		sb.texture = tex(n)
		var m: Array = MARGINS.get(n, [24, 24, 24, 24])
		sb.texture_margin_left = m[0]
		sb.texture_margin_top = m[1]
		sb.texture_margin_right = m[2]
		sb.texture_margin_bottom = m[3]
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		_box[n] = sb
	return _box[n]


## Dessine le panneau `n` étiré sur `r` (NinePatch).
static func panel(ci: CanvasItem, n: String, r: Rect2, modulate := Color.WHITE) -> void:
	if tex(n) == null:
		return
	ci.draw_style_box(box(n), r)
	if modulate != Color.WHITE:
		pass


## Dessine la texture `n` entière dans `r` (icônes, cadres sans étirement).
static func image(ci: CanvasItem, n: String, r: Rect2, modulate := Color.WHITE) -> void:
	var t := tex(n)
	if t != null:
		ci.draw_texture_rect(t, r, false, modulate)


## Barre de progression : fond puis remplissage jusqu'à `frac`.
static func bar(ci: CanvasItem, r: Rect2, frac: float, tint := Color.WHITE, fill := "barre_progression_remplissage") -> void:
	panel(ci, "barre_progression_fond", r)
	if frac > 0.004:
		var w := maxf(r.size.y, r.size.x * clampf(frac, 0.0, 1.0))
		if tex(fill) == null:
			fill = "barre_progression_remplissage"
		var t := tex(fill)
		if t != null:
			var sb := box(fill).duplicate() as StyleBoxTexture
			sb.modulate_color = tint
			ci.draw_style_box(sb, Rect2(r.position, Vector2(w, r.size.y)))
