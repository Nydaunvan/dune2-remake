shader_type canvas_item;
// Panneau moderne : fond sombre légèrement translucide aux coins arrondis, filet clair de 1 px.
// Aucun halo, aucun balayage : l'interface reste lisible et sobre au-dessus du jeu.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 rect_size = vec2(300.0, 300.0);
uniform float radius = 10.0;
uniform float margin = 0.0;
uniform vec4 fill : source_color = vec4(0.078, 0.055, 0.05, 1.0);
uniform vec4 border : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fill_alpha = 0.86;
uniform float border_alpha = 0.16;
uniform float border_w = 1.0;
uniform float blur = 2.0;

float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * rect_size - rect_size * 0.5;
	vec2 hb = rect_size * 0.5 - vec2(margin);
	float d = sd_box(p, hb, radius);
	float inside = 1.0 - smoothstep(-0.75, 0.75, d);
	float edge = 1.0 - smoothstep(0.0, border_w, abs(d + border_w * 0.5));
	vec3 blurred = textureLod(screen_tex, SCREEN_UV, blur).rgb;
	vec3 col = mix(blurred * 0.35, fill.rgb, 0.8);
	col = mix(col, border.rgb, edge * border_alpha);
	float a = inside * mix(fill_alpha, 1.0, edge * border_alpha * 2.0);
	COLOR = vec4(col, a);
}
