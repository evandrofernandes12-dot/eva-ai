shader_type spatial;
// Mar em volta da Ilha dos Orcs: ondas por soma de senos (sem textura), cor funda, reflexo do céu
// nas bordas (fresnel) e brilho do sol.
uniform vec4 funda : source_color = vec4(0.03, 0.16, 0.24, 1.0);
uniform vec4 rasa : source_color = vec4(0.1, 0.36, 0.42, 1.0);
uniform vec4 ceu : source_color = vec4(0.55, 0.7, 0.9, 1.0);
varying vec3 w;

void vertex() {
	w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME;
	float dx = cos(w.x * 0.35 + t * 1.3) * 0.35 + cos((w.x + w.z) * 0.9 + t * 1.9) * 0.15 + cos(w.x * 2.3 - t * 2.7) * 0.05;
	float dz = cos(w.z * 0.4 + t * 1.1) * 0.35 + cos((w.x + w.z) * 0.9 + t * 1.9) * 0.15 + cos(w.z * 2.1 + t * 2.4) * 0.05;
	vec3 n = normalize(vec3(-dx * 0.25, 1.0, -dz * 0.25));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float raso = 1.0 - smoothstep(0.0, 30.0, abs(w.x - 262.0));
	vec3 c = mix(funda.rgb, rasa.rgb, raso * 0.7);
	ALBEDO = mix(c, ceu.rgb, fres * 0.55);
	ROUGHNESS = 0.12;
	METALLIC = 0.0;
	SPECULAR = 0.7;
}
