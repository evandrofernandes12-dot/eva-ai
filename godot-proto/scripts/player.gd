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
var _arco: Node   # arco_ik.gd do arqueiro (levanta o arco e puxa a corda)
var _dead := false
var _morte: StringName = &""
var correndo := false            # botão CORRER (ou Shift)
var defendendo := false          # botão DEFESA (ou Q): recebe 1/4 do dano e anda devagar
var em_guarda := false
var avanco := 0.0                # velocidade do avanço ao golpear (lanceiro: estocada)
var _lunge := 0.0
var _def: StringName = &""
var _corre: StringName = &""
var _bolha: MeshInstance3D
var _lanca: Node3D               # BoneAttachment da lança (estocada com a ponta)
var _lanca_t := 0.0
var _lanca_tr := Transform3D()

@onready var model: Node3D = $Model

func _ready() -> void:
	hp = max_hp
	Fit.to_height(model, 1.8)
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_idle = Fit.find_anim(_ap, ["Idle"])
	_run = Fit.find_anim(_ap, ["Run", "Walking", "Walk"])
	_atk = Fit.find_anim(_ap, ["Run_swordAttack", "swordAttack", "Attack", "Punch"])
	Fit.play(_ap, _idle)
	_bolha = MeshInstance3D.new()   # bolha azul que aparece durante a defesa
	var sp := SphereMesh.new()
	sp.radius = 1.05
	sp.height = 2.1
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_color = Color(0.45, 0.7, 1.0, 0.22)
	sp.material = bm
	_bolha.mesh = sp
	_bolha.position.y = 0.95
	_bolha.visible = false
	add_child(_bolha)

## Troca o boneco por um dos personagens (Heroi.montar) com as animações da classe.
func trocar_modelo(novo: Node3D, anims: Dictionary) -> void:
	var antigo := model
	add_child(novo)
	novo.rotation = antigo.rotation
	novo.visible = antigo.visible
	antigo.queue_free()
	model = novo
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_idle = anims.idle
	_run = anims.run
	_atk = anims.atk
	_morte = anims.morte
	_lanca = novo.find_child("Lanca", true, false) as Node3D
	_arco = novo.find_child("ArcoIK", true, false)
	_lanca_t = 0.0
	_def = anims.get("def", &"")
	_corre = anims.get("corre", &"")
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
	em_guarda = defendendo or Input.is_action_pressed("block")
	var corre := correndo or Input.is_action_pressed("run")
	var mult := 0.35 if em_guarda else (1.7 if corre else 1.0)
	_bolha.visible = em_guarda
	velocity.x = dir.x * speed * mult
	velocity.z = dir.z * speed * mult
	if _lunge > 0.0:   # avanço do golpe (estocada do lanceiro)
		_lunge -= delta
		velocity.x = global_basis.z.x * avanco
		velocity.z = global_basis.z.z * avanco
	velocity.y = velocity.y - 20.0 * delta if not is_on_floor() else 0.0
	move_and_slide()
	if dir.length() > 0.1 and not primeira_pessoa:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
	if Input.is_action_just_pressed("attack"):
		attack()
	if _busy <= 0.0:
		if em_guarda and _def != &"":
			Fit.play(_ap, _def)
		elif dir.length() > 0.1:
			Fit.play(_ap, _corre if (corre and _corre != &"") else _run, true, 1.0)
		else:
			Fit.play(_ap, _idle)

func attack() -> void:
	if _dead or _cd > 0.0:
		return
	defendendo = false   # atacar baixa a guarda
	_lunge = 0.16 if avanco > 0.0 else 0.0
	if _lanca != null and _lanca_t <= 0.0:
		_lanca_t = 0.5
		_lanca_tr = (_lanca.get_child(0) as Node3D).transform
	_cd = 0.55
	_busy = 0.45
	if _arco != null:
		_arco.disparar()
	if _atk != &"":
		_ap.stop()
		Fit.play(_ap, _atk, false, 1.6)
	attacked.emit()

func hurt(amount: int) -> void:
	if _dead:
		return
	if em_guarda:
		amount = maxi(1, int(amount * 0.25))
	hp = maxi(0, hp - amount)
	if hp == 0:
		_dead = true
		Fit.play(_ap, _morte if _morte != &"" else Fit.find_anim(_ap, ["Death"]), false)
		died.emit()

func revive(at: Vector3) -> void:
	_dead = false
	hp = max_hp
	global_position = at
	Fit.play(_ap, _idle)

## Estocada: durante o golpe a lança deixa a mão do osso e aponta a PONTA para a frente,
## avançando e voltando junto com a mão (o braço faz o soco da animação).
func _process(delta: float) -> void:
	if _lanca == null or _lanca_t <= 0.0:
		return
	var piv := _lanca.get_child(0) as Node3D
	_lanca_t -= delta
	if _lanca_t <= 0.0:
		piv.top_level = false
		piv.transform = _lanca_tr
		return
	var k := 1.0 - _lanca_t / 0.5
	var f := Vector3(global_basis.z.x, 0, global_basis.z.z).normalized()
	var y := (f + Vector3(0, 0.04, 0)).normalized()   # a ponta (+Y do cabo) aponta para a frente
	var x := y.cross(Vector3.UP).normalized()
	var z := x.cross(y)
	piv.top_level = true
	piv.global_transform = Transform3D(Basis(x, y, z), _lanca.global_position + f * (1.0 * sin(k * PI)) + Vector3(0, 0.05, 0))
