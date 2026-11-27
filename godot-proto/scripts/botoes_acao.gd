extends Node
class_name BotoesAcao
## Botões de ação redondos e translúcidos com ícone: ATACAR mostra a arma em uso (em 3D), CORRER duas
## perninhas correndo, DEFESA um escudo. Ao apertar o botão encolhe e volta pulando; ligado (defesa/correr)
## o aro brilha pulsando.

var jogo: Node
var _atacar: Button
var _defesa: Button
var _correr: Button
var _vp_arma: SubViewport
var _arma: Node3D
var _id_arma := ""
var _t := 0.0

func montar(j: Node, atacar: Button, defesa: Button, correr: Button) -> void:
	jogo = j
	_atacar = atacar
	_defesa = defesa
	_correr = correr
	_redondo(_atacar, 190.0, Vector2(-230, -230), Color(0.95, 0.35, 0.25))
	_redondo(_defesa, 120.0, Vector2(-385, -175), Color(0.4, 0.7, 1.0))
	_redondo(_correr, 120.0, Vector2(-330, -330), Color(0.55, 1.0, 0.45))
	_vp_arma = _icone_3d(_atacar, "", 0.95)
	_icone_3d(_defesa, "res://models/armas/Shield_Heater.glb", 0.7)
	var tr := TextureRect.new()
	tr.texture = load("res://ui/correr.png")
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.anchor_right = 1.0
	tr.anchor_bottom = 1.0
	tr.offset_left = 22
	tr.offset_right = -22
	tr.offset_top = 16
	tr.offset_bottom = -28
	_correr.add_child(tr)
	_rotulo(_atacar, "ATACAR")
	_rotulo(_defesa, "DEFESA")
	_rotulo(_correr, "CORRER")
	for b: Button in [_atacar, _defesa, _correr]:
		b.button_down.connect(_pular.bind(b, 0.82))
		b.button_up.connect(_pular.bind(b, 1.0))
	atualizar_arma()

## Botão circular de vidro escuro com aro colorido.
func _redondo(b: Button, tam: float, canto: Vector2, cor: Color) -> void:
	b.text = ""
	b.offset_left = canto.x
	b.offset_top = canto.y
	b.offset_right = canto.x + tam
	b.offset_bottom = canto.y + tam
	b.pivot_offset = Vector2(tam, tam) * 0.5
	b.set_meta("cor", cor)
	for estado: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		var ligado := estado in ["pressed", "hover_pressed"]
		sb.bg_color = Color(0.05, 0.07, 0.12, 0.55 if not ligado else 0.7)
		sb.border_color = Color(cor, 0.85 if ligado else 0.45)
		sb.set_border_width_all(5 if ligado else 3)
		sb.set_corner_radius_all(int(tam / 2.0))
		sb.shadow_color = Color(cor, 0.45 if ligado else 0.0)
		sb.shadow_size = 14 if ligado else 0
		b.add_theme_stylebox_override(estado, sb)

func _rotulo(b: Button, texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_right = 1.0
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_top = -34 if b == _atacar else -28
	l.offset_bottom = -6
	l.add_theme_font_size_override("font_size", 20 if b == _atacar else 15)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)

## Ícone 3D dentro do botão (SubViewport transparente). Devolve a viewport para trocar o modelo depois.
func _icone_3d(b: Button, caminho: String, escala: float) -> SubViewport:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	svc.anchor_right = 1.0
	svc.anchor_bottom = 1.0
	var m := 14.0
	svc.offset_left = m
	svc.offset_right = -m
	svc.offset_top = m * 0.6
	svc.offset_bottom = -m * 1.8
	b.add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(vp)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 30, 0)
	vp.add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	vp.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0, -1)), Vector3(0, 0, 2.6))
	vp.add_child(cam)
	vp.set_meta("escala", escala)
	if caminho != "":
		_por_modelo(vp, caminho)
	return vp

func _por_modelo(vp: SubViewport, caminho: String) -> Node3D:
	var giro := Node3D.new()
	giro.name = "Giro"
	vp.add_child(giro)
	var m: Node3D = (load(caminho) as PackedScene).instantiate()
	giro.add_child(m)
	var bb := _caixa(giro)
	if bb.size.z > maxf(bb.size.x, bb.size.y):
		m.rotation.y += PI * 0.5
	elif bb.size.y > bb.size.x * 2.0:
		pass
	bb = _caixa(giro)
	if bb.size.x > bb.size.y * 2.0:   # comprido deitado: põe na diagonal, como no ícone de jogo
		giro.rotation.z = 0.8
	elif bb.size.y > bb.size.x * 2.0:
		giro.rotation.z = -0.75
	var esc := 1.25 * float(vp.get_meta("escala")) / maxf(maxf(bb.size.x, bb.size.y), 0.0001) * 1.6
	m.scale *= esc
	bb = _caixa(giro)
	m.position -= bb.get_center()
	return giro

## Caixa só das malhas, no espaço de `raiz` (sem depender de estar na árvore).
func _caixa(raiz: Node3D) -> AABB:
	var box := AABB()
	var primeiro := true
	for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var t := Transform3D.IDENTITY
		var no: Node = mi
		while no != raiz and no is Node3D:
			t = (no as Node3D).transform * t
			no = no.get_parent()
		var b := t * mi.mesh.get_aabb()
		box = b if primeiro else box.merge(b)
		primeiro = false
	return box

## Troca o ícone do ATACAR pela arma do personagem (ou a comprada no mercado).
func atualizar_arma() -> void:
	var caminho := ""
	var eq: String = jogo.equipado.get("Armas", "")
	if eq != "" and Mercado.IMG.has(eq):
		caminho = Mercado.IMG[eq][0]
	elif jogo.heroi != "" and Heroi.lista().has(jogo.heroi):
		for a: Array in Heroi.lista()[jogo.heroi].armas:
			var f := String(a[0])
			if not (f.begins_with("Shield") or f.begins_with("Aljava") or f.begins_with("Orbe")):
				caminho = "res://models/armas/" + f
				break
	if caminho == "":
		caminho = "res://models/armas/Sword.glb"
	if caminho == _id_arma:
		return
	_id_arma = caminho
	var velho := _vp_arma.get_node_or_null("Giro")
	if velho != null:
		velho.free()
	_arma = _por_modelo(_vp_arma, caminho)

func _pular(b: Button, alvo: float) -> void:
	var tw := b.create_tween()
	if alvo < 1.0:
		tw.tween_property(b, "scale", Vector2.ONE * alvo, 0.06)
	else:
		tw.tween_property(b, "scale", Vector2.ONE * 1.08, 0.08).set_trans(Tween.TRANS_BACK)
		tw.tween_property(b, "scale", Vector2.ONE, 0.1)
	if b == _atacar and alvo < 1.0 and _arma != null:   # a arma dá um golpe no ícone
		var ta := _arma.create_tween()
		ta.tween_property(_arma, "rotation:y", _arma.rotation.y + TAU, 0.3).set_trans(Tween.TRANS_QUAD)

func _process(delta: float) -> void:
	_t += delta
	if _arma != null and is_instance_valid(_arma):
		_arma.position.y = sin(_t * 2.0) * 0.04   # flutua de leve
	for b: Button in [_defesa, _correr]:   # ligado: o botão pulsa
		if b != null and b.button_pressed:
			b.modulate = Color(1, 1, 1).lerp(Color(b.get_meta("cor"), 1.0), 0.25 + 0.2 * sin(_t * 6.0))
		elif b != null:
			b.modulate = Color(1, 1, 1)
