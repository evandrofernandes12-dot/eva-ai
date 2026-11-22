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
	if chama and efeito != null:   # chama tremulando
		var k := 1.0 + 0.12 * sin(_t * 17.0) + 0.08 * sin(_t * 29.0 + 1.3)
		for c in efeito.get_children():
			if c is Node3D:
				(c as Node3D).scale.y = k * (1.0 + 0.1 * sin(_t * 11.0 + (c as Node3D).position.x * 40.0))

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
		efeito.global_position = palma + (gt.basis * _cima).normalized() * 0.13 * esc

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

## Chama em camadas (laranja, roxa e azul, como na imagem), com brilho aditivo.
static func criar_chama() -> Node3D:
	var r := Node3D.new()
	var camadas := [[Color(1.0, 0.55, 0.12), Vector3(-0.012, 0, 0), 1.0], [Color(0.75, 0.25, 1.0), Vector3(0.012, 0, 0.004), 0.85], [Color(0.25, 0.55, 1.0), Vector3(0.022, -0.01, -0.004), 0.7], [Color(1.0, 0.92, 0.6), Vector3(0, -0.015, 0), 0.45]]
	for c: Array in camadas:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = c[0]
		m.no_depth_test = false
		var s := SphereMesh.new()
		var t: float = c[2]
		s.radius = 0.045 * t
		s.height = 0.17 * t
		s.radial_segments = 12
		s.rings = 8
		s.material = m
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = c[1] + Vector3(0, 0.06 * t, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r.add_child(mi)
	return r
