extends Node3D
## Lote de construção. Chegue perto e toque em CONSTRUIR.
## Mude nome, modelo, custos e efeito no Inspetor.

signal built(plot)

@export var nome := "Casa"
@export var modelo: PackedScene
@export var altura := 6.0
@export var custo_madeira := 20
@export var custo_pedra := 0
@export var custo_comida := 0
## "vida" = +25 de vida máxima · "madeira" = produz madeira · "torre" = atira nos inimigos · "descanso" = cura mais rápido
@export_enum("nenhum", "vida", "madeira", "torre", "descanso") var efeito := "nenhum"

var construido := false
var _sign: Label3D
var _ring: MeshInstance3D

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
	_sign.text = "%s\n%s" % [nome, custo_texto()]
	add_child(_sign)

func custo() -> Dictionary:
	return {"madeira": custo_madeira, "pedra": custo_pedra, "comida": custo_comida}

func custo_texto() -> String:
	var p: Array = []
	if custo_madeira > 0: p.append("%d madeira" % custo_madeira)
	if custo_pedra > 0: p.append("%d pedra" % custo_pedra)
	if custo_comida > 0: p.append("%d comida" % custo_comida)
	return ", ".join(p)

func construir(animar := true) -> void:
	if construido or modelo == null:
		return
	construido = true
	_sign.queue_free()
	_ring.queue_free()
	var b: Node3D = modelo.instantiate()
	add_child(b)
	Fit.to_height(b, altura)
	var box := Fit.bounds(b)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(box.size.x * 0.85, maxf(box.size.y, 1.0), box.size.z * 0.85)
	cs.shape = sh
	cs.position = box.get_center()
	body.add_child(cs)
	b.add_child(body)
	if animar:
		var alvo := b.scale
		b.scale = alvo * Vector3(1, 0.02, 1)
		create_tween().tween_property(b, "scale", alvo, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	built.emit(self)
