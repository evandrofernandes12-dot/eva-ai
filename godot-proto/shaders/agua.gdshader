shader_type spatial;
// Água do lago: ondinhas (duas camadas de ruído andando), cor rasa na beira e funda no meio,
// reflexo do céu nas bordas (fresnel), brilho do sol e da lua (especular) e espuma leve na margem.
// UV.x = 0 na margem, 1 no centro (montado em lago.gd).
render_mode cull_disabled;
uniform sampler2D ondas : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 rasa : source_color = vec4(0.22, 0.42, 0.4, 1.0);
uniform vec4 funda : source_color = vec4(0.03, 0.11, 0.15, 1.0);
uniform vec4 ceu : source_color = vec4(0.55, 0.7, 0.9, 1.0);   // atualizada pelo ciclo de dia e noite
uniform float escuro = 0.0;                                    // 0 dia, 1 noite
varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(mundo.x * 0.7 + TIME * 1.1) * 0.015 + cos(mundo.z * 0.9 + TIME * 0.9) * 0.015;
}

void fragment() {
	vec2 uv = mundo.xz * 0.12;
	vec3 n1 = texture(ondas, uv + vec2(TIME * 0.02, TIME * 0.013)).rgb;
	vec3 n2 = texture(ondas, uv * 1.7 - vec2(TIME * 0.017, -TIME * 0.021)).rgb;
	NORMAL_MAP = normalize(mix(n1, n2, 0.5) * 2.0 - 1.0) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.6;
	float prof = smoothstep(0.0, 0.7, UV.x);
	vec3 c = mix(rasa.rgb, funda.rgb, prof);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	c = mix(c, ceu.rgb * mix(1.0, 0.25, escuro), fres * 0.65);
	float espuma = (1.0 - smoothstep(0.0, 0.06, UV.x)) * smoothstep(0.45, 0.6, n1.r);
	c = mix(c, vec3(0.85, 0.9, 0.92) * mix(1.0, 0.3, escuro), espuma * 0.7);
	ALBEDO = c;
	ROUGHNESS = 0.06;
	METALLIC = 0.0;
	SPECULAR = 0.9;
}
