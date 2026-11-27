extends Node3D
## Protótipo: aldeia + floresta + jogador + inimigos + construção + missões + save.
## Casas prontas ficam no nó "Aldeia"; os lotes para construir ficam em "Lotes".

## Natureza: Quaternius Stylized Nature MegaKit e KayKit Forest Nature Pack (CC0), em assets/nature/.
const QN := "res://assets/nature/quaternius/"
const KK := "res://assets/nature/kaykit/"
const TREES := [QN + "CommonTree_1.gltf", QN + "CommonTree_2.gltf", QN + "CommonTree_3.gltf", QN + "CommonTree_4.gltf", QN + "CommonTree_5.gltf",
	QN + "Pine_1.gltf", QN + "Pine_2.gltf", QN + "Pine_3.gltf", QN + "Pine_4.gltf", QN + "Pine_5.gltf",
	QN + "TwistedTree_1.gltf", QN + "TwistedTree_2.gltf", QN + "TwistedTree_3.gltf"]
const ROCKS := [QN + "Rock_Medium_1.gltf", QN + "Rock_Medium_2.gltf", QN + "Rock_Medium_3.gltf"]   # as da KayKit (brancas/quadradas) destoavam
const BUSHES := [QN + "Bush_Common.gltf", QN + "Bush_Common_Flowers.gltf"]
## Enfeites sem coleta (sem colisão): [arquivo, altura mín., altura máx., quantidade]
const ENFEITES := [[QN + "Flower_3_Group.gltf", 0.35, 0.55, 45], [QN + "Flower_4_Group.gltf", 0.35, 0.55, 45],
	[QN + "Fern_1.gltf", 0.7, 1.1, 50], [QN + "Plant_1.gltf", 0.6, 1.0, 30], [QN + "Plant_7.gltf", 0.6, 1.0, 25],
	[QN + "Mushroom_Common.gltf", 0.25, 0.4, 35], [QN + "Mushroom_Laetiporus.gltf", 0.3, 0.45, 15],
	[QN + "DeadTree_1.gltf", 5.0, 7.0, 6], [QN + "DeadTree_3.gltf", 4.0, 6.0, 6],
	[QN + "Clover_1.gltf", 0.15, 0.25, 30], [QN + "Pebble_Round_2.gltf", 0.15, 0.3, 30], [QN + "Pebble_Square_3.gltf", 0.15, 0.3, 20]]
const TUFOS := [QN + "Grass_Common_Short.gltf", QN + "Grass_Common_Tall.gltf", QN + "Grass_Wispy_Short.gltf", QN + "Grass_Wispy_Tall.gltf"]
const DIST_ARVORE := 45.0        # até aqui a árvore é o modelo 3D; depois vira a "foto" (impostor)
const DIST_IMPOSTOR := 150.0     # a foto some daqui em diante (a neblina disfarça)
## Altura da foto em relação à altura da árvore (gerada por ../scripts/impostores.py)
const IMPOSTOR := {"CommonTree_1": 1.2855, "CommonTree_2": 1.1916, "CommonTree_3": 1.02, "CommonTree_4": 1.02, "CommonTree_5": 1.2286, "Pine_1": 1.3786, "Pine_2": 1.5842, "Pine_3": 1.1027, "Pine_4": 1.1563, "Pine_5": 1.5013, "TwistedTree_1": 1.6485, "TwistedTree_2": 1.1372, "TwistedTree_3": 1.4603}
const BOSQUES := 22               # centros de bosque: as árvores se agrupam em volta deles
const ORC := preload("res://models/Orc.gltf")
const KNIGHT := preload("res://models/Knight.glb")
const VILLAGER := preload("res://scripts/villager.gd")
const MINOTAURO := preload("res://models/Minotauro_Dark.glb")
const BOSS := preload("res://scripts/boss.gd")
const FENIX := preload("res://scripts/fenix.gd")
const PET := preload("res://scripts/pet.gd")
const PET_DA_CLASSE := {"guerreiro": "cavalo", "lanceiro": "urso", "arqueiro": "lobo", "mago": "fenix"}
const SAVE := "user://save_v4.json"
const VERSAO := "v71"
const ZOOM_MIN := 0.2            # pinça: 0.2 = bem perto do personagem
const ZOOM_MAX := 1.5
const MURO_R := 52.0             # raio da muralha (aumentada para caber armazéns, horta, currais e oficinas)
const RIO_R := 76.0              # raio médio do riacho em volta da aldeia (ondula ±3,5 m)
const RIO_LARG := 5.0            # largura da água
const LAGO_ANG := PI * 0.75      # o lago fica a noroeste, encostado no riacho (que o alimenta)
const VIRAR_PARA_PRACA := ["SalaoDoChefe", "Casa1", "Casa2", "Casa3", "Forja", "Moinho", "Barraca"]
const ALTURA_CASTELO := 13.0     # castelo maior por fora (antes 10 m)
const DIRS := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
const CAM_NOMES := ["3ª pessoa", "1ª pessoa", "Visão de águia"]

## Classes: vida base, dano por nível da arma, alcance. "area" = dano em área (mago).
const CLASSES := {
	"guerreiro": {"nome": "Guerreiro", "desc": "Corpo a corpo, forte e resistente", "hp": 140, "dano": [14, 20, 28], "alcance": 2.8, "longe": false, "area": 0.0, "cor": Color(1, 1, 1), "tiro": Color(1, 1, 1)},
	"arqueiro": {"nome": "Arqueiro", "desc": "Dispara flechas de longe", "hp": 100, "dano": [10, 15, 21], "alcance": 15.0, "longe": true, "area": 0.0, "cor": Color(0.65, 1.0, 0.6), "tiro": Color(0.95, 0.85, 0.5)},
	"lanceiro": {"nome": "Lanceiro", "desc": "Estocada longa que atravessa vários inimigos em linha", "hp": 120, "dano": [12, 18, 25], "alcance": 4.2, "avanco": 9.0, "longe": false, "area": 0.0, "cor": Color(1, 1, 1), "tiro": Color(1, 1, 1)},
	"mago": {"nome": "Mago", "desc": "Magia pelo cajado: explosão em área ou raio forte num alvo", "hp": 90, "dano": [9, 13, 18], "alcance": 13.0, "longe": true, "area": 3.2, "cor": Color(0.8, 0.65, 1.0), "tiro": Color(0.7, 0.4, 1.0)},
}
## Mercado: cada classe vê só os itens dela. item = [id, nome, bônus, custo]. Bônus: dano, vida, energia.
const LOJA_CATS := ["Armas", "Armaduras", "Roupas", "Artefatos"]
const LOJA := {
	"guerreiro": {
		"Armas": [["g_esp_aco", "Espada de aço temperado", {"dano": 5}, {"pedra": 60, "madeira": 30}], ["g_esp_runa", "Espada rúnica", {"dano": 12}, {"pedra": 160, "madeira": 80, "comida": 40}]],
		"Armaduras": [["g_cota", "Cota de malha", {"vida": 30}, {"pedra": 80}], ["g_placas", "Armadura de placas", {"vida": 70}, {"pedra": 200, "madeira": 40}]],
		"Roupas": [["g_capa", "Capa vermelha do reino", {}, {"comida": 30}], ["g_tabardo", "Tabardo real", {}, {"comida": 60, "madeira": 20}]],
		"Artefatos": [["g_amuleto", "Amuleto do guardião", {"vida": 20}, {"comida": 120}], ["g_anel", "Anel da força", {"dano": 4}, {"pedra": 100, "comida": 60}]]},
	"lanceiro": {
		"Armas": [["l_lanca_ferro", "Lança de ferro", {"dano": 5}, {"pedra": 60, "madeira": 40}], ["l_lanca_drag", "Lança do dragão", {"dano": 12}, {"pedra": 150, "madeira": 100, "comida": 40}]],
		"Armaduras": [["l_couro", "Couraça de couro", {"vida": 25}, {"comida": 60, "pedra": 30}], ["l_escamas", "Armadura de escamas", {"vida": 60}, {"pedra": 180, "comida": 40}]],
		"Roupas": [["l_manto", "Manto de caçador", {}, {"comida": 30}], ["l_pele", "Pele de urso", {}, {"comida": 70}]],
		"Artefatos": [["l_totem", "Totem do urso", {"vida": 25}, {"comida": 110}], ["l_presa", "Presa de javali", {"energia": 30}, {"comida": 90, "pedra": 30}]]},
	"arqueiro": {
		"Armas": [["a_arco_longo", "Arco longo", {"dano": 5}, {"madeira": 90}], ["a_arco_elfo", "Arco élfico", {"dano": 12}, {"madeira": 200, "comida": 50}]],
		"Armaduras": [["a_couro", "Couro batido", {"vida": 20}, {"comida": 60}], ["a_brig", "Brigantina", {"vida": 50}, {"pedra": 120, "comida": 40}]],
		"Roupas": [["a_capuz", "Capuz verde", {}, {"comida": 25}], ["a_folhas", "Capa de folhas", {}, {"comida": 60, "madeira": 20}]],
		"Artefatos": [["a_aljava", "Aljava encantada", {"dano": 4}, {"madeira": 80, "comida": 60}], ["a_pena", "Pena de falcão", {"energia": 35}, {"comida": 100}]]},
	"mago": {
		"Armas": [["m_cajado_carv", "Cajado de carvalho antigo", {"dano": 5}, {"madeira": 80, "comida": 20}], ["m_cajado_crist", "Cajado de cristal", {"dano": 12}, {"pedra": 140, "madeira": 80, "comida": 40}]],
		"Armaduras": [["m_seda", "Manto de seda", {"vida": 20}, {"comida": 70}], ["m_arcano", "Manto arcano", {"vida": 45}, {"comida": 150, "pedra": 40}]],
		"Roupas": [["m_chapeu", "Chapéu pontudo", {}, {"comida": 30}], ["m_estrelas", "Túnica estrelada", {}, {"comida": 70}]],
		"Artefatos": [["m_orbe", "Orbe de mana", {"energia": 40}, {"pedra": 60, "comida": 80}], ["m_grimorio", "Grimório antigo", {"dano": 5}, {"comida": 140}]]},
}
var sexo_inicial := ""           # "m"/"f": aldeão ou aldeã escolhido na abertura (antes de ter classe)
const MACHADO_ALDEAO := ["Machado_Lenhador.glb", "hand_r", Heroi.MAO_D, Vector3(90, 0, 0), 0.75, 0.3]
var nivel_jog := 1               # nível do personagem (sobe com experiência: inimigos e missões do Rei)
var xp := 0
var diamantes := 0               # dinheiro do jogo (missões do Rei, chefões, venda de recursos)
var predios: Array = []          # construções que evoluem (0 a 100): {id, nome, cat, node, custo, base, nivel}
var _niveis_salvos := {}
var _torres_castelo: Array = []   # as duas torres redondas do castelo (ganham a cor do nível do castelo)
const PREDIOS_ALDEIA := {"SalaoDoChefe": ["Castelo do Rei", "castelo", {"madeira": 80, "pedra": 120}], "Casa1": ["Casa", "", {"madeira": 40, "pedra": 25}],
	"Casa2": ["Casa", "", {"madeira": 40, "pedra": 25}], "Casa3": ["Casa do Mago", "", {"madeira": 50, "pedra": 40}],
	"Forja": ["Forja", "", {"madeira": 50, "pedra": 60}], "Moinho": ["Moinho", "", {"madeira": 50, "pedra": 20}]}
var compras: Array = []          # ids dos itens comprados no mercado
var equipado := {}               # categoria -> id do item em uso (da classe atual)

const ARMA_CUSTO := [{}, {"madeira": 40, "pedra": 30}, {"madeira": 90, "pedra": 70, "comida": 30}]
const OFICIOS := ["madeira", "pedra", "comida"]

@export var forest_radius := 118.0
@export var village_radius := 58.0
@export var tree_count := 300
@export var rock_count := 40
@export var bush_count := 50
@export var max_enemies := 4

var res := {"madeira": 0, "pedra": 0, "comida": 0}
var kills := 0
var quest := 0
var classe := ""
var heroi := ""                  # um dos 16 personagens (Heroi.lista)
var magia := "orbe"              # mago: "orbe" (área) ou "livro" (um alvo, mais forte)
var visual := {}                 # personalização por personagem: {id: {"mao": "orbe"|"chama", "acess": ""|"mascara"|"coroa"}}
var arma := 1
var nodes: Array = []            # coletáveis: {node, tipo, hp, scene, h, dono}
var aldeoes: Array = []
var tiros: Array = []            # projéteis: {node, alvo, dano, area}
var _renascer: Array = []        # recursos que voltam a nascer: {t, scene, h, tipo, hp}
var _holder: Node3D
var ceu: Ceu                     # dia, noite e chuva (scripts/ceu.gd)
var lago: Lago                   # lago da floresta (scripts/lago.gd)
var mundo: Mundo                 # mundo aberto: regiões inimigas, mar, Ilha dos Orcs e barcos (scripts/mundo.gd)
var vila: Vila                   # aldeia funcionando: trabalhadores, guardas, animais, armazéns (scripts/vila.gd)
var fogueira: Fogueira           # fogueira grande do centro da vila (scripts/fogueira.gd)
var _guardas_noite: Array = []   # guardas em volta da fogueira, só à noite
var _pilha_t := 0.0
var _viu_aldeoes := false
var _painel: Control
var boss: Node3D                 # Minotauro Dark, quando está vivo
var boss_derrotas := 0
var boss_em := 6                 # aparece quando o número de orcs derrotados chega aqui
var _boss_bar: ProgressBar
var _boss_vp: SubViewport        # barra do chefe desenhada aqui...
var _boss_spr: Sprite3D          # ...e mostrada em cima da cabeça dele
var _boss_lbl: Label
var cam_modo := 0                # 0 = terceira pessoa, 1 = primeira, 2 = águia
var _cam_off := Vector3(0, 9, 10)
var _olhar := 0.0               # arrastar um dedo: 0 = normal, 1 = olhando o céu, negativo = mais para o chão
const OLHAR_MIN := -0.3
const OLHAR_MAX := 1.0
var _giro := 0.0                # arrastar para os lados: gira a câmera em volta do personagem
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
var _botoes: BotoesAcao
var som: Som                     # música, ambientes e efeitos (scripts/som.gd)
var _status: PainelStatus         # retrato, vida e energia (scripts/painel_status.gd)
var _menu_b: Array = []        # botões que o MENU mostra/esconde
var _hud_info := false          # INFO: recursos e missões visíveis
var _dentro := ""                # nome do prédio em que o jogador está ("" = fora)
var _perto := ""                 # prédio da aldeia ao alcance da porta
var _saida := Vector3(0, 0, 8)
var _trans := false
var _cam_antes := 0
var pet: Node3D                  # pet da classe (cavalo alado, urso, lobo ou fênix)
var _pet_tipo := ""
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
	{"t": "Veja os trabalhadores da aldeia (botão ALDEÕES)", "p": func(): return 1 if _viu_aldeoes else 0, "n": 1, "r": {"comida": 20}},
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
	add_to_group("jogo")   # inimigos e outros acham o jogo por aqui
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
			if String(b.name) in VIRAR_PARA_PRACA:   # porta (lado -Z do modelo) virada para o centro da aldeia
				b.rotation.y = atan2(b.position.x, b.position.z)
			if String(b.name) == "SalaoDoChefe":
				b.set_meta("altura", ALTURA_CASTELO)
			# "altura" (metadado do nó) define o tamanho da construção em metros
			if b.has_meta("altura"):
				Fit.to_height(b, float(b.get_meta("altura")))
			if String(b.name) == "SalaoDoChefe":
				_castelo_extra.call_deferred(b)
			_add_collision(b)
			var bx := Fit.bounds(b)
			var centro: Vector3 = b.global_transform * bx.get_center()
			_fixos.append({"pos": centro, "r": maxf(bx.size.x, bx.size.z) * 0.5 * b.scale.x, "h": bx.size.y * b.scale.y, "nome": String(b.name)})
	for p in $Lotes.get_children():
		plots.append(p)
		p.built.connect(_on_built)
		p.upgraded.connect(_on_upgraded)
	lago = Lago.new()
	lago.name = "Lago"
	var rl := RIO_R + Lago.RAIO * 0.85
	lago.position = Vector3(cos(LAGO_ANG) * rl, 0, sin(LAGO_ANG) * rl)
	add_child(lago)
	vila = Vila.new()
	vila.name = "Vila"
	add_child(vila)
	vila.montar(self)
	mundo = Mundo.new()
	mundo.name = "Mundo"
	add_child(mundo)
	mundo.montar(self)
	_registrar_predios()
	_scatter_forest()
	_ceu()
	lago.montar(ceu)
	_aldeia_extra()
	for c in $Aldeia.get_children():
		Construcoes.estilo_casa(c)
	Efeitos.chao($Chao/Malha, load("res://models/grass_albedo.jpg"))
	player.attacked.connect(_on_player_attack)
	player.died.connect(_on_player_died)
	$HUD/Atacar.pressed.connect(player.attack)
	use_b.pressed.connect(_use)
	$HUD/Novo.pressed.connect(_new_game)
	$HUD/Novo.text = "Novo jogo (%s)" % VERSAO
	use_b.visible = false
	# HUD limpo: MENU mostra Novo jogo/Classe/Aldeões/Câmera; INFO mostra recursos e missões
	_menu_b.append($HUD/Novo)
	$HUD/Novo.offset_top = 70.0
	$HUD/Novo.offset_bottom = 116.0
	_menu_b.append(_hud_button("CLASSE", 124.0, _menu_classe))
	_menu_b.append(_hud_button("ALDEÕES", 178.0, _menu_aldeoes))
	_menu_b.append(_hud_button("CÂMERA", 232.0, _trocar_camera))
	_menu_b.append(_hud_button("MERCADO", 286.0, _menu_mercado))
	_menu_b.append(_hud_button("ALDEIA", 340.0, _menu_aldeia))
	for b: Control in _menu_b:
		b.visible = false
	var mb := _hud_button("MENU", 16.0, abrir_menu)
	var ib := _hud_button("INFO", 16.0, func():
		_hud_info = not _hud_info
		quest_l.visible = _hud_info
		_rei_l.visible = _hud_info)
	ib.offset_left = -330
	ib.offset_right = -200
	_def_b = _botao_acao("DEFESA", -400.0, -230.0, true)
	_def_b.toggled.connect(func(v): player.defendendo = v)
	_corre_b = _botao_acao("CORRER", -400.0, -130.0, true)
	_corre_b.toggled.connect(func(v): player.correndo = v)
	_botoes = BotoesAcao.new()   # botões redondos com ícone e animação (scripts/botoes_acao.gd)
	add_child(_botoes)
	_botoes.montar(self, $HUD/Atacar, _def_b, _corre_b)
	_ent_b = _botao_acao("ENTRAR", -260.0, -440.0, false, 70.0)
	_ent_b.pressed.connect(_porta)
	_ent_b.visible = false
	_rei_b = _botao_acao("FALAR COM O REI", -260.0, -520.0, false, 70.0)
	_rei_b.pressed.connect(_menu_rei)
	_rei_b.visible = false
	_status = PainelStatus.new()
	_status.jogo = self
	$HUD.add_child(_status)
	$HUD.move_child(_status, 0)
	_status.retrato(heroi)
	info.offset_top = 108.0     # recursos e missões ficam embaixo do painel
	quest_l.offset_top = 140.0
	quest_l.offset_bottom = 178.0
	_rei_l = Label.new()
	_rei_l.offset_left = 24.0
	_rei_l.offset_top = 178.0
	_rei_l.add_theme_font_size_override("font_size", 20)
	_rei_l.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	_rei_l.add_theme_color_override("font_outline_color", Color.BLACK)
	_rei_l.add_theme_constant_override("outline_size", 8)
	$HUD.add_child(_rei_l)
	quest_l.visible = false
	_rei_l.visible = false
	_fade_r = ColorRect.new()
	_fade_r.color = Color(0, 0, 0, 0)
	_fade_r.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(_fade_r)
	_recalc()
	_boss_hud()
	if not _load():
		say("Ande com o direcional. Bata em árvores, rochas e arbustos para coletar.", 7.0)
	som = Som.new()
	som.name = "Som"
	som.jogo = self
	add_child(som)
	# abertura: logo em tela cheia; no jogo novo, depois vem a escolha aldeão/aldeã (scripts/abertura.gd)
	var ab := Abertura.new()
	ab.jogo = self
	ab.escolher = heroi == "" and sexo_inicial == ""
	add_child(ab)
	if heroi == "" and sexo_inicial != "":
		_vestir_aldeao()

## Castelo: duas torres redondas de pedra nas laterais da frente e dois guardas na porta.
func _castelo_extra(b: Node3D) -> void:
	var bx := Fit.bounds(b)
	var c: Vector3 = b.global_transform * bx.get_center()
	var meia_l := bx.size.x * 0.5 * b.scale.x
	var meia_p := bx.size.z * 0.5 * b.scale.z
	var frente := c.z + meia_p                    # a porta olha para o centro (+Z)
	for sx: float in [-1.0, 1.0]:
		var t := Construcoes.torre_pedra(2.2, ALTURA_CASTELO * 1.05)
		t.position = Vector3(c.x + sx * (meia_l + 1.6), 0, frente - 2.0)
		add_child(t)
		_torres_castelo.append(t)
		for pr: Dictionary in predios:
			if pr.id == "SalaoDoChefe":
				Niveis.tingir(t, Niveis.faixa(pr.nivel))
		var g := Guarda.new()   # guardas do castelo: guerreiro e arqueiro, lutam se um inimigo chegar perto
		g.tipo = "guerreiro" if sx < 0 else "arqueiro"
		g.jogo = self
		g.position = Vector3(c.x + sx * 2.6, 0.0, frente + 1.6)
		add_child(g)
		if vila != null:
			vila.guardas.append(g)

## Detalhes da aldeia montados por código (caminhos, lampiões, placa, feno, lenha, varal, cocho, banca).
func _aldeia_extra() -> void:
	var r := Node3D.new()
	r.name = "Detalhes"
	add_child(r)
	var praca := MeshInstance3D.new()   # praça de terra batida
	var pc := CylinderMesh.new()
	pc.top_radius = 8.5
	pc.bottom_radius = 8.5
	pc.height = 0.004
	pc.radial_segments = 32
	pc.material = Construcoes.mat_terra()
	praca.mesh = pc
	praca.position.y = 0.008
	praca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(praca)
	Construcoes.caminho(r, Vector3(0, 0, 8), Vector3(0, 0, RIO_R + 12), 3.2)
	Construcoes.caminho(r, Vector3(0, 0, -8), Vector3(0, 0, -21), 3.2)
	Construcoes.caminho(r, Vector3(8, 0, 0), Vector3(RIO_R + 12, 0, 0), 3.2)
	Construcoes.caminho(r, Vector3(-8, 0, 0), Vector3(-RIO_R - 12, 0, 0), 3.2)
	# riacho em volta da aldeia, com pontes onde os caminhos dos portões cruzam (2 de madeira, 2 de pedra)
	r.add_child(Construcoes.riacho(Callable(self, "_rio_raio"), RIO_LARG))
	Construcoes.caminho(r, Vector3(0, 0, -MURO_R - 1), Vector3(0, 0, -RIO_R - 12), 3.2)
	for i in 4:
		var ang := PI * 0.5 * i
		var pt := Construcoes.ponte(RIO_LARG + 4.0, 3.4, i % 2 == 1)
		pt.position = Vector3(cos(ang), 0, sin(ang)) * _rio_raio(ang)
		pt.rotation.y = -ang
		r.add_child(pt)
	# calçamento: pedras chatas na beira da praça e ao longo dos caminhos (Quaternius RockPath)
	var pedras := [load(QN + "RockPath_Round_Small_1.gltf"), load(QN + "RockPath_Round_Small_2.gltf"), load(QN + "RockPath_Square_Small_1.gltf"), load(QN + "RockPath_Round_Thin.gltf")]
	for i in 40:
		var a := TAU * i / 40.0 + _rng.randf() * 0.05
		_pedra_chao(r, pedras[i % pedras.size()], Vector3(cos(a), 0, sin(a)) * _rng.randf_range(7.6, 8.6))
	for eixo: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var lado := Vector3(eixo.z, 0, eixo.x)
		var fim := 21.0 if eixo.z < 0 else RIO_R - 4.0
		var d := 10.0
		while d < fim:
			_pedra_chao(r, pedras[_rng.randi() % pedras.size()], eixo * d + lado * _rng.randf_range(-1.1, 1.1))
			d += _rng.randf_range(1.4, 2.6)
	# canteiros: flores, samambaias e arbustos encostados nos prédios da aldeia
	var canteiro := [load(QN + "Flower_3_Group.gltf"), load(QN + "Flower_4_Group.gltf"), load(QN + "Fern_1.gltf"), load(QN + "Bush_Common_Flowers.gltf"), load(QN + "Plant_1.gltf")]
	for f in _fixos:
		if not Interior.SALAS.has(f.nome) and f.nome != "Moinho":
			continue
		for k in 6:
			var a := _rng.randf() * TAU
			var p: Vector3 = Vector3(f.pos.x, 0, f.pos.z) + Vector3(cos(a), 0, sin(a)) * (float(f.r) + 0.6)
			if minf(absf(p.x), absf(p.z)) < 2.2 or Vector2(p.x, p.z).length() < 9.0:
				continue
			var c: PackedScene = canteiro[_rng.randi() % canteiro.size()]
			var n: Node3D = c.instantiate()
			r.add_child(n)
			n.position = p
			n.rotation.y = _rng.randf() * TAU
			Fit.to_height(n, _rng.randf_range(0.45, 0.9))
			Efeitos.vento(n, 0.05, 0.9)
			Efeitos.distancia(n, 45.0)
	fogueira = Fogueira.new()
	fogueira.name = "Fogueira"
	fogueira.position = Vector3(0, 0, 0.5)
	r.add_child(fogueira)
	for i in 3:   # guardas da noite em volta da fogueira, olhando para fora
		var ang := TAU * i / 3.0 + 0.4
		var g := Heroi.montar(["G1", "L1", "G3"][i])
		g.position = fogueira.position + Vector3(cos(ang), 0, sin(ang)) * 3.6 + Vector3(0, 0.05, 0)
		g.rotation.y = atan2(cos(ang), sin(ang))
		g.visible = false
		r.add_child(g)
		Fit.play(Fit.find_node_of(g, "AnimationPlayer") as AnimationPlayer, &"Sword_Idle")
		_guardas_noite.append(g)
	var por := func(n: Node3D, pos: Vector3, giro: float) -> void:
		n.position = pos
		n.rotation.y = giro
		r.add_child(n)
	for p in [Vector3(7, 0, -6), Vector3(-7, 0, -6), Vector3(-8, 0, 4), Vector3(2.5, 0, 16), Vector3(-2.5, 0, 28), Vector3(16, 0, -2.5), Vector3(-16, 0, 2.5), Vector3(-2.5, 0, -15), Vector3(2.5, 0, -15)]:
		var lp := Construcoes.lampiao(p.length() < 9.0)   # os da praça têm luz de verdade à noite
		por.call(lp, p, atan2(-p.x, -p.z) + PI / 2.0)
		var luz := lp.get_node_or_null("Luz")
		ceu.lampioes.append([Construcoes.vidro_lampiao(), luz])
	var alvos := {"Salão do Rei": Vector3(0, 0, -27), "Forja": Vector3(27, 0, 4), "Moinho": Vector3(29, 0, -13), "Portão Sul": Vector3(0, 0, 40)}
	var pl := Vector3(3.5, 0, 6.5)
	var giros: Array = []
	for k in alvos:
		var d: Vector3 = alvos[k] - pl
		giros.append(atan2(d.x, d.z))
	por.call(Construcoes.placa(alvos.keys(), giros), pl, 0.0)
	por.call(Construcoes.feno(), Vector3(23, 0, -7), 0.4)
	por.call(Construcoes.feno(), Vector3(21, 0, -21), -0.3)
	por.call(Construcoes.lenha(), Vector3(22, 0, 9), 0.2)
	por.call(Construcoes.lenha(), Vector3(-11, 0, -12), -0.6)
	por.call(Construcoes.varal(Vector3(-21, 0, -10), Vector3(-21, 0, -5)), Vector3.ZERO, 0.0)
	por.call(Construcoes.cocho(), Vector3(3.6, 0, -6.5), 0.3)
	por.call(Construcoes.banca(Color(0.7, 0.15, 0.12)), Vector3(-3.5, 0, 13), PI)
	por.call(Construcoes.banca(Color(0.15, 0.3, 0.6)), Vector3(-15, 0, 9), PI * 0.6)
	for p in [Vector3(-12.5, 0, 13), Vector3(-13.3, 0, 13.6), Vector3(12.5, 0, 14.2), Vector3(-5.5, 0, -1.8)]:
		por.call(Construcoes.caixote(0.6 + 0.15 * sin(p.x)), p, p.z)

## Céu: foto 360° (Sketchfab, CC-BY: Marcin Lubecki), no lugar do céu liso. A luz ambiente continua branca.
func _ceu() -> void:
	ceu = Ceu.new()
	ceu.name = "Ceu"
	add_child(ceu)
	ceu.iniciar($Sol, $Ambiente.environment, cam)
	ceu.mudou_periodo.connect(_periodo)

## Noite: aldeões vão para casa; de manhã voltam ao trabalho.
func _periodo(e_noite: bool) -> void:
	say("Anoiteceu. Os aldeões foram para casa e os guardas acenderam a fogueira." if e_noite else "Amanheceu!", 3.0)
	if e_noite and ceu.noite_cheia:
		if _dentro == "":
			_comecar_lua_cheia()
		else:
			_lua_pendente = true
	elif not e_noite:
		_fim_lua_cheia()
	for g in _guardas_noite:
		g.visible = e_noite
	for v in aldeoes:
		if is_instance_valid(v):
			v.dormir(e_noite)

# ---------- noite de lua cheia ----------
const LOBOS_LUA := 6               # lobisomens que saem da Floresta da Escuridão para atacar a aldeia
var _cena_lua := 0.0               # segundos restantes da cena da câmera olhando a lua
var _lobos_lua: Array = []

var _lua_pendente := false        # a lua cheia começou com o jogador dentro de casa: a cena roda quando ele sair

func _comecar_lua_cheia() -> void:
	if _cena_lua > 0.0 or not _lobos_lua.is_empty():
		return
	_lua_pendente = false
	_cena_lua = 8.0
	$HUD.visible = false
	Som.eu.musica_forcada = "lua_cheia"
	get_tree().create_timer(1.6).timeout.connect(func(): Som.efeito("uivo", null, 4.0))
	get_tree().create_timer(8.0).timeout.connect(func():
		$HUD.visible = true
		say("NOITE DE LUA CHEIA!\nOs lobisomens saíram da Floresta da Escuridão e vêm atacar a aldeia!", 7.0)
		_soltar_lobos())

func _soltar_lobos() -> void:
	for i in LOBOS_LUA:
		var e := CharacterBody3D.new()
		e.set_script(preload("res://scripts/enemy.gd"))
		e.collision_mask = 3
		e.max_hp = 90 + 10 * boss_derrotas
		e.damage = 14
		e.speed = 4.8
		e.altura = 2.8
		e.voz = "rugido"
		e.setup_no(mundo.lobisomem(), player)
		e.position = Vector3(_rng.randf_range(-35.0, 35.0), 0, -165.0 - _rng.randf() * 20.0)
		e.rumo = Vector3(0, 0, -MURO_R - 8.0)   # vêm pela estrada até o portão norte
		add_child(e)
		e.killed.connect(func(): kills += 1)
		enemies.append(e)
		_lobos_lua.append(e)

func _fim_lua_cheia() -> void:
	if Som.eu != null and Som.eu.musica_forcada == "lua_cheia":
		Som.eu.musica_forcada = ""
	var restavam := 0
	for e in _lobos_lua:
		if is_instance_valid(e) and not e._dead:
			restavam += 1
			e.queue_free()   # com o sol, os lobisomens fogem de volta para a floresta
	_lobos_lua.clear()
	if restavam > 0:
		say("O sol nasceu e os lobisomens fugiram para a floresta.", 4.0)

## Cena da lua cheia: a câmera fica atrás do personagem e sobe o olhar até a lua gigante (com zoom).
func _camera_lua(delta: float) -> void:
	_cena_lua -= delta
	var pp := player.global_position
	var dl: Vector3 = ceu.dir_lua
	var plano := Vector3(dl.x, 0, dl.z).normalized()
	var k := clampf((8.0 - _cena_lua) / 3.0, 0.0, 1.0)
	var pos := pp - plano * 3.5 + Vector3(0, 1.8, 0)
	cam.global_position = cam.global_position.lerp(pos, minf(1.0, 3.0 * delta))
	var olho := (pp + Vector3(0, 1.6, 0)).lerp(cam.global_position + dl * 100.0, smoothstep(0.0, 1.0, k))
	cam.look_at(olho)
	cam.fov = lerpf(60.0, 30.0, smoothstep(0.3, 1.0, k))
	if _cena_lua <= 0.0:
		cam.fov = 60.0

## Porta da casa mais perta (para os aldeões dormirem).
func casa_perto(de: Vector3) -> Vector3:
	var melhor := Vector3(0, 0, 4)
	var bd := 1e9
	for f in _fixos:
		if String(f.nome).begins_with("Casa"):
			var c: Vector3 = Vector3(f.pos.x, 0, f.pos.z)
			var porta: Vector3 = c - c.normalized() * (float(f.r) + 0.5)
			var dd := porta.distance_to(de)
			if dd < bd:
				bd = dd
				melhor = porta
	return melhor

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
	var a := 0.0
	var r := 0.0
	for tentativa in 12:   # longe do riacho e do lago
		a = _rng.randf() * TAU
		r = sqrt(_rng.randf_range(pow(village_radius / forest_radius, 2.0), 1.0)) * forest_radius
		if absf(r - _rio_raio(a)) > RIO_LARG * 0.5 + 2.5 and not _no_lago(Vector3(cos(a) * r, 0, sin(a) * r), 3.5):
			break
	return Vector3(cos(a) * r, 0, sin(a) * r)

func _no_lago(p: Vector3, folga: float) -> bool:
	return lago != null and lago.dentro(p, folga)

## Raio do riacho no ângulo `a` (ondula em volta da aldeia).
func _rio_raio(a: float) -> float:
	return RIO_R + 3.5 * sin(3.0 * a + 0.7)

func _scatter_forest() -> void:
	var holder := Node3D.new()
	holder.name = "Floresta"
	add_child(holder)
	_holder = holder
	for i in tree_count:
		_place(holder, load(TREES[_rng.randi() % TREES.size()]), _rng.randf_range(6.5, 10.5), "madeira", 3)
	for i in rock_count:
		_place(holder, load(ROCKS[_rng.randi() % ROCKS.size()]), _rng.randf_range(1.2, 2.0), "pedra", 3)
	for i in bush_count:
		_place(holder, load(BUSHES[_rng.randi() % BUSHES.size()]), _rng.randf_range(1.0, 1.5), "comida", 2)
	for e: Array in ENFEITES:
		var cena: PackedScene = load(e[0])
		for i in int(e[3]):
			_place(holder, cena, _rng.randf_range(e[1], e[2]), "", 0)
	_tufos_grama(holder)

## Tufos de grama espalhados por toda a volta (MultiMesh: centenas de tufos com poucas chamadas de desenho).
## Divididos em 8 setores, para a câmera descartar os que estão fora da tela.
@export var tufos_grama := 900   # quantidade de tufos (diminua se o tablet ficar lento)
func _tufos_grama(holder: Node3D) -> void:
	var setores := 8
	for k in TUFOS.size():
		var malha: Dictionary = _malha_de(load(TUFOS[k]))
		if malha.is_empty():
			continue
		var pos: Array = []
		for i in tufos_grama / TUFOS.size():
			var a := _rng.randf() * TAU
			var r := sqrt(_rng.randf_range(pow(10.0 / forest_radius, 2.0), 1.0)) * forest_radius
			var pp := Vector3(cos(a) * r, 0, sin(a) * r)
			if absf(r - _rio_raio(a)) < RIO_LARG * 0.5 + 0.5 or absf(r - MURO_R) < 1.0 or minf(absf(pp.x), absf(pp.z)) < 2.2 or _no_lago(pp, 0.5) or (r < MURO_R and _perto_de_predio(pp)):   # fora da água, da muralha, dos caminhos e dos prédios
				continue
			pos.append(Vector3(cos(a) * r, 0, sin(a) * r))
		for sct in setores:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = malha.mesh as Mesh
			var meus: Array = []
			for p: Vector3 in pos:
				if int(fposmod(atan2(p.z, p.x), TAU) / TAU * setores) == sct:
					meus.append(p)
			mm.instance_count = meus.size()
			for i in meus.size():
				var esc: float = _rng.randf_range(0.7, 1.3) * float(malha.esc)
				mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * esc), meus[i]))
			var mi := MultiMeshInstance3D.new()
			mi.multimesh = mm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if malha.mat != null:
				mi.material_override = malha.mat as Material
			holder.add_child(mi)

## Pedra chata de calçamento rente ao chão (sem colisão).
func _pedra_chao(pai: Node3D, cena: PackedScene, pos: Vector3) -> void:
	var n: Node3D = cena.instantiate()
	pai.add_child(n)
	n.position = pos
	n.rotation.y = _rng.randf() * TAU
	var bb := Heroi._caixa(n)
	var esc := _rng.randf_range(0.7, 1.1) / maxf(maxf(bb.size.x, bb.size.z), 0.01)
	n.scale = Vector3.ONE * esc
	n.position.y = -bb.position.y * esc - bb.size.y * esc * 0.6   # quase enterrada: não tropeça e não esconde o pé
	Efeitos.distancia(n, 40.0)

## Posição de árvore: agrupada em bosques e mais densa longe da aldeia (borda da floresta mais fechada).
var _bosques: Array = []
func _pos_arvore() -> Vector3:
	if _bosques.is_empty():
		for i in BOSQUES:
			var a := _rng.randf() * TAU
			var r := _rng.randf_range(village_radius + 6.0, forest_radius - 4.0)
			_bosques.append(Vector3(cos(a) * r, 0, sin(a) * r))
	for tentativa in 12:
		var p: Vector3
		if _rng.randf() < 0.7:   # 70% em bosques, 30% soltas (mais para a borda)
			var c: Vector3 = _bosques[_rng.randi() % _bosques.size()]
			p = c + Vector3(_rng.randfn(0.0, 7.0), 0, _rng.randfn(0.0, 7.0))
		else:
			var a := _rng.randf() * TAU
			var r := lerpf(village_radius, forest_radius, sqrt(_rng.randf()))
			p = Vector3(cos(a) * r, 0, sin(a) * r)
		var rr := Vector2(p.x, p.z).length()
		var ang := atan2(p.z, p.x)
		if rr > village_radius and rr < forest_radius and absf(rr - _rio_raio(ang)) > RIO_LARG * 0.5 + 2.5 and not _no_lago(p, 4.0):
			return p
	return _ring_pos()

## De longe, a árvore vira uma foto virada para a câmera (impostor): bem mais leve para o tablet.
static var _mat_imp := {}
func _impostor(n: Node3D, scene: PackedScene, h: float) -> void:
	var nome := scene.resource_path.get_file().get_basename()
	if not IMPOSTOR.has(nome):
		return
	var arq := "res://assets/nature/impostores/%s.png" % nome
	if not ResourceLoader.exists(arq):
		return
	if not _mat_imp.has(nome):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load(arq)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.45
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 1.0
		_mat_imp[nome] = m
	var alto: float = h * float(IMPOSTOR[nome])
	var q := QuadMesh.new()
	q.size = Vector2(alto * 0.5, alto)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = _mat_imp[nome]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_begin = DIST_ARVORE
	mi.visibility_range_begin_margin = DIST_ARVORE * 0.1
	mi.visibility_range_end = DIST_IMPOSTOR
	var s := n.scale.x
	mi.scale = Vector3.ONE / s
	mi.position = Vector3(0, (h * 0.5 - n.position.y) / s, 0)
	n.add_child(mi)

func _perto_de_predio(p: Vector3) -> bool:
	for f in _fixos:
		if Vector2(p.x - f.pos.x, p.z - f.pos.z).length() < float(f.r) + 1.0:
			return true
	return false

## Primeira malha de um modelo, com a escala para ~0,5 m de altura e o material com vento.
func _malha_de(cena: PackedScene) -> Dictionary:
	var n: Node3D = cena.instantiate()
	var lista: Array = []
	Fit._collect(n, lista)
	if lista.is_empty():
		n.free()
		return {}
	var mi: MeshInstance3D = lista[0]
	var bb := mi.mesh.get_aabb()
	var mat: Material = null
	var tmp := Node3D.new()
	var copia := MeshInstance3D.new()
	copia.mesh = mi.mesh
	tmp.add_child(copia)
	Efeitos.vento(tmp, 0.05, 0.6)
	mat = copia.get_surface_override_material(0)
	tmp.free()
	var r := {"mesh": mi.mesh, "esc": 0.5 / maxf(bb.size.y, 0.01), "mat": mat}
	n.free()
	return r

func _place(holder: Node3D, scene: PackedScene, h: float, tipo: String, hp: int) -> void:
	var n: Node3D = scene.instantiate()
	holder.add_child(n)
	n.position = _pos_arvore() if tipo == "madeira" else _ring_pos()
	n.rotation.y = _rng.randf() * TAU
	Fit.to_height(n, h)
	if tipo == "madeira":       # árvores balançam ao vento
		Efeitos.vento(n, 0.18, h)
		Efeitos.distancia(n, DIST_ARVORE, true)
		_impostor(n, scene, h)
	elif tipo == "comida" or (tipo == "" and h < 1.5):   # arbustos e plantas, de leve
		Efeitos.vento(n, 0.06, h)
		Efeitos.distancia(n, 45.0)
	else:
		Efeitos.distancia(n, 60.0)
	if tipo == "":   # enfeites: sem colisão e sem sombra (mais leve)
		for c in n.find_children("*", "StaticBody3D", true, false):
			c.queue_free()
	if tipo != "":
		nodes.append({"node": n, "tipo": tipo, "hp": hp, "scene": scene, "h": h, "maxhp": hp, "dono": null})

func _process(delta: float) -> void:
	player.joy = joy.value
	if ceu != null:
		ceu.abrigado = _dentro != ""   # dentro de casa não chove
	_camera(delta)
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	_mag_t = maxf(0.0, _mag_t - delta)
	if _dentro == "":
		_spawn_t -= delta
		if _spawn_t <= 0.0 and enemies.filter(func(e): return e.get("guarda") != true).size() < max_enemies:
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
	_pilha_t -= delta
	if _pilha_t <= 0.0:
		_pilha_t = 2.0
		_pilhas_armazem()
	if fogueira != null and ceu != null:
		fogueira.intensidade = lerpf(0.15, 1.0, smoothstep(0.3, 0.75, ceu.fator_noite))
	_renascimento(delta)
	_nearest_plot()
	if Input.is_action_just_pressed("use"):
		_use()
	_check_quest()
	if _hud_info:
		info.text = "Diamantes %d   Madeira %d   Pedra %d   Comida %d   Inimigos %d" % [diamantes, res.madeira, res.pedra, res.comida, kills]
	else:
		info.text = ""
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
			res.madeira += int(2 + 0.3 * _lvl("madeira"))
	_tower_t -= delta
	if _tower_t <= 0.0:
		_tower_t = 1.5
		for p in plots:
			if p.construido and p.efeito == "torre":
				for e in enemies:
					if is_instance_valid(e) and e.global_position.distance_to(p.global_position) < 20.0:
						_balista(p, e)
						break
	# cura na aldeia, longe de inimigos; a Estalagem dobra
	var safe := player.global_position.length() < MURO_R
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_to(player.global_position) < 12.0:
			safe = false
	if safe and player.hp > 0 and player.hp < player.max_hp:
		_regen += delta * (2.0 + 0.2 * _lvl("descanso"))
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
	if vila != null:   # construtores e serralheiros vão martelar na obra
		vila.nova_obra(_near.global_position)

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
	var b := _bonus_loja()
	player.damage += int(b.get("dano", 0))
	player.max_energia = 100.0 + float(b.get("energia", 0))
	player.energia = minf(player.energia, player.max_energia)
	player.max_hp = base + 5 * _lvl("vida") + 4 * (nivel_jog - 1) + int(b.get("vida", 0))
	if _botoes != null:
		_botoes.atualizar_arma()
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
	if mundo != null:   # os orcs chegam de barco, pelo cais a leste, e marcham até o portão leste
		var pt = mundo.ponto_orc()
		if pt == null:
			e.free()
			return
		e.position = pt
		e.rumo = Vector3(MURO_R + 8.0, 0, 0)
	add_child(e)
	e.killed.connect(func(): kills += 1)
	enemies.append(e)

func _on_player_attack() -> void:
	var p := player.global_position
	Som.efeito("magia" if classe == "mago" else ("lamina" if classe == "arqueiro" else "corte"), null, -4.0)
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
		if alvo == null and vila != null and not _recurso_perto(p):   # sem inimigo e longe de árvore/pedra: caça um animal
			alvo = vila.animal_perto(p, best)
		if alvo != null:
			var to: Vector3 = alvo.global_position - p
			player.rotation.y = atan2(to.x, to.z)
			if pet != null and is_instance_valid(pet) and not (alvo is Animal):
				pet.atacar(alvo)   # o pet ataca junto com o golpe (só orcs e chefe, não a caça)
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
			Som.efeito("espada" if classe in ["guerreiro"] else ("soco_forte" if classe == "" else "metal"), p)
			som.em_batalha()
			return
	if vila != null and vila.golpe_jogador(p, 2.6, player.damage):   # caça de perto
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

func _recurso_perto(p: Vector3) -> bool:
	for t in nodes:
		if is_instance_valid(t.node) and t.hp > 0 and t.node.global_position.distance_to(p) < 2.8:
			return true
	return false

## Um golpe num recurso. Devolve true quando ele acaba (e some).
func golpear(t: Dictionary, _do_jogador: bool) -> bool:
	var n = t.node
	if not is_instance_valid(n) or t.hp <= 0:
		return true
	t.hp -= 1
	Som.efeito({"madeira": "machado", "pedra": "pedra", "comida": "madeira"}.get(t.tipo, "madeira"), n.global_position, 0.0, 25.0)
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
	if _cena_lua > 0.0:
		_camera_lua(delta)
		return
	var pp := player.global_position
	if cam_modo == 1:        # primeira pessoa: olhos do personagem
		var olhos := pp + Vector3(0, 1.65, 0)
		var frente := player.global_basis.z
		cam.global_position = olhos + frente * 0.2
		cam.look_at(olhos + frente * 10.0 + Vector3(0, -0.8 + _olhar * 14.0, 0))
		return
	var alvo := Vector3(0, 9 * (1.0 - 0.85 * maxf(_olhar, 0.0)) + 0.6, 10) * _zoom   # olhando para cima, a câmera desce atrás do boneco
	if cam_modo == 2:        # visão de águia
		alvo = Vector3(0, 40, 8) * _zoom
	else:
		# construção entre a câmera e o personagem: ela some enquanto atrapalha (a câmera não sobe mais)
		if _dentro == "":
			_esconder_tapando(delta)
	alvo = alvo.rotated(Vector3.UP, _giro)
	player.giro_cam = _giro
	_cam_off = _cam_off.lerp(alvo, minf(1.0, 5.0 * delta))
	cam.global_position = cam.global_position.lerp(pp + _cam_off, minf(1.0, 8.0 * delta))
	cam.look_at(pp + Vector3(0, 1.2 + (_olhar * 16.0 if cam_modo == 0 else 0.0), 0))
	# árvores na frente do boneco ficam escondidas enquanto atrapalham
	_arv_t -= delta
	if _arv_t <= 0.0:
		_arv_t = 0.15
		var c := cam.global_position
		for t in nodes:
			if t.tipo == "madeira" and is_instance_valid(t.node):
				var s := _seg(t.node.global_position, c, pp)
				# a árvore que o personagem está cortando (perto dele) nunca some
				t.node.visible = not (cam_modo == 0 and s.x < 2.6 and s.y > 0.12 and s.y < 0.9 and t.node.global_position.distance_to(pp) > 4.5)

var _escondidos := {}   # construção escondida -> segundos até voltar
var _esconde_t := 0.0

## Raio da câmera até o peito do personagem: cada construção atingida fica invisível por um instante.
func _esconder_tapando(delta: float) -> void:
	for n in _escondidos.keys():
		_escondidos[n] -= delta
		if not is_instance_valid(n):
			_escondidos.erase(n)
		elif _escondidos[n] <= 0.0:
			(n as Node3D).visible = true
			_escondidos.erase(n)
	_esconde_t -= delta
	if _esconde_t > 0.0:
		return
	_esconde_t = 0.1
	var de := cam.global_position
	var ate := player.global_position + Vector3(0, 1.2, 0)
	var esp := get_world_3d().direct_space_state
	var excluir: Array[RID] = [player.get_rid()]
	for i in 5:
		var q := PhysicsRayQueryParameters3D.create(de, ate)
		q.exclude = excluir
		var r := esp.intersect_ray(q)
		if r.is_empty():
			break
		var col: Object = r.collider
		excluir.append(r.rid)
		if not (col is StaticBody3D):
			continue
		var raiz := _raiz_construcao(col as Node)
		if raiz != null:
			if raiz.visible or _escondidos.has(raiz):
				raiz.visible = false
				_escondidos[raiz] = 0.35

## Sobe da colisão até o nó "inteiro" da construção (filho da aldeia, da vila ou de uma região).
func _raiz_construcao(n: Node) -> Node3D:
	var atual: Node = n
	while atual != null and atual != self:
		var pai := atual.get_parent()
		if pai == null:
			return null
		if pai == $Aldeia or pai == $Lotes or pai == vila or pai == _muro or (mundo != null and (pai == mundo or String(pai.name).begins_with("Regiao_"))) or pai == self:
			if atual == $Chao or atual is CharacterBody3D or atual == player or atual == $Lotes:
				return null
			return atual as Node3D
		atual = pai
	return null

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
		if _toques.size() == 1 and e.position.x < get_viewport().get_visible_rect().size.x * 0.68:   # um dedo arrastando: olha para cima/baixo
			_olhar = clampf(_olhar - e.relative.y * 0.004, OLHAR_MIN, OLHAR_MAX)
			_giro -= e.relative.x * 0.006   # para os lados: gira a câmera em volta do personagem
		if _toques.size() == 2 and _mag_t <= 0.0:
			var k: Array = _toques.keys()
			var d: float = (_toques[k[0]] - _toques[k[1]]).length()
			if _pinca_d > 0.0 and d > 1.0:
				_zoom = clampf(_zoom * _pinca_d / d, ZOOM_MIN, ZOOM_MAX)
			_pinca_d = d
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_RIGHT):   # botão direito arrastando (computador)
		_olhar = clampf(_olhar - e.relative.y * 0.004, OLHAR_MIN, OLHAR_MAX)
		_giro -= e.relative.x * 0.006
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
		var pj := player.global_position
		for f in _fixos:
			if Interior.SALAS.has(f.nome):
				var d: float = Vector2(pj.x - f.pos.x, pj.z - f.pos.z).length()
				if d < float(f.r) + 3.2 and d < best:
					best = d
					_perto = f.nome
		for p in plots:   # prédios construídos nos lotes (Casa, Estalagem, Serraria) também têm interior
			if p.construido and p.modelo != null and Interior.SALAS.has(String(p.name)):
				var h: float = p.altura * (1.0 + 0.1 * (p.nivel - 1))
				var d2: float = Vector2(pj.x - p.global_position.x, pj.z - p.global_position.z).length()
				if d2 < h * 0.55 + 3.5 and d2 < best:
					best = d2
					_perto = String(p.name)
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
	Som.efeito("porta")
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
		sala.position = Vector3(600.0 + 60.0 * _interiores.size(), 0, 1400.0)   # fora do mapa (o mar e a ilha ficam em z perto de 0)
		add_child(sala)
		_interiores[id] = sala
	_dentro = id
	var raiz: Node3D = _interiores[id]
	_familia(raiz, id)
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

## À noite, quem mora na casa está lá dentro: o aldeão aquecendo-se perto da lareira, a esposa e o filho
## sentados no banco. De dia a casa fica vazia (estão trabalhando).
func _familia(sala: Node3D, id: String) -> void:
	if not (id.begins_with("Casa") or id == "LoteCasa") or id == "Casa3":   # Casa3 é a do alquimista
		return
	var f := sala.get_node_or_null("Familia") as Node3D
	if f == null:
		f = Node3D.new()
		f.name = "Familia"
		sala.add_child(f)
		# pai, mãe e filho sentados à mesa (cadeiras do kit: assento a 0,50 m; as de z = 0,85 olham para +Z,
		# as de z = 2,35 para -Z). A animação de sentar põe a pélvis ~0,26 da altura acima da origem e ~0,19 atrás
		# dela: a origem sobe e avança para a pélvis cair no meio do assento.
		var lugares := [["A2", 1.75, Vector3(1.8, 0, 0.85), 0.0], ["A3", 1.66, Vector3(3.4, 0, 0.85), 0.0], ["A2", 1.2, Vector3(1.8, 0, 2.35), PI]]
		for l: Array in lugares:
			var m := Heroi.montar(String(l[0]), false, true)
			Heroi.vestir(m, "Male_Peasant" if String(l[0]) == "A2" else "Female_Peasant", float(l[1]) < 1.5)   # roupa de camponês
			for nm in ["Capa", "Capuz"] + (["Hair_Beard"] if float(l[1]) < 1.5 else []):   # dentro de casa, sem capa; o filho sem barba
				var c := m.find_child(nm, true, false) as Node3D
				if c != null:
					c.visible = false
			var hh: float = l[1]
			var giro: float = l[3]
			var cadeira: Vector3 = l[2]
			var frente := Vector3(sin(giro), 0, cos(giro))
			var n := Node3D.new()
			n.position = cadeira + Vector3(0, 0.5 - 0.26 * hh, 0) + frente * 0.19 * hh
			n.rotation.y = giro
			f.add_child(n)
			n.add_child(m)
			Fit.to_height(m, hh)
			Fit.play(Fit.find_node_of(m, "AnimationPlayer") as AnimationPlayer, &"Sitting_Idle")
		# prato com comida e caneca no lugar do filho
		Interior.peca(f, Interior.MP + "Table_Plate.gltf", Vector3(1.8, 0.81, 1.85), PI)
		Interior.peca(f, Interior.MP + "Mug.gltf", Vector3(1.45, 0.81, 1.9))
		var pao := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.07
		var mp := StandardMaterial3D.new()
		mp.albedo_color = Color(0.78, 0.52, 0.25)
		sm.material = mp
		pao.mesh = sm
		pao.position = Vector3(1.8, 0.86, 1.85)
		pao.scale = Vector3(1.4, 1, 1)
		f.add_child(pao)
	f.visible = ceu != null and ceu.noite

func _sair() -> void:
	Som.efeito("porta")
	if _lua_pendente and ceu.noite_cheia:
		get_tree().create_timer(1.5).timeout.connect(_comecar_lua_cheia)
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
	diamantes += 10
	ganhar_xp(120)
	say("O Rei agradece! +" + plots[0].texto(q.r) + ", +10 diamantes", 5.0)
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
	var madeira := Construcoes.mat(Construcoes.MADEIRA_ESCURA)
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
	for lado: float in [-1.0, 1.0]:
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
	for lado: float in [-1.0, 1.0]:
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
	var faixa := Niveis.faixa(nivel)
	var altura := 3.0 + 0.035 * nivel
	var tora := CylinderMesh.new()
	tora.top_radius = 0.2
	tora.bottom_radius = 0.3
	tora.height = altura
	tora.radial_segments = 6
	tora.material = Construcoes.mat(Color(0.52, 0.36, 0.22) if nivel < 3 else Color(0.46, 0.32, 0.2))   # casca de madeira (antes saía cinza-claro)
	var ponta := CylinderMesh.new()   # ponta afiada em cima de cada tora
	ponta.top_radius = 0.0
	ponta.bottom_radius = 0.2
	ponta.height = 0.55
	ponta.radial_segments = 6
	ponta.material = Construcoes.mat(Color(0.72, 0.6, 0.45))
	var corda := CylinderMesh.new()   # amarração de corda (duas faixas)
	corda.top_radius = 0.29
	corda.bottom_radius = 0.29
	corda.height = 0.09
	corda.radial_segments = 6
	corda.material = Construcoes.mat(Construcoes.CORDA, false)
	var angs: Array = []
	var n := int(TAU * MURO_R / 0.56)
	for i in n:
		var a := TAU * i / n
		# deixa 4 portões abertos (leste, oeste, norte, sul)
		var perto := absf(fposmod(a + PI * 0.25, PI * 0.5) - PI * 0.25)
		if perto > 0.15:
			angs.append(a)
	var pedra := nivel >= 40   # faixa 4 em diante: muro de pedra com ameias (antes: paliçada de troncos)
	tora.material = Niveis.material(tora.material, faixa)
	ponta.material = Niveis.material(ponta.material, faixa)
	var malha_muro: Mesh = tora
	var malha_topo: Mesh = ponta
	if pedra:
		altura += 0.6
		var bloco := BoxMesh.new()
		bloco.size = Vector3(0.6, altura, 1.4)
		bloco.material = Niveis.material(Construcoes.mat_pedra(), faixa)
		malha_muro = bloco
		var ameia := BoxMesh.new()
		ameia.size = Vector3(0.62, 0.7, 1.45)
		ameia.material = Niveis.material(Construcoes.mat_pedra(), faixa)
		malha_topo = ameia
		corda.material = Construcoes.mat_pedra()
		corda.top_radius = 0.01   # sem amarração de corda na pedra
		corda.bottom_radius = 0.01
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malha_muro
	mm.instance_count = angs.size()
	for i in angs.size():
		var a: float = angs[i]
		var hh := 1.0 + 0.08 * sin(i * 1.7) if not pedra else 1.0
		var giro := Basis(Vector3.UP, -(a + PI * 0.5)) if pedra else Basis()
		mm.set_instance_transform(i, Transform3D(giro.scaled(Vector3(1, hh, 1)), Vector3(cos(a) * MURO_R, altura * 0.5 * hh, sin(a) * MURO_R)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	_muro.add_child(mmi)
	var mp := MultiMesh.new()
	mp.transform_format = MultiMesh.TRANSFORM_3D
	mp.mesh = malha_topo
	mp.instance_count = angs.size()
	var mc := MultiMesh.new()
	mc.transform_format = MultiMesh.TRANSFORM_3D
	mc.mesh = corda
	mc.instance_count = angs.size() * 2
	for i in angs.size():
		var a2: float = angs[i]
		var hh := 1.0 + 0.08 * sin(i * 1.7)
		var base := Vector3(cos(a2) * MURO_R, 0, sin(a2) * MURO_R)
		if pedra:   # ameias: um bloco sim, outro não
			hh = 1.0
			var giro2 := Basis(Vector3.UP, -(a2 + PI * 0.5))
			mp.set_instance_transform(i, Transform3D(giro2 if i % 2 == 0 else giro2.scaled(Vector3(1, 0.001, 1)), base + Vector3(0, altura + 0.35, 0)))
		else:
			mp.set_instance_transform(i, Transform3D(Basis(), base + Vector3(0, altura * hh + 0.27, 0)))
		mc.set_instance_transform(i * 2, Transform3D(Basis(), base + Vector3(0, altura * 0.3, 0)))
		mc.set_instance_transform(i * 2 + 1, Transform3D(Basis(), base + Vector3(0, altura * 0.75, 0)))
	for m2 in [mp, mc]:
		var mi2 := MultiMeshInstance3D.new()
		mi2.multimesh = m2
		_muro.add_child(mi2)
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
## Nome e barra de vida do chefe flutuando em cima da cabeça dele (antes ficavam no meio da tela).
## Desenhados num SubViewport pequeno e mostrados num Sprite3D que sempre olha para a câmera.
func _boss_hud() -> void:
	_boss_vp = SubViewport.new()
	_boss_vp.size = Vector2i(420, 70)
	_boss_vp.transparent_bg = true
	_boss_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_boss_vp)
	_boss_lbl = Label.new()
	_boss_lbl.position = Vector2(0, 0)
	_boss_lbl.size = Vector2(420, 34)
	_boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_lbl.add_theme_font_size_override("font_size", 24)
	_boss_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.35))
	_boss_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_boss_lbl.add_theme_constant_override("outline_size", 8)
	_boss_vp.add_child(_boss_lbl)
	_boss_bar = ProgressBar.new()
	_boss_bar.position = Vector2(30, 38)
	_boss_bar.size = Vector2(360, 24)
	_boss_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.12, 0.1)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0, 0, 0, 0.6)
	_boss_bar.add_theme_stylebox_override("background", fundo)
	_boss_vp.add_child(_boss_bar)
	_boss_spr = Sprite3D.new()
	_boss_spr.texture = _boss_vp.get_texture()
	_boss_spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_boss_spr.no_depth_test = true
	_boss_spr.pixel_size = 0.0075
	_boss_spr.visible = false
	add_child(_boss_spr)

func _chefe() -> void:
	var vivo: bool = boss != null and is_instance_valid(boss) and not boss._dead
	_boss_spr.visible = vivo and _dentro == ""
	if vivo:
		_boss_spr.global_position = boss.global_position + Vector3(0, float(boss.altura) + 0.9, 0)
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
	diamantes += 50
	ganhar_xp(400)
	say("Minotauro Dark derrotado! +%d de cada recurso e +50 diamantes. Ele voltará mais forte..." % premio, 7.0)
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
	if ResourceLoader.exists("res://models/armas/Flecha.glb"):   # flecha realista (Sketchfab, CC-BY: Gwappa)
		var f: Node3D = load("res://models/armas/Flecha.glb").instantiate()
		f.rotation.y = PI / 2.0   # a ponta do modelo está em +X; a flecha voa para -Z
		r.add_child(f)
		return r
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
	var arco: Node = player.model.find_child("ArcoIK", true, false)
	await get_tree().create_timer(0.28 if arco == null else 0.4).timeout   # espera o golpe do cajado / a corda soltar (SOLTA em arco_ik.gd)
	if not is_instance_valid(alvo) or not is_instance_valid(player):
		m.free()
		return
	add_child(m)
	m.global_position = _ponta() if mago else player.global_position + Vector3(0, 1.3, 0) + player.global_basis.z * 0.6
	if is_instance_valid(arco) and arco.arco != null:   # a flecha sai do arco
		m.global_position = arco.arco.global_position
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
			Som.efeito("fogo" if t.area > 0.0 or not t.flecha else "flecha", dest)
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

## A balista da torre gira para o inimigo e dispara um dardo grande (dano ao chegar).
func _balista(p, e) -> void:   # p: lote (plot.gd), e: inimigo
	var bal := p.find_child("Balista", true, false) as Node3D
	var dano: int = 4 + 3 * int(p.nivel)
	if bal == null:
		e.hurt(dano)
		return
	var alvo: Vector3 = e.global_position
	var giro: float = atan2(alvo.x - bal.global_position.x, alvo.z - bal.global_position.z) - bal.get_parent_node_3d().global_rotation.y
	bal.rotation.y = giro
	var m := _flecha()
	m.scale = Vector3.ONE * 1.8
	add_child(m)
	m.global_position = (bal.get_node("Ponta") as Node3D).global_position
	tiros.append({"node": m, "alvo": e, "dano": dano, "area": 0.0, "cor": Color.WHITE, "flecha": true})

## Flecha disparada por um guarda arqueiro.
func flecha_de(de: Vector3, alvo: Node3D, dano: int) -> void:
	var m := _flecha()
	add_child(m)
	m.global_position = de
	tiros.append({"node": m, "alvo": alvo, "dano": dano, "area": 0.0, "cor": Color.WHITE, "flecha": true})

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
	return 2 + mini(10, _lvl("vida") / 5)

func custo_aldeao() -> Dictionary:
	return {"comida": 15 + 10 * aldeoes.size(), "madeira": 10 * aldeoes.size()}

func deposito() -> Vector3:
	for p in plots:   # com o armazém construído, os aldeões entregam na frente dele
		if p.efeito == "armazem" and p.construido:
			return p.global_position + (-p.global_position).normalized() * 5.0
	return Vector3(0, 0, 4)

## Pilhas do armazém: cada item aparece a cada 25 unidades do recurso (até 6).
func _pilhas_armazem() -> void:
	for p in plots:
		if p.efeito == "armazem" and p.construido:
			for tipo: String in ["madeira", "pedra", "comida"]:
				var pilha: Node = p.find_child("Pilha_" + tipo, true, false)
				if pilha == null:
					continue
				var qtd := mini(6, int(res[tipo]) / 25)
				for i in pilha.get_child_count():
					(pilha.get_child(i) as Node3D).visible = i < qtd

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
	if ceu != null and ceu.noite:
		v.dormir.call_deferred(true)
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
	var ex: Dictionary = (visual.get(id, {}) as Dictionary).duplicate()
	ex.erase("acess")   # máscara e coroa foram tiradas (não ficaram boas)
	var m := Heroi.montar(id, true, false, ex)
	player.trocar_modelo(m, Heroi.ANIMS[classe])
	player.model.visible = cam_modo != 1
	Efeitos.realce(player.model, Color(1.0, 0.85, 0.6), 0.1)   # luz de borda no herói
	if _status != null:
		_status.retrato(id)
	if _botoes != null:
		_botoes.atualizar_arma()
	_recalc()
	_pet_ajustar()
	if salvar:
		player.hp = player.max_hp
		_save()

## Aldeão/aldeã do começo: corpo de herói com roupa de camponês e machado de lenhador, sem armadura.
func modelo_aldeao(sexo: String) -> Node3D:
	var m := Heroi.montar("A2" if sexo == "m" else "A3", false, true)
	Heroi.vestir(m, "Male_Peasant" if sexo == "m" else "Female_Peasant", sexo == "f")
	Heroi._prender(Fit.find_node_of(m, "Skeleton3D") as Skeleton3D, MACHADO_ALDEAO)
	return m

## Escolha feita na abertura.
func comecar_como(sexo: String) -> void:
	sexo_inicial = sexo
	_vestir_aldeao()
	_save()
	say("Bem-vind%s à aldeia! Use o botão CLASSE quando quiser virar guerreiro, lanceiro, arqueiro ou mago." % ("o" if sexo == "m" else "a"), 7.0)

func _vestir_aldeao() -> void:
	player.trocar_modelo(modelo_aldeao(sexo_inicial), Heroi.ANIMS["aldeao"])
	player.model.visible = cam_modo != 1
	Efeitos.realce(player.model, Color(1.0, 0.85, 0.6), 0.1)
	if _status != null:
		_status.retrato("aldeao_" + sexo_inicial)
	if _botoes != null:
		_botoes.atualizar_arma()

## Cada classe tem um pet: guerreiro = cavalo alado, lanceiro = urso, arqueiro = lobo, mago = fênix de fogo.
func _pet_ajustar() -> void:
	var tipo: String = PET_DA_CLASSE.get(classe, "")
	var tem: bool = pet != null and is_instance_valid(pet)
	if tem and tipo == _pet_tipo:
		return
	if tem:
		pet.queue_free()
	pet = null
	_pet_tipo = ""
	if tipo == "":
		return
	pet = FENIX.new() if tipo == "fenix" else PET.new()
	if tipo != "fenix":
		pet.tipo = tipo
	pet.dono = player
	pet.jogo = self
	add_child(pet)
	pet.global_position = player.global_position + Vector3(0, 3.0 if tipo == "fenix" else 0.0, 0)
	_pet_tipo = tipo

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
func _hud_button(texto: String, y: float, cb: Callable) -> Button:
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
	return b

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
	sb.bg_color = Color(0.05, 0.06, 0.1, 0.8)   # vidro escuro translúcido (mesmo estilo do painel de vida)
	sb.border_color = Color(0.95, 0.8, 0.45, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
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
	var lista: VBoxContainer = vb
	if rows.size() > 6:   # muitas linhas: rolam dentro da janela
		var rolar := ScrollContainer.new()
		rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rolar.custom_minimum_size = Vector2(620, minf(480.0, get_viewport().get_visible_rect().size.y - 280.0))
		vb.add_child(rolar)
		lista = VBoxContainer.new()
		lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lista.add_theme_constant_override("separation", 8)
		rolar.add_child(lista)
	for r in rows:
		var b := Button.new()
		b.text = r.t
		b.disabled = r.get("off", false)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 58)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(r.cb)
		lista.add_child(b)
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
		var v: Dictionary = visual.get(heroi, {})
		var mao := String(v.get("mao", "orbe"))
		rows.append({"t": ("✔ " if mao == "orbe" else "") + "Mão esquerda: orbe flutuando", "cb": func(): _personalizar("mao", "orbe")})
		rows.append({"t": ("✔ " if mao == "chama" else "") + "Mão esquerda: chama colorida", "cb": func(): _personalizar("mao", "chama")})

	rows.append({"t": "Trocar de personagem ou de classe", "cb": func(): _menu_escolha()})
	_abrir("Classe e arma", txt, rows)

## Personalização do personagem atual (vale só para ele): mão esquerda e acessório.
func _personalizar(chave: String, valor: String) -> void:
	var v: Dictionary = visual.get(heroi, {})
	v[chave] = valor
	visual[heroi] = v
	vestir(heroi, false)
	_save()
	_menu_classe()

# ---------- níveis das construções (0 a 100) ----------
func _registrar_predios() -> void:
	for nome_no: String in PREDIOS_ALDEIA:
		var n := $Aldeia.get_node_or_null(nome_no) as Node3D
		if n != null:
			var d: Array = PREDIOS_ALDEIA[nome_no]
			predios.append({"id": nome_no, "nome": d[0], "cat": d[1], "node": n, "custo": d[2], "base": n.scale, "nivel": 0})
	for v: Dictionary in vila.predios:
		var pr := v.duplicate()
		pr["cat"] = ""
		pr["base"] = (v.node as Node3D).scale
		pr["nivel"] = 0
		predios.append(pr)
	for pr: Dictionary in predios:
		Niveis.visual(pr.node, 0, pr.base)

func _definir_predio(pr: Dictionary, n: int) -> void:
	pr.nivel = clampi(n, 0, Niveis.MAX)
	Niveis.visual(pr.node, pr.nivel, pr.base)
	if pr.id == "SalaoDoChefe":
		for t in _torres_castelo:
			Niveis.tingir(t, Niveis.faixa(pr.nivel))

func _niveis_predios() -> Dictionary:
	var d := {}
	for pr: Dictionary in predios:
		d[pr.id] = pr.nivel
	return d

## Menu ALDEIA: todas as construções com o nome da faixa, o nível e o botão de evoluir (madeira e pedra).
func _menu_aldeia() -> void:
	var rows: Array = []
	for n: Node3D in _construcoes_alvo():   # consertos primeiro
		if n.get_meta("destruida", false):
			var cc := {"madeira": 30 + 5 * _nivel_de(n), "pedra": 20 + 4 * _nivel_de(n)}
			rows.append({"t": "CONSERTAR construção destruída (%s)" % plots[0].texto(cc), "off": not _can_pay(cc), "cb": func():
				_pay(cc)
				consertar(n)
				_save()
				_menu_aldeia()})
	for pr: Dictionary in predios:
		var nome_f := Niveis.nome(pr.nome, pr.cat, pr.nivel)
		if pr.nivel >= Niveis.MAX:
			rows.append({"t": "%s · Nv %d (máximo)" % [nome_f, pr.nivel], "off": true, "cb": func(): pass})
			continue
		var c := Niveis.custo(pr.custo, pr.nivel)
		rows.append({"t": "%s · Nv %d → %d  (%s)" % [nome_f, pr.nivel, pr.nivel + 1, plots[0].texto(c)], "off": not _can_pay(c), "cb": func():
			_pay(c)
			_definir_predio(pr, pr.nivel + 1)
			Som.efeito("madeira", (pr.node as Node3D).global_position)
			_save()
			_menu_aldeia()})
	for p in plots:
		if p.construido:
			var nome_p: String = Niveis.nome(p.nome, p.categoria(), p.nivel)
			if p.nivel >= p.NIVEL_MAX:
				rows.append({"t": "%s · Nv %d (máximo)" % [nome_p, p.nivel], "off": true, "cb": func(): pass})
			else:
				var c2: Dictionary = p.custo()
				rows.append({"t": "%s · Nv %d → %d  (%s)" % [nome_p, p.nivel, p.nivel + 1, plots[0].texto(c2)], "off": not _can_pay(c2), "cb": func():
					_pay(c2)
					p.melhorar()
					_save()
					_menu_aldeia()})
	_abrir("Aldeia", "Evolua as construções com madeira e pedra (até o nível 100, lendário).\nMadeira %d · Pedra %d" % [res.madeira, res.pedra], rows)

# ---------- ataques à aldeia ----------
## Alvo mais perto para um invasor: guarda ou aldeão de pé, ou construção inteira (dentro do raio).
func alvo_na_aldeia(de: Vector3, raio: float) -> Node3D:
	var melhor: Node3D = null
	var bd := raio
	if vila != null:
		for g in vila.guardas + vila.trabalhadores:
			if is_instance_valid(g) and g.visible and not g.caido:
				var d: float = g.global_position.distance_to(de)
				if d < bd:
					bd = d
					melhor = g
	for n: Node3D in _construcoes_alvo():
		if not n.get_meta("destruida", false):
			var d2 := n.global_position.distance_to(de) - float(n.get_meta("raio", 0.0))
			if d2 < bd:
				bd = d2
				melhor = n
	return melhor

func _construcoes_alvo() -> Array:
	var lista: Array = []
	for pr: Dictionary in predios:
		var n: Node3D = pr.node
		if not n.has_meta("raio"):
			var bb := Niveis._caixa(n)
			n.set_meta("raio", maxf(bb.size.x, bb.size.z) * 0.5 * n.scale.x)
		lista.append(n)
	for p in plots:
		if p.construido and p._b != null:
			if not p.has_meta("raio"):
				p.set_meta("raio", 2.5)
			lista.append(p)
	return lista

## Vida da construção: 150 + 25 por nível. Sem vida, fica destruída até ser consertada no menu ALDEIA.
func _nivel_de(n: Node3D) -> int:
	for pr: Dictionary in predios:
		if pr.node == n:
			return pr.nivel
	return int(n.get("nivel")) if n.get("nivel") != null else 0

func danificar_construcao(n: Node3D, dano: int) -> void:
	var maxv := 150 + 25 * _nivel_de(n)
	var hpv: int = int(n.get_meta("hp", maxv)) - dano
	n.set_meta("hp", hpv)
	var l := n.get_node_or_null("Vida") as Label3D
	if l == null:
		l = Label3D.new()
		l.name = "Vida"
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.font_size = 40
		l.outline_size = 10
		l.modulate = Color(1.0, 0.45, 0.35)
		l.pixel_size = 0.012
		l.no_depth_test = true
		l.position.y = 7.0
		l.top_level = true
		n.add_child(l)
	var alvo_v: Node3D = n.get("_b") if n.get("_b") != null else n
	var bbv := Niveis._caixa(alvo_v)
	l.global_position = alvo_v.global_transform * Vector3(bbv.get_center().x, bbv.end.y, bbv.get_center().z) + Vector3(0, 1.5, 0)
	l.text = "%d / %d" % [maxi(hpv, 0), maxv]
	if hpv <= 0 and not n.get_meta("destruida", false):
		n.set_meta("destruida", true)
		l.text = "DESTRUÍDA"
		var alvo: Node3D = alvo_v
		var tw := create_tween()
		tw.tween_property(alvo, "scale:y", alvo.scale.y * 0.35, 0.8)
		tw.parallel().tween_property(alvo, "rotation:z", 0.08, 0.8)
		say("Uma construção da aldeia foi destruída! Conserte no menu ALDEIA.", 5.0)

func consertar(n: Node3D) -> void:
	n.set_meta("destruida", false)
	n.remove_meta("hp")
	var l := n.get_node_or_null("Vida")
	if l != null:
		l.queue_free()
	for pr: Dictionary in predios:
		if pr.node == n:
			n.rotation.z = 0.0
			_definir_predio(pr, pr.nivel)
			return
	if n.get("_b") != null:
		(n.get("_b") as Node3D).rotation.z = 0.0
		n.definir_nivel(n.nivel)

# ---------- experiência e nível do personagem ----------
func ganhar_xp(n: int) -> void:
	if nivel_jog >= Niveis.MAX:
		return
	xp += n
	var subiu := false
	while nivel_jog < Niveis.MAX and xp >= Niveis.xp_para(nivel_jog):
		xp -= Niveis.xp_para(nivel_jog)
		nivel_jog += 1
		subiu = true
	if subiu:
		_recalc()
		player.hp = player.max_hp
		Som.efeito("magia", null, 2.0)
		flash(player.global_position + Vector3(0, 1, 0), Color(1.0, 0.85, 0.3), 2.5, 0.6)
		say("Você subiu para o nível %d!" % nivel_jog, 4.0)
		for e in enemies:   # os inimigos acompanham o seu nível
			if is_instance_valid(e) and e.has_method("ajustar_nivel"):
				e.ajustar_nivel(nivel_jog)

## Botão MENU: mostra/esconde a lista de botões (Novo jogo, CLASSE, ALDEÕES, CÂMERA, MERCADO).
func abrir_menu(mostrar = null) -> void:
	for b: Control in _menu_b:
		b.visible = (not b.visible) if mostrar == null else bool(mostrar)

## Soma os bônus dos itens equipados da classe atual.
func _bonus_loja() -> Dictionary:
	var b := {}
	if not LOJA.has(classe):
		return b
	for cat: String in LOJA_CATS:
		for it: Array in LOJA[classe][cat]:
			if equipado.get(cat, "") == it[0]:
				for k: String in it[2]:
					b[k] = int(b.get(k, 0)) + int(it[2][k])
	return b

## MERCADO: roupas, armas, artefatos e armaduras — só os do personagem em uso.
func _menu_mercado() -> void:
	if classe == "" or heroi == "":
		say("Escolha primeiro a classe e o personagem (botão CLASSE).", 3.0)
		return
	# cartões com a imagem 3D do item, nome, bônus e preço (scripts/mercado.gd)
	_fechar()
	var m := Mercado.new()
	m.jogo = self
	$HUD.add_child(m)
	_painel = m

func _menu_mercado_cat(cat: String) -> void:
	var rows: Array = []
	for it: Array in LOJA[classe][cat]:
		var id: String = it[0]
		var bon: Dictionary = it[2]
		var txt_b := ""
		for k: String in bon:
			txt_b += "  +%d %s" % [bon[k], k]
		if txt_b == "":
			txt_b = "  (visual)"
		if id in compras:
			if equipado.get(cat, "") == id:
				rows.append({"t": "✔ %s%s — em uso (tirar)" % [it[1], txt_b], "cb": func(): equipado.erase(cat); _recalc(); _save(); _menu_mercado_cat(cat)})
			else:
				rows.append({"t": "%s%s — usar" % [it[1], txt_b], "cb": func(): equipado[cat] = id; _recalc(); _save(); _menu_mercado_cat(cat)})
		else:
			var custo: Dictionary = it[3]
			rows.append({"t": "Comprar %s%s — %s" % [it[1], txt_b, plots[0].texto(custo)], "off": not _can_pay(custo), "cb": func():
				_pay(custo)
				compras.append(id)
				equipado[cat] = id
				_recalc()
				_save()
				say("Você comprou: %s!" % it[1], 3.0)
				_menu_mercado_cat(cat)})
	rows.append({"t": "← Voltar ao mercado", "cb": func(): _menu_mercado()})
	_abrir(cat, "Madeira %d · Pedra %d · Comida %d" % [res.madeira, res.pedra, res.comida], rows)

## 1) escolhe a classe; 2) escolhe entre os 4 personagens dela (2 masculinos e 2 femininos).
func _menu_escolha(cl := "") -> void:
	var rows: Array = []
	if cl == "":
		for k in CLASSES:
			var c: Dictionary = CLASSES[k]
			rows.append({"t": "%s — %s (vida %d, dano %d)" % [c.nome, c.desc, c.hp, c.dano[0]], "cb": func(): _menu_escolha(k)})
		_abrir("Escolha sua classe", "A classe define sua vida, seu dano e se você luta de perto ou de longe.", rows)
		return
	# os 4 personagens da classe de corpo inteiro, com arma e armadura (scripts/escolha.gd)
	_fechar()
	var tela := EscolhaPersonagem.new()
	tela.jogo = self
	tela.classe = cl
	$HUD.add_child(tela)
	_painel = tela

func _menu_aldeoes() -> void:
	_viu_aldeoes = true
	var linhas: Array = []
	if vila != null:
		var por_oficio := {}
		for w in vila.trabalhadores:
			var k: String = Trabalhador.OFICIOS[w.oficio].nome
			por_oficio[k] = por_oficio.get(k, []) + [w.nome()]
		for k in por_oficio:
			linhas.append("%s: %s" % [k, ", ".join(por_oficio[k])])
		linhas.append("Guardas: %d (um guerreiro e um arqueiro em cada casa e armazém)" % vila.guardas.size())
		linhas.append("Animais: %d (floresta e curral)" % vila.animais.size())
	var txt := "\n".join(linhas) + "\n\nArmazéns: Pedreira (pedra), Madeireira (madeira), Mantimentos (comida), Açougue (caça).\nAlmoço 11h30 e jantar 16h45 na Cozinha. À noite todos vão para casa."
	_abrir("Aldeia", txt, [])

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
		f.store_string(JSON.stringify({"res": res, "kills": kills, "quest": quest, "lotes": niveis, "classe": classe, "heroi": heroi, "magia": magia, "arma": arma, "aldeoes": papeis, "boss_derrotas": boss_derrotas, "boss_em": boss_em, "rei_q": rei_q, "rei_ativa": rei_ativa, "rei_base": rei_base, "visual": visual, "compras": compras, "equipado": equipado, "sexo_inicial": sexo_inicial, "nivel_jog": nivel_jog, "xp": xp, "diamantes": diamantes, "predios": _niveis_predios(), "hora": ceu.hora, "dia": ceu.dia}))

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
	ceu.definir(float(d.get("hora", 9.0)), int(d.get("dia", 0)))
	sexo_inicial = String(d.get("sexo_inicial", ""))
	nivel_jog = clampi(int(d.get("nivel_jog", 1)), 1, Niveis.MAX)
	xp = int(d.get("xp", 0))
	diamantes = int(d.get("diamantes", 0))
	var pn = d.get("predios", {})
	_niveis_salvos = pn if pn is Dictionary else {}
	for pr: Dictionary in predios:
		_definir_predio(pr, int(_niveis_salvos.get(pr.id, 0)))
	var cp = d.get("compras", [])
	compras = cp if cp is Array else []
	var eq = d.get("equipado", {})
	equipado = eq if eq is Dictionary else {}
	var vis = d.get("visual", {})
	visual = vis if vis is Dictionary else {}
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
	# (os aldeões antigos contratados foram substituídos pelos trabalhadores fixos da vila)
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
