extends Node3D
## Protótipo: aldeia + floresta + jogador + inimigos + construção + missões + save.
## Casas prontas ficam no nó "Aldeia"; os lotes para construir ficam em "Lotes".

const TREES := [
	preload("res://models/PineTree_1.glb"),
	preload("res://models/CommonTree_1.glb"),
	preload("res://models/BirchTree_1.glb"),
]
const ROCK := preload("res://models/Resource_Rock_1.glb")
const BUSH := preload("res://models/Bush_1.glb")
const FLOWERS := preload("res://models/Flowers.glb")
const ORC := preload("res://models/Orc.gltf")
const SAVE := "user://save.json"

@export var forest_radius := 70.0
@export var village_radius := 24.0
@export var tree_count := 140
@export var rock_count := 40
@export var bush_count := 50
@export var max_enemies := 4

var res := {"madeira": 0, "pedra": 0, "comida": 0}
var kills := 0
var quest := 0
var nodes: Array = []            # coletáveis: {node, tipo, hp}
var enemies: Array = []
var plots: Array = []
var _spawn_t := 12.0
var _save_t := 10.0
var _prod_t := 0.0
var _tower_t := 0.0
var _regen := 0.0
var _rng := RandomNumberGenerator.new()
var _near: Node3D

## Missões: texto, progresso atual, meta e recompensa.
var QUESTS := [
	{"t": "Corte árvores: junte 20 de madeira", "p": func(): return res.madeira, "n": 20, "r": {"comida": 10}},
	{"t": "Quebre rochas: junte 15 de pedra", "p": func(): return res.pedra, "n": 15, "r": {"madeira": 10}},
	{"t": "Construa a Casa (lote amarelo)", "p": func(): return _built("vida"), "n": 1, "r": {"pedra": 15}},
	{"t": "Derrote 3 orcs", "p": func(): return kills, "n": 3, "r": {"madeira": 30, "pedra": 20}},
	{"t": "Construa a Serraria", "p": func(): return _built("madeira"), "n": 1, "r": {"comida": 20}},
	{"t": "Colha arbustos: junte 30 de comida", "p": func(): return res.comida, "n": 30, "r": {"pedra": 30}},
	{"t": "Construa a Torre de Vigia", "p": func(): return _built("torre"), "n": 1, "r": {"madeira": 40}},
	{"t": "Construa a Estalagem", "p": func(): return _built("descanso"), "n": 1, "r": {}},
]

@onready var player: CharacterBody3D = $Jogador
@onready var cam: Camera3D = $Camera
@onready var joy: Control = $HUD/Direcional
@onready var info: Label = $HUD/Info
@onready var quest_l: Label = $HUD/Missao
@onready var msg: Label = $HUD/Mensagem
@onready var use_b: Button = $HUD/Usar

func _enter_tree() -> void:
	_action("move_left", [KEY_A, KEY_LEFT])
	_action("move_right", [KEY_D, KEY_RIGHT])
	_action("move_up", [KEY_W, KEY_UP])
	_action("move_down", [KEY_S, KEY_DOWN])
	_action("attack", [KEY_SPACE])
	_action("use", [KEY_E])

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
	for p in $Lotes.get_children():
		plots.append(p)
		p.built.connect(_on_built)
	_scatter_forest()
	player.attacked.connect(_on_player_attack)
	player.died.connect(_on_player_died)
	$HUD/Atacar.pressed.connect(player.attack)
	use_b.pressed.connect(_use)
	$HUD/Novo.pressed.connect(_new_game)
	use_b.visible = false
	if not _load():
		say("Ande com o direcional. Bata em árvores, rochas e arbustos para coletar.", 7.0)

func say(t: String, secs := 4.0) -> void:
	msg.text = t
	var mine := t
	get_tree().create_timer(secs).timeout.connect(func():
		if msg.text == mine:
			msg.text = "")

func _built(efeito: String) -> int:
	var n := 0
	for p in plots:
		if p.construido and p.efeito == efeito:
			n += 1
	return n

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

func _ring_pos() -> Vector3:
	var a := _rng.randf() * TAU
	var r := sqrt(_rng.randf_range(pow(village_radius / forest_radius, 2.0), 1.0)) * forest_radius
	return Vector3(cos(a) * r, 0, sin(a) * r)

func _scatter_forest() -> void:
	var holder := Node3D.new()
	holder.name = "Floresta"
	add_child(holder)
	for i in tree_count:
		_place(holder, TREES[_rng.randi() % TREES.size()], _rng.randf_range(6.0, 9.5), "madeira", 3)
	for i in rock_count:
		_place(holder, ROCK, _rng.randf_range(1.2, 1.9), "pedra", 3)
	for i in bush_count:
		_place(holder, BUSH, _rng.randf_range(0.9, 1.3), "comida", 2)
	for i in 60:
		_place(holder, FLOWERS, _rng.randf_range(0.5, 0.8), "", 0)

func _place(holder: Node3D, scene: PackedScene, h: float, tipo: String, hp: int) -> void:
	var n: Node3D = scene.instantiate()
	holder.add_child(n)
	n.position = _ring_pos()
	n.rotation.y = _rng.randf() * TAU
	Fit.to_height(n, h)
	if tipo != "":
		nodes.append({"node": n, "tipo": tipo, "hp": hp})

func _process(delta: float) -> void:
	player.joy = joy.value
	# câmera em terceira pessoa, seguindo o jogador
	var want := player.global_position + Vector3(0, 9.0, 10.0)
	cam.global_position = cam.global_position.lerp(want, minf(1.0, 6.0 * delta))
	cam.look_at(player.global_position + Vector3(0, 1.2, 0))
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	_spawn_t -= delta
	if _spawn_t <= 0.0 and enemies.size() < max_enemies:
		_spawn_t = 10.0
		_spawn_enemy()
	_buildings(delta)
	_nearest_plot()
	if Input.is_action_just_pressed("use"):
		_use()
	_check_quest()
	info.text = "Vida %d/%d   Madeira %d   Pedra %d   Comida %d   Orcs %d" % [player.hp, player.max_hp, res.madeira, res.pedra, res.comida, kills]
	_save_t -= delta
	if _save_t <= 0.0:
		_save_t = 10.0
		_save()

## Efeitos das construções: produção, torre e descanso.
func _buildings(delta: float) -> void:
	if _built("madeira") > 0:
		_prod_t += delta
		if _prod_t >= 6.0:
			_prod_t = 0.0
			res.madeira += 2 * _built("madeira")
	_tower_t -= delta
	if _tower_t <= 0.0:
		_tower_t = 1.5
		for p in plots:
			if p.construido and p.efeito == "torre":
				for e in enemies:
					if e.global_position.distance_to(p.global_position) < 16.0:
						e.hurt(6)
						break
	# cura na aldeia, longe de inimigos; a Estalagem dobra
	var safe := player.global_position.length() < village_radius
	for e in enemies:
		if e.global_position.distance_to(player.global_position) < 12.0:
			safe = false
	if safe and player.hp > 0 and player.hp < player.max_hp:
		_regen += delta * (4.0 if _built("descanso") > 0 else 2.0)
		if _regen >= 1.0:
			player.hp = mini(player.max_hp, player.hp + int(_regen))
			_regen = 0.0

func _nearest_plot() -> void:
	_near = null
	for p in plots:
		if not p.construido and p.global_position.distance_to(player.global_position) < 4.5:
			_near = p
	use_b.visible = _near != null
	if _near:
		use_b.text = "CONSTRUIR\n" + _near.nome
		use_b.disabled = not _can_pay(_near.custo())

func _can_pay(c: Dictionary) -> bool:
	for k in c:
		if res[k] < c[k]:
			return false
	return true

func _use() -> void:
	if _near == null:
		return
	var c: Dictionary = _near.custo()
	if not _can_pay(c):
		say("Faltam recursos: " + _near.custo_texto())
		return
	for k in c:
		res[k] -= c[k]
	_near.construir()

func _on_built(p) -> void:
	if p.efeito == "vida":
		player.max_hp += 25
		player.hp += 25
	# tira o jogador de dentro da construção nova
	if player.global_position.distance_to(p.global_position) < 6.0:
		player.global_position = p.global_position + Vector3(0, 0, 7.0)
	say("%s construída!" % p.nome)
	_save()

func _check_quest() -> void:
	if quest >= QUESTS.size():
		quest_l.text = "Todas as missões concluídas!"
		return
	var q: Dictionary = QUESTS[quest]
	var p: int = q.p.call()
	quest_l.text = "Missão %d/%d: %s  (%d/%d)" % [quest + 1, QUESTS.size(), q.t, mini(p, q.n), q.n]
	if p >= q.n:
		quest += 1
		var parts: Array = []
		for k in q.r:
			res[k] += q.r[k]
			parts.append("+%d %s" % [q.r[k], k])
		say("Missão concluída! " + "  ".join(parts), 5.0)
		_save()

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
		if e.global_position.distance_to(p) < player.attack_range:
			e.hurt(player.damage)
			hit = true
	if hit:
		return
	for t in nodes:
		var n: Node3D = t.node
		if t.hp > 0 and is_instance_valid(n) and n.global_position.distance_to(p) < 2.8:
			t.hp -= 1
			res[t.tipo] += 2
			var tw := create_tween()
			tw.tween_property(n, "rotation:z", 0.08, 0.06)
			tw.tween_property(n, "rotation:z", 0.0, 0.12)
			if t.hp <= 0:
				res[t.tipo] += 4
				var tw2 := create_tween()
				tw2.tween_property(n, "scale", n.scale * 0.01, 0.4)
				tw2.tween_callback(n.queue_free)
			return

func _on_player_died() -> void:
	say("Você caiu! Voltando para a aldeia...", 3.0)
	await get_tree().create_timer(3.0).timeout
	player.revive(Vector3(0, 0, 4))

# ---------- salvar / carregar ----------
func _save() -> void:
	var built: Array = []
	for p in plots:
		if p.construido:
			built.append(String(p.name))
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"res": res, "kills": kills, "quest": quest, "built": built}))

func _load() -> bool:
	if not FileAccess.file_exists(SAVE):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	for k in res:
		res[k] = int(d.get("res", {}).get(k, 0))
	kills = int(d.get("kills", 0))
	quest = int(d.get("quest", 0))
	for p in plots:
		if d.get("built", []).has(String(p.name)):
			p.built.disconnect(_on_built)
			p.construir(false)
			if p.efeito == "vida":
				player.max_hp += 25
	player.hp = player.max_hp
	say("Jogo carregado.", 3.0)
	return true

func _new_game() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_node_ready():
			_save()
