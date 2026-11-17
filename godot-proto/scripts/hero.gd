class_name Heroi
## Os 16 personagens jogáveis: corpo realista (Quaternius, CC0) + roupas geradas no Blender
## (scripts/personagens na raiz do repositório) + armas presas nos ossos da mão.

## arma: [arquivo, osso, posição, rotação (graus), comprimento (m), deslocamento ao longo da arma]
const MAO_D := Vector3(-0.03, 0.085, 0.0)     # ponto de pegada (punho fechado) no osso hand_r
const MAO_E := Vector3(0.03, 0.085, 0.0)      # idem no hand_l
const ESPADA := ["Sword.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 1.0, 0.35]
const ESPADAO := ["Sword_Big.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 1.4, 0.5]
const LANCA := ["Spear.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 2.3, 0.0]
const BESTA := ["Besta.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 0.75, 0.0]
const ALJAVA := ["Aljava.glb", "spine_03", Vector3(0.12, 0, -0.15), Vector3(0, 0, 0), 0.8, 0.0]
# o escudo gótico tem a ponta em -Y no modelo; o eixo Y do osso aponta para a mão, então gira 180° (Z) para a ponta ficar para baixo
const ESC_GOTICO := ["Shield_Heater.glb", "lowerarm_l", Vector3(-0.12, 0.13, 0), Vector3(0, -90, 180), 0.75, 0.0, "escudo"]
const ESC_REDONDO := ["Shield_Round.glb", "lowerarm_l", Vector3(-0.12, 0.13, 0), Vector3(0, -90, 0), 0.7, 0.0, "escudo"]
static func CAJADO(cor: String) -> Array: return ["Cajado_%s.glb" % cor, "hand_r", MAO_D, Vector3(90, 0, 0), 1.9, 0.25]

static func lista() -> Dictionary:
	return {
		"G1": {"classe": "guerreiro", "sexo": "m", "nome": "Armadura e elmo, espada e escudo", "armas": [ESPADA, ESC_GOTICO]},
		"G2": {"classe": "guerreiro", "sexo": "m", "nome": "Armadura sem elmo, espadão", "armas": [ESPADAO]},
		"G3": {"classe": "guerreiro", "sexo": "f", "nome": "Armadura de bronze, espada e escudo", "armas": [ESPADA, ESC_REDONDO]},
		"G4": {"classe": "guerreiro", "sexo": "f", "nome": "Armadura sem elmo, espadão", "armas": [ESPADAO]},
		"M1": {"classe": "mago", "sexo": "m", "nome": "Robe azul com capuz", "armas": [CAJADO("Azul")]},
		"M2": {"classe": "mago", "sexo": "m", "nome": "Robe roxo, capuz e ombreiras", "armas": [CAJADO("Roxo")]},
		"M3": {"classe": "mago", "sexo": "f", "nome": "Robe vermelho, sem capuz", "armas": [CAJADO("Rubi")]},
		"M4": {"classe": "mago", "sexo": "f", "nome": "Robe verde, capuz e ombreiras", "armas": [CAJADO("Azul")]},
		"A1": {"classe": "arqueiro", "sexo": "m", "nome": "Toda de verde, com capuz e capa", "armas": [BESTA, ALJAVA]},
		"A2": {"classe": "arqueiro", "sexo": "m", "nome": "Couro marrom, sem capuz", "armas": [BESTA, ALJAVA]},
		"A4": {"classe": "arqueiro", "sexo": "f", "nome": "Toda de verde, com capuz e capa", "armas": [BESTA, ALJAVA]},
		"A3": {"classe": "arqueiro", "sexo": "f", "nome": "Couro marrom, sem capuz", "armas": [BESTA, ALJAVA]},
		"L1": {"classe": "lanceiro", "sexo": "m", "nome": "Armadura e elmo, lança e escudo", "armas": [LANCA, ESC_REDONDO]},
		"L2": {"classe": "lanceiro", "sexo": "m", "nome": "Couro e capa vermelha, lança", "armas": [LANCA]},
		"L3": {"classe": "lanceiro", "sexo": "f", "nome": "Armadura, lança e escudo", "armas": [LANCA, ESC_GOTICO]},
		"L4": {"classe": "lanceiro", "sexo": "f", "nome": "Couro e capa vermelha, lança", "armas": [LANCA]},
	}

## Animações de cada classe (nomes da Universal Animation Library).
const ANIMS := {
	"guerreiro": {"idle": "Sword_Idle", "run": "Jog_Fwd", "atk": "Sword_Regular_A", "hit": "Hit_Chest", "morte": "Death01", "def": "Idle_Shield", "corre": "Sprint"},
	"lanceiro": {"idle": "Sword_Idle", "run": "Jog_Fwd", "atk": "Punch_Jab", "hit": "Hit_Chest", "morte": "Death01", "def": "Idle_Shield", "corre": "Sprint"},
	"arqueiro": {"idle": "Pistol_Idle", "run": "Jog_Fwd", "atk": "Pistol_Shoot", "hit": "Hit_Chest", "morte": "Death01", "def": "Idle_Shield", "corre": "Sprint"},
	"mago": {"idle": "Idle", "run": "Jog_Fwd", "atk": "Sword_Attack", "hit": "Hit_Chest", "morte": "Death01", "def": "Idle_Shield", "corre": "Sprint"},
}

static var _lib: AnimationLibrary

static func _biblioteca() -> AnimationLibrary:
	if _lib == null:
		_lib = AnimationLibrary.new()
		for f in ["UAL1.glb", "UAL2.glb"]:   # Universal Animation Library 1 e 2 (Quaternius, CC0)
			var u: Node = load("res://models/herois/" + f).instantiate()
			var ap := u.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
			var lib := ap.get_animation_library(&"")
			for n in lib.get_animation_list():
				if not _lib.has_animation(n):
					_lib.add_animation(n, lib.get_animation(n))
			u.free()
		for n in _lib.get_animation_list():
			var loop := n.begins_with("Idle") or n.begins_with("Jog") or n.begins_with("Walk") or n.begins_with("Sprint") or n in ["Sword_Idle", "Pistol_Idle", "Spell_Simple_Idle"]
			_lib.get_animation(n).loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	return _lib

## Caixa do modelo no espaço dele mesmo (funciona fora da árvore de cena).
static func _caixa(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var pilha: Array = [[root, Transform3D()]]
	while pilha.size() > 0:
		var it: Array = pilha.pop_back()
		var n: Node = it[0]
		var tr: Transform3D = it[1]
		if n is MeshInstance3D and n.mesh != null:
			var b: AABB = tr * n.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		for c in n.get_children():
			if c is Node3D:
				pilha.append([c, tr * c.transform])
	return box

## Monta o personagem pronto para o jogo (com AnimationPlayer e armas).
static func montar(id: String) -> Node3D:
	var info: Dictionary = lista()[id]
	var m: Node3D = load("res://models/herois/%s.gltf" % id).instantiate()
	m.name = "Model"
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	m.add_child(ap)
	ap.add_animation_library(&"", _biblioteca())
	var sk := Fit.find_node_of(m, "Skeleton3D") as Skeleton3D
	for a in info.armas:
		_prender(sk, a)
	return m

static func _prender(sk: Skeleton3D, x: Array) -> void:
	var w: Node3D = load("res://models/armas/" + x[0]).instantiate()
	var ba := BoneAttachment3D.new()
	ba.bone_name = x[1]
	sk.add_child(ba)
	var piv := Node3D.new()
	ba.add_child(piv)
	piv.add_child(w)
	if x[4] > 0.0:
		var bb := _caixa(w)
		var s: float = x[4] / maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
		w.scale = Vector3.ONE * s
		w.position = -(bb.get_center() * s) + Vector3(0, x[5], 0)
	piv.position = x[2]
	piv.rotation_degrees = x[3]
	if String(x[0]).begins_with("Cajado"):   # ponta do cajado (cristal em +Y): de onde sai a magia
		var mk := Marker3D.new()
		mk.name = "Ponta"
		piv.add_child(mk)
		mk.position = Vector3(0, x[5] + x[4] * 0.5, 0)
	var tipo: String = x[6] if x.size() > 6 else ""
	if tipo != "":
		ba.name = tipo.capitalize()
	if tipo == "escudo":   # duas alças de couro em volta do antebraço, presas atrás do escudo
		var couro := StandardMaterial3D.new()
		couro.albedo_color = Color(0.22, 0.12, 0.05)
		couro.roughness = 0.8
		for yy in [0.07, 0.19]:
			var al := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.042
			tm.outer_radius = 0.058
			tm.rings = 16
			tm.ring_segments = 6
			tm.material = couro
			al.mesh = tm
			ba.add_child(al)
			al.position = Vector3(0, yy, 0)
			var tira := MeshInstance3D.new()
			var bx := BoxMesh.new()
			bx.size = Vector3(0.08, 0.03, 0.03)
			bx.material = couro
			tira.mesh = bx
			ba.add_child(tira)
			tira.position = Vector3(-0.08, yy, 0)
