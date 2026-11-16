extends CharacterBody3D
## Jogador: anda com o direcional (ou WASD) e ataca com o botão (ou Espaço).

signal attacked
signal died

@export var speed := 6.0
@export var max_hp := 100
@export var damage := 12
@export var attack_range := 2.6

var hp := 100
var joy := Vector2.ZERO          # preenchido pelo direcional da tela
var primeira_pessoa := false     # na 1ª pessoa o direcional gira e anda para a frente
var _cd := 0.0
var _busy := 0.0
var _ap: AnimationPlayer
var _idle: StringName
var _run: StringName
var _atk: StringName
var _dead := false

@onready var model: Node3D = $Model

func _ready() -> void:
	hp = max_hp
	Fit.to_height(model, 1.8)
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_idle = Fit.find_anim(_ap, ["Idle"])
	_run = Fit.find_anim(_ap, ["Run", "Walking", "Walk"])
	_atk = Fit.find_anim(_ap, ["Run_swordAttack", "swordAttack", "Attack", "Punch"])
	Fit.play(_ap, _idle)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_cd = maxf(0.0, _cd - delta)
	_busy = maxf(0.0, _busy - delta)
	var v := joy + Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length() > 1.0:
		v = v.normalized()
	# a câmera olha de trás e de cima, então "para cima" na tela é -Z no mundo
	var dir := Vector3(v.x, 0, v.y)
	if primeira_pessoa:
		rotation.y -= v.x * 2.4 * delta
		dir = global_basis.z * (-v.y)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = velocity.y - 20.0 * delta if not is_on_floor() else 0.0
	move_and_slide()
	if dir.length() > 0.1 and not primeira_pessoa:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
	if Input.is_action_just_pressed("attack"):
		attack()
	if _busy <= 0.0:
		Fit.play(_ap, _run if dir.length() > 0.1 else _idle)

func attack() -> void:
	if _dead or _cd > 0.0:
		return
	_cd = 0.55
	_busy = 0.45
	if _atk != &"":
		_ap.stop()
		Fit.play(_ap, _atk, false, 1.6)
	attacked.emit()

func hurt(amount: int) -> void:
	if _dead:
		return
	hp = maxi(0, hp - amount)
	if hp == 0:
		_dead = true
		Fit.play(_ap, Fit.find_anim(_ap, ["Death"]), false)
		died.emit()

func revive(at: Vector3) -> void:
	_dead = false
	hp = max_hp
	global_position = at
	Fit.play(_ap, _idle)
