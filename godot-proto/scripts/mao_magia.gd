extends SkeletonModifier3D
## Mago: mão esquerda levantada ao lado do corpo, com a PALMA PARA CIMA, segurando a magia
## (orbe flutuando ou chama colorida) — como na referência do usuário. IK de dois ossos depois da animação.
## Nos heróis o osso hand_l tem: Y = direção dos dedos, X = normal da palma (na pose T a palma olha para baixo).

var efeito: Node3D        # orbe ou chama (top_level), posto acima da palma a cada quadro
var chama := false        # true: tremula a chama
var _ok := false
var _i := {}
var _esq := Vector3.RIGHT
var _cima := Vector3.UP
var _frente := Vector3.BACK
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta

func _preparar(sk: Skeleton3D) -> bool:
	for n: String in ["upperarm_l", "lowerarm_l", "hand_l", "thigh_l", "thigh_r", "pelvis", "Head"]:
		var k := sk.find_bone(n)
		if k < 0:
			k = sk.find_bone(n.to_lower())
		if k < 0:
			push_warning("mao_magia: osso não achado: " + n)
			return false
		_i[n] = k
	var r_tl: Vector3 = sk.get_bone_global_rest(_i["thigh_l"]).origin
	var r_tr: Vector3 = sk.get_bone_global_rest(_i["thigh_r"]).origin
	var r_h: Vector3 = sk.get_bone_global_rest(_i["Head"]).origin
	var r_p: Vector3 = sk.get_bone_global_rest(_i["pelvis"]).origin
	_esq = (r_tl - r_tr).normalized()
	_cima = (r_h - r_p).normalized()
	_frente = _esq.cross(_cima).normalized()
	_esq = _cima.cross(_frente).normalized()
	_ok = true
	return true

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or (not _ok and not _preparar(sk)):
		return
	var i1: int = _i["upperarm_l"]
	var i2: int = _i["lowerarm_l"]
	var i3: int = _i["hand_l"]
	var p1 := sk.get_bone_global_pose(i1).origin
	var l1 := p1.distance_to(sk.get_bone_global_pose(i2).origin)
	var l2 := sk.get_bone_global_pose(i2).origin.distance_to(sk.get_bone_global_pose(i3).origin)
	var braco := l1 + l2
	# mão ao lado e à frente do ombro, um pouco abaixo (cotovelo dobrado, como na imagem)
	var alvo := p1 + _esq * braco * 0.55 + _frente * braco * 0.45 - _cima * braco * 0.12
	_ik(sk, i1, i2, i3, alvo, -_cima - _frente * 0.3 + _esq * 0.4)
	# palma para cima: X do osso da mão -> cima; dedos (Y) para fora e para a frente
	var g := sk.get_bone_global_pose(i3)
	var dedos := (_esq * 0.6 + _frente * 0.8).normalized()
	var x := _cima
	var z := x.cross(dedos).normalized()
	var y := z.cross(x).normalized()
	g.basis = Basis(x, y, z).orthonormalized().scaled(g.basis.get_scale())
	sk.set_bone_global_pose(i3, g)
	sk.force_update_bone_child_transform(i3)
	if efeito != null:
		var gt := sk.global_transform
		var esc := gt.basis.get_scale().x
		var palma := gt * (g.origin + y * 0.075)
		efeito.global_position = palma + (gt.basis * _cima).normalized() * (0.03 if chama else 0.13) * esc   # chama nasce rente à palma

func _ik(sk: Skeleton3D, i1: int, i2: int, i3: int, alvo: Vector3, polo: Vector3) -> void:
	var p1 := sk.get_bone_global_pose(i1).origin
	var p2 := sk.get_bone_global_pose(i2).origin
	var p3 := sk.get_bone_global_pose(i3).origin
	var l1 := p1.distance_to(p2)
	var l2 := p2.distance_to(p3)
	var v := alvo - p1
	var d := clampf(v.length(), 0.05 * (l1 + l2), (l1 + l2) * 0.995)
	var dir := v.normalized()
	var a1 := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a1 * a1))
	var pl := polo - dir * polo.dot(dir)
	if pl.length() < 0.001:
		pl = -_cima
	var cotovelo := p1 + dir * a1 + pl.normalized() * h
	_apontar(sk, i1, i2, cotovelo)
	_apontar(sk, i2, i3, p1 + dir * d)

func _apontar(sk: Skeleton3D, osso: int, filho: int, destino: Vector3) -> void:
	var g := sk.get_bone_global_pose(osso)
	var atual := sk.get_bone_global_pose(filho).origin - g.origin
	var novo := destino - g.origin
	if atual.length() < 0.0001 or novo.length() < 0.0001:
		return
	g.basis = Basis(Quaternion(atual.normalized(), novo.normalized())) * g.basis
	sk.set_bone_global_pose(osso, g)
	sk.force_update_bone_child_transform(osso)

## Chama de partículas (CPU, leve no tablet): labaredas que sobem e mudam de amarelo -> laranja -> roxo -> azul.
static func criar_chama() -> Node3D:
	var r := Node3D.new()
	var p := CPUParticles3D.new()
	p.amount = 28
	p.lifetime = 0.55
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.025
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 0.6, 0)
	p.initial_velocity_min = 0.18
	p.initial_velocity_max = 0.32
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.1
	var curva := Curve.new()   # nasce pequena, cresce e some afinando
	curva.add_point(Vector2(0.0, 0.5))
	curva.add_point(Vector2(0.25, 1.0))
	curva.add_point(Vector2(1.0, 0.1))
	p.scale_amount_curve = curva
	var cores := Gradient.new()
	cores.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	cores.set_color(1, Color(0.2, 0.4, 1.0, 0.0))
	cores.add_point(0.3, Color(1.0, 0.5, 0.1, 0.95))
	cores.add_point(0.6, Color(0.8, 0.2, 0.9, 0.7))
	p.color_ramp = cores
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.1)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var g := GradientTexture2D.new()   # ponto macio (redondo, borda transparente)
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(0.5, 0.0)
	var gg := Gradient.new()
	gg.set_color(0, Color(1, 1, 1, 1))
	gg.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gg
	g.width = 64
	g.height = 64
	m.albedo_texture = g
	quad.material = m
	p.mesh = quad
	r.add_child(p)
	return r
