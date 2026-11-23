extends Node3D
class_name Fogueira
## Fogueira grande do centro da vila: anel de pedras, toras em pirâmide, cinzas, chamas de partículas,
## faíscas, fumaça e luz tremulando. `intensidade` (0..1): de dia só brasas e chaminhas; à noite, alta e flamejante.

var intensidade := 1.0
var _chamas: CPUParticles3D
var _faiscas: CPUParticles3D
var _fumaca: CPUParticles3D
var _luz: OmniLight3D
var _brasa: StandardMaterial3D
var _t := 0.0

func _ready() -> void:
	var pedra := Construcoes.mat(Color(0.45, 0.44, 0.43), true, 0.95)
	for i in 14:   # anel de pedras
		var a := TAU * i / 14.0
		var p := Construcoes.caixa(self, Vector3(cos(a) * 1.55, 0.16, sin(a) * 1.55), Vector3(0.5, 0.34, 0.42), pedra, -a)
		p.rotation.z = 0.15 * sin(i * 2.3)
	var cinza := MeshInstance3D.new()   # cinzas e brasas no chão
	var cm := CylinderMesh.new()
	cm.top_radius = 1.3
	cm.bottom_radius = 1.35
	cm.height = 0.06
	_brasa = StandardMaterial3D.new()
	_brasa.albedo_color = Color(0.12, 0.08, 0.06)
	_brasa.emission_enabled = true
	_brasa.emission = Color(1.0, 0.3, 0.05)
	cm.material = _brasa
	cinza.mesh = cm
	cinza.position.y = 0.03
	add_child(cinza)
	var casca := Construcoes.mat(Color(0.35, 0.24, 0.15))
	var queimada := Construcoes.mat(Color(0.1, 0.07, 0.05))
	for i in 7:   # toras em pirâmide (tipi), pontas queimadas
		var a := TAU * i / 7.0
		var base := Vector3(cos(a) * 1.0, 0.05, sin(a) * 1.0)
		var topo := Vector3(cos(a) * 0.12, 1.5, sin(a) * 0.12)
		Construcoes.tora(self, base, base.lerp(topo, 0.6), 0.13, casca)
		Construcoes.tora(self, base.lerp(topo, 0.6), topo, 0.11, queimada)
	for i in 3:   # toras deitadas
		var a := TAU * i / 3.0 + 0.5
		Construcoes.tora(self, Vector3(cos(a) * 1.1, 0.12, sin(a) * 1.1), Vector3(cos(a + 2.2) * 1.1, 0.12, sin(a + 2.2) * 1.1), 0.12, queimada)
	_chamas = _particulas(60, 0.9, Vector2(0.55, 0.8), Vector3(0, 2.6, 0), 0.6, [Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.75, 0.25, 0.95), Color(1.0, 0.35, 0.05, 0.7), Color(0.6, 0.08, 0.02, 0.0)], true)
	_chamas.position.y = 0.3
	_faiscas = _particulas(30, 1.8, Vector2(0.05, 0.05), Vector3(0, 3.5, 0), 0.9, [Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.5, 0.1, 1.0), Color(1.0, 0.3, 0.05, 0.0)], true)
	_faiscas.position.y = 0.8
	_faiscas.initial_velocity_min = 1.5
	_faiscas.initial_velocity_max = 3.5
	_fumaca = _particulas(20, 4.0, Vector2(1.0, 1.0), Vector3(0.3, 1.2, 0.1), 0.4, [Color(0.3, 0.3, 0.3, 0.0), Color(0.35, 0.35, 0.36, 0.35), Color(0.4, 0.4, 0.42, 0.0)], false)
	_fumaca.position.y = 2.4
	_luz = OmniLight3D.new()
	_luz.light_color = Color(1.0, 0.6, 0.25)
	_luz.position.y = 1.8
	_luz.omni_range = 16.0
	add_child(_luz)
	var sb := StaticBody3D.new()   # não dá para atravessar a fogueira
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.7
	sh.height = 2.0
	cs.shape = sh
	sb.add_child(cs)
	sb.position.y = 1.0
	add_child(sb)

func _particulas(qtd: int, vida: float, tam: Vector2, subida: Vector3, raio: float, cores: Array, aditivo: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = qtd
	p.lifetime = vida
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = raio
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = subida
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.2
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.6))
	curva.add_point(Vector2(0.3, 1.0))
	curva.add_point(Vector2(1.0, 0.2 if aditivo else 1.6))
	p.scale_amount_curve = curva
	var g := Gradient.new()
	g.set_color(0, cores[0])
	g.set_color(1, cores[cores.size() - 1])
	for i in range(1, cores.size() - 1):
		g.add_point(float(i) / (cores.size() - 1), cores[i])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = tam
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if aditivo:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var gg := Gradient.new()
	gg.set_color(0, Color(1, 1, 1, 1))
	gg.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = gg
	m.albedo_texture = tex
	q.material = m
	p.mesh = q
	add_child(p)
	return p

func _process(delta: float) -> void:
	_t += delta
	var k := clampf(intensidade, 0.0, 1.0)
	_chamas.scale_amount_min = lerpf(0.35, 1.3, k)
	_chamas.scale_amount_max = lerpf(0.55, 2.1, k)
	_chamas.gravity = Vector3(0, lerpf(0.8, 3.2, k), 0)
	_chamas.lifetime = lerpf(0.5, 1.0, k)
	_faiscas.emitting = k > 0.5
	_fumaca.emitting = true
	var tremor := 0.85 + 0.1 * sin(_t * 13.0) + 0.06 * sin(_t * 23.0 + 1.0)
	_luz.light_energy = lerpf(0.4, 2.6, k) * tremor
	_luz.omni_range = lerpf(6.0, 17.0, k)
	_brasa.emission_energy_multiplier = lerpf(0.8, 1.6, k) * tremor
