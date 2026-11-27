extends CharacterBody3D
## Inimigo simples: persegue o jogador e bate quando chega perto.

signal killed

@export var speed := 3.2
@export var max_hp := 30
@export var damage := 8
@export var altura := 1.9        # altura do modelo (m)
var guarda := false              # monstro de vila: fica perto de `casa` e só ataca quem chega perto
var casa := Vector3.ZERO
var raio_guarda := 22.0
var rumo: Variant = null
var nivel := 1                   # acompanha o nível do personagem (mais vida e mais dano)
var _base_hp := 0
var _base_dano := 0
var voz := "grunhido"
var _outro: Node3D = null        # alvo que não é o jogador: guarda, aldeão ou construção da aldeia
var _busca_t := 0.0            # som de dor/ataque: grunhido (orc), rugido (lobisomem, yeti), osso (caveira), pedra (golem)         # com o jogador longe, anda até aqui (orcs do barco vão para a aldeia)

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
var jogo: Node

func setup(scene: PackedScene, player: Node3D) -> void:
	setup_no(scene.instantiate(), player)

func setup_no(m: Node3D, player: Node3D) -> void:
	target = player
	hp = max_hp
	model = m
	add_child(model)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	add_child(shape)

func _ready() -> void:
	_base_hp = max_hp
	_base_dano = damage
	var j := get_tree().get_first_node_in_group("jogo")
	if j != null and j.get("nivel_jog") != null:
		ajustar_nivel(int(j.nivel_jog))
	Fit.to_height(model, altura)
	model.position.y += 0.05   # pés um pouco acima do chão (sumiam na praça e nos caminhos de terra)
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_idle = Fit.find_anim(_ap, ["Idle", "Rest"])
	_run = Fit.find_anim(_ap, ["Run", "Gallop", "Fast_Flying", "Walk"])
	_atk = Fit.find_anim(_ap, ["Punch", "Attack", "Attak", "Weapon", "Throw", "Headbutt", "creep"])
	_hit = Fit.find_anim(_ap, ["HitReact", "RecieveHit", "Hit_A"])
	_death = Fit.find_anim(_ap, ["Death"])
	Fit.play(_ap, _idle)

func _physics_process(delta: float) -> void:
	if _dead or target == null:
		return
	_cd = maxf(0.0, _cd - delta)
	_busy = maxf(0.0, _busy - delta)
	if guarda and _vigiar(delta):
		return
	# invasores escolhem o alvo mais perto: o jogador, um guarda, um aldeão ou uma construção
	if not guarda:
		_busca_t -= delta
		if _busca_t <= 0.0:
			_busca_t = 0.8
			var jg := get_tree().get_first_node_in_group("jogo")
			_outro = jg.alvo_na_aldeia(global_position, 14.0) if jg != null and jg.has_method("alvo_na_aldeia") else null
			if _outro != null and global_position.distance_to(target.global_position) < global_position.distance_to(_outro.global_position) + 3.0:
				_outro = null
		if _outro != null and is_instance_valid(_outro):
			_atacar_outro(delta)
			return
	if rumo != null and global_position.distance_to(target.global_position) >= 90.0:
		_andar_ate(rumo, 20.0, delta)
		return
	var to := target.global_position - global_position
	to.y = 0
	var d := to.length()
	var moving := false
	# com a muralha de pé, dá a volta até um portão
	var via := to
	var desvia := false
	if jogo == null:
		jogo = get_parent()
	if jogo != null and jogo.has_method("destino"):
		var dest: Vector3 = jogo.destino(global_position)
		desvia = dest.distance_to(target.global_position) > 0.5
		via = dest - global_position
		via.y = 0
	# portão fechado no caminho: para e bate nele
	var portao = jogo.portao_em(global_position) if (desvia and jogo != null and jogo.has_method("portao_em")) else null
	if portao != null:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		var pg: Vector3 = portao.pos - global_position
		rotation.y = lerp_angle(rotation.y, atan2(pg.x, pg.z), 8.0 * delta)
		if _cd <= 0.0:
			_cd = 1.4
			_busy = 0.6
			_ap.stop()
			Fit.play(_ap, _atk, false, 1.4)
			jogo.bater_portao(portao, damage)
		elif _busy <= 0.0:
			Fit.play(_ap, _idle)
		return
	if (desvia or d > 1.7) and d < 90.0 and _busy <= 0.0 and via.length() > 0.2:
		var dir := via.normalized()
		to = via
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
		Som.efeito(voz if voz != "osso" else "ataque_monstro", global_position)
		if Som.eu != null:
			Som.eu.em_batalha()
	elif _busy <= 0.0:
		Fit.play(_ap, _run if moving else _idle)

func _atacar_outro(delta: float) -> void:
	var to := _outro.global_position - global_position
	to.y = 0
	var alcance := 2.0 + float(_outro.get_meta("raio", 0.0))
	if to.length() > alcance:
		_andar_ate(_outro.global_position, alcance - 0.3, delta)
		return
	velocity.x = 0
	velocity.z = 0
	move_and_slide()
	rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 8.0 * delta)
	if _cd <= 0.0:
		_cd = 1.4
		_busy = 0.6
		_ap.stop()
		Fit.play(_ap, _atk, false, 1.4)
		Som.efeito(voz if voz != "osso" else "ataque_monstro", global_position)
		if _outro.has_method("hurt"):
			_outro.hurt(damage)
		else:
			var jg := get_tree().get_first_node_in_group("jogo")
			if jg != null:
				jg.danificar_construcao(_outro, damage)
				Som.efeito("pancada_madeira", _outro.global_position)
		if _outro.get("caido") == true or _outro.get_meta("destruida", false):
			_outro = null
	elif _busy <= 0.0:
		Fit.play(_ap, _idle)

## Guarda de vila: longe do jogador fica em casa. Devolve true quando não está perseguindo.
func _vigiar(delta: float) -> bool:
	var jc := target.global_position.distance_to(casa)
	if jc > 150.0:   # jogador em outra região: nem processa
		return true
	if global_position.distance_to(target.global_position) < raio_guarda and jc < raio_guarda * 2.5 and target.get("hp") > 0:
		return false
	_andar_ate(casa, 2.5, delta)
	return true

func _andar_ate(p: Vector3, perto: float, delta: float) -> void:
	var to: Vector3 = p - global_position
	to.y = 0
	if to.length() > perto and _busy <= 0.0:
		var dir := to.normalized()
		velocity.x = dir.x * speed * 0.6
		velocity.z = dir.z * speed * 0.6
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 6.0 * delta)
		Fit.play(_ap, _run)
	else:
		velocity.x = 0
		velocity.z = 0
		if _busy <= 0.0:
			Fit.play(_ap, _idle)
	velocity.y = velocity.y - 20.0 * delta if not is_on_floor() else 0.0
	move_and_slide()

## Sobe ou desce o nível: vida e dano crescem com o nível do personagem (a vida atual cresce junto).
func ajustar_nivel(n: int) -> void:
	nivel = n
	var f := Niveis.forca_inimigo(n)
	var novo := int(_base_hp * f.x)
	if max_hp > 0:
		hp = int(float(hp) * novo / max_hp)
	max_hp = novo
	damage = int(_base_dano * f.y)

func hurt(amount: int) -> void:
	if _dead:
		return
	hp -= amount
	Som.efeito(voz if hp > 0 else ("osso" if voz == "osso" else "morte"), global_position, 2.0 if altura > 4.0 else 0.0)
	if Som.eu != null:
		Som.eu.em_batalha()
	if hp <= 0:
		_dead = true
		collision_layer = 0
		collision_mask = 0
		if _death != &"":
			Fit.play(_ap, _death, false)
		else:   # sem animação de morte (lobisomem): tomba de lado
			create_tween().tween_property(model, "rotation:z", PI * 0.5, 0.5)
		killed.emit()
		var j := get_tree().get_first_node_in_group("jogo")
		if j != null and j.has_method("ganhar_xp"):
			j.ganhar_xp(int(10 + _base_hp / 6))   # experiência pela força do inimigo
		await get_tree().create_timer(2.5).timeout
		queue_free()
	else:
		_busy = 0.3
		_ap.stop()
		Fit.play(_ap, _hit, false, 1.5)
