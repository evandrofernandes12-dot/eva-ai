extends CharacterBody3D
## Minotauro Dark: o chefe.
## Fase 1: luta com o machado. Quando a vida cai até `largar_machado_em`, o machado cai no chão.
## Fase 2: dá dois socos; depois raspa o pé no chão (patada) e investe com os chifres.
## Esqueleto e animações foram feitos no Blender por script.

signal killed
signal largou_machado

@export var altura := 4.6
@export var speed := 2.8
## Fração da vida em que ele larga o machado (0.9 = quando a vida chega a 90%).
@export_range(0.05, 0.95) var largar_machado_em := 0.9

var max_hp := 500
var hp := 500
var damage := 22
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
	model.scale = Vector3.ONE * k
	model.position.y = 0.95 * k
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_montar.call_deferred()

## Olhos (presos à cabeça) e machado (preso à mão da frente).
func _montar() -> void:
	var sk := Fit.find_node_of(model, "Skeleton3D") as Skeleton3D
	var cabeca: Node3D = model
	var mao: Node3D = model
	if sk != null:
		if sk.find_bone("Head") >= 0:
			cabeca = BoneAttachment3D.new()
			cabeca.bone_name = "Head"
			sk.add_child(cabeca)
		if sk.find_bone("HandA") >= 0:
			mao = BoneAttachment3D.new()
			mao.bone_name = "HandA"
			sk.add_child(mao)
	var olho := StandardMaterial3D.new()
	olho.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	olho.albedo_color = Color(1.0, 0.25, 0.05)
	for p in [Vector3(-0.047, 0.668, 0.222), Vector3(0.043, 0.672, 0.25)]:
		var e := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.011
		sp.height = 0.022
		sp.material = olho
		e.mesh = sp
		cabeca.add_child(e)
		e.transform = _no_osso(sk, "Head", Transform3D(Basis(), p))
	machado = _criar_machado()
	mao.add_child(machado)
	# na pose de descanso: cabo para cima e um pouco para a frente, lâminas no plano frente-trás, passando pela mão
	var y := Vector3(0.0, 0.92, 0.38).normalized()
	var z := Vector3(1.0, 0.0, 0.0)
	var x := y.cross(z).normalized()
	machado.transform = _no_osso(sk, "HandA", Transform3D(Basis(x, y, z), Vector3(-0.445, -0.25, 0.19)))
	Fit.play(_ap, &"AxeIdle")

## Converte uma posição dada no espaço do modelo (pose de descanso) para o espaço local do osso.
func _no_osso(sk: Skeleton3D, osso: String, no_modelo: Transform3D) -> Transform3D:
	if sk == null or sk.find_bone(osso) < 0:
		return no_modelo
	var no_esqueleto: Transform3D = sk.global_transform.affine_inverse() * model.global_transform * no_modelo
	return sk.get_bone_global_rest(sk.find_bone(osso)).affine_inverse() * no_esqueleto

## Machado de duas lâminas, feito de formas simples (unidades do modelo: ele tem 1,9 de altura).
func _criar_machado() -> Node3D:
	var root := Node3D.new()
	root.name = "Machado"
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.3, 0.17, 0.08)
	madeira.roughness = 0.85
	var aco := StandardMaterial3D.new()
	aco.albedo_color = Color(0.62, 0.66, 0.72)
	aco.metallic = 0.75
	aco.roughness = 0.35
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.2, 0.2, 0.23)
	ferro.metallic = 0.6
	ferro.roughness = 0.5
	# cabo ao longo do eixo Y local; a mão segura perto de y = 0
	var cabo := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.022
	c.bottom_radius = 0.026
	c.height = 1.25
	c.radial_segments = 8
	c.material = madeira
	cabo.mesh = c
	cabo.position.y = 0.38
	root.add_child(cabo)
	# cabeça de ferro que prende as lâminas
	var cab := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.09, 0.2, 0.07)
	cb.material = ferro
	cab.mesh = cb
	cab.position.y = 0.9
	root.add_child(cab)
	# duas lâminas em meia-lua (discos finos, um de cada lado)
	for lado in [-1.0, 1.0]:
		var lam := MeshInstance3D.new()
		var d := CylinderMesh.new()
		d.top_radius = 0.19
		d.bottom_radius = 0.19
		d.height = 0.022
		d.radial_segments = 14
		d.material = aco
		lam.mesh = d
		lam.rotation.x = PI * 0.5                # disco "em pé", no plano do corte
		lam.scale = Vector3(0.75, 1.0, 1.0)
		lam.position = Vector3(lado * 0.13, 0.9, 0.0)
		root.add_child(lam)
	# ponta de lança em cima e pino embaixo
	for item in [[1.08, 0.2, 0.0], [-0.3, 0.12, PI]]:
		var p := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.04
		cone.height = item[1]
		cone.radial_segments = 6
		cone.material = aco
		p.mesh = cone
		p.position.y = item[0]
		p.rotation.x = item[2]
		root.add_child(p)
	return root

func _mudar(novo: String) -> void:
	estado = novo
	_t = 0.0
	_bateu = 0

func _acertar(alcance: float, dano: int) -> void:
	if target.get("hp") > 0 and target.global_position.distance_to(global_position) < alcance:
		target.call("hurt", dano)

func _largar_machado() -> void:
	fase = 2
	if machado == null or not is_instance_valid(machado):
		return
	var m := machado
	machado = null
	var gt := m.global_transform
	m.get_parent().remove_child(m)
	jogo.add_child(m)
	m.global_transform = gt
	var chao := Vector3(gt.origin.x, 0.12, gt.origin.z) + global_basis.x * 1.2
	var tw := m.create_tween()
	tw.tween_property(m, "global_position", chao, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(m, "global_rotation", Vector3(PI * 0.5, rotation.y + 0.6, 0.0), 0.45)
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
			if d > 3.2 and d < 80.0:
				var dir := to / d
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
				moving = true
			if d > 0.1:
				rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 4.0 * delta)
			if _cd <= 0.0 and target.get("hp") > 0:
				if fase == 1:
					if d <= 4.2:
						_mudar("golpe")
				elif _socos >= 2 or d > 7.0:
					if d < 26.0:
						_socos = 0
						_mudar("pata")
				elif d <= 3.8:
					_mudar("soco")
		"golpe":      # machado: sobe e desce
			Fit.play(_ap, &"AxeAttack", false, 1.2)
			if _t >= 0.6 and _bateu == 0:
				_bateu = 1
				_acertar(5.6, int(damage * 1.3))
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
			Fit.play(_ap, &"AxeWalk" if moving else &"AxeIdle")
		else:
			Fit.play(_ap, &"Walk" if moving else &"Idle")

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
