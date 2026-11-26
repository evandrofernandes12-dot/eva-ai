extends PanelContainer
class_name PainelStatus
## Painel translúcido no canto superior esquerdo: retrato do personagem (rosto ao vivo, numa
## SubViewport), nome e classe, barra de vida e barra de energia.

const LARG := 420.0
var jogo: Node
var _vp: SubViewport
var _modelo: Node3D
var _nome: Label
var _vida: ProgressBar
var _vida_l: Label
var _energia: ProgressBar
var _energia_l: Label

func _ready() -> void:
	position = Vector2(14, 12)
	custom_minimum_size = Vector2(LARG, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.1, 0.42)
	sb.border_color = Color(0.95, 0.8, 0.45, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	add_child(hb)
	hb.add_child(_retrato_ui())
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	hb.add_child(vb)
	_nome = Label.new()
	_nome.add_theme_font_size_override("font_size", 20)
	_nome.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	_nome.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_nome.add_theme_constant_override("outline_size", 6)
	vb.add_child(_nome)
	var v := _barra(Color(0.95, 0.22, 0.2), Color(1.0, 0.5, 0.35))
	_vida = v[0]
	_vida_l = v[1]
	vb.add_child(v[2])
	var e := _barra(Color(0.95, 0.75, 0.15), Color(0.6, 1.0, 0.45))
	_energia = e[0]
	_energia_l = e[1]
	vb.add_child(e[2])

## Barra com fundo escuro translúcido, preenchimento com brilho de vidro e o número por cima.
func _barra(c1: Color, c2: Color) -> Array:
	var caixa := Control.new()
	caixa.custom_minimum_size = Vector2(0, 26)
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0, 0, 0, 0.45)
	fundo.set_corner_radius_all(13)
	fundo.border_color = Color(1, 1, 1, 0.18)
	fundo.set_border_width_all(1)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = c1.lerp(c2, 0.35)
	cheio.set_corner_radius_all(13)
	cheio.border_color = c2
	cheio.border_width_top = 2
	pb.add_theme_stylebox_override("background", fundo)
	pb.add_theme_stylebox_override("fill", cheio)
	caixa.add_child(pb)
	var brilho := ColorRect.new()   # reflexo de vidro na metade de cima
	brilho.color = Color(1, 1, 1, 0.12)
	brilho.anchor_right = 1.0
	brilho.anchor_bottom = 0.45
	brilho.offset_left = 6
	brilho.offset_right = -6
	brilho.offset_top = 2
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(brilho)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	caixa.add_child(l)
	return [pb, l, caixa]

## Retrato redondo: o rosto do herói renderizado ao vivo (respira, pisca) dentro de um círculo com aro dourado.
func _retrato_ui() -> Control:
	var tam := 96
	var moldura := Control.new()
	moldura.custom_minimum_size = Vector2(tam, tam)
	_vp = SubViewport.new()
	_vp.size = Vector2i(160, 160)
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	moldura.add_child(_vp)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-25, 25, 0)
	_vp.add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	_vp.add_child(env)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.6, 0.62)
	cam.fov = 32.0
	_vp.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0, 1.56, 0))
	var fundo := Panel.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sf := StyleBoxFlat.new()
	sf.bg_color = Color(0.15, 0.2, 0.3, 0.55)
	sf.set_corner_radius_all(tam / 2)
	sf.border_color = Color(0.95, 0.8, 0.45, 0.9)
	sf.set_border_width_all(3)
	fundo.add_theme_stylebox_override("panel", sf)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(fundo)
	var tr := TextureRect.new()
	tr.texture = _vp.get_texture()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() { vec4 c = texture(TEXTURE, UV); float d = length(UV - 0.5); c.a *= 1.0 - smoothstep(0.43, 0.46, d); COLOR = c; }"
	var mt := ShaderMaterial.new()
	mt.shader = sh
	tr.material = mt
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(tr)
	return moldura

## Troca o rosto do retrato (chamado quando o jogador escolhe outro personagem).
func retrato(id: String) -> void:
	if _modelo != null:
		_modelo.queue_free()
		_modelo = null
	if id == "" or not Heroi.lista().has(id):
		return
	_modelo = Heroi.montar(id, false, true)
	_vp.add_child(_modelo)
	Fit.to_height(_modelo, 1.75)
	var ap := Fit.find_node_of(_modelo, "AnimationPlayer") as AnimationPlayer
	Fit.play(ap, Fit.find_anim(ap, ["Idle"]))

func _process(_d: float) -> void:
	if jogo == null or jogo.player == null:
		return
	var pl = jogo.player
	_vida.max_value = pl.max_hp
	_vida.value = pl.hp
	_vida_l.text = "%d / %d" % [pl.hp, pl.max_hp]
	_energia.max_value = pl.max_energia
	_energia.value = pl.energia
	_energia_l.text = "Energia %d" % int(pl.energia)
	var cl: String = jogo.classe
	var nome := "Aventureiro"
	if jogo.heroi != "" and Heroi.lista().has(jogo.heroi):
		nome = jogo.CLASSES[cl].nome if jogo.CLASSES.has(cl) else nome
	_nome.text = nome
