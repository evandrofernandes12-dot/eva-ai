shader_type spatial;
// Chão PBR (ambientCG, CC0): grama Grass001 com manchas de terra Ground037, cor + relevo + rugosidade.
// A grama é amostrada em duas escalas e varia de tom em manchas grandes, para não aparecer o padrão repetido.
uniform sampler2D grama : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grama_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D grama_r : hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform sampler2D terra : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D terra_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D manchas : filter_linear_mipmap, repeat_enable;   // ruído: onde aparece terra
uniform vec4 tom : source_color = vec4(0.85, 0.95, 0.8, 1.0);
uniform float escala = 90.0;        // repetições da grama no plano inteiro
uniform float terra_qtd = 0.32;     // 0 = só grama; 1 = muita terra

void fragment() {
	vec2 uv = UV * escala;
	vec3 a = texture(grama, uv).rgb;
	vec3 b = texture(grama, uv * 0.31 + vec2(0.37, 0.11)).rgb;
	float n = texture(manchas, UV * 3.0).r;
	float v = texture(manchas, UV * 11.0 + 0.5).r;
	vec3 g = mix(a, b, 0.4) * tom.rgb * (0.85 + 0.3 * v);
	vec3 t = texture(terra, uv * 0.7).rgb;
	float k = smoothstep(1.0 - terra_qtd, 1.0 - terra_qtd + 0.12, n);
	ALBEDO = mix(g, t, k);
	NORMAL_MAP = mix(texture(grama_n, uv).rgb, texture(terra_n, uv * 0.7).rgb, k);
	ROUGHNESS = mix(texture(grama_r, uv).g, 0.95, k);
}
