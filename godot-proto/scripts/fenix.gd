extends Node3D
## Fênix de fogo do mago: paira um pouco acima da cabeça dele. Quando o mago ataca, ou um inimigo chega perto,
## ela mergulha como uma flecha de fogo, causa dano alto em área pequena e volta. O corpo é feito por código.

const GUARDA := 7.0       # raio (m) em que ela defende o mago sozinha
const VOO := 24.0         # velocidade do mergulho (m/s)
const RECARGA := 2.2      # segundos entre ataques

var dono: Node3D          # o mago (Jogador)
var jogo: Node            # main.gd
var estado := "paira"     # paira, ataca, volta
var _t := 0.0
var _cd := 1.0
var _ang := 0.0
var _alvo: Node3D
var _asas: Array = []     # [pivô, lado]
var _rastro: CPUParticles3D

func _ready() -> void:
	_montar()

static func _mat(cor: Color, alfa := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(cor.r, cor.g, cor.b, alfa)
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _peca(pai: Node3D, malha: Mesh, cor: Color, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = _mat(cor)
	mi.position = pos
	mi.rotation_degrees = rot
	pai.add_child(mi)
	return mi

## Modelo virado para -Z (o bico aponta para -Z, a cauda vai para +Z). Envergadura de ~2,2 m.
func _montar() -> void:
	var laranja := Color(1.0, 0.45, 0.05)
	var amarelo := Color(1.0, 0.85, 0.2)
	var vermelho := Color(0.9, 0.12, 0.04)
	var corpo := SphereMesh.new()
	corpo.radius = 0.5
	corpo.height = 1.0
	var c := _peca(self, corpo, laranja, Vector3.ZERO)
	c.scale = Vector3(0.34, 0.3, 0.8)
	var cab := SphereMesh.new()
	cab.radius = 0.5
	cab.height = 1.0
	var h := _peca(self, cab, amarelo, Vector3(0, 0.13, -0.5))
	h.scale = Vector3.ONE * 0.24
	var bico := CylinderMesh.new()
	bico.top_radius = 0.0
	bico.bottom_radius = 0.06
	bico.height = 0.25
	_peca(self, bico, Color(1.0, 0.95, 0.4), Vector3(0, 0.1, -0.72), Vector3(-90, 0, 0))   # ápice (+Y) vira -Z
	for i in 3:   # crista na cabeça
		var cr := CylinderMesh.new()
		cr.top_radius = 0.0
		cr.bottom_radius = 0.035
		cr.height = 0.26
		_peca(self, cr, vermelho if i != 1 else amarelo, Vector3((i - 1) * 0.06, 0.3, -0.42), Vector3(70, 0, (i - 1) * 25))
	# asas: 5 penas em leque de cada lado, de amarelo (perto do corpo) a vermelho (pontas)
	for lado in [-1.0, 1.0]:
		var pivo := Node3D.new()
		pivo.position = Vector3(lado * 0.14, 0.08, -0.1)
		add_child(pivo)
		for i in 5:
			var pena := BoxMesh.new()
			pena.size = Vector3(0.95 - i * 0.07, 0.02, 0.2)
			var mi := _peca(pivo, pena, amarelo.lerp(vermelho, i / 4.0), Vector3(lado * (0.47 - i * 0.02), 0, 0.05 + i * 0.17), Vector3(0, -lado * i * 9.0, 0))
			mi.name = "pena%d" % i
		_asas.append([pivo, lado])
	# cauda: 5 plumas longas
	for i in 5:
		var pl := BoxMesh.new()
		pl.size = Vector3(0.08, 0.02, 1.5 - absf(i - 2) * 0.25)
		var ang := (i - 2) * 9.0
		var mi := _peca(self, pl, amarelo.lerp(vermelho, absf(i - 2) / 2.0), Vector3((i - 2) * 0.1, -0.02, 0.8 + 0.5), Vector3(0, ang, 0))
		mi.position.z = 0.6 + (1.5 - absf(i - 2) * 0.25) * 0.5
		mi.position.x = (i - 2) * 0.12
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.55, 0.15)
	luz.light_energy = 1.6
	luz.omni_range = 6.0
	add_child(luz)
	# chamas que ficam para trás
	_rastro = CPUParticles3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.12
	bola.height = 0.24
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.vertex_color_use_as_albedo = true
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bola.material = pm
	_rastro.mesh = bola
	_rastro.amount = 36
	_rastro.lifetime = 0.8
	_rastro.local_coords = false
	_rastro.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_rastro.emission_sphere_radius = 0.25
	_rastro.direction = Vector3(0, 1, 0)
	_rastro.spread = 60.0
	_rastro.gravity = Vector3(0, 1.6, 0)
	_rastro.initial_velocity_min = 0.2
	_rastro.initial_velocity_max = 0.7
	_rastro.scale_amount_min = 0.6
	_rastro.scale_amount_max = 1.2
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 0.9, 0.3, 0.9), Color(1.0, 0.4, 0.05, 0.7), Color(0.5, 0.05, 0.0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	_rastro.color_ramp = g
	add_child(_rastro)

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

## Pede o ataque (o mago atacou ou alguém chegou perto). Ignora se ela está ocupada ou recarregando.
func atacar(alvo: Node3D) -> void:
	if estado != "paira" or _cd > 0.0 or not is_instance_valid(alvo):
		return
	_alvo = alvo
	estado = "ataca"

func _posto() -> Vector3:
	return dono.global_position + Vector3(cos(_ang) * 0.9, 3.0 + sin(_t * 2.2) * 0.25, sin(_ang) * 0.9)

func _virar(dir: Vector3) -> void:
	if dir.length() > 0.01 and absf(dir.normalized().dot(Vector3.UP)) < 0.98:
		look_at(global_position + dir, Vector3.UP)

func _process(delta: float) -> void:
	if dono == null or not is_instance_valid(dono):
		queue_free()
		return
	visible = jogo._dentro == ""
	if not visible:
		return
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	var batida := 14.0 if estado == "paira" else 4.0
	for a in _asas:   # bater de asas (no mergulho ficam quase fechadas)
		a[0].rotation.z = a[1] * (sin(_t * batida) * 0.7 if estado == "paira" else -0.25)
	_rastro.emitting = true
	match estado:
		"paira":
			_ang += delta * 1.2
			var antes := global_position
			global_position = global_position.lerp(_posto(), minf(1.0, 4.0 * delta))
			var v := global_position - antes
			_virar(v if v.length() > 0.002 else dono.global_basis.z)
			if _cd <= 0.0:
				var e := _inimigo(GUARDA)
				if e != null:
					atacar(e)
		"ataca":
			if not is_instance_valid(_alvo) or _alvo._dead:
				estado = "volta"
				return
			var dest := _alvo.global_position + Vector3(0, 1.0, 0)
			var to := dest - global_position
			var d := to.length()
			_virar(to)
			if d < 1.2:
				_acertar(dest)
				estado = "volta"
			else:
				global_position += to / d * minf(d, VOO * delta)
		"volta":
			var to2 := _posto() - global_position
			_virar(to2)
			if to2.length() < 0.7:
				estado = "paira"
			else:
				global_position += to2.normalized() * minf(to2.length(), 18.0 * delta)

## Impacto: explosão de fogo, dano alto em quem estiver perto do ponto atingido.
func _acertar(pos: Vector3) -> void:
	_cd = RECARGA
	var dano: int = int(dono.damage) * 4 + 30
	jogo.flash(pos, Color(1.0, 0.45, 0.1), 2.2, 0.5)
	jogo.flash(pos, Color(1.0, 0.85, 0.3), 1.2, 0.3)
	for e in jogo.enemies:
		if is_instance_valid(e) and not e._dead and e.global_position.distance_to(pos) < 2.2:
			e.hurt(dano)
