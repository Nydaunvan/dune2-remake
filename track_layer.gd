class_name TrackLayer
extends Node2D
## Traces laissées par les véhicules dans le sable, selon leur mode de déplacement (chenilles, roues, coussin d'air) :
## elles s'estompent peu à peu.

const LIFE := 9.0      # secondes avant disparition complète
const MAX_SEGS := 900  # plafond de segments affichés (les plus anciens sont retirés)

var _segs: Array = []  # [a: Vector2, b: Vector2, perp: Vector2, t0: float, half_w: float, kind: String]
var _t := 0.0


func _init() -> void:
	z_index = -9 # au-dessus du terrain, sous les bâtiments et les unités


func add(a: Vector2, b: Vector2, half_w: float, kind := "tracks") -> void:
	var d := b - a
	if d.length() < 0.5:
		return
	var perp := Vector2(-d.y, d.x).normalized()
	_segs.append([a, b, perp, _t, half_w, kind])
	if _segs.size() > MAX_SEGS:
		_segs.pop_front()


func _process(delta: float) -> void:
	_t += delta
	while not _segs.is_empty() and _t - float(_segs[0][3]) > LIFE:
		_segs.pop_front()
	if not _segs.is_empty():
		queue_redraw()


func _draw() -> void:
	for s in _segs:
		var k := 1.0 - (_t - float(s[3])) / LIFE
		if k <= 0.0:
			continue
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var off: Vector2 = (s[2] as Vector2) * float(s[4])
		var al := 0.32 * k * k # s'efface de plus en plus vite
		var perp: Vector2 = s[2]
		match String(s[5]):
			"tracks":
				# Chenilles : deux larges bandes cannelées (barrettes en travers) et bourrelets de sable
				var col := Color(0.28, 0.16, 0.09, al)
				var rim := Color(1.0, 0.85, 0.6, al * 0.4)
				for sd in [-1.0, 1.0]:
					var o: Vector2 = off * sd
					draw_line(a + o, b + o, col, 3.8, true)
					draw_line(a + o + perp * sd * 3.2, b + o + perp * sd * 3.2, rim, 1.3, true)
					draw_line(b + o - perp * 2.6, b + o + perp * 2.6, Color(0.18, 0.1, 0.05, al * 1.1), 1.4, true)
			"wheels":
				# Roues : deux fins sillons réguliers, plus nets qu'une chenille mais sans cannelures
				var col := Color(0.33, 0.2, 0.11, al * 0.95)
				for sd in [-1.0, 1.0]:
					var o: Vector2 = off * sd * 0.9
					draw_line(a + o, b + o, col, 1.7, true)
			"hover":
				# Coussin d'air : pas de sillon, le sable est simplement soufflé en une large bande claire et floue
				var soft := Color(1.0, 0.9, 0.7, al * 0.55)
				draw_line(a, b, soft, off.length() * 2.6, true)
				draw_line(a, b, Color(1.0, 0.95, 0.8, al * 0.5), off.length() * 1.1, true)
