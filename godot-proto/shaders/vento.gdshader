shader_type spatial;
// Vento nas árvores, arbustos e plantas: a copa balança, o tronco (perto do chão) fica parado. Barato: só mexe nos vértices.
// Folhas com recorte (alpha scissor) e casca com relevo (normal map), como nos modelos Quaternius.
render_mode cull_disabled;
uniform vec4 cor : source_color = vec4(1.0);
uniform sampler2D textura : source_color, hint_default_white, filter_linear_mipmap;
uniform bool usa_textura = false;
uniform sampler2D relevo : hint_normal, filter_linear_mipmap;
uniform bool usa_relevo = false;
uniform bool recorta = false;      // folhas: descarta os pixels transparentes da textura
uniform float corte = 0.5;
uniform float rugosidade = 0.85;
uniform float forca = 0.12;   // balanço no topo, em metros
uniform float altura = 6.0;   // altura em que o balanço chega ao máximo

void vertex() {
	vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = clamp((mundo.y - NODE_POSITION_WORLD.y) / altura, 0.0, 1.0);
	float t = TIME * 1.3 + NODE_POSITION_WORLD.x * 0.37 + NODE_POSITION_WORLD.z * 0.23;
	vec3 desl = vec3(sin(t), 0.0, cos(t * 0.8)) * forca * h * h;
	desl += vec3(sin(t * 3.1 + mundo.x * 2.0), 0.0, cos(t * 2.7 + mundo.z * 2.0)) * forca * 0.15 * h;   // folhas tremem
	VERTEX += (inverse(MODEL_MATRIX) * vec4(desl, 0.0)).xyz;
}

void fragment() {
	vec4 c = cor;
	if (usa_textura) {
		c *= texture(textura, UV);
	}
	ALBEDO = c.rgb;
	if (recorta) {
		ALPHA = c.a;
		ALPHA_SCISSOR_THRESHOLD = corte;
	}
	if (usa_relevo) {
		NORMAL_MAP = texture(relevo, UV).rgb;
	}
	ROUGHNESS = rugosidade;
}
