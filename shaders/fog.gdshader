shader_type canvas_item;
global uniform float gamma_fix; // 1.0 en Compatibilité, 2.2 en Forward+/Mobile (le moteur re-convertit alors la sortie en sRGB)
// Brouillard de guerre : la texture (une valeur par case) vaut 0 = visible,
// ~0.55 = exploré, 1 = inconnu. L'interpolation donne des bords doux.
uniform sampler2D fog : filter_linear, repeat_disable;

void fragment() {
	float f = texture(fog, UV).r;
	float shade = smoothstep(0.0, 1.0, f);
	COLOR = vec4(pow(vec3(0.04, 0.015, 0.08), vec3(gamma_fix)), shade * 0.94);
}
