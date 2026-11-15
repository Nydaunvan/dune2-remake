shader_type spatial;
// Coque de véhicule « ultra HD » (cuisson des sprites) : panneaux de tôle, rivets, rayures, crasse, sable accumulé,
// liseré d'arête usé et assombrissement près du sol. Tout est procédural, calculé dans l'espace local de chaque pièce
// (le motif ne bouge donc pas quand le véhicule tourne). Utilisé seulement quand Models.hd est vrai.

uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float emit_energy = 0.0;  // > 0 : pièce lumineuse (pas de détails de tôle)
uniform float metallic = 0.45;
uniform float roughness = 0.5;
uniform vec3 half_ext = vec3(0.0); // demi-dimensions d'une pièce en boîte (0 = pas de liseré d'arête)
uniform float base_y = 0.0;        // hauteur du centre de la pièce dans le modèle
uniform float seed = 0.0;
uniform float panel = 9.5;         // taille d'un panneau de tôle (pixels du monde)
uniform float bump = 1.6;

varying vec3 lp;
varying vec3 ln;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
}

void fragment() {
	vec3 col = albedo.rgb;
	if (emit_energy > 0.0) {
		ALBEDO = col;
		EMISSION = col * emit_energy;
		ROUGHNESS = 0.4;
		METALLIC = 0.0;
	} else {
		vec3 an = abs(ln);
		vec2 uv;
		if (an.x > an.y && an.x > an.z) {
			uv = lp.zy;
		} else if (an.y > an.z) {
			uv = lp.xz;
		} else {
			uv = lp.xy;
		}
		uv += vec2(seed * 13.1, seed * 7.7);

		// Panneaux de tôle : rainures sur les joints, rivets aux croisements
		vec2 pc = uv / panel;
		vec2 f = fract(pc);
		vec2 dm = min(f, 1.0 - f) * panel;
		float dseam = min(dm.x, dm.y);
		float seam = 1.0 - smoothstep(0.0, 0.3, dseam);
		vec2 g = (fract(pc + 0.5) - 0.5) * panel;
		float rivet = smoothstep(0.55, 0.25, length(g)) * step(0.55, hash(floor(pc + 0.5) + seed * 1.7));
		float tone = hash(floor(pc) + seed);

		// Crasse, rayures, taches
		float n = vnoise(uv / 3.0) * 0.6 + vnoise(uv / 1.1) * 0.4;
		float scratch = smoothstep(0.82, 0.95, vnoise(vec2(uv.x * 2.4, uv.y / 7.0) + seed)) + smoothstep(0.84, 0.96, vnoise(vec2(uv.x / 7.0, uv.y * 2.4) + seed * 3.0));
		float stain = vnoise(uv / 9.0 + seed * 5.0);

		// Usure des arêtes (pièces en boîte)
		float edge = 0.0;
		if (half_ext.x > 0.0) {
			vec3 d = half_ext - abs(lp);
			float med = max(min(d.x, d.y), min(max(d.x, d.y), d.z));
			edge = 1.0 - smoothstep(0.0, 0.75, med);
		}

		// Hauteur dans le modèle : plus sombre près du sol, sable sur les faces horizontales basses
		float hy = base_y + lp.y;
		float ao = mix(0.7, 1.0, smoothstep(0.0, 10.0, hy));
		float dust = smoothstep(0.35, 0.95, ln.y) * (1.0 - smoothstep(3.0, 17.0, hy)) * smoothstep(0.3, 0.75, n);
		float dirt = (1.0 - smoothstep(0.0, 7.0, hy)) * (0.35 + 0.65 * n);

		col *= 0.94 + 0.12 * tone;                     // chaque panneau a sa teinte
		col *= 0.9 + 0.2 * n;                          // marbrure
		col *= 1.0 - seam * 0.3;                       // joints sombres
		col *= 1.0 - stain * 0.1;
		col = mix(col, col * vec3(0.55, 0.5, 0.45), dirt * 0.55); // poussière et boue basses
		col = mix(col, vec3(0.62, 0.45, 0.33), dust * 0.4);        // sable
		col = mix(col, mix(col, vec3(0.85, 0.87, 0.92), 0.55), edge * 0.8); // arêtes de métal nu
		col += vec3(0.5, 0.5, 0.55) * scratch * 0.1;
		col += vec3(0.4, 0.4, 0.45) * rivet * 0.25;
		col *= ao;

		// Relief des joints, rivets et rayures sans maillage (bump par dérivées d'écran)
		float h = -seam * 0.55 + rivet * 0.45 + (n - 0.5) * 0.14 - scratch * 0.05;
		vec3 sx = dFdx(VERTEX);
		vec3 sy = dFdy(VERTEX);
		float dbx = dFdx(h);
		float dby = dFdy(h);
		vec3 r1 = cross(sy, NORMAL);
		vec3 r2 = cross(NORMAL, sx);
		float det = dot(sx, r1);
		vec3 grad = sign(det) * (dbx * r1 + dby * r2);
		NORMAL = normalize(abs(det) * NORMAL - grad * bump);

		ALBEDO = col;
		METALLIC = clamp(metallic + edge * 0.3 - dirt * 0.25, 0.0, 1.0);
		ROUGHNESS = clamp(roughness + (n - 0.5) * 0.35 + seam * 0.25 + dirt * 0.3 - edge * 0.28 - rivet * 0.1, 0.12, 1.0);
	}
}
