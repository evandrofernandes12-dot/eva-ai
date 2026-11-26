extends Node3D
class_name Mundo
## Mundo aberto em volta da aldeia: chão grande, mar a leste com a Ilha dos Orcs (só se chega de barco)
## e mais três regiões inimigas, cada uma com a sua vila e os seus monstros:
##   norte: Floresta da Escuridão (Vila dos Lobisomens)
##   oeste: Floresta do Cemitério Maldito (Vila das Caveiras)
##   sul:   Floresta dos Golems de Pedra (neve, montanhas, Vila dos Golems)
##   leste: Ilha dos Orcs (Vila dos Orcs); os orcs vêm de barco atacar a aldeia.
## Cada região some (não é desenhada) quando o jogador está longe dela.

const QN := "res://assets/nature/quaternius/"
const HW := "res://assets/halloween/"
const KC := "res://models/caveiras/"
const T := "res://assets/textures/ground/"
const REGIAO := preload("res://shaders/regiao.gdshader")
const MAR := preload("res://shaders/mar.gdshader")
const MONTANHA := preload("res://shaders/montanha.gdshader")
const ENEMY := preload("res://scripts/enemy.gd")

const TAMANHO := 1800.0          # lado do mapa (m); a aldeia fica no centro
const COSTA_X := 260.0           # a leste daqui é mar
const ILHA := Vector3(560, 0, 0) # centro da Ilha dos Orcs
const ILHA_R := 125.0
const CAIS_CASA := Vector3(262, 0, 0)     # ponta de terra do cais da aldeia (o barco para em +x)
const CAIS_ILHA := Vector3(ILHA.x - ILHA_R + 4.0, 0, 0)
const VIAGEM := 22.0             # segundos de barco entre os dois cais
const LONGE := 140.0             # região some quando o jogador está a mais que raio + isto do centro

## id -> nome, vila, centro, raio, cor da neblina, densidade extra da neblina, quanto escurece
const REGIOES := {
	"escuridao": {"nome": "Floresta da Escuridão", "vila": "Vila dos Lobisomens", "centro": Vector3(0, 0, -440), "raio": 160.0, "neblina": Color(0.07, 0.05, 0.12), "dens": 0.022, "escuro": 0.5, "ceu": 0.95},
	"cemiterio": {"nome": "Floresta do Cemitério Maldito", "vila": "Vila das Caveiras", "centro": Vector3(-440, 0, 0), "raio": 160.0, "neblina": Color(0.3, 0.36, 0.32), "dens": 0.022, "escuro": 0.4, "ceu": 0.8},
	"golems": {"nome": "Floresta dos Golems de Pedra", "vila": "Vila dos Golems", "centro": Vector3(0, 0, 440), "raio": 170.0, "neblina": Color(0.86, 0.9, 0.96), "dens": 0.006, "escuro": 0.0, "ceu": 0.4},
	"orcs": {"nome": "Ilha dos Orcs", "vila": "Vila dos Orcs", "centro": ILHA, "raio": ILHA_R, "neblina": Color(0.7, 0.75, 0.8), "dens": 0.0, "escuro": 0.0, "ceu": 0.0},
}

var jogo: Node
var regioes := {}               # id -> Node3D
var regiao_atual := ""
var _rng := RandomNumberGenerator.new()
var _neve: GPUParticles3D
var _barco: Node3D               # barco do jogador
var _barco_orc: Node3D
var _botao: Button
var _viagem := {}                # {t, de, ate, chegada}
var _orc_estado := "indo"        # ilha -> indo -> atracado -> voltando -> ilha
var _orc_t := 0.0
var _ok := Vector3.ZERO          # última posição do jogador em terra firme
var _libs := {}

func montar(j: Node) -> void:
	jogo = j
	_rng.seed = 2024
	_chao()
	_mar_e_ilha()
	_estradas()
	for id: String in REGIOES:
		var r := Node3D.new()
		r.name = "Regiao_" + id
		add_child(r)
		regioes[id] = r
	_escuridao(regioes.escuridao)
	_cemiterio(regioes.cemiterio)
	_golems(regioes.golems)
	_ilha_orcs(regioes.orcs)
	_neve = _flocos()
	add_child(_neve)
	_barco = barco(Color(0.92, 0.88, 0.75))
	add_child(_barco)
	_barco.position = CAIS_CASA + Vector3(9, 0, -3.5)
	_barco.rotation.y = PI * 0.5
	_barco_orc = barco(Color(0.45, 0.1, 0.08))
	add_child(_barco_orc)
	_orc_t = VIAGEM * 0.4
	_botao = jogo._botao_acao("BARCO", -260.0, -540.0, false, 70.0)
	_botao.pressed.connect(_embarcar)
	_botao.visible = false
	_ok = jogo.player.global_position

# ---------- terreno ----------
func _chao() -> void:
	# o chão de grama da cena cobre só a terra (a leste da costa fica o mar)
	var malha: MeshInstance3D = jogo.get_node("Chao/Malha")
	var pm := PlaneMesh.new()
	pm.size = Vector2(TAMANHO, TAMANHO)
	malha.mesh = pm
	malha.position.x = COSTA_X - TAMANHO * 0.5
	var sm := malha.material_override as ShaderMaterial
	if sm != null:
		sm.set_shader_parameter("escala", 90.0 * TAMANHO / 300.0)
	# praia: faixa de areia e rampa até o fundo do mar
	var areia := _mat_regiao("Ground080", Color(1, 0.95, 0.85), 0.3, 1.0)
	var faixa := MeshInstance3D.new()
	var fp := PlaneMesh.new()
	fp.size = Vector2(26, TAMANHO)
	faixa.mesh = fp
	faixa.material_override = _mat_plano("Ground080", Color(0.85, 0.78, 0.62), 0.3)
	faixa.position = Vector3(COSTA_X - 12.0, 0.012, 0)
	add_child(faixa)
	var rampa := MeshInstance3D.new()
	var rp := PlaneMesh.new()
	rp.size = Vector2(40, TAMANHO)
	rampa.mesh = rp
	rampa.material_override = faixa.material_override
	rampa.position = Vector3(COSTA_X + 19.0, -1.5, 0)
	rampa.rotation.z = -atan2(3.0, 40.0)
	add_child(rampa)
	areia = null

## Material de chão de região (disco com borda irregular).
func _mat_regiao(tex: String, tom: Color, escala: float, borda: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = REGIAO
	m.set_shader_parameter("tex", load(T + tex + "/" + tex + "_Color.jpg"))
	m.set_shader_parameter("tex_n", load(T + tex + "/" + tex + "_NormalGL.jpg"))
	m.set_shader_parameter("tom", tom)
	m.set_shader_parameter("escala", escala)
	m.set_shader_parameter("borda", borda)
	return m

## Material comum com textura em coordenadas do mundo (faixas retas, como a praia).
func _mat_plano(tex: String, tom: Color, escala: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(T + tex + "/" + tex + "_Color.jpg")
	m.albedo_color = tom
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * escala
	m.roughness = 1.0
	return m

func _disco(pai: Node3D, centro: Vector3, raio: float, m: Material, y := 0.014) -> void:
	var d := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(raio * 2.0, raio * 2.0)
	pm.subdivide_width = 0
	d.mesh = pm
	d.material_override = m
	d.position = centro + Vector3(0, y, 0)
	pai.add_child(d)

func _mar_e_ilha() -> void:
	var mar := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2400, 2400)
	mar.mesh = pm
	var mm := ShaderMaterial.new()
	mm.shader = MAR
	mar.material_override = mm
	mar.position = Vector3(COSTA_X + 1200.0, -0.45, 0)
	add_child(mar)
	# ilha: um morro baixo de areia com grama em cima
	var ilha := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = ILHA_R
	cm.bottom_radius = ILHA_R + 30.0
	cm.height = 3.0
	cm.radial_segments = 48
	ilha.mesh = cm
	ilha.material_override = _mat_plano("Ground080", Color(0.85, 0.78, 0.62), 0.3)
	ilha.position = ILHA + Vector3(0, -1.5, 0)
	add_child(ilha)
	var grama := _mat_regiao("Ground067", Color(0.55, 0.75, 0.4), 0.3, 0.8)
	grama.set_shader_parameter("tex", load("res://assets/textures/ground/Grass001/Grass001_1K-JPG_Color.jpg"))
	grama.set_shader_parameter("tex_n", load("res://assets/textures/ground/Grass001/Grass001_1K-JPG_NormalGL.jpg"))
	_disco(self, ILHA, ILHA_R - 14.0, grama)
	# cais da aldeia e da ilha
	add_child(_cais(CAIS_CASA, 1.0))
	add_child(_cais(CAIS_ILHA, -1.0))

## Cais de madeira saindo da terra em direção ao mar (sentido +x ou -x).
func _cais(raiz: Vector3, sentido: float) -> Node3D:
	var c := Node3D.new()
	c.position = raiz
	var tab := Construcoes.mat(Color(0.5, 0.36, 0.22))
	var poste := Construcoes.mat(Color(0.32, 0.22, 0.13))
	for k in 12:
		Construcoes.caixa(c, Vector3(sentido * (k * 1.0 + 0.5), 0.35, 0), Vector3(0.9, 0.08, 3.2), tab)
	for k in 5:
		for s2: float in [-1.0, 1.0]:
			Construcoes.tora(c, Vector3(sentido * k * 3.0, -2.0, s2 * 1.5), Vector3(sentido * k * 3.0, 0.9, s2 * 1.5), 0.12, poste)
	return c

func _estradas() -> void:
	var r := Node3D.new()
	r.name = "Estradas"
	add_child(r)
	var rio: float = jogo.RIO_R + 12.0
	Construcoes.caminho(r, Vector3(rio, 0, 0), Vector3(COSTA_X - 20.0, 0, 0), 3.4)
	Construcoes.caminho(r, Vector3(0, 0, -rio), Vector3(0, 0, -275), 3.4)
	Construcoes.caminho(r, Vector3(-rio, 0, 0), Vector3(-275, 0, 0), 3.4)
	Construcoes.caminho(r, Vector3(0, 0, rio), Vector3(0, 0, 265), 3.4)
	# placas nas entradas
	for id: String in ["escuridao", "cemiterio", "golems"]:
		var info: Dictionary = REGIOES[id]
		var c: Vector3 = info.centro
		var p := c - c.normalized() * (float(info.raio) + 8.0) + c.normalized().cross(Vector3.UP) * 3.5
		_placa(r, p, String(info.nome), atan2(c.x, c.z) + PI)
	_placa(r, CAIS_CASA + Vector3(-6, 0, 3.5), "Cais  →  Ilha dos Orcs", -PI * 0.5)

func _placa(pai: Node3D, pos: Vector3, texto: String, giro: float) -> void:
	var p := Node3D.new()
	p.position = pos
	p.rotation.y = giro
	pai.add_child(p)
	var mad := Construcoes.mat(Color(0.42, 0.29, 0.17))
	Construcoes.tora(p, Vector3.ZERO, Vector3(0, 2.6, 0), 0.09, mad)
	Construcoes.caixa(p, Vector3(0, 2.2, 0.08), Vector3(2.6, 0.6, 0.08), mad)
	var l := Label3D.new()
	l.text = texto
	l.font_size = 40
	l.pixel_size = 0.006
	l.outline_size = 8
	l.position = Vector3(0, 2.2, 0.14)
	p.add_child(l)
	var l2 := l.duplicate() as Label3D
	l2.position.z = 0.02
	l2.rotation.y = PI
	p.add_child(l2)

# ---------- peças ----------
func _cena(caminho: String) -> Node3D:
	return (load(caminho) as PackedScene).instantiate() as Node3D

## Coloca um modelo com altura `h`, girado ao acaso, com distância de desenho limitada.
func _por(pai: Node3D, caminho: String, pos: Vector3, h: float, solido := false, giro := 1000.0, cor := Color(1, 1, 1)) -> Node3D:
	var n := _cena(caminho)
	pai.add_child(n)
	Fit.to_height(n, h)
	n.position = pos
	n.rotation.y = giro if giro < 999.0 else _rng.randf() * TAU   # 1000 = ao acaso
	if cor != Color(1, 1, 1):
		Fit.tint(n, cor)
	for g: GeometryInstance3D in n.find_children("*", "GeometryInstance3D", true, false):
		g.visibility_range_end = 170.0
	if solido:
		jogo._add_collision(n)
	return n

## Muitas árvores de uma vez: cada tipo vira um MultiMesh (bem mais leve que um nó por árvore).
## `tipos` = caminhos dos modelos; altura entre hmin e hmax; `cor` multiplica a cor dos materiais.
func _floresta(pai: Node3D, tipos: Array, n: int, centro: Vector3, raio: float, miolo: float, hmin: float, hmax: float, cor: Color) -> void:
	var grupos := {}
	for k in n:
		var cam: String = tipos[k % tipos.size()]
		if not grupos.has(cam):
			grupos[cam] = []
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(hmin, hmax))
		grupos[cam].append(Transform3D(b, _ponto(centro, raio, miolo)))
	for cam: String in grupos:
		_multi(pai, cam, grupos[cam], cor)

func _multi(pai: Node3D, cam: String, lista: Array, cor: Color) -> void:
	var n := _cena(cam)
	pai.add_child(n)
	var bb := Fit.bounds(n)
	var s := 1.0 / maxf(bb.size.y, 0.001)   # a escala de cada árvore (na lista) vira a altura em metros
	var base := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), Vector3(0, -bb.position.y * s, 0))
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		var local := Transform3D.IDENTITY
		var no: Node = mi
		while no != n and no is Node3D:
			local = (no as Node3D).transform * local
			no = no.get_parent()
		var malha := mi.mesh.duplicate() as Mesh
		for i in malha.get_surface_count():
			var m := mi.get_active_material(i)
			if m is BaseMaterial3D and cor != Color(1, 1, 1):
				var m2 := m.duplicate() as BaseMaterial3D
				m2.albedo_color = Color(m2.albedo_color.r * cor.r, m2.albedo_color.g * cor.g, m2.albedo_color.b * cor.b, m2.albedo_color.a)
				m = m2
			malha.surface_set_material(i, m)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = malha
		mm.instance_count = lista.size()
		for k in lista.size():
			mm.set_instance_transform(k, (lista[k] as Transform3D) * base * local)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		pai.add_child(mmi)
	n.queue_free()

## Ponto ao acaso dentro do círculo, fora do miolo (onde fica a vila) e longe dos caminhos.
func _ponto(centro: Vector3, raio: float, miolo: float) -> Vector3:
	for tentativa in 20:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf_range(pow(miolo / raio, 2.0), 1.0)) * raio
		var p := centro + Vector3(cos(a), 0, sin(a)) * r
		var dir := centro.normalized()
		var lado := (p - centro) - dir * (p - centro).dot(dir)
		if (p - centro).dot(dir) < 0.0 and lado.length() < 5.0:
			continue   # deixa livre a estrada que chega da aldeia
		return p
	return centro + Vector3(raio, 0, 0)

func _cabana(pai: Node3D, pos: Vector3, raio: float, parede: Color, teto: Color, giro: float) -> Node3D:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = giro
	pai.add_child(c)
	var mp := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raio
	cm.bottom_radius = raio * 1.05
	cm.height = raio * 1.1
	cm.radial_segments = 12
	mp.mesh = cm
	mp.material_override = Construcoes.mat(parede)
	mp.position.y = raio * 0.55
	c.add_child(mp)
	var mt := MeshInstance3D.new()
	var ct := CylinderMesh.new()
	ct.top_radius = 0.05
	ct.bottom_radius = raio * 1.4
	ct.height = raio * 1.3
	ct.radial_segments = 12
	mt.mesh = ct
	mt.material_override = Construcoes.mat(teto)
	mt.position.y = raio * 1.1 + raio * 0.65
	c.add_child(mt)
	Construcoes.caixa(c, Vector3(0, raio * 0.4, raio * 1.03), Vector3(raio * 0.5, raio * 0.8, 0.08), Construcoes.mat(Color(0.12, 0.08, 0.05)))
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = raio
	sh.height = raio * 2.0
	cs.shape = sh
	cs.position.y = raio
	corpo.add_child(cs)
	c.add_child(corpo)
	return c

func _fogueira(pai: Node3D, pos: Vector3, h: float) -> void:
	var f := _por(pai, "res://models/Bonfire_Lit.glb", pos, h, false, 0.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.55, 0.25)
	luz.light_energy = 2.0
	luz.omni_range = 14.0
	luz.position = pos + Vector3(0, 1.5, 0)
	pai.add_child(luz)
	f.name = "Fogueira"

# ---------- monstros ----------
## Modelo KayKit (caveiras) com as animações do Rig_Medium (vêm em arquivos separados).
func _kaykit(caminho: String) -> Node3D:
	var m := _cena(caminho)
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	m.add_child(ap)
	ap.root_node = NodePath("..")
	for f: String in ["Rig_Medium_General", "Rig_Medium_MovementBasic"]:
		if not _libs.has(f):
			var r := _cena(KC + f + ".glb")
			var a := r.get_node("AnimationPlayer") as AnimationPlayer
			_libs[f] = a.get_animation_library(&"")
			r.free()
		ap.add_animation_library(f.substr(11, 1).to_lower(), _libs[f])
	return m

func _arma(m: Node3D, osso: String, caminho: String, esc: float) -> void:
	var sk := m.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var ba := BoneAttachment3D.new()
	ba.bone_name = osso
	sk.add_child(ba)
	var a := _cena(caminho)
	a.scale = Vector3.ONE * esc
	ba.add_child(a)

func caveira(tipo: int) -> Node3D:
	var nomes := ["Skeleton_Warrior", "Skeleton_Minion", "Skeleton_Rogue", "Skeleton_Mage"]
	var m := _kaykit(KC + nomes[tipo % 4] + ".glb")
	var armas := ["Skeleton_Blade", "Skeleton_Axe", "Skeleton_Crossbow", "Skeleton_Staff"]
	_arma(m, "handslot.r", KC + armas[tipo % 4] + ".gltf", 1.0)
	if tipo % 4 == 0:
		_arma(m, "handslot.l", KC + "Skeleton_Shield_Small_A.gltf", 1.0)
	return m

## Golem de pedra animado (Sketchfab, "Drugdör The Golem Animated" por Phons, CC BY).
func golem() -> Node3D:
	return _cena("res://models/sketchfab/golem.glb")

func lobisomem() -> Node3D:
	return _cena("res://models/sketchfab/lobisomem.glb")   # "Stylized Nightmarish Werewolf" por Stylized.Builder (CC BY)

## Monstro que guarda a vila: fica perto de casa e só ataca quem chega perto.
func _monstro(pai: Node3D, m: Node3D, pos: Vector3, altura: float, hp: int, dano: int, vel: float) -> void:
	var e := CharacterBody3D.new()
	e.set_script(ENEMY)
	e.collision_mask = 3
	e.max_hp = hp
	e.damage = dano
	e.speed = vel
	e.altura = altura
	e.guarda = true
	e.casa = pos
	e.setup_no(m, jogo.player)
	e.position = pos
	pai.add_child(e)
	e.killed.connect(func(): jogo.kills += 1)
	jogo.enemies.append(e)

# ---------- regiões ----------
func _escuridao(r: Node3D) -> void:
	var info: Dictionary = REGIOES.escuridao
	var c: Vector3 = info.centro
	var raio: float = info.raio
	_disco(r, c, raio, _mat_regiao("Ground067", Color(0.32, 0.27, 0.3), 0.25, 0.85))
	var escuro := Color(0.3, 0.28, 0.36)
	var tipos := []
	for k in 5:
		tipos.append(QN + "TwistedTree_%d.gltf" % (k + 1))
		tipos.append(QN + "TwistedTree_%d.gltf" % (k + 1))
		tipos.append(QN + "DeadTree_%d.gltf" % (k + 1))
	_floresta(r, tipos, 650, c, raio * 0.97, 34.0, 7.0, 14.0, escuro)
	for k in 40:
		_por(r, QN + ["Fern_1.gltf", "Mushroom_Common.gltf", "Bush_Common.gltf"][k % 3], _ponto(c, raio, 20.0), _rng.randf_range(0.5, 1.2), false, 1000.0, Color(0.4, 0.38, 0.45))
	# Vila dos Lobisomens: cabanas de palha escura em roda, fogueira, ossos e caveiras nos postes
	for k in 7:
		var a := TAU * k / 7.0 + 0.3
		_cabana(r, c + Vector3(cos(a), 0, sin(a)) * 19.0, _rng.randf_range(2.6, 3.4), Color(0.28, 0.22, 0.18), Color(0.2, 0.17, 0.12), -a - PI * 0.5)
	_fogueira(r, c, 1.6)
	for k in 10:
		var a2 := TAU * k / 10.0
		_por(r, HW + "post_skull.gltf", c + Vector3(cos(a2), 0, sin(a2)) * 28.0, 2.4, false)
	for k in 14:
		_por(r, HW + ["bone_A.gltf", "ribcage.gltf", "skull.gltf"][k % 3], _ponto(c, 15.0, 4.0), 0.4, false)
	for k in 7:
		var a3 := TAU * k / 7.0
		_monstro(r, lobisomem(), c + Vector3(cos(a3), 0, sin(a3)) * _rng.randf_range(8.0, 30.0), 2.8, 80, 12, 4.6)

func _cemiterio(r: Node3D) -> void:
	var info: Dictionary = REGIOES.cemiterio
	var c: Vector3 = info.centro
	var raio: float = info.raio
	_disco(r, c, raio, _mat_regiao("Ground054", Color(0.45, 0.47, 0.42), 0.25, 0.85))
	var cinza := Color(0.55, 0.55, 0.58)
	_floresta(r, [HW + "tree_dead_large.gltf", HW + "tree_dead_medium.gltf", HW + "tree_dead_large_decorated.gltf"], 260, c, raio * 0.95, 38.0, 6.0, 10.0, cinza)
	var mortas := []
	for k in 5:
		mortas.append(QN + "DeadTree_%d.gltf" % (k + 1))
	_floresta(r, mortas, 300, c, raio * 0.95, 38.0, 6.0, 11.0, cinza)
	# túmulos espalhados pela floresta
	for k in 90:
		_por(r, HW + ["gravestone.gltf", "grave_A.gltf", "grave_B.gltf", "gravemarker_A.gltf", "gravemarker_B.gltf"][k % 5], _ponto(c, raio * 0.9, 36.0), _rng.randf_range(0.9, 1.4), false)
	for k in 12:
		_por(r, HW + "pumpkin_orange_jackolantern.gltf", _ponto(c, raio * 0.8, 30.0), 0.5, false)
	# Vila das Caveiras: muro de cerca com portão em arco, criptas, santuário, caixões e lanternas
	var muro := 30.0
	var n := 64
	for k in n:
		var a := TAU * k / n
		var dir := Vector3(cos(a), 0, sin(a))
		if dir.dot(-c.normalized()) > 0.985:
			continue   # abertura do portão, virada para a aldeia
		_por(r, HW + ("fence_pillar.gltf" if k % 4 == 0 else ("fence_broken.gltf" if k % 7 == 3 else "fence.gltf")), c + dir * muro, 1.6, false, -a - PI * 0.5)
	var portao := c - c.normalized() * muro
	_por(r, HW + "arch_gate.gltf", portao, 5.0, false, atan2(c.x, c.z) + PI * 0.5)
	for k in 5:
		var a2 := TAU * k / 5.0 + 0.6
		_por(r, HW + "crypt.gltf", c + Vector3(cos(a2), 0, sin(a2)) * 18.0, 6.5, true, -a2 - PI * 0.5)
	_por(r, HW + "shrine_candles.gltf", c, 4.5, true, atan2(c.x, c.z))
	for k in 16:
		_por(r, HW + ["coffin.gltf", "grave_A.gltf", "candle_triple.gltf", "lantern_standing.gltf"][k % 4], _ponto(c, 26.0, 7.0), [1.1, 1.0, 0.5, 1.8][k % 4], false)
	for k in 8:
		var a3 := TAU * k / 8.0
		_monstro(r, caveira(k), c + Vector3(cos(a3), 0, sin(a3)) * _rng.randf_range(8.0, 26.0), 1.85, 50, 9, 3.2)
	# fantasmas e zumbis pelo cemitério da floresta
	for k in 4:
		var p := _ponto(c, raio * 0.6, 30.0)
		_monstro(r, _cena("res://models/monstros/" + ("Ghost.gltf" if k % 2 == 0 else "Ghost_Skull.gltf")), p, 1.8, 40, 8, 3.0)
	for k in 5:
		var p2 := _ponto(c, raio * 0.7, 32.0)
		_monstro(r, _cena("res://models/personagens/" + ("Zombie_Male.gltf" if k % 2 == 0 else "Zombie_Female.gltf")), p2, 1.75, 45, 9, 1.8)

func _golems(r: Node3D) -> void:
	var info: Dictionary = REGIOES.golems
	var c: Vector3 = info.centro
	var raio: float = info.raio
	_disco(r, c, raio * 1.25, _mat_regiao("Snow006", Color(0.86, 0.88, 0.92), 0.2, 0.8))
	# montanhas de neve em volta (e mais ao fundo)
	var mm := ShaderMaterial.new()
	mm.shader = MONTANHA
	mm.set_shader_parameter("rocha", load(T + "Rock030/Rock030_Color.jpg"))
	mm.set_shader_parameter("neve", load(T + "Snow006/Snow006_Color.jpg"))
	mm.set_shader_parameter("altura", 50.0)
	for k in 26:
		var a := TAU * k / 26.0 + _rng.randf() * 0.15
		var dir := Vector3(cos(a), 0, sin(a))
		if dir.dot(-c.normalized()) > 0.85:
			continue   # passagem livre para quem vem da aldeia
		var dist := _rng.randf_range(raio * 0.85, raio * 1.25)
		var mt := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var alt := _rng.randf_range(35.0, 85.0)
		cm.top_radius = _rng.randf_range(0.5, 3.0)
		cm.bottom_radius = alt * _rng.randf_range(0.55, 0.8)
		cm.height = alt
		cm.radial_segments = 7 + k % 4
		cm.rings = 3
		mt.mesh = cm
		mt.material_override = mm
		mt.position = c + dir * dist + Vector3(0, alt * 0.5 - 0.5, 0)
		mt.rotation.y = _rng.randf() * TAU
		mt.visibility_range_end = 600.0
		r.add_child(mt)
		var corpo := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = cm.bottom_radius * 0.8
		sh.height = alt
		cs.shape = sh
		corpo.add_child(cs)
		mt.add_child(corpo)
	var gelo := Color(0.82, 0.9, 1.0)
	var pinheiros := []
	for k in 5:
		pinheiros.append(QN + "Pine_%d.gltf" % (k + 1))
	_floresta(r, pinheiros, 500, c, raio * 0.85, 34.0, 7.0, 14.0, gelo)
	for k in 40:
		_por(r, QN + "Rock_Medium_%d.gltf" % (k % 3 + 1), _ponto(c, raio * 0.85, 30.0), _rng.randf_range(0.8, 2.5), false, 1000.0, Color(0.8, 0.84, 0.9))
	# Vila dos Golems: cabanas de pedra, círculo de pedras em pé e cristais de gelo
	for k in 6:
		var a2 := TAU * k / 6.0 + 0.5
		_cabana(r, c + Vector3(cos(a2), 0, sin(a2)) * 20.0, _rng.randf_range(3.0, 3.8), Color(0.5, 0.52, 0.55), Color(0.92, 0.95, 1.0), -a2 - PI * 0.5)
	for k in 9:
		var a3 := TAU * k / 9.0
		var pedra := _por(r, QN + "Rock_Medium_%d.gltf" % (k % 3 + 1), c + Vector3(cos(a3), 0, sin(a3)) * 9.0, 4.0, true, 1000.0, Color(0.6, 0.62, 0.66))
		pedra.scale.y *= 1.8
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.55, 0.85, 1.0, 0.8)
	cristal.emission_enabled = true
	cristal.emission = Color(0.3, 0.7, 1.0)
	cristal.emission_energy_multiplier = 1.2
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for k in 12:
		var cr := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.6, _rng.randf_range(1.5, 3.5), 0.6)
		cr.mesh = pm
		cr.material_override = cristal
		var p := _ponto(c, 30.0, 10.0)
		cr.position = p + Vector3(0, pm.size.y * 0.45, 0)
		cr.rotation = Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf() * TAU, _rng.randf_range(-0.3, 0.3))
		r.add_child(cr)
	for k in 5:
		var a4 := TAU * k / 5.0
		_monstro(r, golem(), c + Vector3(cos(a4), 0, sin(a4)) * _rng.randf_range(12.0, 30.0), 3.3, 200, 20, 2.3)
	# yetis nas montanhas de neve
	for k in 4:
		_monstro(r, _cena("res://models/monstros/Yeti.gltf"), _ponto(c, raio * 0.7, 40.0), 2.6, 120, 15, 3.4)

func _ilha_orcs(r: Node3D) -> void:
	var c: Vector3 = ILHA
	var comuns := []
	for k in 5:
		comuns.append(QN + "CommonTree_%d.gltf" % (k + 1))
	_floresta(r, comuns, 320, c, ILHA_R - 20.0, 36.0, 7.0, 12.0, Color(0.85, 1.0, 0.8))
	for k in 30:
		_por(r, QN + ["Bush_Common.gltf", "Plant_7_Big.gltf", "Fern_1.gltf"][k % 3], _ponto(c, ILHA_R - 16.0, 30.0), _rng.randf_range(0.8, 1.8), false)
	# Vila dos Orcs: paliçada de troncos, tendas de couro, totens com caveira e fogueira
	var tronco := Construcoes.mat(Color(0.4, 0.28, 0.16))
	var n := 150
	for k in n:
		var a := TAU * k / n
		var dir := Vector3(cos(a), 0, sin(a))
		if dir.x < -0.97:
			continue   # portão virado para o cais
		var h := _rng.randf_range(3.2, 4.2)
		Construcoes.tora(r, c + dir * 26.0, c + dir * 26.0 + Vector3(0, h, 0), 0.32, tronco)
	var corpo := StaticBody3D.new()
	r.add_child(corpo)
	for k in 16:
		var a2 := TAU * (k + 0.5) / 16.0
		var dir2 := Vector3(cos(a2), 0, sin(a2))
		if dir2.x < -0.95:
			continue
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(10.4, 4.0, 0.8)
		cs.shape = sh
		cs.position = c + dir2 * 26.0 + Vector3(0, 2, 0)
		cs.rotation.y = -a2 + PI * 0.5
		corpo.add_child(cs)
	var couro := [Color(0.55, 0.4, 0.25), Color(0.45, 0.3, 0.2), Color(0.6, 0.5, 0.35)]
	for k in 8:
		var a3 := TAU * k / 8.0 + 0.2
		var tenda := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.1
		cm.bottom_radius = 3.2
		cm.height = 4.5
		cm.radial_segments = 8
		tenda.mesh = cm
		tenda.material_override = Construcoes.mat(couro[k % 3])
		tenda.position = c + Vector3(cos(a3), 0, sin(a3)) * 16.0 + Vector3(0, 2.25, 0)
		r.add_child(tenda)
		for s2: float in [-0.5, 0.5]:
			Construcoes.tora(r, tenda.position + Vector3(s2, 1.8, 0), tenda.position + Vector3(s2 * 2.0, 3.0, 0), 0.06, tronco)
		var cb := StaticBody3D.new()
		var cs2 := CollisionShape3D.new()
		var sh2 := CylinderShape3D.new()
		sh2.radius = 2.6
		sh2.height = 4.0
		cs2.shape = sh2
		cb.add_child(cs2)
		tenda.add_child(cb)
	for k in 4:
		var a4 := TAU * k / 4.0 + PI * 0.25
		var p := c + Vector3(cos(a4), 0, sin(a4)) * 9.0
		var pinta := [Color(0.6, 0.15, 0.1), Color(0.35, 0.25, 0.15), Color(0.2, 0.35, 0.2)]
		for j in 3:
			Construcoes.caixa(r, p + Vector3(0, 0.6 + j * 1.1, 0), Vector3(0.9 - j * 0.1, 1.0, 0.9 - j * 0.1), Construcoes.mat(pinta[(j + k) % 3]))
		_por(r, HW + "skull.gltf", p + Vector3(0, 3.6, 0), 0.6, false, a4)
	_fogueira(r, c, 1.8)
	for k in 8:
		var a5 := TAU * k / 8.0
		_monstro(r, (jogo.ORC as PackedScene).instantiate(), c + Vector3(cos(a5), 0, sin(a5)) * _rng.randf_range(6.0, 22.0), 1.95, 60, 10, 3.3)

# ---------- neve ----------
func _flocos() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 700
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.visibility_aabb = AABB(Vector3(-40, -20, -40), Vector3(80, 40, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(35, 1, 35)
	pm.direction = Vector3(0.2, -1, 0.1)
	pm.spread = 15.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 2.2
	pm.gravity = Vector3(0, -0.4, 0)
	pm.turbulence_enabled = false
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var mf := StandardMaterial3D.new()
	mf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mf.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mf.albedo_color = Color(1, 1, 1, 0.9)
	mf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = mf
	p.draw_pass_1 = q
	p.emitting = false
	p.visible = false
	return p

# ---------- barcos ----------
static func barco(vela: Color) -> Node3D:
	var b := Node3D.new()
	var casco := Construcoes.mat(Color(0.42, 0.27, 0.15))
	var escuro := Construcoes.mat(Color(0.3, 0.19, 0.1))
	Construcoes.caixa(b, Vector3(0, 0.15, 0), Vector3(2.4, 0.3, 6.0), escuro)          # fundo
	for s2: float in [-1.0, 1.0]:
		var lado := Construcoes.caixa(b, Vector3(s2 * 1.25, 0.6, 0), Vector3(0.12, 0.9, 6.0), casco)
		lado.rotation.z = s2 * 0.25
	Construcoes.caixa(b, Vector3(0, 0.6, -3.0), Vector3(2.5, 0.9, 0.12), casco)        # popa
	var proa := MeshInstance3D.new()
	var pr := PrismMesh.new()
	pr.size = Vector3(2.5, 1.5, 0.9)   # triângulo deitado: a ponta aponta para a frente (+z)
	proa.mesh = pr
	proa.material_override = casco
	proa.position = Vector3(0, 0.6, 3.74)
	proa.rotation = Vector3(PI * 0.5, 0, 0)
	b.add_child(proa)
	Construcoes.caixa(b, Vector3(0, 0.45, 0), Vector3(2.3, 0.06, 5.6), Construcoes.mat(Color(0.55, 0.4, 0.25)))   # convés
	Construcoes.tora(b, Vector3(0, 0.4, 0.6), Vector3(0, 6.0, 0.6), 0.1, escuro)                                   # mastro
	Construcoes.tora(b, Vector3(-1.6, 5.4, 0.7), Vector3(1.6, 5.4, 0.7), 0.06, escuro)
	var mv := StandardMaterial3D.new()
	mv.albedo_color = vela
	mv.cull_mode = BaseMaterial3D.CULL_DISABLED
	mv.roughness = 1.0
	var v := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(3.0, 3.8)
	v.mesh = q
	v.material_override = mv
	v.position = Vector3(0, 3.45, 0.75)
	b.add_child(v)
	return b

## Ponto sobre o mar, à frente de um cais, onde o barco encosta.
func _doca(cais: Vector3, sentido: float) -> Vector3:
	return cais + Vector3(sentido * 13.0, 0, -3.5)

func _rota(de: Vector3, ate: Vector3, t: float) -> Vector3:
	var p := de.lerp(ate, t)
	p.z += sin(t * PI) * -40.0   # faz uma curva pelo mar
	return p

func _embarcar() -> void:
	if not _viagem.is_empty():
		return
	var na_ilha: bool = jogo.player.global_position.distance_to(ILHA) < ILHA_R + 20.0
	var de := _doca(CAIS_ILHA, -1.0) if na_ilha else _doca(CAIS_CASA, 1.0)
	var ate := _doca(CAIS_CASA, 1.0) if na_ilha else _doca(CAIS_ILHA, -1.0)
	var chegada := CAIS_CASA + Vector3(-2, 0, 0) if na_ilha else CAIS_ILHA + Vector3(2, 0, 0)
	_viagem = {"t": 0.0, "de": de, "ate": ate, "chegada": chegada}
	_botao.visible = false
	jogo.player.set_physics_process(false)
	jogo.say("Navegando para " + ("a aldeia" if na_ilha else "a Ilha dos Orcs") + "...", 4.0)

func _navegar(delta: float) -> void:
	_viagem.t = float(_viagem.t) + delta / VIAGEM
	var t: float = minf(1.0, _viagem.t)
	var p := _rota(_viagem.de, _viagem.ate, t)
	var p2 := _rota(_viagem.de, _viagem.ate, minf(1.0, t + 0.01))
	if p2.distance_to(p) > 0.001:
		_barco.rotation.y = atan2(p2.x - p.x, p2.z - p.z)
	_barco.position = p + Vector3(0, -0.25 + sin(Time.get_ticks_msec() * 0.002) * 0.06, 0)
	jogo.player.global_position = _barco.global_position + Vector3(0, 0.5, 0)
	jogo.player.rotation.y = _barco.rotation.y
	if t >= 1.0:
		jogo.player.global_position = _viagem.chegada
		_ok = _viagem.chegada
		jogo.player.set_physics_process(true)
		_viagem = {}

## Barco dos orcs: sai da ilha, atraca no cais da aldeia (os orcs desembarcam) e volta.
func _barco_dos_orcs(delta: float) -> void:
	_orc_t += delta
	var ida := _doca(CAIS_ILHA, -1.0) + Vector3(0, 0, 7)
	var volta := _doca(CAIS_CASA, 1.0) + Vector3(0, 0, 7)
	match _orc_estado:
		"ilha":
			_barco_orc.position = ida
			if _orc_t > 50.0:
				_orc_estado = "indo"
				_orc_t = 0.0
		"indo", "voltando":
			var t := minf(1.0, _orc_t / VIAGEM)
			var de := ida if _orc_estado == "indo" else volta
			var ate := volta if _orc_estado == "indo" else ida
			var p := de.lerp(ate, t)
			p.z += sin(t * PI) * 30.0
			var p2 := de.lerp(ate, minf(1.0, t + 0.01))
			p2.z += sin(minf(1.0, t + 0.01) * PI) * 30.0
			_barco_orc.rotation.y = atan2(p2.x - p.x, p2.z - p.z)
			_barco_orc.position = p + Vector3(0, -0.25, 0)
			if t >= 1.0:
				_orc_estado = "atracado" if _orc_estado == "indo" else "ilha"
				_orc_t = 0.0
				if _orc_estado == "atracado" and jogo.player.global_position.length() < 200.0:
					jogo.say("Um barco de orcs chegou ao cais!", 4.0)
		"atracado":
			_barco_orc.position = volta + Vector3(0, -0.25, 0)
			if _orc_t > 45.0:
				_orc_estado = "voltando"
				_orc_t = 0.0

## Onde os orcs desembarcam (só com o barco deles atracado na aldeia); null se não há barco.
func ponto_orc() -> Variant:
	if _orc_estado != "atracado":
		return null
	return CAIS_CASA + Vector3(-3.0, 0, _rng.randf_range(-1.5, 1.5))

# ---------- a cada quadro ----------
## Terra firme: dentro do mapa, a oeste da costa ou na ilha.
func terra(p: Vector3) -> bool:
	if absf(p.z) > TAMANHO * 0.5 - 5.0 or p.x < -TAMANHO * 0.5 + 5.0:
		return false
	if p.x < COSTA_X + 1.0:
		return true
	if Vector2(p.x - ILHA.x, p.z - ILHA.z).length() < ILHA_R - 3.0:
		return true
	# em cima dos cais
	for cais: Vector3 in [CAIS_CASA, CAIS_ILHA]:
		if absf(p.z - cais.z) < 1.6 and absf(p.x - cais.x) < 12.0 and (p.x - cais.x) * (1.0 if cais == CAIS_CASA else -1.0) > -1.0:
			return true
	return false

func _process(delta: float) -> void:
	if jogo == null or jogo.player == null:
		return
	var pj: Vector3 = jogo.player.global_position
	var fora: bool = jogo._dentro == ""
	# regiões longe não são desenhadas
	var atual := ""
	var peso := 0.0
	for id: String in REGIOES:
		var info: Dictionary = REGIOES[id]
		var d := Vector2(pj.x - info.centro.x, pj.z - info.centro.z).length()
		var r: Node3D = regioes[id]
		r.visible = fora and d < float(info.raio) + LONGE
		var w := 1.0 - smoothstep(float(info.raio) * 0.6, float(info.raio) * 1.05, d)
		if w > peso:
			peso = w
			atual = id
	if atual != regiao_atual and peso > 0.5:
		regiao_atual = atual
		var info2: Dictionary = REGIOES[atual]
		jogo.say("%s\n%s" % [info2.nome, info2.vila], 5.0)
	elif peso < 0.2:
		regiao_atual = ""
	# neblina e escuridão da região
	if jogo.ceu != null:
		var ceu = jogo.ceu
		if atual != "" and fora:
			var info3: Dictionary = REGIOES[atual]
			ceu.reg_cor = info3.neblina
			ceu.reg_peso = peso
			ceu.reg_dens = float(info3.dens) * peso
			ceu.reg_escuro = float(info3.escuro) * peso
			ceu.reg_ceu = float(info3.ceu) * peso
		else:
			ceu.reg_peso = 0.0
			ceu.reg_dens = 0.0
			ceu.reg_escuro = 0.0
			ceu.reg_ceu = 0.0
	# neve caindo na região dos golems
	var nevando := fora and atual == "golems" and peso > 0.3
	_neve.visible = nevando
	_neve.emitting = nevando
	if nevando:
		_neve.global_position = pj + Vector3(0, 14, 0)
	# barcos
	_barco_dos_orcs(delta)
	if not _viagem.is_empty():
		_navegar(delta)
		return
	var perto_cais := pj.distance_to(CAIS_CASA + Vector3(10, 0, 0)) < 5.0 or pj.distance_to(CAIS_ILHA + Vector3(-10, 0, 0)) < 5.0
	_botao.visible = fora and perto_cais
	if pj.distance_to(CAIS_CASA + Vector3(10, 0, 0)) < 15.0:
		_barco.position = _doca(CAIS_CASA, 1.0) + Vector3(0, -0.25, 0)
		_barco.rotation.y = PI * 0.5
	elif pj.distance_to(CAIS_ILHA + Vector3(-10, 0, 0)) < 15.0:
		_barco.position = _doca(CAIS_ILHA, -1.0) + Vector3(0, -0.25, 0)
		_barco.rotation.y = -PI * 0.5
	# não entra no mar andando
	if fora:
		if terra(pj):
			_ok = pj
		else:
			jogo.player.global_position = Vector3(_ok.x, pj.y, _ok.z)
