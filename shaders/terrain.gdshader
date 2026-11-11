shader_type canvas_item;
// Terrain Dune : sable rosé, plateaux rocheux fissurés, montagnes, épice.
// Le relief (hauteur + épice) vient d'une petite texture générée par le jeu ;
// tout le détail (grain, dunes, fissures, ombres, nuages) est calculé ici, sur GPU.

uniform sampler2D field : filter_linear, repeat_disable; // R = hauteur, G = épice
uniform vec2 world_size = vec2(2048.0, 2048.0);
uniform float tile = 32.0;
uniform float rock_h = 0.12;
uniform float mountain_h = 0.5;
uniform float spice_t = 0.35;
uniform vec2 light_dir = vec2(0.7071, -0.7071); // direction de la lumière (haut-droite)

uniform vec3 sand_a : source_color = vec3(0.788, 0.502, 0.435);
uniform vec3 sand_b : source_color = vec3(0.898, 0.655, 0.561);
uniform vec3 spice_c : source_color = vec3(0.886, 0.463, 0.165);
uniform vec3 rock_a : source_color = vec3(0.353, 0.149, 0.125);
uniform vec3 rock_b : source_color = vec3(0.541, 0.275, 0.227);
uniform vec3 mount_c : source_color = vec3(0.165, 0.063, 0.055);
uniform vec3 shadow_c : source_color = vec3(0.165, 0.129, 0.322);
uniform vec3 rim_c : source_color = vec3(0.949, 0.604, 0.525);

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
	vec2 fv = texture(field, UV).rg;
	float h = fv.r;
	float sp = fv.g;

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
	vec3 col = vec3(0.0);

	if (h > mountain_h) {
		float r = fbm(cp * 3.0 + warp * 2.0);
		float ridge = 1.0 - abs(2.0 * vnoise(cp * 2.2 + warp * 3.0) - 1.0);
		col = mix(mount_c, rock_a, r * 0.55 + ridge * 0.25);
		col = mix(col, rock_b, (1.0 - smoothstep(0.0, 0.06, h - mountain_h)) * 0.6);
		col *= 1.0 - slope * 2.5;
	} else if (h > rock_h) {
		float v = fbm(cp * 1.3 + warp);
		col = mix(rock_a, rock_b, v);
		vec2 vr = voro(cp * 0.85 + warp * 1.5);
		float crack = 1.0 - smoothstep(0.0, 0.09, vr.y - vr.x);
		col *= 1.0 - crack * 0.55;
		col *= 0.9 + 0.2 * vnoise(wp * 0.7);
		col = mix(col, mount_c, smoothstep(mountain_h - 0.08, mountain_h, h) * 0.7);
		float rim = 1.0 - smoothstep(0.0, 0.05, h - rock_h);
		col = mix(col, rim_c, rim * 0.5);
		col *= 1.0 - slope * 1.6;
	} else {
		float d = fbm(cp * 0.9 + 3.0);
		float ripple = 0.5 + 0.5 * sin(dot(cp, vec2(0.45, 0.8)) * 5.0 + warp * 9.0);
		col = mix(sand_a, sand_b, d * 0.6 + ripple * 0.4);
		col *= 0.95 + 0.1 * vnoise(wp * 0.9);
		float sm = smoothstep(spice_t - 0.1, spice_t + 0.12, sp + (fbm(cp * 2.5) - 0.5) * 0.18);
		float pulse = 0.96 + 0.04 * sin(TIME * 1.6 + cp.x * 0.5 + cp.y * 0.3);
		col = mix(col, spice_c * pulse * (0.9 + 0.3 * vnoise(cp * 6.0)), sm * 0.9);
		col = mix(col, rim_c, (1.0 - smoothstep(0.0, 0.07, rock_h - h)) * 0.25); // halo au pied des plateaux
	}

	col = mix(col, shadow_c, shadow * 0.62);

	// Ombres de nuages, très lentes
	float cloud = fbm(cp * 0.06 + vec2(TIME * 0.012, TIME * 0.006));
	col *= 0.9 + 0.2 * smoothstep(0.35, 0.7, cloud);

	COLOR = vec4(col, 1.0);
}
