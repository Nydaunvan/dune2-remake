shader_type canvas_item;
global uniform float gamma_fix; // 1.0 en Compatibilité, 2.2 en Forward+/Mobile (le moteur re-convertit alors la sortie en sRGB)
// Terrain Dune « ultra HD » : sable rosé rippé, plateaux rocheux stratifiés et fissurés, montagnes crêtées, épice.
// Le relief (hauteur + épice + minerai) vient d'une texture générée par le jeu ; tout le détail est calculé ici,
// sur GPU, en pixels monde : il reste net à tous les zooms et s'estompe (LOD) quand il deviendrait plus petit
// qu'un pixel d'écran, ce qui évite le scintillement.

uniform sampler2D field : filter_linear, repeat_disable; // R = hauteur, G = épice, B = minerai
uniform vec2 world_size = vec2(2048.0, 2048.0);
uniform float tile = 32.0;
uniform float rock_h = 0.12;
uniform float mountain_h = 0.5;
uniform float spice_t = 0.35;
uniform float ore_t = 0.35;
uniform vec2 light_dir = vec2(0.7071, -0.7071); // direction de la lumière (haut-droite)
uniform float detail : hint_range(0.0, 1.0) = 1.0; // 0 = rendu léger, 1 = rendu complet

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
	// hachage sans motif visible, même pour de grandes coordonnées (monde de plusieurs milliers de pixels)
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
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

float fbm3(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p = p * 2.07 + vec2(5.3, 11.9);
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

// Visibilité d'un détail de longueur d'onde wl (pixels monde) : 1 quand il fait plus de ~3 pixels d'écran, 0 sous ~1
float vis(float wl, float pw) {
	return smoothstep(1.0, 3.2, wl / pw);
}

// Micro-relief (pixels monde) : rides de sable, strates de roche, crêtes de montagne. Sert à calculer la lumière.
float micro(vec2 wp, float pw, float w_r, float w_m, vec2 wv, float rz) {
	float hs = 0.0;
	float hr = 0.0;
	float hm = 0.0;
	if (w_r < 0.999) {
		// grandes dunes, rides de vent et fines rides : phases gauchies par le bruit (lignes courbes, jamais parallèles),
		// avec une pente douce et une pente raide ; des zones rippées alternent avec des zones lisses
		float ph3 = dot(wp, vec2(0.5, 0.86)) / 27.0 + wv.y * 15.0;
		float dune = sin(ph3) + 0.35 * sin(2.0 * ph3 + 0.7);
		float ph = dot(wp, vec2(0.62, 0.78)) / 7.0 + wv.x * 22.0;
		float rip = sin(ph) + 0.3 * sin(2.0 * ph + 1.3);
		float amp = 0.25 + 0.75 * smoothstep(0.35, 0.65, wv.y);
		float ph2 = dot(wp, vec2(0.78, -0.62)) / 2.6 + wv.x * 9.0 + wv.y * 6.0;
		float fine = sin(ph2) * vis(16.0, pw) * amp;
		float grain = (vnoise(wp / 1.7) - 0.5) * vis(3.4, pw) + (vnoise(wp / 0.8) - 0.5) * vis(1.6, pw);
		// rz = zone rippée (grande échelle) : hors de ces zones le sable est presque lisse, sans rides ni grandes dunes
		hs = dune * 1.2 * (0.12 + 0.88 * rz) + rip * 0.5 * amp * rz * vis(44.0, pw) + fine * 0.12 * rz + grain * (0.045 + 0.055 * rz);
	}
	if (w_r > 0.001 && w_m < 0.999) {
		float st = sin(wp.y / 5.5 + wv.x * 11.0 + vnoise(wp / 26.0) * 4.0);
		hr = st * 0.28 * vis(34.0, pw) + (vnoise(wp / 3.0) - 0.5) * 0.28 * vis(6.0, pw) + (vnoise(wp / 1.3) - 0.5) * 0.12 * vis(2.6, pw);
	}
	if (w_m > 0.001) {
		float rd = 1.0 - abs(2.0 * vnoise(wp / 9.0 + wv * 3.0) - 1.0);
		hm = rd * 0.9 + (vnoise(wp / 3.2) - 0.5) * 0.3 * vis(6.4, pw) + (vnoise(wp / 1.4) - 0.5) * 0.12 * vis(2.8, pw);
	}
	return mix(mix(hs, hr, w_r), hm, w_m);
}

void fragment() {
	vec2 wp = UV * world_size; // pixels monde
	vec2 cp = wp / tile;       // coordonnées en cases
	float pw = max(0.2, 0.5 * (length(dFdx(wp)) + length(dFdy(wp)))); // pixels monde par pixel d'écran
	float dt = detail;
	vec2 px = 1.0 / vec2(textureSize(field, 0));
	vec3 fv = tex_bicubic(field, UV).rgb;
	// Bords organiques : trois fréquences de bruit déforment les contours plutôt que de laisser voir la grille
	float edge_n = (fbm(cp * 4.0 + 11.0) - 0.5) * 0.05 + (vnoise(cp * 11.0) - 0.5) * 0.015;
	edge_n += (vnoise(wp / 3.0 + 5.0) - 0.5) * 0.012 * vis(6.0, pw) * dt;
	float h = fv.r + edge_n;
	float sp = fv.g;
	float ore = fv.b;
	float aa = max(fwidth(h) * 1.2, 0.003);

	// Niveau de référence pour les ombres et l'occlusion
	float lvl = rock_h;
	if (h > mountain_h) {
		lvl = 9.0;
	} else if (h > rock_h) {
		lvl = mountain_h;
	}
	// Ombre portée : on remonte vers la lumière et on cherche un relief plus haut ; trois rayons légèrement
	// écartés donnent une pénombre douce au lieu d'un bord net
	float shadow = 0.0;
	for (int k = -1; k <= 1; k++) {
		float ca = cos(float(k) * 0.09);
		float sa = sin(float(k) * 0.09);
		vec2 ld = vec2(light_dir.x * ca - light_dir.y * sa, light_dir.x * sa + light_dir.y * ca);
		float sk = 0.0;
		for (int i = 1; i <= 9; i++) {
			float hh = texture(field, UV + ld * px * float(i) * 1.6).r;
			sk = max(sk, smoothstep(lvl, lvl + 0.05, hh) * (1.0 - float(i) / 11.0));
		}
		shadow += sk * 0.3333;
	}
	// Occlusion ambiante : le pied des falaises et le fond des cuvettes sont plus sombres
	float occ = 0.0;
	if (dt > 0.3) {
		for (int k = 0; k < 4; k++) {
			float a = float(k) * 1.5708 + 0.785;
			vec2 o = vec2(cos(a), sin(a)) * px * 3.5;
			occ += smoothstep(lvl, lvl + 0.05, texture(field, UV + o).r);
		}
		occ *= 0.25;
	}
	// Pente : les faces tournées vers la lumière sont plus claires
	float slope = texture(field, UV + light_dir * px * 3.0).r - texture(field, UV - light_dir * px * 3.0).r;

	float warp = fbm(cp * 0.7);
	vec2 wv = vec2(fbm3(cp * 0.45 + 7.0), fbm3(cp * 0.45 + 31.0)); // gauchissement des rides
	float rz = smoothstep(0.47, 0.6, fbm3(cp * 0.17 + 21.0)); // zones de sable rippé (≈ un tiers de la carte)
	// Trois matériaux calculés puis fondus avec des seuils adoucis (anti-aliasing des contours)
	float w_m = smoothstep(mountain_h - aa, mountain_h + aa, h);
	float w_r = smoothstep(rock_h - aa, rock_h + aa, h);

	// Micro-relief et normale (différences finies de 1 pixel monde) -> éclairage fin
	vec3 L = normalize(vec3(light_dir.x, light_dir.y, 0.75));
	float lit = 0.0;
	if (dt > 0.05) {
		float e = max(1.0, pw * 0.6);
		float m0 = micro(wp, pw, w_r, w_m, wv, rz);
		float mx = micro(wp + vec2(e, 0.0), pw, w_r, w_m, wv, rz);
		float my = micro(wp + vec2(0.0, e), pw, w_r, w_m, wv, rz);
		float str = mix(3.0, 2.4, w_r) + 1.4 * w_m;
		vec3 n = normalize(vec3((m0 - mx) / e * str, (m0 - my) / e * str, 1.0));
		lit = (dot(n, L) - L.z) * dt;
		lit += (m0 - 0.2) * 0.05 * dt; // les creux sont un peu plus sombres, les bosses plus claires
	}

	vec3 col_s = vec3(0.0);
	vec3 col_r = vec3(0.0);
	vec3 col_m = vec3(0.0);
	float sm = 0.0;

	// --- Sable / épice -----------------------------------------------------------
	if (w_r < 0.999) {
		float d = fbm(cp * 0.9 + 3.0);
		float ripple = 0.5 + 0.5 * sin(dot(cp, vec2(0.45, 0.8)) * 5.0 + warp * 9.0);
		col_s = mix(sand_a, sand_b, d * 0.6 + ripple * 0.4 * (0.25 + 0.75 * rz));
		col_s *= 0.93 + 0.14 * fbm3(cp * 0.2 + 50.0);          // grandes plaques plus claires ou plus sombres
		col_s *= 0.95 + 0.1 * vnoise(wp * 0.9);
		col_s = mix(col_s, col_s * vec3(1.06, 0.97, 0.9), smoothstep(0.45, 0.8, vnoise(cp * 0.8 + 90.0))); // veines plus chaudes
		sm = smoothstep(spice_t - 0.1, spice_t + 0.12, sp + (fbm(cp * 2.5) - 0.5) * 0.18);
		if (sm > 0.001) {
			float pulse = 0.96 + 0.04 * sin(TIME * 1.6 + cp.x * 0.5 + cp.y * 0.3);
			vec3 spice_col = spice_c * pulse * (0.9 + 0.3 * vnoise(cp * 6.0));
			spice_col *= 0.92 + 0.16 * vnoise(wp / 2.2) * vis(4.4, pw);   // grains d'épice
			spice_col = mix(spice_col, spice_col * vec3(1.15, 1.0, 0.7), smoothstep(0.55, 0.9, fbm3(cp * 2.2 + 70.0)) * 0.6);
			if (dt > 0.3) {
				// paillettes d'épice : quelques grains brillants, discrets, qui scintillent lentement
				vec2 gcell = floor(wp / 3.0);
				float gl = step(0.985, hash(gcell)) * (0.5 + 0.5 * sin(TIME * 2.0 + hash(gcell + 3.0) * 6.28)) * vis(6.0, pw);
				gl *= smoothstep(0.5, 0.1, length(fract(wp / 3.0) - 0.5)); // grain rond
				spice_col += vec3(1.0, 0.8, 0.45) * gl * 0.35;
			}
			col_s = mix(col_s, spice_col, sm * 0.92);
		}
		col_s = mix(col_s, rim_c, (1.0 - smoothstep(0.0, 0.07, rock_h - h)) * 0.25);
		if (dt > 0.3) {
			// petits cailloux épars et grains clairs sur le sable
			vec2 vc = voro(wp / 9.0);
			float peb = smoothstep(0.2, 0.08, vc.x) * step(0.88, hash(floor(wp / 9.0) + 13.0)) * vis(9.0, pw);
			col_s = mix(col_s, rock_b * 0.85, peb * 0.5 * (1.0 - sm));
			float talus = (1.0 - smoothstep(0.0, 0.16, rock_h - h)) * (1.0 - w_r);
			col_s = mix(col_s, rock_b * 0.7, talus * peb * 0.5);
			float sparkle = step(0.9965, hash(floor(wp / 1.5) + 21.0)) * vis(3.0, pw) * smoothstep(0.5, 0.1, length(fract(wp / 1.5) - 0.5));
			col_s += vec3(0.5, 0.42, 0.34) * sparkle * 0.5;
		}
	}

	// --- Plateau rocheux -----------------------------------------------------------
	if (w_r > 0.001 && w_m < 0.999) {
		float v = fbm(cp * 1.3 + warp);
		col_r = mix(rock_a, rock_b, v);
		// strates horizontales ondulées
		float strata = 0.5 + 0.5 * sin(wp.y / 5.5 + wv.x * 11.0 + vnoise(wp / 26.0) * 4.0);
		col_r *= mix(1.0, 0.82 + 0.3 * strata, vis(34.0, pw) * 0.7);
		vec2 vr = voro(cp * 0.85 + warp * 1.5);
		float crack = 1.0 - smoothstep(0.0, 0.09, vr.y - vr.x);
		col_r *= 1.0 - crack * 0.55;
		if (dt > 0.3) {
			// fissures fines, plus petites, et blocs
			vec2 vr2 = voro(wp / 11.0 + warp * 2.0);
			float crack2 = 1.0 - smoothstep(0.0, 0.07, vr2.y - vr2.x);
			col_r *= 1.0 - crack2 * 0.38 * vis(11.0, pw);
			col_r *= 0.93 + 0.14 * hash(floor(wp / 11.0) + floor(vr2.x * 3.0) * 0.1); // chaque bloc a sa teinte
		}
		col_r *= 0.9 + 0.2 * vnoise(wp * 0.7);
		col_r *= 0.94 + 0.12 * vnoise(wp / 1.5) * vis(3.0, pw);
		float om = smoothstep(ore_t - 0.08, ore_t + 0.1, ore + (fbm(cp * 3.0) - 0.5) * 0.2);
		if (om > 0.001) {
			vec2 sc = fract(cp * 12.0) - 0.5;
			float spark = 0.0; // scintillement du minerai retiré
			vec3 ore_col = ore_c * (0.75 + 0.5 * vnoise(cp * 8.0)) + vec3(spark * 0.6);
			if (dt > 0.3) {
				// éclats de cristal : chaque facette a sa clarté, les arêtes brillent
				vec2 vo = voro(wp / 8.0);
				float edge = 1.0 - smoothstep(0.0, 0.1, vo.y - vo.x);
				ore_col *= (0.82 + 0.36 * hash(floor(wp / 8.0 + vo.x * 2.7) + 5.0)) * mix(1.0, 0.8 + 0.5 * edge, vis(8.0, pw));
			}
			ore_col *= 0.92 + 0.16 * vnoise(wp / 2.0) * vis(4.0, pw);
			col_r = mix(col_r, ore_col, om * 0.85);
		}
		col_r = mix(col_r, mount_c, smoothstep(mountain_h - 0.08, mountain_h, h) * 0.7);
		col_r = mix(col_r, rim_c, (1.0 - smoothstep(0.0, 0.05, h - rock_h)) * 0.5);
		col_r *= 1.0 - slope * 1.6;
	}

	// --- Montagne ------------------------------------------------------------------
	if (w_m > 0.001) {
		float r = fbm(cp * 3.0 + warp * 2.0);
		float ridge = 1.0 - abs(2.0 * vnoise(cp * 2.2 + warp * 3.0) - 1.0);
		col_m = mix(mount_c, rock_a, r * 0.55 + ridge * 0.25);
		float ridge2 = 1.0 - abs(2.0 * vnoise(wp / 7.0 + wv * 4.0) - 1.0);
		col_m = mix(col_m, rock_b * 0.85, smoothstep(0.65, 1.0, ridge2) * 0.5 * vis(7.0, pw)); // arêtes éclairées
		if (dt > 0.3) {
			// facettes rocheuses et failles
			vec2 vm = voro(wp / 16.0 + wv * 1.5);
			float fault = 1.0 - smoothstep(0.0, 0.08, vm.y - vm.x);
			col_m *= 1.0 - fault * 0.5 * vis(16.0, pw);
			col_m *= 0.82 + 0.36 * hash(floor(wp / 16.0 + vm.x * 1.3) + 9.0);
		}
		col_m = mix(col_m, rock_b, (1.0 - smoothstep(0.0, 0.06, h - mountain_h)) * 0.6);
		col_m *= 0.92 + 0.16 * vnoise(wp / 2.0) * vis(4.0, pw);
		col_m *= 1.0 - slope * 2.5;
	}

	vec3 col = mix(mix(col_s, col_r, w_r), col_m, w_m);

	// Éclairage fin du micro-relief, puis occlusion et ombres portées
	col *= 1.0 + lit * 0.95;
	col *= 1.0 - occ * 0.22 * (1.0 - w_m);
	col = mix(col, shadow_c, shadow * 0.62);

	// Ombres de nuages, très lentes
	float cloud = fbm(cp * 0.06 + vec2(TIME * 0.012, TIME * 0.006));
	col *= 0.9 + 0.2 * smoothstep(0.35, 0.7, cloud);

	COLOR = vec4(pow(max(col, vec3(0.0)), vec3(gamma_fix)), 1.0);
}
