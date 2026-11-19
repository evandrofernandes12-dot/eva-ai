extends Node3D
## Aldeão: vai até o recurso do seu ofício, trabalha, volta e entrega na aldeia.

const NOMES := {"madeira": "Lenhador", "pedra": "Pedreiro", "comida": "Coletor"}
const CORES := {"madeira": Color(0.55, 0.85, 0.45), "pedra": Color(0.6, 0.7, 1.0), "comida": Color(1.0, 0.75, 0.4)}

var papel := "madeira"
var jogo: Node            # main.gd
var speed := 3.4
var carga := 0
var estado := "busca"
var alvo                   # entrada de jogo.nodes
var _t := 0.0
var _ap: AnimationPlayer
var _idle: StringName
var _run: StringName
var _atk: StringName
var model: Node3D
var _tag: Label3D

func setup(scene: PackedScene, main: Node, oficio: String) -> void:
	jogo = main
	papel = oficio
	model = scene.instantiate()
	add_child(model)

func _ready() -> void:
	Fit.to_height(model, 1.55)
	Fit.tint(model, CORES[papel])
	_ferramenta()
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_idle = Fit.find_anim(_ap, ["Idle"])
	_run = Fit.find_anim(_ap, ["Walking", "Walk", "Run"])
	_atk = Fit.find_anim(_ap, ["Run_swordAttack", "swordAttack", "Attack", "Punch"])
	_tag = Label3D.new()
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.font_size = 30
	_tag.outline_size = 10
	_tag.pixel_size = 0.012
	_tag.position.y = 2.1
	_tag.visibility_range_end = 28.0
	_tag.text = NOMES[papel]
	add_child(_tag)

func _alvo_ok() -> bool:
	return alvo != null and is_instance_valid(alvo.node) and alvo.hp > 0

func _andar(dest: Vector3, delta: float) -> bool:
	var to := dest - global_position
	to.y = 0
	var d := to.length()
	if d < 1.5:
		return true
	global_position += to / d * speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 8.0 * delta)
	Fit.play(_ap, _run)
	return false

func _process(delta: float) -> void:
	_t -= delta
	match estado:
		"busca":
			Fit.play(_ap, _idle)
			if _t > 0.0:
				return
			_t = 1.5
			alvo = jogo.reservar(papel, global_position, self)
			if alvo != null:
				estado = "ir"
		"ir":
			if not _alvo_ok():
				estado = "busca"
			elif _andar(alvo.node.global_position, delta):
				estado = "trabalha"
				_t = 1.0
		"trabalha":
			if not _alvo_ok():
				estado = "volta" if carga > 0 else "busca"
			elif _t <= 0.0:
				_t = 1.3
				_ap.stop()
				Fit.play(_ap, _atk, false, 1.4)
				carga += 2
				if jogo.golpear(alvo, false):
					carga += 2
					estado = "volta"
		"volta":
			if _andar(jogo.deposito(), delta):
				jogo.res[papel] += carga
				carga = 0
				estado = "busca"
				_t = 0.5

## Ferramenta na mão direita (Sketchfab, CC-BY: RoboticModels): machado do lenhador, picareta do pedreiro.
const FERRAMENTA := {"madeira": "res://models/armas/Machado_Lenhador.glb", "pedra": "res://models/armas/Picareta.glb"}

func _ferramenta() -> void:
	if not FERRAMENTA.has(papel) or not ResourceLoader.exists(FERRAMENTA[papel]):
		return
	var sk := Fit.find_node_of(model, "Skeleton3D") as Skeleton3D
	if sk == null or sk.find_bone("MiddleHand.R") < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "MiddleHand.R"
	sk.add_child(ba)
	# o esqueleto do modelo tem outra escala: mede a escala real para a ferramenta ter ~0,8 m no mundo
	var osso := sk.find_bone("MiddleHand.R")
	var s: float = maxf((sk.global_transform * sk.get_bone_global_pose(osso)).basis.get_scale().x, 0.0001)
	var piv := Node3D.new()            # o cabo atravessa o punho, com a cabeça da ferramenta para a frente
	piv.position = Vector3(0, 0.08 / s, 0)
	piv.rotation_degrees = Vector3(0, 0, 90)
	ba.add_child(piv)
	var f: Node3D = load(FERRAMENTA[papel]).instantiate()
	f.scale = Vector3.ONE * (0.8 / s)
	f.position = Vector3(0, 0.28 / s, 0)    # segura perto do fim do cabo
	piv.add_child(f)
