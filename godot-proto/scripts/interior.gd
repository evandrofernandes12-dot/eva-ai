class_name Interior
## Interiores das construções da aldeia (gerados por código). Cada um é uma sala fechada,
## longe do mapa; o jogador entra pelo botão ENTRAR e sai pelo botão SAIR.

const BARRIL := preload("res://models/Barrel.glb")
const FOGO := preload("res://models/Bonfire_Lit.glb")

## nome do nó em "Aldeia": título, largura, fundo, altura (m), cor do piso, cor das paredes, cor do tapete
const SALAS := {
	"SalaoDoChefe": {"nome": "Salão do Rei", "w": 26.0, "d": 22.0, "alt": 8.0, "piso": Color(0.5, 0.48, 0.46), "parede": Color(0.62, 0.6, 0.56), "tapete": Color(0.13, 0.22, 0.52)},
	"Casa1": {"nome": "Casa", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.45, 0.32, 0.2), "parede": Color(0.74, 0.62, 0.46), "tapete": Color(0.62, 0.15, 0.12)},
	"Casa2": {"nome": "Casa", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.4, 0.34, 0.22), "parede": Color(0.55, 0.68, 0.5), "tapete": Color(0.18, 0.45, 0.25)},
	"Casa3": {"nome": "Casa do Alquimista", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.42, 0.34, 0.26), "parede": Color(0.52, 0.6, 0.78), "tapete": Color(0.18, 0.28, 0.6)},
	"LoteCasa": {"nome": "Casa", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.5, 0.36, 0.22), "parede": Color(0.8, 0.7, 0.52), "tapete": Color(0.55, 0.35, 0.15)},
	"LoteEstalagem": {"nome": "Estalagem", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.38, 0.24, 0.14), "parede": Color(0.75, 0.5, 0.38), "tapete": Color(0.5, 0.12, 0.12)},
	"LoteSerraria": {"nome": "Serraria", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.5, 0.4, 0.26), "parede": Color(0.7, 0.55, 0.35), "tapete": Color(0.4, 0.3, 0.15)},
	"Moinho": {"nome": "Moinho", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.55, 0.5, 0.42), "parede": Color(0.9, 0.86, 0.76), "tapete": Color(0.55, 0.5, 0.4)},
	"Barraca": {"nome": "Barraca", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.5, 0.42, 0.3), "parede": Color(0.85, 0.72, 0.5), "tapete": Color(0.6, 0.45, 0.25)},
	"Forja": {"nome": "Forja", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.27, 0.26, 0.26), "parede": Color(0.4, 0.37, 0.36), "tapete": Color(0.2, 0.2, 0.2)},
}
const MADEIRA := Color(0.42, 0.27, 0.14)
const PEDRA := Color(0.45, 0.44, 0.46)
const OURO := Color(0.95, 0.75, 0.2)
const AZUL_REAL := Color(0.13, 0.22, 0.52)

static var _autoluz := 0.0   # fração da cor que "brilha sozinha": casas e forja são pequenas e escuras

static func _mat(cor: Color, brilho := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.85
	if _autoluz > 0.0 and not brilho:
		m.emission_enabled = true
		m.emission = cor * _autoluz
	if brilho:
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = 1.2
	return m

## Caixa (com colisão opcional). `visivel` false = só colisão.
static func caixa(pai: Node3D, pos: Vector3, tam: Vector3, cor: Color, colide := false, visivel := true, brilho := false) -> void:
	if visivel:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = tam
		bm.material = _mat(cor, brilho)
		mi.mesh = bm
		mi.position = pos
		pai.add_child(mi)
	if colide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = tam
		cs.shape = sh
		sb.position = pos
		sb.add_child(cs)
		pai.add_child(sb)

static func coluna(pai: Node3D, pos: Vector3, raio: float, alt: float, cor: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raio
	cm.bottom_radius = raio
	cm.height = alt
	cm.material = _mat(cor)
	mi.mesh = cm
	mi.position = pos + Vector3(0, alt * 0.5, 0)
	pai.add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = raio
	sh.height = alt
	cs.shape = sh
	sb.position = mi.position
	sb.add_child(cs)
	pai.add_child(sb)

static func modelo(pai: Node3D, cena: PackedScene, pos: Vector3, alt: float, giro := 0.0) -> Node3D:
	# A sala ainda não está na árvore de cena: Fit.to_height mediria errado (sem global_transform) e o barril
	# e a fogueira saíam gigantes, atravessando a casa. Heroi._caixa mede o modelo fora da árvore.
	var n: Node3D = cena.instantiate()
	pai.add_child(n)
	var bb := Heroi._caixa(n)
	var s := alt / maxf(bb.size.y, 0.0001)
	n.scale = Vector3.ONE * s
	n.position = pos - Vector3(0, bb.position.y * s, 0)
	n.rotation.y = giro
	return n

static func luz(pai: Node3D, pos: Vector3, cor: Color, energia: float, alcance: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = cor
	l.light_energy = energia
	l.omni_range = alcance
	pai.add_child(l)

static func cilindro(pai: Node3D, pos: Vector3, raio: float, alt: float, cor: Color, colide := false) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raio
	cm.bottom_radius = raio
	cm.height = alt
	cm.material = _mat(cor)
	mi.mesh = cm
	mi.position = pos + Vector3(0, alt * 0.5, 0)
	pai.add_child(mi)
	if colide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = raio
		sh.height = alt
		cs.shape = sh
		sb.position = mi.position
		sb.add_child(cs)
		pai.add_child(sb)

## Degraus visuais descendo de `topo` (borda de cima, na altura `alt`) na direção horizontal `dir`,
## mais uma rampa invisível com colisão (o personagem não sobe degraus de verdade).
static func escada(pai: Node3D, topo: Vector3, dir: Vector3, run: float, alt: float, larg: float, cor: Color, n := 7) -> void:
	var ab := Vector3(absf(dir.x), 0, absf(dir.z))
	var pe := Vector3(absf(dir.z), 0, absf(dir.x))
	for i in n:
		var h: float = alt * (1.0 - (i + 0.5) / n)
		var c := topo + dir * ((i + 0.5) * run / n)
		caixa(pai, Vector3(c.x, h * 0.5, c.z), ab * (run / n) + pe * larg + Vector3(0, h, 0), cor)
	var s := (dir * run + Vector3(0, -alt, 0)).normalized()      # sentido da descida
	var nm := (dir * alt + Vector3(0, run, 0)).normalized()      # perpendicular à rampa, para cima
	var bx := nm.cross(s)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(larg, 0.2, sqrt(run * run + alt * alt))
	cs.shape = sh
	sb.add_child(cs)
	sb.transform = Transform3D(Basis(bx, nm, s), Vector3(topo.x, alt, topo.z) + dir * (run * 0.5) + Vector3(0, -alt * 0.5, 0) - nm * 0.1)
	pai.add_child(sb)

## Monta a sala. Devolve a raiz; `rei` (meta) é o nó do Rei, quando existe.
static func construir(id: String) -> Node3D:
	_autoluz = 0.0 if id == "SalaoDoChefe" else 0.55
	var s: Dictionary = SALAS[id]
	var w: float = s.w
	var d: float = s.d
	var alt: float = s.alt
	var raiz := Node3D.new()
	raiz.name = "Interior_" + id
	var pa: Color = s.parede
	var tap: Color = s.tapete
	caixa(raiz, Vector3(0, -0.5, 0), Vector3(w, 1.0, d), s.piso, true)                         # piso
	caixa(raiz, Vector3(0, alt * 0.5, -d * 0.5), Vector3(w, alt, 0.5), pa, true)               # paredes
	caixa(raiz, Vector3(0, alt * 0.5, d * 0.5), Vector3(w, alt, 0.5), pa, true)
	caixa(raiz, Vector3(-w * 0.5, alt * 0.5, 0), Vector3(0.5, alt, d), pa, true)
	caixa(raiz, Vector3(w * 0.5, alt * 0.5, 0), Vector3(0.5, alt, d), pa, true)
	var castelo := id == "SalaoDoChefe"
	# teto: madeira escura no castelo; nas casas, liso e claro como as paredes (sem nada pendurado)
	caixa(raiz, Vector3(0, alt + 0.25, 0), Vector3(w + 1.0, 0.5, d + 1.0), MADEIRA.darkened(0.2) if castelo else pa.lightened(0.15))
	caixa(raiz, Vector3(0, 1.2, d * 0.5 - 0.3), Vector3(1.8, 2.4, 0.08), MADEIRA.darkened(0.25))       # porta (folha)
	if castelo:   # nas casas, sem verga nem batentes de madeira escura (pareciam vigas)
		caixa(raiz, Vector3(0, 2.5, d * 0.5 - 0.3), Vector3(2.2, 0.2, 0.12), Color(0.2, 0.12, 0.06))       # verga
		for sx: float in [-1.0, 1.0]:
			caixa(raiz, Vector3(sx, 1.25, d * 0.5 - 0.3), Vector3(0.15, 2.5, 0.12), Color(0.2, 0.12, 0.06)) # batentes
	caixa(raiz, Vector3(0.6, 1.1, d * 0.5 - 0.35), Vector3(0.1, 0.1, 0.1), OURO)                        # maçaneta
	caixa(raiz, Vector3(0, 0.02, d * 0.5 - 1.3), Vector3(2.4, 0.04, 1.4), Color(0.3, 0.12, 0.1))       # capacho
	var janelas := 2 if id != "SalaoDoChefe" else 4
	for lado: float in [-1.0, 1.0]:                                                                    # janelas luminosas
		for i in janelas:
			var z := -d * 0.5 + (i + 1.0) * d / (janelas + 1.0)
			caixa(raiz, Vector3(lado * (w * 0.5 - 0.27), alt * 0.55, z), Vector3(0.05, alt * 0.35, 1.2), Color(0.75, 0.88, 1.0), false, true, true)
			if castelo:   # moldura de madeira só no castelo
				caixa(raiz, Vector3(lado * (w * 0.5 - 0.3), alt * 0.55, z), Vector3(0.08, 0.1, 1.5), MADEIRA.darkened(0.3))
	luz(raiz, Vector3(0, alt - 1.4, 0), Color(1.0, 0.88, 0.7), 1.3, maxf(w, d) * 1.2)
	if id != "SalaoDoChefe":    # luzes extras nos cantos: as paredes ficam claras até o teto
		luz(raiz, Vector3(-w * 0.3, 2.0, -d * 0.3), Color(1.0, 0.9, 0.75), 0.7, 9.0)
		luz(raiz, Vector3(w * 0.3, 2.0, d * 0.3), Color(1.0, 0.9, 0.75), 0.7, 9.0)
	match id:
		"SalaoDoChefe":
			_salao(raiz, w, d, alt, tap)
		"Forja":
			_forja(raiz, w, d, alt)
		"Casa3":   # casa do alquimista (poções, caldeirão, cristais)
			_alquimia(raiz, w, d, alt, tap)
		_:
			_casa(raiz, w, d, alt, tap)
	return raiz

## Casa: cama, lareira, quadros, sofá, mesa com 4 cadeiras. Faixa da porta (|x| < 2,2 e z > 2,2) livre; `tap` = cor do estofado.
static func _cadeira(r: Node3D, x: float, z: float, olha: float) -> void:   # olha: 1 = encosto ao sul, -1 = ao norte
	caixa(r, Vector3(x, 0.45, z), Vector3(0.5, 0.06, 0.5), MADEIRA.lightened(0.1), true)
	for dx: float in [-0.21, 0.21]:
		for dz: float in [-0.21, 0.21]:
			caixa(r, Vector3(x + dx, 0.21, z + dz), Vector3(0.05, 0.42, 0.05), MADEIRA.darkened(0.2))
	caixa(r, Vector3(x, 0.78, z + 0.23 * olha), Vector3(0.5, 0.6, 0.05), MADEIRA.lightened(0.1))

static func _quadro(r: Node3D, pos: Vector3, larg: float, alt: float, giro: float, ceu: Color, terra: Color) -> void:
	var q := Node3D.new()
	q.position = pos
	q.rotation.y = giro
	r.add_child(q)
	caixa(q, Vector3.ZERO, Vector3(larg, alt, 0.06), MADEIRA.darkened(0.3))
	caixa(q, Vector3(0, alt * 0.12, 0.035), Vector3(larg - 0.16, alt - 0.16 - alt * 0.24, 0.02), ceu)
	caixa(q, Vector3(0, -alt * 0.27, 0.04), Vector3(larg - 0.16, alt * 0.3, 0.02), terra)
	caixa(q, Vector3(larg * 0.2, alt * 0.12, 0.05), Vector3(0.22, 0.22, 0.02), Color(1.0, 0.9, 0.4))

static func _casa(r: Node3D, w: float, d: float, alt: float, tap: Color) -> void:
	var zn := -d * 0.5            # parede norte (face interna em zn + 0,25)
	cilindro(r, Vector3(0, 0, 0.3), 1.9, 0.03, tap.lightened(0.15))                              # tapete redondo
	# cama no canto noroeste, com cabeceira baixa
	var bx := -5.3
	caixa(r, Vector3(bx, 0.25, -2.6), Vector3(2.1, 0.5, 3.3), MADEIRA, true)
	caixa(r, Vector3(bx, 0.6, -2.6), Vector3(1.95, 0.22, 3.1), Color(0.93, 0.91, 0.86))
	caixa(r, Vector3(bx, 0.78, -3.85), Vector3(1.3, 0.16, 0.5), Color(1, 1, 1))
	caixa(r, Vector3(bx, 0.74, -2.0), Vector3(2.0, 0.08, 1.8), tap)
	caixa(r, Vector3(bx, 0.55, zn + 0.45), Vector3(2.2, 1.1, 0.12), MADEIRA.lightened(0.1))
	_quadro(r, Vector3(bx, 2.1, zn + 0.3), 1.8, 1.2, 0.0, Color(0.55, 0.75, 0.95), Color(0.3, 0.55, 0.25))
	# criado-mudo com abajur
	caixa(r, Vector3(bx + 1.5, 0.3, zn + 0.8), Vector3(0.6, 0.6, 0.6), MADEIRA, true)
	caixa(r, Vector3(bx + 1.5, 0.75, zn + 0.8), Vector3(0.2, 0.3, 0.2), Color(1.0, 0.85, 0.5), false, true, true)
	# lareira na parede norte, com moldura, fogo e quadro ao lado
	var lx := 3.0
	caixa(r, Vector3(lx, 1.1, zn + 0.7), Vector3(3.2, 2.2, 0.9), PEDRA, true)
	caixa(r, Vector3(lx, 0.6, zn + 1.18), Vector3(1.5, 0.9, 0.05), Color(0.04, 0.03, 0.03))
	modelo(r, FOGO, Vector3(lx, 0.05, zn + 1.5), 0.75)
	luz(r, Vector3(lx, 1.2, zn + 2.2), Color(1.0, 0.55, 0.2), 1.3, 6.5)
	_quadro(r, Vector3(-0.4, 2.0, zn + 0.3), 1.2, 0.9, 0.0, Color(0.95, 0.8, 0.55), Color(0.45, 0.3, 0.2))
	# sofá de frente para a lareira
	var sz := -0.6
	caixa(r, Vector3(lx, 0.25, sz), Vector3(3.0, 0.5, 1.0), tap.darkened(0.15), true)
	caixa(r, Vector3(lx, 0.55, sz), Vector3(2.7, 0.2, 0.85), tap)
	caixa(r, Vector3(lx, 0.8, sz + 0.5), Vector3(3.0, 0.7, 0.22), tap.darkened(0.1), true)
	for sx: float in [-1.4, 1.4]:
		caixa(r, Vector3(lx + sx, 0.45, sz), Vector3(0.25, 0.7, 1.0), tap.darkened(0.2), true)
	# mesa com 4 cadeiras (leste, entre o sofá e a parede da frente)
	var mx := 4.3
	var mz := 2.1
	caixa(r, Vector3(mx, 0.78, mz), Vector3(1.7, 0.08, 1.0), MADEIRA, true)
	for dx: float in [-0.75, 0.75]:
		for dz: float in [-0.4, 0.4]:
			caixa(r, Vector3(mx + dx, 0.37, mz + dz), Vector3(0.08, 0.74, 0.08), MADEIRA.darkened(0.2))
	cilindro(r, Vector3(mx - 0.3, 0.82, mz), 0.18, 0.07, Color(0.85, 0.65, 0.3))
	cilindro(r, Vector3(mx + 0.4, 0.82, mz + 0.1), 0.07, 0.13, Color(0.75, 0.75, 0.8))
	for cx: float in [-0.45, 0.45]:
		_cadeira(r, mx + cx, mz - 0.95, 1.0)
		_cadeira(r, mx + cx, mz + 0.95, -1.0)
	# parede oeste: quadro grande e baú; barris junto à porta
	_quadro(r, Vector3(-w * 0.5 + 0.3, 2.0, 0.5), 1.8, 1.2, PI * 0.5, Color(0.7, 0.8, 0.95), Color(0.25, 0.45, 0.3))
	caixa(r, Vector3(-5.0, 0.35, d * 0.5 - 1.2), Vector3(1.4, 0.7, 0.8), MADEIRA.darkened(0.1), true)
	caixa(r, Vector3(-5.0, 0.75, d * 0.5 - 1.2), Vector3(1.5, 0.1, 0.9), OURO.darkened(0.3))
	modelo(r, BARRIL, Vector3(5.5, 0, d * 0.5 - 1.1), 1.0)

static func _forja(r: Node3D, w: float, d: float, alt: float) -> void:
	var ferro := Color(0.22, 0.22, 0.25)
	var zf := -d * 0.5 + 1.3
	# fornalha de pedra com boca de brasa, coifa em pirâmide e chaminé
	caixa(r, Vector3(0, 0.55, zf), Vector3(3.6, 1.1, 2.2), PEDRA.darkened(0.15), true)
	caixa(r, Vector3(0, 1.12, zf + 0.2), Vector3(2.4, 0.06, 1.4), Color(1.0, 0.42, 0.08), false, true, true)   # brasa
	for i in 9:   # carvões acesos por cima da brasa
		var s := SphereMesh.new()
		s.radius = 0.12
		s.height = 0.18
		s.material = _mat(Color(1.0, 0.3, 0.05) if i % 3 else Color(0.08, 0.06, 0.05), i % 3 != 0)
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = Vector3(-0.9 + (i % 5) * 0.45, 1.18, zf - 0.2 + (i / 5) * 0.6)
		r.add_child(mi)
	var coifa := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.55
	cm.bottom_radius = 2.2
	cm.height = 1.3
	cm.radial_segments = 4
	cm.material = _mat(PEDRA.darkened(0.3))
	coifa.mesh = cm
	coifa.position = Vector3(0, 2.5, zf)
	coifa.rotation.y = PI / 4.0
	r.add_child(coifa)
	caixa(r, Vector3(0, (3.15 + alt) * 0.5, zf), Vector3(0.9, alt - 3.15, 0.9), PEDRA.darkened(0.3))
	luz(r, Vector3(0, 1.6, zf + 1.4), Color(1.0, 0.45, 0.12), 2.2, 9.0)
	# bigorna de verdade: toco, pé, corpo e chifre
	var bx := -3.0
	cilindro(r, Vector3(bx, 0, 0.3), 0.45, 0.6, MADEIRA, true)
	caixa(r, Vector3(bx, 0.72, 0.3), Vector3(0.36, 0.25, 0.5), ferro)
	caixa(r, Vector3(bx, 0.92, 0.3), Vector3(0.42, 0.16, 0.8), ferro)
	var chifre := MeshInstance3D.new()
	var ch := CylinderMesh.new()
	ch.top_radius = 0.0
	ch.bottom_radius = 0.12
	ch.height = 0.45
	ch.material = _mat(ferro)
	chifre.mesh = ch
	chifre.position = Vector3(bx, 0.94, 0.92)
	chifre.rotation.x = PI / 2.0
	r.add_child(chifre)
	caixa(r, Vector3(bx + 0.1, 1.05, 0.2), Vector3(0.08, 0.06, 0.35), Color(0.45, 0.3, 0.18))   # martelo em cima
	caixa(r, Vector3(bx + 0.1, 1.07, 0.03), Vector3(0.14, 0.1, 0.1), ferro)
	# tina de água para temperar e fole de couro ao lado da fornalha
	cilindro(r, Vector3(-2.3, 0, zf + 0.4), 0.5, 0.6, Color(0.36, 0.24, 0.13), true)
	cilindro(r, Vector3(-2.3, 0.6, zf + 0.4), 0.44, 0.01, Color(0.25, 0.4, 0.48))
	caixa(r, Vector3(2.4, 0.55, zf + 0.3), Vector3(0.9, 0.18, 1.3), Color(0.32, 0.2, 0.1))
	caixa(r, Vector3(2.4, 0.75, zf + 0.3), Vector3(0.8, 0.22, 1.1), Color(0.42, 0.28, 0.16))
	caixa(r, Vector3(2.4, 0.6, zf - 0.55), Vector3(0.12, 0.12, 0.6), ferro)
	# pedra de amolar: roda de pedra num cavalete, com manivela
	var px := 3.6
	for sz: float in [-0.35, 0.35]:
		caixa(r, Vector3(px, 0.45, 1.6 + sz), Vector3(0.12, 0.9, 0.12), MADEIRA)
	var roda := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.45
	rm.bottom_radius = 0.45
	rm.height = 0.16
	rm.material = _mat(Color(0.7, 0.68, 0.62))
	roda.mesh = rm
	roda.position = Vector3(px, 0.95, 1.6)
	roda.rotation.x = PI / 2.0
	r.add_child(roda)
	caixa(r, Vector3(px, 0.95, 2.05), Vector3(0.06, 0.3, 0.06), ferro)
	caixa(r, Vector3(px, 0.25, 1.6), Vector3(0.9, 0.2, 0.5), MADEIRA.darkened(0.2), true)
	# bancada com ferramentas e lingotes; suporte de tenazes e martelos na parede oeste
	caixa(r, Vector3(-w * 0.5 + 0.9, 0.9, -1.2), Vector3(1.2, 0.12, 2.6), MADEIRA, true)
	for sz: float in [-1.1, 1.1]:
		caixa(r, Vector3(-w * 0.5 + 0.9, 0.42, -1.2 + sz), Vector3(1.0, 0.85, 0.12), MADEIRA.darkened(0.2))
	for i in 4:
		caixa(r, Vector3(-w * 0.5 + 0.8, 1.0, -2.2 + i * 0.3), Vector3(0.3, 0.08, 0.14), [Color(0.6, 0.62, 0.65), Color(0.72, 0.45, 0.25), Color(0.6, 0.62, 0.65), Color(0.85, 0.7, 0.3)][i])
	caixa(r, Vector3(-w * 0.5 + 0.3, 2.0, 1.4), Vector3(0.1, 0.15, 2.6), MADEIRA.darkened(0.25))
	for i in 6:
		var z := 0.3 + i * 0.42
		caixa(r, Vector3(-w * 0.5 + 0.38, 1.6, z), Vector3(0.05, 0.8, 0.05), ferro)
		caixa(r, Vector3(-w * 0.5 + 0.4, 1.22, z), Vector3(0.12, 0.12, 0.2) if i % 2 == 0 else Vector3(0.08, 0.2, 0.08), ferro)
	# monte de carvão e barras de ferro
	for i in 7:
		cilindro(r, Vector3(1.4 + (i % 3) * 0.3, 0, zf + 1.6 + (i / 3) * 0.25), 0.14, 0.18 + 0.05 * (i % 2), Color(0.07, 0.07, 0.08))
	# estante de armas na parede leste
	caixa(r, Vector3(w * 0.5 - 0.6, 1.4, -1.0), Vector3(0.3, 2.8, 3.6), MADEIRA.darkened(0.2), true)
	for i in 4:
		caixa(r, Vector3(w * 0.5 - 0.9, 1.5, -2.4 + i * 0.95), Vector3(0.1, 2.0, 0.12), Color(0.75, 0.78, 0.82))
		caixa(r, Vector3(w * 0.5 - 0.9, 0.6, -2.4 + i * 0.95), Vector3(0.3, 0.1, 0.5), MADEIRA)
	modelo(r, BARRIL, Vector3(-w * 0.5 + 1.2, 0, 2.6), 1.1)
	modelo(r, BARRIL, Vector3(-w * 0.5 + 1.2, 0, 3.7), 1.1)

## Casa do alquimista: prateleiras de poções coloridas (brilham), caldeirão borbulhando em verde,
## mesa com livro aberto, velas, cristais, ervas em vasos, crânio e baú. Faixa da porta livre.
static func _alquimia(r: Node3D, w: float, d: float, alt: float, tap: Color) -> void:
	var cores := [Color(0.2, 0.85, 0.3), Color(0.25, 0.45, 1.0), Color(0.75, 0.3, 0.95), Color(1.0, 0.3, 0.4), Color(1.0, 0.75, 0.2), Color(0.3, 0.9, 0.9)]
	# duas estantes de poções na parede do fundo
	for ex: float in [-3.2, 3.2]:
		caixa(r, Vector3(ex, 1.5, -d * 0.5 + 0.5), Vector3(3.0, 3.0, 0.5), MADEIRA.darkened(0.15), true)
		for prat in 4:
			var y := 0.4 + prat * 0.7
			caixa(r, Vector3(ex, y, -d * 0.5 + 0.75), Vector3(2.9, 0.06, 0.4), MADEIRA)
			for k in 7:
				var c: Color = cores[(k + prat * 2 + int(ex)) % cores.size()]
				var alt_f := 0.2 + 0.1 * ((k + prat) % 3)
				cilindro(r, Vector3(ex - 1.2 + k * 0.4, y + 0.03, -d * 0.5 + 0.78), 0.07 + 0.02 * (k % 2), alt_f, c)
				caixa(r, Vector3(ex - 1.2 + k * 0.4, y + 0.03 + alt_f * 0.45, -d * 0.5 + 0.78), Vector3(0.09, alt_f * 0.6, 0.09), c, false, true, true)
	# caldeirão de ferro com líquido verde que brilha, sobre fogo
	cilindro(r, Vector3(0, 0, -1.2), 0.75, 0.1, Color(0.25, 0.22, 0.2))
	modelo(r, FOGO, Vector3(0, 0.05, -1.2), 0.55)
	var cal := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 0.9
	sm.is_hemisphere = false
	sm.material = _mat(Color(0.12, 0.12, 0.13))
	cal.mesh = sm
	cal.position = Vector3(0, 0.75, -1.2)
	r.add_child(cal)
	cilindro(r, Vector3(0, 1.08, -1.2), 0.5, 0.04, Color(0.3, 1.0, 0.35))
	caixa(r, Vector3(0, 1.1, -1.2), Vector3(0.7, 0.02, 0.7), Color(0.3, 1.0, 0.35), false, true, true)
	luz(r, Vector3(0, 1.8, -1.2), Color(0.4, 1.0, 0.45), 1.4, 6.0)
	caixa(r, Vector3(0, 0.75, -1.2), Vector3(1.4, 1.5, 1.4), Color.BLACK, true, false)
	# mesa de trabalho com livro aberto, velas, almofariz e crânio
	var mx := -w * 0.5 + 1.6
	caixa(r, Vector3(mx, 0.85, 0.6), Vector3(1.6, 0.1, 2.6), MADEIRA, true)
	for sx: float in [-0.65, 0.65]:
		for sz: float in [-1.15, 1.15]:
			caixa(r, Vector3(mx + sx, 0.4, 0.6 + sz), Vector3(0.12, 0.8, 0.12), MADEIRA.darkened(0.2))
	caixa(r, Vector3(mx, 0.93, 0.4), Vector3(0.55, 0.05, 0.8), Color(0.92, 0.88, 0.75))   # livro aberto
	caixa(r, Vector3(mx, 0.92, 0.4), Vector3(0.6, 0.03, 0.85), Color(0.45, 0.15, 0.1))
	for i in 3:
		cilindro(r, Vector3(mx + 0.5, 0.9, -0.3 + i * 0.25), 0.04, 0.2 + i * 0.05, Color(0.95, 0.92, 0.8))
		caixa(r, Vector3(mx + 0.5, 1.12 + i * 0.05, -0.3 + i * 0.25), Vector3(0.03, 0.06, 0.03), Color(1.0, 0.7, 0.2), false, true, true)
	cilindro(r, Vector3(mx - 0.4, 0.9, 1.4), 0.14, 0.14, Color(0.5, 0.48, 0.45))
	var cranio := MeshInstance3D.new()
	var cr := SphereMesh.new()
	cr.radius = 0.15
	cr.height = 0.28
	cr.material = _mat(Color(0.9, 0.86, 0.75))
	cranio.mesh = cr
	cranio.position = Vector3(mx + 0.3, 1.04, 1.5)
	r.add_child(cranio)
	luz(r, Vector3(mx + 0.4, 1.6, 0.2), Color(1.0, 0.75, 0.4), 0.8, 4.0)
	# cristais e ervas em vasos na parede leste; pilha de livros e baú
	for i in 4:
		var z := -2.0 + i * 1.1
		cilindro(r, Vector3(w * 0.5 - 0.7, 0, z), 0.25, 0.4, Color(0.6, 0.35, 0.2))
		var folha := MeshInstance3D.new()
		var fs := SphereMesh.new()
		fs.radius = 0.32
		fs.height = 0.5
		fs.material = _mat(Color(0.25, 0.55, 0.2))
		folha.mesh = fs
		folha.position = Vector3(w * 0.5 - 0.7, 0.62, z)
		r.add_child(folha)
	for i in 3:
		var cristal := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.0
		cc.bottom_radius = 0.12
		cc.height = 0.45 + 0.15 * i
		cc.radial_segments = 5
		cc.material = _mat([Color(0.6, 0.3, 1.0), Color(0.3, 0.9, 0.85), Color(0.6, 0.3, 1.0)][i], true)
		cristal.mesh = cc
		cristal.position = Vector3(w * 0.5 - 1.6 + i * 0.2, cc.height * 0.5, 2.6 + 0.15 * (i % 2))
		cristal.rotation.z = (i - 1) * 0.25
		r.add_child(cristal)
	for i in 5:
		caixa(r, Vector3(-w * 0.5 + 0.7, 0.1 + i * 0.14, 3.2), Vector3(0.6 - i * 0.04, 0.12, 0.45), [Color(0.5, 0.2, 0.15), Color(0.2, 0.3, 0.5), Color(0.3, 0.45, 0.2), Color(0.6, 0.45, 0.15), Color(0.4, 0.15, 0.3)][i])
	caixa(r, Vector3(w * 0.5 - 1.0, 0.4, 3.6), Vector3(1.2, 0.8, 0.7), Color(0.35, 0.22, 0.12), true)
	caixa(r, Vector3(w * 0.5 - 1.0, 0.82, 3.6), Vector3(1.25, 0.08, 0.75), Color(0.6, 0.5, 0.2))
	caixa(r, Vector3(0, 0.02, 1.2), Vector3(4.0, 0.03, 2.4), tap)   # tapete


static func _salao(r: Node3D, w: float, d: float, alt: float, tap: Color) -> void:
	# tapete vermelho da porta até o altar
	caixa(r, Vector3(0, 0.025, 1.5), Vector3(4.0, 0.05, d - 6.0), tap)
	for z: float in [-3.0, 2.0, 7.0]:
		for x: float in [-8.0, 8.0]:
			cilindro(r, Vector3(x, 0, z), 0.65, alt, Color(0.62, 0.6, 0.58), true)
			caixa(r, Vector3(x, 3.6, z + 0.8), Vector3(0.9, 2.4, 0.06), AZUL_REAL)                              # estandarte azul
			caixa(r, Vector3(x, 4.85, z + 0.8), Vector3(1.1, 0.08, 0.08), OURO)                                  # haste
			caixa(r, Vector3(x, 3.8, z + 0.84), Vector3(0.36, 0.36, 0.03), OURO, false, true, true)              # brasão
			caixa(r, Vector3(x, 2.35, z + 0.8), Vector3(0.9, 0.3, 0.06), AZUL_REAL.darkened(0.2))                # ponta do estandarte
			caixa(r, Vector3(x, 2.0, z + 0.7), Vector3(0.2, 0.2, 0.2), Color(1.0, 0.6, 0.15), false, true, true)  # tocha
			if z == 2.0:   # só o par do meio tem luz de verdade (tablet: máx. ~6 luzes por sala)
				luz(r, Vector3(x, 2.5, z), Color(1.0, 0.6, 0.25), 0.8, 9.0)
	# mesas de banquete com bancos, dos dois lados
	for x: float in [-5.0, 5.0]:
		caixa(r, Vector3(x, 0.9, 4.0), Vector3(1.7, 0.14, 7.0), MADEIRA, true)
		caixa(r, Vector3(x, 0.45, 4.0), Vector3(1.4, 0.9, 6.6), MADEIRA.darkened(0.2))
		caixa(r, Vector3(x, 0.98, 4.0), Vector3(0.8, 0.02, 7.1), AZUL_REAL)                 # toalha azul no meio da mesa
		for bx: float in [-1.25, 1.25]:   # cadeiras de espaldar alto, estofado azul
			for i in 5:
				var cz := 1.3 + i * 1.35
				caixa(r, Vector3(x + bx, 0.48, cz), Vector3(0.6, 0.1, 0.6), MADEIRA.darkened(0.1), true)
				caixa(r, Vector3(x + bx, 0.56, cz), Vector3(0.5, 0.06, 0.5), AZUL_REAL)
				caixa(r, Vector3(x + bx * 1.22, 1.15, cz), Vector3(0.08, 1.3, 0.6), MADEIRA.darkened(0.25))
				caixa(r, Vector3(x + bx * 1.2, 1.2, cz), Vector3(0.04, 0.9, 0.44), AZUL_REAL)
				for pz: float in [-0.25, 0.25]:
					caixa(r, Vector3(x + bx, 0.22, cz + pz), Vector3(0.07, 0.45, 0.07), MADEIRA.darkened(0.25))
		for i in 4:   # taças, velas, livro e mapa
			cilindro(r, Vector3(x + (0.45 if i % 2 == 0 else -0.45), 0.97, 1.8 + i * 1.6), 0.08, 0.2, Color(0.85, 0.7, 0.3))
		for i in 3:
			cilindro(r, Vector3(x, 0.99, 2.0 + i * 2.0), 0.05, 0.3, Color(0.95, 0.92, 0.8))
			caixa(r, Vector3(x, 1.33, 2.0 + i * 2.0), Vector3(0.04, 0.07, 0.04), Color(1.0, 0.7, 0.2), false, true, true)
		caixa(r, Vector3(x, 1.0, 3.0), Vector3(0.6, 0.02, 0.8), Color(0.88, 0.8, 0.6))          # mapa aberto
		caixa(r, Vector3(x - 0.3, 1.02, 6.3), Vector3(0.45, 0.1, 0.6), Color(0.15, 0.2, 0.45))  # livro
	# dois lustres de ferro (aro com velas, preso por correntes) sobre as mesas
	for lx: float in [-5.0, 5.0]:
		var ly := alt - 2.4
		var aro := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = 1.0
		tor.outer_radius = 1.12
		tor.material = _mat(Color(0.12, 0.12, 0.13))
		aro.mesh = tor
		aro.position = Vector3(lx, ly, 4.0)
		r.add_child(aro)
		for i in 8:
			var a := TAU * i / 8.0
			var p := Vector3(lx + cos(a) * 1.06, ly, 4.0 + sin(a) * 1.06)
			cilindro(r, p, 0.045, 0.22, Color(0.95, 0.92, 0.82))
			caixa(r, p + Vector3(0, 0.28, 0), Vector3(0.05, 0.09, 0.05), Color(1.0, 0.72, 0.25), false, true, true)
		for i in 4:
			var a := TAU * i / 4.0 + PI / 4.0
			var p0 := Vector3(lx + cos(a) * 1.06, ly, 4.0 + sin(a) * 1.06)
			var p1 := Vector3(lx, alt, 4.0)
			var cor := MeshInstance3D.new()
			var cc := CylinderMesh.new()
			cc.top_radius = 0.015
			cc.bottom_radius = 0.015
			cc.height = p0.distance_to(p1)
			cc.material = _mat(Color(0.12, 0.12, 0.13))
			cor.mesh = cc
			var dd := (p1 - p0).normalized()
			cor.transform = Transform3D(Basis(Quaternion(Vector3.UP, dd)), (p0 + p1) * 0.5)
			r.add_child(cor)
		luz(r, Vector3(lx, ly - 0.3, 4.0), Color(1.0, 0.82, 0.5), 1.1, 11.0)
	# tesouras de madeira no teto (o castelo pode ter vigas)
	for z: float in [-7.0, -2.0, 3.0, 8.0]:
		caixa(r, Vector3(0, alt - 0.35, z), Vector3(w - 0.6, 0.35, 0.4), MADEIRA.darkened(0.3))
		for sx: float in [-1.0, 1.0]:
			var br := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(3.2, 0.25, 0.3)
			bm.material = _mat(MADEIRA.darkened(0.3))
			br.mesh = bm
			br.position = Vector3(sx * (w * 0.5 - 1.6), alt - 1.2, z)
			br.rotation.z = sx * 0.55
			r.add_child(br)
	# janelas góticas com vitral azul (por cima das janelas claras das paredes laterais)
	for lado: float in [-1.0, 1.0]:
		for i in 4:
			var z := -d * 0.5 + (i + 1.0) * d / 5.0
			var xw := lado * (w * 0.5 - 0.3)
			caixa(r, Vector3(xw, alt * 0.55, z), Vector3(0.05, alt * 0.35, 1.2), Color(0.35, 0.55, 0.95), false, true, true)
			for k in 3:   # chumbo do vitral
				caixa(r, Vector3(xw - lado * 0.02, alt * 0.55 - alt * 0.12 + k * alt * 0.12, z), Vector3(0.03, 0.04, 1.22), Color(0.1, 0.1, 0.12))
			caixa(r, Vector3(xw - lado * 0.02, alt * 0.55, z), Vector3(0.03, alt * 0.35, 0.04), Color(0.1, 0.1, 0.12))
			for s2: float in [-1.0, 1.0]:   # arco pontudo em cima
				var ar := MeshInstance3D.new()
				var am := BoxMesh.new()
				am.size = Vector3(0.1, 0.12, 0.9)
				am.material = _mat(PEDRA.darkened(0.25))
				ar.mesh = am
				ar.position = Vector3(xw - lado * 0.03, alt * 0.55 + alt * 0.175 + 0.25, z + s2 * 0.32)
				ar.rotation.x = s2 * 0.75
				r.add_child(ar)
	# estantes de livros nos cantos perto da porta
	for sx: float in [-1.0, 1.0]:
		var ex := sx * (w * 0.5 - 0.6)
		caixa(r, Vector3(ex, 1.6, d * 0.5 - 2.6), Vector3(0.6, 3.2, 2.4), MADEIRA.darkened(0.2), true)
		for prat in 4:
			for k in 7:
				caixa(r, Vector3(ex - sx * 0.12, 0.45 + prat * 0.75, d * 0.5 - 3.6 + k * 0.3), Vector3(0.35, 0.5 - 0.06 * (k % 3), 0.22), [Color(0.5, 0.15, 0.12), Color(0.15, 0.25, 0.5), Color(0.25, 0.4, 0.2), Color(0.55, 0.45, 0.2)][(k + prat) % 4])
	# tapeçaria atrás do trono
	caixa(r, Vector3(0, alt * 0.55, -d * 0.5 + 0.3), Vector3(9.0, alt * 0.7, 0.08), AZUL_REAL)
	caixa(r, Vector3(0, alt * 0.58, -d * 0.5 + 0.25), Vector3(2.2, 2.2, 0.06), OURO, false, true, true)
	# altar: plataforma alta, escada em volta (frente, esquerda e direita) e o trono em cima
	var alt_a := 1.4
	var zc := -d * 0.5 + 0.25 + 3.2
	caixa(r, Vector3(0, alt_a * 0.5, zc), Vector3(12.0, alt_a, 6.4), Color(0.5, 0.48, 0.5), true)
	caixa(r, Vector3(0, alt_a + 0.03, zc), Vector3(12.1, 0.06, 6.5), OURO.darkened(0.2))
	caixa(r, Vector3(0, alt_a + 0.04, zc + 0.4), Vector3(3.4, 0.05, 5.2), tap)
	escada(r, Vector3(0, alt_a, zc + 3.2), Vector3(0, 0, 1), 3.4, alt_a, 5.0, Color(0.58, 0.56, 0.58))
	escada(r, Vector3(-6.0, alt_a, zc), Vector3(-1, 0, 0), 3.0, alt_a, 4.0, Color(0.58, 0.56, 0.58))
	escada(r, Vector3(6.0, alt_a, zc), Vector3(1, 0, 0), 3.0, alt_a, 4.0, Color(0.58, 0.56, 0.58))
	luz(r, Vector3(0, alt_a + 3.5, zc + 1.0), Color(1.0, 0.9, 0.65), 1.4, 10.0)
	# trono dourado. A animação de sentar põe a pélvis atrás da origem do Rei e as canelas à frente dela:
	# o assento fica só sob a pélvis (do encosto até um pouco depois da origem), para as pernas aparecerem.
	var zt := zc - 0.7
	var ty := alt_a
	caixa(r, Vector3(0, ty + 0.35, zt - 0.5), Vector3(2.8, 0.7, 1.2), OURO.darkened(0.15), true)
	caixa(r, Vector3(0, ty + 0.72, zt - 0.5), Vector3(2.5, 0.06, 1.1), AZUL_REAL)      # almofada
	caixa(r, Vector3(0, ty + 2.2, zt - 1.25), Vector3(3.0, 4.4, 0.3), OURO.darkened(0.1), true)     # encosto
	caixa(r, Vector3(0, ty + 4.5, zt - 1.25), Vector3(1.6, 0.6, 0.3), OURO)
	caixa(r, Vector3(0, ty + 2.2, zt - 1.08), Vector3(2.2, 3.6, 0.06), AZUL_REAL)
	for x: float in [-1.7, 1.7]:
		caixa(r, Vector3(x, ty + 0.6, zt - 0.5), Vector3(0.3, 1.2, 1.2), OURO.darkened(0.15), true)   # braços
		caixa(r, Vector3(x, ty + 1.22, zt - 0.5), Vector3(0.38, 0.1, 1.3), OURO)
	caixa(r, Vector3(0, ty + 0.05, zt + 0.9), Vector3(2.4, 0.1, 0.9), AZUL_REAL)        # tapete dos pés
	# Excalibur cravada na pedra, ao pé da escada (Sketchfab, CC-BY: JuanWithOutAim)
	if ResourceLoader.exists("res://models/Excalibur_Pedra.glb"):
		modelo(r, load("res://models/Excalibur_Pedra.glb"), Vector3(4.5, 0, zc + 5.0), 1.7)
	var rei := Node3D.new()
	rei.name = "Rei"
	rei.position = Vector3(0, ty, zt)
	r.add_child(rei)
	var m := Heroi.rei()
	rei.add_child(m)
	var ap := Fit.find_node_of(m, "AnimationPlayer") as AnimationPlayer
	Fit.play(ap, Fit.find_anim(ap, ["Sitting_Idle", "Sitting"]))
	var nome := Label3D.new()
	nome.text = "Rei"
	nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nome.font_size = 72
	nome.outline_size = 14
	nome.modulate = Color(1.0, 0.88, 0.4)
	nome.position = Vector3(0, 3.9, 0)
	rei.add_child(nome)
	r.set_meta("rei", rei)
