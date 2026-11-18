extends Node3D
## Fênix de fogo do mago: paira acima da cabeça dele. Quando o mago ataca, ou um inimigo chega perto,
## voa como uma flecha de fogo, dá um golpe (DANO) e volta. Corpo, penas e chamas são feitos por código.
## Para usar um modelo realista de verdade, ponha `models/pets/fenix.glb`: ele substitui o corpo de código.

const GUARDA := 7.0       # raio (m) em que ela defende o mago sozinha
const VOO := 22.0         # velocidade do mergulho (m/s)
const RECARGA := 1.6      # segundos entre golpes
const DANO := 5           # dano por golpe

var dono: Node3D          # o mago (Jogador)
var jogo: Node            # main.gd
var estado := "paira"     # paira, ataca, volta
var _t := 0.0
var _cd := 1.0
var _ang := 0.0
var _alvo: Node3D
var _asas: Array = []     # [pivô, lado]
var _cauda: Node3D
var _corpo: Node3D
var _anim: AnimationPlayer

func _ready() -> void:
	_corpo = Node3D.new()
	add_child(_corpo)
	if ResourceLoader.exists("res://models/pets/fenix.glb"):   # ave animada (feita no Blender) + cauda de fogo
		var giro := Node3D.new()
		giro.rotation.y = PI   # o .glb olha para +Z
		_corpo.add_child(giro)
		var m: Node3D = load("res://models/pets/fenix.glb").instantiate()
		giro.add_child(m)
		var bb := Fit.bounds(m)
		var s := 2.2 / maxf(bb.size.x, bb.size.z)
		m.scale = Vector3.ONE * s
		m.position = -bb.get_center() * s
		var meshes: Array = []
		Fit._collect(m, meshes)
		var mv := StandardMaterial3D.new()
		mv.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   # cores de fogo, acesas
		mv.vertex_color_use_as_albedo = true
		mv.cull_mode = BaseMaterial3D.CULL_DISABLED
		for mi: MeshInstance3D in meshes:
			mi.material_override = mv
		_anim = Fit.find_node_of(m, "AnimationPlayer") as AnimationPlayer
		_cauda_fogo(Vector3(0, 0, bb.size.z * s * 0.3))
	else:
		_montar()
	_chamas()
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.55, 0.15)
	luz.light_energy = 1.5
	luz.omni_range = 6.0
	add_child(luz)

static func _fogo(vertice := true, soma := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = vertice
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if soma:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m

func _pena(pai: Node3D, comp: float, larg: float, c0: Color, c1: Color, pos: Vector3, rot: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Pet.pena(comp, larg, c0, c1)
	mi.material_override = _fogo()
	mi.position = pos
	mi.rotation_degrees = rot
	pai.add_child(mi)

## Modelo virado para -Z (bico em -Z, cauda em +Z). Envergadura de ~2,6 m.
func _montar() -> void:
	var braseiro := StandardMaterial3D.new()    # corpo: carne escura de brasa, com brilho laranja
	braseiro.albedo_color = Color(0.45, 0.07, 0.02)
	braseiro.emission_enabled = true
	braseiro.emission = Color(1.0, 0.32, 0.05)
	braseiro.emission_energy_multiplier = 1.4
	braseiro.roughness = 0.6
	var ouro := Pet.liso(Color(0.95, 0.7, 0.15), 0.35)
	ouro.emission_enabled = true
	ouro.emission = Color(0.8, 0.45, 0.05)
	for e in [[Vector3(0, 0, 0.0), Vector3(0.3, 0.28, 0.85), Vector3.ZERO],            # tronco
			[Vector3(0, 0.05, -0.5), Vector3(0.22, 0.22, 0.5), Vector3(25, 0, 0)],     # pescoço
			[Vector3(0, 0.2, -0.78), Vector3(0.2, 0.19, 0.3), Vector3.ZERO],           # cabeça
			[Vector3(0, 0.0, 0.5), Vector3(0.2, 0.17, 0.4), Vector3(-15, 0, 0)]]:      # rabadilha
		var mi := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.5
		sp.height = 1.0
		mi.mesh = sp
		mi.material_override = braseiro
		mi.position = e[0]
		mi.scale = e[1]
		mi.rotation_degrees = e[2]
		_corpo.add_child(mi)
	var bico := MeshInstance3D.new()    # bico curvo de ouro
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.055
	cm.height = 0.26
	bico.mesh = cm
	bico.material_override = ouro
	bico.position = Vector3(0, 0.17, -0.98)
	bico.rotation_degrees = Vector3(-100, 0, 0)
	_corpo.add_child(bico)
	for lado in [-1.0, 1.0]:   # olhos acesos
		var olho := MeshInstance3D.new()
		var so := SphereMesh.new()
		so.radius = 0.03
		so.height = 0.06
		var mo := _fogo(false)
		mo.albedo_color = Color(1.0, 0.95, 0.5)
		so.material = mo
		olho.mesh = so
		olho.position = Vector3(lado * 0.09, 0.25, -0.86)
		_corpo.add_child(olho)
	var amarelo := Color(1.0, 0.85, 0.25, 0.95)
	var laranja := Color(1.0, 0.45, 0.05, 0.85)
	var rubro := Color(0.8, 0.08, 0.02, 0.0)
	for i in 5:    # penacho
		_pena(_corpo, 0.5 - absf(i - 2) * 0.07, 0.08, amarelo, rubro, Vector3(0, 0.36, -0.72), Vector3(0, -90.0 + (i - 2) * 20.0, 60))
	for lado in [-1.0, 1.0]:   # asas: 8 primárias + 6 secundárias + cobertura, em leque
		var pivo := Node3D.new()
		pivo.position = Vector3(lado * 0.16, 0.1, -0.12)
		pivo.scale.x = lado
		_corpo.add_child(pivo)
		for i in 8:
			_pena(pivo, 1.5 - i * 0.07, 0.3, amarelo.lerp(laranja, i / 7.0), rubro, Vector3(0.04, 0.012 * i, 0), Vector3(0, 24 - i * 9.0, 0))
		for i in 6:
			_pena(pivo, 0.8 - i * 0.05, 0.26, amarelo, laranja.darkened(0.2), Vector3(0.04, 0.07 + 0.01 * i, 0), Vector3(0, 12 - i * 13.0, 0))
		_asas.append([pivo, lado])
	_cauda_fogo(Vector3(0, -0.02, 0.62))

## Cauda de 7 plumas longas, de ouro a rubro, em leque e caindo.
func _cauda_fogo(pos: Vector3) -> void:
	var amarelo := Color(1.0, 0.85, 0.25, 0.95)
	var laranja := Color(1.0, 0.45, 0.05, 0.85)
	var rubro := Color(0.8, 0.08, 0.02, 0.0)
	_cauda = Node3D.new()
	_cauda.position = pos
	_corpo.add_child(_cauda)
	for i in 7:    # cauda de 7 plumas longas, de ouro a rubro, em leque e caindo
		var f := absf(i - 3) / 3.0
		_pena(_cauda, 2.1 - f * 0.7, 0.2, amarelo.lerp(laranja, f), rubro, Vector3.ZERO, Vector3(0, -90.0 + (i - 3) * 8.0, -8 - f * 6))

## Chamas e brasas: duas fontes de partículas aditivas (corpo e rastro).
func _chamas() -> void:
	for cfg in [[60, 0.9, 0.3, 1.8, 0.5, true], [30, 1.4, 0.18, 0.5, 0.25, false]]:
		var ps := CPUParticles3D.new()
		var bola := SphereMesh.new()
		bola.radius = 0.1
		bola.height = 0.2
		bola.material = _fogo()
		ps.mesh = bola
		ps.amount = cfg[0]
		ps.lifetime = cfg[1]
		ps.local_coords = false
		ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		ps.emission_sphere_radius = cfg[2]
		ps.direction = Vector3(0, 1, 0)
		ps.spread = 70.0
		ps.gravity = Vector3(0, cfg[3], 0)
		ps.initial_velocity_min = 0.1
		ps.initial_velocity_max = cfg[4]
		ps.scale_amount_min = 0.5
		ps.scale_amount_max = 1.5 if cfg[5] else 0.8
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1.0, 0.9, 0.35, 0.9), Color(1.0, 0.4, 0.05, 0.6), Color(0.4, 0.04, 0.0, 0.0)])
		g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		ps.color_ramp = g
		ps.position = Vector3(0, 0, 0.3) if not cfg[5] else Vector3.ZERO
		add_child(ps)

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
	var paira := estado == "paira"
	for a in _asas:   # bater de asas (no mergulho ficam recolhidas para trás)
		a[0].rotation.z = a[1] * (sin(_t * 9.0) * 0.6 + 0.1 if paira else -0.2)
	if _cauda != null:
		_cauda.rotation.y = sin(_t * 2.0) * 0.12
	if _anim != null and _anim.get_animation_list().size() > 0:   # bater de asas do modelo
		Fit.play(_anim, _anim.get_animation_list()[0], true, 1.3 if paira else 0.5)
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
				_cd = RECARGA
				_alvo.hurt(DANO)
				jogo.flash(dest, Color(1.0, 0.5, 0.1), 0.6, 0.25)
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
