shader_type spatial;
// Rebentação na areia: a espuma sobe a praia e volta, com a borda irregular (ruído) e a areia molhada.
// modo 0: costa reta (distância = x - linha); modo 1: ilha (distância = raio - linha).
render_mode cull_disabled, depth_draw_never;
uniform int modo = 0;
uniform float linha = 265.0;
uniform vec2 centro = vec2(560.0, 0.0);
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
varying vec3 w;

void vertex() {
	w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = modo == 0 ? (w.x - linha) : (length(w.xz - centro) - linha);   // > 0 do lado do mar
	float t = TIME;
	float along = modo == 0 ? w.z : atan(w.z - centro.y, w.x - centro.x) * 130.0;
	float n = texture(ruido, vec2(along * 0.015, 0.37)).r;          // borda irregular, mas suave
	float n2 = texture(ruido, w.xz * 0.6 + vec2(t * 0.05, 0.0)).r;  // bolhas da espuma
	float ciclo = 0.5 + 0.5 * sin(t * 0.7 + along * 0.003);
	float frente = -2.6 * ciclo + (n - 0.5) * 0.7;                  // até onde a água sobe na areia
	float agua = smoothstep(frente - 0.05, frente + 0.35, d);        // película de água sobre a areia
	float borda = (1.0 - smoothstep(0.0, 0.22, abs(d - frente))) * smoothstep(0.35, 0.55, n2 + 0.1);
	float bolhas = agua * smoothstep(0.62, 0.78, n2) * (1.0 - smoothstep(0.0, 2.5, d - frente));
	float esp = clamp(borda * 0.9 + bolhas * 0.6, 0.0, 1.0);
	float molhado = smoothstep(-3.0, frente, d) * (1.0 - agua);      // areia escura onde a onda acabou de passar
	vec3 cor_agua = vec3(0.35, 0.62, 0.62);
	ALBEDO = mix(mix(vec3(0.38, 0.32, 0.22), cor_agua, agua), vec3(0.95, 0.97, 0.98), esp);
	ALPHA = clamp(max(esp, max(agua * 0.35, molhado * 0.28)), 0.0, 0.9) * (1.0 - smoothstep(1.5, 3.0, d));
	ROUGHNESS = 0.35;
}
