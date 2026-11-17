class_name Interior
## Interiores das construções da aldeia (gerados por código). Cada um é uma sala fechada,
## longe do mapa; o jogador entra pelo botão ENTRAR e sai pelo botão SAIR.

const BARRIL := preload("res://models/Barrel.glb")
const FOGO := preload("res://models/Bonfire_Lit.glb")
const REI := preload("res://models/Knight.glb")

## nome do nó em "Aldeia": título, largura, fundo (m), cor do piso, cor das paredes
const SALAS := {
	"SalaoDoChefe": {"nome": "Salão do Rei", "w": 24.0, "d": 18.0, "piso": Color(0.36, 0.3, 0.26), "parede": Color(0.5, 0.46, 0.42)},
	"Casa1": {"nome": "Casa", "w": 12.0, "d": 10.0, "piso": Color(0.5, 0.35, 0.2), "parede": Color(0.72, 0.6, 0.45)},
	"Casa2": {"nome": "Casa", "w": 12.0, "d": 10.0, "piso": Color(0.5, 0.35, 0.2), "parede": Color(0.68, 0.55, 0.4)},
	"Casa3": {"nome": "Casa", "w": 12.0, "d": 10.0, "piso": Color(0.5, 0.35, 0.2), "parede": Color(0.75, 0.62, 0.5)},
	"Forja": {"nome": "Forja", "w": 12.0, "d": 10.0, "piso": Color(0.28, 0.27, 0.27), "parede": Color(0.4, 0.38, 0.38)},
}

static func _mat(cor: Color, brilho := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.85
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

## Monta a sala. Devolve a raiz; `rei` (meta) é o nó do Rei, quando existe.
static func construir(id: String) -> Node3D:
	var s: Dictionary = SALAS[id]
	var w: float = s.w
	var d: float = s.d
	var raiz := Node3D.new()
	raiz.name = "Interior_" + id
	var alt := 4.2
	var pa: Color = s.parede
	# piso (com colisão grossa) e paredes; a parede sul (entrada) só tem colisão, para a câmera enxergar
	caixa(raiz, Vector3(0, -0.5, 0), Vector3(w, 1.0, d), s.piso, true)
	caixa(raiz, Vector3(0, alt * 0.5, -d * 0.5), Vector3(w, alt, 0.5), pa, true)
	caixa(raiz, Vector3(-w * 0.5, alt * 0.5, 0), Vector3(0.5, alt, d), pa, true)
	caixa(raiz, Vector3(w * 0.5, alt * 0.5, 0), Vector3(0.5, alt, d), pa, true)
	caixa(raiz, Vector3(0, alt * 0.5, d * 0.5), Vector3(w, alt, 0.5), pa, true, false)
	# tapete da porta
	caixa(raiz, Vector3(0, 0.02, d * 0.5 - 1.2), Vector3(2.6, 0.04, 1.6), Color(0.3, 0.12, 0.1))
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, 3.6, 0)
	luz.omni_range = maxf(w, d) * 1.1
	luz.light_energy = 1.4
	luz.light_color = Color(1.0, 0.85, 0.65)
	raiz.add_child(luz)
	var madeira := Color(0.42, 0.27, 0.14)
	match id:
		"SalaoDoChefe":
			caixa(raiz, Vector3(0, 0.025, 1.0), Vector3(4.0, 0.05, d - 4.0), Color(0.55, 0.08, 0.1))      # tapete vermelho
			for x in [-8.0, 8.0]:
				for z in [-5.0, 2.0]:
					coluna(raiz, Vector3(x, 0, z), 0.5, alt, Color(0.6, 0.58, 0.55))
			# trono
			caixa(raiz, Vector3(0, 0.6, -d * 0.5 + 2.0), Vector3(2.2, 1.2, 1.8), Color(0.45, 0.3, 0.1), true)
			caixa(raiz, Vector3(0, 1.0, -d * 0.5 + 1.2), Vector3(1.6, 2.4, 0.3), Color(0.85, 0.7, 0.2), true)
			for x in [-5.0, 5.0]:       # estandartes
				caixa(raiz, Vector3(x, 2.4, -d * 0.5 + 0.35), Vector3(1.4, 2.4, 0.08), Color(0.7, 0.1, 0.12))
			for x in [-3.0, 3.0]:       # mesas de banquete
				caixa(raiz, Vector3(x * 3.0, 0.5, 5.0), Vector3(1.6, 0.1, 4.0), madeira, true)
				caixa(raiz, Vector3(x * 3.0, 0.25, 5.0), Vector3(1.4, 0.5, 3.8), madeira)
			modelo(raiz, FOGO, Vector3(-9.0, 0, -6.5), 1.2)
			modelo(raiz, FOGO, Vector3(9.0, 0, -6.5), 1.2)
			var rei := Node3D.new()
			rei.name = "Rei"
			rei.position = Vector3(0, 1.2, -d * 0.5 + 2.0)
			raiz.add_child(rei)
			var m := modelo(rei, REI, Vector3.ZERO, 1.95)
			m.rotation.y = 0.0
			var ap := Fit.find_node_of(m, "AnimationPlayer") as AnimationPlayer
			Fit.play(ap, Fit.find_anim(ap, ["Idle"]))
			var coroa := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.17
			cm.bottom_radius = 0.13
			cm.height = 0.16
			cm.material = _mat(Color(1.0, 0.82, 0.2), true)
			coroa.mesh = cm
			coroa.position = Vector3(0, 2.0, 0)
			rei.add_child(coroa)
			caixa(rei, Vector3(0, 1.2, -0.3), Vector3(0.8, 1.4, 0.06), Color(0.7, 0.08, 0.1))   # manto
			var nome := Label3D.new()
			nome.text = "Rei"
			nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			nome.font_size = 72
			nome.outline_size = 14
			nome.modulate = Color(1.0, 0.88, 0.4)
			nome.position = Vector3(0, 2.7, 0)
			rei.add_child(nome)
			raiz.set_meta("rei", rei)
		"Forja":
			modelo(raiz, FOGO, Vector3(-3.5, 0, -3.2), 1.6)
			caixa(raiz, Vector3(0, 0.5, -2.8), Vector3(2.4, 1.0, 1.0), Color(0.3, 0.3, 0.33), true)       # bigorna
			caixa(raiz, Vector3(3.5, 0.5, -3.5), Vector3(2.6, 1.0, 1.0), madeira, true)                   # bancada
			modelo(raiz, BARRIL, Vector3(-5.0, 0, 3.0), 1.1)
			modelo(raiz, BARRIL, Vector3(5.0, 0, 3.4), 1.1)
		_:
			caixa(raiz, Vector3(-4.2, 0.35, -3.5), Vector3(2.0, 0.7, 3.0), madeira, true)                 # cama
			caixa(raiz, Vector3(-4.2, 0.8, -4.6), Vector3(1.8, 0.2, 0.7), Color(0.9, 0.9, 0.85))           # travesseiro
			caixa(raiz, Vector3(1.0, 0.45, -1.0), Vector3(2.2, 0.1, 1.2), madeira, true)                  # mesa
			caixa(raiz, Vector3(1.0, 0.22, -1.0), Vector3(2.0, 0.44, 1.0), madeira)
			caixa(raiz, Vector3(1.0, 0.28, 0.3), Vector3(0.6, 0.56, 0.6), madeira, true)                  # banco
			caixa(raiz, Vector3(3.2, 0.9, -d * 0.5 + 0.5), Vector3(1.6, 1.8, 0.8), Color(0.35, 0.33, 0.32), true)   # lareira
			caixa(raiz, Vector3(3.2, 0.45, -d * 0.5 + 0.95), Vector3(0.9, 0.5, 0.1), Color(1.0, 0.45, 0.1), false, true, true)
			modelo(raiz, BARRIL, Vector3(-5.0, 0, 3.0), 1.0)
	return raiz
