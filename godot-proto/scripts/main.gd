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
const FENIX := preload("res://scripts/fenix.gd")
const SAVE := "user://save_v4.json"
const VERSAO := "v14"
const ZOOM_MIN := 0.2            # pinça: 0.2 = bem perto do personagem
const ZOOM_MAX := 1.5
const MURO_R := 40.0             # raio da muralha
const DIRS := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
const CAM_NOMES := ["3ª pessoa", "1ª pessoa", "Visão de águia"]

## Classes: vida base, dano por nível da arma, alcance. "area" = dano em área (mago).
const CLASSES := {
	"guerreiro": {"nome": "Guerreiro", "desc": "Corpo a corpo, forte e resistente", "hp": 140, "dano": [14, 20, 28], "alcance": 2.8, "longe": false, "area": 0.0, "cor": Color(1, 1, 1), "tiro": Color(1, 1, 1)},
	"arqueiro": {"nome": "Arqueiro", "desc": "Dispara flechas de longe", "hp": 100, "dano": [10, 15, 21], "alcance": 15.0, "longe": true, "area": 0.0, "cor": Color(0.65, 1.0, 0.6), "tiro": Color(0.95, 0.85, 0.5)},
	"lanceiro": {"nome": "Lanceiro", "desc": "Estocada longa que atravessa vários inimigos em linha", "hp": 120, "dano": [12, 18, 25], "alcance": 4.2, "avanco": 9.0, "longe": false, "area": 0.0, "cor": Color(1, 1, 1), "tiro": Color(1, 1, 1)},
	"mago": {"nome": "Mago", "desc": "Magia pelo cajado: explosão em área ou raio forte num alvo", "hp": 90, "dano": [9, 13, 18], "alcance": 13.0, "longe": true, "area": 3.2, "cor": Color(0.8, 0.65, 1.0), "tiro": Color(0.7, 0.4, 1.0)},
}
const ARMA_CUSTO := [{}, {"madeira": 40, "pedra": 30}, {"madeira": 90, "pedra": 70, "comida": 30}]
const OFICIOS := ["madeira", "pedra", "comida"]

@export var forest_radius := 95.0
@export var village_radius := 46.0
@export var tree_count := 190
@export var rock_count := 40
@export var bush_count := 50
@export var max_enemies := 4

var res := {"madeira": 0, "pedra": 0, "comida": 0}
var kills := 0
var quest := 0
var classe := ""
var heroi := ""                  # um dos 16 personagens (Heroi.lista)
var magia := "orbe"              # mago: "orbe" (área) ou "livro" (um alvo, mais forte)
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
var cam_modo := 0                # 0 = terceira pessoa, 1 = primeira, 2 = águia
var _cam_off := Vector3(0, 9, 10)
var _tapado_t := 0.0
var _arv_t := 0.0
var _fixos: Array = []           # construções prontas da aldeia: {pos, r, h}
var _muro: Node3D
var portoes: Array = []          # {dir, pos, hp, max, quebrado, folhas, corpo, rotulo}
var enemies: Array = []
var plots: Array = []
var _spawn_t := 12.0
var _save_t := 10.0
var _prod_t := 0.0
var _tower_t := 0.0
var _regen := 0.0
var _rng := RandomNumberGenerator.new()
var _near: Node3D
var _zoom := 1.0                 # pinça (dois dedos) aproxima/afasta a câmera
var _toques := {}
var _pinca_d := 0.0
var _mag_t := 0.0
var _def_b: Button
var _corre_b: Button
var _ent_b: Button
var _rei_b: Button
var _fade_r: ColorRect
var _rei_l: Label
var _dentro := ""                # nome do prédio em que o jogador está ("" = fora)
var _perto := ""                 # prédio da aldeia ao alcance da porta
var _saida := Vector3(0, 0, 8)
var _trans := false
var _cam_antes := 0
var fenix: Node3D                # fênix de fogo do mago
var _interiores := {}
var rei_q := 0                   # próxima missão do Rei
var rei_ativa := false
var rei_base := 0

## Missões do Rei: tipo "kills" (orcs derrotados), "chefe" (Minotauro) ou "entrega" (recurso entregue ao Rei).
const REI_QUESTS := [
	{"t": "Derrote 5 orcs que rondam a aldeia", "tipo": "kills", "n": 5, "r": {"madeira": 40, "comida": 30}},
	{"t": "Entregue 50 de madeira para a guarnição", "tipo": "entrega", "k": "madeira", "n": 50, "r": {"pedra": 60, "comida": 20}},
	{"t": "Derrote 12 orcs: o Rei quer a estrada limpa", "tipo": "kills", "n": 12, "r": {"madeira": 60, "pedra": 60}},
	{"t": "Entregue 60 de pedra para reforçar o castelo", "tipo": "entrega", "k": "pedra", "n": 60, "r": {"madeira": 80, "comida": 40}},
	{"t": "Derrote o Minotauro Dark mais uma vez", "tipo": "chefe", "n": 1, "r": {"madeira": 120, "pedra": 120, "comida": 120}},
	{"t": "Derrote 25 orcs: a aldeia precisa de paz", "tipo": "kills", "n": 25, "r": {"madeira": 100, "pedra": 100, "comida": 60}},
	{"t": "Entregue 80 de comida para o banquete real", "tipo": "entrega", "k": "comida", "n": 80, "r": {"madeira": 120, "pedra": 120}},
	{"t": "Derrote o Minotauro Dark duas vezes", "tipo": "chefe", "n": 2, "r": {"madeira": 250, "pedra": 250, "comida": 250}},
]

## Missões: texto, progresso atual, meta e recompensa.
var QUESTS := [
	{"t": "Corte árvores: junte 20 de madeira", "p": func(): return res.madeira, "n": 20, "r": {"comida": 10}},
	{"t": "Quebre rochas: junte 15 de pedra", "p": func(): return res.pedra, "n": 15, "r": {"madeira": 10}},
	{"t": "Construa a Casa (lote amarelo)", "p": func(): return _built("vida"), "n": 1, "r": {"pedra": 15}},
	{"t": "Escolha classe e personagem (botão CLASSE)", "p": func(): return 0 if heroi == "" else 1, "n": 1, "r": {"comida": 20}},
	{"t": "Derrote 3 orcs", "p": func(): return kills, "n": 3, "r": {"madeira": 30, "pedra": 20}},
	{"t": "Contrate um aldeão (botão ALDEÕES)", "p": func(): return aldeoes.size(), "n": 1, "r": {"comida": 20}},
	{"t": "Construa a Serraria", "p": func(): return _built("madeira"), "n": 1, "r": {"comida": 20}},
	{"t": "Colha arbustos: junte 30 de comida", "p": func(): return res.comida, "n": 30, "r": {"pedra": 30}},
	{"t": "Melhore a Casa para o nível 2", "p": func(): return _lvl("vida"), "n": 2, "r": {"madeira": 40}},
	{"t": "Evolua sua arma para o nível 2", "p": func(): return arma, "n": 2, "r": {"pedra": 40}},
	{"t": "Construa uma Torre de Vigia", "p": func(): return _built("torre"), "n": 1, "r": {"madeira": 40}},
	{"t": "Erga a Muralha (lote perto da saída sul)", "p": func(): return _built("muralha"), "n": 1, "r": {"pedra": 60}},
	{"t": "Construa as 4 Torres de Vigia", "p": func(): return _built("torre"), "n": 4, "r": {"madeira": 80, "pedra": 80}},
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
	_action("run", [KEY_SHIFT])
	_action("block", [KEY_Q])

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
			var bx := Fit.bounds(b)
			var centro: Vector3 = b.global_transform * bx.get_center()
			_fixos.append({"pos": centro, "r": maxf(bx.size.x, bx.size.z) * 0.5 * b.scale.x, "h": bx.size.y * b.scale.y, "nome": String(b.name)})
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
	_hud_button("CÂMERA", 178.0, _trocar_camera)
	_def_b = _botao_acao("DEFESA", -400.0, -230.0, true)
	_def_b.toggled.connect(func(v): player.defendendo = v)
	_corre_b = _botao_acao("CORRER", -400.0, -130.0, true)
	_corre_b.toggled.connect(func(v): player.correndo = v)
	_ent_b = _botao_acao("ENTRAR", -260.0, -440.0, false, 70.0)
	_ent_b.pressed.connect(_porta)
	_ent_b.visible = false
	_rei_b = _botao_acao("FALAR COM O REI", -260.0, -520.0, false, 70.0)
	_rei_b.pressed.connect(_menu_rei)
	_rei_b.visible = false
	_rei_l = Label.new()
	_rei_l.offset_left = 24.0
	_rei_l.offset_top = 96.0
	_rei_l.add_theme_font_size_override("font_size", 20)
	_rei_l.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	_rei_l.add_theme_color_override("font_outline_color", Color.BLACK)
	_rei_l.add_theme_constant_override("outline_size", 8)
	$HUD.add_child(_rei_l)
	_fade_r = ColorRect.new()
	_fade_r.color = Color(0, 0, 0, 0)
	_fade_r.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(_fade_r)
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
	_camera(delta)
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	_mag_t = maxf(0.0, _mag_t - delta)
	if _dentro == "":
		_spawn_t -= delta
		if _spawn_t <= 0.0 and enemies.size() < max_enemies:
			_spawn_t = 10.0
			_spawn_enemy()
		_chefe()
	_contexto()
	_check_rei()
	if _def_b.button_pressed != player.defendendo:
		_def_b.set_pressed_no_signal(player.defendendo)
	_portoes(delta)
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
					if is_instance_valid(e) and e.global_position.distance_to(p.global_position) < 20.0:
						e.hurt(4 + 3 * p.nivel)
						break
	# cura na aldeia, longe de inimigos; a Estalagem dobra
	var safe := player.global_position.length() < MURO_R
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
	if p.efeito == "muralha":
		_erguer_muralha(p.nivel)
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
		if classe == "mago" and magia == "livro":
			player.damage = int(player.damage * 1.35)
		player.attack_range = 2.6 if CLASSES[classe].longe else CLASSES[classe].alcance
		player.avanco = CLASSES[classe].get("avanco", 0.0)
	player.max_hp = base + 25 * _lvl("vida")
	if player.hp > 0:
		player.hp = clampi(player.hp + maxi(0, player.max_hp - antes), 1, player.max_hp)

func _on_built(p) -> void:
	_recalc()
	if p.efeito == "muralha":
		_erguer_muralha(p.nivel)
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
	e.collision_mask = 3
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
			if fenix != null and is_instance_valid(fenix):
				fenix.atacar(alvo)   # a fênix mergulha junto com o golpe do cajado
			_atirar(alvo)
			return
	elif classe == "lanceiro":
		if _estocada(p):
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

# ---------- câmera ----------
func _trocar_camera() -> void:
	if _dentro != "":
		say("Dentro dos prédios a câmera fica em 1ª pessoa.", 2.5)
		return
	cam_modo = (cam_modo + 1) % 3
	player.primeira_pessoa = cam_modo == 1
	player.model.visible = cam_modo != 1
	say("Câmera: " + CAM_NOMES[cam_modo], 2.5)

## Construções que podem tapar a visão: as fixas da aldeia e as dos lotes.
func _obstaculos() -> Array:
	var out: Array = _fixos.duplicate()
	for p in plots:
		if p.construido and p.modelo != null:
			var h: float = p.altura * (1.0 + 0.1 * (p.nivel - 1))
			out.append({"pos": p.global_position + Vector3(0, h * 0.5, 0), "r": h * 0.55, "h": h})
	return out

## Distância (no plano do chão) de um ponto ao segmento a-b, e a posição ao longo dele (0..1).
func _seg(p: Vector3, a: Vector3, b: Vector3) -> Vector2:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var t := clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return Vector2((ap - ab * t).length(), t)

func _tapado(de: Vector3, ate: Vector3) -> bool:
	var obs := _obstaculos()
	for k in 13:
		var pt := de.lerp(ate, 0.04 + 0.07 * k)
		for o in obs:
			if Vector2(pt.x - o.pos.x, pt.z - o.pos.z).length() < o.r * 1.15 and pt.y < o.h + 1.0:
				return true
	return false

func _camera(delta: float) -> void:
	var pp := player.global_position
	if cam_modo == 1:        # primeira pessoa: olhos do personagem
		var olhos := pp + Vector3(0, 1.65, 0)
		var frente := player.global_basis.z
		cam.global_position = olhos + frente * 0.2
		cam.look_at(olhos + frente * 10.0 - Vector3(0, 0.8, 0))
		return
	var alvo := Vector3(0, 9, 10) * _zoom
	if cam_modo == 2:        # visão de águia
		alvo = Vector3(0, 40, 8) * _zoom
	else:
		# se uma construção fica entre a câmera e o boneco, a câmera sobe e olha por cima do telhado
		if _dentro == "" and _tapado(pp + Vector3(0, 9, 10) * _zoom, pp + Vector3(0, 1.2, 0)):
			_tapado_t = 0.7
		_tapado_t -= delta
		if _tapado_t > 0.0:
			alvo = Vector3(0, 22, 2.5)
			# se a câmera já está presa dentro de um telhado, pula para cima na hora
			if _dentro == "" and _tapado(cam.global_position, pp + Vector3(0, 1.2, 0)) and _cam_off.y < 15.0:
				_cam_off = alvo
				cam.global_position = pp + _cam_off
	_cam_off = _cam_off.lerp(alvo, minf(1.0, 5.0 * delta))
	cam.global_position = cam.global_position.lerp(pp + _cam_off, minf(1.0, 8.0 * delta))
	cam.look_at(pp + Vector3(0, 1.2, 0))
	# árvores na frente do boneco ficam escondidas enquanto atrapalham
	_arv_t -= delta
	if _arv_t <= 0.0:
		_arv_t = 0.15
		var c := cam.global_position
		for t in nodes:
			if t.tipo == "madeira" and is_instance_valid(t.node):
				var s := _seg(t.node.global_position, c, pp)
				t.node.visible = not (cam_modo == 0 and s.x < 2.6 and s.y > 0.12 and s.y < 0.97)

# ---------- pinça (zoom) ----------
func _input(e: InputEvent) -> void:
	if e is InputEventMagnifyGesture:        # pinça reconhecida pelo sistema
		_mag_t = 0.5
		_zoom = clampf(_zoom / maxf(e.factor, 0.01), ZOOM_MIN, ZOOM_MAX)
	elif e is InputEventScreenTouch:         # pinça com dois dedos (fora do direcional)
		if e.pressed and not joy.get_global_rect().grow(30).has_point(e.position):
			_toques[e.index] = e.position
		else:
			_toques.erase(e.index)
		_pinca_d = 0.0
	elif e is InputEventScreenDrag and _toques.has(e.index):
		_toques[e.index] = e.position
		if _toques.size() == 2 and _mag_t <= 0.0:
			var k: Array = _toques.keys()
			var d: float = (_toques[k[0]] - _toques[k[1]]).length()
			if _pinca_d > 0.0 and d > 1.0:
				_zoom = clampf(_zoom * _pinca_d / d, ZOOM_MIN, ZOOM_MAX)
			_pinca_d = d
	elif e is InputEventMouseButton and e.pressed:   # roda do mouse (computador)
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom * 0.9, ZOOM_MIN, ZOOM_MAX)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom / 0.9, ZOOM_MIN, ZOOM_MAX)

# ---------- interiores e o Rei ----------
func _botao_acao(texto: String, esq: float, topo: float, alterna: bool, alt := 80.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = alterna
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.offset_left = esq
	b.offset_right = esq + (140.0 if alterna else 220.0)
	b.offset_top = topo
	b.offset_bottom = topo + alt
	$HUD.add_child(b)
	return b

## Mostra ENTRAR perto de uma construção com interior, SAIR lá dentro e FALAR COM O REI perto do trono.
func _contexto() -> void:
	if _dentro == "":
		_perto = ""
		var best := 1e9
		for f in _fixos:
			if Interior.SALAS.has(f.nome):
				var d: float = Vector2(player.global_position.x - f.pos.x, player.global_position.z - f.pos.z).length()
				if d < float(f.r) + 3.2 and d < best:
					best = d
					_perto = f.nome
		_ent_b.visible = _perto != "" and not _trans
		if _perto != "":
			_ent_b.text = "ENTRAR\n" + Interior.SALAS[_perto].nome
		_rei_b.visible = false
	else:
		_ent_b.visible = not _trans
		_ent_b.text = "SAIR"
		var rei = _interiores[_dentro].get_meta("rei", null)
		_rei_b.visible = rei != null and player.global_position.distance_to(rei.global_position) < 8.5

func _porta() -> void:
	if _trans:
		return
	if _dentro == "":
		if _perto != "":
			_entrar(_perto)
	else:
		_sair()

func _cam_fora() -> void:
	cam_modo = _cam_antes
	player.primeira_pessoa = cam_modo == 1
	player.model.visible = cam_modo != 1

func _fade(a: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_r, "color:a", a, 0.25)
	await tw.finished

func _entrar(id: String) -> void:
	_trans = true
	_fechar()
	await _fade(1.0)
	_saida = player.global_position
	if not _interiores.has(id):
		var sala := Interior.construir(id)
		sala.position = Vector3(600.0 + 60.0 * _interiores.size(), 0, 600.0)
		add_child(sala)
		_interiores[id] = sala
	_dentro = id
	var raiz: Node3D = _interiores[id]
	var fundo: float = Interior.SALAS[id].d
	player.global_position = raiz.global_position + Vector3(0, 0.1, fundo * 0.5 - 2.4)
	player.rotation.y = PI
	player.velocity = Vector3.ZERO
	for e in enemies:
		if is_instance_valid(e):
			e.process_mode = Node.PROCESS_MODE_DISABLED
	_cam_antes = cam_modo       # dentro dos prédios: 1ª pessoa, para enxergar a sala
	cam_modo = 1
	player.primeira_pessoa = true
	player.model.visible = false
	await _fade(0.0)
	_trans = false
	if id == "SalaoDoChefe":
		say("Salão do Rei: chegue perto do trono e toque em FALAR COM O REI.", 5.0)

func _sair() -> void:
	if _dentro == "" or _trans:
		return
	_trans = true
	_fechar()
	await _fade(1.0)
	_dentro = ""
	player.global_position = _saida
	player.velocity = Vector3.ZERO
	for e in enemies:
		if is_instance_valid(e):
			e.process_mode = Node.PROCESS_MODE_INHERIT
	_cam_fora()
	cam.global_position = player.global_position + Vector3(0, 9, 10) * _zoom
	await _fade(0.0)
	_trans = false

## Quanto da missão ativa do Rei já foi cumprido.
func _rei_prog() -> int:
	var q: Dictionary = REI_QUESTS[rei_q]
	match q.tipo:
		"kills":
			return kills - rei_base
		"chefe":
			return boss_derrotas - rei_base
	return mini(res[q.k], q.n)

func _check_rei() -> void:
	if rei_q >= REI_QUESTS.size():
		_rei_l.text = "Missões do Rei: todas cumpridas!"
	elif not rei_ativa:
		_rei_l.text = "Missões do Rei: fale com o Rei no Salão (nova missão disponível)"
	else:
		var q: Dictionary = REI_QUESTS[rei_q]
		var p := mini(_rei_prog(), q.n)
		_rei_l.text = "Rei %d/%d: %s (%d/%d)%s" % [rei_q + 1, REI_QUESTS.size(), q.t, p, q.n, "  ← volte ao Rei" if p >= q.n else ""]

func _menu_rei() -> void:
	var rows: Array = []
	if rei_q >= REI_QUESTS.size():
		_abrir("O Rei", "Você cumpriu todas as missões do reino. A aldeia é grata, herói!", rows)
		return
	var q: Dictionary = REI_QUESTS[rei_q]
	var premio: String = plots[0].texto(q.r)
	if not rei_ativa:
		rows.append({"t": "Aceitar a missão", "cb": func(): _aceitar_rei()})
		_abrir("O Rei", "%s\n\nRecompensa: %s" % [q.t, premio], rows)
		return
	var p := mini(_rei_prog(), q.n)
	var pronto: bool = p >= q.n
	rows.append({"t": "Entregar e receber a recompensa" if pronto else "Ainda não cumpriu (%d/%d)" % [p, q.n], "off": not pronto, "cb": func(): _entregar_rei()})
	_abrir("O Rei", "%s\n\nProgresso: %d/%d · Recompensa: %s" % [q.t, p, q.n, premio], rows)

func _aceitar_rei() -> void:
	var q: Dictionary = REI_QUESTS[rei_q]
	rei_ativa = true
	rei_base = kills if q.tipo == "kills" else boss_derrotas
	_fechar()
	say("Missão do Rei aceita!", 3.0)
	_save()

func _entregar_rei() -> void:
	var q: Dictionary = REI_QUESTS[rei_q]
	if _rei_prog() < q.n:
		return
	if q.tipo == "entrega":
		res[q.k] -= q.n
	for k in q.r:
		res[k] += q.r[k]
	rei_q += 1
	rei_ativa = false
	_fechar()
	say("O Rei agradece! +" + plots[0].texto(q.r), 5.0)
	_save()

# ---------- muralha ----------
## Com a muralha de pé, quem está de um lado e quer chegar ao outro precisa passar por um portão.
func destino(de: Vector3) -> Vector3:
	var alvo := player.global_position
	if _muro == null:
		return alvo
	var dentro := Vector2(de.x, de.z).length() < MURO_R
	var jog_dentro := Vector2(alvo.x, alvo.z).length() < MURO_R
	if dentro == jog_dentro:
		return alvo
	var best := Vector3.ZERO
	var bd := 1e9
	for g in DIRS:
		var gp: Vector3 = g * MURO_R
		var dd := de.distance_to(gp) + gp.distance_to(alvo)
		if dd < bd:
			bd = dd
			best = g
	# primeiro se alinha com o portão (do lado em que está), depois atravessa
	var alinhado := absf(angle_difference(atan2(de.z, de.x), atan2(best.z, best.x))) < 0.07
	if not alinhado:
		return best * (MURO_R + (6.0 if jog_dentro else -6.0))
	return best * (MURO_R * (0.86 if jog_dentro else 1.14))

## Portão fechado (e inteiro) perto de `pos`, ou null. Os inimigos param nele e batem até quebrar.
func portao_em(pos: Vector3):
	for g in portoes:
		if not g.quebrado and pos.distance_to(g.pos) < 4.2:
			return g
	return null

func bater_portao(g: Dictionary, dano: int) -> void:
	if g.quebrado:
		return
	g.hp -= dano
	if g.hp <= 0:
		g.hp = 0
		g.quebrado = true
		g.conserto = 40.0
		g.corpo.collision_layer = 0
		for f in g.folhas:
			f.visible = false
		say("Um portão foi derrubado! Ele será consertado em 40 s.", 4.0)
	_rotulo_portao(g)

func _rotulo_portao(g: Dictionary) -> void:
	g.rotulo.text = "Portão derrubado" if g.quebrado else "Portão %d/%d" % [g.hp, g.max]

## Abre as folhas para o jogador e os aldeões; conserta os portões derrubados.
func _portoes(delta: float) -> void:
	for g in portoes:
		if g.quebrado:
			g.conserto -= delta
			if g.conserto <= 0.0:
				g.quebrado = false
				g.hp = g.max
				g.corpo.collision_layer = 2
				for f in g.folhas:
					f.visible = true
				_rotulo_portao(g)
			continue
		var perto: bool = player.global_position.distance_to(g.pos) < 8.0
		var alvo := 1.35 if perto else 0.0
		g.folhas[0].rotation.y = lerpf(g.folhas[0].rotation.y, alvo, 5.0 * delta)
		g.folhas[1].rotation.y = lerpf(g.folhas[1].rotation.y, -alvo, 5.0 * delta)

func _criar_portao(d: Vector3, altura: float, nivel: int) -> void:
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.36, 0.22, 0.1)
	madeira.roughness = 0.9
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.2, 0.2, 0.22)
	ferro.metallic = 0.6
	var raiz := Node3D.new()
	_muro.add_child(raiz)
	raiz.position = d * MURO_R
	raiz.rotation.y = atan2(d.x, d.z)          # o eixo Z local aponta para fora da aldeia
	var vao := MURO_R * 0.30                    # largura da abertura deixada na paliçada
	var h := altura + 1.2
	# dois pilares e a viga de cima
	for lado in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.0, h + 0.8, 1.0)
		bm.material = madeira
		pil.mesh = bm
		pil.position = Vector3(lado * vao * 0.5, (h + 0.8) * 0.5, 0)
		raiz.add_child(pil)
	var viga := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(vao + 1.6, 0.8, 1.2)
	vm.material = madeira
	viga.mesh = vm
	viga.position = Vector3(0, h + 0.6, 0)
	raiz.add_child(viga)
	# duas folhas que giram nas dobradiças
	var folhas: Array = []
	for lado in [-1.0, 1.0]:
		var dob := Node3D.new()
		dob.position = Vector3(lado * (vao * 0.5 - 0.5), 0, 0)
		raiz.add_child(dob)
		var folha := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(vao * 0.5 - 0.55, h - 0.3, 0.3)
		fm.material = madeira
		folha.mesh = fm
		folha.position = Vector3(-lado * fm.size.x * 0.5, (h - 0.3) * 0.5 + 0.1, 0)
		dob.add_child(folha)
		for y in [0.8, h - 1.0]:
			var faixa := MeshInstance3D.new()
			var xm := BoxMesh.new()
			xm.size = Vector3(fm.size.x, 0.22, 0.36)
			xm.material = ferro
			faixa.mesh = xm
			faixa.position = Vector3(folha.position.x, y, 0)
			dob.add_child(faixa)
		folhas.append(dob)
	# barreira só para os inimigos (camada 2): o jogador passa, eles precisam derrubar
	var corpo := StaticBody3D.new()
	corpo.collision_layer = 2
	corpo.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(vao, h + 2.0, 0.9)
	cs.shape = sh
	cs.position.y = h * 0.5
	corpo.add_child(cs)
	raiz.add_child(corpo)
	var rot := Label3D.new()
	rot.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rot.font_size = 34
	rot.outline_size = 10
	rot.pixel_size = 0.012
	rot.position.y = h + 2.0
	rot.visibility_range_end = 40.0
	raiz.add_child(rot)
	var vida := 150 * nivel
	var g := {"dir": d, "pos": d * MURO_R, "hp": vida, "max": vida, "quebrado": false, "conserto": 0.0, "folhas": folhas, "corpo": corpo, "rotulo": rot}
	_rotulo_portao(g)
	portoes.append(g)

func _erguer_muralha(nivel: int) -> void:
	if _muro != null:
		_muro.queue_free()
	portoes.clear()
	_muro = StaticBody3D.new()
	_muro.name = "Muralha"
	add_child(_muro)
	var altura := 3.0 + 0.9 * (nivel - 1)
	var tora := CylinderMesh.new()
	tora.top_radius = 0.2
	tora.bottom_radius = 0.3
	tora.height = altura
	tora.radial_segments = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.27, 0.14) if nivel < 3 else Color(0.5, 0.5, 0.52)
	mat.roughness = 0.9
	tora.material = mat
	var angs: Array = []
	var n := int(TAU * MURO_R / 0.56)
	for i in n:
		var a := TAU * i / n
		# deixa 4 portões abertos (leste, oeste, norte, sul)
		var perto := absf(fposmod(a + PI * 0.25, PI * 0.5) - PI * 0.25)
		if perto > 0.15:
			angs.append(a)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tora
	mm.instance_count = angs.size()
	for i in angs.size():
		var a: float = angs[i]
		var hh := 1.0 + 0.08 * sin(i * 1.7)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, hh, 1)), Vector3(cos(a) * MURO_R, altura * 0.5 * hh, sin(a) * MURO_R)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	_muro.add_child(mmi)
	for d in DIRS:
		_criar_portao(d, altura, nivel)
	# colisão em trechos
	var passo := 0.1
	var a := 0.0
	while a < TAU:
		var perto := absf(fposmod(a + PI * 0.25, PI * 0.5) - PI * 0.25)
		if perto > 0.15 + passo * 0.5:
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.8, altura + 2.0, MURO_R * passo * 1.05)
			cs.shape = sh
			cs.position = Vector3(cos(a) * MURO_R, altura * 0.5, sin(a) * MURO_R)
			cs.rotation.y = -a
			_muro.add_child(cs)
		a += passo

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
	b.collision_mask = 3
	b.setup(MINOTAURO, player, self, boss_derrotas + 1)
	var a := _rng.randf() * TAU
	b.position = Vector3(cos(a), 0, sin(a)) * (village_radius + 18.0)
	add_child(b)
	b.killed.connect(_chefe_morreu.bind(b))
	b.largou_machado.connect(func(): say("O machado do Minotauro se despedaçou! Cuidado com os socos e a chifrada.", 5.0))
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

# ---------- projéteis e golpes ----------
## Ponta do cajado (de onde sai a magia) ou, se não houver, a altura do peito.
func _ponta() -> Vector3:
	var mk := player.model.find_child("Ponta", true, false) as Node3D
	if mk != null:
		return mk.global_position
	return player.global_position + Vector3(0, 1.4, 0) + player.global_basis.z * 0.6

## Flecha: haste, ponta de metal e penas. Aponta o -Z para o alvo (look_at).
func _flecha() -> Node3D:
	var r := Node3D.new()
	Interior.caixa(r, Vector3(0, 0, 0), Vector3(0.035, 0.035, 0.9), Color(0.55, 0.38, 0.2))
	var tip := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.06
	cm.height = 0.2
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.75, 0.78, 0.82)
	tm.metallic = 0.7
	cm.material = tm
	tip.mesh = cm
	tip.rotation_degrees.x = -90.0   # ápice (+Y) vira -Z
	tip.position = Vector3(0, 0, -0.52)
	r.add_child(tip)
	Interior.caixa(r, Vector3(0, 0, 0.38), Vector3(0.2, 0.012, 0.18), Color(0.95, 0.95, 0.9))
	Interior.caixa(r, Vector3(0, 0, 0.38), Vector3(0.012, 0.2, 0.18), Color(0.85, 0.2, 0.15))
	return r

func _atirar(alvo: Node3D) -> void:
	var c: Dictionary = CLASSES[classe]
	var m: Node3D
	var mago: bool = classe == "mago"
	var area: float = c.area if not (mago and magia == "livro") else 0.0
	if mago:    # bola de energia sai da ponta do cajado
		var mi := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.22 if area > 0.0 else 0.13
		sph.height = sph.radius * 2.0
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = c.tiro if area > 0.0 else Color(1.0, 0.85, 0.4)
		sph.material = mat
		mi.mesh = sph
		m = mi
	else:
		m = _flecha()
	await get_tree().create_timer(0.28).timeout   # espera o golpe do cajado / o disparo
	if not is_instance_valid(alvo) or not is_instance_valid(player):
		m.free()
		return
	add_child(m)
	m.global_position = _ponta() if mago else player.global_position + Vector3(0, 1.3, 0) + player.global_basis.z * 0.6
	if mago:
		flash(m.global_position, c.tiro, 0.7, 0.25)
	tiros.append({"node": m, "alvo": alvo, "dano": player.damage, "area": area, "cor": c.tiro, "flecha": not mago})

func _tiros(delta: float) -> void:
	for t in tiros.duplicate():
		var m: Node3D = t.node
		if not is_instance_valid(t.alvo) or not is_instance_valid(m):
			tiros.erase(t)
			if is_instance_valid(m):
				m.queue_free()
			continue
		var dest: Vector3 = t.alvo.global_position + Vector3(0, 1.1, 0)
		var to := dest - m.global_position
		var d := to.length()
		if d < 0.7:
			if t.area > 0.0:
				flash(dest, t.cor, t.area, 0.4)
				for e in enemies:
					if is_instance_valid(e) and e.global_position.distance_to(t.alvo.global_position) < t.area:
						e.hurt(t.dano)
			else:
				if not t.flecha:
					flash(dest, Color(1.0, 0.85, 0.4), 0.8, 0.25)
				t.alvo.hurt(t.dano)
			tiros.erase(t)
			m.queue_free()
		else:
			if t.flecha:
				m.look_at(dest)
			m.global_position += to / d * minf(d, (34.0 if t.flecha else 24.0) * delta)

## Faixa branca da lança, no instante da estocada.
func _rastro(fwd: Vector3, alc: float) -> void:
	await get_tree().create_timer(0.12).timeout
	var pf := player.global_position + Vector3(0, 1.1, 0)
	var rast := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.09, 0.09, alc)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.95, 0.75, 0.8)
	bm.material = mat
	rast.mesh = bm
	add_child(rast)
	rast.global_position = pf + fwd * (alc * 0.5)
	rast.look_at(pf + fwd * alc)
	var tw := rast.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tw.tween_callback(rast.queue_free)

## Clarão que cresce e some (impactos, explosões, brilho do cajado).
func flash(pos: Vector3, cor: Color, raio: float, dur: float) -> void:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(cor.r, cor.g, cor.b, 0.6)
	sph.material = mat
	mi.mesh = sph
	add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 0.2
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * raio * 2.0, dur)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, dur)
	tw.tween_callback(mi.queue_free)

## Estocada do lanceiro: mira no inimigo mais perto, avança e fura todos em linha à frente.
func _estocada(p: Vector3) -> bool:
	var alvo = null
	var best: float = player.attack_range + 2.0
	for e in enemies:
		if is_instance_valid(e) and not e._dead:
			var dd: float = e.global_position.distance_to(p)
			if dd < best:
				best = dd
				alvo = e
	if alvo != null:
		var to: Vector3 = alvo.global_position - p
		player.rotation.y = atan2(to.x, to.z)
	var f: Vector3 = player.global_basis.z
	var fwd := Vector3(f.x, 0, f.z).normalized()
	var alc: float = player.attack_range
	_rastro(fwd, alc)
	var hit := false
	for e in enemies:
		if not is_instance_valid(e) or e._dead:
			continue
		var raio: float = float(e.get("raio") if e.get("raio") != null else 0.0)
		var v: Vector3 = e.global_position - player.global_position
		v.y = 0
		var along := v.dot(fwd)
		var lado := (v - fwd * along).length()
		if along > -0.3 and along < alc + raio and lado < 0.9 + raio * 0.6:
			e.hurt(player.damage)
			flash(e.global_position + Vector3(0, 1.0, 0), Color(1.0, 0.9, 0.6), 0.6, 0.2)
			hit = true
	return hit

# ---------- aldeões ----------
func max_aldeoes() -> int:
	return 2 + 2 * _lvl("vida")

func custo_aldeao() -> Dictionary:
	return {"comida": 15 + 10 * aldeoes.size(), "madeira": 10 * aldeoes.size()}

func deposito() -> Vector3:
	return Vector3(0, 0, 4)

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
	say("Agora você é %s! Escolha o seu personagem." % CLASSES[c].nome)
	_save()

## Põe no jogador um dos 16 personagens.
func vestir(id: String, salvar := true) -> void:
	var info: Dictionary = Heroi.lista()[id]
	heroi = id
	classe = info.classe
	var m := Heroi.montar(id)
	player.trocar_modelo(m, Heroi.ANIMS[classe])
	player.model.visible = cam_modo != 1
	_recalc()
	_fenix_ajustar()
	if salvar:
		player.hp = player.max_hp
		_save()

## O mago ganha uma fênix de fogo que paira sobre ele; outras classes não têm.
func _fenix_ajustar() -> void:
	var tem: bool = fenix != null and is_instance_valid(fenix)
	if classe == "mago" and not tem:
		fenix = FENIX.new()
		fenix.dono = player
		fenix.jogo = self
		add_child(fenix)
		fenix.global_position = player.global_position + Vector3(0, 3.0, 0)
	elif classe != "mago" and tem:
		fenix.queue_free()
		fenix = null

func trocar_magia(qual: String) -> void:
	magia = qual
	_recalc()
	say("Cajado: %s!" % ("explosão em área" if qual == "orbe" else "raio forte"), 2.5)
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
	if classe == "" or heroi == "":
		_menu_escolha()
		return
	var c: Dictionary = CLASSES[classe]
	var rows: Array = []
	var txt := "%s · %s\nArma nível %d/3 · Dano %d · Vida máx. %d" % [c.nome, Heroi.lista()[heroi].nome, arma, player.damage, player.max_hp]
	if arma < 3:
		var cu: Dictionary = ARMA_CUSTO[arma]
		rows.append({"t": "Evoluir arma para nível %d (dano %d) — %s" % [arma + 1, c.dano[arma], plots[0].texto(cu)], "off": not _can_pay(cu), "cb": func(): evoluir_arma(); _menu_classe()})
	if classe == "mago":
		rows.append({"t": ("✔ " if magia == "orbe" else "") + "Cajado: explosão em área (acerta vários)", "cb": func(): trocar_magia("orbe"); _menu_classe()})
		rows.append({"t": ("✔ " if magia == "livro" else "") + "Cajado: raio mais forte num alvo só", "cb": func(): trocar_magia("livro"); _menu_classe()})
	rows.append({"t": "Trocar de personagem ou de classe", "cb": func(): _menu_escolha()})
	_abrir("Classe e arma", txt, rows)

## 1) escolhe a classe; 2) escolhe entre os 4 personagens dela (2 masculinos e 2 femininos).
func _menu_escolha(cl := "") -> void:
	var rows: Array = []
	if cl == "":
		for k in CLASSES:
			var c: Dictionary = CLASSES[k]
			rows.append({"t": "%s — %s (vida %d, dano %d)" % [c.nome, c.desc, c.hp, c.dano[0]], "cb": func(): _menu_escolha(k)})
		_abrir("Escolha sua classe", "A classe define sua vida, seu dano e se você luta de perto ou de longe.", rows)
		return
	var lista := Heroi.lista()
	for sexo in ["m", "f"]:
		for id in lista:
			var h: Dictionary = lista[id]
			if h.classe == cl and h.sexo == sexo:
				rows.append({"t": "%s — %s" % ["Masculino" if sexo == "m" else "Feminino", h.nome], "cb": func(): vestir(id); _fechar(); say("Personagem escolhido!", 2.5)})
	rows.append({"t": "← Voltar para as classes", "cb": func(): _menu_escolha()})
	_abrir(CLASSES[cl].nome, "Escolha o seu personagem.", rows)

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
	if _dentro != "":
		_dentro = ""
		_cam_fora()
		for e in enemies:
			if is_instance_valid(e):
				e.process_mode = Node.PROCESS_MODE_INHERIT
	player.revive(Vector3(0, 0, 8))

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
		f.store_string(JSON.stringify({"res": res, "kills": kills, "quest": quest, "lotes": niveis, "classe": classe, "heroi": heroi, "magia": magia, "arma": arma, "aldeoes": papeis, "boss_derrotas": boss_derrotas, "boss_em": boss_em, "rei_q": rei_q, "rei_ativa": rei_ativa, "rei_base": rei_base}))

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
	magia = String(d.get("magia", "orbe"))
	var hid := String(d.get("heroi", ""))
	if Heroi.lista().has(hid):
		vestir(hid, false)
	arma = clampi(int(d.get("arma", 1)), 1, 3)
	boss_derrotas = int(d.get("boss_derrotas", 0))
	boss_em = int(d.get("boss_em", 6))
	rei_q = int(d.get("rei_q", 0))
	rei_ativa = bool(d.get("rei_ativa", false))
	rei_base = int(d.get("rei_base", 0))
	var niveis: Dictionary = d.get("lotes", {})
	for p in plots:
		p.built.disconnect(_on_built)
		p.upgraded.disconnect(_on_upgraded)
		p.definir_nivel(int(niveis.get(String(p.name), 0)))
		if p.efeito == "muralha" and p.nivel > 0:
			_erguer_muralha(p.nivel)
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
