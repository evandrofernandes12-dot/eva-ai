extends CanvasLayer
class_name Abertura
## Abertura do jogo: a logo cobre a tela inteira e entra com zoom, brilho passando e faíscas douradas;
## depois (no jogo novo) aparece a escolha do personagem inicial: aldeão ou aldeã, em 3D, girando.
## Tocar na tela pula a animação da logo.

var jogo: Node
var escolher := true            # false: só a logo (jogo carregado)
var _fundo: ColorRect
var _logo: TextureRect
var _brilho: ColorRect
var _faiscas: CPUParticles2D
var _fase := "logo"
var _t := 0.0
const DURACAO_LOGO := 3.2       # segundos da logo na tela

func _ready() -> void:
	layer = 50
	_fundo = ColorRect.new()
	_fundo.color = Color(0.03, 0.04, 0.07)
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_fundo.gui_input.connect(_toque)
	add_child(_fundo)
	_logo = TextureRect.new()
	_logo.texture = load("res://logo.png")
	_logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED   # cobre a tela toda sem deformar
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.modulate.a = 0.0
	add_child(_logo)
	# faixa de luz que passa na diagonal por cima da logo
	_brilho = ColorRect.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float pos = -0.5;
void fragment() {
	float d = abs((UV.x + UV.y * 0.6) - pos);
	COLOR = vec4(1.0, 0.95, 0.75, (1.0 - smoothstep(0.0, 0.12, d)) * 0.45);
}"""
	var mt := ShaderMaterial.new()
	mt.shader = sh
	_brilho.material = mt
	_brilho.set_anchors_preset(Control.PRESET_FULL_RECT)
	_brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_brilho)
	_faiscas = CPUParticles2D.new()
	_faiscas.amount = 70
	_faiscas.lifetime = 2.2
	_faiscas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_faiscas.direction = Vector2(0, -1)
	_faiscas.spread = 35.0
	_faiscas.gravity = Vector2(0, -30)
	_faiscas.initial_velocity_min = 40.0
	_faiscas.initial_velocity_max = 120.0
	_faiscas.scale_amount_min = 2.0
	_faiscas.scale_amount_max = 5.0
	_faiscas.color = Color(1.0, 0.8, 0.35, 0.9)
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
	g.set_color(1, Color(1.0, 0.5, 0.1, 0.0))
	_faiscas.color_ramp = g
	add_child(_faiscas)
	_posicionar.call_deferred()
	var tw := create_tween().set_parallel(true)
	_logo.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	_logo.scale = Vector2.ONE * 1.15
	tw.tween_property(_logo, "modulate:a", 1.0, 0.9)
	tw.tween_property(_logo, "scale", Vector2.ONE, 2.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): mt.set_shader_parameter("pos", v), -0.4, 2.0, 1.6).set_delay(0.8)

func _posicionar() -> void:
	var tam := get_viewport().get_visible_rect().size
	_logo.pivot_offset = tam * 0.5
	_faiscas.position = Vector2(tam.x * 0.5, tam.y * 0.85)
	_faiscas.emission_rect_extents = Vector2(tam.x * 0.45, tam.y * 0.1)

func _toque(ev: InputEvent) -> void:
	if _fase == "logo" and ((ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed)):
		_t = DURACAO_LOGO   # pula a logo

func _process(delta: float) -> void:
	_t += delta
	if _fase == "logo" and _t >= DURACAO_LOGO:
		_fase = "saindo"
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_logo, "modulate:a", 0.0, 0.6)
		tw.tween_property(_brilho, "modulate:a", 0.0, 0.4)
		_faiscas.emitting = false
		if escolher:
			tw.chain().tween_callback(_mostrar_escolha)
		else:
			tw.tween_property(_fundo, "modulate:a", 0.0, 0.7)
			tw.chain().tween_callback(queue_free)

## Escolha do personagem inicial: aldeão ou aldeã com roupa de camponês.
func _mostrar_escolha() -> void:
	_fase = "escolha"
	_fundo.color = Color(0.03, 0.04, 0.07, 0.86)
	var caixa := VBoxContainer.new()
	caixa.set_anchors_preset(Control.PRESET_FULL_RECT)
	caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.add_theme_constant_override("separation", 14)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caixa)
	var t := Label.new()
	t.text = "Quem vai começar a aventura?"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 8)
	caixa.add_child(t)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 40)
	caixa.add_child(hb)
	hb.add_child(_cartao("m"))
	hb.add_child(_cartao("f"))
	caixa.modulate.a = 0.0
	create_tween().tween_property(caixa, "modulate:a", 1.0, 0.5)

func _cartao(sexo: String) -> Control:
	var c := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.14, 0.22, 0.65)
	sb.border_color = Color(0.95, 0.8, 0.45, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	c.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	c.add_child(vb)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(240, 360)
	vb.add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(vp)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, 30, 0)
	vp.add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	vp.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var pc := Vector3(0, 1.1, 4.4)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.92, 0) - pc), pc)
	vp.add_child(cam)
	var m: Node3D = jogo.modelo_aldeao(sexo)
	vp.add_child(m)
	Fit.to_height(m, 1.8)
	var ap := Fit.find_node_of(m, "AnimationPlayer") as AnimationPlayer
	Fit.play(ap, Fit.find_anim(ap, ["Idle"]))
	m.set_meta("gira", true)
	var b := Button.new()
	b.text = "Aldeão" if sexo == "m" else "Aldeã"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(func(): _escolhido(sexo))
	vb.add_child(b)
	set_process(true)
	_girar.append(m)
	return c

var _girar: Array = []

func _physics_process(delta: float) -> void:
	for m: Node3D in _girar:
		if is_instance_valid(m):
			m.rotation.y += delta * 0.7

func _escolhido(sexo: String) -> void:
	jogo.comecar_como(sexo)
	var tw := create_tween()
	tw.tween_property(_fundo, "modulate:a", 0.0, 0.5)
	for c in get_children():
		if c is VBoxContainer:
			tw.parallel().tween_property(c, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
