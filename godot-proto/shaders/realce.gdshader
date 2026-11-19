shader_type spatial;
// Realce de contorno (luz de borda) por cima do material normal: destaca o herói e o chefe na cena.
render_mode blend_add, unshaded, cull_back, depth_draw_never;
uniform vec4 cor : source_color = vec4(1.0, 0.85, 0.6, 1.0);
uniform float forca = 0.45;

void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = cor.rgb * f * forca;
}
