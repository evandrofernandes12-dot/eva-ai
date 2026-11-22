class_name ItemBox
extends Area3D
## Caixa de Item ("The Villa Crate"): ao tocar inicia o sorteio do item e reaparece depois.

const RESPAWN_TIME: float = 4.0

var _visual: Node3D
var _t: float = 0.0
var _active: bool = true


func _ready() -> void:
	collision_layer = 16 # triggers
	collision_mask = 4   # karts
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU
	_visual = Node3D.new()
	_visual.position.y = 1.4
	add_child(_visual)
	ProcMesh.rbox(_visual, Vector3(1.3, 1.3, 1.3), Vector3.ZERO, Color(0.62, 0.4, 0.18), Vector3.ZERO, 0.8)
	for sx: float in [-0.65, 0.65]:
		for sz: float in [-0.65, 0.65]:
			ProcMesh.rbox(_visual, Vector3(0.18, 1.4, 0.18), Vector3(sx, 0, sz), Color(0.35, 0.35, 0.4), Vector3.ZERO, 0.5, 0.6)
	for i in 4:
		var pivot := Node3D.new()
		pivot.rotation.y = float(i) * PI / 2.0
		_visual.add_child(pivot)
		var l := Label3D.new()
		l.text = "?"
		l.font_size = 140
		l.pixel_size = 0.0065
		l.modulate = Color(1.0, 0.85, 0.1)
		l.outline_modulate = Color(0.45, 0.2, 0.0)
		l.outline_size = 22
		l.position = Vector3(0, 0, -0.67)
		l.rotation.y = PI
		pivot.add_child(l)


func _process(delta: float) -> void:
	if _visual == null:
		return
	_t += delta * 2.0
	_visual.rotation.y += delta * 1.8
	_visual.position.y = 1.4 + sin(_t) * 0.15


func _on_body_entered(body: Node3D) -> void:
	var k: KartController = body as KartController
	if k == null or not _active:
		return
	if k.held_item != ItemDefs.Type.NONE or k.item_rolling:
		return
	k.begin_item_roll()
	if k.is_player:
		AudioManager.play_sfx("pickup")
	_active = false
	_visual.visible = false
	set_deferred("monitoring", false)
	get_tree().create_timer(RESPAWN_TIME).timeout.connect(_respawn)


func _respawn() -> void:
	_active = true
	if _visual != null:
		_visual.visible = true
	monitoring = true
