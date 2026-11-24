extends Node3D
class_name Animal
## Animal da floresta ou do curral: passeia dentro da sua área, para para pastar/olhar em volta e,
## se for selvagem, foge do jogador. Pode ser caçado (jogador ou caçadores): morre, cai e vira carne (comida).

## tipo -> [arquivo, altura (m), anim parado, anim andando, anim correndo, anim morrendo, cor (opcional)]
const TIPOS := {
	"coelho": ["res://models/animais/Coelho.glb", 0.45, "Sitting.000", "Jump", "Running", "Dying.000"],
	"cervo": ["res://models/animais/Cervo.glb", 1.7, "Idle", "Run", "Run", "Die.000"],
	"corca": ["res://models/animais/Corca.glb", 1.35, "Idle", "Run", "Run", "Die.000", Color(0.55, 0.36, 0.2)],
	"crocodilo": ["res://models/animais/Crocodilo.glb", 0.45, "", "", "", "", Color(0.25, 0.33, 0.16)],
	"galinha": ["res://models/animais/Galinha.glb", 0.45, "Idle", "Pecking1", "Pecking1", "Dying"],
	"vaca": ["res://models/animais/Vaca.gltf", 1.5, "Idle", "WalkSlow", "Walk", "Death"],
	"porco": ["res://models/animais/Porco.gltf", 0.9, "Idle", "WalkSlow", "Walk", "Death"],
	"ovelha": ["res://models/animais/Ovelha.gltf", 1.0, "Idle", "WalkSlow", "Walk", "Death"],
	"cavalo": ["res://models/pets/cavalo.glb", 1.75, "", "horse", "horse", "", Color(0.55, 0.35, 0.2)],   # o cavalo realista do pet, marrom
}
const VEL := {"coelho": 3.5, "cervo": 4.5, "corca": 4.5, "crocodilo": 0.8, "galinha": 0.7, "vaca": 0.8, "porco": 0.9, "ovelha": 0.8, "cavalo": 1.6}
const CARNE := {"coelho": 3, "cervo": 10, "corca": 8, "crocodilo": 8, "galinha": 2, "vaca": 12, "porco": 8, "ovelha": 8, "cavalo": 10}

const CORES_MAT := {"galinha": {"Comb": Color(0.8, 0.1, 0.08), "Material.001": Color(0.72, 0.52, 0.32)}}
const LISOS := ["vaca", "porco", "ovelha"]

## Normais suavizadas (média das faces que tocam cada ponto), mantendo ossos e pesos da animação.
static var _lisos := {}
static func _suavizar(m: ArrayMesh) -> ArrayMesh:
	if m == null:
		return m
	if _lisos.has(m):
		return _lisos[m]
	var novo := ArrayMesh.new()
	for si in m.get_surface_count():
		var arr := m.surface_get_arrays(si)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var soma := {}
		for i in vs.size():
			var k := (vs[i] * 1000.0).round()
			soma[k] = soma.get(k, Vector3.ZERO) + ns[i]
		for i in vs.size():
			var k2 := (vs[i] * 1000.0).round()
			var n: Vector3 = soma[k2]
			ns[i] = n.normalized() if n.length() > 0.0001 else ns[i]
		arr[Mesh.ARRAY_NORMAL] = ns
		arr[Mesh.ARRAY_TANGENT] = null
		novo.add_surface_from_arrays(m.surface_get_primitive_type(si), arr, [], {}, m.surface_get_format(si) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
		novo.surface_set_material(si, m.surface_get_material(si))
	_lisos[m] = novo
	return novo

var tipo := "coelho"
var selvagem := true
var centro := Vector3.ZERO     # área onde passeia (círculo)
var raio := 10.0
var hp := 3
var morto := false
var _dead := false             # mesmo nome dos inimigos (pets e tiros checam _dead)
var reservado: Node = null     # caçador que escolheu este animal
var jogador: Node3D
var model: Node3D
var _ap: AnimationPlayer
var _alvo := Vector3.ZERO
var _t := 0.0
var _fugindo := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	var info: Array = TIPOS[tipo]
	model = (load(info[0]) as PackedScene).instantiate()
	add_child(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.name.begins_with("Plane"):   # alguns vêm com um plano de sombra embaixo
			mi.visible = false
		elif info.size() > 6:              # sem textura no arquivo: pinta (corça marrom, crocodilo verde)
			var m := StandardMaterial3D.new()
			m.vertex_color_use_as_albedo = true   # mantém o sombreado pintado nos vértices (cavalo)
			m.albedo_color = info[6] if not mi.name.begins_with("Eye") else Color(0.05, 0.05, 0.05)
			m.roughness = 0.8
			mi.material_override = m
	if CORES_MAT.has(tipo):   # galinha: crista vermelha e parte de baixo creme (vinha branca)
		var cm: Dictionary = CORES_MAT[tipo]
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var mt := mi.mesh.surface_get_material(i)
				if mt != null and cm.has(mt.resource_name):
					var nm := StandardMaterial3D.new()
					nm.albedo_color = cm[mt.resource_name]
					nm.roughness = 0.8
					mi.set_surface_override_material(i, nm)
	if tipo in LISOS:   # vaca, porco e ovelha vinham "quadrados" (sombreado facetado): normais suavizadas
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			mi.mesh = _suavizar(mi.mesh as ArrayMesh)
	Fit.to_height(model, info[1])
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	hp = 2 if info[1] < 0.6 else 4
	_alvo = position
	_tocar(info[2])

func _tocar(nome: String, laco := true, vel := 1.0) -> void:
	if _ap == null:
		return
	if nome == "":   # sem animação de parado: congela a pose
		if _ap.is_playing():
			_ap.pause()
		return
	var a := Fit.find_anim(_ap, [nome])
	if a != &"":
		Fit.play(_ap, a, laco, vel)

func _process(delta: float) -> void:
	if morto:
		return
	var info: Array = TIPOS[tipo]
	_t -= delta
	_fugindo = maxf(0.0, _fugindo - delta)
	var vel: float = VEL[tipo]
	# selvagem: foge do jogador que chega perto
	if selvagem and is_instance_valid(jogador) and tipo != "crocodilo":
		var d := jogador.global_position - global_position
		d.y = 0
		if d.length() < 7.0:
			_fugindo = 2.5
			_alvo = global_position - d.normalized() * 10.0
	if _fugindo > 0.0:
		vel *= 2.2
	var to := _alvo - global_position
	to.y = 0
	if to.length() > 0.4:
		var passo := minf(vel * delta, to.length())
		var novo := global_position + to.normalized() * passo
		if Vector2(novo.x - centro.x, novo.z - centro.z).length() <= raio + 0.5 or _fugindo > 0.0:
			global_position = novo
		else:
			_alvo = global_position
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 6.0 * delta)
		_tocar(info[4] if _fugindo > 0.0 else info[3], true, 0.45 if tipo == "cavalo" else 1.0)
	else:
		_tocar(info[2])
		if _t <= 0.0:   # escolhe outro lugar para ir (às vezes fica parado mais um pouco)
			_t = _rng.randf_range(3.0, 9.0)
			if _rng.randf() < 0.7:
				var a := _rng.randf() * TAU
				_alvo = centro + Vector3(cos(a), 0, sin(a)) * sqrt(_rng.randf()) * raio

## Leva um golpe ou uma flecha. Devolve true quando morre.
func ferir(dano: int) -> bool:
	if morto:
		return false
	hp -= maxi(1, dano / 6)
	_fugindo = 3.0
	if hp > 0:
		return false
	morto = true
	_dead = true
	var info: Array = TIPOS[tipo]
	if info[5] != "":
		_tocar(info[5], false)
	else:   # sem animação de morte: tomba de lado
		create_tween().tween_property(self, "rotation:z", PI * 0.5, 0.5)
	return true

## Flecha do jogador (main.gd chama hurt nos alvos dos tiros).
func hurt(dano: int) -> void:
	if ferir(dano * 3) and get_parent().has_method("abatido"):
		get_parent().abatido(self)

func carne() -> int:
	return CARNE[tipo]
