extends CharacterBody3D
## Inimigo simples: persegue o jogador e bate quando chega perto.

signal killed

@export var speed := 3.2
@export var max_hp := 30
@export var damage := 8

var hp := 30
var target: Node3D
var _cd := 1.0
var _busy := 0.0
var _dead := false
var _preso := 0.0
var _desvio := 0.0
var _lado := 1.0
var _ap: AnimationPlayer
var _idle: StringName
var _run: StringName
var _atk: StringName
var _hit: StringName
var _death: StringName
var model: Node3D

func setup(scene: PackedScene, player: Node3D) -> void:
	target = player
	hp = max_hp
	model = scene.instantiate()
	add_child(model)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	add_child(shape)

func _ready() -> void:
	Fit.to_height(model, 1.9)
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_idle = Fit.find_anim(_ap, ["Idle"])
	_run = Fit.find_anim(_ap, ["Run", "Walk"])
	_atk = Fit.find_anim(_ap, ["Punch", "Attack", "Weapon"])
	_hit = Fit.find_anim(_ap, ["HitReact"])
	_death = Fit.find_anim(_ap, ["Death"])
	Fit.play(_ap, _idle)

func _physics_process(delta: float) -> void:
	if _dead or target == null:
		return
	_cd = maxf(0.0, _cd - delta)
	_busy = maxf(0.0, _busy - delta)
	var to := target.global_position - global_position
	to.y = 0
	var d := to.length()
	var moving := false
	if d > 1.7 and d < 40.0 and _busy <= 0.0:
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
	if d > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 8.0 * delta)
	if d <= 1.9 and _cd <= 0.0 and target.get("hp") > 0:
		_cd = 1.4
		_busy = 0.6
		_ap.stop()
		Fit.play(_ap, _atk, false, 1.4)
		target.call("hurt", damage)
	elif _busy <= 0.0:
		Fit.play(_ap, _run if moving else _idle)

func hurt(amount: int) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0:
		_dead = true
		collision_layer = 0
		collision_mask = 0
		Fit.play(_ap, _death, false)
		killed.emit()
		await get_tree().create_timer(2.5).timeout
		queue_free()
	else:
		_busy = 0.3
		_ap.stop()
		Fit.play(_ap, _hit, false, 1.5)
