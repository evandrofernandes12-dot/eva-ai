extends CharacterBody3D
## Minotauro Dark: o chefe.
## Fase 1: luta com o machado. Quando a vida cai até `largar_machado_em`, o machado se despedaça e some.
## Fase 2: dá dois socos; depois raspa o pé no chão (patada) e investe com os chifres.
## Esqueleto e animações foram feitos no Blender por script.

signal killed
signal largou_machado

const MACHADO := preload("res://models/Machado.glb")
const DUAS_MAOS := preload("res://scripts/duas_maos.gd")
## Velocidade em que a animação de andar foi feita (m/s), para os pés não deslizarem.
const PASSO := 2.1

@export var altura := 4.6
@export var speed := 2.8
## Fração da vida em que o machado se despedaça (0.5 = quando ele fica com metade da vida).
@export_range(0.05, 0.95) var largar_machado_em := 0.5
## Distância (m) entre o Minotauro e o alvo quando o machado desce: ajuste se a lâmina cair antes ou depois dele.
@export var alcance_machado := 2.8

var max_hp := 500
var hp := 500
var damage := 22
const FRACAO_GOLPE := 0.33   # o golpe mais forte (chifrada) tira até 1/3 da vida máxima do herói
var nivel := 1
var target: Node3D
var jogo: Node
var raio := 1.6            # corpo largo: o golpe do jogador alcança de mais longe
var fase := 1
var estado := "segue"      # segue, golpe, soco, pata, investida
var _dead := false
var _cd := 2.0
var _t := 0.0              # tempo dentro do estado atual
var _bateu := 0
var _socos := 0
var _dir := Vector3.ZERO   # direção da investida
var _preso := 0.0
var _desvio := 0.0
var _lado := 1.0
var _tonto := 0.0
var model: Node3D
var _pivot: Node3D
var _ap: AnimationPlayer
var machado: Node3D
var _mod                       # IK: as duas mãos seguram o cabo (duas_maos.gd)
var _k := 1.0
var _sk: Skeleton3D
var _ia := -1   # ossos dos ombros: o machado é posto em relação a eles (sempre ao alcance dos braços)
var _ib := -1
var _alvo_local := Vector3(0, 1.1, 3.0)   # onde o machado vai cair (peito do alvo, no espaço do Minotauro)
var _capt := false

func setup(scene: PackedScene, player: Node3D, main: Node, lvl: int) -> void:
	target = player
	jogo = main
	nivel = lvl
	max_hp = int(500 * (1.0 + 0.5 * (lvl - 1)))
	hp = max_hp
	damage = 22 + 6 * (lvl - 1)
	_pivot = Node3D.new()
	add_child(_pivot)
	model = scene.instantiate()
	_pivot.add_child(model)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.1
	cap.height = altura
	shape.shape = cap
	shape.position.y = altura * 0.5
	add_child(shape)

func _ready() -> void:
	# as cores (pele, chifres, ombreiras, braceletes, couro, cascos) vêm pintadas nos vértices
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.15
	mat.roughness = 0.7
	var meshes: Array = []
	Fit._collect(model, meshes)
	for m: MeshInstance3D in meshes:
		m.material_override = mat
	# o modelo tem 1,9 de altura e a origem no meio do corpo
	var k := altura / 1.9
	_k = k
	model.scale = Vector3.ONE * k
	model.position.y = 0.95 * k
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_montar.call_deferred()

## Olhos (presos à cabeça) e machado (preso à mão da frente).
func _montar() -> void:
	var sk := Fit.find_node_of(model, "Skeleton3D") as Skeleton3D
	var cabeca: Node3D = model
	if sk != null:
		if sk.find_bone("Head") >= 0:
			cabeca = BoneAttachment3D.new()
			cabeca.bone_name = "Head"
			sk.add_child(cabeca)

	var olho := StandardMaterial3D.new()
	olho.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	olho.albedo_color = Color(1.0, 0.25, 0.05)
	for p: Vector3 in [Vector3(-0.046, 0.672, 0.248), Vector3(0.046, 0.672, 0.248)]:   # órbitas (espaço do modelo), um pouco à frente para aparecer de baixo
		var e := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.016
		sp.height = 0.032
		sp.material = olho
		e.mesh = sp
		cabeca.add_child(e)
		e.transform = _no_osso(sk, "Head", Transform3D(Basis(), p))
	# o machado não fica preso a um osso: é posto por código (_process) e as duas mãos o seguram por IK
	machado = _criar_machado()
	machado.scale = Vector3.ONE * _k
	add_child(machado)
	if sk != null:
		_sk = sk
		_ia = sk.find_bone("ArmA")
		_ib = sk.find_bone("ArmB")
		_mod = DUAS_MAOS.new()
		sk.add_child(_mod)
	Fit.play(_ap, &"AxeIdle")

## Converte uma posição dada no espaço do modelo (pose de descanso) para o espaço local do osso.
func _no_osso(sk: Skeleton3D, osso: String, no_modelo: Transform3D) -> Transform3D:
	if sk == null or sk.find_bone(osso) < 0:
		return no_modelo
	var no_esqueleto: Transform3D = sk.global_transform.affine_inverse() * model.global_transform * no_modelo
	return sk.get_bone_global_rest(sk.find_bone(osso)).affine_inverse() * no_esqueleto

## Machado de duas lâminas em meia-lua (modelo feito no Blender: models/Machado.glb).
func _criar_machado() -> Node3D:
	var root: Node3D = MACHADO.instantiate()
	root.name = "Machado"
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.25
	mat.roughness = 0.6
	var meshes: Array = []
	Fit._collect(root, meshes)
	for m: MeshInstance3D in meshes:
		m.material_override = mat
	return root

## Pose do machado em duas mãos (espaço do Minotauro, em metros): posição da mão da frente `g` e
## ângulo `fi` do cabo no plano frente/cima (0° = para a frente, 90° = para cima, 180° = para trás).
func _process(_delta: float) -> void:
	if machado == null or not is_instance_valid(machado):
		return
	# centro dos ombros no espaço do Minotauro: as mãos ficam a até ~1,2 m dele (alcance do braço ~1,8 m)
	var ombros := Vector3(0, 3.7, 0)
	if _sk != null and _ia >= 0 and _ib >= 0:
		var pm := (_sk.get_bone_global_pose(_ia).origin + _sk.get_bone_global_pose(_ib).origin) * 0.5
		ombros = to_local(_sk.global_transform * pm)
	var carga_g := ombros + Vector3(0, -0.4, 1.0)
	var carga_fi := deg_to_rad(70.0)
	var alto_g := ombros + Vector3(0, 0.9, 0.0)
	var alto_fi := deg_to_rad(160.0)
	var imp_g := ombros + Vector3(0, -0.7, 1.0)
	var dd := (_alvo_local - imp_g).normalized()
	var imp_fi := atan2(dd.y, dd.z)
	var g := carga_g
	var fi := carga_fi
	if estado == "golpe":
		if _t < 0.35:
			var k := _t / 0.35
			k = k * k * (3.0 - 2.0 * k)
			g = carga_g.lerp(alto_g, k)
			fi = lerpf(carga_fi, alto_fi, k)
		elif _t < 0.6:
			var k := (_t - 0.35) / 0.25
			k *= k   # desce acelerando
			g = alto_g.lerp(imp_g, k)
			fi = lerpf(alto_fi, imp_fi, k)
		elif _t < 1.1:
			g = imp_g
			fi = imp_fi
		else:
			var k := clampf((_t - 1.1) / 0.25, 0.0, 1.0)
			g = imp_g.lerp(carga_g, k)
			fi = lerpf(imp_fi, carga_fi, k)
	else:
		g.y += sin(Time.get_ticks_msec() * 0.003) * 0.05
	var d := Vector3(0, sin(fi), cos(fi))
	var z := Vector3.RIGHT
	var x := d.cross(z)
	machado.transform = Transform3D(Basis(x, d, z).scaled(Vector3.ONE * _k), g)
	if _mod != null:
		_mod.ativo = true
		_mod.ponto_a = to_global(g)
		_mod.ponto_b = to_global(g - d * 0.85)

func _mudar(novo: String) -> void:
	estado = novo
	_t = 0.0
	_bateu = 0
	_capt = false

func _acertar(alcance: float, dano: int) -> void:
	if target.get("hp") > 0 and target.global_position.distance_to(global_position) < alcance:
		var vmax = target.get("max_hp")
		if vmax != null:   # golpe mais forte tira no máximo FRACAO_GOLPE da vida máxima (antes matava em 2 golpes)
			dano = mini(dano, int(ceil(float(vmax) * FRACAO_GOLPE * dano / (damage * 1.7))))
		target.call("hurt", dano)

## O machado se despedaça na mão dele e some.
func _largar_machado() -> void:
	fase = 2
	if machado == null or not is_instance_valid(machado):
		return
	var centro: Vector3 = machado.global_transform * Vector3(0, 0.7, 0)
	if _mod != null:
		_mod.ativo = false
	machado.queue_free()
	machado = null
	var cores := [Color(0.62, 0.66, 0.72), Color(0.3, 0.33, 0.38), Color(0.3, 0.17, 0.08)]
	for i in 14:
		var p := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(randf_range(0.12, 0.38), randf_range(0.05, 0.14), randf_range(0.12, 0.3))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = cores[i % cores.size()]
		mat.metallic = 0.5
		b.material = mat
		p.mesh = b
		jogo.add_child(p)
		p.global_position = centro + Vector3(randf_range(-0.4, 0.4), randf_range(-0.6, 0.6), randf_range(-0.4, 0.4))
		var alvo := Vector3(centro.x + randf_range(-3.0, 3.0), 0.08, centro.z + randf_range(-3.0, 3.0))
		var tw := p.create_tween()
		tw.tween_property(p, "global_position", alvo, randf_range(0.45, 0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(p, "rotation", Vector3(randf() * 6.0, randf() * 6.0, randf() * 6.0), 0.7)
		tw.tween_interval(1.2)
		tw.tween_property(p, "scale", Vector3.ONE * 0.01, 0.5)
		tw.tween_callback(p.queue_free)
	largou_machado.emit()

func _physics_process(delta: float) -> void:
	if _dead or target == null:
		return
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	var to := target.global_position - global_position
	to.y = 0
	var d := to.length()
	var moving := false
	velocity.x = 0
	velocity.z = 0
	match estado:
		"segue":
			# com a muralha de pé, ele dá a volta até um portão
			var via: Vector3 = jogo.destino(global_position) - global_position
			via.y = 0
			var desvia: bool = jogo.destino(global_position).distance_to(target.global_position) > 0.5
			# portão fechado no caminho: derruba a golpes
			var portao = jogo.portao_em(global_position) if desvia else null
			if portao != null:
				var pg: Vector3 = portao.pos - global_position
				rotation.y = lerp_angle(rotation.y, atan2(pg.x, pg.z), 6.0 * delta)
				if _cd <= 0.0:
					_cd = 1.6
					_ap.stop()
					Fit.play(_ap, &"AxeAttack" if fase == 1 else &"Punch", false, 1.2)
					_tonto = 1.2
					jogo.bater_portao(portao, damage * 2)
			elif (desvia or d > 2.9) and d < 90.0 and via.length() > 0.2:
				var dir := via.normalized()
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
				moving = true
				rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 4.0 * delta)
			elif d > 0.1:
				rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 4.0 * delta)
			if _cd <= 0.0 and target.get("hp") > 0:
				if fase == 1:
					if d <= 3.7:
						_mudar("golpe")
				elif _socos >= 2 or d > 7.0:
					if d < 26.0:
						_socos = 0
						_mudar("pata")
				elif d <= 3.8:
					_mudar("soco")
		"golpe":      # machado: sobe e desce
			Fit.play(_ap, &"AxeAttack", false, 1.2)
			# até o golpe cair, acompanha o alvo e avança/recua até ficar a `alcance_machado` dele:
			# assim a lâmina desce NO adversário e não no chão
			if _t >= 0.45 and not _capt:
				_capt = true
				_alvo_local = to_local(target.global_position + Vector3(0, 1.1, 0))
				_alvo_local.x = clampf(_alvo_local.x, -0.5, 0.5)
				_alvo_local.z = clampf(_alvo_local.z, 1.8, 3.2)
			if _t < 0.6 and d > 0.1:
				rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 10.0 * delta)
				var falta := d - alcance_machado
				if absf(falta) > 0.1:
					var dir := to / d
					var v := clampf(falta * 6.0, -4.0, 9.0)
					velocity.x = dir.x * v
					velocity.z = dir.z * v
			if _t >= 0.6 and _bateu == 0:
				_bateu = 1
				_acertar(alcance_machado + 1.6, int(damage * 1.3))
				if target.get("hp") > 0:   # o machado fica fincado nele por um instante: clarão no ponto do impacto
					jogo.flash(target.global_position + Vector3(0, 1.1, 0), Color(1.0, 0.3, 0.15), 1.4, 0.4)
			if _t > 1.35:
				_cd = 1.5
				_mudar("segue")
		"soco":       # dois socos seguidos
			Fit.play(_ap, &"Punch", false, 1.15)
			if _t >= 0.36 and _bateu == 0:
				_bateu = 1
				_acertar(4.8, int(damage * 0.6))
			if _t >= 0.69 and _bateu == 1:
				_bateu = 2
				_acertar(4.8, int(damage * 0.6))
			if _t > 1.2:
				_socos = 2
				_cd = 0.9
				_mudar("segue")
		"pata":       # raspa o pé no chão, mirando o jogador
			Fit.play(_ap, &"Paw", false, 1.0)
			if d > 0.1:
				rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 6.0 * delta)
				# recua um pouco para pegar distância antes da chifrada
				if d < 9.0:
					velocity.x = -to.x / d * 2.4
					velocity.z = -to.z / d * 2.4
			if _t > 1.5:
				_dir = to.normalized() if d > 0.1 else global_basis.z
				_mudar("investida")
		"investida":  # corre em linha reta com os chifres
			Fit.play(_ap, &"Charge", true, 2.2)
			velocity.x = _dir.x * speed * 3.6
			velocity.z = _dir.z * speed * 3.6
			rotation.y = atan2(_dir.x, _dir.z)
			if _bateu == 0 and d < 3.0:
				_bateu = 1
				_acertar(3.4, int(damage * 1.7))
			if _t > 1.5 or (_t > 0.25 and get_real_velocity().length() < 2.0):
				_cd = 1.2
				_mudar("segue")
	velocity.y = velocity.y - 20.0 * delta if not is_on_floor() else 0.0
	move_and_slide()
	if estado == "segue":
		# se ficar preso numa construção, contorna pelo lado
		if moving:
			if get_real_velocity().length() < speed * 0.35:
				_preso += delta
				if _preso > 0.4 and _desvio <= 0.0:
					_desvio = 1.2
					_lado = -_lado
			else:
				_preso = 0.0
		if _desvio > 0.0:
			_desvio -= delta
			var dd := to.normalized()
			velocity.x = (dd.x * 0.2 - dd.z * _lado) * speed
			velocity.z = (dd.z * 0.2 + dd.x * _lado) * speed
			move_and_slide()
		if _tonto > 0.0:
			_tonto -= delta
		elif fase == 1:
			Fit.play(_ap, &"AxeWalk" if moving else &"AxeIdle", true, speed / PASSO if moving else 1.0)
		else:
			Fit.play(_ap, &"Walk" if moving else &"Idle", true, speed / PASSO if moving else 1.0)

func hurt(amount: int) -> void:
	if _dead:
		return
	hp -= amount
	if fase == 1 and hp <= int(max_hp * largar_machado_em):
		_largar_machado()
	if hp <= 0:
		hp = 0
		_dead = true
		collision_layer = 0
		collision_mask = 0
		var tw := create_tween()
		tw.tween_property(_pivot, "rotation:x", -PI * 0.5, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(_pivot, "position:y", 0.6, 1.1)
		killed.emit()
		await get_tree().create_timer(5.0).timeout
		queue_free()
	elif estado == "segue":
		_tonto = 0.35
		if _ap:
			_ap.stop()
		Fit.play(_ap, &"Hit", false, 1.6)
