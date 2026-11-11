shader_type canvas_item;
// Terrain Dune : sable rosé, plateaux rocheux fissurés, montagnes, épice.
// Le relief (hauteur + épice + minerai) vient d'une petite texture générée par le jeu ;
// tout le détail (grain, dunes, fissures, ombres, nuages) est calculé ici, sur GPU.

uniform sampler2D field : filter_linear, repeat_disable; // R = hauteur, G = épice, B = minerai
uniform vec2 world_size = vec2(2048.0, 2048.0);
uniform float tile = 32.0;
uniform float rock_h = 0.12;
uniform float mountain_h = 0.5;
uniform float spice_t = 0.35;
uniform float ore_t = 0.35;
uniform vec2 light_dir = vec2(0.7071, -0.7071); // direction de la lumière (haut-droite)

uniform vec3 sand_a : source_color = vec3(0.788, 0.502, 0.435);
uniform vec3 sand_b : source_color = vec3(0.898, 0.655, 0.561);
uniform vec3 spice_c : source_color = vec3(0.886, 0.463, 0.165);
uniform vec3 rock_a : source_color = vec3(0.353, 0.149, 0.125);
uniform vec3 rock_b : source_color = vec3(0.541, 0.275, 0.227);
uniform vec3 mount_c : source_color = vec3(0.165, 0.063, 0.055);
uniform vec3 shadow_c : source_color = vec3(0.165, 0.129, 0.322);
uniform vec3 rim_c : source_color = vec3(0.949, 0.604, 0.525);
uniform vec3 ore_c : source_color = vec3(0.55, 0.68, 0.90);

// Échantillonnage bicubique (B-spline) : supprime l'aspect « pixels » de la texture de relief
vec4 tex_bicubic(sampler2D tex, vec2 uv) {
	vec2 ts = vec2(textureSize(tex, 0));
	vec2 coord = uv * ts - 0.5;
	vec2 f = fract(coord);
	vec2 i = floor(coord);
	vec2 w0 = (1.0 - f) * (1.0 - f) * (1.0 - f) / 6.0;
	vec2 w1 = (4.0 - 6.0 * f * f + 3.0 * f * f * f) / 6.0;
	vec2 w2 = (1.0 + 3.0 * f + 3.0 * f * f - 3.0 * f * f * f) / 6.0;
	vec2 w3 = f * f * f / 6.0;
	vec2 g0 = w0 + w1;
	vec2 g1 = w2 + w3;
	vec2 h0 = (i + 0.5 - 1.0 + w1 / g0) / ts;
	vec2 h1 = (i + 0.5 + 1.0 + w3 / g1) / ts;
	vec4 a = mix(texture(tex, vec2(h0.x, h1.y)), texture(tex, vec2(h1.x, h1.y)), g1.x / (g0.x + g1.x));
	vec4 b = mix(texture(tex, vec2(h0.x, h0.y)), texture(tex, vec2(h1.x, h0.y)), g1.x / (g0.x + g1.x));
	return mix(a, b, g0.y / (g0.y + g1.y));
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
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

// Distances au premier et au second point de Voronoï : la différence dessine des fissures
vec2 voro(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = vec2(hash(n + g), hash(n + g + vec2(37.0, 17.0)));
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec2(d1, d2);
}

void fragment() {
	vec2 wp = UV * world_size; // pixels monde
	vec2 cp = wp / tile;       // coordonnées en cases
	vec2 px = 1.0 / vec2(textureSize(field, 0));
	vec3 fv = tex_bicubic(field, UV).rgb;
	// Bords organiques : un bruit fin déforme les contours plutôt que de laisser voir la grille
	float edge_n = (fbm(cp * 4.0 + 11.0) - 0.5) * 0.05 + (vnoise(cp * 11.0) - 0.5) * 0.015;
	float h = fv.r + edge_n;
	float sp = fv.g;
	float ore = fv.b;
	float aa = max(fwidth(h) * 1.2, 0.003);

	// Ombre portée : on remonte vers la lumière et on cherche un relief plus haut
	float lvl = rock_h;
	if (h > mountain_h) {
		lvl = 9.0;
	} else if (h > rock_h) {
		lvl = mountain_h;
	}
	float shadow = 0.0;
	for (int i = 1; i <= 8; i++) {
		float hh = texture(field, UV + light_dir * px * float(i) * 1.5).r;
		shadow = max(shadow, smoothstep(lvl, lvl + 0.04, hh) * (1.0 - float(i) / 9.0));
	}
	// Pente : les faces tournées vers la lumière sont plus claires
	float slope = texture(field, UV + light_dir * px * 3.0).r - texture(field, UV - light_dir * px * 3.0).r;

	float warp = fbm(cp * 0.7);
	// Trois matériaux calculés puis fondus avec des seuils adoucis (anti-aliasing des contours)
	float w_m = smoothstep(mountain_h - aa, mountain_h + aa, h);
	float w_r = smoothstep(rock_h - aa, rock_h + aa, h);

	// Sable / épice
	float d = fbm(cp * 0.9 + 3.0);
	float ripple = 0.5 + 0.5 * sin(dot(cp, vec2(0.45, 0.8)) * 5.0 + warp * 9.0);
	vec3 col_s = mix(sand_a, sand_b, d * 0.6 + ripple * 0.4);
	col_s *= 0.95 + 0.1 * vnoise(wp * 0.9);
	float sm = smoothstep(spice_t - 0.1, spice_t + 0.12, sp + (fbm(cp * 2.5) - 0.5) * 0.18);
	float pulse = 0.96 + 0.04 * sin(TIME * 1.6 + cp.x * 0.5 + cp.y * 0.3);
	col_s = mix(col_s, spice_c * pulse * (0.9 + 0.3 * vnoise(cp * 6.0)), sm * 0.9);
	col_s = mix(col_s, rim_c, (1.0 - smoothstep(0.0, 0.07, rock_h - h)) * 0.25);

	// Plateau rocheux
	float v = fbm(cp * 1.3 + warp);
	vec3 col_r = mix(rock_a, rock_b, v);
	vec2 vr = voro(cp * 0.85 + warp * 1.5);
	float crack = 1.0 - smoothstep(0.0, 0.09, vr.y - vr.x);
	col_r *= 1.0 - crack * 0.55;
	col_r *= 0.9 + 0.2 * vnoise(wp * 0.7);
	float om = smoothstep(ore_t - 0.08, ore_t + 0.1, ore + (fbm(cp * 3.0) - 0.5) * 0.2);
	vec2 sc = fract(cp * 12.0) - 0.5;
	float spark = smoothstep(0.22, 0.0, length(sc)) * step(0.94, hash(floor(cp * 12.0) + floor(TIME * 1.5)));
	col_r = mix(col_r, ore_c * (0.75 + 0.5 * vnoise(cp * 8.0)) + vec3(spark * 0.6), om * 0.85);
	col_r = mix(col_r, mount_c, smoothstep(mountain_h - 0.08, mountain_h, h) * 0.7);
	col_r = mix(col_r, rim_c, (1.0 - smoothstep(0.0, 0.05, h - rock_h)) * 0.5);
	col_r *= 1.0 - slope * 1.6;

	// Montagne
	float r = fbm(cp * 3.0 + warp * 2.0);
	float ridge = 1.0 - abs(2.0 * vnoise(cp * 2.2 + warp * 3.0) - 1.0);
	vec3 col_m = mix(mount_c, rock_a, r * 0.55 + ridge * 0.25);
	col_m = mix(col_m, rock_b, (1.0 - smoothstep(0.0, 0.06, h - mountain_h)) * 0.6);
	col_m *= 1.0 - slope * 2.5;

	vec3 col = mix(mix(col_s, col_r, w_r), col_m, w_m);

	col = mix(col, shadow_c, shadow * 0.62);

	// Ombres de nuages, très lentes
	float cloud = fbm(cp * 0.06 + vec2(TIME * 0.012, TIME * 0.006));
	col *= 0.9 + 0.2 * smoothstep(0.35, 0.7, cloud);

	COLOR = vec4(col, 1.0);
}
