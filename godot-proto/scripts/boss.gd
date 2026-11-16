extends CharacterBody3D
## Minotauro Dark: o chefe. O modelo não tem esqueleto, então o movimento é feito por código
## (balanço ao andar, investida ao atacar, queda ao morrer).

signal killed

@export var altura := 4.6
@export var speed := 2.8

var max_hp := 500
var hp := 500
var damage := 22
var nivel := 1
var target: Node3D
var jogo: Node
var _dead := false
var _cd := 2.0
var _golpe := -1.0        # tempo dentro do golpe (-1 = não está atacando)
var _bateu := false
var raio := 1.6            # corpo largo: o golpe do jogador alcança de mais longe
var _preso := 0.0
var _desvio := 0.0
var _lado := 1.0
var _t := 0.0
var model: Node3D
var _pivot: Node3D

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
	# material escuro com leve brilho metálico
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.12, 0.16)
	mat.metallic = 0.45
	mat.roughness = 0.5
	var meshes: Array = []
	Fit._collect(model, meshes)
	for m: MeshInstance3D in meshes:
		m.material_override = mat
	# olhos vermelhos brilhantes (posições medidas no modelo original)
	var olho := StandardMaterial3D.new()
	olho.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	olho.albedo_color = Color(1.0, 0.1, 0.05)
	for p in [Vector3(-0.047, 0.668, 0.222), Vector3(0.043, 0.672, 0.25)]:
		var e := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.013
		s.height = 0.026
		s.material = olho
		e.mesh = s
		e.position = p
		model.add_child(e)
	Fit.to_height(model, altura)

func _physics_process(delta: float) -> void:
	if _dead or target == null:
		return
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	var to := target.global_position - global_position
	to.y = 0
	var d := to.length()
	var moving := false
	if _golpe < 0.0 and d > 3.2 and d < 80.0:
		var dir := to / d
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		moving = true
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y = velocity.y - 20.0 * delta if not is_on_floor() else 0.0
	move_and_slide()
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
	if d > 0.1 and _golpe < 0.0:
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 4.0 * delta)
	# começa o golpe
	if _golpe < 0.0 and d <= 4.0 and _cd <= 0.0 and target.get("hp") > 0:
		_golpe = 0.0
		_bateu = false
	# animação por código
	if _golpe >= 0.0:
		_golpe += delta
		if _golpe < 0.55:      # prepara: inclina para trás
			_pivot.rotation.x = lerpf(_pivot.rotation.x, -0.35, 10.0 * delta)
		elif _golpe < 0.8:     # investe para a frente
			_pivot.rotation.x = lerpf(_pivot.rotation.x, 0.55, 22.0 * delta)
			if not _bateu:
				_bateu = true
				if target.global_position.distance_to(global_position) < 5.2:
					target.call("hurt", damage)
		else:
			_pivot.rotation.x = lerpf(_pivot.rotation.x, 0.0, 8.0 * delta)
			if _golpe > 1.3:
				_golpe = -1.0
				_cd = 2.2
	elif moving:
		_pivot.position.y = absf(sin(_t * 5.0)) * 0.14
		_pivot.rotation.z = sin(_t * 5.0) * 0.06
		_pivot.rotation.x = lerpf(_pivot.rotation.x, 0.08, 6.0 * delta)
	else:
		_pivot.position.y = lerpf(_pivot.position.y, 0.0, 6.0 * delta)
		_pivot.rotation.z = lerpf(_pivot.rotation.z, 0.0, 6.0 * delta)
		_pivot.rotation.x = sin(_t * 1.6) * 0.025

func hurt(amount: int) -> void:
	if _dead:
		return
	hp -= amount
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
	else:
		var tw := create_tween()
		tw.tween_property(_pivot, "scale", Vector3.ONE * 1.05, 0.05)
		tw.tween_property(_pivot, "scale", Vector3.ONE, 0.1)
