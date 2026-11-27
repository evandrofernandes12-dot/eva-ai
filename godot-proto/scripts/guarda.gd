extends Node3D
class_name Guarda
## Guarda de uma casa, armazém ou do castelo: fica no posto (andando um pouco em volta) e luta.
## Arqueiro: atira flechas no inimigo a até 18 m. Guerreiro: corre até o inimigo a até 14 m, golpeia
## com a espada e volta ao posto quando não há mais ninguém por perto.

var tipo := "guerreiro"      # ou "arqueiro"
var sexo := "m"
var posto := Vector3.ZERO
var fixo := false            # flecheiro numa torre: não sai andando, só gira e atira
var jogo: Node
var model: Node3D
var _ap: AnimationPlayer
var _arco: Node
var _cd := 0.0
var _passeio := Vector3.ZERO
var _t := 0.0
var _rng := RandomNumberGenerator.new()
const DANO := 8
const ALCANCE_ARCO := 18.0
const ALCANCE_ESPADA := 14.0

func _ready() -> void:
	_rng.randomize()
	var id := ("G1" if sexo == "m" else "G3") if tipo == "guerreiro" else ("A1" if sexo == "m" else "A4")
	model = Heroi.montar(id)
	add_child(model)
	Fit.to_height(model, 1.8 if sexo == "m" else 1.7)
	model.position.y += 0.05
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_arco = model.find_child("ArcoIK", true, false)
	posto = global_position
	_passeio = posto
	var tag := Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.text = "Guarda" if sexo == "m" else "Guarda"
	tag.font_size = 26
	tag.outline_size = 8
	tag.pixel_size = 0.011
	tag.position.y = 2.2
	tag.visibility_range_end = 24.0
	tag.modulate = Color(0.75, 0.85, 1.0)
	add_child(tag)


## Leva um golpe de inimigo. Sem vida, cai desmaiado e volta ao posto/trabalho depois de um tempo.
var hp := 140
var max_hp := 140
var caido := false
func hurt(dano: int) -> void:
	if caido:
		return
	hp -= dano
	Som.efeito("dor_jogador", global_position, -4.0)
	if hp > 0:
		return
	caido = true
	var tw := create_tween()
	tw.tween_property(model, "rotation:x", -PI * 0.5, 0.5)
	tw.tween_property(model, "position:y", 0.25, 0.2)
	get_tree().create_timer(40.0).timeout.connect(func():
		caido = false
		hp = max_hp
		model.rotation.x = 0.0
		model.position.y = 0.05)

func _tocar(nome: String) -> void:
	Fit.play(_ap, Fit.find_anim(_ap, [nome]), true)

func _inimigo(alcance: float) -> Node3D:
	var melhor: Node3D = null
	var bd := alcance
	for e in jogo.enemies:
		if is_instance_valid(e) and not e._dead:
			var d: float = e.global_position.distance_to(global_position)
			if d < bd:
				bd = d
				melhor = e
	return melhor

func _process(delta: float) -> void:
	if jogo == null or not visible or caido:
		return
	_cd -= delta
	_t -= delta
	var alvo := _inimigo(ALCANCE_ARCO if tipo == "arqueiro" else ALCANCE_ESPADA)
	if alvo != null:
		var to := alvo.global_position - global_position
		to.y = 0
		rotation.y = atan2(to.x, to.z)
		if tipo == "arqueiro":
			_tocar("Idle")
			if _cd <= 0.0:
				_cd = 1.6
				if _arco != null:
					_arco.disparar()
				jogo.flecha_de(global_position + Vector3(0, 1.4, 0) + to.normalized() * 0.6, alvo, DANO)
		else:
			if to.length() > 1.8:
				global_position += to.normalized() * 5.0 * delta
				_tocar("Jog_Fwd")
			else:
				_tocar("Sword_Regular_A")
				if _cd <= 0.0:
					_cd = 1.2
					alvo.hurt(DANO)
		return
	# sem inimigo: volta ao posto e passeia um pouco em volta dele (o flecheiro da torre fica parado)
	if fixo:
		_tocar("Idle")
		return
	var dest := _passeio
	var d := dest - global_position
	d.y = 0
	if d.length() > 0.4:
		global_position += d.normalized() * minf(2.0 * delta, d.length())
		rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), 6.0 * delta)
		_tocar("Walk")
	else:
		_tocar("Idle_Shield" if tipo == "guerreiro" else "Idle")
		if _t <= 0.0:
			_t = _rng.randf_range(5.0, 12.0)
			var a := _rng.randf() * TAU
			_passeio = posto + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.0, 2.5)
