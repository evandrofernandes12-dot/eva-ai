class_name Interior
## Interiores das construções da aldeia (gerados por código). Cada um é uma sala fechada,
## longe do mapa; o jogador entra pelo botão ENTRAR e sai pelo botão SAIR.

const BARRIL := preload("res://models/Barrel.glb")
const FOGO := preload("res://models/Bonfire_Lit.glb")

## nome do nó em "Aldeia": título, largura, fundo, altura (m), cor do piso, cor das paredes, cor do tapete
const SALAS := {
	"SalaoDoChefe": {"nome": "Salão do Rei", "w": 26.0, "d": 22.0, "alt": 8.0, "piso": Color(0.5, 0.48, 0.46), "parede": Color(0.62, 0.6, 0.56), "tapete": Color(0.13, 0.22, 0.52)},
	"Casa1": {"nome": "Casa", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color(0.45, 0.32, 0.2), "parede": Color(0.74, 0.62, 0.46), "tapete": Color(0.62, 0.15, 0.12)},
	"Casa2": {"nome": "Casa", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color(0.4, 0.34, 0.22), "parede": Color(0.55, 0.68, 0.5), "tapete": Color(0.18, 0.45, 0.25)},
	"Casa3": {"nome": "Casa do Alquimista", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.42, 0.34, 0.26), "parede": Color(0.52, 0.6, 0.78), "tapete": Color(0.18, 0.28, 0.6)},
	"LoteCasa": {"nome": "Casa", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color(0.5, 0.36, 0.22), "parede": Color(0.8, 0.7, 0.52), "tapete": Color(0.55, 0.35, 0.15)},
	"LoteEstalagem": {"nome": "Estalagem", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color(0.38, 0.24, 0.14), "parede": Color(0.75, 0.5, 0.38), "tapete": Color(0.5, 0.12, 0.12)},
	"LoteSerraria": {"nome": "Serraria", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color(0.5, 0.4, 0.26), "parede": Color(0.7, 0.55, 0.35), "tapete": Color(0.4, 0.3, 0.15)},
	"Moinho": {"nome": "Moinho", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color(0.55, 0.5, 0.42), "parede": Color(0.9, 0.86, 0.76), "tapete": Color(0.55, 0.5, 0.4)},
	"Barraca": {"nome": "Barraca", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color(0.5, 0.42, 0.3), "parede": Color(0.85, 0.72, 0.5), "tapete": Color(0.6, 0.45, 0.25)},
	"Pedreira": {"nome": "Pedreira", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color.GRAY, "parede": Color.GRAY, "tapete": Color.GRAY},
	"Madeireira": {"nome": "Madeireira", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color.GRAY, "parede": Color.GRAY, "tapete": Color.GRAY},
	"Mantimentos": {"nome": "Mantimentos", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color.GRAY, "parede": Color.GRAY, "tapete": Color.GRAY},
	"Açougue": {"nome": "Açougue", "w": 12.0, "d": 10.0, "alt": 3.12, "piso": Color.GRAY, "parede": Color.GRAY, "tapete": Color.GRAY},
	"Forja": {"nome": "Forja", "w": 14.0, "d": 10.0, "alt": 3.8, "piso": Color(0.27, 0.26, 0.26), "parede": Color(0.4, 0.37, 0.36), "tapete": Color(0.2, 0.2, 0.2)},
}
const MADEIRA := Color(0.42, 0.27, 0.14)
const PEDRA := Color(0.45, 0.44, 0.46)
const OURO := Color(0.95, 0.75, 0.2)
const AZUL_REAL := Color(0.13, 0.22, 0.52)

static var _autoluz := 0.0   # fração da cor que "brilha sozinha": casas e forja são pequenas e escuras

static func _mat(cor: Color, brilho := false, tex: Texture2D = null, escala := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.85
	if not brilho:   # textura em tudo (antes cor lisa = cara de desenho); triplanar dispensa UV
		m.albedo_texture = tex if tex != null else Construcoes.textura_veios()
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * escala
		if cor.s < 0.15 and cor.v < 0.35:   # ferro: um pouco metálico e liso
			m.metallic = 0.55
			m.roughness = 0.45
	if _autoluz > 0.0 and not brilho:
		m.emission_enabled = true
		m.emission = cor * _autoluz
	if brilho:
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = 1.2
	return m

## Caixa (com colisão opcional). `visivel` false = só colisão.
static func caixa(pai: Node3D, pos: Vector3, tam: Vector3, cor: Color, colide := false, visivel := true, brilho := false, tex: Texture2D = null, escala := 0.8) -> void:
	if visivel:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = tam
		bm.material = _mat(cor, brilho, tex, escala)
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
	_autoluz = 0.0 if id == "SalaoDoChefe" else 0.25   # menos brilho próprio (achatava as cores); compensado nas luzes
	var s: Dictionary = SALAS[id]
	if id in CASAS_MEDIEVAIS or ARMAZENS.has(id):   # salas montadas com as peças medievais
		_autoluz = 0.0
		var rm := Node3D.new()
		rm.name = "Interior_" + id
		if ARMAZENS.has(id):
			_armazem_medieval(rm, ARMAZENS[id])
		else:
			_casa_medieval(rm, s.tapete)
		return rm
	var w: float = s.w
	var d: float = s.d
	var alt: float = s.alt
	var raiz := Node3D.new()
	raiz.name = "Interior_" + id
	var pa: Color = s.parede
	var tap: Color = s.tapete
	var pedra_parede := id == "Forja" or id == "SalaoDoChefe"
	var tex_piso: Texture2D = Construcoes.textura_pedras() if pedra_parede else Construcoes.textura_tabuas()
	var tex_par: Texture2D = Construcoes.textura_pedras() if pedra_parede else null
	caixa(raiz, Vector3(0, -0.5, 0), Vector3(w, 1.0, d), s.piso, true, true, false, tex_piso, 0.45)                         # piso
	caixa(raiz, Vector3(0, alt * 0.5, -d * 0.5), Vector3(w, alt, 0.5), pa, true, true, false, tex_par, 0.42)               # paredes
	caixa(raiz, Vector3(0, alt * 0.5, d * 0.5), Vector3(w, alt, 0.5), pa, true, true, false, tex_par, 0.42)
	caixa(raiz, Vector3(-w * 0.5, alt * 0.5, 0), Vector3(0.5, alt, d), pa, true, true, false, tex_par, 0.42)
	caixa(raiz, Vector3(w * 0.5, alt * 0.5, 0), Vector3(0.5, alt, d), pa, true, true, false, tex_par, 0.42)
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
	luz(raiz, Vector3(0, alt - 1.4, 0), Color(1.0, 0.88, 0.7), 1.3 if castelo else 1.8, maxf(w, d) * 1.2)
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
	var tora := MADEIRA.darkened(0.1)
	var palha := Color(0.82, 0.7, 0.42)
	var linho := Color(0.9, 0.86, 0.76)
	var pedras := Construcoes.textura_pedras()
	cilindro(r, Vector3(0, 0, 0.3), 1.9, 0.03, tap.lightened(0.15))                              # tapete de lã redondo
	# cama rústica de aldeão no canto noroeste: estrado de toras, colchão de palha, manta de lã listrada
	var bx := -5.3
	var bz := -2.5
	for sx: float in [-0.95, 0.95]:
		for pz: float in [-1.55, 1.55]:
			cilindro(r, Vector3(bx + sx, 0, bz + pz), 0.09, 0.75 if pz < 0 else 0.55, tora)        # pés/postes
	for sx: float in [-0.95, 0.95]:
		caixa(r, Vector3(bx + sx, 0.33, bz), Vector3(0.14, 0.18, 3.2), tora, true)              # laterais
	caixa(r, Vector3(bx, 0.33, bz), Vector3(1.9, 0.08, 3.1), MADEIRA)                            # estrado
	caixa(r, Vector3(bx, 0.48, bz), Vector3(1.8, 0.22, 3.0), palha)                              # colchão de palha
	caixa(r, Vector3(bx, 0.62, bz - 1.25), Vector3(1.1, 0.14, 0.42), linho)                      # travesseiro de linho
	caixa(r, Vector3(bx, 0.62, bz + 0.35), Vector3(1.86, 0.07, 2.1), tap)                        # manta de lã
	for k in 3:
		caixa(r, Vector3(bx, 0.66, bz - 0.4 + k * 0.6), Vector3(1.87, 0.02, 0.12), tap.lightened(0.35))
	caixa(r, Vector3(bx, 0.62, bz - 1.6), Vector3(1.9, 0.5, 0.1), tora)                          # cabeceira de tábuas
	# baú ao pé da cama e banquinho com vela
	caixa(r, Vector3(bx, 0.3, bz + 2.15), Vector3(1.3, 0.6, 0.65), MADEIRA.darkened(0.15), true)
	caixa(r, Vector3(bx, 0.62, bz + 2.15), Vector3(1.35, 0.06, 0.7), Color(0.25, 0.25, 0.27))
	cilindro(r, Vector3(bx + 1.5, 0, zn + 0.8), 0.25, 0.5, MADEIRA)
	cilindro(r, Vector3(bx + 1.5, 0.5, zn + 0.8), 0.05, 0.18, Color(0.95, 0.92, 0.8))
	caixa(r, Vector3(bx + 1.5, 0.73, zn + 0.8), Vector3(0.04, 0.07, 0.04), Color(1.0, 0.7, 0.2), false, true, true)
	_quadro(r, Vector3(bx, 2.1, zn + 0.3), 1.6, 1.1, 0.0, Color(0.55, 0.75, 0.95), Color(0.3, 0.55, 0.25))
	# lareira de pedra assentada, panela pendurada, lenha empilhada e atiçador
	var lx := 3.0
	caixa(r, Vector3(lx, 1.1, zn + 0.7), Vector3(3.2, 2.2, 0.9), PEDRA, true, true, false, pedras, 0.9)
	caixa(r, Vector3(lx, 2.25, zn + 0.75), Vector3(3.4, 0.14, 1.05), PEDRA.darkened(0.15), false, true, false, pedras, 0.9)   # prateleira de pedra
	caixa(r, Vector3(lx, 0.6, zn + 1.18), Vector3(1.5, 0.9, 0.05), Color(0.04, 0.03, 0.03))
	modelo(r, FOGO, Vector3(lx, 0.05, zn + 1.5), 0.7)
	var panela := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 0.28
	pm.height = 0.4
	pm.material = _mat(Color(0.12, 0.12, 0.13))
	panela.mesh = pm
	panela.position = Vector3(lx, 0.95, zn + 1.45)
	r.add_child(panela)
	caixa(r, Vector3(lx, 1.35, zn + 1.45), Vector3(0.02, 0.6, 0.02), Color(0.12, 0.12, 0.13))
	for k in 6:
		var y := 0.12 + (k / 3) * 0.22
		var z := zn + 1.0 + (k % 3) * 0.25
		caixa(r, Vector3(lx + 2.0, y, z), Vector3(0.8, 0.2, 0.2), Color(0.45, 0.31, 0.18))
	caixa(r, Vector3(lx - 1.75, 0.5, zn + 1.3), Vector3(0.03, 1.0, 0.03), Color(0.12, 0.12, 0.13))
	for k in 3:   # potes de barro na prateleira da lareira
		cilindro(r, Vector3(lx - 1.0 + k * 1.0, 2.32, zn + 0.75), 0.12, 0.22 + 0.05 * k, Color(0.62, 0.36, 0.22))
	luz(r, Vector3(lx, 1.2, zn + 2.2), Color(1.0, 0.55, 0.2), 1.4, 6.5)
	# banco comprido de encosto alto (o "sofá" do aldeão) com almofadas e pele de carneiro
	var sz := -0.6
	caixa(r, Vector3(lx, 0.42, sz), Vector3(2.8, 0.1, 0.7), MADEIRA, true)
	caixa(r, Vector3(lx, 0.95, sz + 0.33), Vector3(2.8, 1.0, 0.08), MADEIRA, true)
	for sx: float in [-1.35, 1.35]:
		caixa(r, Vector3(lx + sx, 0.5, sz), Vector3(0.1, 1.0, 0.7), MADEIRA.darkened(0.2), true)
	caixa(r, Vector3(lx - 0.6, 0.52, sz), Vector3(1.0, 0.1, 0.6), tap)
	caixa(r, Vector3(lx + 0.6, 0.52, sz), Vector3(1.0, 0.1, 0.6), tap.darkened(0.1))
	caixa(r, Vector3(lx + 0.9, 0.6, sz + 0.1), Vector3(0.8, 0.06, 0.55), Color(0.92, 0.9, 0.84))   # pele de carneiro
	# mesa de tábuas com pão, queijo, jarra, tigelas e vela; 4 cadeiras
	var mx := 4.3
	var mz := 2.1
	caixa(r, Vector3(mx, 0.78, mz), Vector3(1.8, 0.1, 1.05), MADEIRA, true)
	for dx: float in [-0.75, 0.75]:
		for dz: float in [-0.4, 0.4]:
			caixa(r, Vector3(mx + dx, 0.37, mz + dz), Vector3(0.1, 0.74, 0.1), MADEIRA.darkened(0.2))
	var pao := MeshInstance3D.new()
	var pa := SphereMesh.new()
	pa.radius = 0.16
	pa.height = 0.18
	pa.material = _mat(Color(0.78, 0.55, 0.28))
	pao.mesh = pa
	pao.position = Vector3(mx - 0.4, 0.88, mz - 0.1)
	pao.scale = Vector3(1.5, 1, 1)
	r.add_child(pao)
	caixa(r, Vector3(mx - 0.05, 0.87, mz + 0.2), Vector3(0.22, 0.1, 0.16), Color(0.95, 0.8, 0.35))   # queijo
	cilindro(r, Vector3(mx + 0.4, 0.83, mz - 0.15), 0.09, 0.24, Color(0.6, 0.38, 0.24))              # jarra de barro
	for k in 2:
		cilindro(r, Vector3(mx + 0.25 - k * 0.5, 0.83, mz + 0.3), 0.12, 0.05, Color(0.55, 0.4, 0.25))  # tigelas
	cilindro(r, Vector3(mx + 0.65, 0.83, mz + 0.25), 0.04, 0.16, Color(0.95, 0.92, 0.8))
	caixa(r, Vector3(mx + 0.65, 1.02, mz + 0.25), Vector3(0.03, 0.06, 0.03), Color(1.0, 0.7, 0.2), false, true, true)
	for cx: float in [-0.45, 0.45]:
		_cadeira(r, mx + cx, mz - 0.95, 1.0)
		_cadeira(r, mx + cx, mz + 0.95, -1.0)
	# parede oeste: prateleira com potes e tigelas, sacos de grão, vassoura, balde e roca de fiar
	var ox := -w * 0.5 + 0.45
	for k in 2:
		caixa(r, Vector3(ox, 1.3 + k * 0.6, 1.0), Vector3(0.4, 0.06, 2.0), MADEIRA)
		for j in 4:
			cilindro(r, Vector3(ox, 1.33 + k * 0.6, 0.3 + j * 0.45), 0.1, 0.2 + 0.06 * ((j + k) % 2), [Color(0.62, 0.36, 0.22), Color(0.75, 0.68, 0.55), Color(0.5, 0.42, 0.3)][(j + k) % 3])
	for k in 3:   # sacos de grão
		var saco := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.32
		sm.height = 0.75
		sm.material = _mat(Color(0.7, 0.6, 0.42))
		saco.mesh = sm
		saco.position = Vector3(-w * 0.5 + 0.8 + k * 0.55, 0.35, 2.6 + (k % 2) * 0.3)
		r.add_child(saco)
	caixa(r, Vector3(-w * 0.5 + 0.45, 0.9, 3.4), Vector3(0.04, 1.6, 0.04), MADEIRA.lightened(0.15))   # vassoura
	caixa(r, Vector3(-w * 0.5 + 0.45, 0.12, 3.4), Vector3(0.12, 0.25, 0.3), palha.darkened(0.2))
	cilindro(r, Vector3(-3.4, 0, d * 0.5 - 0.9), 0.22, 0.35, Color(0.45, 0.31, 0.18))                 # balde
	var rx := -2.6
	var rz := -3.4
	for sz2: float in [-0.12, 0.12]:
		caixa(r, Vector3(rx, 0.5, rz + sz2), Vector3(0.06, 1.0, 0.06), MADEIRA)
	var roda := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.4
	tm.outer_radius = 0.46
	tm.material = _mat(MADEIRA)
	roda.mesh = tm
	roda.position = Vector3(rx, 0.95, rz)
	roda.rotation.x = PI / 2.0
	r.add_child(roda)
	caixa(r, Vector3(rx + 0.55, 0.3, rz), Vector3(1.4, 0.08, 0.3), MADEIRA)
	caixa(r, Vector3(rx + 1.0, 0.6, rz), Vector3(0.05, 0.5, 0.05), linho)
	modelo(r, BARRIL, Vector3(5.5, 0, d * 0.5 - 1.1), 1.0)

static func _forja(r: Node3D, w: float, d: float, alt: float) -> void:
	var ferro := Color(0.22, 0.22, 0.25)
	var zf := -d * 0.5 + 1.3
	# fornalha de pedra com boca de brasa, coifa em pirâmide e chaminé
	caixa(r, Vector3(0, 0.55, zf), Vector3(3.6, 1.1, 2.2), PEDRA.darkened(0.15), true, true, false, Construcoes.textura_pedras(), 0.9)
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
	caixa(r, Vector3(0, (3.15 + alt) * 0.5, zf), Vector3(0.9, alt - 3.15, 0.9), PEDRA.darkened(0.3), false, true, false, Construcoes.textura_pedras(), 0.9)
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
	# tronos da família real em cima do altar: Rei e Rainha no meio, os dois filhos ao lado da Rainha.
	# A animação de sentar põe a pélvis atrás da origem e as canelas à frente: o assento fica só sob a pélvis.
	var zt := zc - 0.7
	var ty := alt_a
	var rei := _trono_com(r, Vector3(-1.5, ty, zt), 2.6, 1.0, Heroi.rei(), "Rei")
	_trono_com(r, Vector3(1.5, ty, zt), 2.45, 0.92, Heroi.realeza("G4", 2.45, false, 0.85), "Rainha")   # corpo sem manto longo: sentada, a saia em cone deformava as pernas
	_trono_com(r, Vector3(3.7, ty, zt + 0.2), 1.75, 0.68, Heroi.realeza("A2", 1.75, false, 0.6), "Príncipe")
	_trono_com(r, Vector3(5.2, ty, zt + 0.2), 1.65, 0.65, Heroi.realeza("A3", 1.65, false, 0.6), "Princesa")
	caixa(r, Vector3(0, ty + 0.05, zt + 0.9), Vector3(5.6, 0.1, 0.9), AZUL_REAL)        # tapete dos pés
	# Excalibur cravada na pedra, em cima do altar, à esquerda do Rei (Sketchfab, CC-BY: JuanWithOutAim)
	if ResourceLoader.exists("res://models/Excalibur_Pedra.glb"):
		modelo(r, load("res://models/Excalibur_Pedra.glb"), Vector3(-4.6, ty, zc + 0.6), 1.5)
	r.set_meta("rei", rei)

## Trono dourado (tamanho `k`; 1 = do Rei) com uma figura sentada e o nome em cima. Devolve o nó da figura.
static func _trono_com(r: Node3D, p: Vector3, altura: float, k: float, figura: Node3D, nome_txt: String) -> Node3D:
	var assento := 0.75 * altura / 2.9
	caixa(r, p + Vector3(0, assento * 0.47, -0.5 * k), Vector3(2.0 * k, assento * 0.94, 1.1 * k), OURO.darkened(0.15), true)
	caixa(r, p + Vector3(0, assento * 0.97, -0.5 * k), Vector3(1.8 * k, 0.06, 1.0 * k), AZUL_REAL)        # almofada
	caixa(r, p + Vector3(0, 1.6 * k, -1.1 * k), Vector3(2.1 * k, 3.2 * k, 0.25), OURO.darkened(0.1), true)   # encosto
	caixa(r, p + Vector3(0, 3.3 * k, -1.1 * k), Vector3(1.1 * k, 0.4 * k, 0.25), OURO)
	caixa(r, p + Vector3(0, 1.6 * k, -0.96 * k), Vector3(1.5 * k, 2.6 * k, 0.05), AZUL_REAL)
	for sx: float in [-1.0, 1.0]:
		caixa(r, p + Vector3(sx * 1.05 * k, 0.55 * k, -0.5 * k), Vector3(0.22 * k, 1.1 * k, 1.1 * k), OURO.darkened(0.15), true)   # braços
		caixa(r, p + Vector3(sx * 1.05 * k, 1.12 * k, -0.5 * k), Vector3(0.3 * k, 0.08, 1.2 * k), OURO)
	var no := Node3D.new()
	no.name = nome_txt
	no.position = p
	r.add_child(no)
	no.add_child(figura)
	var ap := Fit.find_node_of(figura, "AnimationPlayer") as AnimationPlayer
	Fit.play(ap, Fit.find_anim(ap, ["Sitting_Idle", "Sitting"]))
	var nome := Label3D.new()
	nome.text = nome_txt
	nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nome.font_size = 64 if k >= 0.9 else 48
	nome.outline_size = 12
	nome.modulate = Color(1.0, 0.88, 0.4)
	nome.position = Vector3(0, altura * 1.2 + 0.4, 0)
	no.add_child(nome)
	return no

# ---------- interiores medievais (Quaternius Medieval Village MegaKit + Fantasy Props MegaKit, CC0) ----------
const MV := "res://assets/medieval/vila/"
const MP := "res://assets/medieval/props/"
## Salas montadas com as peças medievais: casas comuns e os armazéns da vila.
const CASAS_MEDIEVAIS := ["Casa1", "Casa2", "LoteCasa", "LoteEstalagem", "LoteSerraria", "Moinho", "Barraca"]
const ARMAZENS := {"Pedreira": "pedra", "Madeireira": "madeira", "Mantimentos": "comida", "Açougue": "carne"}
const MW := 12.0   # largura da sala medieval (6 módulos de 2 m)
const MD := 10.0   # fundo (5 módulos)
const MH := 3.12   # altura das paredes do kit

## Peça do kit no tamanho original (as peças já vêm em metros).
static func peca(pai: Node3D, arq: String, pos: Vector3, giro := 0.0, esc := 1.0) -> Node3D:
	if not ResourceLoader.exists(arq):
		return null
	var n: Node3D = (load(arq) as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = giro
	n.scale = Vector3.ONE * esc
	pai.add_child(n)
	return n

## Piso, quatro paredes (janelas nas laterais e no fundo, porta na frente), teto de tábuas, colisões e luzes.
static func _sala_medieval(r: Node3D, tijolo: bool) -> void:
	var parede := "Wall_UnevenBrick_" if tijolo else "Wall_Plaster_"
	var piso := "Floor_UnevenBrick" if tijolo else "Floor_WoodDark"
	for i in 6:
		for j in 5:
			peca(r, MV + piso + ".gltf", Vector3(-5.0 + i * 2.0, 0, -4.0 + j * 2.0))
			var teto := peca(r, MV + "Floor_WoodDark.gltf", Vector3(-5.0 + i * 2.0, MH, -4.0 + j * 2.0))
			if teto != null:
				teto.rotation.x = PI   # tábuas viradas para baixo
	for i in 6:   # fundo (janela no meio) e frente (porta no meio)
		var x := -5.0 + i * 2.0
		peca(r, MV + parede + ("Window_Wide_Round" if i == 2 else "Straight") + ".gltf", Vector3(x, 0, -MD * 0.5))
		peca(r, MV + parede + ("Door_Round" if i == 2 or i == 3 else "Straight") + ".gltf", Vector3(x, 0, MD * 0.5), PI)
	for j in 5:   # laterais com uma janela cada
		var z := -4.0 + j * 2.0
		peca(r, MV + parede + ("Window_Wide_Round" if j == 2 else "Straight") + ".gltf", Vector3(-MW * 0.5, 0, z), PI * 0.5)
		peca(r, MV + parede + ("Window_Wide_Round" if j == 2 else "Straight") + ".gltf", Vector3(MW * 0.5, 0, z), -PI * 0.5)
	# luz do dia entrando pelas janelas (placas claras do lado de fora)
	for p: Array in [[Vector3(-1.0, 1.7, -MD * 0.5 - 0.5), 0.0], [Vector3(-MW * 0.5 - 0.5, 1.7, 0), PI * 0.5], [Vector3(MW * 0.5 + 0.5, 1.7, 0), PI * 0.5]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.0, 2.4, 0.05)
		bm.material = _mat(Color(0.85, 0.92, 1.0), true)
		mi.mesh = bm
		mi.position = p[0]
		mi.rotation.y = p[1]
		r.add_child(mi)
	caixa(r, Vector3(0, -0.5, 0), Vector3(MW, 1.0, MD), Color.BLACK, true, false)             # colisões
	caixa(r, Vector3(0, MH * 0.5, -MD * 0.5 - 0.1), Vector3(MW, MH, 0.4), Color.BLACK, true, false)
	caixa(r, Vector3(0, MH * 0.5, MD * 0.5 + 0.1), Vector3(MW, MH, 0.4), Color.BLACK, true, false)
	caixa(r, Vector3(-MW * 0.5 - 0.1, MH * 0.5, 0), Vector3(0.4, MH, MD), Color.BLACK, true, false)
	caixa(r, Vector3(MW * 0.5 + 0.1, MH * 0.5, 0), Vector3(0.4, MH, MD), Color.BLACK, true, false)
	var lus := peca(r, MP + "Chandelier.gltf", Vector3(0, MH - 0.02, 0.5))
	if lus != null:
		lus.scale = Vector3.ONE * 0.8
	luz(r, Vector3(0, MH - 1.3, 0.5), Color(1.0, 0.82, 0.55), 1.6, 11.0)
	luz(r, Vector3(-3.5, 2.2, 2.5), Color(1.0, 0.9, 0.75), 0.6, 8.0)

## Fogo de verdade (partículas) para a lareira.
static func _chamas(pai: Node3D, pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 30
	p.lifetime = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.35, 0.05, 0.15)
	p.direction = Vector3.UP
	p.spread = 8.0
	p.gravity = Vector3(0, 1.6, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.9, 0.5, 0.0))
	g.set_color(1, Color(0.7, 0.1, 0.02, 0.0))
	g.add_point(0.25, Color(1.0, 0.6, 0.15, 0.95))
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.45)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var gg := Gradient.new()
	gg.set_color(0, Color(1, 1, 1, 1))
	gg.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = gg
	m.albedo_texture = tex
	q.material = m
	p.mesh = q
	p.position = pos
	pai.add_child(p)

## Casa de aldeão: lareira de tijolos com fogo, cama do casal e cama do filho, mesa com 4 cadeiras e louça,
## banco em frente à lareira (onde a família senta à noite), estante, armário, baú, barris e lustre de velas.
static func _casa_medieval(r: Node3D, tap: Color) -> void:
	_sala_medieval(r, false)
	var tij := Construcoes.textura_pedras()
	var lx := 2.6
	var zn := -MD * 0.5
	caixa(r, Vector3(lx, 0.65, zn + 0.55), Vector3(2.6, 1.3, 0.8), Color(0.62, 0.42, 0.34), true, true, false, tij, 0.9)     # lareira
	caixa(r, Vector3(lx, 1.38, zn + 0.6), Vector3(2.9, 0.14, 1.0), Color(0.45, 0.32, 0.25), false, true, false, tij, 0.9)    # prateleira
	caixa(r, Vector3(lx, (1.45 + MH) * 0.5, zn + 0.45), Vector3(1.5, MH - 1.45, 0.6), Color(0.62, 0.42, 0.34), false, true, false, tij, 0.9)   # chaminé
	caixa(r, Vector3(lx, 0.45, zn + 0.96), Vector3(1.5, 0.8, 0.04), Color(0.05, 0.04, 0.03))                                 # boca escura
	for k in 3:   # lenha queimando
		Construcoes.tora(r, Vector3(lx - 0.5, 0.12, zn + 1.05 + k * 0.08), Vector3(lx + 0.5, 0.12 + (k % 2) * 0.06, zn + 1.0 + k * 0.1), 0.07, Construcoes.mat(Color(0.18, 0.11, 0.07)))
	_chamas(r, Vector3(lx, 0.2, zn + 1.05))
	luz(r, Vector3(lx, 0.9, zn + 1.8), Color(1.0, 0.55, 0.2), 1.4, 6.0)
	peca(r, MP + "Pot_1.gltf", Vector3(lx + 1.7, 0, zn + 0.9))
	peca(r, MP + "Bucket_Wooden_1.gltf", Vector3(lx - 1.8, 0, zn + 0.9))
	for k in 3:
		peca(r, MP + "Vase_2.gltf", Vector3(lx - 0.9 + k * 0.9, 1.45, zn + 0.6), 0.0, 0.6)
	peca(r, MP + "Bench.gltf", Vector3(lx, 0, -2.3))                                             # banco da família
	peca(r, MP + "Bed_Twin1.gltf", Vector3(-4.7, 0, -3.6))                                      # cama do casal
	peca(r, MP + "Nightstand_Shelf.gltf", Vector3(-3.3, 0, -4.6))
	peca(r, MP + "CandleStick_Triple.gltf", Vector3(-3.3, 0.72, -4.6), 0.0, 0.8)
	peca(r, MP + "Chest_Wood.gltf", Vector3(-4.7, 0, -1.9))
	peca(r, MP + "Bed_Twin2.gltf", Vector3(-4.7, 0, 2.5), 0.0, 0.85)                            # cama do filho
	peca(r, MP + "Table_Large.gltf", Vector3(2.6, 0, 1.6))                                      # mesa com 4 cadeiras
	for x: float in [1.8, 3.4]:
		peca(r, MP + "Chair_1.gltf", Vector3(x, 0, 0.85))
		peca(r, MP + "Chair_1.gltf", Vector3(x, 0, 2.35), PI)
		peca(r, MP + "Table_Plate.gltf", Vector3(x, 0.81, 1.35))
		peca(r, MP + "Mug.gltf", Vector3(x + 0.3, 0.81, 1.5))
	peca(r, MP + "Bookcase_2.gltf", Vector3(-1.4, 0, -MD * 0.5 + 0.35))
	peca(r, MP + "Cabinet.gltf", Vector3(MW * 0.5 - 0.35, 0, -1.6), -PI * 0.5)
	peca(r, MP + "Pot_1_Lid.gltf", Vector3(MW * 0.5 - 0.35, 1.0, -1.9))
	peca(r, MP + "Barrel.gltf", Vector3(5.1, 0, 4.1))
	peca(r, MP + "Barrel_Apples.gltf", Vector3(4.2, 0, 4.3))
	peca(r, MP + "Lantern_Wall.gltf", Vector3(-1.9, 2.1, MD * 0.5 - 0.3), PI)
	cilindro(r, Vector3(-0.4, 0, 0.0), 1.7, 0.02, tap.lightened(0.1))                          # tapete

## Armazém por dentro: paredes de tijolo, prateleiras, caixotes, barris, sacos e o estoque do tipo.
static func _armazem_medieval(r: Node3D, tipo: String) -> void:
	_sala_medieval(r, true)
	for i in 4:   # prateleiras nas laterais
		peca(r, MP + "Shelf_Simple.gltf", Vector3(-MW * 0.5 + 0.35, 0, -3.5 + i * 2.2), PI * 0.5)
		peca(r, MP + "Shelf_Simple.gltf", Vector3(MW * 0.5 - 0.35, 0, -3.5 + i * 2.2), -PI * 0.5)
	for i in 5:
		peca(r, MP + "Crate_Wooden.gltf", Vector3(-4.5 + i * 0.9, 0, -4.2), i * 0.4)
		peca(r, MP + "Bag.gltf", Vector3(-4.0 + i * 0.95, 0, 3.6), i * 0.7)
	peca(r, MP + "Workbench.gltf", Vector3(3.5, 0, -4.1))
	peca(r, MP + "Barrel.gltf", Vector3(4.8, 0, 3.8))
	peca(r, MP + "Barrel.gltf", Vector3(4.0, 0, 4.2))
	peca(r, MP + "Rope_1.gltf", Vector3(3.2, 0.89, -4.1))
	match tipo:
		"madeira":   # toras empilhadas
			for fila in 3:
				for k in 6 - fila:
					var x := -2.0 + (k - (5 - fila) * 0.5) * 0.45
					Construcoes.tora(r, Vector3(x, 0.22 + fila * 0.4, -1.8), Vector3(x, 0.22 + fila * 0.4, 1.0), 0.21, Construcoes.mat(Color(0.45, 0.31, 0.18)))
		"pedra":   # blocos de pedra
			for k in 14:
				caixa(r, Vector3(-3.0 + (k % 5) * 0.75, 0.25 + (k / 5) * 0.48, -0.6 + (k % 2) * 0.3), Vector3(0.65, 0.45, 0.6), Color(0.55, 0.55, 0.57), true, true, false, Construcoes.textura_pedras(), 1.2)
		"comida":   # caixotes de feira com maçãs e cenouras, barris de maçã
			for k in 6:
				peca(r, MP + ("FarmCrate_Apple.gltf" if k % 2 == 0 else "FarmCrate_Carrot.gltf"), Vector3(-3.0 + (k % 3) * 1.1, (k / 3) * 0.45, -0.5), 0.0)
			for k in 3:
				peca(r, MP + "Barrel_Apples.gltf", Vector3(1.0 + k * 0.85, 0, -0.5))
		"carne":   # mesa de corte e carnes penduradas
			peca(r, MP + "Table_Large.gltf", Vector3(-1.0, 0, -0.5))
			peca(r, MP + "Table_Knife.gltf", Vector3(-1.3, 0.81, -0.5))
			for x: float in [-3.5, -2.3, 1.5, 2.7]:
				Construcoes.tora(r, Vector3(x - 0.5, 2.2, -2.2), Vector3(x + 0.5, 2.2, -2.2), 0.03, Construcoes.mat(Construcoes.MADEIRA_ESCURA))
				for k in 3:
					var s := SphereMesh.new()
					s.radius = 0.13
					s.height = 0.45
					s.material = _mat(Color(0.6, 0.18, 0.15))
					var mi := MeshInstance3D.new()
					mi.mesh = s
					mi.position = Vector3(x - 0.35 + k * 0.35, 1.85, -2.2)
					r.add_child(mi)
