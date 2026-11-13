class_name Fx
## Effets visuels partagés : particules de poussière, rafales, réglages d'affichage.

static var _soft: GradientTexture2D


## Texture ronde et douce pour les particules.
static func soft_texture() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		g.offsets = PackedFloat32Array([0.0, 1.0])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 64
		t.height = 64
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_soft = t
	return _soft


## Émetteur continu (désactivé par défaut) : traînée de poussière, étincelles...
static func make_dust(color: Color, amount := 14, lifetime := 1.0, size := 0.5) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = soft_texture()
	p.amount = amount
	p.lifetime = lifetime
	p.emitting = false
	p.local_coords = false # les particules restent dans le monde : effet de traînée
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 28.0
	p.scale_amount_min = size
	p.scale_amount_max = size * 1.8
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(color.r, color.g, color.b, 0.55), Color(color.r, color.g, color.b, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	p.color_ramp = ramp
	p.show_behind_parent = true
	return p


## Explosion de particules ponctuelle, supprimée toute seule.
static func burst(parent: Node, pos: Vector2, color: Color, amount := 30, size := 1.0) -> void:
	var p := make_dust(color, amount, 1.2, size)
	p.one_shot = true
	p.explosiveness = 0.9
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 120.0
	p.show_behind_parent = false
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Petit impact d'arme : quelques particules discrètes et brèves, pour que la cible reste lisible.
static func impact(parent: Node, pos: Vector2, color: Color, amount := 3, size := 0.22) -> void:
	var c := Color(minf(color.r, 1.2), minf(color.g, 1.2), minf(color.b, 1.2))
	var p := make_dust(c, amount, 0.35, size)
	p.one_shot = true
	p.explosiveness = 1.0
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 40.0
	p.show_behind_parent = false
	p.position = pos
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(c.r, c.g, c.b, 0.4), Color(c.r, c.g, c.b, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	p.color_ramp = ramp
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Explosion : flamme HDR + fumée.
static func explosion(parent: Node, pos: Vector2, size := 1.0) -> void:
	var snd = parent.get("sfx")
	if snd != null:
		snd.play("boom_big" if size >= 2.0 else ("boom" if size >= 1.0 else "hit"), pos, -2.0)
	burst(parent, pos, Color(1.5, 0.8, 0.3), int(14 * size), size * 0.9)
	burst(parent, pos, Color(0.28, 0.24, 0.24), int(8 * size), size * 1.3)


## MSAA 2D + (option) rendu HDR avec bloom, pour toute scène.
static func setup_display(node: Node, glow: bool) -> void:
	var vp := node.get_viewport()
	vp.msaa_2d = Viewport.MSAA_4X
	if glow:
		vp.use_hdr_2d = true
		var env := Environment.new()
		env.background_mode = Environment.BG_CANVAS
		env.glow_enabled = true
		env.glow_intensity = 0.7
		env.glow_strength = 1.0
		env.glow_bloom = 0.0
		env.glow_hdr_threshold = 1.0
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		var we := WorldEnvironment.new()
		we.environment = env
		node.add_child(we)


## Impulsion au sol à l'endroit où l'on envoie des unités (clic droit) : anneaux qui s'étendent et s'effacent.
static func ground_pulse(parent: Node, pos: Vector2, color: Color = Color(0.4, 1.0, 0.7)) -> void:
	var n := GroundPulse.new()
	n.color = Color(minf(color.r, 1.3), minf(color.g, 1.3), minf(color.b, 1.3))
	n.position = pos
	n.z_index = 45
	parent.add_child(n)


class GroundPulse:
	extends Node2D
	const LIFE := 0.7
	var color := Color.WHITE
	var age := 0.0

	func _process(delta: float) -> void:
		age += delta
		if age >= LIFE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := age / LIFE
		var e := 1.0 - pow(1.0 - t, 3.0) # départ vif, fin douce
		for i in 2:
			var k := clampf(e - 0.22 * i, 0.0, 1.0)
			if k <= 0.0:
				continue
			var a := (1.0 - t) * (0.95 - 0.35 * i)
			var r := 6.0 + 24.0 * k
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color.r, color.g, color.b, a), 2.5 - 1.0 * i, true)
		draw_circle(Vector2.ZERO, 5.0 * (1.0 - e), Color(color.r, color.g, color.b, (1.0 - t) * 0.7))
