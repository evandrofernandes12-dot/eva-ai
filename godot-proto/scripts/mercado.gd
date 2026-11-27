extends PanelContainer
class_name Mercado
## Mercado: abas (Armas, Armaduras, Roupas, Artefatos) e um cartão por item da classe em uso:
## imagem 3D do item girando com o nome em cima e, ao lado, o bônus (dano, vida, energia), o preço e o botão.

const A := "res://models/armas/"
## id do item -> [modelo ou peça feita por código ("proc:..."), cor que tinge o modelo]
const IMG := {
	"g_esp_aco": [A + "Sword.glb", Color(1, 1, 1)], "g_esp_runa": [A + "Espada_Runica.glb", Color(1, 1, 1)],
	"g_cota": ["proc:cota", Color(0.7, 0.72, 0.75)], "g_placas": ["proc:placas", Color(0.85, 0.86, 0.9)],
	"g_capa": ["proc:capa", Color(0.75, 0.1, 0.1)], "g_tabardo": ["proc:capa", Color(0.15, 0.25, 0.7)],
	"g_amuleto": ["proc:amuleto", Color(0.95, 0.2, 0.25)], "g_anel": ["proc:anel", Color(1.0, 0.45, 0.1)],
	"l_lanca_ferro": [A + "Spear.glb", Color(1, 1, 1)], "l_lanca_drag": [A + "Spear.glb", Color(1.0, 0.45, 0.3)],
	"l_couro": ["proc:cota", Color(0.5, 0.33, 0.18)], "l_escamas": ["proc:placas", Color(0.35, 0.6, 0.4)],
	"l_manto": ["proc:capa", Color(0.35, 0.45, 0.25)], "l_pele": ["proc:capa", Color(0.45, 0.32, 0.2)],
	"l_totem": ["proc:totem", Color(0.6, 0.4, 0.2)], "l_presa": ["proc:presa", Color(0.95, 0.92, 0.82)],
	"a_arco_longo": [A + "Arco.glb", Color(1, 1, 1)], "a_arco_elfo": [A + "Arco.glb", Color(0.6, 1.0, 0.6)],
	"a_couro": ["proc:cota", Color(0.45, 0.3, 0.16)], "a_brig": ["proc:placas", Color(0.4, 0.3, 0.22)],
	"a_capuz": ["proc:capa", Color(0.2, 0.45, 0.2)], "a_folhas": ["proc:capa", Color(0.35, 0.6, 0.2)],
	"a_aljava": [A + "Aljava.glb", Color(0.8, 0.9, 1.2)], "a_pena": ["proc:pena", Color(0.95, 0.85, 0.6)],
	"m_cajado_carv": [A + "Cajado_Roxo.glb", Color(1, 1, 1)], "m_cajado_crist": [A + "Cajado_Cristal.glb", Color(1, 1, 1)],
	"m_seda": ["proc:cota", Color(0.55, 0.3, 0.7)], "m_arcano": ["proc:placas", Color(0.25, 0.25, 0.6)],
	"m_chapeu": ["proc:chapeu", Color(0.25, 0.2, 0.55)], "m_estrelas": ["proc:capa", Color(0.1, 0.12, 0.35)],
	"m_orbe": [A + "Orbe_Azul.glb", Color(1, 1, 1)], "m_grimorio": [A + "Livro_Vermelho.glb", Color(1, 1, 1)],
}
const NOMES_BONUS := {"dano": "Dano", "vida": "Vida", "energia": "Energia"}

var jogo: Node
var cat := "Armas"
var _itens: Node3D
var _girar: Array = []
var _corpo: VBoxContainer
var _saldo: Label

func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.1, 0.84)
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
	t.text = "Mercado — " + String(jogo.CLASSES[jogo.classe].nome)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65))
	vb.add_child(t)
	_saldo = Label.new()
	_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_saldo.add_theme_font_size_override("font_size", 18)
	vb.add_child(_saldo)
	var abas := HBoxContainer.new()
	abas.alignment = BoxContainer.ALIGNMENT_CENTER
	abas.add_theme_constant_override("separation", 8)
	vb.add_child(abas)
	for c: String in jogo.LOJA_CATS:
		var b := _botao(c, func(): cat = c; _mostrar())
		b.toggle_mode = true
		b.button_pressed = c == cat
		b.custom_minimum_size = Vector2(150, 46)
		b.set_meta("cat", c)
		abas.add_child(b)
	_corpo = VBoxContainer.new()
	_corpo.add_theme_constant_override("separation", 10)
	vb.add_child(_corpo)
	var f := _botao("Fechar", func(): jogo._fechar())
	f.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	f.custom_minimum_size = Vector2(220, 48)
	vb.add_child(f)
	_mostrar()

func _botao(texto: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(cb)
	return b

func _mostrar() -> void:
	for b in find_children("*", "Button", true, false):
		if b.has_meta("cat"):
			(b as Button).set_pressed_no_signal(String(b.get_meta("cat")) == cat)
	for c in _corpo.get_children():
		c.queue_free()
	_girar.clear()
	_saldo.text = "Madeira %d   ·   Pedra %d   ·   Comida %d" % [jogo.res.madeira, jogo.res.pedra, jogo.res.comida]
	for it: Array in jogo.LOJA[jogo.classe][cat]:
		_corpo.add_child(_cartao(it))
	_centralizar.call_deferred()

func _centralizar() -> void:
	size = get_combined_minimum_size()
	position = (get_viewport_rect().size - size) * 0.5

func _cartao(it: Array) -> Control:
	var id: String = it[0]
	var c := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.16, 0.24, 0.6)
	sb.set_corner_radius_all(14)
	sb.border_color = Color(1, 0.85, 0.5, 0.5) if jogo.equipado.get(cat, "") == id else Color(1, 1, 1, 0.12)
	sb.set_border_width_all(2)
	sb.content_margin_left = 10
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	c.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	c.add_child(hb)
	# esquerda: nome em cima, imagem do item embaixo
	var esq := VBoxContainer.new()
	hb.add_child(esq)
	var nome := Label.new()
	nome.text = String(it[1])
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.custom_minimum_size = Vector2(230, 0)
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.add_theme_font_size_override("font_size", 19)
	nome.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	esq.add_child(nome)
	esq.add_child(_imagem(id))
	# direita: bônus, preço e botão
	var dir := VBoxContainer.new()
	dir.alignment = BoxContainer.ALIGNMENT_CENTER
	dir.add_theme_constant_override("separation", 8)
	dir.custom_minimum_size = Vector2(260, 0)
	hb.add_child(dir)
	var bon: Dictionary = it[2]
	var lb := Label.new()
	var linhas := []
	for k: String in bon:
		linhas.append("%s  +%d" % [NOMES_BONUS.get(k, k), bon[k]])
	lb.text = "\n".join(linhas) if not linhas.is_empty() else "Só visual"
	lb.add_theme_font_size_override("font_size", 24)
	lb.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if bon.has("dano") else Color(0.6, 1.0, 0.65))
	dir.add_child(lb)
	var custo: Dictionary = it[3]
	var lp := Label.new()
	lp.text = "Preço: " + String(jogo.plots[0].texto(custo))
	lp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lp.add_theme_font_size_override("font_size", 18)
	dir.add_child(lp)
	var b: Button
	if id in jogo.compras:
		if jogo.equipado.get(cat, "") == id:
			b = _botao("✔ Em uso (tirar)", func(): jogo.equipado.erase(cat); _depois())
		else:
			b = _botao("Usar", func(): jogo.equipado[cat] = id; _depois())
	else:
		b = _botao("Comprar", func():
			jogo._pay(custo)
			jogo.compras.append(id)
			jogo.equipado[cat] = id
			jogo.say("Você comprou: %s!" % it[1], 3.0)
			_depois())
		b.disabled = not jogo._can_pay(custo)
	b.custom_minimum_size = Vector2(0, 50)
	dir.add_child(b)
	return c

func _depois() -> void:
	jogo._recalc()
	jogo._save()
	_mostrar()

## Imagem do item: o modelo 3D girando numa SubViewport com fundo transparente.
func _imagem(id: String) -> Control:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(230, 150)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(vp)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 35, 0)
	vp.add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	vp.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 35.0
	vp.add_child(cam)
	var pos_cam := Vector3(0, 0.25, 2.6)
	cam.transform = Transform3D(Basis.looking_at(-pos_cam), pos_cam)   # (ainda fora da árvore: look_at não funciona)
	var giro := Node3D.new()
	vp.add_child(giro)
	var info: Array = IMG.get(id, ["proc:amuleto", Color(1, 1, 1)])
	var m: Node3D
	if String(info[0]).begins_with("proc:"):
		m = _peca(String(info[0]).substr(5), info[1])
	else:
		m = (load(info[0]) as PackedScene).instantiate()
		if info[1] != Color(1, 1, 1):
			Fit.tint(m, info[1])
	var deita := Node3D.new()
	giro.add_child(deita)
	deita.add_child(m)
	# itens compridos (espada, lança, cajado) ficam deitados na horizontal e um pouco inclinados
	var bb := _caixa(giro)
	var maior := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
	if maior > 1.8 * minf(bb.size.x, bb.size.y) or bb.size.z == maior:
		if bb.size.z == maior:
			m.rotation.y += PI * 0.5
		elif bb.size.y == maior:
			m.rotation.z += PI * 0.5
		deita.rotation.z = 0.45
	bb = _caixa(giro)
	var esc := (2.1 if deita.rotation.z != 0.0 else 1.6) / maxf(maxf(bb.size.x, bb.size.y), 0.0001)
	deita.scale = Vector3.ONE * esc
	bb = _caixa(giro)
	deita.position -= bb.get_center()
	_girar.append(giro)
	return svc

## Caixa só das malhas (Fit.bounds usa os ossos quando o modelo tem esqueleto, e as armas do Sketchfab têm).
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

func _mat(cor: Color, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.metallic = metal
	m.roughness = 0.35 if metal > 0.0 else 0.8
	return m

func _malha(pai: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	pai.add_child(mi)
	return mi

## Peças feitas por código para itens sem modelo: armaduras, capas, chapéu, amuleto, anel, totem, presa, pena.
func _peca(tipo: String, cor: Color) -> Node3D:
	var r := Node3D.new()
	var metal := _mat(cor, 0.7)
	var pano := _mat(cor)
	var ouro := _mat(Color(1.0, 0.8, 0.3), 0.9)
	match tipo:
		"cota", "placas":
			var t := CylinderMesh.new()
			t.top_radius = 0.42
			t.bottom_radius = 0.34
			t.height = 0.8
			t.radial_segments = 12
			_malha(r, t, metal if tipo == "placas" else pano, Vector3.ZERO).scale = Vector3(1, 1, 0.6)
			for s2: float in [-1.0, 1.0]:
				var om := SphereMesh.new()
				om.radius = 0.2
				om.height = 0.3
				_malha(r, om, metal, Vector3(s2 * 0.45, 0.32, 0))
			var cinto := BoxMesh.new()
			cinto.size = Vector3(0.75, 0.08, 0.45)
			_malha(r, cinto, _mat(Color(0.3, 0.2, 0.1)), Vector3(0, -0.28, 0))
			if tipo == "placas":
				var faixa := BoxMesh.new()
				faixa.size = Vector3(0.08, 0.7, 0.5)
				_malha(r, faixa, ouro, Vector3(0, 0.02, 0.02))
		"capa":
			var q := BoxMesh.new()
			q.size = Vector3(0.8, 1.1, 0.04)
			_malha(r, q, pano, Vector3(0, 0, 0), Vector3(0.15, 0, 0))
			var gola := CylinderMesh.new()
			gola.top_radius = 0.2
			gola.bottom_radius = 0.24
			gola.height = 0.1
			_malha(r, gola, pano, Vector3(0, 0.55, 0.05))
			var broche := SphereMesh.new()
			broche.radius = 0.06
			broche.height = 0.12
			_malha(r, broche, ouro, Vector3(0, 0.52, 0.28))
		"chapeu":
			var aba := CylinderMesh.new()
			aba.top_radius = 0.55
			aba.bottom_radius = 0.55
			aba.height = 0.04
			_malha(r, aba, pano, Vector3.ZERO)
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.28
			cone.height = 0.8
			_malha(r, cone, pano, Vector3(0, 0.4, 0), Vector3(0, 0, 0.2))
		"amuleto":
			var corrente := TorusMesh.new()
			corrente.inner_radius = 0.42
			corrente.outer_radius = 0.46
			_malha(r, corrente, ouro, Vector3(0, 0.35, 0), Vector3(PI * 0.5, 0, 0))
			var pedra := SphereMesh.new()
			pedra.radius = 0.16
			pedra.height = 0.32
			var gema := _mat(cor, 0.2)
			gema.emission_enabled = true
			gema.emission = cor
			gema.emission_energy_multiplier = 0.8
			_malha(r, pedra, gema, Vector3(0, -0.12, 0.02))
		"anel":
			var aro := TorusMesh.new()
			aro.inner_radius = 0.3
			aro.outer_radius = 0.38
			_malha(r, aro, ouro, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
			var g2 := SphereMesh.new()
			g2.radius = 0.12
			g2.height = 0.24
			var gm := _mat(cor, 0.2)
			gm.emission_enabled = true
			gm.emission = cor
			_malha(r, g2, gm, Vector3(0, 0.4, 0))
		"totem":
			for k in 3:
				var bx := BoxMesh.new()
				bx.size = Vector3(0.4 - k * 0.05, 0.35, 0.4 - k * 0.05)
				_malha(r, bx, _mat(cor.lerp(Color(0.6, 0.15, 0.1), k * 0.4)), Vector3(0, k * 0.36 - 0.35, 0))
		"presa":
			var p := CylinderMesh.new()
			p.top_radius = 0.0
			p.bottom_radius = 0.12
			p.height = 0.9
			_malha(r, p, _mat(cor), Vector3.ZERO, Vector3(0, 0, 0.5))
		"pena":
			var pn := PrismMesh.new()
			pn.size = Vector3(0.3, 1.0, 0.02)
			_malha(r, pn, _mat(cor), Vector3.ZERO, Vector3(0, 0, 0.4))
			var haste := CylinderMesh.new()
			haste.top_radius = 0.015
			haste.bottom_radius = 0.015
			haste.height = 1.1
			_malha(r, haste, _mat(Color(0.95, 0.95, 0.9)), Vector3(0, -0.05, 0.02), Vector3(0, 0, 0.4))
	return r

func _process(delta: float) -> void:
	for g: Node3D in _girar:
		if is_instance_valid(g):
			g.rotation.y += delta * 0.8
