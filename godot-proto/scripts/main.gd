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
const KNIGHT := preload("res://models/Knight.glb")
const VILLAGER := preload("res://scripts/villager.gd")
const MINOTAURO := preload("res://models/Minotauro_Dark.glb")
const BOSS := preload("res://scripts/boss.gd")
const SAVE := "user://save_v4.json"
const VERSAO := "v6"

## Classes: vida base, dano por nível da arma, alcance. "area" = dano em área (mago).
const CLASSES := {
	"guerreiro": {"nome": "Guerreiro", "desc": "Corpo a corpo, forte e resistente", "hp": 140, "dano": [14, 20, 28], "alcance": 2.8, "longe": false, "area": 0.0, "cor": Color(1, 1, 1), "tiro": Color(1, 1, 1)},
	"arqueiro": {"nome": "Arqueiro", "desc": "Flechas de longe", "hp": 100, "dano": [10, 15, 21], "alcance": 15.0, "longe": true, "area": 0.0, "cor": Color(0.65, 1.0, 0.6), "tiro": Color(0.95, 0.85, 0.5)},
	"mago": {"nome": "Mago", "desc": "Orbes que explodem em área", "hp": 90, "dano": [9, 13, 18], "alcance": 13.0, "longe": true, "area": 3.2, "cor": Color(0.8, 0.65, 1.0), "tiro": Color(0.7, 0.4, 1.0)},
}
const ARMA_CUSTO := [{}, {"madeira": 40, "pedra": 30}, {"madeira": 90, "pedra": 70, "comida": 30}]
const OFICIOS := ["madeira", "pedra", "comida"]

@export var forest_radius := 70.0
@export var village_radius := 24.0
@export var tree_count := 140
@export var rock_count := 40
@export var bush_count := 50
@export var max_enemies := 4

var res := {"madeira": 0, "pedra": 0, "comida": 0}
var kills := 0
var quest := 0
var classe := ""
var arma := 1
var nodes: Array = []            # coletáveis: {node, tipo, hp, scene, h, dono}
var aldeoes: Array = []
var tiros: Array = []            # projéteis: {node, alvo, dano, area}
var _renascer: Array = []        # recursos que voltam a nascer: {t, scene, h, tipo, hp}
var _holder: Node3D
var _painel: Control
var boss: Node3D                 # Minotauro Dark, quando está vivo
var boss_derrotas := 0
var boss_em := 6                 # aparece quando o número de orcs derrotados chega aqui
var _boss_bar: ProgressBar
var _boss_lbl: Label
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
	{"t": "Escolha uma classe (botão CLASSE)", "p": func(): return 0 if classe == "" else 1, "n": 1, "r": {"comida": 20}},
	{"t": "Derrote 3 orcs", "p": func(): return kills, "n": 3, "r": {"madeira": 30, "pedra": 20}},
	{"t": "Contrate um aldeão (botão ALDEÕES)", "p": func(): return aldeoes.size(), "n": 1, "r": {"comida": 20}},
	{"t": "Construa a Serraria", "p": func(): return _built("madeira"), "n": 1, "r": {"comida": 20}},
	{"t": "Colha arbustos: junte 30 de comida", "p": func(): return res.comida, "n": 30, "r": {"pedra": 30}},
	{"t": "Melhore a Casa para o nível 2", "p": func(): return _lvl("vida"), "n": 2, "r": {"madeira": 40}},
	{"t": "Evolua sua arma para o nível 2", "p": func(): return arma, "n": 2, "r": {"pedra": 40}},
	{"t": "Construa a Torre de Vigia", "p": func(): return _built("torre"), "n": 1, "r": {"madeira": 40}},
	{"t": "Construa a Estalagem", "p": func(): return _built("descanso"), "n": 1, "r": {"comida": 40}},
	{"t": "Derrote o Minotauro Dark", "p": func(): return boss_derrotas, "n": 1, "r": {"madeira": 100, "pedra": 100, "comida": 100}},
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

func _action(acao: String, keys: Array) -> void:
	if InputMap.has_action(acao):
		return
	InputMap.add_action(acao)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(acao, e)

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
		p.upgraded.connect(_on_upgraded)
	_scatter_forest()
	player.attacked.connect(_on_player_attack)
	player.died.connect(_on_player_died)
	$HUD/Atacar.pressed.connect(player.attack)
	use_b.pressed.connect(_use)
	$HUD/Novo.pressed.connect(_new_game)
	$HUD/Novo.text = "Novo jogo (%s)" % VERSAO
	use_b.visible = false
	_hud_button("CLASSE", 70.0, _menu_classe)
	_hud_button("ALDEÕES", 124.0, _menu_aldeoes)
	_recalc()
	_boss_hud()
	if not _load():
		say("Ande com o direcional. Bata em árvores, rochas e arbustos para coletar.", 7.0)

func say(t: String, secs := 4.0) -> void:
	msg.text = t
	var mine := t
	get_tree().create_timer(secs).timeout.connect(func():
		if msg.text == mine:
			msg.text = "")

## Soma dos níveis das construções com esse efeito.
func _lvl(efeito: String) -> int:
	var n := 0
	for p in plots:
		if p.efeito == efeito:
			n += p.nivel
	return n

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
	_holder = holder
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
		nodes.append({"node": n, "tipo": tipo, "hp": hp, "scene": scene, "h": h, "maxhp": hp, "dono": null})

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
	_chefe()
	_buildings(delta)
	_tiros(delta)
	_renascimento(delta)
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
			res.madeira += 2 * _lvl("madeira")
	_tower_t -= delta
	if _tower_t <= 0.0:
		_tower_t = 1.5
		for p in plots:
			if p.construido and p.efeito == "torre":
				for e in enemies:
					if is_instance_valid(e) and e.global_position.distance_to(p.global_position) < 16.0:
						e.hurt(4 + 3 * p.nivel)
						break
	# cura na aldeia, longe de inimigos; a Estalagem dobra
	var safe := player.global_position.length() < village_radius
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_to(player.global_position) < 12.0:
			safe = false
	if safe and player.hp > 0 and player.hp < player.max_hp:
		_regen += delta * (2.0 + 2.0 * _lvl("descanso"))
		if _regen >= 1.0:
			player.hp = mini(player.max_hp, player.hp + int(_regen))
			_regen = 0.0

func _nearest_plot() -> void:
	_near = null
	var best := 999.0
	for p in plots:
		if p.nivel >= p.NIVEL_MAX:
			continue
		var d: float = p.global_position.distance_to(player.global_position)
		if d < (9.0 if p.construido else 4.5) and d < best:
			best = d
			_near = p
	use_b.visible = _near != null and _painel == null
	if _near:
		var c: Dictionary = _near.custo()
		use_b.text = ("MELHORAR %s\nNv %d: " % [_near.nome, _near.nivel + 1] if _near.construido else "CONSTRUIR %s\n" % _near.nome) + _near.texto(c)
		use_b.disabled = not _can_pay(c)

func _can_pay(c: Dictionary) -> bool:
	for k in c:
		if res[k] < c[k]:
			return false
	return true

func _pay(c: Dictionary) -> void:
	for k in c:
		res[k] -= c[k]

func _use() -> void:
	if _near == null:
		return
	var c: Dictionary = _near.custo()
	if not _can_pay(c):
		say("Faltam recursos: " + _near.texto(c))
		return
	_pay(c)
	if _near.construido:
		_near.melhorar()
	else:
		_near.construir()

func _on_upgraded(p) -> void:
	_recalc()
	say("%s agora é nível %d!" % [p.nome, p.nivel])
	_save()

## Recalcula vida máxima e dano do jogador (classe, arma e Casas).
func _recalc() -> void:
	var antes: int = player.max_hp
	var base := 100
	player.damage = 12
	if classe != "":
		base = CLASSES[classe].hp
		player.damage = CLASSES[classe].dano[arma - 1]
		Fit.tint(player.model, CLASSES[classe].cor)
	player.max_hp = base + 25 * _lvl("vida")
	if player.hp > 0:
		player.hp = clampi(player.hp + maxi(0, player.max_hp - antes), 1, player.max_hp)

func _on_built(p) -> void:
	_recalc()
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
	e.max_hp = 30 + mini(50, kills * 2)
	e.setup(ORC, player)
	e.position = Vector3(cos(a), 0, sin(a)) * (village_radius + 14.0)
	add_child(e)
	e.killed.connect(func(): kills += 1)
	enemies.append(e)

func _on_player_attack() -> void:
	var p := player.global_position
	# classes de longe: atira no inimigo mais próximo dentro do alcance
	if classe != "" and CLASSES[classe].longe:
		var alvo = null
		var best: float = CLASSES[classe].alcance
		for e in enemies:
			if is_instance_valid(e) and not e._dead:
				var d: float = e.global_position.distance_to(p)
				if d < best:
					best = d
					alvo = e
		if alvo != null:
			var to: Vector3 = alvo.global_position - p
			player.rotation.y = atan2(to.x, to.z)
			_atirar(alvo)
			return
	else:
		var hit := false
		for e in enemies:
			if is_instance_valid(e) and not e._dead and e.global_position.distance_to(p) < player.attack_range + float(e.get("raio") if e.get("raio") != null else 0.0):
				e.hurt(player.damage)
				hit = true
		if hit:
			return
	for t in nodes:
		var n = t.node
		if not is_instance_valid(n) or t.hp <= 0:
			continue
		if n.global_position.distance_to(p) < 2.8:
			res[t.tipo] += 2
			if golpear(t, true):
				res[t.tipo] += 4
			return

## Um golpe num recurso. Devolve true quando ele acaba (e some).
func golpear(t: Dictionary, _do_jogador: bool) -> bool:
	var n = t.node
	if not is_instance_valid(n) or t.hp <= 0:
		return true
	t.hp -= 1
	var tw := create_tween()
	tw.tween_property(n, "rotation:z", 0.08, 0.06)
	tw.tween_property(n, "rotation:z", 0.0, 0.12)
	if t.hp > 0:
		return false
	nodes.erase(t)
	_renascer.append({"t": 45.0, "scene": t.scene, "h": t.h, "tipo": t.tipo, "hp": t.maxhp})
	var tw2 := create_tween()
	tw2.tween_property(n, "scale", n.scale * 0.01, 0.4)
	tw2.tween_callback(n.queue_free)
	return true

func _renascimento(delta: float) -> void:
	for r in _renascer.duplicate():
		r.t -= delta
		if r.t <= 0.0:
			_renascer.erase(r)
			_place(_holder, r.scene, r.h, r.tipo, r.hp)

# ---------- chefe: Minotauro Dark ----------
func _boss_hud() -> void:
	_boss_lbl = Label.new()
	_boss_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_lbl.offset_top = 150
	_boss_lbl.add_theme_font_size_override("font_size", 22)
	_boss_lbl.add_theme_color_override("font_color", Color(1, 0.35, 0.3))
	_boss_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_boss_lbl.add_theme_constant_override("outline_size", 8)
	$HUD.add_child(_boss_lbl)
	_boss_bar = ProgressBar.new()
	_boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_bar.offset_top = 182
	_boss_bar.custom_minimum_size = Vector2(460, 22)
	_boss_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.12, 0.1)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	$HUD.add_child(_boss_bar)

func _chefe() -> void:
	var vivo: bool = boss != null and is_instance_valid(boss) and not boss._dead
	_boss_bar.visible = vivo
	_boss_lbl.visible = vivo
	if vivo:
		_boss_bar.max_value = boss.max_hp
		_boss_bar.value = boss.hp
		_boss_lbl.text = "Minotauro Dark · Nv %d · %d/%d" % [boss.nivel, boss.hp, boss.max_hp]
	elif (boss == null or not is_instance_valid(boss)) and kills >= boss_em:
		invocar_chefe()

func invocar_chefe() -> void:
	var b := CharacterBody3D.new()
	b.set_script(BOSS)
	b.setup(MINOTAURO, player, self, boss_derrotas + 1)
	var a := _rng.randf() * TAU
	b.position = Vector3(cos(a), 0, sin(a)) * (village_radius + 18.0)
	add_child(b)
	b.killed.connect(_chefe_morreu.bind(b))
	enemies.append(b)
	boss = b
	say("O MINOTAURO DARK se aproxima da aldeia!", 6.0)

func _chefe_morreu(b: Node) -> void:
	boss_derrotas += 1
	boss_em = kills + 12
	var premio: int = 80 * b.nivel
	for k in res:
		res[k] += premio
	say("Minotauro Dark derrotado! +%d de cada recurso. Ele voltará mais forte..." % premio, 7.0)
	_save()

# ---------- projéteis ----------
func _atirar(alvo: Node3D) -> void:
	var c: Dictionary = CLASSES[classe]
	var m := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.22 if c.area > 0.0 else 0.12
	sph.height = sph.radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c.tiro
	sph.material = mat
	m.mesh = sph
	add_child(m)
	m.global_position = player.global_position + Vector3(0, 1.3, 0)
	tiros.append({"node": m, "alvo": alvo, "dano": player.damage, "area": c.area})

func _tiros(delta: float) -> void:
	for t in tiros.duplicate():
		var m: MeshInstance3D = t.node
		if not is_instance_valid(t.alvo):
			tiros.erase(t)
			m.queue_free()
			continue
		var dest: Vector3 = t.alvo.global_position + Vector3(0, 1.1, 0)
		var to := dest - m.global_position
		var d := to.length()
		if d < 0.7:
			if t.area > 0.0:
				for e in enemies:
					if is_instance_valid(e) and e.global_position.distance_to(t.alvo.global_position) < t.area:
						e.hurt(t.dano)
			else:
				t.alvo.hurt(t.dano)
			tiros.erase(t)
			m.queue_free()
		else:
			m.global_position += to / d * minf(d, 24.0 * delta)

# ---------- aldeões ----------
func max_aldeoes() -> int:
	return 2 + 2 * _lvl("vida")

func custo_aldeao() -> Dictionary:
	return {"comida": 15 + 10 * aldeoes.size(), "madeira": 10 * aldeoes.size()}

func deposito() -> Vector3:
	return Vector3(0, 0, 2)

## Reserva para um aldeão o recurso livre mais próximo do tipo pedido.
func reservar(tipo: String, de: Vector3, quem: Node):
	var best = null
	var bd := 1e9
	for t in nodes:
		if t.tipo != tipo or t.hp <= 0 or not is_instance_valid(t.node):
			continue
		if t.dono != null and is_instance_valid(t.dono) and t.dono != quem:
			continue
		var d: float = t.node.global_position.distance_to(de)
		if d < bd:
			bd = d
			best = t
	if best != null:
		best.dono = quem
	return best

func contratar(papel: String, pagar := true) -> void:
	if pagar:
		if aldeoes.size() >= max_aldeoes():
			say("Limite de aldeões. Melhore a Casa para ter mais.")
			return
		var c := custo_aldeao()
		if not _can_pay(c):
			say("Faltam recursos: " + plots[0].texto(c))
			return
		_pay(c)
	var v := Node3D.new()
	v.set_script(VILLAGER)
	v.setup(KNIGHT, self, papel)
	v.position = deposito() + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3))
	add_child(v)
	aldeoes.append(v)
	if pagar:
		say("%s contratado!" % v.NOMES[papel])
		_save()

# ---------- classe e arma ----------
func escolher_classe(c: String) -> void:
	classe = c
	_recalc()
	player.hp = player.max_hp
	say("Agora você é %s!" % CLASSES[c].nome)
	_save()

func evoluir_arma() -> void:
	if arma >= 3:
		return
	var c: Dictionary = ARMA_CUSTO[arma]
	if not _can_pay(c):
		say("Faltam recursos: " + plots[0].texto(c))
		return
	_pay(c)
	arma += 1
	_recalc()
	say("Arma nível %d! Dano %d." % [arma, player.damage])
	_save()

# ---------- menus ----------
func _hud_button(texto: String, y: float, cb: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -190
	b.offset_right = -24
	b.offset_top = y
	b.offset_bottom = y + 46
	b.pressed.connect(cb)
	$HUD.add_child(b)

func _fechar() -> void:
	if _painel != null:
		_painel.queue_free()
		_painel = null

## Painel simples: título, linhas de texto e botões. rows = [{t, cb, off}]
func _abrir(titulo: String, texto: String, rows: Array) -> void:
	_fechar()
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pc.grow_vertical = Control.GROW_DIRECTION_BOTH
	pc.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.09, 0.05, 0.96)
	sb.border_color = Color(0.89, 0.75, 0.41)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	pc.add_theme_stylebox_override("panel", sb)
	var mg := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + side, 18)
	pc.add_child(mg)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	mg.add_child(vb)
	var tl := Label.new()
	tl.text = titulo
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_size_override("font_size", 30)
	vb.add_child(tl)
	if texto != "":
		var dl := Label.new()
		dl.text = texto
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_font_size_override("font_size", 20)
		vb.add_child(dl)
	for r in rows:
		var b := Button.new()
		b.text = r.t
		b.disabled = r.get("off", false)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 58)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(r.cb)
		vb.add_child(b)
	var x := Button.new()
	x.text = "Fechar"
	x.focus_mode = Control.FOCUS_NONE
	x.custom_minimum_size = Vector2(0, 50)
	x.add_theme_font_size_override("font_size", 20)
	x.pressed.connect(_fechar)
	vb.add_child(x)
	$HUD.add_child(pc)
	_painel = pc

func _menu_classe() -> void:
	var rows: Array = []
	if classe == "":
		for k in CLASSES:
			var c: Dictionary = CLASSES[k]
			rows.append({"t": "%s — %s (vida %d, dano %d)" % [c.nome, c.desc, c.hp, c.dano[0]], "cb": func(): escolher_classe(k); _menu_classe()})
		_abrir("Escolha sua classe", "A classe define sua vida, seu dano e se você luta de perto ou de longe.", rows)
		return
	var c: Dictionary = CLASSES[classe]
	var txt := "%s · Arma nível %d/3 · Dano %d · Vida máx. %d" % [c.nome, arma, player.damage, player.max_hp]
	if arma < 3:
		var cu: Dictionary = ARMA_CUSTO[arma]
		rows.append({"t": "Evoluir arma para nível %d (dano %d) — %s" % [arma + 1, c.dano[arma], plots[0].texto(cu)], "off": not _can_pay(cu), "cb": func(): evoluir_arma(); _menu_classe()})
	for k in CLASSES:
		if k != classe:
			rows.append({"t": "Trocar para %s" % CLASSES[k].nome, "cb": func(): escolher_classe(k); _menu_classe()})
	_abrir("Classe e arma", txt, rows)

func _menu_aldeoes() -> void:
	var conta := {"madeira": 0, "pedra": 0, "comida": 0}
	for v in aldeoes:
		conta[v.papel] += 1
	var c := custo_aldeao()
	var cheio := aldeoes.size() >= max_aldeoes()
	var txt := "Aldeões: %d/%d (cada nível de Casa libera mais 2)\nLenhadores %d · Pedreiros %d · Coletores %d\nPróximo custa: %s" % [aldeoes.size(), max_aldeoes(), conta.madeira, conta.pedra, conta.comida, plots[0].texto(c)]
	var rows: Array = []
	var nomes := {"madeira": "Lenhador (traz madeira)", "pedra": "Pedreiro (traz pedra)", "comida": "Coletor (traz comida)"}
	for k in OFICIOS:
		rows.append({"t": "Contratar " + nomes[k], "off": cheio or not _can_pay(c), "cb": func(): contratar(k); _menu_aldeoes()})
	_abrir("Aldeões", txt, rows)

func _on_player_died() -> void:
	say("Você caiu! Voltando para a aldeia...", 3.0)
	await get_tree().create_timer(3.0).timeout
	player.revive(Vector3(0, 0, 4))

# ---------- salvar / carregar ----------
func _save() -> void:
	var niveis := {}
	for p in plots:
		niveis[String(p.name)] = p.nivel
	var papeis: Array = []
	for v in aldeoes:
		papeis.append(v.papel)
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"res": res, "kills": kills, "quest": quest, "lotes": niveis, "classe": classe, "arma": arma, "aldeoes": papeis, "boss_derrotas": boss_derrotas, "boss_em": boss_em}))

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
	var c := String(d.get("classe", ""))
	classe = c if CLASSES.has(c) else ""
	arma = clampi(int(d.get("arma", 1)), 1, 3)
	boss_derrotas = int(d.get("boss_derrotas", 0))
	boss_em = int(d.get("boss_em", 6))
	var niveis: Dictionary = d.get("lotes", {})
	for p in plots:
		p.built.disconnect(_on_built)
		p.upgraded.disconnect(_on_upgraded)
		p.definir_nivel(int(niveis.get(String(p.name), 0)))
		p.built.connect(_on_built)
		p.upgraded.connect(_on_upgraded)
	for papel in d.get("aldeoes", []):
		if OFICIOS.has(papel):
			contratar(papel, false)
	_recalc()
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
