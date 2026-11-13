class_name TrackLayer
extends Node2D
## Traces de roues et de chenilles laissées par les véhicules dans le sable : elles s'estompent peu à peu.

const LIFE := 9.0      # secondes avant disparition complète
const MAX_SEGS := 900  # plafond de segments affichés (les plus anciens sont retirés)

var _segs: Array = []  # [a: Vector2, b: Vector2, perp: Vector2, t0: float, half_w: float]
var _t := 0.0


func _init() -> void:
	z_index = -9 # au-dessus du terrain, sous les bâtiments et les unités


func add(a: Vector2, b: Vector2, half_w: float) -> void:
	var d := b - a
	if d.length() < 0.5:
		return
	var perp := Vector2(-d.y, d.x).normalized()
	_segs.append([a, b, perp, _t, half_w])
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
		var col := Color(0.30, 0.18, 0.10, al)
		draw_line(a + off, b + off, col, 2.4, true)
		draw_line(a - off, b - off, col, 2.4, true)
		# bourrelet de sable clair au bord de chaque trace
		var rim := Color(1.0, 0.85, 0.6, al * 0.35)
		draw_line(a + off * 1.5, b + off * 1.5, rim, 1.2, true)
		draw_line(a - off * 1.5, b - off * 1.5, rim, 1.2, true)
