class_name Heroi
## Os 16 personagens jogáveis: corpo realista (Quaternius, CC0) + roupas geradas no Blender
## (scripts/personagens na raiz do repositório) + armas presas nos ossos da mão.

## arma: [arquivo, osso, posição, rotação (graus), comprimento (m), deslocamento ao longo da arma]
const MAO_D := Vector3(-0.03, 0.085, 0.0)     # ponto de pegada (punho fechado) no osso hand_r
const MAO_E := Vector3(0.03, 0.085, 0.0)      # idem no hand_l
const ESPADA := ["Sword.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 1.0, 0.35]
const ESPADAO := ["Sword_Big.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 1.4, 0.5]
const LANCA := ["Spear.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 2.3, 0.5, "lanca"]
const BESTA := ["Besta.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 0.75, 0.0]
# armas do Sketchfab (CC-BY): espada rúnica (Thomas Garzon), Excalibur (JuanWithOutAim), espada maldita (suddel)
const ESPADA_RUNICA := ["Espada_Runica.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 1.3, 0.44]   # mão no meio do cabo
const EXCALIBUR := ["Excalibur.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 1.3, 0.49]
const ESPADA_MALDITA := ["Espada_Maldita.glb", "hand_r", MAO_D, Vector3(90, 0, 0), 1.1, 0.40]
# arco (Sketchfab, CC-BY: Francisco Fischer Pioner): em pé na mão (comprimento no eixo Z do osso, que fica
# vertical com o braço esticado na mira), corda virada para o arqueiro
const ARCO := ["Arco.glb", "hand_l", MAO_E, Vector3.ZERO, 1.15, 0.0, "arco"]   # na mão esquerda, guiado por arco_ik.gd
const ALJAVA := ["Aljava.glb", "spine_03", Vector3(0.12, 0, -0.15), Vector3(0, 0, 0), 0.8, 0.0]
# o escudo gótico tem a ponta em -Y no modelo; o eixo Y do osso aponta para a mão, então gira 180° (Z) para a ponta ficar para baixo
const ESC_GOTICO := ["Shield_Heater.glb", "lowerarm_l", Vector3(-0.12, 0.13, 0), Vector3(0, -90, 180), 0.75, 0.0, "escudo"]
const ESC_REDONDO := ["Shield_Round.glb", "lowerarm_l", Vector3(-0.12, 0.13, 0), Vector3(0, -90, 0), 0.7, 0.0, "escudo"]
static func ORBE(cor: String) -> Array: return ["Orbe_%s.glb" % cor, "hand_l", Vector3(0.1, 0.08, 0.12), Vector3.ZERO, 0.0, 0.0, "magia"]   # mão esquerda com a palma para cima (mao_magia.gd): orbe ou chama
## cajados do Sketchfab (CC-BY): cetro mágico (wellintonfarias) e cajado de cristal (gabriel machiniski)
static func CAJADO_N(arq: String) -> Array: return [arq, "hand_r", MAO_D, Vector3(90, 0, 0), 1.9, 0.25, "cajado"]
static func CAJADO(cor: String) -> Array: return ["Cajado_%s.glb" % cor, "hand_r", MAO_D, Vector3(90, 0, 0), 1.9, 0.25]

static func lista() -> Dictionary:
	return {
		"G1": {"classe": "guerreiro", "sexo": "m", "nome": "Armadura e elmo, espada e escudo", "armas": [ESPADA_RUNICA, ESC_GOTICO]},
		"G2": {"classe": "guerreiro", "sexo": "m", "nome": "Armadura sem elmo, espadão", "armas": [ESPADA_MALDITA]},
		"G3": {"classe": "guerreiro", "sexo": "f", "nome": "Armadura de bronze, espada e escudo", "armas": [EXCALIBUR, ESC_REDONDO]},
		"G4": {"classe": "guerreiro", "sexo": "f", "nome": "Armadura sem elmo, espadão", "armas": [ESPADA_MALDITA]},
		"M1": {"classe": "mago", "sexo": "m", "nome": "Manto azul-marinho e ouro, pelerine e pedras turquesa", "armas": [CAJADO_N("Cetro_Magico.glb"), ORBE("Azul")]},
		"M2": {"classe": "mago", "sexo": "m", "nome": "Casaco cinza com runas de gelo e colar de pedras", "armas": [CAJADO_N("Cetro_Magico.glb"), ORBE("Roxo")]},
		"M3": {"classe": "mago", "sexo": "f", "nome": "Manto das runas: cinza com bordas vermelhas, capuz e peitoral de cobre", "armas": [CAJADO_N("Cajado_Cristal.glb"), ORBE("Rubi")]},
		"M4": {"classe": "mago", "sexo": "f", "nome": "Robe verde, capuz e ombreiras", "armas": [CAJADO_N("Cajado_Cristal.glb"), ORBE("Verde")]},
		"A1": {"classe": "arqueiro", "sexo": "m", "nome": "Verde com couraça de couro, ombreiras de aço e tabardo", "armas": [ARCO, ALJAVA]},
		"A2": {"classe": "arqueiro", "sexo": "m", "nome": "Couro marrom, sem capuz", "armas": [ARCO, ALJAVA]},
		"A4": {"classe": "arqueiro", "sexo": "f", "nome": "Verde com corpete de couro, saia longa e detalhes dourados", "armas": [ARCO, ALJAVA]},
		"A3": {"classe": "arqueiro", "sexo": "f", "nome": "Couro marrom, sem capuz", "armas": [ARCO, ALJAVA]},
		"L1": {"classe": "lanceiro", "sexo": "m", "nome": "Armadura e elmo, lança e escudo", "armas": [LANCA, ESC_REDONDO]},
		"L2": {"classe": "lanceiro", "sexo": "m", "nome": "Couro e capa vermelha, lança", "armas": [LANCA]},
		"L3": {"classe": "lanceiro", "sexo": "f", "nome": "Armadura, lança e escudo", "armas": [LANCA, ESC_GOTICO]},
		"L4": {"classe": "lanceiro", "sexo": "f", "nome": "Couro e capa vermelha, lança", "armas": [LANCA]},
	}

## Animações de cada classe (nomes da Universal Animation Library).
const ANIMS := {
	"guerreiro": {"idle": "Sword_Idle", "run": "Jog_Fwd", "atk": "Sword_Regular_A", "hit": "Hit_Chest", "morte": "Death01", "def": "Idle_Shield", "corre": "Sprint"},
	"lanceiro": {"idle": "Sword_Idle", "run": "Jog_Fwd", "atk": "Punch_Jab", "hit": "Hit_Chest", "morte": "Death01", "def": "Idle_Shield", "corre": "Sprint"},
	"arqueiro": {"idle": "Idle", "run": "Jog_Fwd", "atk": "", "hit": "Hit_Chest", "morte": "Death01", "def": "Idle_Shield", "corre": "Sprint"},
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
			var loop := n.begins_with("Idle") or n.begins_with("Jog") or n.begins_with("Walk") or n.begins_with("Sprint") or n.begins_with("Sitting_Idle") or n in ["Sword_Idle", "Pistol_Idle", "Spell_Simple_Idle"]
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
## extras (personalização do mago, escolhida no menu): {"mao": "orbe" | "chama", "acess": "" | "mascara" | "coroa"}
static func montar(id: String, armado := true, sem_nada := false, extras := {}) -> Node3D:   # sem_nada: nenhuma arma/escudo/orbe
	var info: Dictionary = lista()[id]
	var m: Node3D = load("res://models/herois/%s.gltf" % id).instantiate()
	m.name = "Model"
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	m.add_child(ap)
	ap.add_animation_library(&"", _biblioteca())
	_pele(m)
	var sk := Fit.find_node_of(m, "Skeleton3D") as Skeleton3D
	for a in info.armas:
		if sem_nada:
			break
		if armado or a.size() > 6:   # desarmado: só fica o que não é arma de mão
			_prender(sk, a, String(extras.get("mao", "orbe")))
	var capuz := m.find_child("Capuz", true, false) != null
	match String(extras.get("acess", "")):
		"mascara":
			_mascara(sk)
		"coroa":
			_coroa_galhos(sk, capuz)
	return m

const CABELO := Color(0.16, 0.09, 0.06)   # castanho escuro (sobrancelha e cabelo)
const PELE := Color(0.66, 0.48, 0.38)   # multiplica a textura da pele (1,1,1 = original, que saía clara demais no tablet)

## Troca o material do corpo por um fosco, com cor de pele mais forte e sem brilho branco.
static func _pele(raiz: Node) -> void:
	var malhas: Array = []
	Fit._collect(raiz, malhas)
	for mi: MeshInstance3D in malhas:
		if mi.mesh == null:
			continue
		if mi.name == "Capa":   # pano fino de dupla face: a própria sombra fazia manchas e serrilhado
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in mi.mesh.get_surface_count():
			var orig := mi.mesh.surface_get_material(i) as StandardMaterial3D
			if orig != null and orig.resource_name.begins_with("MI_Hair"):   # sobrancelha/cabelo: a cor vem no COLOR_1, que o Godot ignora
				var cab := orig.duplicate() as StandardMaterial3D
				cab.vertex_color_use_as_albedo = false
				cab.albedo_color = CABELO
				cab.metallic_specular = 0.2
				mi.set_surface_override_material(i, cab)
				continue
			if orig == null or not orig.resource_name.begins_with("MI_Superhero"):
				continue
			var mat := orig.duplicate() as StandardMaterial3D
			mat.vertex_color_use_as_albedo = false
			mat.albedo_color = PELE
			mat.metallic = 0.0
			mat.metallic_texture = null
			mat.roughness = 0.85
			mat.roughness_texture = null
			mat.metallic_specular = 0.2
			mi.set_surface_override_material(i, mat)

static func _esconder_material(raiz: Node, nome: String) -> void:
	var some := StandardMaterial3D.new()
	some.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	some.albedo_color = Color(0, 0, 0, 0)
	var malhas: Array = []
	Fit._collect(raiz, malhas)
	for mi: MeshInstance3D in malhas:
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m != null and m.resource_name == nome:
				mi.set_surface_override_material(i, some)

## Máscara de chamas (preta, borda azul à esquerda e vermelha à direita, chama no topo), presa à cabeça.
## Feita numa grade curvada em volta do rosto, com os dois buracos dos olhos.
static func _mascara(sk: Skeleton3D) -> void:
	var preto := StandardMaterial3D.new()
	preto.albedo_color = Color(0.06, 0.06, 0.07)
	preto.roughness = 0.4
	preto.metallic = 0.3
	preto.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cores := [Color(0.15, 0.35, 1.0), Color(1.0, 0.22, 0.08)]
	var st := [SurfaceTool.new(), SurfaceTool.new(), SurfaceTool.new()]   # preto, azul, vermelho
	for t: SurfaceTool in st:
		t.begin(Mesh.PRIMITIVE_TRIANGLES)
	var raio := 0.112
	var cy := 0.10
	var cz := -0.008
	var nu := 44
	var nv := 26
	var topo := func(xn: float) -> float:   # borda de cima com bicos de chama
		return 0.135 + 0.035 * maxf(0.0, sin(absf(xn) * 3.0 * PI)) * (1.0 - absf(xn) * 0.4) + 0.05 * maxf(0.0, 1.0 - absf(xn) * 6.0)
	var baixo := func(xn: float) -> float:   # borda de baixo: ponta no nariz, sobe para os lados
		return 0.07 - 0.025 * maxf(0.0, 1.0 - absf(xn) * 4.0) + 0.03 * absf(xn)
	for i in nu:
		for j in nv:
			var u0 := -1.0 + 2.0 * i / nu
			var u1 := -1.0 + 2.0 * (i + 1) / nu
			var y0 := 0.04 + 0.18 * j / nv
			var y1 := 0.04 + 0.18 * (j + 1) / nv
			var uc := (u0 + u1) * 0.5
			var yc := (y0 + y1) * 0.5
			var tp: float = topo.call(uc)
			var bx: float = baixo.call(uc)
			if yc > tp or yc < bx:
				continue
			var xs := sin(uc * 1.2) * raio
			var olho := Vector2((absf(xs) - 0.034) / 0.019, (yc - cy) / 0.011)
			if olho.length() < 1.0:
				continue
			var borda := minf(tp - yc, yc - bx) < 0.012 or olho.length() < 1.35
			var k := 0 if not borda else (1 if uc < 0.0 else 2)
			var cantos := [Vector2(u0, y0), Vector2(u1, y0), Vector2(u1, y1), Vector2(u0, y1)]
			var vs: Array = []
			for c: Vector2 in cantos:
				var a := c.x * 1.2
				vs.append(Vector3(sin(a) * raio, c.y, cz + cos(a) * raio))
			for q: int in [0, 1, 2, 0, 2, 3]:
				var vq: Vector3 = vs[q]
				var t: SurfaceTool = st[k]
				t.set_normal((vq - Vector3(0, vq.y, cz)).normalized())
				t.add_vertex(vq)
	var mesh := ArrayMesh.new()
	var mats := [preto]
	for c: Color in cores:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c * 0.6
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mats.append(m)
	for k in 3:
		var arr: Array = (st[k] as SurfaceTool).commit_to_arrays()
		if (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > 0:
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mats[k])
	_peca(sk, "head", mesh, Vector3.ZERO, Vector3.ONE)
	var fogo := StandardMaterial3D.new()   # chaminha no topo da máscara
	fogo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fogo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fogo.albedo_color = Color(1.0, 0.5, 0.15)
	var fm := SphereMesh.new()
	fm.radius = 0.014
	fm.height = 0.06
	fm.material = fogo
	_peca(sk, "head", fm, Vector3(0, 0.205, cz + raio + 0.004), Vector3.ONE)

## Coroa de galhos dourada com um rubi na testa (por cima do capuz, se houver).
static func _coroa_galhos(sk: Skeleton3D, capuz: bool) -> void:
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = Color(1.0, 0.78, 0.3)
	ouro.metallic = 0.9
	ouro.roughness = 0.25
	var rubi := StandardMaterial3D.new()
	rubi.albedo_color = Color(0.85, 0.05, 0.08)
	rubi.emission_enabled = true
	rubi.emission = Color(0.5, 0.0, 0.02)
	rubi.metallic = 0.3
	rubi.roughness = 0.1
	var r := 0.118 if not capuz else 0.152
	var y0 := 0.17 if not capuz else 0.2
	for k in 15:   # aro na frente da cabeça
		var a := -1.9 + 3.8 * k / 14.0
		var b := BoxMesh.new()
		b.size = Vector3(0.03, 0.022, 0.012)
		b.material = ouro
		_peca_rot(sk, b, Vector3(sin(a) * r, y0, cos(a) * r - 0.01), Vector3(0, a, 0))
	var galho := func(de: Vector3, ate: Vector3, grossura: float) -> void:
		var cm := CylinderMesh.new()
		cm.top_radius = grossura * 0.25
		cm.bottom_radius = grossura
		cm.height = de.distance_to(ate)
		cm.material = ouro
		var d := (ate - de).normalized()
		var q := Quaternion(Vector3.UP, d)
		_peca_rot(sk, cm, (de + ate) * 0.5, q.get_euler())
	for s: float in [-1.0, 1.0]:   # galhos principais com 3 pontas cada
		var base := Vector3(s * r * 0.75, y0, r * 0.55)
		var topo_g := base + Vector3(s * 0.09, 0.17, -0.05)
		galho.call(base, topo_g, 0.012)
		for t: float in [0.35, 0.6, 0.85]:
			var p := base.lerp(topo_g, t)
			galho.call(p, p + Vector3(s * 0.035, 0.06, 0.02), 0.007)
	for s: float in [-1.0, 1.0]:   # duas pontas do meio
		galho.call(Vector3(s * 0.02, y0 + 0.01, r), Vector3(s * 0.045, y0 + 0.09, r - 0.01), 0.008)
	var g := SphereMesh.new()
	g.radius = 0.014
	g.height = 0.05
	g.material = rubi
	_peca(sk, "head", g, Vector3(0, y0 + 0.02, r + 0.008), Vector3(1, 1, 0.6))

static func _peca_rot(sk: Skeleton3D, malha: Mesh, pos: Vector3, rot: Vector3) -> void:
	_peca(sk, "head", malha, pos, Vector3.ONE)
	var ba := sk.get_child(sk.get_child_count() - 1)
	if ba != null and ba.get_child_count() > 0:
		(ba.get_child(0) as Node3D).rotation = rot

static func tipo_da(x: Array) -> String:
	return String(x[6]) if x.size() > 6 else ""

const ARCO_IK := preload("res://scripts/arco_ik.gd")

const MAO_MAGIA := preload("res://scripts/mao_magia.gd")

static func _prender(sk: Skeleton3D, x: Array, mao := "orbe") -> void:
	if tipo_da(x) == "magia":
		var mm := MAO_MAGIA.new()
		mm.name = "MaoMagia"
		sk.add_child(mm)
		var ef: Node3D
		if mao == "chama":
			ef = MAO_MAGIA.criar_chama()
			mm.chama = true
		else:
			ef = load("res://models/armas/" + x[0]).instantiate()
		ef.top_level = true
		mm.add_child(ef)
		mm.efeito = ef
		return
	if tipo_da(x) == "arco":
		var ik := ARCO_IK.new()
		ik.name = "ArcoIK"
		sk.add_child(ik)
		var a: Node3D = load("res://models/armas/" + x[0]).instantiate()
		a.top_level = true
		ik.add_child(a)
		ik.arco = a
		if ResourceLoader.exists("res://models/armas/Flecha.glb"):   # flecha encaixada na corda durante a puxada
			var f := Node3D.new()
			f.top_level = true
			f.visible = false
			var fm: Node3D = load("res://models/armas/Flecha.glb").instantiate()
			fm.rotation.y = PI / 2.0   # ponta do modelo em +X -> -Z
			f.add_child(fm)
			var bb := _caixa(f)
			fm.position.z = -bb.end.z   # a cauda (lado +Z) fica na origem, na corda
			ik.add_child(f)
			ik.flecha = f
		return
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
	if String(x[0]).begins_with("Cajado") or tipo_da(x) == "cajado":   # ponta do cajado (cristal em +Y): de onde sai a magia
		var mk := Marker3D.new()
		mk.name = "Ponta"
		piv.add_child(mk)
		mk.position = Vector3(0, x[5] + x[4] * 0.5, 0)
	if x[0] == "Cetro_Magico.glb":   # tira a bolha branca translúcida (aura) em volta da ponta do cetro
		_esconder_material(w, "Material_29")
	var tipo: String = x[6] if x.size() > 6 else ""
	if tipo != "":
		ba.name = tipo.capitalize()
	if tipo == "escudo":   # duas alças de couro em volta do antebraço, presas atrás do escudo
		var couro := StandardMaterial3D.new()
		couro.albedo_color = Color(0.22, 0.12, 0.05)
		couro.roughness = 0.8
		for yy: float in [0.07, 0.19]:
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

## O Rei: corpo do G2 (mais forte e maior que os heróis), sentado, com armadura e coroa de ouro.
## Família real (Salão do Rei): corpo de um herói, sem armas, com coroa (ou tiara) de ouro.
## armadura: peças douradas no peito, ombros, braços e pernas (só o Rei).
static func realeza(id: String, altura: float, armadura: bool, coroa_r: float) -> Node3D:
	var m := montar(id, false, true)
	var sk := Fit.find_node_of(m, "Skeleton3D") as Skeleton3D
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = Color(1.0, 0.8, 0.25)
	ouro.metallic = 0.9
	ouro.roughness = 0.25
	ouro.emission_enabled = true
	ouro.emission = Color(0.5, 0.35, 0.05)
	if armadura:
		_peca(sk, "spine_03", _esfera(ouro), Vector3(0, 0.02, 0.05), Vector3(0.36, 0.34, 0.25))     # peitoral
		_peca(sk, "spine_01", _esfera(ouro), Vector3(0, 0.03, 0.04), Vector3(0.3, 0.3, 0.22))       # barriga blindada
		for lado: String in ["l", "r"]:
			_peca(sk, "upperarm_" + lado, _esfera(ouro), Vector3(0, 0.03, 0), Vector3(0.22, 0.2, 0.22))   # ombreira
			_peca(sk, "lowerarm_" + lado, _esfera(ouro), Vector3(0, 0.12, 0), Vector3(0.1, 0.24, 0.1))    # braçadeira
			_peca(sk, "thigh_" + lado, _esfera(ouro), Vector3(0, 0.15, 0), Vector3(0.17, 0.34, 0.17))     # coxote
			_peca(sk, "calf_" + lado, _esfera(ouro), Vector3(0, 0.16, 0), Vector3(0.13, 0.32, 0.13))      # canela
	var coroa := CylinderMesh.new()
	coroa.top_radius = 0.115 * coroa_r
	coroa.bottom_radius = 0.095 * coroa_r
	coroa.height = 0.07 * coroa_r
	coroa.material = ouro
	_peca(sk, "head", coroa, Vector3(0, 0.2, 0.01), Vector3.ONE)
	for i in 5:   # pontas da coroa
		var ponta := CylinderMesh.new()
		ponta.top_radius = 0.0
		ponta.bottom_radius = 0.02 * coroa_r
		ponta.height = 0.07 * coroa_r
		ponta.material = ouro
		var a := TAU * i / 5.0
		_peca(sk, "head", ponta, Vector3(cos(a) * 0.105 * coroa_r, 0.2 + 0.06 * coroa_r, 0.01 + sin(a) * 0.105 * coroa_r), Vector3.ONE)
	Fit.to_height(m, altura)
	return m

static func rei() -> Node3D:
	var m := realeza("G2", 2.6, true, 1.0)
	m.scale = Vector3(m.scale.x * 1.2, m.scale.y, m.scale.z * 1.2)   # mais forte
	return m

static func _esfera(mat: Material) -> SphereMesh:
	var sp := SphereMesh.new()
	sp.radius = 0.5
	sp.height = 1.0
	sp.material = mat
	return sp

static func _peca(sk: Skeleton3D, osso: String, malha: Mesh, pos: Vector3, esc: Vector3) -> void:
	if sk == null:
		return
	if sk.find_bone(osso) < 0:
		osso = osso.capitalize()   # nos heróis a cabeça é "Head" (a coroa sumia por isso)
		if sk.find_bone(osso) < 0:
			return
	var ba := BoneAttachment3D.new()
	ba.bone_name = osso
	sk.add_child(ba)
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.position = pos
	mi.scale = esc
	ba.add_child(mi)
