shader_type canvas_item;
// Fond animé du menu : désert de dunes en couches (parallaxe), deux lunes, voie lactée,
// étoiles à halo et à croisillons, étoile filante, poussière portée par le vent.

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(37.7, 11.3)));
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

// Bruit 1D à interpolation quintique : pente continue, donc des courbes bien arrondies
float snoise(float x, float k) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(hash(vec2(i, k)), hash(vec2(i + 1.0, k)), f);
}

// Profil de dune : grandes ondulations lisses et rondes, crêtes adoucies
float dune(float x, float k) {
	float h = 0.66 * snoise(x * 0.75, k) + 0.28 * snoise(x * 1.5 + 5.0, k + 3.0) + 0.06 * snoise(x * 2.6 + 9.0, k + 7.0);
	// arrondit les sommets et étale les creux (dos de dune plus pleins)
	return h * h * (3.0 - 2.0 * h);
}

// Une étoile dans la cellule : halo gaussien, scintillement, teinte
vec3 star_layer(vec2 p, float scale, float density, float t, float seed) {
	vec2 g = p * scale;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id + seed);
	if (h < density) {
		return vec3(0.0);
	}
	vec2 o = (hash2(id + seed * 3.1) - 0.5) * 0.7;
	vec2 d = f - o;
	float sz = 0.035 + 0.07 * hash(id + seed * 5.3);
	float core = exp(-dot(d, d) / (sz * sz * 0.55));
	float halo = exp(-dot(d, d) / (sz * sz * 9.0)) * 0.22;
	float tw = 0.65 + 0.35 * sin(t * (1.5 + 4.0 * hash(id + 9.1)) + h * 40.0);
	// une étoile sur six « respire » lentement, une sur dix change légèrement de teinte
	float breathe = step(0.84, hash(id + seed * 11.0));
	tw *= mix(1.0, 0.45 + 0.75 * (0.5 + 0.5 * sin(t * 0.7 + h * 60.0)), breathe);
	float tint = hash(id + seed * 7.7);
	tint = clamp(tint + step(0.9, hash(id + seed * 13.0)) * 0.25 * sin(t * 0.5 + h * 30.0), 0.0, 1.0);
	vec3 c = mix(vec3(0.70, 0.82, 1.0), vec3(1.0, 0.86, 0.68), tint);
	return c * (core + halo) * tw * (0.55 + 0.9 * hash(id + 2.2));
}

// Étoile brillante à croisillons
vec3 flare_star(vec2 p, float scale, float t, float seed) {
	vec2 g = p * scale;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	if (hash(id + seed) < 0.82) {
		return vec3(0.0);
	}
	vec2 d = f - (hash2(id + seed * 2.3) - 0.5) * 0.5;
	float r = length(d);
	float tw = 0.7 + 0.3 * sin(t * 2.0 + hash(id) * 30.0);
	float core = exp(-r * r * 900.0);
	float glow = exp(-r * 22.0) * 0.35;
	float pulse = 0.55 + 0.45 * sin(t * 0.9 + hash(id + 3.0) * 20.0); // les croisillons s'allongent et se rétractent
	float cross = (exp(-abs(d.x) * 140.0) * exp(-abs(d.y) * (7.0 + 9.0 * (1.0 - pulse))) + exp(-abs(d.y) * 140.0) * exp(-abs(d.x) * (7.0 + 9.0 * (1.0 - pulse)))) * 0.7;
	return vec3(1.0, 0.95, 0.88) * (core + glow + cross) * tw;
}

vec3 moon(vec2 p, vec2 c, float r, vec3 lit, vec3 shade, vec3 halo_col, vec2 light_dir, float seed) {
	vec2 q = (p - c) / r;
	float l = length(q);
	vec3 res = halo_col * exp(-max(l - 1.0, 0.0) * 3.2) * 0.35 * smoothstep(3.0, 1.0, l);
	if (l < 1.0) {
		vec3 n = vec3(q, sqrt(1.0 - l * l));
		float diff = clamp(dot(n, normalize(vec3(light_dir, 0.55))), 0.0, 1.0);
		float cr = fbm(q * 3.5 + seed);
		float crater = smoothstep(0.35, 0.7, cr);
		vec3 surf = mix(shade, lit, smoothstep(0.0, 0.85, diff));
		surf *= 0.8 + 0.2 * crater;
		float rim = pow(1.0 - n.z, 3.0) * 0.35;
		res = mix(res, surf + halo_col * rim * diff, smoothstep(1.0, 0.985, l));
	}
	return res;
}

void fragment() {
	vec2 uv = UV;
	float ar = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = vec2(uv.x * ar, uv.y); // coordonnées à l'échelle correcte
	float t = TIME;
	float horizon = 0.56;

	// ----- Ciel : indigo profond -> mauve -> braise à l'horizon -----
	float h = clamp(uv.y / horizon, 0.0, 1.0);
	vec3 sky = mix(vec3(0.015, 0.012, 0.065), vec3(0.11, 0.045, 0.19), smoothstep(0.0, 0.55, h));
	sky = mix(sky, vec3(0.62, 0.21, 0.24), smoothstep(0.55, 0.92, h));
	sky = mix(sky, vec3(1.0, 0.58, 0.30), smoothstep(0.88, 1.0, h) * 0.85);

	// Voie lactée : bande diagonale poussiéreuse
	vec2 mw = vec2(p.x * 0.8 + 0.05, p.y) ;
	float line = (mw.y - 0.62 * mw.x * 0.9 + 0.08);
	float band = exp(-line * line * 28.0);
	float dust = fbm(p * 5.0 + vec2(t * 0.004, 0.0));
	float lane = smoothstep(0.42, 0.62, fbm(p * 9.0 + 4.0));
	vec3 milky = (vec3(0.30, 0.22, 0.55) * dust + vec3(0.65, 0.30, 0.45) * pow(dust, 3.0)) * band * (1.0 - 0.55 * lane);
	vec3 col = sky + milky * 0.55 * smoothstep(0.7, 0.2, h);

	// Étoiles : trois couches de profondeur, plus denses dans la voie lactée
	float fade = smoothstep(0.95, 0.35, h);
	vec3 stars = star_layer(p + vec2(t * 0.0006, 0.0), 55.0, 0.93 - band * 0.05, t, 1.0) * 0.9
			+ star_layer(p + vec2(t * 0.0006, 0.0) + 0.3, 105.0, 0.945 - band * 0.06, t, 2.0) * 0.75
			+ star_layer(p + vec2(t * 0.0006, 0.0) + 0.7, 190.0, 0.955 - band * 0.07, t, 3.0) * 0.6
			+ flare_star(p + vec2(t * 0.0006, 0.0), 9.0, t, 4.0) * 1.1
			+ flare_star(p + vec2(t * 0.0006, 0.0) + 0.4, 17.0, t, 5.0) * 0.8;
	col += stars * fade;

	// Étoile filante (toutes les ~9 s)
	float ph = fract(t / 9.0);
	if (ph < 0.09) {
		float k = ph / 0.09;
		vec2 a = vec2(0.95 * ar, 0.05);
		vec2 b = vec2(0.45 * ar, 0.33);
		vec2 head = mix(a, b, k);
		vec2 dir = normalize(b - a);
		vec2 rel = p - head;
		float along = -dot(rel, dir);
		float across = abs(dot(rel, vec2(-dir.y, dir.x)));
		float tail = step(0.0, along) * exp(-along * 22.0) * exp(-across * 520.0) * smoothstep(0.35, 0.0, along);
		float headg = exp(-dot(rel, rel) * 60000.0);
		col += vec3(1.0, 0.92, 0.8) * (tail + headg) * sin(k * 3.14159) * 1.3 * fade;
	}

	// Deux lunes : grande lune dorée et petite lune bleutée
	vec2 ld = normalize(vec2(0.8, 0.3));
	col += moon(p, vec2(0.115 * ar, 0.20), 0.07, vec3(1.0, 0.86, 0.66), vec3(0.18, 0.09, 0.16), vec3(1.0, 0.6, 0.4), ld, 3.0) * smoothstep(0.0, 0.05, horizon - uv.y);
	col += moon(p, vec2(0.265 * ar, 0.11), 0.02, vec3(0.78, 0.88, 1.0), vec3(0.08, 0.10, 0.2), vec3(0.5, 0.7, 1.0), ld, 11.0);

	// Lueur du soleil couché derrière les dunes
	vec2 sp = vec2((uv.x - 0.70) * ar, (uv.y - horizon) * 1.7);
	col += vec3(1.0, 0.55, 0.28) * 0.55 * exp(-length(sp) * 4.2);
	col += vec3(1.0, 0.82, 0.5) * 0.45 * exp(-length(sp) * 12.0);

	// ----- Dunes en couches, de la plus lointaine à la plus proche -----
	vec3 haze = vec3(0.85, 0.36, 0.30);
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		float depth = fi / 4.0; // 0 = lointain, 1 = premier plan
		float x = uv.x * (1.6 + depth * 1.8) * ar + fi * 3.7; // dunes immobiles : seul le vent bouge
		float base = horizon + 0.035 + depth * 0.40 - 0.02 * fi;
		float amp = 0.035 + 0.075 * depth;
		float ridge = base - amp * dune(x, fi * 5.0);
		float sc = (1.6 + depth * 1.8) * ar;
		float aa = SCREEN_PIXEL_SIZE.y * 1.6;
		if (uv.y > ridge - aa) {
			// éclairage : côté tourné vers le soleil (à droite) éclairé
			float below = uv.y - ridge;
			// pente lue en biais (l'ombre de la dune glisse le long de sa face, jamais de bande verticale)
			// et sur un large pas, pour un dégradé continu d'un bout à l'autre de la dune
			float xs = x - below * sc * 1.4;
			float e = 0.06;
			float slope = (dune(xs + e, fi * 5.0) - dune(xs - e, fi * 5.0)) / (2.0 * e) * amp * sc;
			float slope_lit = smoothstep(0.0, 1.0, clamp(0.5 + slope * 2.0, 0.0, 1.0));
			float lit = mix(0.55, slope_lit, exp(-below * (12.0 - 4.0 * depth)));
			vec3 shade_c = mix(vec3(0.24, 0.07, 0.13), vec3(0.10, 0.035, 0.08), depth);
			vec3 lit_c = mix(vec3(0.98, 0.54, 0.36), vec3(0.62, 0.27, 0.20), depth);
			vec3 sand = mix(shade_c, lit_c, lit);
			// ondulations du sable : rides larges, douces, qui suivent la dune
			// (les rides glissent très lentement avec le vent)
			float rip = vnoise(vec2(x * 9.0 + below * 4.0 - t * (0.05 + 0.08 * depth), below * (26.0 + 30.0 * depth)));
			sand *= 0.92 + 0.14 * rip;
			sand *= 0.985 + 0.03 * hash(floor(uv * vec2(900.0, 500.0)));
			// arête éclairée
			float rim = smoothstep(0.03 + 0.012 * depth, 0.0, below) * slope_lit * 0.75;
			sand += vec3(1.0, 0.72, 0.45) * rim * (0.5 + 0.4 * (1.0 - depth));
			// assombrissement vers le bas de l'écran (lisibilité de l'interface)
			sand *= mix(1.0, 0.45, smoothstep(0.62, 1.0, uv.y));
			// brume atmosphérique : forte au loin, faible au premier plan
			float fog = (1.0 - depth) * 0.62 + 0.04;
			fog *= exp(-below * 9.0) * 0.7 + 0.3;
			sand = mix(sand, haze * (0.6 + 0.4 * lit), clamp(fog, 0.0, 0.85));
			// panache de sable soulevé de la crête par le vent, qui file vers la gauche
			float plume = fbm(vec2(x * 5.0 + t * (0.55 + 0.5 * depth), below * 22.0 - t * 0.04));
			float plume_m = smoothstep(0.42, 0.8, plume) * exp(-below * (20.0 - 8.0 * depth)) * (0.5 + 0.5 * sin(t * 0.35 + fi * 2.0 + x * 1.7));
			sand += vec3(1.0, 0.66, 0.42) * plume_m * (0.20 + 0.16 * depth);
			col = mix(col, sand, smoothstep(ridge - aa, ridge + aa, uv.y));
		}
	}

	// Traînées de sable chassées par le vent sur les crêtes
	float wind = fbm(vec2(uv.x * 5.0 + t * 0.28, uv.y * 24.0 + sin(t * 0.2) * 0.6)) * smoothstep(0.55, 0.9, uv.y) * smoothstep(1.0, 0.7, uv.y);
	col += vec3(1.0, 0.7, 0.5) * pow(wind, 3.0) * 0.28;

	// Poussière en suspension : petits grains lumineux emportés par le vent
	vec2 dp = vec2(p.x * 38.0 - t * 1.4, uv.y * 26.0 - t * 0.12);
	vec2 did = floor(dp);
	vec2 df = fract(dp) - 0.5;
	float dr = hash(did);
	float mote = step(0.965, dr) * exp(-dot(df - (hash2(did) - 0.5) * 0.5, df - (hash2(did) - 0.5) * 0.5) * 70.0);
	col += vec3(1.0, 0.75, 0.5) * mote * smoothstep(0.5, 0.8, uv.y) * (0.5 + 0.5 * sin(t * 2.0 + dr * 50.0)) * 0.7;

	// Chaleur : léger voile au ras de l'horizon
	col += vec3(0.9, 0.4, 0.3) * 0.10 * exp(-abs(uv.y - horizon - 0.02) * 30.0);

	// Vignettage et grain de pellicule
	col *= 1.0 - 0.60 * pow(length((uv - 0.5) * vec2(1.0, 1.05)) * 1.15, 2.2);
	col += (hash(uv * 900.0 + fract(t)) - 0.5) * 0.018;
	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
