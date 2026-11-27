extends Node3D
class_name Vila
## A aldeia funcionando: armazéns (Pedreira, Madeireira, Mantimentos, Açougue), Cozinha, ateliê da Artesã,
## horta com pomar e parreira, curral com galinheiro, animais da floresta, 16 trabalhadores (8 ofícios,
## masculino e feminino), guardas em cada casa, armazém e no castelo, almoço e jantar na cozinha.

const ALMOCO := Vector2(11.5, 12.5)   # horas do jogo
const JANTAR := Vector2(16.8, 17.8)   # antes de escurecer
## nome -> [posição, ofício que guarda ali, tipo de estoque]
const PREDIOS := {
	"pedreira": [Vector3(38, 0, -22), "Pedreira", "pedra"],
	"madeireira": [Vector3(-38, 0, -22), "Madeireira", "madeira"],
	"mantimentos": [Vector3(30, 0, 30), "Mantimentos", "comida"],
	"acougue": [Vector3(-30, 0, 30), "Açougue", "carne"],
}
const HORTA := Vector3(40, 0, 10)
const CURRAL := Vector3(-40, 0, 11)
const COZINHA := Vector3(-24, 0, -37)
const ARTESA := Vector3(24, 0, -37)

var jogo: Node
var ponto := {}              # lugares de trabalho (mundo)
var canteiros: Array = []    # posições dos canteiros da horta
var trabalhadores: Array = []
var guardas: Array = []
var animais: Array = []
var _pilhas := {}            # tipo -> nó "Pilha" do galpão
var obra := Vector3.INF      # construção em andamento (construtores e serralheiros vão martelar lá)
var _obra_t := 0.0
var _fila_n := 0             # próxima vaga da fila do prato
var _lod_t := 0.0
var _renasce_t := 0.0
var _rng := RandomNumberGenerator.new()

func montar(o_jogo: Node) -> void:
	jogo = o_jogo
	_rng.seed = 23
	for k: String in PREDIOS:
		var d: Array = PREDIOS[k]
		var g := Construcoes.galpao(d[1], d[2])
		_por(g, d[0], 7.0, String(d[1]))   # o nome deixa entrar (interior em interior.gd)
		_pilhas[d[2]] = g.get_node("Pilha")
		ponto[k] = g.to_global(Vector3(0, 0, 3.2))
	var coz := Construcoes.cozinha()
	_por(coz, COZINHA, 6.0)
	ponto["cozinha_porta"] = coz.to_global(Vector3(0, 0, 1.2))
	ponto["caldeirao"] = coz.to_global(Vector3(-2.4, 0, 2.6))
	ponto["balcao"] = coz.to_global(Vector3(1.2, 0, 1.5))
	ponto["fila"] = coz.to_global(Vector3(1.2, 0, 3.1))
	ponto["fila_dir"] = coz.global_transform.basis.z.normalized()
	ponto["mesa"] = coz
	var art := Construcoes.artesa()
	_por(art, ARTESA, 5.5)
	ponto["tear"] = art.to_global(Vector3(-2.0, 0, 2.7))
	ponto["varal"] = art.to_global(Vector3(2.0, 0, 3.3))
	ponto["manequim"] = art.to_global(Vector3(3.2, 0, 1.6))
	_horta()
	_curral()
	_oficinas()
	_animais_floresta()
	ponto["castelo"] = Vector3(0, 0, -16)
	_gente()

## Põe um prédio virado para o centro da aldeia e registra para a grama e as plantas não nascerem dentro.
func _por(n: Node3D, pos: Vector3, raio: float, nome := "") -> void:
	n.position = pos
	n.rotation.y = atan2(-pos.x, -pos.z)
	add_child(n)
	jogo._fixos.append({"pos": pos, "r": raio, "h": 4.0, "nome": nome if nome != "" else "vila_" + str(jogo._fixos.size())})

func _horta() -> void:
	var r := Node3D.new()
	_por(r, HORTA, 7.5)
	var tipos := ["cenoura", "tomate", "milho", "abobora", "cebola", "trigo"]
	for i in tipos.size():
		var c := Construcoes.canteiro_novo(tipos[i])
		c.position = Vector3(-6.0 + i * 2.4, 0, 0)
		r.add_child(c)
		canteiros.append(r.to_global(Vector3(-6.0 + i * 2.4, 0, 3.4)))
	r.add_child(Construcoes.cerca(15.5, 8.0))
	ponto["horta"] = r.to_global(Vector3(0, 0, 4.5))
	for k in 3:   # pomar: laranjeiras e macieiras atrás da horta
		var t := Construcoes.frutifera(Color(1.0, 0.55, 0.1) if k % 2 == 0 else Color(0.85, 0.12, 0.1))
		t.position = Vector3(-5.0 + k * 5.0, 0, -6.5)
		r.add_child(t)
	var p := Construcoes.parreira()
	p.position = Vector3(0, 0, -10.0)
	r.add_child(p)
	ponto["pomar"] = r.to_global(Vector3(0, 0, -5.0))

func _curral() -> void:
	var r := Node3D.new()
	_por(r, CURRAL, 9.5)
	r.add_child(Construcoes.cerca(18.0, 12.0))   # maior: os animais não ficam apertados
	var cocho := Construcoes.cocho()
	cocho.position = Vector3(6.5, 0, -4.5)
	r.add_child(cocho)
	var feno := Construcoes.feno()
	feno.position = Vector3(-6.5, 0, -4.5)
	feno.scale = Vector3.ONE * 0.7
	r.add_child(feno)
	ponto["curral"] = r.to_global(Vector3(0, 0, 6.8))
	ponto["vaca"] = r.to_global(Vector3(2.0, 0, 0.0))
	var centro := r.global_position
	for t: String in ["vaca", "touro", "porco", "porco", "ovelha", "ovelha", "cavalo", "cavalo_branco", "burro"]:
		_animal(t, centro + Vector3(_rng.randf_range(-4, 4), 0, _rng.randf_range(-3, 3)), centro, 4.6, false)
	# galinheiro com cerquinha, ao lado do curral (mais perto do centro)
	var gpos := Vector3(-43, 0, -8)   # galinheiro do outro lado do caminho oeste
	var g := Node3D.new()
	_por(g, gpos, 4.0)
	g.add_child(Construcoes.cerca(6.0, 5.0))
	var casa := Construcoes.galinheiro()
	casa.position = Vector3(0, 0, -1.4)
	g.add_child(casa)
	ponto["galinheiro"] = g.to_global(Vector3(0, 0, 3.0))
	for i in 6:
		_animal("galinha", g.global_position + Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(-1, 1.5)), g.global_position + Vector3(0, 0, 0.6), 2.0, false)

## Bigorna e suporte de armas na frente da Forja (oficina "Armas") e caldeirão na frente da casa dos magos.
func _oficinas() -> void:
	for f in jogo._fixos:
		if f.nome == "Forja" or f.nome == "Casa3":
			var c: Vector3 = Vector3(f.pos.x, 0, f.pos.z)
			var frente: Vector3 = c - c.normalized() * (float(f.r) + 2.2)
			var lado := Vector3(c.z, 0, -c.x).normalized()
			var r := Node3D.new()
			r.position = frente
			r.rotation.y = atan2(-c.x, -c.z)
			add_child(r)
			if f.nome == "Forja":
				Construcoes.tora(r, Vector3(-1.2, 0, 0), Vector3(-1.2, 0.6, 0), 0.35, Construcoes.mat(Construcoes.MADEIRA))
				Construcoes.caixa(r, Vector3(-1.2, 0.75, 0), Vector3(0.35, 0.22, 0.75), Construcoes.mat(Color(0.2, 0.2, 0.22), false, 0.4))
				Construcoes.caixa(r, Vector3(1.4, 0.9, -0.3), Vector3(1.6, 1.8, 0.2), Construcoes.mat(Construcoes.MADEIRA_ESCURA))
				for i in 4:
					Construcoes.caixa(r, Vector3(0.85 + i * 0.37, 1.1, -0.15), Vector3(0.06, 1.3, 0.06), Construcoes.mat(Color(0.7, 0.72, 0.76), false, 0.3))
				Construcoes._placa(r, "ARMAS", Vector3(1.4, 2.0, -0.18))
				ponto["bigorna"] = r.to_global(Vector3(-1.2, 0, 0.9))
				ponto["suporte"] = r.to_global(Vector3(1.4, 0, 0.6))
			else:
				var cal := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.5
				sm.height = 0.8
				sm.material = Construcoes.mat(Color(0.12, 0.12, 0.13), false, 0.4)
				cal.mesh = sm
				cal.position = Vector3(0, 0.45, 0)
				r.add_child(cal)
				var liq := StandardMaterial3D.new()
				liq.albedo_color = Color(0.4, 1.0, 0.5)
				liq.emission_enabled = true
				liq.emission = Color(0.2, 0.9, 0.35)
				Construcoes.caixa(r, Vector3(0, 0.82, 0), Vector3(0.6, 0.02, 0.6), liq)
				Construcoes.caixa(r, Vector3(1.5, 0.45, 0), Vector3(1.0, 0.9, 0.6), Construcoes.mat(Construcoes.MADEIRA))
				for i in 4:
					Construcoes.cilindro_mesh(r, Vector3(1.15 + i * 0.22, 0.98, 0), 0.05, 0.16, [Color(0.3, 0.5, 1.0), Color(1.0, 0.3, 0.4), Color(0.4, 1.0, 0.4), Color(0.9, 0.7, 0.2)][i])
				Construcoes._placa(r, "POÇÕES", Vector3(1.5, 1.4, 0.32))
				ponto["caldeirao_magico"] = r.to_global(Vector3(0, 0, 0.9))
				ponto["mesa_pocoes"] = r.to_global(Vector3(1.5, 0, 0.8))
			ponto[f.nome + "_lado"] = lado

func _animal(tipo: String, pos: Vector3, centro: Vector3, raio: float, selvagem: bool) -> Animal:
	var a := Animal.new()
	a.tipo = tipo
	a.centro = centro
	a.raio = raio
	a.selvagem = selvagem
	a.jogador = jogo.player
	a.position = pos
	a.rotation.y = _rng.randf() * TAU
	add_child(a)
	animais.append(a)
	return a

## Animais selvagens espalhados pela floresta (e crocodilos na beira do lago).
func _animais_floresta() -> void:
	var lista := {"coelho": 9, "cervo": 4, "corca": 4, "raposa": 3, "lobo": 2}
	for t: String in lista:
		for i in int(lista[t]):
			_animal_selvagem(t)
	if jogo.lago != null:
		for i in 2:
			var a := _rng.randf() * TAU
			var p: Vector3 = jogo.lago.global_position + Vector3(cos(a), 0, sin(a)) * (Lago.raio_em(a) + 1.0)
			_animal("crocodilo", p, p, 3.0, true)

func _animal_selvagem(t: String) -> void:
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(jogo.village_radius + 4.0, jogo.forest_radius - 6.0)
	var p := Vector3(cos(a) * r, 0, sin(a) * r)
	_animal(t, p, p, 14.0 if t != "coelho" else 8.0, true)

## 16 trabalhadores (2 de cada ofício, um homem e uma mulher) e os guardas.
func _gente() -> void:
	var k := 0
	for of: String in Trabalhador.OFICIOS:
		for sx: String in ["m", "f"]:
			var w := Trabalhador.new()
			w.oficio = of
			w.sexo = sx
			w.jogo = jogo
			w.vila = self
			w.position = Vector3(cos(k * 0.4) * 6.0, 0, 6.0 + sin(k * 0.4) * 3.0)
			add_child(w)
			trabalhadores.append(w)
			k += 1
	# dois guardas (um guerreiro e um arqueiro) em cada casa e em cada armazém
	var postos: Array = []
	for f in jogo._fixos:
		if String(f.nome).begins_with("Casa"):
			postos.append([Vector3(f.pos.x, 0, f.pos.z), float(f.r)])
	for k2: String in PREDIOS:
		postos.append([PREDIOS[k2][0], 3.5])
	var i := 0
	for p: Array in postos:
		var c: Vector3 = p[0]
		var frente: Vector3 = c - c.normalized() * (float(p[1]) + 2.0)
		var lado := Vector3(c.z, 0, -c.x).normalized()
		for s: float in [-1.0, 1.0]:
			var g := Guarda.new()
			g.tipo = "guerreiro" if s < 0 else "arqueiro"
			g.sexo = "m" if (i % 2 == 0) == (s < 0) else "f"
			g.jogo = jogo
			g.position = frente + lado * s * 1.6
			add_child(g)
			guardas.append(g)
		i += 1

# ---------- rotina ----------
func periodo(_w: Node) -> String:
	if jogo.ceu == null:
		return "trabalho"
	if jogo.ceu.noite:
		return "noite"
	var h: float = jogo.ceu.hora
	if (h >= ALMOCO.x and h < ALMOCO.y) or (h >= JANTAR.x and h < JANTAR.y):
		return "refeicao"
	return "trabalho"

func _chave_refeicao() -> String:
	return ("almoco" if jogo.ceu.hora < 14.0 else "jantar") + str(jogo.ceu.dia)

## Almoço/jantar: cozinheiros servem no balcão; os outros entram na fila, pegam o prato e comem na mesa.
func rotina_refeicao(w: Trabalhador) -> void:
	if w.oficio == "cozinheiro":
		w.ir(ponto.balcao + Vector3(0.8 if w.sexo == "m" else -0.8, 0, 0))
		w.depois(func(): w.segurar("colher"); w.olhar_para(ponto.fila))
		w.fazer("Interact", 200.0)
		return
	var chave := _chave_refeicao()
	if w.comeu == chave:
		return
	var n := _fila_n
	_fila_n = (_fila_n + 1) % 14
	var fila_p: Vector3 = ponto.fila + (ponto.fila_dir as Vector3) * (0.9 * n)
	w.ir(fila_p)
	w.depois(func(): w.olhar_para(ponto.balcao))
	w.fazer("Idle", 2.0 + n * 1.2)
	w.depois(func(): w.na_esquerda("prato"))
	var mesa: Node3D = ponto.mesa
	var lado := -0.95 if n % 2 == 0 else 0.95
	var lugar := mesa.to_global(Vector3(-2.5 + (n / 2) * 0.85, 0, 6.0 + lado * 1.35))
	w.ir(lugar)
	w.depois(func(): w.olhar_para(mesa.to_global(Vector3(-2.5 + (n / 2) * 0.85, 0, 6.0))))
	w.fazer("Consume", 9.0)
	w.depois(func(): w.na_esquerda(""); w.comeu = chave)

func nova_obra(p: Vector3) -> void:
	obra = p
	_obra_t = 30.0

## Escolhe as próximas tarefas de um trabalhador conforme o ofício.
func planejar(w: Trabalhador) -> void:
	var lado := Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(-1.5, 1.5))
	match w.oficio:
		"construtor", "serralheiro":
			if obra != Vector3.INF and _rng.randf() < 0.85:   # ajuda na construção, só com o martelo
				w.depois(func(): w.segurar("martelo"))
				w.ir(obra + lado * 2.0)
				w.depois(func(): w.olhar_para(obra))
				w.fazer("Fixing_Kneeling", 6.0)
				w.fazer("Sword_Attack", 3.0)
				w.depois(func(): w.segurar(""))
				return
			var tipo := "pedra" if w.oficio == "construtor" else "madeira"
			var alvo = jogo.reservar(tipo, w.global_position, w)
			if alvo == null:
				w.fazer("Idle", 3.0)
				return
			w.depois(func(): w.carrinho("", true))   # vai empurrando o carrinho vazio
			var no: Node3D = alvo.node
			w.ir(no.global_position + (w.global_position - no.global_position).normalized() * 1.6)
			w.depois(func(): w.olhar_para(no.global_position); w.empurrar(false); w.segurar("picareta" if tipo == "pedra" else "machado"))
			for k in 3:
				w.fazer("TreeChopping", 2.0)
				w.depois(func(): jogo.golpear(alvo, false))
			w.depois(func(): w.carrinho(tipo, true))   # põe no carrinho, amarra com a corda e volta empurrando
			w.ir(ponto["pedreira" if tipo == "pedra" else "madeireira"] + lado)
			w.fazer("PickUp_Table", 1.5)
			w.depois(func(): jogo.res[tipo] += 5; w.carrinho("", false); w.segurar(""))
		"fazendeiro":
			var r := _rng.randf()
			if r < 0.55:   # horta: ara com a enxada, rega, colhe com o cesto e leva para Mantimentos
				var c: Vector3 = canteiros[_rng.randi() % canteiros.size()]
				w.depois(func(): w.segurar("enxada"))
				w.ir(c)
				w.fazer("Farm_PlantSeed", 4.0)
				w.fazer("Farm_Watering", 3.0)
				w.depois(func(): w.segurar(""); w.na_esquerda("cesto"))
				w.fazer("Farm_Harvest", 4.0)
				w.ir(ponto.mantimentos + lado, "Walk_Carry")
				w.fazer("PickUp_Table", 1.2)
				w.depois(func(): jogo.res["comida"] += 3; w.na_esquerda(""))
			elif r < 0.75:   # pomar e parreira
				w.ir(ponto.pomar + lado * 2.0)
				w.fazer("Farm_Harvest", 4.0)
				w.depois(func(): w.na_esquerda("cesto"))
				w.ir(ponto.mantimentos + lado, "Walk_Carry")
				w.depois(func(): jogo.res["comida"] += 2; w.na_esquerda(""))
			elif r < 0.88:   # ovos do galinheiro
				w.ir(ponto.galinheiro)
				w.fazer("PickUp_Table", 3.0)
				w.depois(func(): w.na_esquerda("cesto"))
				w.ir(ponto.mantimentos + lado, "Walk_Carry")
				w.depois(func(): jogo.res["comida"] += 2; w.na_esquerda(""))
			else:   # tira leite e cuida dos animais do curral
				w.ir(ponto.curral)
				w.ir(ponto.vaca)
				w.fazer("Fixing_Kneeling", 5.0)
				w.ir(ponto.curral)
				w.ir(ponto.mantimentos + lado, "Walk_Carry")
				w.depois(func(): jogo.res["comida"] += 2)
		"cacador":
			if w.sexo == "f" and _rng.randf() < 0.35 and jogo.lago != null:   # pesca com a lança na beira do lago
				var l: Vector3 = jogo.lago.global_position
				var beira := l + (Vector3.ZERO - l).normalized() * (Lago.RAIO * 0.9)
				w.ir(beira)
				w.depois(func(): w.olhar_para(l))
				w.fazer("Punch_Jab", 6.0)
				w.depois(func(): w.nos_ombros("coelho"))
				w.ir(ponto.acougue + lado, "Walk_Carry")
				w.depois(func(): w.nos_ombros(""); jogo.res["comida"] += 3)
				return
			var presa := _presa(w)
			if presa == null:
				w.fazer("Idle", 4.0)
				return
			presa.reservado = w
			var dist := 11.0 if w.sexo == "m" else 2.0
			w.ir(presa.global_position + (w.global_position - presa.global_position).normalized() * dist, "Jog_Fwd")
			w.depois(func():
				if not is_instance_valid(presa) or presa.morto:
					return
				w.olhar_para(presa.global_position)
				if w.sexo == "m":
					var ik := w.model.find_child("ArcoIK", true, false)
					if ik != null:
						ik.disparar()
				presa.ferir(99))
			w.fazer("Punch_Jab" if w.sexo == "f" else "Idle", 1.0)
			w.ir(presa.global_position + Vector3(0.6, 0, 0))
			w.fazer("PickUp_Table", 1.5)
			w.depois(func():
				if is_instance_valid(presa):
					w.nos_ombros(presa.tipo)
					w.set_meta("carne", presa.carne())
					animais.erase(presa)
					presa.queue_free())
			w.ir(ponto.acougue + lado, "Walk_Carry")
			w.fazer("PickUp_Table", 1.2)
			w.depois(func(): w.nos_ombros(""); jogo.res["comida"] += int(w.get_meta("carne", 4)))
		"cozinheiro":
			var r2 := _rng.randf()
			if r2 < 0.35:
				w.ir(ponto.mantimentos + lado)
				w.fazer("PickUp_Table", 2.0)
				w.depois(func(): w.na_esquerda("cesto"))
			elif r2 < 0.6:
				w.ir(ponto.acougue + lado)
				w.fazer("PickUp_Table", 2.0)
				w.depois(func(): w.na_esquerda("cesto"))
			elif r2 < 0.75:   # leva a refeição do Rei até o castelo
				w.ir(ponto.cozinha_porta)
				w.depois(func(): w.na_esquerda("prato"))
				w.ir(ponto.castelo, "Walk_Carry")
				w.fazer("Interact", 2.0)
				w.depois(func(): w.na_esquerda(""))
			w.ir(ponto.caldeirao, "Walk_Carry" if r2 < 0.6 else "Walk")
			w.depois(func(): w.na_esquerda(""); w.segurar("colher"); w.olhar_para(ponto.cozinha_porta))
			w.fazer("Interact", 8.0)
			w.depois(func(): w.segurar(""))
		"artesao":
			var lugares := ["tear", "varal", "manequim"]
			var lg: String = lugares[_rng.randi() % 3]
			w.ir(ponto[lg])
			w.fazer("Interact" if lg != "varal" else "PickUp_Table", 6.0)
			w.fazer("Idle", 1.5)
		"ferreiro":
			w.depois(func(): w.segurar("martelo"))
			w.ir(ponto.bigorna + lado * 0.3)
			w.fazer("Sword_Regular_A", 7.0)
			w.depois(func(): w.segurar(""))
			w.ir(ponto.suporte, "Walk_Carry")
			w.fazer("PickUp_Table", 2.0)
		"mago":
			if _rng.randf() < 0.5:
				w.ir(ponto.caldeirao_magico + lado * 0.3)
				w.fazer("Spell_Simple_Shoot", 3.0)
				w.fazer("Interact", 5.0)
			else:
				w.ir(ponto.mesa_pocoes)
				w.fazer("Interact", 6.0)

func _presa(w: Node3D) -> Animal:
	var melhor: Animal = null
	var bd := 1e9
	for a: Animal in animais:
		if is_instance_valid(a) and a.selvagem and not a.morto and (a.reservado == null or not is_instance_valid(a.reservado) or a.reservado == w):
			var d := a.global_position.distance_to(w.global_position)
			if d < bd:
				bd = d
				melhor = a
	return melhor

## Golpe ou flecha do jogador num animal perto (caça): devolve true se acertou algum.
func golpe_jogador(p: Vector3, alcance: float, dano: int) -> bool:
	for a: Animal in animais:
		if is_instance_valid(a) and not a.morto and a.global_position.distance_to(p) < alcance:
			if a.ferir(dano):
				abatido(a)
			return true
	return false

## Animal abatido pelo jogador: vira comida e some depois de um tempo.
func abatido(a: Animal) -> void:
	jogo.res["comida"] += a.carne()
	jogo.say("Caça: +%d de comida" % a.carne(), 2.5)
	get_tree().create_timer(15.0).timeout.connect(func():
		if is_instance_valid(a):
			animais.erase(a)
			a.queue_free())

func animal_perto(p: Vector3, alcance: float) -> Animal:
	for a: Animal in animais:
		if is_instance_valid(a) and a.selvagem and not a.morto and a.global_position.distance_to(p) < alcance:
			return a
	return null

func _process(delta: float) -> void:
	_obra_t -= delta
	if _obra_t <= 0.0:
		obra = Vector3.INF
	if periodo(null) != "refeicao":
		_fila_n = 0
	_lod_t -= delta
	if _lod_t <= 0.0:   # longe da câmera: animação parada e animais escondidos (alivia o tablet)
		_lod_t = 0.5
		var cam: Vector3 = jogo.cam.global_position
		for lista: Array in [trabalhadores, guardas, animais]:
			for n in lista:
				if not is_instance_valid(n):
					continue
				var d: float = (n as Node3D).global_position.distance_to(cam)
				var ap := Fit.find_node_of(n, "AnimationPlayer") as AnimationPlayer
				if ap != null:
					ap.active = d < 55.0
				if n is Animal:
					n.visible = d < 95.0
		for tipo: String in _pilhas:   # pilhas dos armazéns crescem com o estoque
			var qtd := 0
			match tipo:
				"pedra":
					qtd = int(jogo.res["pedra"]) / 15
				"madeira":
					qtd = int(jogo.res["madeira"]) / 15
				_:
					qtd = int(jogo.res["comida"]) / 20
			var pilha: Node3D = _pilhas[tipo]
			for i in pilha.get_child_count():
				var it := pilha.get_child(i) as Node3D
				if it.name.begins_with("Item"):
					it.visible = i < qtd + (2 if tipo == "carne" else 0)
	_renasce_t -= delta
	if _renasce_t <= 0.0:   # a floresta repõe os animais caçados
		_renasce_t = 40.0
		animais = animais.filter(func(a): return is_instance_valid(a))
		var conta := 0
		for a: Animal in animais:
			if a.selvagem:
				conta += 1
		if conta < 15:
			_animal_selvagem(["coelho", "coelho", "cervo", "corca", "raposa", "lobo"][_rng.randi() % 6])
