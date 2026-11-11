shader_type canvas_item;
// Fond animé du menu : désert au crépuscule, dunes mouvantes, étoiles, soleil bas.

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.7);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = vec2(uv.x * 3.2, uv.y * 1.8);
	float d = fbm(p * 1.5 + vec2(TIME * 0.02, 0.0));
	float band = 0.5 + 0.5 * sin((p.x * 0.6 + p.y * 1.4) * 3.0 + d * 6.0 + TIME * 0.1);

	vec3 sky = mix(vec3(0.05, 0.02, 0.10), vec3(0.50, 0.18, 0.22), smoothstep(0.0, 0.55, uv.y));
	vec3 dune = mix(vec3(0.30, 0.09, 0.12), vec3(0.80, 0.40, 0.34), band * 0.6 + d * 0.4);
	float horizon = 0.50 + 0.05 * sin(uv.x * 7.0 + d * 3.0);
	vec3 col = mix(sky, dune, smoothstep(horizon - 0.01, horizon + 0.01, uv.y));

	// Soleil bas et halo
	col += vec3(1.0, 0.5, 0.3) * 0.30 * exp(-length((uv - vec2(0.72, 0.48)) * vec2(1.0, 2.4)) * 5.0);

	// Étoiles scintillantes dans le ciel
	float st = step(0.996, hash(floor(uv * vec2(420.0, 240.0)))) * (1.0 - smoothstep(0.0, 0.42, uv.y));
	col += st * (0.6 + 0.4 * sin(TIME * 3.0 + uv.x * 60.0));

	// Vignettage
	col *= 1.0 - 0.55 * pow(length(uv - 0.5) * 1.15, 2.0);
	COLOR = vec4(col, 1.0);
}
