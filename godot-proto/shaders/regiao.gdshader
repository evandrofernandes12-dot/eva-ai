shader_type spatial;
// Chão de uma região (neve, terra escura, areia...): disco com a borda recortada em ondas irregulares,
// textura em coordenadas do mundo (não estica) e manchas de tom para não repetir.
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 tom : source_color = vec4(1.0);
uniform float escala = 0.25;   // repetições da textura por metro
uniform float borda = 0.82;    // até aqui (fração do raio) é cheio; depois recorta com ruído
uniform float aspereza = 0.95;
varying vec3 w;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float lim = borda + (1.0 - borda) * (0.55 * ruido(w.xz * 0.04) + 0.45 * ruido(w.xz * 0.15));
	if (length(c) > lim) {
		discard;
	}
	vec2 uv = w.xz * escala;
	vec3 a = texture(tex, uv).rgb;
	vec3 b = texture(tex, uv * 0.27 + vec2(0.31, 0.17)).rgb;
	float m = ruido(w.xz * 0.06);
	ALBEDO = mix(a, b, 0.35) * tom.rgb * (0.82 + 0.36 * m);
	NORMAL_MAP = texture(tex_n, uv).rgb;
	ROUGHNESS = aspereza;
}
