shader_type canvas_item;
// Panneau en verre dépoli : flou de l'arrière-plan, liseré néon animé,
// halo extérieur et lignes de balayage. Les valeurs > 1 alimentent le glow (HDR).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 rect_size = vec2(300.0, 300.0);
uniform float radius = 20.0;
uniform float margin = 0.0;       // marge réservée au halo extérieur
uniform vec4 accent_a : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform vec4 accent_b : source_color = vec4(1.0, 0.18, 0.65, 1.0);
uniform float border_w = 2.0;
uniform float glow = 1.0;
uniform float blur = 3.0;
uniform float tint = 0.62;

float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * rect_size - rect_size * 0.5;
	float d = sd_box(p, rect_size * 0.5 - vec2(margin), radius);
	float inside = 1.0 - smoothstep(-1.0, 1.0, d);

	vec3 blurred = textureLod(screen_tex, SCREEN_UV, blur).rgb;
	vec3 base = mix(vec3(0.04, 0.02, 0.09), vec3(0.12, 0.04, 0.18), UV.y);
	vec3 col = mix(blurred * 0.55, base, tint);
	col += (1.0 - UV.y) * 0.04;                                  // reflet en haut
	col += 0.012 * sin(UV.y * rect_size.y * 1.2 - TIME * 3.0);   // lignes de balayage

	float ang = atan(p.y, p.x);
	float t = 0.5 + 0.5 * sin(ang + TIME * 0.9);
	vec3 bc = mix(accent_a.rgb, accent_b.rgb, t);

	float edge = 1.0 - smoothstep(0.0, border_w, abs(d + border_w * 0.5));
	float inner = exp(d * 0.09) * step(d, 0.0);
	float outer = exp(-max(d, 0.0) * 0.22) * step(0.0, d);

	col += bc * inner * 0.22 * glow;
	col = mix(col, bc * (1.0 + 0.6 * glow), edge);
	col = mix(bc, col, inside);

	float a = inside * mix(0.88, 1.0, edge);
	a = max(a, outer * 0.35 * glow);
	COLOR = vec4(col, a);
}
