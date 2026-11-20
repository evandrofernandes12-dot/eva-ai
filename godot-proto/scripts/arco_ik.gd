extends SkeletonModifier3D
## Arqueiro: o arco fica na MÃO ESQUERDA. Ao atirar (`disparar()`), o tronco vira de lado, o braço
## esquerdo levanta o arco apontando para a frente e a mão direita puxa a corda até o queixo e solta.
## Tudo por IK de dois ossos, depois da animação (o corpo continua com a animação de idle/corrida).

const SOLTA := 0.4        # s até soltar a flecha (main.gd espera o mesmo tempo para lançar a flecha)
const FIM := 0.8          # s até baixar o arco de novo
const GIRO_TRONCO := 55.0 # graus que o tronco vira para a direita (ombro esquerdo para o alvo)
const COMPRIMENTO := 1.15 # tamanho do arco em metros (escala do herói)

var arco: Node3D          # modelo do arco (top_level, posicionado aqui a cada quadro)
var flecha: Node3D        # flecha encaixada na corda durante a puxada
var _t := FIM             # tempo desde o último disparo
var _ok := false
var _i := {}              # índices dos ossos
var _esq := Vector3.RIGHT # eixos do esqueleto (pose de descanso): esquerda, cima, frente
var _cima := Vector3.UP
var _frente := Vector3.BACK

func disparar() -> void:
	_t = 0.1 if (_t > 0.1 and _t < FIM) else 0.0   # já mirando: só puxa de novo

func _process(delta: float) -> void:
	_t = minf(_t + delta, FIM)

func _preparar(sk: Skeleton3D) -> bool:
	for n in ["upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "lowerarm_r", "hand_r", "spine_01", "spine_03", "head", "thigh_l", "thigh_r", "pelvis"]:
		var k := sk.find_bone(n)
		if k < 0:
			k = sk.find_bone(n.capitalize())   # nos heróis a cabeça é "Head"
		if k < 0:
			push_warning("arco_ik: osso não achado: " + n)
			return false
		_i[n] = k
	var rest := func(n: String) -> Vector3: return sk.get_bone_global_rest(_i[n]).origin
	_esq = (rest.call("thigh_l") - rest.call("thigh_r")).normalized()
	_cima = (rest.call("head") - rest.call("pelvis")).normalized()
	_frente = _esq.cross(_cima).normalized()
	_esq = _cima.cross(_frente).normalized()
	_ok = true
	return true

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or (not _ok and not _preparar(sk)):
		return
	var w := smoothstep(0.0, 0.12, _t) * (1.0 - smoothstep(0.55, FIM, _t))   # quanto está mirando
	var puxa := smoothstep(0.1, SOLTA - 0.02, _t)
	if w > 0.001:
		_girar(sk, _i.spine_01, -GIRO_TRONCO * 0.5 * w)
		_girar(sk, _i.spine_03, -GIRO_TRONCO * 0.5 * w)
		_girar(sk, _i.head, GIRO_TRONCO * 0.8 * w)   # a cabeça continua olhando o alvo
		var o_e := sk.get_bone_global_pose(_i.upperarm_l).origin
		var l_e := _comp(sk, "upperarm_l", "lowerarm_l") + _comp(sk, "lowerarm_l", "hand_l")
		var alvo_e := o_e + _frente * l_e * 0.97 + _cima * l_e * 0.04
		var mao_e := sk.get_bone_global_pose(_i.hand_l).origin
		_ik(sk, "upperarm_l", "lowerarm_l", "hand_l", mao_e.lerp(alvo_e, w), -_cima + _esq * 0.3)
		var cabeca := sk.get_bone_global_pose(_i.head).origin
		var corda := alvo_e - _frente * l_e * 0.2
		var queixo := cabeca + _frente * l_e * 0.12 - _esq * l_e * 0.08 - _cima * l_e * 0.02
		var mao_d := sk.get_bone_global_pose(_i.hand_r).origin
		var alvo_d := corda.lerp(queixo, puxa)
		_ik(sk, "upperarm_r", "lowerarm_r", "hand_r", mao_d.lerp(alvo_d, w), -_esq - _frente * 0.4 + _cima * 0.3)
	_posicionar(sk, w, puxa)

func _comp(sk: Skeleton3D, a: String, b: String) -> float:
	return sk.get_bone_global_pose(_i[a]).origin.distance_to(sk.get_bone_global_pose(_i[b]).origin)

func _girar(sk: Skeleton3D, osso: int, graus: float) -> void:
	var g := sk.get_bone_global_pose(osso)
	g.basis = Basis(_cima, deg_to_rad(graus)) * g.basis
	sk.set_bone_global_pose(osso, g)
	sk.force_update_bone_child_transform(osso)

## IK de dois ossos com o cotovelo puxado para o lado `polo`.
func _ik(sk: Skeleton3D, a: String, b: String, c: String, alvo: Vector3, polo: Vector3) -> void:
	var i1: int = _i[a]
	var i2: int = _i[b]
	var i3: int = _i[c]
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

## Arco no punho esquerdo: limbos em pé quando mira, apontando para a frente quando o braço está baixo.
func _posicionar(sk: Skeleton3D, w: float, puxa: float) -> void:
	if arco == null:
		return
	var gt := sk.global_transform
	var cot := gt * sk.get_bone_global_pose(_i.lowerarm_l).origin
	var pulso := gt * sk.get_bone_global_pose(_i.hand_l).origin
	var ante := (pulso - cot).normalized()               # direção do antebraço (mundo)
	var esc := gt.basis.get_scale().x
	var frente := (gt.basis * _frente).normalized()
	var cima := (gt.basis * _cima).normalized()
	var punho := pulso + ante * 0.08 * esc
	var y := frente.lerp(cima, 0.45 + 0.55 * w)   # baixo: arco inclinado para a frente; mirando: em pé
	y = (y - ante * y.dot(ante))
	if y.length() < 0.01:
		y = cima
	y = y.normalized()
	var x := ante                                         # -X do modelo é o lado da corda (para o arqueiro)
	var z := x.cross(y).normalized()
	x = y.cross(z).normalized()
	var s := COMPRIMENTO * esc
	arco.global_transform = Transform3D(Basis(x * s, y * s, z * s), punho)
	if flecha == null:
		return
	var nocada := w > 0.6 and _t < SOLTA
	flecha.visible = nocada
	if nocada:
		var mao_d := gt * sk.get_bone_global_pose(_i.hand_r).origin
		var corda := mao_d + (mao_d - gt * sk.get_bone_global_pose(_i.lowerarm_r).origin).normalized() * 0.06 * esc
		var ponta := punho + (punho - corda).normalized() * 0.12 * esc
		if corda.distance_to(ponta) > 0.05 * esc:
			flecha.global_position = corda
			flecha.look_at(ponta, cima)
			flecha.scale = Vector3.ONE * esc
