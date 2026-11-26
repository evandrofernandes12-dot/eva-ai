shader_type spatial;
// Mar em volta da Ilha dos Orcs: ondas grandes (o plano sobe e desce), ondinhas (dois mapas de relevo
// andando), cor funda/rasa, reflexo do céu nas bordas (fresnel), cristas brancas no mar aberto e faixas
// de espuma chegando na praia (perto da costa e da ilha).
render_mode cull_disabled;
uniform vec4 funda : source_color = vec4(0.02, 0.15, 0.24, 1.0);
uniform vec4 rasa : source_color = vec4(0.1, 0.42, 0.45, 1.0);
uniform vec4 ceu : source_color = vec4(0.55, 0.7, 0.9, 1.0);
uniform sampler2D ondinhas : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform float costa_x = 265.0;          // onde a água encontra a areia na costa da aldeia
uniform vec2 ilha_c = vec2(560.0, 0.0);
uniform float ilha_r = 129.5;           // raio onde a água encontra a areia da ilha
varying vec3 w;

float onda(vec2 p, float t) {
	return sin(p.x * 0.11 + t * 0.9) * 0.22 + sin((p.x * 0.6 + p.y) * 0.085 + t * 1.25) * 0.16 + sin(p.y * 0.19 - t * 1.05) * 0.08;
}
float costa(vec2 p) {
	return min(p.x - costa_x, length(p - ilha_c) - ilha_r);
}

void vertex() {
	w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float perto = smoothstep(0.0, 30.0, costa(w.xz));
	VERTEX.y += onda(w.xz, TIME) * mix(0.35, 1.0, perto);
}

void fragment() {
	float t = TIME;
	vec2 p = w.xz;
	float d = costa(p);
	// normal das ondas grandes
	float e = 0.6;
	float hx = (onda(p + vec2(e, 0.0), t) - onda(p - vec2(e, 0.0), t)) / (2.0 * e);
	float hz = (onda(p + vec2(0.0, e), t) - onda(p - vec2(0.0, e), t)) / (2.0 * e);
	vec3 n = normalize(vec3(-hx, 1.0, -hz));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	// ondinhas
	vec3 n1 = texture(ondinhas, p * 0.045 + vec2(t * 0.012, t * 0.008)).rgb;
	vec3 n2 = texture(ondinhas, p * 0.11 - vec2(t * 0.02, -t * 0.015)).rgb;
	NORMAL_MAP = normalize(mix(n1, n2, 0.5) * 2.0 - 1.0) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.9;
	float raso = 1.0 - smoothstep(0.0, 40.0, d);
	vec3 c = mix(funda.rgb, rasa.rgb, raso * 0.8);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	c = mix(c, ceu.rgb, fres * 0.5);
	// espuma: faixas que andam em direção à praia + espuma grudada na beira + cristas no mar aberto
	float rn = texture(ruido, p * 0.09 + vec2(t * 0.015, 0.0)).r;
	float rn2 = texture(ruido, p * 0.31 - vec2(0.0, t * 0.03)).r;
	float fase = fract(d * 0.1 - t * 0.22);
	float banda = smoothstep(0.0, 0.06, fase) * (1.0 - smoothstep(0.06, 0.28, fase));
	float perto = 1.0 - smoothstep(1.0, 24.0, d);
	float beira = 1.0 - smoothstep(0.0, 3.0, d);
	float crista = smoothstep(0.32, 0.46, onda(p, t)) * smoothstep(0.55, 0.8, rn2) * (1.0 - perto);
	float esp = clamp(banda * perto * 1.3 + beira, 0.0, 1.0) * smoothstep(0.3, 0.6, rn * 0.6 + rn2 * 0.6) + crista * 0.6;
	esp = clamp(esp, 0.0, 1.0);
	ALBEDO = mix(c, vec3(0.93, 0.96, 0.98), esp * 0.9);
	ROUGHNESS = mix(0.06, 0.65, esp);
	SPECULAR = 0.75;
}
