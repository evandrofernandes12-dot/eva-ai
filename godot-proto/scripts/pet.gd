class_name Pet
extends Node3D
## Pets das classes: cavalo alado branco (guerreiro), urso branco malhado (lanceiro), lobo cinza (arqueiro).
## A fênix do mago está em fenix.gd. Os corpos são montados por código (elipsoides com textura de pelo gerada);
## para usar um modelo realista de verdade, ponha `models/pets/<tipo>.glb` (cavalo, urso, lobo): ele substitui o corpo de código.
## Os pets seguem o dono e, quando um inimigo chega perto, avançam e dão uma mordida/patada/coice (DANO) e voltam.

const GUARDA := 6.0       # raio (m) ao redor do dono em que o pet ataca sozinho
const RECARGA := 1.6      # segundos entre ataques
const DANO := 5           # dano por golpe

var tipo := "lobo"        # cavalo, urso, lobo
var dono: Node3D
var jogo: Node
var estado := "segue"     # segue, ataca, volta
var _t := 0.0
var _cd := 1.0
var _ciclo := 0.0
var _alvo: Node3D
var _voa := false
var _vel := 0.0
var _pernas: Array = []   # [quadril, joelho, fase]
var _asas: Array = []     # [pivô, lado]
var _corpo: Node3D
var _cauda: Node3D
var _anim: AnimationPlayer
var _velocidade := 6.5

static var _tex := {}

# ---------- utilidades de modelagem ----------
## Pena (folha) de malha própria, estendida em +X, com cor de uma ponta à outra (usada pelas asas e caudas).
static func pena(comp: float, larg: float, c0: Color, c1: Color, n := 8) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var w0 := larg * 0.5 * sin(PI * pow(t0, 0.55))
		var w1 := larg * 0.5 * sin(PI * pow(t1, 0.55))
		var a := Vector3(t0 * comp, 0, -w0)
		var b := Vector3(t0 * comp, 0, w0)
		var c := Vector3(t1 * comp, 0, -w1)
		var d := Vector3(t1 * comp, 0, w1)
		var k0 := c0.lerp(c1, t0)
		var k1 := c0.lerp(c1, t1)
		for v in [[a, k0], [b, k0], [c, k1], [b, k0], [d, k1], [c, k1]]:
			st.set_normal(Vector3.UP)
			st.set_color(v[1])
			st.add_vertex(v[0])
	return st.commit()

## Material de pelo: textura gerada (base + manchas claras/escuras + fios), aplicada em triplanar.
static func pelo(chave: String, base: Color, claro: Color, escuro: Color, manchas: float, escala := 0.9) -> StandardMaterial3D:
	if not _tex.has(chave):
		var img := Image.create(160, 160, false, Image.FORMAT_RGB8)
		var nb := FastNoiseLite.new()
		nb.seed = chave.hash() % 1000
		nb.frequency = 0.045
		var nf := FastNoiseLite.new()
		nf.seed = nb.seed + 7
		nf.frequency = 0.3
		var ns := FastNoiseLite.new()    # fios: esticado na vertical
		ns.seed = nb.seed + 13
		ns.frequency = 0.5
		for y in 160:
			for x in 160:
				var cor := base
				var blot := nb.get_noise_2d(x, y)
				if blot > 0.18:
					cor = cor.lerp(escuro, clampf((blot - 0.18) * 4.0 * manchas, 0.0, 0.85))
				elif blot < -0.2:
					cor = cor.lerp(claro, clampf((-blot - 0.2) * 4.0, 0.0, 0.8))
				var fino := nf.get_noise_2d(x, y)
				if fino > 0.4:
					cor = cor.lerp(escuro, (fino - 0.4) * 1.1 * manchas)
				var fio := ns.get_noise_2d(x * 0.25, y * 1.6)
				cor = cor * (1.0 + fio * 0.14)
				img.set_pixel(x, y, cor)
		_tex[chave] = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex[chave]
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * escala
	m.roughness = 0.95
	return m

static func liso(cor: Color, rugosidade := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	return m

static func _mat_pena(vertice := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = vertice
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.8
	return m

func _elip(pai: Node3D, pos: Vector3, esc: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.5
	sp.height = 1.0
	sp.radial_segments = 20
	sp.rings = 10
	mi.mesh = sp
	mi.material_override = mat
	mi.position = pos
	mi.scale = esc
	mi.rotation_degrees = rot
	pai.add_child(mi)
	return mi

func _cone(pai: Node3D, pos: Vector3, raio: float, alt: float, mat: Material, rot := Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = raio
	cm.height = alt
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	pai.add_child(mi)

func _cap(pai: Node3D, pos: Vector3, raio: float, alt: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = raio
	cm.height = maxf(alt, raio * 2.0)
	cm.radial_segments = 14
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)

## Perna de dois segmentos (quadril -> joelho -> pata). Pivôs giram no eixo X.
func _perna(pos: Vector3, c1: float, c2: float, r1: float, r2: float, mat: Material, pata: Material, pata_esc: Vector3, fase: float) -> void:
	var q := Node3D.new()
	q.position = pos
	_corpo.add_child(q)
	_cap(q, Vector3(0, -c1 * 0.5, 0), r1, c1 + r1, mat)
	var j := Node3D.new()
	j.position = Vector3(0, -c1, 0)
	q.add_child(j)
	_cap(j, Vector3(0, -c2 * 0.5, 0), r2, c2 + r2, mat)
	_elip(j, Vector3(0, -c2 - pata_esc.y * 0.2, -pata_esc.z * 0.18), pata_esc, pata)
	_pernas.append([q, j, fase])

func _olhos(pai: Node3D, y: float, z: float, x: float, tam: float) -> void:
	for lado in [-1.0, 1.0]:
		_elip(pai, Vector3(lado * x, y, z), Vector3.ONE * tam, liso(Color(0.04, 0.03, 0.02), 0.2))

# ---------- construção de cada pet ----------
func _ready() -> void:
	_corpo = Node3D.new()
	add_child(_corpo)
	var caminho := "res://models/pets/%s.glb" % tipo
	if ResourceLoader.exists(caminho):   # modelo realista fornecido pelo usuário
		var m: Node3D = load(caminho).instantiate()
		_corpo.add_child(m)
		_anim = Fit.find_node_of(m, "AnimationPlayer") as AnimationPlayer
	else:
		match tipo:
			"cavalo":
				_cavalo()
			"urso":
				_urso()
			_:
				_lobo()
	_voa = tipo == "cavalo"
	_velocidade = {"cavalo": 8.0, "urso": 5.5, "lobo": 8.0}.get(tipo, 6.5)

func _lobo() -> void:
	var pl := pelo("lobo", Color(0.42, 0.43, 0.45), Color(0.62, 0.63, 0.64), Color(0.2, 0.2, 0.22), 1.0)
	var barriga := pelo("lobo_claro", Color(0.66, 0.66, 0.65), Color(0.8, 0.8, 0.78), Color(0.45, 0.45, 0.45), 0.5)
	var escuro := liso(Color(0.12, 0.12, 0.13), 0.8)
	_elip(_corpo, Vector3(0, 0.66, 0.05), Vector3(0.36, 0.4, 0.9), pl)                    # tronco
	_elip(_corpo, Vector3(0, 0.7, -0.3), Vector3(0.38, 0.46, 0.5), pl)                    # peito e ombros
	_elip(_corpo, Vector3(0, 0.52, -0.05), Vector3(0.3, 0.2, 0.8), barriga)               # barriga clara
	_elip(_corpo, Vector3(0, 0.8, -0.58), Vector3(0.2, 0.22, 0.42), pl, Vector3(35, 0, 0)) # pescoço
	_elip(_corpo, Vector3(0, 0.88, -0.78), Vector3(0.2, 0.2, 0.28), pl)                   # cabeça
	_elip(_corpo, Vector3(0, 0.83, -0.97), Vector3(0.11, 0.1, 0.24), barriga)             # focinho
	_elip(_corpo, Vector3(0, 0.86, -1.09), Vector3(0.06, 0.05, 0.05), escuro)             # nariz
	for lado in [-1.0, 1.0]:
		_cone(_corpo, Vector3(lado * 0.075, 1.04, -0.72), 0.05, 0.16, pl, Vector3(-10, 0, -lado * 8))   # orelhas
	_olhos(_corpo, 0.91, -0.9, 0.075, 0.035)
	for p in [[-0.14, -0.38, 0.0], [0.14, -0.38, PI], [-0.14, 0.36, PI], [0.14, 0.36, 0.0]]:
		_perna(Vector3(p[0], 0.58, p[1]), 0.28, 0.3, 0.06, 0.045, pl, escuro, Vector3(0.09, 0.07, 0.16), p[2])
	_cauda = Node3D.new()
	_cauda.position = Vector3(0, 0.72, 0.5)
	_corpo.add_child(_cauda)
	_elip(_cauda, Vector3(0, -0.12, 0.22), Vector3(0.14, 0.14, 0.55), pl, Vector3(-45, 0, 0))

func _urso() -> void:
	var pl := pelo("urso", Color(0.92, 0.92, 0.9), Color(0.97, 0.97, 0.96), Color(0.34, 0.34, 0.36), 1.25, 0.6)
	var cinza := pelo("urso_cinza", Color(0.8, 0.8, 0.79), Color(0.9, 0.9, 0.9), Color(0.5, 0.5, 0.52), 0.8, 0.6)
	var preto := liso(Color(0.05, 0.05, 0.05), 0.5)
	_elip(_corpo, Vector3(0, 0.95, 0.1), Vector3(0.85, 0.9, 1.6), pl)                      # tronco
	_elip(_corpo, Vector3(0, 1.1, -0.5), Vector3(0.8, 0.8, 0.8), pl)                       # cernelha (ombros altos)
	_elip(_corpo, Vector3(0, 0.95, 0.75), Vector3(0.75, 0.8, 0.7), cinza)                  # garupa
	_elip(_corpo, Vector3(0, 1.0, -1.05), Vector3(0.46, 0.46, 0.5), pl)                    # cabeça
	_elip(_corpo, Vector3(0, 0.9, -1.38), Vector3(0.24, 0.2, 0.32), cinza)                 # focinho
	_elip(_corpo, Vector3(0, 0.96, -1.55), Vector3(0.1, 0.07, 0.08), preto)                # nariz
	for lado in [-1.0, 1.0]:
		_elip(_corpo, Vector3(lado * 0.2, 1.27, -0.95), Vector3(0.14, 0.14, 0.1), pl)      # orelhas redondas
	_olhos(_corpo, 1.05, -1.3, 0.14, 0.04)
	for p in [[-0.28, -0.55, 0.0], [0.28, -0.55, PI], [-0.28, 0.8, PI], [0.28, 0.8, 0.0]]:
		_perna(Vector3(p[0], 0.7, p[1]), 0.36, 0.34, 0.17, 0.13, pl, cinza, Vector3(0.26, 0.12, 0.38), p[2])
	_cauda = Node3D.new()
	_cauda.position = Vector3(0, 1.0, 1.15)
	_corpo.add_child(_cauda)
	_elip(_cauda, Vector3(0, 0, 0.06), Vector3(0.14, 0.14, 0.16), pl)

func _cavalo() -> void:
	var pl := pelo("cavalo", Color(0.96, 0.96, 0.97), Color(1.0, 1.0, 1.0), Color(0.72, 0.73, 0.76), 0.35, 0.8)
	var crina := liso(Color(0.92, 0.93, 0.96), 0.9)
	var casco := liso(Color(0.35, 0.34, 0.33), 0.6)
	var preto := liso(Color(0.04, 0.03, 0.03), 0.2)
	_elip(_corpo, Vector3(0, 1.25, 0.05), Vector3(0.62, 0.72, 1.5), pl)
	_elip(_corpo, Vector3(0, 1.28, 0.62), Vector3(0.6, 0.7, 0.7), pl)                      # garupa
	_elip(_corpo, Vector3(0, 1.32, -0.55), Vector3(0.6, 0.82, 0.7), pl)                    # peito
	_elip(_corpo, Vector3(0, 1.8, -0.98), Vector3(0.3, 0.3, 0.95), pl, Vector3(35, 0, 0))  # pescoço
	_elip(_corpo, Vector3(0, 2.1, -1.38), Vector3(0.27, 0.3, 0.62), pl, Vector3(-24, 0, 0))   # cabeça
	_elip(_corpo, Vector3(0, 1.98, -1.66), Vector3(0.17, 0.17, 0.34), pl, Vector3(-24, 0, 0))   # focinho
	_elip(_corpo, Vector3(0, 1.93, -1.82), Vector3(0.1, 0.07, 0.07), preto)
	for lado in [-1.0, 1.0]:
		_cone(_corpo, Vector3(lado * 0.09, 2.38, -1.27), 0.06, 0.2, pl, Vector3(-10, 0, -lado * 6))
	_olhos(_corpo, 2.15, -1.46, 0.14, 0.04)
	for i in 6:   # crina pelo alto do pescoço
		var f := i / 5.0
		_elip(_corpo, Vector3(0, 2.2 - f * 0.6, -1.12 + f * 0.55), Vector3(0.06, 0.2, 0.3), crina, Vector3(35, 0, 0))
	for p in [[-0.2, -0.55, 0.0], [0.2, -0.55, PI], [-0.2, 0.7, PI], [0.2, 0.7, 0.0]]:
		_perna(Vector3(p[0], 1.0, p[1]), 0.52, 0.55, 0.09, 0.06, pl, casco, Vector3(0.12, 0.09, 0.16), p[2])
	_cauda = Node3D.new()
	_cauda.position = Vector3(0, 1.45, 0.95)
	_corpo.add_child(_cauda)
	_elip(_cauda, Vector3(0, -0.4, 0.2), Vector3(0.16, 0.9, 0.2), crina, Vector3(-15, 0, 0))
	_elip(_cauda, Vector3(0, -0.85, 0.32), Vector3(0.12, 0.6, 0.16), crina, Vector3(-20, 0, 0))
	# asas emplumadas: 9 penas longas + 5 curtas (cobertura) de cada lado, brancas com pontas cinza-claro
	for lado in [-1.0, 1.0]:
		var pivo := Node3D.new()
		pivo.position = Vector3(lado * 0.3, 1.75, -0.1)
		pivo.scale.x = lado   # a esquerda é a direita espelhada
		_corpo.add_child(pivo)
		for i in 9:
			var mi := MeshInstance3D.new()
			mi.mesh = pena(1.5 - i * 0.07, 0.34, Color(1, 1, 1), Color(0.82, 0.84, 0.9))
			mi.material_override = _mat_pena()
			mi.rotation_degrees = Vector3(0, 22 - i * 9.0, 0)
			mi.position = Vector3(0.05, 0.01 * i, 0.0)
			pivo.add_child(mi)
		for i in 5:
			var mc := MeshInstance3D.new()
			mc.mesh = pena(0.7 - i * 0.05, 0.3, Color(1, 1, 1), Color(0.9, 0.91, 0.95))
			mc.material_override = _mat_pena()
			mc.rotation_degrees = Vector3(0, 15 - i * 12.0, 0)
			mc.position = Vector3(0.05, 0.05 + 0.01 * i, 0.0)
			pivo.add_child(mc)
		_asas.append([pivo, lado])

# ---------- comportamento ----------
func _inimigo(raio: float) -> Node3D:
	var melhor: Node3D = null
	var bd := raio
	for e in jogo.enemies:
		if is_instance_valid(e) and not e._dead:
			var d: float = e.global_position.distance_to(dono.global_position)
			if d < bd:
				bd = d
				melhor = e
	return melhor

func atacar(alvo: Node3D) -> void:
	if estado != "segue" or _cd > 0.0 or not is_instance_valid(alvo):
		return
	_alvo = alvo
	estado = "ataca"

## Onde o pet fica: ao lado e um pouco atrás do dono (o cavalo alado voa à altura da cintura).
func _posto() -> Vector3:
	var f := Vector3(dono.global_basis.z.x, 0, dono.global_basis.z.z).normalized()
	var lado := f.cross(Vector3.UP)
	var p := dono.global_position - f * 1.9 + lado * 1.7
	p.y = 1.7 + sin(_t * 1.6) * 0.15 if _voa else 0.0
	return p

func _virar(dir: Vector3, delta: float) -> void:
	var h := Vector3(dir.x, 0, dir.z)
	if h.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-h.x, -h.z), minf(1.0, 9.0 * delta))

func _process(delta: float) -> void:
	if dono == null or not is_instance_valid(dono):
		queue_free()
		return
	var fora: bool = jogo._dentro == ""
	if visible != fora:
		visible = fora
		if fora:
			global_position = _posto()
	if not fora:
		return
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	var antes := global_position
	match estado:
		"segue":
			var posto := _posto()
			var to := posto - global_position
			var d := to.length()
			if d > 28.0:
				global_position = posto
			elif d > 0.5:
				var v := minf(_velocidade, d * 3.0)
				global_position += to.normalized() * v * delta
				_virar(to, delta)
			else:
				_virar(dono.global_basis.z, delta)
			if _cd <= 0.0:
				var e := _inimigo(GUARDA)
				if e != null:
					atacar(e)
		"ataca":
			if not is_instance_valid(_alvo) or _alvo._dead:
				estado = "volta"
			else:
				var dest: Vector3 = _alvo.global_position + Vector3(0, 1.0 if _voa else 0.0, 0)
				var to2 := dest - global_position
				var d2 := to2.length()
				_virar(to2, delta)
				if d2 < 1.9:
					_alvo.hurt(DANO)
					jogo.flash(_alvo.global_position + Vector3(0, 0.9, 0), Color(1.0, 0.9, 0.7), 0.5, 0.2)
					_cd = RECARGA
					estado = "volta"
				else:
					global_position += to2 / d2 * minf(d2, 13.0 * delta)
		"volta":
			var to3 := _posto() - global_position
			_virar(to3, delta)
			if to3.length() < 1.0:
				estado = "segue"
			else:
				global_position += to3.normalized() * minf(to3.length(), 12.0 * delta)
	_vel = lerpf(_vel, (global_position - antes).length() / maxf(delta, 0.0001), minf(1.0, 8.0 * delta))
	_animar(delta)

func _animar(delta: float) -> void:
	var anda := clampf(_vel / 4.0, 0.0, 1.5)
	if _anim != null:   # modelo fornecido pelo usuário: usa as animações dele (Walk/Idle), se existirem
		Fit.play(_anim, Fit.find_anim(_anim, ["Walk", "Run", "Fly"] if anda > 0.2 else ["Idle", "Stand"]))
		return
	_ciclo += delta * (3.0 + _vel * 1.6)
	for p in _pernas:
		if _voa:   # cavalo alado: pernas recolhidas e balançando pouco
			p[0].rotation.x = 0.55 + sin(_ciclo * 0.6 + p[2]) * 0.12 * anda
			p[1].rotation.x = -1.2
		else:
			var a := sin(_ciclo + p[2])
			p[0].rotation.x = a * 0.55 * anda
			p[1].rotation.x = -maxf(0.0, -sin(_ciclo + p[2] + 1.2)) * 0.8 * anda - 0.05
	for a in _asas:
		a[0].rotation.z = a[1] * (0.45 + sin(_t * 3.2) * 0.5)
	if _cauda != null:
		_cauda.rotation.y = sin(_t * 2.4) * 0.25
	if _voa:
		_corpo.rotation.x = -0.05 - anda * 0.08
	else:
		_corpo.position.y = absf(sin(_ciclo)) * 0.03 * anda
