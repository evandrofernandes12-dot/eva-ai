shader_type spatial;
// Montanha de neve: rocha embaixo e nas encostas íngremes, neve em cima (pela altura e pela inclinação).
uniform sampler2D rocha : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D neve : source_color, filter_linear_mipmap, repeat_enable;
uniform float neve_de = 0.28;   // fração da altura onde a neve começa
uniform float altura = 60.0;
varying vec3 w;
varying vec3 nl;

void vertex() {
	w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	nl = NORMAL;
}

void fragment() {
	vec2 uv = vec2(w.x + w.z, w.y) * 0.08;
	vec3 r = texture(rocha, uv).rgb * 0.9;
	vec3 s = texture(neve, w.xz * 0.06).rgb * 1.05;
	float faixa = sin(w.x * 0.3) * sin(w.z * 0.27) * 0.08;
	float k = smoothstep(neve_de - 0.06, neve_de + 0.04, w.y / altura + faixa);
	ALBEDO = mix(r, s, k);
	ROUGHNESS = mix(0.95, 0.7, k);
}
