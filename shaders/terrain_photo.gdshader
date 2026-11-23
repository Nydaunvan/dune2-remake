shader_type canvas_item;
global uniform float gamma_fix; // 1.0 en Compatibilité, 2.2 en Forward+/Mobile (le moteur re-convertit alors la sortie en sRGB)
// Terrain Dune « photo » : matériaux photographiques (sable, roche, épice, minerai) mélangés selon le relief du jeu.
// Même relief, mêmes ombres portées et occlusion que le terrain HD ; la couleur et le micro-relief viennent des textures.
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

uniform sampler2D sand_fine_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_fine_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_crust_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_crust_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_strata_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_strata_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_dark_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_dark_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D spice_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D spice_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ore_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ore_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float sand_scale = 640.0;   // taille d'une tuile en pixels monde
uniform float rock_scale = 520.0;
uniform float mount_scale = 560.0;
uniform float spice_scale = 480.0;
uniform float ore_scale = 300.0;
uniform float tex_relief = 1.0;     // force du relief des textures
uniform float tex_exposure = 1.0;
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

// Échantillon de matériau sans répétition visible : deux lectures (échelle et rotation différentes) fondues par un bruit lent.
// Renvoie l'albédo (rgb) + AO (a), et remplit n (xy de la normale, hauteur dans z).
vec4 mat_sample(sampler2D ta, sampler2D tn, vec2 wp, float sc, out vec3 n) {
	vec2 u1 = wp / sc;
	vec2 u2 = vec2(wp.x * 0.8 - wp.y * 0.6, wp.x * 0.6 + wp.y * 0.8) / (sc * 0.83) + 0.37;
	float m = smoothstep(0.32, 0.68, vnoise(wp / (sc * 1.9) + 3.0));
	vec4 a = mix(texture(ta, u1), texture(ta, u2), m);
	vec3 n1 = texture(tn, u1).rgb;
	vec3 n2 = texture(tn, u2).rgb;
	// la normale de la 2e lecture est tournée avec les coordonnées
	n2.xy = vec2((n2.x * 2.0 - 1.0) * 0.8 - (n2.y * 2.0 - 1.0) * 0.6, (n2.x * 2.0 - 1.0) * 0.6 + (n2.y * 2.0 - 1.0) * 0.8) * 0.5 + 0.5;
	n = mix(n1, n2, m);
	return a;
}

// Normale d'écran (y vers le bas) à partir de la normale GL de la texture
vec3 to_screen_normal(vec3 n, float k) {
	return normalize(vec3((n.x * 2.0 - 1.0) * k, -(n.y * 2.0 - 1.0) * k, 1.0));
}

// Visibilité d'un détail de longueur d'onde wl (pixels monde) : 1 quand il fait plus de ~3 pixels d'écran, 0 sous ~1
float vis(float wl, float pw) {
	return smoothstep(1.0, 3.2, wl / pw);
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

	vec3 L = normalize(vec3(light_dir.x, light_dir.y, 0.75));
	vec3 col_s = vec3(0.0);
	vec3 col_r = vec3(0.0);
	vec3 col_m = vec3(0.0);
	float sm = 0.0;
	float lit_s = 0.0;
	float lit_r = 0.0;
	float lit_m = 0.0;
	vec3 tn;

	// --- Sable / épice -----------------------------------------------------------
	if (w_r < 0.999) {
		vec3 n1;
		vec4 a1 = mat_sample(sand_fine_a, sand_fine_n, wp, sand_scale, n1);
		float cm = smoothstep(0.42, 0.62, fbm3(cp * 0.12 + 5.0)) * 0.85; // zones de sable croûté
		vec3 n2 = n1;
		vec4 a2 = a1;
		if (cm > 0.01) {
			a2 = mat_sample(sand_crust_a, sand_crust_n, wp, sand_scale * 0.9, n2);
		}
		vec4 sa = mix(a1, a2, cm);
		tn = mix(n1, n2, cm);
		col_s = sa.rgb * mix(1.0, sa.a, 0.7);
		col_s *= vec3(1.02, 0.98, 0.95) * (0.94 + 0.12 * fbm3(cp * 0.2 + 50.0)); // grandes plaques plus claires ou plus sombres
		lit_s = dot(to_screen_normal(tn, tex_relief), L) - L.z;
		sm = smoothstep(spice_t - 0.1, spice_t + 0.12, sp + (fbm(cp * 2.5) - 0.5) * 0.18);
		if (sm > 0.001) {
			vec3 ns;
			vec4 sp_a = mat_sample(spice_a, spice_n, wp, spice_scale, ns);
			float pulse = 0.96 + 0.04 * sin(TIME * 1.6 + cp.x * 0.5 + cp.y * 0.3);
			vec3 spice_col = sp_a.rgb * mix(1.0, sp_a.a, 0.6) * pulse;
			if (dt > 0.3) {
				// paillettes d'épice : quelques grains brillants, discrets, qui scintillent lentement
				vec2 gcell = floor(wp / 3.0);
				float gl = step(0.985, hash(gcell)) * (0.5 + 0.5 * sin(TIME * 2.0 + hash(gcell + 3.0) * 6.28)) * vis(6.0, pw);
				gl *= smoothstep(0.5, 0.1, length(fract(wp / 3.0) - 0.5)); // grain rond
				spice_col += vec3(1.0, 0.8, 0.45) * gl * 0.35;
			}
			col_s = mix(col_s, spice_col, sm * 0.95);
			lit_s = mix(lit_s, dot(to_screen_normal(ns, tex_relief), L) - L.z, sm);
		}
		col_s = mix(col_s, rim_c, (1.0 - smoothstep(0.0, 0.07, rock_h - h)) * 0.12);
	}

	// --- Plateau rocheux -----------------------------------------------------------
	if (w_r > 0.001 && w_m < 0.999) {
		vec3 nr;
		vec4 ra = mat_sample(rock_strata_a, rock_strata_n, wp, rock_scale, nr);
		col_r = ra.rgb * mix(1.0, ra.a, 0.8);
		col_r *= 0.9 + 0.2 * fbm3(cp * 0.35 + 13.0);
		lit_r = dot(to_screen_normal(nr, tex_relief), L) - L.z;
		float om = smoothstep(ore_t - 0.08, ore_t + 0.1, ore + (fbm(cp * 3.0) - 0.5) * 0.2);
		if (om > 0.001) {
			vec3 no;
			vec4 oa = mat_sample(ore_a, ore_n, wp, ore_scale, no);
			vec3 ore_col = oa.rgb * mix(1.0, oa.a, 0.6) * vec3(0.78, 0.98, 1.35);
			float spark = 0.0; // scintillement du minerai retiré
			ore_col += vec3(0.5, 0.8, 1.0) * spark * 0.5;
			col_r = mix(col_r, ore_col, om * 0.9);
			lit_r = mix(lit_r, dot(to_screen_normal(no, tex_relief), L) - L.z, om);
		}
		col_r = mix(col_r, col_r * mount_c * 4.0, smoothstep(mountain_h - 0.08, mountain_h, h) * 0.5);
		col_r = mix(col_r, rim_c * 0.8, (1.0 - smoothstep(0.0, 0.05, h - rock_h)) * 0.18);
		col_r *= 1.0 - slope * 1.6;
	}

	// --- Montagne ------------------------------------------------------------------
	if (w_m > 0.001) {
		vec3 nm;
		vec4 ma = mat_sample(rock_dark_a, rock_dark_n, wp, mount_scale, nm);
		col_m = ma.rgb * mix(1.0, ma.a, 0.8) * 1.15;
		col_m *= 0.85 + 0.3 * fbm3(cp * 0.5 + 29.0);
		lit_m = dot(to_screen_normal(nm, tex_relief * 1.4), L) - L.z;
		col_m = mix(col_m, col_m * 1.6, (1.0 - smoothstep(0.0, 0.06, h - mountain_h)) * 0.35); // arête éclairée
		col_m *= 1.0 - slope * 2.5;
	}

	float lit = mix(mix(lit_s, lit_r, w_r), lit_m, w_m) * dt;
	vec3 col = mix(mix(col_s, col_r, w_r), col_m, w_m);

	// Éclairage fin du micro-relief, puis occlusion et ombres portées
	col *= tex_exposure * (1.0 + lit * 1.1);
	col *= 1.0 - occ * 0.22 * (1.0 - w_m);
	col = mix(col, shadow_c, shadow * 0.62);

	// Ombres de nuages, très lentes
	float cloud = fbm(cp * 0.06 + vec2(TIME * 0.012, TIME * 0.006));
	col *= 0.9 + 0.2 * smoothstep(0.35, 0.7, cloud);

	COLOR = vec4(pow(max(col, vec3(0.0)), vec3(gamma_fix)), 1.0);
}
