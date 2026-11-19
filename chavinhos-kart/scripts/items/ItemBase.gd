class_name ItemBase
extends Area3D
## Base de todos os itens lançáveis/colocáveis. Camadas: item = 4 (valor 8), detecta karts = 3 (valor 4).

var owner_kart: KartController
var lifetime: float = 15.0
var arm_time: float = 0.5 # o dono é imune durante este tempo
var armed: bool = false
var _age: float = 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_build_visual()


## Chamado logo depois de instanciar o item. Sobrescreva e chame super.activate(kart).
func activate(kart: KartController) -> void:
	owner_kart = kart


func _build_visual() -> void:
	pass


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= arm_time:
		armed = true
	if _age >= lifetime:
		queue_free()
		return
	_tick(delta)


func _tick(_delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	var k: KartController = body as KartController
	if k == null:
		return
	if k == owner_kart and not armed:
		return
	_hit_kart(k)


func _hit_kart(_kart: KartController) -> void:
	pass
