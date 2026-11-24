extends Node3D
class_name Trabalhador
## Trabalhador da aldeia (versão masculina e feminina de cada ofício), com corpo de personagem,
## roupa da profissão, ferramentas e uma rotina feita de tarefas: ir até um lugar, fazer uma ação
## (animação) por um tempo, chamar uma função. À noite vai para casa; no almoço e no jantar entra na
## fila da cozinha, pega o prato e come na mesa comprida.

## ofício -> nome, corpo masculino/feminino, cores das roupas (material -> cor), acessório
const OFICIOS := {
	"construtor": {"nome": "Construtor", "m": "A2", "f": "A3", "cor": {"tunica": Color(0.45, 0.32, 0.18), "calca": Color(0.3, 0.3, 0.32), "saiote": Color(0.4, 0.28, 0.15)}, "aces": "avental_couro"},
	"serralheiro": {"nome": "Serralheiro", "m": "A2", "f": "A3", "cor": {"tunica": Color(0.6, 0.15, 0.12), "calca": Color(0.22, 0.2, 0.18), "saiote": Color(0.45, 0.12, 0.1)}, "aces": "gorro"},
	"fazendeiro": {"nome": "Fazendeiro", "m": "A2", "f": "A3", "cor": {"tunica": Color(0.62, 0.58, 0.4), "calca": Color(0.25, 0.32, 0.5), "saiote": Color(0.4, 0.5, 0.28)}, "aces": "chapeu"},
	"cacador": {"nome": "Caçador", "m": "A1", "f": "A4", "cor": {}, "aces": ""},
	"cozinheiro": {"nome": "Cozinheiro", "m": "A2", "f": "A3", "cor": {"tunica": Color(0.92, 0.92, 0.9), "calca": Color(0.3, 0.3, 0.33), "saiote": Color(0.9, 0.9, 0.88)}, "aces": "cozinheiro"},
	"artesao": {"nome": "Artesão", "m": "A2", "f": "A3", "cor": {"tunica": Color(0.35, 0.18, 0.45), "calca": Color(0.2, 0.32, 0.38), "saiote": Color(0.6, 0.35, 0.15)}, "aces": "lenco"},
	"ferreiro": {"nome": "Ferreiro", "m": "L2", "f": "L4", "cor": {"tunica": Color(0.22, 0.22, 0.24), "calca": Color(0.18, 0.15, 0.12), "saiote": Color(0.2, 0.2, 0.2)}, "aces": "avental_couro"},
	"mago": {"nome": "Mago", "m": "M2", "f": "M4", "cor": {}, "aces": ""},
}
const VEL := 3.0

var oficio := "construtor"
var sexo := "m"
var jogo: Node
var vila: Node
var model: Node3D
var fila: Array = []          # tarefas: {"ir": Vector3, "anim": nome} | {"fazer": anim, "t": s} | {"f": Callable}
var _ap: AnimationPlayer
var _sk: Skeleton3D
var _mao_d: Node3D            # pivô da mão direita (ferramenta)
var _mao_e: Node3D            # pivô da mão esquerda (cesto, prato)
var _ombro: Node3D            # carcaça nos ombros
var _carrinho: Node3D
var _tag: Label3D
var _t := 0.0
var _periodo := ""
var comeu := ""               # refeição em que já comeu ("almoco3", "jantar3"...)
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	var info: Dictionary = OFICIOS[oficio]
	var id: String = info[sexo]
	var armado := oficio == "mago" or (oficio == "cacador" and sexo == "m")
	model = Heroi.montar(id, armado, not armado)
	add_child(model)
	_sk = Fit.find_node_of(model, "Skeleton3D") as Skeleton3D
	_ap = Fit.find_node_of(model, "AnimationPlayer") as AnimationPlayer
	_roupa(info.cor)
	if oficio != "cacador" and oficio != "mago":
		for n in ["Capa", "Capuz"]:
			var c := model.find_child(n, true, false) as Node3D
			if c != null:
				c.visible = false
	Fit.to_height(model, 1.74 if sexo == "m" else 1.64)
	model.position.y += 0.05
	_mao_d = _pivo("hand_r", Heroi.MAO_D)
	_mao_e = _pivo("hand_l", Heroi.MAO_E)
	_ombro = _pivo("spine_03", Vector3.ZERO)
	_acessorio(String(info.aces))
	if oficio == "cacador" and sexo == "f":   # caçadora: lança e corda
		Heroi._prender(_sk, Heroi.LANCA)
	_carrinho = Construcoes.carrinho()
	_carrinho.position = Vector3(0, 0, 1.5)   # pegadores na altura das mãos, à frente do corpo
	_carrinho.visible = false
	add_child(_carrinho)
	_tag = Label3D.new()
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.font_size = 28
	_tag.outline_size = 10
	_tag.pixel_size = 0.011
	_tag.position.y = 2.15
	_tag.visibility_range_end = 26.0
	_tag.text = info.nome if sexo == "m" else _feminino(String(info.nome))
	add_child(_tag)
	_tocar("Idle")

static func _feminino(n: String) -> String:
	return {"Construtor": "Construtora", "Serralheiro": "Serralheira", "Fazendeiro": "Fazendeira", "Caçador": "Caçadora", "Cozinheiro": "Cozinheira", "Artesão": "Artesã", "Ferreiro": "Ferreira", "Mago": "Maga"}.get(n, n)

func nome() -> String:
	return _tag.text if _tag != null else oficio

## Pinta as roupas do corpo pelos nomes dos materiais (tunica, calca...).
func _roupa(cores: Dictionary) -> void:
	if cores.is_empty():
		return
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m != null and cores.has(m.resource_name):
				var nm := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				nm.albedo_color = cores[m.resource_name]
				mi.set_surface_override_material(i, nm)

func _pivo(osso: String, pos: Vector3) -> Node3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = osso if _sk.find_bone(osso) >= 0 else osso.capitalize()
	_sk.add_child(ba)
	var p := Node3D.new()
	p.position = pos
	if osso.begins_with("hand"):
		p.rotation_degrees = Vector3(90, 0, 0)
	ba.add_child(p)
	return p

func _acessorio(tipo: String) -> void:
	var cabeca := _pivo("Head", Vector3.ZERO)
	var corpo := _pivo("spine_01", Vector3.ZERO)
	match tipo:
		"chapeu":   # chapéu de palha
			Construcoes.cilindro_mesh(cabeca, Vector3(0, 0.2, 0.0), 0.24, 0.02, Color(0.85, 0.72, 0.4))
			Construcoes.cilindro_mesh(cabeca, Vector3(0, 0.26, 0.0), 0.12, 0.12, Color(0.85, 0.72, 0.4))
		"cozinheiro":   # touca branca e avental
			Construcoes.cilindro_mesh(cabeca, Vector3(0, 0.27, 0.0), 0.12, 0.18, Color(0.97, 0.97, 0.97))
			Construcoes.caixa(corpo, Vector3(0, -0.12, 0.13), Vector3(0.34, 0.6, 0.02), Construcoes.mat(Color(0.97, 0.97, 0.95), false, 1.0))
		"avental_couro":
			Construcoes.caixa(corpo, Vector3(0, -0.1, 0.14), Vector3(0.36, 0.62, 0.025), Construcoes.mat(Color(0.32, 0.2, 0.1), true, 0.7))
		"gorro":
			var s := SphereMesh.new()
			s.radius = 0.12
			s.height = 0.14
			s.material = Construcoes.mat(Color(0.25, 0.4, 0.25), false, 1.0)
			var mi := MeshInstance3D.new()
			mi.mesh = s
			mi.position = Vector3(0, 0.19, -0.01)
			cabeca.add_child(mi)
		"lenco":
			Construcoes.cilindro_mesh(cabeca, Vector3(0, 0.0, 0.0), 0.09, 0.05, Color(0.85, 0.6, 0.15))

## Ferramenta na mão direita ("" = mão vazia).
func segurar(nome: String) -> void:
	for c in _mao_d.get_children():
		c.queue_free()
	if nome == "":
		return
	var f: Node3D
	if nome == "machado" or nome == "picareta":
		f = load("res://models/armas/%s.glb" % ("Machado_Lenhador" if nome == "machado" else "Picareta")).instantiate()
		var bb := Heroi._caixa(f)
		var s := 0.85 / maxf(bb.size.y, 0.01)
		f.scale = Vector3.ONE * s
		f.position = -bb.get_center() * s + Vector3(0, 0.3, 0)
	else:
		f = Construcoes.ferramenta(nome)
		f.position.y = 0.05
	_mao_d.add_child(f)

func na_esquerda(nome: String) -> void:
	for c in _mao_e.get_children():
		c.queue_free()
	if nome != "":
		var f := Construcoes.ferramenta(nome)
		f.rotation_degrees = Vector3(-90, 0, 0)
		_mao_e.add_child(f)

## Animal abatido nos ombros ("" tira).
func nos_ombros(tipo: String) -> void:
	for c in _ombro.get_children():
		c.queue_free()
	if tipo == "" or not Animal.TIPOS.has(tipo):
		return
	var a: Node3D = load(Animal.TIPOS[tipo][0]).instantiate()
	for ap in a.find_children("*", "AnimationPlayer", true, false):
		ap.queue_free()
	_ombro.add_child(a)
	var bb := Heroi._caixa(a)
	var s := minf(0.9, Animal.TIPOS[tipo][1]) / maxf(bb.size.y, 0.01) * 0.8
	a.scale = Vector3.ONE * s
	a.rotation_degrees = Vector3(0, 90, 90)   # deitado atravessado nos ombros, nas costas
	a.position = Vector3(0, 0.22, -0.24) - a.basis * (bb.get_center() * s)   # centralizado atrás do pescoço (antes ficava na frente)

func carrinho(tipo: String, mostrar: bool) -> void:
	_carrinho.visible = mostrar
	Construcoes.encher_carrinho(_carrinho, tipo)

func _tocar(nome: String, vel := 1.0) -> void:
	if _ap == null:
		return
	var a := Fit.find_anim(_ap, [nome])
	if a == &"":
		a = Fit.find_anim(_ap, ["Idle"])
	Fit.play(_ap, a, true, vel)

# ---------- tarefas ----------
const MURO := 52.0   # raio da muralha (MURO_R em main.gd): para atravessar, passa pelo portão mais perto

func ir(p: Vector3, anim := "Walk") -> void:
	var de := global_position
	for i in range(fila.size() - 1, -1, -1):
		if (fila[i] as Dictionary).has("ir"):
			de = fila[i].ir
			break
	var dentro := Vector2(de.x, de.z).length() < MURO
	if dentro != (Vector2(p.x, p.z).length() < MURO):
		var melhor := Vector3.FORWARD
		var bd := 1e9
		for g: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var dd := de.distance_to(g * MURO) + (g * MURO).distance_to(p)
			if dd < bd:
				bd = dd
				melhor = g
		var ordem := [MURO - 4.0, MURO + 4.0] if dentro else [MURO + 4.0, MURO - 4.0]
		for r: float in ordem:
			fila.append({"ir": melhor * r, "anim": anim})
	fila.append({"ir": p, "anim": anim})

func fazer(anim: String, t: float) -> void:
	fila.append({"fazer": anim, "t": t})

func depois(f: Callable) -> void:
	fila.append({"f": f})

func limpar() -> void:
	fila.clear()
	segurar("")
	na_esquerda("")
	nos_ombros("")
	carrinho("", false)

func _process(delta: float) -> void:
	if vila == null:
		return
	var per: String = vila.periodo(self)
	if per != _periodo:
		_periodo = per
		limpar()
		visible = true
		if per == "noite":
			ir(jogo.casa_perto(global_position))
			depois(func(): visible = false)
		elif per == "refeicao":
			vila.rotina_refeicao(self)
	if not visible:
		return
	if fila.is_empty():
		if per == "trabalho":
			vila.planejar(self)
		if fila.is_empty():
			_tocar("Idle")
			return
	var tf: Dictionary = fila[0]
	if tf.has("ir"):
		var to: Vector3 = tf.ir - global_position
		to.y = 0
		if to.length() < 0.35:
			fila.pop_front()
			return
		global_position += to.normalized() * minf(VEL * delta, to.length())
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 8.0 * delta)
		_tocar(String(tf.anim))
	elif tf.has("fazer"):
		if not tf.has("ini"):
			tf["ini"] = true
			_t = float(tf.t)
		_tocar(String(tf.fazer))
		_t -= delta
		if _t <= 0.0:
			fila.pop_front()
	elif tf.has("f"):
		fila.pop_front()
		(tf.f as Callable).call()

func olhar_para(p: Vector3) -> void:
	var to := p - global_position
	rotation.y = atan2(to.x, to.z)
