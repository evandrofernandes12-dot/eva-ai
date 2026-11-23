extends Node3D
## Lote de construção. Chegue perto e toque em CONSTRUIR; depois, em MELHORAR (até o nível 3).
## Mude nome, modelo, custos e efeito no Inspetor.

signal built(plot)
signal upgraded(plot)

const NIVEL_MAX := 3

@export var nome := "Casa"
@export var modelo: PackedScene
@export var altura := 6.0
@export var custo_madeira := 20
@export var custo_pedra := 0
@export var custo_comida := 0
## "vida" = +25 de vida máxima por nível · "madeira" = produz madeira · "torre" = atira nos inimigos · "descanso" = cura mais rápido · "armazem" = aldeões entregam ali (mais perto) e o estoque aparece empilhado
@export_enum("nenhum", "vida", "madeira", "torre", "descanso", "muralha", "armazem") var efeito := "nenhum"

var nivel := 0
var construido: bool:
	get: return nivel > 0
var _sign: Label3D
var _ring: MeshInstance3D
var _b: Node3D
var _base := Vector3.ONE

func _ready() -> void:
	_ring = MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 2.6
	m.bottom_radius = 2.6
	m.height = 0.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.25, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	_ring.mesh = m
	_ring.position.y = 0.04
	add_child(_ring)
	_sign = Label3D.new()
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 56
	_sign.outline_size = 14
	_sign.pixel_size = 0.012
	_sign.position.y = 2.4
	_sign.visibility_range_end = 32.0
	_sign.text = "%s\n%s" % [nome, texto(custo())]
	add_child(_sign)

## Custo para construir (nível 0) ou para o próximo nível.
func custo() -> Dictionary:
	var k := 1.0 if nivel == 0 else 1.5 * nivel
	return {"madeira": int(custo_madeira * k), "pedra": int(custo_pedra * k), "comida": int(custo_comida * k)}

static func texto(c: Dictionary) -> String:
	var p: Array = []
	for k in c:
		if c[k] > 0:
			p.append("%d %s" % [c[k], k])
	return ", ".join(p)

func construir(animar := true) -> void:
	if construido:
		return
	nivel = 1
	_ring.queue_free()
	if modelo == null:        # ex.: muralha, que o jogo monta em volta da aldeia
		_sign.font_size = 40
		_rotulo()
		built.emit(self)
		return
	_b = _modelo_novo()
	add_child(_b)
	if efeito != "torre":   # porta virada para o centro da aldeia
		_b.rotation.y = atan2(global_position.x, global_position.z)
	Construcoes.estilo_casa(_b)
	Fit.to_height(_b, altura)
	_base = _b.scale
	var box := Fit.bounds(_b)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(box.size.x * 0.85, maxf(box.size.y, 1.0), box.size.z * 0.85)
	cs.shape = sh
	cs.position = box.get_center()
	body.add_child(cs)
	_b.add_child(body)
	_sign.position.y = altura + 1.2
	_sign.font_size = 40
	_rotulo()
	if animar:
		_b.scale = _base * Vector3(1, 0.02, 1)
		create_tween().tween_property(_b, "scale", _base, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	built.emit(self)

## Modelo do prédio: torre e armazém são feitos por código e mudam com o nível.
func _modelo_novo() -> Node3D:
	if efeito == "torre":
		return Construcoes.torre_nivel(nivel)
	if efeito == "armazem":
		return Construcoes.armazem(nivel)
	return modelo.instantiate()

func _trocar_modelo() -> void:
	var giro := _b.rotation.y
	_b.queue_free()
	_b = _modelo_novo()
	add_child(_b)
	_b.rotation.y = giro
	Construcoes.estilo_casa(_b)
	Fit.to_height(_b, altura)
	_base = _b.scale
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	var box := Fit.bounds(_b)
	sh.size = Vector3(box.size.x * 0.85, maxf(box.size.y, 1.0), box.size.z * 0.85)
	cs.shape = sh
	cs.position = box.get_center()
	body.add_child(cs)
	_b.add_child(body)
	_b.scale = _base * Vector3(1, 0.05, 1)
	create_tween().tween_property(_b, "scale", _base, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func melhorar(animar := true) -> void:
	if not construido or nivel >= NIVEL_MAX:
		return
	nivel += 1
	if _b == null:
		_rotulo()
		upgraded.emit(self)
		return
	if efeito == "torre" or efeito == "armazem":   # evolui o modelo (torre: madeira -> braseiro -> pedra)
		_trocar_modelo()
		_rotulo()
		upgraded.emit(self)
		return
	var alvo := _base * (1.0 + 0.1 * (nivel - 1))
	_sign.position.y = altura * (1.0 + 0.1 * (nivel - 1)) + 1.2
	_rotulo()
	if animar:
		var tw := create_tween()
		tw.tween_property(_b, "scale", alvo * 1.12, 0.2)
		tw.tween_property(_b, "scale", alvo, 0.25)
	else:
		_b.scale = alvo
	upgraded.emit(self)

func definir_nivel(n: int) -> void:
	if n >= 1:
		construir(false)
	while nivel < mini(n, NIVEL_MAX):
		melhorar(false)

func _rotulo() -> void:
	_sign.text = "%s · Nv %d" % [nome, nivel]
