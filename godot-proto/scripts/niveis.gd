class_name Niveis
## Níveis de 0 a 100: nome por faixa de 10 níveis, custo para subir, visual da construção em cada faixa
## (tamanho, cor do material e enfeites) e experiência do personagem. No nível 100 (lendário) tudo fica
## azul-real escuro e ouro velho.

const MAX := 100

## Nome em cada faixa (0-9, 10-19, ..., 90-99, 100).
const MATERIAIS := ["de Pau a Pique", "de Madeira", "de Pinho", "de Carvalho", "de Pedra", "de Pedra Talhada",
	"de Tijolos", "de Granito", "de Mármore", "Real", "Lendári"]   # "Lendári" + o/a conforme o nome
const NOMES := {
	"muro": ["Cerca de Galhos", "Paliçada de Madeira", "Paliçada de Pinho", "Paliçada de Carvalho", "Muro de Pedra",
		"Muro de Pedra Talhada", "Muro de Concreto", "Muro de Concreto Reforçado", "Muro de Ferro", "Muro de Aço", "Muro Lendário"],
	"torre": ["Torrezinha de Galhos", "Torre de Madeira", "Torre de Pinho", "Torre de Carvalho", "Torre de Pedra",
		"Torre de Pedra Talhada", "Torre de Concreto", "Torre de Granito", "Torre de Ferro", "Torre de Aço", "Torre Lendária"],
	"castelo": ["Fortim de Madeira", "Castelo de Madeira", "Castelo de Carvalho", "Castelo de Pedra", "Castelo de Pedra Talhada",
		"Castelo de Granito", "Castelo de Mármore", "Castelo de Ferro", "Castelo de Aço", "Castelo Real", "Castelo Lendário"],
}
const FEMININO := ["Casa", "Torre", "Forja", "Cozinha", "Horta", "Estalagem", "Serraria", "Casa do Mago", "Casa da Artesã", "Casa do Rei"]

## Cor que multiplica os materiais em cada faixa (madeira rústica, pinho claro, carvalho escuro, pedra, granito, mármore...).
const TINTAS := [Color(0.8, 0.74, 0.66), Color(0.92, 0.85, 0.75), Color(1.0, 0.93, 0.8), Color(0.84, 0.7, 0.56),
	Color(0.9, 0.9, 0.92), Color(1.0, 1.0, 1.0), Color(1.0, 0.86, 0.8), Color(0.82, 0.84, 0.9), Color(1.08, 1.07, 1.04),
	Color(1.06, 0.98, 0.86), Color(1, 1, 1)]
const TURQUESA := Color(0.015, 0.035, 0.14)   # azul-real escuro e imponente (o nome ficou do começo)
const OURO := Color(0.56, 0.39, 0.12)       # ouro velho, metálico (não dourado claro)

static func faixa(nivel: int) -> int:
	return clampi(nivel / 10, 0, 10)

## Nome da construção no nível (ex.: "Muro de Pedra", "Casa de Carvalho", "Forja Lendária").
static func nome(base: String, cat: String, nivel: int) -> String:
	var f := faixa(nivel)
	if NOMES.has(cat):
		return NOMES[cat][f]
	var m: String = MATERIAIS[f]
	if f == 10:
		m += "a" if base in FEMININO else "o"
	return "%s %s" % [base, m]

## Custo para subir do nível `nivel` para o próximo (só madeira e pedra).
static func custo(base: Dictionary, nivel: int) -> Dictionary:
	var k := 1.0 + 0.3 * nivel + 0.015 * nivel * nivel
	return {"madeira": int(int(base.get("madeira", 0)) * k), "pedra": int(int(base.get("pedra", 0)) * k)}

## Experiência para passar do nível n do personagem para o n+1.
static func xp_para(n: int) -> int:
	return int(60.0 * pow(float(n), 1.35))

## Multiplicadores dos inimigos no nível do personagem: [vida, dano].
static func forca_inimigo(nivel_jogador: int) -> Vector2:
	var n := maxf(0.0, float(nivel_jogador - 1))
	return Vector2(1.0 + 0.15 * n, 1.0 + 0.08 * n)

## Aplica o visual da faixa: tamanho (até +35%), cor dos materiais e enfeites (bandeira, base de pedra,
## braseiros, faixa de metal, torre dourada, brilho turquesa no lendário).
static func visual(raiz: Node3D, nivel: int, escala_base: Vector3) -> void:
	if raiz == null or not is_instance_valid(raiz):
		return
	var f := faixa(nivel)
	raiz.scale = escala_base * (1.0 + 0.0035 * nivel)
	tingir(raiz, f)
	var velho := raiz.get_node_or_null("Enfeites")
	if velho != null:
		velho.free()
	var bl := _caixa(raiz)
	if bl.size.length() < 0.1:
		return
	# os enfeites são medidos em metros (não crescem com a escala do prédio: no castelo viravam muros)
	var sc := raiz.scale.x
	var bb := AABB(bl.position * sc, bl.size * sc)
	var e := Node3D.new()
	e.name = "Enfeites"
	e.scale = Vector3.ONE / sc
	raiz.add_child(e)
	# frente = lado virado para a praça (a porta); nada é posto na frente da porta
	var praca := raiz.to_local(Vector3.ZERO) if raiz.is_inside_tree() else Vector3(0, 0, 1)
	var fz := 1.0 if praca.z >= 0.0 else -1.0
	var z_frente := bb.end.z if fz > 0.0 else bb.position.z
	var z_fundo := bb.position.z if fz > 0.0 else bb.end.z
	var topo := bb.end.y
	var cx := bb.get_center().x
	var cz := bb.get_center().z
	var cor_band: Color = [Color(0.6, 0.2, 0.15), Color(0.2, 0.35, 0.7), Color(0.8, 0.6, 0.1), TURQUESA][mini(f / 3, 3)]
	if f >= 1:   # bandeira no alto
		var px := bb.position.x + bb.size.x * 0.2
		Construcoes.tora(e, Vector3(px, topo - 0.2, cz), Vector3(px, topo + 1.8, cz), 0.04, Construcoes.mat(Color(0.3, 0.22, 0.14)))
		Construcoes.caixa(e, Vector3(px + 0.45, topo + 1.45, cz), Vector3(0.85, 0.5, 0.03), Construcoes.mat(cor_band, false))
	if f >= 3:   # meio-fio de pedra baixo nas laterais e no fundo (a frente fica livre)
		var m := Construcoes.mat_pedra() if f < 10 else _mat(TURQUESA, 0.4)
		Construcoes.caixa(e, Vector3(cx, 0.15, z_fundo - fz * 0.2), Vector3(bb.size.x + 0.4, 0.3, 0.35), m)
		for s2: float in [-1.0, 1.0]:
			Construcoes.caixa(e, Vector3(cx + s2 * (bb.size.x * 0.5 + 0.2), 0.15, cz), Vector3(0.35, 0.3, bb.size.z + 0.4), m)
	if f >= 5:   # dois braseiros nas quinas da frente
		for s2: float in [-1.0, 1.0]:
			var p := Vector3(cx + s2 * (bb.size.x * 0.5 + 0.5), 0, z_frente + fz * 0.3)
			Construcoes.tora(e, p, p + Vector3(0, 1.1, 0), 0.06, _mat(Color(0.2, 0.2, 0.22), 0.6))
			var chama := MeshInstance3D.new()
			var cm := SphereMesh.new()
			cm.radius = 0.16
			cm.height = 0.4
			chama.mesh = cm
			var mc := StandardMaterial3D.new()
			mc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mc.albedo_color = Color(1.0, 0.6, 0.15) if f < 10 else Color(0.25, 0.45, 1.0)
			chama.material_override = mc
			chama.position = p + Vector3(0, 1.3, 0)
			e.add_child(chama)
	if f >= 7:   # faixa de metal no meio da altura
		var mm := _mat(Color(0.55, 0.56, 0.6), 0.7) if f < 9 else _mat(OURO, 0.9)
		var y := bb.position.y + bb.size.y * 0.45
		for s2: float in [-1.0, 1.0]:
			Construcoes.caixa(e, Vector3(cx, y, cz + s2 * bb.size.z * 0.505), Vector3(bb.size.x * 1.01, 0.15, 0.06), mm)
			Construcoes.caixa(e, Vector3(cx + s2 * bb.size.x * 0.505, y, cz), Vector3(0.06, 0.15, bb.size.z * 1.01), mm)
	if f >= 9:   # pináculo de ouro no telhado
		var pin := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.0
		cyl.bottom_radius = 0.22
		cyl.height = 1.4
		pin.mesh = cyl
		pin.material_override = _mat(OURO, 0.9)
		pin.position = Vector3(cx, topo + 0.6, cz)
		e.add_child(pin)
	if f >= 10:   # lendário: faíscas de ouro
		var p2 := CPUParticles3D.new()
		p2.amount = 24
		p2.lifetime = 2.5
		p2.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p2.emission_box_extents = bb.size * 0.5
		p2.position = bb.get_center()
		p2.gravity = Vector3(0, 0.6, 0)
		p2.initial_velocity_max = 0.3
		var q := QuadMesh.new()
		q.size = Vector2(0.12, 0.12)
		var mq := StandardMaterial3D.new()
		mq.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mq.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mq.albedo_color = OURO
		q.material = mq
		p2.mesh = q
		e.add_child(p2)

## Muda a cor dos materiais da construção para a faixa (guarda os originais para não acumular).
static func tingir(raiz: Node, f: int) -> void:
	for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.get_parent().name == "Enfeites" or (mi.get_parent() != null and mi.get_parent().get_parent() != null and mi.get_parent().get_parent().name == "Enfeites"):
			continue
		for i in mi.mesh.get_surface_count():
			var orig: Material = mi.get_meta("orig_%d" % i) if mi.has_meta("orig_%d" % i) else mi.get_active_material(i)
			if orig == null:
				continue
			mi.set_meta("orig_%d" % i, orig)
			if not (orig is BaseMaterial3D):
				continue
			var m := (orig as BaseMaterial3D).duplicate() as BaseMaterial3D
			var c := m.albedo_color
			if f >= 10:   # lendário: partes claras viram ouro, partes escuras viram turquesa
				var lum := c.get_luminance()
				var alvo := OURO if lum > 0.55 else TURQUESA
				var forte := 1.5 if m.albedo_texture != null else 1.0   # a textura escurece: compensa para o ouro não ficar marrom
				m.albedo_color = Color(alvo.r * forte, alvo.g * forte, alvo.b * forte, c.a)   # mantém a textura (pedras, tábuas) por baixo
				m.metallic = 0.9 if lum > 0.55 else 0.3
				m.roughness = 0.28 if lum > 0.55 else 0.45
			else:
				var t: Color = TINTAS[f]
				m.albedo_color = Color(c.r * t.r, c.g * t.g, c.b * t.b, c.a)
			mi.set_surface_override_material(i, m)

## Copia um material com a cor da faixa (para peças feitas por código, como a muralha).
static func material(orig: BaseMaterial3D, f: int) -> BaseMaterial3D:
	var m := orig.duplicate() as BaseMaterial3D
	var c := m.albedo_color
	if f >= 10:
		var ouro := c.get_luminance() > 0.5
		m.albedo_color = OURO if ouro else TURQUESA
		m.metallic = 0.9 if ouro else 0.3
		m.roughness = 0.28 if ouro else 0.45
	else:
		var t: Color = TINTAS[f]
		m.albedo_color = Color(c.r * t.r, c.g * t.g, c.b * t.b, c.a)
	return m

static func _mat(c: Color, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = 0.4 if metal > 0.0 else 0.85
	return m

## Caixa das malhas no espaço da raiz (ignora os enfeites).
static func _caixa(raiz: Node3D) -> AABB:
	var box := AABB()
	var primeiro := true
	for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var t := Transform3D.IDENTITY
		var no: Node = mi
		var pular := false
		while no != raiz and no is Node3D:
			if no.name == "Enfeites":
				pular = true
			t = (no as Node3D).transform * t
			no = no.get_parent()
		if pular:
			continue
		var b := t * mi.mesh.get_aabb()
		box = b if primeiro else box.merge(b)
		primeiro = false
	return box
