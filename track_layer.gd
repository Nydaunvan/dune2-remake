class_name TrackLayer
extends Node2D
## Traces laissées dans le sable selon le mode de déplacement (chenilles, roues, coussin d'air, empreintes de mechas) :
## elles s'estompent peu à peu.

const LIFE := 9.0      # secondes avant disparition complète
const MAX_SEGS := 900  # plafond de segments affichés (les plus anciens sont retirés)

var _segs: Array = []  # [a: Vector2, b: Vector2, perp: Vector2, t0: float, half_w: float, kind: String]
var _t := 0.0


func _init() -> void:
	z_index = -9 # au-dessus du terrain, sous les bâtiments et les unités


var _step := 0          # alterne pied gauche / pied droit pour les marcheurs


func add(a: Vector2, b: Vector2, half_w: float, kind := "tracks") -> void:
	var d := b - a
	if d.length() < 0.5:
		return
	var perp := Vector2(-d.y, d.x).normalized()
	_step += 1
	_segs.append([a, b, perp, _t, half_w, kind, 1.0 if _step % 2 == 0 else -1.0])
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
			"legs_biped":
				# Mecha bipède : empreintes de pieds lourds, un pas sur deux, talon plus profond que la pointe
				var fwd := (b - a).normalized()
				var c: Vector2 = b + perp * float(s[6]) * off.length() * 1.15
				var dk := Color(0.26, 0.15, 0.08, al * 1.15)
				var heel := PackedVector2Array([c - fwd * 5.5 + perp * 3.0, c - fwd * 5.5 - perp * 3.0, c - fwd * 0.5 - perp * 3.4, c - fwd * 0.5 + perp * 3.4])
				var toe := PackedVector2Array([c - fwd * 0.5 + perp * 3.4, c - fwd * 0.5 - perp * 3.4, c + fwd * 4.5 - perp * 2.2, c + fwd * 4.5 + perp * 2.2])
				draw_colored_polygon(heel, dk)
				draw_colored_polygon(toe, Color(0.3, 0.18, 0.1, al))
				draw_line(c - fwd * 6.2 + perp * 3.4, c + fwd * 5.2 + perp * 2.6, Color(1.0, 0.85, 0.6, al * 0.45), 1.0, true) # bourrelet
			"legs_quad":
				# Quadrupède : quatre pattes en marche diagonale (avant gauche + arrière droite, puis l'inverse)
				var fq := (b - a).normalized()
				var sq: float = float(s[6])
				var wq: float = off.length() * 1.25
				var dq := Color(0.26, 0.15, 0.08, al * 1.15)
				var pr := [[6.0, sq], [-6.0, -sq]]
				for pw in pr:
					var cq: Vector2 = b + fq * float(pw[0]) + perp * float(pw[1]) * wq
					draw_circle(cq, 3.1, dq)
					draw_circle(cq + fq * 0.8, 1.9, Color(0.34, 0.2, 0.11, al))
					draw_line(cq - fq * 3.4 + perp * 2.0, cq + fq * 2.6 + perp * 2.6, Color(1.0, 0.85, 0.6, al * 0.4), 0.9, true)
			"legs_crystal":
				# Marcheur de cristal : pointes anguleuses (losanges) à peine enfoncées, avec un reflet violet
				var fwd2 := (b - a).normalized()
				var c2: Vector2 = b + perp * float(s[6]) * off.length() * 1.2
				var dia := PackedVector2Array([c2 + fwd2 * 6.0, c2 + perp * 3.4, c2 - fwd2 * 5.0, c2 - perp * 3.4])
				draw_colored_polygon(dia, Color(0.2, 0.12, 0.2, al * 1.1))
				draw_line(c2 + fwd2 * 6.0, c2 - fwd2 * 5.0, Color(0.85, 0.6, 1.0, al * 0.55), 1.1, true)
				draw_line(c2 + perp * 3.4, c2 - perp * 3.4, Color(0.85, 0.6, 1.0, al * 0.3), 0.9, true)
			"legs_spider":
				# Arachnide : six minuscules piqûres (trois paires de pattes), dessinées en éventail
				var fwd3 := (b - a).normalized()
				var col3 := Color(0.25, 0.14, 0.08, al * 1.1)
				for row in [-5.0, 0.0, 5.0]:
					for sd in [-1.0, 1.0]:
						var q: Vector2 = b + fwd3 * row + perp * sd * (off.length() * 1.5 + abs(row) * 0.25)
						draw_circle(q, 1.1, col3)
						draw_line(q, q + perp * sd * 1.6 - fwd3 * 0.6, Color(1.0, 0.85, 0.6, al * 0.35), 0.8, true)
