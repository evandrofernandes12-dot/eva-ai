extends Node3D
## Protótipo: aldeia + floresta + um jogador + inimigos.
## As casas ficam no nó "Aldeia" da cena: arraste-as no editor à vontade.

const TREES := [
	preload("res://models/PineTree_1.glb"),
	preload("res://models/CommonTree_1.glb"),
	preload("res://models/BirchTree_1.glb"),
]
const DECOR := [
	preload("res://models/Bush_1.glb"),
	preload("res://models/Resource_Rock_1.glb"),
	preload("res://models/Flowers.glb"),
]
const ORC := preload("res://models/Orc.gltf")

@export var forest_radius := 70.0
@export var village_radius := 22.0
@export var tree_count := 140
@export var max_enemies := 4

var wood := 0
var kills := 0
var trees: Array = []            # {node, hp}
var enemies: Array = []
var _spawn_t := 6.0
var _rng := RandomNumberGenerator.new()

@onready var player: CharacterBody3D = $Jogador
@onready var cam: Camera3D = $Camera
@onready var joy: Control = $HUD/Direcional
@onready var info: Label = $HUD/Info
@onready var msg: Label = $HUD/Mensagem

func _enter_tree() -> void:
	_action("move_left", [KEY_A, KEY_LEFT])
	_action("move_right", [KEY_D, KEY_RIGHT])
	_action("move_up", [KEY_W, KEY_UP])
	_action("move_down", [KEY_S, KEY_DOWN])
	_action("attack", [KEY_SPACE])

func _action(name: String, keys: Array) -> void:
	if InputMap.has_action(name):
		return
	InputMap.add_action(name)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(name, e)

func _ready() -> void:
	_rng.seed = 7
	for b in $Aldeia.get_children():
		if b is Node3D:
			# "altura" (metadado do nó) define o tamanho da construção em metros
			if b.has_meta("altura"):
				Fit.to_height(b, float(b.get_meta("altura")))
			_add_collision(b)
	_scatter_forest()
	player.attacked.connect(_on_player_attack)
	player.died.connect(_on_player_died)
	$HUD/Atacar.pressed.connect(player.attack)
	msg.text = "Ande com o direcional. Ataque árvores para pegar madeira e defenda a aldeia!"
	get_tree().create_timer(6.0).timeout.connect(func(): msg.text = "")

func _add_collision(b: Node3D) -> void:
	var box := Fit.bounds(b)
	if box.size.length() < 0.2:
		return
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(box.size.x * 0.85, maxf(box.size.y, 1.0), box.size.z * 0.85)
	cs.shape = sh
	cs.position = box.get_center()
	body.add_child(cs)
	b.add_child(body)

func _scatter_forest() -> void:
	var holder := Node3D.new()
	holder.name = "Floresta"
	add_child(holder)
	for i in tree_count:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf_range(pow(village_radius / forest_radius, 2.0), 1.0)) * forest_radius
		var t: Node3D = TREES[_rng.randi() % TREES.size()].instantiate()
		holder.add_child(t)
		t.position = Vector3(cos(a) * r, 0, sin(a) * r)
		t.rotation.y = _rng.randf() * TAU
		Fit.to_height(t, _rng.randf_range(6.0, 9.5))
		trees.append({"node": t, "hp": 3})
	for i in tree_count:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf_range(pow(village_radius / forest_radius, 2.0), 1.0)) * forest_radius
		var d: Node3D = DECOR[_rng.randi() % DECOR.size()].instantiate()
		holder.add_child(d)
		d.position = Vector3(cos(a) * r, 0, sin(a) * r)
		d.rotation.y = _rng.randf() * TAU
		Fit.to_height(d, _rng.randf_range(0.6, 1.3))

func _process(delta: float) -> void:
	player.joy = joy.value
	# câmera em terceira pessoa, seguindo o jogador
	var want := player.global_position + Vector3(0, 9.0, 10.0)
	cam.global_position = cam.global_position.lerp(want, minf(1.0, 6.0 * delta))
	cam.look_at(player.global_position + Vector3(0, 1.2, 0))
	_spawn_t -= delta
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	if _spawn_t <= 0.0 and enemies.size() < max_enemies:
		_spawn_t = 9.0
		_spawn_enemy()
	info.text = "Vida %d/%d    Madeira %d    Inimigos %d" % [player.hp, player.max_hp, wood, kills]

func _spawn_enemy() -> void:
	var e := CharacterBody3D.new()
	e.set_script(preload("res://scripts/enemy.gd"))
	var a := _rng.randf() * TAU
	e.setup(ORC, player)
	e.position = Vector3(cos(a), 0, sin(a)) * (village_radius + 14.0)
	add_child(e)
	e.killed.connect(func(): kills += 1)
	enemies.append(e)

func _on_player_attack() -> void:
	var p := player.global_position
	var hit := false
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_to(p) < player.attack_range:
			e.hurt(player.damage)
			hit = true
	if hit:
		return
	for t in trees:
		var n: Node3D = t.node
		if is_instance_valid(n) and n.global_position.distance_to(p) < 2.6:
			t.hp -= 1
			wood += 2
			var tw := create_tween()
			tw.tween_property(n, "rotation:z", 0.08, 0.06)
			tw.tween_property(n, "rotation:z", 0.0, 0.12)
			if t.hp <= 0:
				wood += 4
				var tw2 := create_tween()
				tw2.tween_property(n, "scale", n.scale * 0.01, 0.4)
				tw2.tween_callback(n.queue_free)
			return

func _on_player_died() -> void:
	msg.text = "Você caiu! Voltando para a aldeia..."
	await get_tree().create_timer(3.0).timeout
	player.revive(Vector3(0, 0, 4))
	msg.text = ""
