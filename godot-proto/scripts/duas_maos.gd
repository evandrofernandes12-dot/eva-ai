extends SkeletonModifier3D
## Faz as duas mãos do Minotauro segurarem o cabo do machado: IK de dois ossos (ombro-cotovelo-mão)
## aplicado depois da animação. `ponto_a` e `ponto_b` são posições no mundo; `ativo` liga/desliga.

var ativo := false
var ponto_a := Vector3.ZERO
var ponto_b := Vector3.ZERO

const BRACOS := [["ArmA", "ForeA", "HandA", 1.0], ["ArmB", "ForeB", "HandB", -1.0]]

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or not ativo:
		return
	_braco(sk, BRACOS[0], ponto_a)
	_braco(sk, BRACOS[1], ponto_b)

func _braco(sk: Skeleton3D, b: Array, alvo_mundo: Vector3) -> void:
	var i1 := sk.find_bone(b[0])
	var i2 := sk.find_bone(b[1])
	var i3 := sk.find_bone(b[2])
	if i1 < 0 or i2 < 0 or i3 < 0:
		return
	var p1 := sk.get_bone_global_pose(i1).origin
	var p2 := sk.get_bone_global_pose(i2).origin
	var p3 := sk.get_bone_global_pose(i3).origin
	var l1 := p1.distance_to(p2)
	var l2 := p2.distance_to(p3)
	var t := sk.global_transform.affine_inverse() * alvo_mundo
	var v := t - p1
	var d := clampf(v.length(), 0.05, (l1 + l2) * 0.995)
	var dir := v.normalized()
	# cotovelo: no plano formado pelo alvo e pelo lado atual do cotovelo (para fora e para baixo)
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a * a))
	var polo := (p2 - p1) - dir * (p2 - p1).dot(dir)
	if polo.length() < 0.001:
		polo = Vector3.DOWN
	polo = polo.normalized()
	var cotovelo := p1 + dir * a + polo * h
	_apontar(sk, i1, i2, cotovelo)
	_apontar(sk, i2, i3, p1 + dir * d)

## Gira o osso para que o filho vá parar em `destino` (espaço do esqueleto).
func _apontar(sk: Skeleton3D, osso: int, filho: int, destino: Vector3) -> void:
	var g := sk.get_bone_global_pose(osso)
	var atual := sk.get_bone_global_pose(filho).origin - g.origin
	var novo := destino - g.origin
	if atual.length() < 0.0001 or novo.length() < 0.0001:
		return
	var q := Quaternion(atual.normalized(), novo.normalized())
	g.basis = Basis(q) * g.basis
	sk.set_bone_global_pose(osso, g)
	sk.force_update_bone_child_transform(osso)
