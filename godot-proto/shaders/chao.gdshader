shader_type spatial;
// Grama do chão sem o padrão repetido: mistura a textura em duas escalas e varia o tom em manchas grandes.
uniform sampler2D grama : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tom : source_color = vec4(0.62, 0.8, 0.5, 1.0);
uniform float escala = 60.0;

void fragment() {
	vec2 uv = UV * escala;
	vec3 a = texture(grama, uv).rgb;
	vec3 b = texture(grama, uv * 0.27 + vec2(0.31, 0.17)).rgb;
	float n = texture(grama, UV * 2.3).g;
	ALBEDO = mix(a, b, 0.45) * tom.rgb * (0.82 + 0.36 * n);
	ROUGHNESS = 1.0;
}
