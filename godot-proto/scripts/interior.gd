class_name Interior
## Interiores das construções da aldeia (gerados por código). Cada um é uma sala fechada,
## longe do mapa; o jogador entra pelo botão ENTRAR e sai pelo botão SAIR.

const BARRIL := preload("res://models/Barrel.glb")
const FOGO := preload("res://models/Bonfire_Lit.glb")

## nome do nó em "Aldeia": título, largura, fundo, altura (m), cor do piso, cor das paredes, cor do tapete
const SALAS := {
	"SalaoDoChefe": {"nome": "Salão do Rei", "w": 26.0, "d": 22.0, "alt": 8.0, "piso": Color(0.42, 0.4, 0.4), "parede": Color(0.55, 0.52, 0.5), "tapete": Color(0.6, 0.07, 0.1)},
	"Casa1": {"nome": "Casa", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.45, 0.32, 0.2), "parede": Color(0.74, 0.62, 0.46), "tapete": Color(0.62, 0.15, 0.12)},
	"Casa2": {"nome": "Casa", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.4, 0.34, 0.22), "parede": Color(0.55, 0.68, 0.5), "tapete": Color(0.18, 0.45, 0.25)},
	"Casa3": {"nome": "Casa", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.42, 0.34, 0.26), "parede": Color(0.52, 0.6, 0.78), "tapete": Color(0.18, 0.28, 0.6)},
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
	var n: Node3D = cena.instantiate()
	pai.add_child(n)
	Fit.to_height(n, alt)
	n.position += pos
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
	caixa(raiz, Vector3(0, alt + 0.25, 0), Vector3(w + 1.0, 0.5, d + 1.0), MADEIRA.darkened(0.2))   # teto
	caixa(raiz, Vector3(0, 1.2, d * 0.5 - 0.3), Vector3(1.8, 2.4, 0.08), MADEIRA.darkened(0.25))       # porta (folha)
	caixa(raiz, Vector3(0, 2.5, d * 0.5 - 0.3), Vector3(2.2, 0.2, 0.12), Color(0.2, 0.12, 0.06))       # verga
	for sx in [-1.0, 1.0]:
		caixa(raiz, Vector3(sx, 1.25, d * 0.5 - 0.3), Vector3(0.15, 2.5, 0.12), Color(0.2, 0.12, 0.06)) # batentes
	caixa(raiz, Vector3(0.6, 1.1, d * 0.5 - 0.35), Vector3(0.1, 0.1, 0.1), OURO)                        # maçaneta
	caixa(raiz, Vector3(0, 0.02, d * 0.5 - 1.3), Vector3(2.4, 0.04, 1.4), Color(0.3, 0.12, 0.1))       # capacho
	var janelas := 2 if id != "SalaoDoChefe" else 4
	for lado in [-1.0, 1.0]:                                                                    # janelas luminosas
		for i in janelas:
			var z := -d * 0.5 + (i + 1.0) * d / (janelas + 1.0)
			caixa(raiz, Vector3(lado * (w * 0.5 - 0.27), alt * 0.55, z), Vector3(0.05, alt * 0.35, 1.2), Color(0.75, 0.88, 1.0), false, true, true)
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
		_:
			_casa(raiz, w, d, alt, tap)
	return raiz

## Casa: cama, lareira, quadros, sofá, mesa com 4 cadeiras. Faixa da porta (|x| < 2,2 e z > 2,2) livre; `tap` = cor do estofado.
static func _cadeira(r: Node3D, x: float, z: float, olha: float) -> void:   # olha: 1 = encosto ao sul, -1 = ao norte
	caixa(r, Vector3(x, 0.45, z), Vector3(0.5, 0.06, 0.5), MADEIRA.lightened(0.1), true)
	for dx in [-0.21, 0.21]:
		for dz in [-0.21, 0.21]:
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
	caixa(r, Vector3(bx, 0.55, zn + 0.45), Vector3(2.2, 1.1, 0.12), MADEIRA.darkened(0.15))
	_quadro(r, Vector3(bx, 2.1, zn + 0.3), 1.8, 1.2, 0.0, Color(0.55, 0.75, 0.95), Color(0.3, 0.55, 0.25))
	# criado-mudo com abajur
	caixa(r, Vector3(bx + 1.5, 0.3, zn + 0.8), Vector3(0.6, 0.6, 0.6), MADEIRA, true)
	caixa(r, Vector3(bx + 1.5, 0.75, zn + 0.8), Vector3(0.2, 0.3, 0.2), Color(1.0, 0.85, 0.5), false, true, true)
	# lareira na parede norte, com moldura, fogo e quadro ao lado
	var lx := 3.0
	caixa(r, Vector3(lx, 1.1, zn + 0.7), Vector3(3.2, 2.2, 0.9), PEDRA, true)
	caixa(r, Vector3(lx, 2.25, zn + 0.7), Vector3(3.6, 0.15, 1.1), MADEIRA.darkened(0.2))               # prateleira
	caixa(r, Vector3(lx, 0.6, zn + 1.18), Vector3(1.5, 0.9, 0.05), Color(0.04, 0.03, 0.03))
	modelo(r, FOGO, Vector3(lx, 0.05, zn + 1.5), 0.75)
	luz(r, Vector3(lx, 1.2, zn + 2.2), Color(1.0, 0.55, 0.2), 1.3, 6.5)
	_quadro(r, Vector3(-0.4, 2.0, zn + 0.3), 1.2, 0.9, 0.0, Color(0.95, 0.8, 0.55), Color(0.45, 0.3, 0.2))
	# sofá de frente para a lareira
	var sz := -0.6
	caixa(r, Vector3(lx, 0.25, sz), Vector3(3.0, 0.5, 1.0), tap.darkened(0.15), true)
	caixa(r, Vector3(lx, 0.55, sz), Vector3(2.7, 0.2, 0.85), tap)
	caixa(r, Vector3(lx, 0.8, sz + 0.5), Vector3(3.0, 0.7, 0.22), tap.darkened(0.1), true)
	for sx in [-1.4, 1.4]:
		caixa(r, Vector3(lx + sx, 0.45, sz), Vector3(0.25, 0.7, 1.0), tap.darkened(0.2), true)
	# mesa com 4 cadeiras (leste, entre o sofá e a parede da frente)
	var mx := 4.3
	var mz := 2.1
	caixa(r, Vector3(mx, 0.78, mz), Vector3(1.7, 0.08, 1.0), MADEIRA, true)
	for dx in [-0.75, 0.75]:
		for dz in [-0.4, 0.4]:
			caixa(r, Vector3(mx + dx, 0.37, mz + dz), Vector3(0.08, 0.74, 0.08), MADEIRA.darkened(0.2))
	cilindro(r, Vector3(mx - 0.3, 0.82, mz), 0.18, 0.07, Color(0.85, 0.65, 0.3))
	cilindro(r, Vector3(mx + 0.4, 0.82, mz + 0.1), 0.07, 0.13, Color(0.75, 0.75, 0.8))
	for cx in [-0.45, 0.45]:
		_cadeira(r, mx + cx, mz - 0.95, 1.0)
		_cadeira(r, mx + cx, mz + 0.95, -1.0)
	# parede oeste: quadro grande e baú; barris junto à porta
	_quadro(r, Vector3(-w * 0.5 + 0.3, 2.0, 0.5), 1.8, 1.2, PI * 0.5, Color(0.7, 0.8, 0.95), Color(0.25, 0.45, 0.3))
	caixa(r, Vector3(-5.0, 0.35, d * 0.5 - 1.2), Vector3(1.4, 0.7, 0.8), MADEIRA.darkened(0.1), true)
	caixa(r, Vector3(-5.0, 0.75, d * 0.5 - 1.2), Vector3(1.5, 0.1, 0.9), OURO.darkened(0.3))
	modelo(r, BARRIL, Vector3(5.5, 0, d * 0.5 - 1.1), 1.0)

static func _forja(r: Node3D, w: float, d: float, alt: float) -> void:
	# fornalha de pedra com brasa e chaminé
	caixa(r, Vector3(0, 1.5, -d * 0.5 + 1.2), Vector3(4.0, 3.0, 1.8), PEDRA.darkened(0.2), true)
	caixa(r, Vector3(0, 0.9, -d * 0.5 + 2.15), Vector3(2.4, 1.1, 0.1), Color(1.0, 0.4, 0.08), false, true, true)
	caixa(r, Vector3(0, alt - 0.5, -d * 0.5 + 1.0), Vector3(1.6, 1.0, 1.4), PEDRA.darkened(0.3))
	luz(r, Vector3(0, 1.2, -d * 0.5 + 2.8), Color(1.0, 0.45, 0.12), 2.0, 9.0)
	# bigorna sobre o toco
	cilindro(r, Vector3(-3.0, 0, 0.0), 0.5, 0.7, MADEIRA, true)
	caixa(r, Vector3(-3.0, 0.9, 0.0), Vector3(0.5, 0.25, 1.2), Color(0.25, 0.25, 0.28), true)
	caixa(r, Vector3(-3.0, 1.1, 0.5), Vector3(0.3, 0.15, 0.5), Color(0.25, 0.25, 0.28))
	# afiador, balde d'água, fole
	cilindro(r, Vector3(3.5, 0, -1.0), 0.5, 0.9, Color(0.5, 0.5, 0.52), true)
	cilindro(r, Vector3(3.5, 0, 1.5), 0.5, 0.6, Color(0.3, 0.22, 0.14), true)
	caixa(r, Vector3(-w * 0.5 + 1.2, 0.5, -2.0), Vector3(1.2, 1.0, 1.8), Color(0.35, 0.22, 0.12), true)
	# estante de armas na parede leste
	caixa(r, Vector3(w * 0.5 - 0.6, 1.4, 0.0), Vector3(0.3, 2.8, 5.0), MADEIRA.darkened(0.2), true)
	for i in 4:
		caixa(r, Vector3(w * 0.5 - 0.9, 1.5, -1.8 + i * 1.2), Vector3(0.1, 2.0, 0.12), Color(0.75, 0.78, 0.82))
		caixa(r, Vector3(w * 0.5 - 0.9, 0.6, -1.8 + i * 1.2), Vector3(0.3, 0.1, 0.5), MADEIRA)
	modelo(r, BARRIL, Vector3(-w * 0.5 + 1.2, 0, 2.5), 1.1)
	modelo(r, BARRIL, Vector3(-w * 0.5 + 1.2, 0, 3.6), 1.1)

static func _salao(r: Node3D, w: float, d: float, alt: float, tap: Color) -> void:
	# tapete vermelho da porta até o altar
	caixa(r, Vector3(0, 0.025, 1.5), Vector3(4.0, 0.05, d - 6.0), tap)
	for z in [-3.0, 2.0, 7.0]:
		for x in [-8.0, 8.0]:
			cilindro(r, Vector3(x, 0, z), 0.65, alt, Color(0.62, 0.6, 0.58), true)
			caixa(r, Vector3(x, 3.0, z + (0.8 if z > 0 else 0.8)), Vector3(0.9, 2.4, 0.06), Color(0.7, 0.08, 0.12))   # estandarte
			caixa(r, Vector3(x, 2.2, z + 0.7), Vector3(0.2, 0.2, 0.2), Color(1.0, 0.6, 0.15), false, true, true)     # tocha
			luz(r, Vector3(x, 2.5, z), Color(1.0, 0.6, 0.25), 0.7, 7.0)
	# mesas de banquete com bancos, dos dois lados
	for x in [-5.0, 5.0]:
		caixa(r, Vector3(x, 0.9, 4.0), Vector3(1.7, 0.14, 7.0), MADEIRA, true)
		caixa(r, Vector3(x, 0.45, 4.0), Vector3(1.4, 0.9, 6.6), MADEIRA.darkened(0.2))
		for bx in [-1.4, 1.4]:
			caixa(r, Vector3(x + bx, 0.42, 4.0), Vector3(0.5, 0.1, 6.4), MADEIRA.darkened(0.1), true)
		for i in 4:
			cilindro(r, Vector3(x + (0.3 if i % 2 == 0 else -0.3), 0.97, 1.8 + i * 1.6), 0.12, 0.2, Color(0.75, 0.75, 0.8))
	# lustre
	for i in 6:
		var a := TAU * i / 6.0
		caixa(r, Vector3(cos(a) * 1.6, alt - 1.6, 4.0 + sin(a) * 1.6), Vector3(0.15, 0.35, 0.15), Color(1.0, 0.8, 0.4), false, true, true)
	cilindro(r, Vector3(0, alt - 1.8, 4.0), 1.7, 0.1, Color(0.2, 0.17, 0.12))
	luz(r, Vector3(0, alt - 2.0, 4.0), Color(1.0, 0.85, 0.55), 1.2, 14.0)
	# tapeçaria atrás do trono
	caixa(r, Vector3(0, alt * 0.55, -d * 0.5 + 0.3), Vector3(9.0, alt * 0.7, 0.08), Color(0.6, 0.08, 0.12))
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
	caixa(r, Vector3(0, ty + 0.72, zt - 0.5), Vector3(2.5, 0.06, 1.1), Color(0.6, 0.08, 0.12))      # almofada
	caixa(r, Vector3(0, ty + 2.2, zt - 1.25), Vector3(3.0, 4.4, 0.3), OURO.darkened(0.1), true)     # encosto
	caixa(r, Vector3(0, ty + 4.5, zt - 1.25), Vector3(1.6, 0.6, 0.3), OURO)
	caixa(r, Vector3(0, ty + 2.2, zt - 1.08), Vector3(2.2, 3.6, 0.06), Color(0.6, 0.08, 0.12))
	for x in [-1.7, 1.7]:
		caixa(r, Vector3(x, ty + 0.6, zt - 0.5), Vector3(0.3, 1.2, 1.2), OURO.darkened(0.15), true)   # braços
		caixa(r, Vector3(x, ty + 1.22, zt - 0.5), Vector3(0.38, 0.1, 1.3), OURO)
	caixa(r, Vector3(0, ty + 0.05, zt + 0.9), Vector3(2.4, 0.1, 0.9), Color(0.6, 0.08, 0.12))        # tapete dos pés
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
