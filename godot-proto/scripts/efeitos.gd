class_name Efeitos
## Shaders do jogo, usados só onde mais aparecem (para não pesar no tablet):
## vento nas árvores e arbustos, realce de contorno no herói e no chefe, e grama do chão sem repetição.

const VENTO := preload("res://shaders/vento.gdshader")
const REALCE := preload("res://shaders/realce.gdshader")
const CHAO := preload("res://shaders/chao.gdshader")

static var _vento := {}   # material original -> ShaderMaterial de vento (compartilhado entre as árvores iguais)

## Troca os materiais do modelo por versões com vento (mesma cor e textura).
static func vento(raiz: Node, forca: float, altura: float) -> void:
	var malhas: Array = []
	Fit._collect(raiz, malhas)
	for mi: MeshInstance3D in malhas:
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if not (m is BaseMaterial3D):
				continue
			var chave := "%d_%.2f" % [m.get_instance_id(), forca]
			if not _vento.has(chave):
				var bm := m as BaseMaterial3D
				var sm := ShaderMaterial.new()
				sm.shader = VENTO
				sm.set_shader_parameter("cor", bm.albedo_color)
				sm.set_shader_parameter("usa_textura", bm.albedo_texture != null)
				if bm.albedo_texture != null:
					sm.set_shader_parameter("textura", bm.albedo_texture)
				sm.set_shader_parameter("rugosidade", bm.roughness)
				if bm.normal_enabled and bm.normal_texture != null:
					sm.set_shader_parameter("usa_relevo", true)
					sm.set_shader_parameter("relevo", bm.normal_texture)
				if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:   # folhas (glTF alphaMode MASK)
					sm.set_shader_parameter("recorta", true)
					sm.set_shader_parameter("corte", bm.alpha_scissor_threshold if bm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR else 0.5)
				sm.set_shader_parameter("forca", forca)
				sm.set_shader_parameter("altura", altura)
				_vento[chave] = sm
			mi.set_surface_override_material(i, _vento[chave])

## Some de longe: árvores e plantas distantes não são desenhadas (a neblina disfarça).
static func distancia(raiz: Node, ate: float) -> void:
	var malhas: Array = []
	Fit._collect(raiz, malhas)
	for mi: MeshInstance3D in malhas:
		mi.visibility_range_end = ate
		mi.visibility_range_end_margin = ate * 0.1
		if ate < 50.0:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Luz de borda por cima de todos os materiais do modelo.
static func realce(raiz: Node, cor: Color, forca := 0.45) -> void:
	var sm := ShaderMaterial.new()
	sm.shader = REALCE
	sm.set_shader_parameter("cor", cor)
	sm.set_shader_parameter("forca", forca)
	var malhas: Array = []
	Fit._collect(raiz, malhas)
	for mi: MeshInstance3D in malhas:
		if not mi.has_meta("sem_realce"):
			mi.material_overlay = sm

static func chao(malha: MeshInstance3D, _textura_antiga: Texture2D = null) -> void:
	const T := "res://assets/textures/ground/"
	var sm := ShaderMaterial.new()
	sm.shader = CHAO
	sm.set_shader_parameter("grama", load(T + "Grass001/Grass001_1K-JPG_Color.jpg"))
	sm.set_shader_parameter("grama_n", load(T + "Grass001/Grass001_1K-JPG_NormalGL.jpg"))
	sm.set_shader_parameter("grama_r", load(T + "Grass001/Grass001_1K-JPG_Roughness.jpg"))
	sm.set_shader_parameter("terra", load(T + "Ground037/Ground037_1K-JPG_Color.jpg"))
	sm.set_shader_parameter("terra_n", load(T + "Ground037/Ground037_1K-JPG_NormalGL.jpg"))
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.012
	ruido.fractal_octaves = 3
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.noise = ruido
	sm.set_shader_parameter("manchas", nt)
	malha.material_override = sm
