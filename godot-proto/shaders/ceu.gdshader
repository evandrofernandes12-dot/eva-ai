shader_type sky;
// Céu com ciclo de dia e noite: degradê que muda com a altura do sol, sol com brilho, pôr do sol laranja,
// nuvens se movendo, lua com fases simples e estrelas piscando. As direções vêm do script (ceu.gd).
uniform vec3 sol_dir = vec3(0.0, 1.0, 0.0);    // aponta PARA o sol
uniform vec3 lua_dir = vec3(0.0, -1.0, 0.0);
uniform float chuva = 0.0;                      // 0..1: céu fechado e cinza
uniform float fase_lua = 1.0;                   // 1 = cheia
uniform float lua_grande = 0.0;                 // 1 = lua cheia gigante e dourada (noite dos lobisomens)
uniform sampler2D nuvens_tex : filter_linear_mipmap, repeat_enable;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = sol_dir.y;                                  // altura do sol (-1..1)
	float dia = smoothstep(-0.12, 0.25, h);
	float por = (1.0 - smoothstep(0.0, 0.35, abs(h + 0.03))) ;   // perto do horizonte
	// degradê: zênite e horizonte de dia, de noite e no pôr do sol
	vec3 zen = mix(vec3(0.01, 0.015, 0.05), vec3(0.18, 0.4, 0.82), dia);
	vec3 hor = mix(vec3(0.03, 0.05, 0.11), vec3(0.62, 0.78, 0.95), dia);
	float lado_sol = pow(max(dot(normalize(vec3(d.x, 0.0, d.z)), normalize(vec3(sol_dir.x, 0.0, sol_dir.z))), 0.0), 3.0);
	hor = mix(hor, vec3(1.0, 0.45, 0.18), por * (0.45 + 0.55 * lado_sol));
	zen = mix(zen, vec3(0.32, 0.25, 0.45), por * 0.5);
	float t = pow(1.0 - max(d.y, 0.0), 2.5);
	vec3 c = mix(zen, hor, t);
	if (d.y < 0.0) { c = hor * 0.85; }                    // abaixo do horizonte
	// estrelas (só de noite, sem chuva)
	float noite = 1.0 - smoothstep(-0.2, 0.05, h);
	vec3 cel = floor(d * 260.0);
	float s = hash(cel);
	float brilho = step(0.9975, s) * (0.6 + 0.4 * sin(TIME * (2.0 + s * 9.0) + s * 40.0));
	c += vec3(brilho) * noite * (1.0 - chuva) * smoothstep(0.0, 0.15, d.y);
	// sol: disco + halo
	float ds = dot(d, normalize(sol_dir));
	vec3 cor_sol = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.95, 0.85), smoothstep(0.0, 0.4, h));
	c += cor_sol * (smoothstep(0.9993, 0.9996, ds) * 6.0 + pow(max(ds, 0.0), 180.0) * 0.8 + pow(max(ds, 0.0), 12.0) * 0.18 * dia) * (1.0 - chuva * 0.9);
	// lua: disco com sombra de fase e halo azulado
	float dl = dot(d, normalize(lua_dir));
	float borda_lua = mix(0.9982, 0.9875, lua_grande);
	if (dl > borda_lua) {
		vec3 lado = normalize(cross(normalize(lua_dir), vec3(0.0, 1.0, 0.0)));
		float x = dot(d - normalize(lua_dir) * dl, lado) / mix(0.06, 0.158, lua_grande);   // -1..1 no disco
		float luz = smoothstep(-0.1, 0.1, x + 2.0 * fase_lua - 1.0);   // 1 = cheia, 0 = nova
		float mancha = 0.85 + 0.15 * hash(floor(d * 900.0));
		float mancha2 = 0.82 + 0.18 * hash(floor(d * 260.0));
		vec3 cor_lua = mix(vec3(0.92, 0.93, 0.88) * mancha, vec3(1.0, 0.86, 0.62) * mancha2, lua_grande);
		c = mix(c, cor_lua, smoothstep(borda_lua, borda_lua + 0.0004, dl) * max(luz, 0.08) * (1.0 - chuva * 0.8));
	}
	c += mix(vec3(0.5, 0.6, 0.8), vec3(1.0, 0.7, 0.4), lua_grande) * (pow(max(dl, 0.0), mix(300.0, 90.0, lua_grande)) * mix(0.6, 1.0, lua_grande) + pow(max(dl, 0.0), 40.0) * mix(0.12, 0.3, lua_grande)) * noite * (1.0 - chuva);   // halo
	// nuvens: textura de ruído projetada no céu, andando com o tempo
	if (d.y > 0.0) {
		vec2 uv = d.xz / (d.y + 0.15) * 0.25 + vec2(TIME * 0.004, TIME * 0.0015);
		float n = texture(nuvens_tex, uv).r * 0.65 + texture(nuvens_tex, uv * 2.7).r * 0.35;
		float cobre = mix(0.55, 0.12, chuva);
		float a = smoothstep(cobre, cobre + 0.25, n) * smoothstep(0.0, 0.2, d.y);
		vec3 cor_n = mix(vec3(0.07, 0.08, 0.11), vec3(1.0, 0.98, 0.95), dia);
		cor_n = mix(cor_n, vec3(1.0, 0.6, 0.4), por * 0.6);
		cor_n = mix(cor_n, cor_n * 0.45, chuva);
		c = mix(c, cor_n, a * mix(0.85, 1.0, chuva));
	}
	c = mix(c, mix(vec3(0.05, 0.055, 0.07), vec3(0.42, 0.44, 0.47), dia), chuva * 0.7);   // tempo fechado
	COLOR = c;
}
