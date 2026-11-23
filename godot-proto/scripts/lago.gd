extends Node3D
class_name Lago
## Lago na floresta, alimentado pelo riacho: água com shader (shaders/agua.gdshader), margem de terra,
## juncos com taboas, vitórias-régias (algumas com flor), pedras, tronco caído, píer de madeira,
## peixes que pulam de vez em quando e vaga-lumes à noite. O reflexo do sol e da lua vem do brilho da água.

const QN := "res://assets/nature/quaternius/"
const KK := "res://assets/nature/kaykit/"
const RAIO := 15.0                 # raio médio do lago (a margem ondula)

var ceu: Ceu
var _rng := RandomNumberGenerator.new()
var _mat_agua: ShaderMaterial
var _peixe_t := 3.0
var _vaga: CPUParticles3D

## Raio da margem no ângulo a (espaço local do lago).
static func raio_em(a: float) -> float:
	return RAIO * (1.0 + 0.16 * sin(3.0 * a + 0.5) + 0.08 * sin(7.0 * a + 1.3))

## true se o ponto (mundo) está na água ou a menos de `folga` metros da margem.
func dentro(p: Vector3, folga := 0.0) -> bool:
	var l := p - global_position
	return Vector2(l.x, l.z).length() < raio_em(atan2(l.z, l.x)) + folga

func montar(o_ceu: Ceu) -> void:
	ceu = o_ceu
	_rng.seed = 11
	add_child(_disco("Margem", 3.2, 0.012, Construcoes.mat_terra()))
	_mat_agua = ShaderMaterial.new()
	_mat_agua.shader = preload("res://shaders/agua.gdshader")
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.03
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.as_normal_map = true
	nt.bump_strength = 6.0
	nt.noise = ruido
	_mat_agua.set_shader_parameter("ondas", nt)
	add_child(_disco("Agua", 0.0, 0.075, _mat_agua))   # um pouco acima do riacho (sem piscar onde se encontram)
	_juncos()
	_vitorias()
	_pedras_e_tronco()
	_pier()
	_vagalumes()

## Disco irregular (margem ou água): anéis do centro até a borda + `extra` metros. UV.x = 1 no centro, 0 na borda.
func _disco(nome: String, extra: float, y: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 64
	var aneis := 8
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		for k in aneis:
			var t0 := float(k) / aneis
			var t1 := float(k + 1) / aneis
			var q := [_pt(a0, t0, extra, y), _pt(a1, t0, extra, y), _pt(a1, t1, extra, y), _pt(a0, t1, extra, y)]
			var uvs := [1.0 - t0, 1.0 - t0, 1.0 - t1, 1.0 - t1]
			for j: int in [0, 2, 1, 0, 3, 2]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(uvs[j], 0.0))
				st.add_vertex(q[j])
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func _pt(a: float, t: float, extra: float, y: float) -> Vector3:
	var r := (raio_em(a) + extra) * t
	return Vector3(cos(a) * r, y, sin(a) * r)

func _na_margem(a: float, de: float) -> Vector3:   # de > 0: para fora da água; < 0: para dentro
	var r := raio_em(a) + de
	return Vector3(cos(a) * r, 0, sin(a) * r)

## Juncos: tufos altos de grama fina com taboas (cabecinhas marrons) em vários trechos da margem.
func _juncos() -> void:
	var grama: PackedScene = load(QN + "Grass_Wispy_Tall.gltf")
	var taboa := StandardMaterial3D.new()
	taboa.albedo_color = Color(0.32, 0.2, 0.1)
	taboa.roughness = 0.9
	var haste := StandardMaterial3D.new()
	haste.albedo_color = Color(0.35, 0.45, 0.2)
	for g in 9:
		var a0 := _rng.randf() * TAU
		for k in 7:
			var a := a0 + _rng.randf_range(-0.12, 0.12)
			var p := _na_margem(a, _rng.randf_range(-1.2, 0.4))
			var n: Node3D = grama.instantiate()
			add_child(n)
			n.position = p
			n.rotation.y = _rng.randf() * TAU
			Fit.to_height(n, _rng.randf_range(1.1, 1.7))
			n.scale.x *= 0.7
			n.scale.z *= 0.7
			Efeitos.vento(n, 0.08, 1.5)
			Efeitos.distancia(n, 50.0)
			if k % 2 == 0:   # taboa: haste fina + cabeça marrom
				var hh := _rng.randf_range(1.3, 1.8)
				var c := CylinderMesh.new()
				c.top_radius = 0.012
				c.bottom_radius = 0.015
				c.height = hh
				c.material = haste
				var mh := MeshInstance3D.new()
				mh.mesh = c
				mh.position = p + Vector3(0.1, hh * 0.5, 0.05)
				add_child(mh)
				var cap := CapsuleMesh.new()
				cap.radius = 0.035
				cap.height = 0.22
				cap.material = taboa
				var mc := MeshInstance3D.new()
				mc.mesh = cap
				mc.position = p + Vector3(0.1, hh - 0.12, 0.05)
				add_child(mc)

## Vitórias-régias: discos verdes com um corte, boiando; algumas com flor rosa.
func _vitorias() -> void:
	var folha := StandardMaterial3D.new()
	folha.albedo_color = Color(0.18, 0.42, 0.14)
	folha.roughness = 0.5
	folha.cull_mode = BaseMaterial3D.CULL_DISABLED
	var flor := StandardMaterial3D.new()
	flor.albedo_color = Color(1.0, 0.6, 0.78)
	flor.emission_enabled = true
	flor.emission = Color(0.3, 0.1, 0.15)
	var malha := _malha_folha()
	for i in 34:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf_range(0.15, 0.85)) * raio_em(a)
		var mi := MeshInstance3D.new()
		mi.mesh = malha
		mi.material_override = folha
		mi.position = Vector3(cos(a) * r, 0.075, sin(a) * r)
		mi.rotation.y = _rng.randf() * TAU
		mi.scale = Vector3.ONE * _rng.randf_range(0.6, 1.2)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		if i % 5 == 0:
			for k in 6:   # flor: pétalas em volta de um miolo amarelo
				var pt := SphereMesh.new()
				pt.radius = 0.06
				pt.height = 0.05
				pt.material = flor
				var mp := MeshInstance3D.new()
				mp.mesh = pt
				var ak := TAU * k / 6.0
				mp.position = mi.position + Vector3(cos(ak) * 0.06, 0.04, sin(ak) * 0.06)
				mp.scale = Vector3(1.0, 1.0, 2.0)
				mp.rotation.y = -ak
				add_child(mp)

func _malha_folha() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 18
	for i in n:
		var a0 := 0.35 + (TAU - 0.35) * i / n   # deixa o corte em forma de fatia
		var a1 := 0.35 + (TAU - 0.35) * (i + 1) / n
		for v: Vector3 in [Vector3.ZERO, Vector3(cos(a1), 0, sin(a1)) * 0.32, Vector3(cos(a0), 0, sin(a0)) * 0.32]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()

## Pedras na margem e um tronco caído com uma ponta na água.
func _pedras_e_tronco() -> void:
	var pedras := [load(QN + "Rock_Medium_1.gltf"), load(QN + "Rock_Medium_2.gltf"), load(KK + "Rock_1_A_Color1.gltf"), load(KK + "Rock_3_C_Color1.gltf"), load(QN + "Pebble_Round_3.gltf")]
	for i in 16:
		var a := _rng.randf() * TAU
		var cena: PackedScene = pedras[i % pedras.size()]
		var n: Node3D = cena.instantiate()
		add_child(n)
		n.position = _na_margem(a, _rng.randf_range(-0.6, 1.2))
		n.rotation.y = _rng.randf() * TAU
		Fit.to_height(n, _rng.randf_range(0.3, 0.9))
		Efeitos.distancia(n, 60.0)
	var a := 2.2
	var p0 := _na_margem(a, 2.5)
	var p1 := _na_margem(a + 0.25, -2.0)
	var tronco := Construcoes.tora(self, p0 + Vector3(0, 0.3, 0), p1 + Vector3(0, 0.15, 0), 0.32, Construcoes.mat(Color(0.4, 0.28, 0.17)))
	var toco := Construcoes.tora(self, p0 + Vector3(0.5, 0, 0.8), p0 + Vector3(0.5, 0.55, 0.8), 0.4, Construcoes.mat(Color(0.42, 0.3, 0.18)))
	toco.name = "Toco"

## Píer de tábuas saindo da margem para dentro da água, com estacas e colisão (dá para andar nele).
func _pier() -> void:
	var a := -0.6
	var dir := Vector3(-cos(a), 0, -sin(a))           # da margem para o centro
	var ini := _na_margem(a, 1.5)
	var comp := 8.0
	var larg := 1.8
	var r := Node3D.new()
	r.name = "Pier"
	r.position = ini
	r.rotation.y = atan2(dir.x, dir.z)
	add_child(r)
	var tab := Construcoes.mat(Construcoes.MADEIRA)
	var est := Construcoes.mat(Construcoes.MADEIRA_ESCURA)
	var n := 20
	for i in n:   # tábuas atravessadas (leve variação de altura e tom)
		var z := (i + 0.5) * comp / n
		var y := 0.06 + minf(z * 0.06, 0.12)
		Construcoes.caixa(r, Vector3(_rng.randf_range(-0.03, 0.03), y, z), Vector3(larg, 0.06, comp / n - 0.03), tab, _rng.randf_range(-0.03, 0.03))
	for z: float in [2.0, 4.0, 6.0, 7.9]:
		for x: float in [-larg * 0.5, larg * 0.5]:
			Construcoes.tora(r, Vector3(x, -0.4, z), Vector3(x, 0.45, z), 0.07, est)
	for x: float in [-larg * 0.5, larg * 0.5]:
		Construcoes.caixa(r, Vector3(x, 0.12, comp * 0.5), Vector3(0.1, 0.1, comp), est)
	var sb := StaticBody3D.new()   # piso do píer: rampa suave na entrada
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(larg, 0.2, comp)
	cs.shape = bs
	sb.add_child(cs)
	sb.position = Vector3(0, 0.05, comp * 0.5)
	sb.rotation.x = -0.015
	r.add_child(sb)
	var barco := Construcoes.caixa(r, Vector3(1.6, 0.12, comp - 0.8), Vector3(0.9, 0.25, 2.4), est, 0.2)   # barquinho amarrado
	barco.name = "Barco"

## Vaga-lumes: pontinhos verde-amarelados flutuando sobre o lago e a margem, só à noite.
func _vagalumes() -> void:
	_vaga = CPUParticles3D.new()
	_vaga.amount = 60
	_vaga.lifetime = 6.0
	_vaga.preprocess = 6.0
	_vaga.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_vaga.emission_box_extents = Vector3(RAIO + 6.0, 1.2, RAIO + 6.0)
	_vaga.position.y = 1.4
	_vaga.direction = Vector3(0, 1, 0)
	_vaga.spread = 180.0
	_vaga.gravity = Vector3.ZERO
	_vaga.initial_velocity_min = 0.1
	_vaga.initial_velocity_max = 0.35
	_vaga.orbit_velocity_min = -0.02
	_vaga.orbit_velocity_max = 0.02
	var cores := Gradient.new()
	cores.set_color(0, Color(0.8, 1.0, 0.3, 0.0))
	cores.add_point(0.2, Color(0.85, 1.0, 0.35, 1.0))
	cores.add_point(0.5, Color(0.6, 0.9, 0.2, 0.2))
	cores.add_point(0.75, Color(0.85, 1.0, 0.35, 1.0))
	cores.set_color(cores.get_point_count() - 1, Color(0.8, 1.0, 0.3, 0.0))
	_vaga.color_ramp = cores
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(0.5, 0.0)
	var gg := Gradient.new()
	gg.set_color(0, Color(1, 1, 1, 1))
	gg.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gg
	m.albedo_texture = g
	q.material = m
	_vaga.mesh = q
	_vaga.emitting = false
	add_child(_vaga)

func _process(delta: float) -> void:
	if ceu != null:
		_vaga.emitting = ceu.fator_noite > 0.6 and ceu.chuva < 0.3
		_mat_agua.set_shader_parameter("escuro", ceu.fator_noite)
		_mat_agua.set_shader_parameter("ceu", ceu.env.fog_light_color)
	_peixe_t -= delta
	if _peixe_t <= 0.0:
		_peixe_t = _rng.randf_range(4.0, 11.0)
		_pular_peixe()

## Um peixe salta em arco para fora da água e cai, com um anel de respingo.
func _pular_peixe() -> void:
	var a := _rng.randf() * TAU
	var r := sqrt(_rng.randf_range(0.1, 0.7)) * raio_em(a)
	var p := Vector3(cos(a) * r, 0.05, sin(a) * r)
	var dir := Vector3(cos(a + 1.6), 0, sin(a + 1.6))
	var peixe := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.09
	s.height = 0.18
	var m := StandardMaterial3D.new()
	m.albedo_color = [Color(0.75, 0.78, 0.8), Color(0.95, 0.5, 0.2), Color(0.5, 0.55, 0.4)][_rng.randi() % 3]
	m.metallic = 0.6
	m.roughness = 0.3
	s.material = m
	peixe.mesh = s
	peixe.scale = Vector3(0.6, 0.7, 2.2)
	add_child(peixe)
	var dur := 0.9
	var voo := func(t: float) -> void:
		if not is_instance_valid(peixe):
			return
		peixe.position = p + dir * t * 1.1 + Vector3(0, sin(t * PI) * 0.7, 0)
		var vel := dir * 1.1 + Vector3(0, cos(t * PI) * 0.7 * PI, 0)
		peixe.look_at(peixe.global_position + vel, Vector3.UP)
	var tw := create_tween()
	tw.tween_method(voo, 0.0, 1.0, dur)
	tw.tween_callback(peixe.queue_free)
	_respingo(p)
	get_tree().create_timer(dur).timeout.connect(func(): _respingo(p + dir * 1.1))

func _respingo(p: Vector3) -> void:
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.1
	t.outer_radius = 0.14
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.9, 0.95, 1.0, 0.7)
	t.material = m
	anel.mesh = t
	anel.position = p + Vector3(0, 0.07, 0)
	anel.scale = Vector3(1, 0.15, 1)
	add_child(anel)
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(anel, "scale", Vector3(6, 0.15, 6), 1.2)
	tw.tween_property(m, "albedo_color:a", 0.0, 1.2)
	tw.chain().tween_callback(anel.queue_free)
