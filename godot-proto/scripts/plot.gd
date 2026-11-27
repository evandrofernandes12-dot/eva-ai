extends Node3D
## Lote de construção. Chegue perto e toque em CONSTRUIR; depois, em MELHORAR (até o nível 100, lendário).
## Mude nome, modelo, custos e efeito no Inspetor.

signal built(plot)
signal upgraded(plot)

const NIVEL_MAX := Niveis.MAX

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
	var c := Niveis.custo({"madeira": custo_madeira, "pedra": maxi(custo_pedra, custo_comida)}, nivel)
	c["comida"] = 0
	return c

## Categoria para o nome da faixa (torre e muro têm nomes próprios).
func categoria() -> String:
	return "torre" if efeito == "torre" else ("muro" if efeito == "muralha" else "")

## Modelo das torres e do armazém muda em 3 etapas (o resto da evolução é cor e enfeites).
static func etapa(n: int) -> int:
	return 1 if n < 20 else (2 if n < 40 else 3)

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
	_sign.position.y = altura + 2.2
	_sign.font_size = 40
	Niveis.visual(_b, nivel, _base)
	_rotulo()
	if animar:
		var alvo := _b.scale
		_b.scale = alvo * Vector3(1, 0.02, 1)
		create_tween().tween_property(_b, "scale", alvo, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	built.emit(self)

## Modelo do prédio: torre e armazém são feitos por código e mudam com o nível.
func _modelo_novo() -> Node3D:
	if efeito == "torre":
		return Construcoes.torre_nivel(etapa(nivel))
	if efeito == "armazem":
		return Construcoes.armazem(etapa(nivel))
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
	Niveis.visual(_b, nivel, _base)
	var alvo := _b.scale
	_b.scale = alvo * Vector3(1, 0.05, 1)
	create_tween().tween_property(_b, "scale", alvo, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func melhorar(animar := true) -> void:
	if not construido or nivel >= NIVEL_MAX:
		return
	nivel += 1
	if _b == null:
		_rotulo()
		upgraded.emit(self)
		return
	if (efeito == "torre" or efeito == "armazem") and etapa(nivel) != etapa(nivel - 1):   # troca o modelo (madeira -> braseiro -> pedra)
		_trocar_modelo()
		_rotulo()
		upgraded.emit(self)
		return
	var muda_faixa := Niveis.faixa(nivel) != Niveis.faixa(nivel - 1) or not animar
	if muda_faixa:
		Niveis.visual(_b, nivel, _base)
	else:
		_b.scale = _base * (1.0 + 0.0035 * nivel)
	var alvo := _b.scale
	_sign.position.y = altura * (1.0 + 0.0035 * nivel) + 2.2
	_rotulo()
	if animar:
		var tw := create_tween()
		tw.tween_property(_b, "scale", alvo * 1.08, 0.18)
		tw.tween_property(_b, "scale", alvo, 0.22)
	upgraded.emit(self)

func definir_nivel(n: int) -> void:
	if n < 1:
		return
	construir(false)
	nivel = mini(n, NIVEL_MAX)
	if _b != null:
		if efeito == "torre" or efeito == "armazem":
			var giro := _b.rotation.y
			_b.free()
			_b = null
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
		Niveis.visual(_b, nivel, _base)
		_sign.position.y = altura * (1.0 + 0.0035 * nivel) + 2.2
	_rotulo()

func _rotulo() -> void:
	_sign.text = "%s · Nv %d" % [Niveis.nome(nome, categoria(), nivel), nivel]
