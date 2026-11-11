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
