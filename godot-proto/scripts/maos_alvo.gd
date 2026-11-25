extends SkeletonModifier3D
## Leva as duas mãos até dois pontos no mundo (IK de dois ossos, depois da animação).
## Usado pelos trabalhadores para segurar os pegadores do carrinho de mão enquanto andam.

var ativo := false
var alvo_e: Node3D   # pegador da mão esquerda
var alvo_d: Node3D   # pegador da mão direita
var _i := {}

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or not ativo or alvo_e == null or alvo_d == null:
		return
	if _i.is_empty():
		for n: String in ["upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "lowerarm_r", "hand_r"]:
			var k := sk.find_bone(n)
			if k < 0:
				return
			_i[n] = k
	var inv := sk.global_transform.affine_inverse()
	_braco(sk, "_l", inv * alvo_e.global_position)
	_braco(sk, "_r", inv * alvo_d.global_position)

func _braco(sk: Skeleton3D, lado: String, alvo: Vector3) -> void:
	var i1: int = _i["upperarm" + lado]
	var i2: int = _i["lowerarm" + lado]
	var i3: int = _i["hand" + lado]
	var p1 := sk.get_bone_global_pose(i1).origin
	var p2 := sk.get_bone_global_pose(i2).origin
	var p3 := sk.get_bone_global_pose(i3).origin
	var l1 := p1.distance_to(p2)
	var l2 := p2.distance_to(p3)
	alvo -= (alvo - p2).normalized() * 0.07   # o osso da mão fica no pulso: o punho cai no pegador
	var v := alvo - p1
	var d := clampf(v.length(), 0.05 * (l1 + l2), (l1 + l2) * 0.995)
	var dir := v.normalized()
	var a1 := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a1 * a1))
	var lado_x := 1.0 if lado == "_l" else -1.0
	var polo := Vector3(lado_x * 0.6, -1.0, -0.4)   # cotovelo para fora, para baixo e para trás
	var pl := polo - dir * polo.dot(dir)
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
