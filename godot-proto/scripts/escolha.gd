extends PanelContainer
class_name EscolhaPersonagem
## Tela de escolha dos 4 personagens de uma classe: cada um aparece de corpo inteiro, de pé, com a arma
## e a armadura, girando devagar (cada cartão tem a sua SubViewport).

var jogo: Node
var classe := ""
var _modelos: Array = []

func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.1, 0.82)
	sb.border_color = Color(0.95, 0.8, 0.45, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)
	var t := Label.new()
	t.text = "%s — escolha o seu personagem" % jogo.CLASSES[classe].nome
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65))
	vb.add_child(t)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)
	var lista := Heroi.lista()
	for sexo: String in ["m", "f"]:
		for id: String in lista:
			var h: Dictionary = lista[id]
			if h.classe == classe and h.sexo == sexo:
				hb.add_child(_cartao(id, h))
	var rodape := HBoxContainer.new()
	rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	rodape.add_theme_constant_override("separation", 16)
	vb.add_child(rodape)
	rodape.add_child(_botao("← Outras classes", func(): jogo._menu_escolha()))
	rodape.add_child(_botao("Fechar", func(): jogo._fechar()))
	_centralizar.call_deferred()

func _centralizar() -> void:
	size = get_combined_minimum_size()
	position = (get_viewport_rect().size - size) * 0.5

func _botao(texto: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(200, 50)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	return b

func _cartao(id: String, h: Dictionary) -> Control:
	var c := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.16, 0.24, 0.6)
	sb.set_corner_radius_all(14)
	sb.border_color = Color(1, 1, 1, 0.15)
	sb.set_border_width_all(1)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	c.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	c.add_child(vb)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(190, 290)
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
	env.environment.ambient_light_color = Color(0.65, 0.65, 0.72)
	vp.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.15, 4.6), Vector3(0, 0.95, 0))
	var m := Heroi.montar(id, true, false)
	vp.add_child(m)
	Fit.to_height(m, 1.85)
	m.rotation.y = 0.35
	var ap := Fit.find_node_of(m, "AnimationPlayer") as AnimationPlayer
	Fit.play(ap, Fit.find_anim(ap, ["Idle"]))
	_modelos.append(m)
	var l := Label.new()
	l.text = ("Masculino" if h.sexo == "m" else "Feminino") + "\n" + String(h.nome)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(190, 0)
	l.add_theme_font_size_override("font_size", 15)
	vb.add_child(l)
	var b := _botao("Escolher", func():
		jogo.vestir(id)
		jogo._fechar()
		jogo.say("Personagem escolhido!", 2.5))
	b.custom_minimum_size = Vector2(0, 46)
	if jogo.heroi == id:
		b.text = "✔ Em uso"
	vb.add_child(b)
	return c

func _process(delta: float) -> void:
	for m: Node3D in _modelos:
		if is_instance_valid(m):
			m.rotation.y += delta * 0.6
