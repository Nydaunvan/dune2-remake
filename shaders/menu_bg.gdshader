shader_type canvas_item;

uniform float time_offset = 0.0; // décalage du temps (captures d'écran de test)
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

// Carte de hauteur du désert : grandes dunes allongées, bords arrondis, légèrement asymétriques
float terrain(vec2 q) {
	vec2 w = q + 3.2 * vec2(vnoise(q * 0.045), vnoise(q * 0.045 + 7.3)) - 1.6;
	float n = 0.60 * vnoise(w * vec2(0.060, 0.105)) + 0.28 * vnoise(w * vec2(0.125, 0.21) + 3.1) + 0.12 * vnoise(w * vec2(0.26, 0.42) + 9.7);
	n = smoothstep(0.10, 0.92, n);
	return n * n * (3.0 - 2.0 * n) * 5.0;
}


// ---------------------------------------------------------------------------------------------
// Silhouettes de passage (véhicules qui traversent le désert, aéronef dans le ciel)
float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

mat2 rot2(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat2(vec2(c, s), vec2(-s, c));
}

// Distance signée d'un véhicule (repère local : x vers l'avant, y vers le haut, sol à y = 0)
float dot2(vec2 v) {
	return dot(v, v);
}

// Trapèze symétrique : demi-largeur r1 en bas (y = -he), r2 en haut (y = +he)
float sd_trap(vec2 p, float r1, float r2, float he) {
	vec2 k1 = vec2(r2, he);
	vec2 k2 = vec2(r2 - r1, 2.0 * he);
	p.x = abs(p.x);
	vec2 ca = vec2(p.x - min(p.x, (p.y < 0.0) ? r1 : r2), abs(p.y) - he);
	vec2 cb = p - k1 + k2 * clamp(dot(k1 - p, k2) / dot2(k2), 0.0, 1.0);
	float sg = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
	return sg * sqrt(min(dot2(ca), dot2(cb)));
}

float sd_vehicle(vec2 p, int kind) {
	if (kind == 0) { // char : silhouette anguleuse (chenilles biseautées, caisse et tourelle en trapèze)
		float d = sd_box(p - vec2(0.0, 0.13), vec2(0.74, 0.13), 0.015);                // chenilles
		d = max(d, (abs(p.x) - 0.74 + 0.12 - p.y) * 0.7071);                            // biseau des extrémités
		d = min(d, sd_trap(p - vec2(0.0, 0.37), 0.62, 0.46, 0.11));                    // caisse inclinée
		d = min(d, sd_trap(p - vec2(0.04, 0.60), 0.30, 0.17, 0.12));                   // tourelle à pans
		d = min(d, sd_box(p - vec2(0.68, 0.62), vec2(0.40, 0.03), 0.004));             // canon
		d = min(d, sd_box(p - vec2(1.06, 0.62), vec2(0.07, 0.05), 0.004));             // frein de bouche
		return d;
	}
	if (kind == 1) { // récolteur
		float d = sd_box(p - vec2(-0.05, 0.14), vec2(0.78, 0.14), 0.03);
		d = min(d, sd_box(p - vec2(-0.12, 0.50), vec2(0.52, 0.24), 0.02));             // cuve
		d = min(d, sd_box(p - vec2(0.58, 0.40), vec2(0.20, 0.18), 0.02));              // cabine
		d = min(d, length(p - vec2(0.88, 0.16)) - 0.16);                               // tambour
		return d;
	}
	// buggy rapide
	float d = sd_box(p - vec2(0.0, 0.30), vec2(0.42, 0.10), 0.05);
	d = min(d, sd_box(p - vec2(-0.08, 0.46), vec2(0.22, 0.08), 0.04));
	d = min(d, length(p - vec2(-0.30, 0.13)) - 0.13);
	d = min(d, length(p - vec2(0.30, 0.13)) - 0.13);
	return d;
}

// ----- Désert : champ de dunes, tracé de rayons sur une carte de hauteur ------------------------
// Renvoie la couleur ; `dist` = distance au sol touché (négatif si aucun).
vec3 desert(vec2 uv, float ar, float t, vec3 ro, out float dist_out) {
	float horizon = 0.56;
	vec3 rd = normalize(vec3((uv.x - 0.5) * ar * 0.85, -(uv.y - horizon) * 1.45 - 0.004, 1.0));
	float dist = 1.5;
	float prev = dist;
	bool hit = false;
	for (int i = 0; i < 110; i++) {
		vec3 p = ro + rd * dist;
		float d = p.y - terrain(p.xz);
		if (d < 0.004 + 0.0004 * dist) {
			hit = true;
			break;
		}
		prev = dist;
		dist += max(d * 0.5, 0.03 + 0.0025 * dist);
		if (dist > 160.0) {
			break;
		}
	}
	dist_out = -1.0;
	if (!hit) {
		return vec3(-1.0);
	}
	// Raffinage : dichotomie entre le dernier point au-dessus du sol et le point sous le sol.
	// Supprime l'effet d'escalier des courbes de niveau dû au pas du tracé de rayons.
	float lo = prev;
	float hi = dist;
	for (int k = 0; k < 7; k++) {
		float mid = 0.5 * (lo + hi);
		vec3 pm = ro + rd * mid;
		if (pm.y - terrain(pm.xz) > 0.0) {
			lo = mid;
		} else {
			hi = mid;
		}
	}
	dist = 0.5 * (lo + hi);
	dist_out = dist;
	vec3 p = ro + rd * dist;
	float e = 0.12 + 0.01 * dist;
	float hc = terrain(p.xz);
	vec3 n = normalize(vec3(terrain(p.xz - vec2(e, 0.0)) - terrain(p.xz + vec2(e, 0.0)), 2.0 * e,
			terrain(p.xz - vec2(0.0, e)) - terrain(p.xz + vec2(0.0, e))));
	// rides de sable : fines, perpendiculaires au vent, qui s'estompent avec la distance
	float rid_amp = 0.16 * exp(-dist * 0.05);
	float rid = vnoise(vec2(p.x * 1.6 + p.z * 0.5 + n.x * 4.0, p.z * 7.0));
	n = normalize(n + vec3(0.0, 0.0, (rid - 0.5) * rid_amp * 2.0));
	vec3 L = normalize(vec3(0.92, 0.20, 0.30));
	float lam = clamp(dot(n, L), 0.0, 1.0);
	float wrap = clamp((dot(n, L) + 0.35) / 1.35, 0.0, 1.0);
	vec3 shade_c = vec3(0.30, 0.12, 0.19);
	vec3 mid_c = vec3(0.80, 0.40, 0.27);
	vec3 lit_c = vec3(1.0, 0.70, 0.42);
	vec3 sand = mix(shade_c, mid_c, smoothstep(0.0, 0.55, wrap));
	sand = mix(sand, lit_c, smoothstep(0.45, 1.0, lam));
	// creux un peu plus sombres et rougeâtres, sommets plus clairs
	sand *= 0.80 + 0.26 * clamp(hc / 5.0, 0.0, 1.0);
	// reflet rasant orangé sur les crêtes qui regardent le soleil
	float rim = pow(clamp(1.0 - dot(n, -rd), 0.0, 1.0), 3.0);
	sand += vec3(1.0, 0.55, 0.28) * rim * 0.22 * smoothstep(0.1, 0.8, dot(n, L) + 0.4);
	// grains de sable
	sand *= 0.985 + 0.03 * hash(floor(uv * vec2(1400.0, 800.0)));
	// rafales : voiles de sable chassés le long des crêtes par le vent
	float crest = smoothstep(0.30, 0.75, 1.0 - n.y);
	float gust = vnoise(vec2(p.x * 0.22 - t * 1.3, p.z * 0.9 + sin(t * 0.3)));
	sand += vec3(1.0, 0.72, 0.46) * smoothstep(0.55, 0.95, gust) * crest * 0.20 * exp(-dist * 0.02);
	// brume : se fond dans la teinte exacte de l'horizon
	vec2 sp0 = vec2((uv.x - 0.70) * ar, 0.0);
	vec3 hz = vec3(0.943, 0.525, 0.291) + vec3(1.0, 0.55, 0.28) * 0.55 * exp(-length(sp0) * 4.2)
			+ vec3(1.0, 0.82, 0.5) * 0.45 * exp(-length(sp0) * 12.0);
	float fogk = 1.0 - exp(-dist * 0.016);
	sand = mix(sand, hz, clamp(fogk, 0.0, 1.0));
	// assombrissement doux vers le bas de l'écran (lisibilité de l'interface)
	sand *= mix(1.0, 0.70, smoothstep(0.66, 1.0, uv.y));
	return sand;
}

// Composition « over » (couleur non pré-multipliée)
vec4 over(vec4 dst, vec3 c, float a) {
	float na = a + dst.a * (1.0 - a);
	vec3 rgb = (c * a + dst.rgb * dst.a * (1.0 - a)) / max(na, 1e-4);
	return vec4(rgb, na);
}

// Passages : toutes les 40 s un événement différent — colonne de chars (0), récolteur escorté (1),
// buggy rapide (2) ou rien (3, 4). Les véhicules suivent le relief du sable
// et disparaissent derrière les buttes (test de profondeur contre le sol touché par le rayon).
vec4 walkers(vec2 uv, float ar, float t, vec3 ro, float terr, vec2 px) {
	float horizon = 0.56;
	float cyc = floor(t / 40.0);
	float ph = t - cyc * 40.0;
	int ev = int(hash(vec2(cyc, 5.1)) * 5.0);
	if (ev >= 3) {
		return vec4(0.0);
	}
	float dir = hash(vec2(cyc, 9.7)) > 0.5 ? 1.0 : -1.0;
	int n = ev == 0 ? 3 : (ev == 1 ? 2 : 1);
	float zc = ev == 0 ? 6.6 : (ev == 1 ? 7.4 : 6.2); // au premier plan : visible sous l'interface
	const float VS = 0.62;                          // échelle des silhouettes
	float dur = ev == 2 ? 15.0 : 30.0;
	float half_w = 0.5 * ar * 0.85 * zc + 3.0;
	vec4 res = vec4(0.0);
	for (int i = 0; i < 3; i++) {
		if (i >= n) {
			break;
		}
		float u = (ph - 2.0 - float(i) * 1.7) / dur;
		if (u < 0.0 || u > 1.0) {
			continue;
		}
		float x = dir * mix(-half_w, half_w, u);
		float z = zc + 0.5 * float(i % 2);
		float y = terrain(vec2(x, z));
		vec3 dv = vec3(x, y, z) - ro;
		float ux = 0.5 + (dv.x / dv.z) / (ar * 0.85);
		float uy = horizon - (dv.y / dv.z + 0.004) / 1.45;
		vec2 l = vec2((uv.x - ux) * ar * 0.85 * dv.z, -(uv.y - uy) * 1.45 * dv.z) / VS;
		if (abs(l.x) > 3.4 || l.y < -0.8 || l.y > 2.4) {
			continue;
		}
		float slope = (terrain(vec2(x + 0.5, z)) - terrain(vec2(x - 0.5, z)));
		float tilt = clamp(atan(slope), -0.6, 0.6);
		float udist = length(dv);
		// caché par une butte : le sol touché par le rayon est plus proche que le véhicule
		bool hidden = terr > 0.0 && terr < udist - 0.45;
		float aa = px.y * 1.45 * dv.z / VS;
		int kind = ev == 0 ? 0 : (ev == 1 ? (i == 0 ? 1 : 0) : 2);
		// poussière soulevée derrière le véhicule
		if (!hidden && u > 0.02 && u < 0.98) {
			for (int k = 0; k < 5; k++) {
				float fk = float(k);
				vec2 c = vec2(-dir * (0.9 + 0.5 * fk), 0.10 + 0.08 * fk + 0.04 * sin(t * 3.0 + fk * 2.0 + float(i)));
				float r = 0.17 + 0.07 * fk;
				float a = smoothstep(r, r * 0.2, length(l - c)) * 0.34 * (1.0 - fk / 5.0);
				res = over(res, vec3(1.0, 0.72, 0.50), a);
			}
		}
		vec2 p = rot2(-tilt) * l;
		p.x *= dir;
		p.y += 0.04;
		float d = sd_vehicle(p, kind);
		if (!hidden) {
			float a = smoothstep(aa, -aa, d);
			if (a > 0.0) {
				// éclairage rasant du couchant : liseré orangé côté soleil
				float e = 0.02;
				vec2 g = vec2(sd_vehicle(p + vec2(e, 0.0), kind) - sd_vehicle(p - vec2(e, 0.0), kind),
						sd_vehicle(p + vec2(0.0, e), kind) - sd_vehicle(p - vec2(0.0, e), kind));
				g = normalize(g + 1e-5);
				g.x *= dir;
				g = rot2(tilt) * g;
				float rimk = smoothstep(0.0, 0.9, dot(g, normalize(vec2(0.92, 0.35)))) * smoothstep(-0.12, 0.0, d);
				vec3 body = vec3(0.075, 0.04, 0.10) + vec3(1.0, 0.58, 0.30) * rimk * 0.85;
				// feu d'avant : petite lueur
				float lamp = exp(-dot(p - vec2(kind == 1 ? 0.62 : (kind == 2 ? 0.42 : 0.30), 0.50), p - vec2(kind == 1 ? 0.62 : (kind == 2 ? 0.42 : 0.30), 0.50)) * 90.0);
				body += vec3(1.0, 0.8, 0.5) * lamp * 0.8;
				body = mix(body, vec3(0.62, 0.32, 0.26), (1.0 - exp(-udist * 0.016)) * 0.55); // brume de distance
				res = over(res, body, a);
			}
		}
	}
	return res;
}

// Un échantillon du désert complet : sable, puis véhicule éventuel ; `sky` si le rayon ne touche rien.
vec3 desert_px(vec2 uv, float ar, float t, vec3 ro, vec3 sky, vec2 px, out float dist_out) {
	dist_out = -1.0;
	if (uv.y < 0.556) {
		return sky;
	}
	vec3 s = desert(uv, ar, t, ro, dist_out);
	vec3 c = s.x < 0.0 ? sky : s;
	vec4 w = walkers(uv, ar, t, ro, dist_out, px);
	return mix(c, w.rgb, w.a);
}

void fragment() {
	vec2 uv = UV;
	float ar = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = vec2(uv.x * ar, uv.y); // coordonnées à l'échelle correcte
	float t = TIME + time_offset;
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

	// ----- Désert (voir desert()) avec antialiasing adaptatif sur les arêtes ------------------
	// Un échantillon au centre ; là où la profondeur ou la couleur varient vite (crêtes, silhouettes),
	// on moyenne quatre échantillons sous-pixel : plus aucun effet d'escalier sur les dunes.
	if (uv.y >= horizon - 0.02) {
		vec2 px = SCREEN_PIXEL_SIZE;
		vec3 ro = vec3(0.0, 5.2, 0.0); // la scène est immobile : seul le vent anime le sable
		float dc;
		vec3 c0 = desert_px(uv, ar, t, ro, col, px, dc);
		vec3 fw = fwidth(c0);
		float edge = max(step(0.04, fwidth(dc) / max(abs(dc), 1.0)), step(0.05, max(fw.x, max(fw.y, fw.z))));
		if (edge > 0.5) {
			float d1;
			vec3 acc = desert_px(uv + px * vec2(-0.3, -0.1), ar, t, ro, col, px, d1);
			acc += desert_px(uv + px * vec2(0.1, -0.3), ar, t, ro, col, px, d1);
			acc += desert_px(uv + px * vec2(0.3, 0.1), ar, t, ro, col, px, d1);
			acc += desert_px(uv + px * vec2(-0.1, 0.3), ar, t, ro, col, px, d1);
			c0 = acc * 0.25;
		}
		col = c0;
	}

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
