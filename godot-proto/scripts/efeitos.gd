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
				sm.set_shader_parameter("forca", forca)
				sm.set_shader_parameter("altura", altura)
				_vento[chave] = sm
			mi.set_surface_override_material(i, _vento[chave])

## Luz de borda por cima de todos os materiais do modelo.
static func realce(raiz: Node, cor: Color, forca := 0.45) -> void:
	var sm := ShaderMaterial.new()
	sm.shader = REALCE
	sm.set_shader_parameter("cor", cor)
	sm.set_shader_parameter("forca", forca)
	var malhas: Array = []
	Fit._collect(raiz, malhas)
	for mi: MeshInstance3D in malhas:
		mi.material_overlay = sm

static func chao(malha: MeshInstance3D, textura: Texture2D) -> void:
	var sm := ShaderMaterial.new()
	sm.shader = CHAO
	sm.set_shader_parameter("grama", textura)
	malha.material_override = sm
