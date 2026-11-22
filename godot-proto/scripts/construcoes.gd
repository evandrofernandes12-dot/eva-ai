class_name Construcoes
## Peças de madeira e pedra montadas por código, no estilo das referências enviadas pelo usuário:
## torre de vigia de troncos com balista, paliçada pontuda amarrada com corda e adereços da aldeia.

static var _mats := {}
static var _veios: NoiseTexture2D

## Textura de veios/casca (ruído esticado ao longo da tora; gerada uma vez só).
static func textura_veios() -> NoiseTexture2D:
	if _veios == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.04
		n.fractal_octaves = 4
		var g := Gradient.new()
		g.set_color(0, Color(0.55, 0.55, 0.55))
		g.set_color(1, Color(1.08, 1.05, 1.0))
		_veios = NoiseTexture2D.new()
		_veios.width = 256
		_veios.height = 256
		_veios.seamless = true
		_veios.noise = n
		_veios.color_ramp = g
	return _veios

## Material de madeira (com veios) ou liso, guardado em cache por cor.
static func mat(cor: Color, veios := true, rugosidade := 0.92) -> StandardMaterial3D:
	var k := "%s/%s/%s" % [cor.to_html(), veios, rugosidade]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	if veios:
		m.albedo_texture = textura_veios()
		m.uv1_scale = Vector3(3.0, 0.45, 1.0)   # veios compridos ao longo da peça
	_mats[k] = m
	return m

const MADEIRA := Color(0.5, 0.34, 0.2)
const MADEIRA_ESCURA := Color(0.33, 0.22, 0.13)
const CORDA := Color(0.62, 0.52, 0.34)

## Tora (cilindro) de `a` até `b`.
static func tora(pai: Node3D, a: Vector3, b: Vector3, raio: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raio * 0.9
	cm.bottom_radius = raio
	cm.height = a.distance_to(b)
	cm.radial_segments = 7
	cm.rings = 1
	cm.material = m
	mi.mesh = cm
	var d := (b - a).normalized()
	var q := Quaternion(Vector3.UP, d) if absf(d.dot(Vector3.UP)) < 0.9999 else Quaternion()
	if d.dot(Vector3.UP) < -0.9999:
		q = Quaternion(Vector3.RIGHT, PI)
	mi.transform = Transform3D(Basis(q), (a + b) * 0.5)
	pai.add_child(mi)
	return mi

static func caixa(pai: Node3D, pos: Vector3, tam: Vector3, m: Material, giro_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	bm.material = m
	mi.mesh = bm
	mi.position = pos
	mi.rotation.y = giro_y
	pai.add_child(mi)
	return mi

## Torre de vigia de troncos (≈ 9 m): pernas inclinadas com travas em X, plataforma com parapeito,
## telhado de 4 águas, escada de mão e uma balista que gira para o alvo (nó "Balista", marcador "Ponta").
static func torre_vigia() -> Node3D:
	var r := Node3D.new()
	r.name = "TorreVigia"
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	var cantos := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var perna := func(c: Vector2, y: float) -> Vector3:   # ponto da perna na altura y (base 1,9 → topo 1,35)
		var h := lerpf(1.9, 1.35, y / 8.0)
		return Vector3(c.x * h, y, c.y * h)
	for c: Vector2 in cantos:
		tora(r, perna.call(c, 0.0), perna.call(c, 8.1), 0.17, m)
	for i in 4:
		var c1: Vector2 = cantos[i]
		var c2: Vector2 = cantos[(i + 1) % 4]
		for faixa in [[0.4, 3.3], [3.3, 6.3]]:
			tora(r, perna.call(c1, faixa[0]), perna.call(c2, faixa[1]), 0.08, me)
			tora(r, perna.call(c2, faixa[0]), perna.call(c1, faixa[1]), 0.08, me)
			tora(r, perna.call(c1, faixa[1]), perna.call(c2, faixa[1]), 0.1, m)
		tora(r, perna.call(c1, 0.4), perna.call(c2, 0.4), 0.1, m)
		# parapeito: corrimão e tábuas em pé
		var a: Vector3 = perna.call(c1, 7.3)
		var b: Vector3 = perna.call(c2, 7.3)
		tora(r, a, b, 0.07, m)
		var lado := (b - a)
		var giro := atan2(lado.x, lado.z)
		for k in 8:
			var t := (k + 0.5) / 8.0
			var p := a.lerp(b, t)
			caixa(r, Vector3(p.x, 6.95, p.z), Vector3(0.05, 0.75, lado.length() / 8.0 - 0.04), m, giro)
	# piso da plataforma e telhado
	caixa(r, Vector3(0, 6.45, 0), Vector3(3.4, 0.18, 3.4), me)
	var tel := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 2.7
	cm.height = 1.5
	cm.radial_segments = 4
	cm.rings = 1
	cm.material = mat(Color(0.36, 0.25, 0.17))
	tel.mesh = cm
	tel.position = Vector3(0, 8.8, 0)
	tel.rotation.y = PI / 4.0
	r.add_child(tel)
	# escada de mão (lado +X)
	for z in [-0.32, 0.32]:
		tora(r, Vector3(2.45, 0, z), Vector3(1.55, 6.5, z), 0.06, m)
	for k in 15:
		var t := (k + 1) / 16.0
		var px := lerpf(2.45, 1.55, t)
		tora(r, Vector3(px, t * 6.5, -0.32), Vector3(px, t * 6.5, 0.32), 0.035, me)
	# escudo pendurado no parapeito
	var esc := MeshInstance3D.new()
	var em := CylinderMesh.new()
	em.top_radius = 0.38
	em.bottom_radius = 0.38
	em.height = 0.06
	em.material = mat(Color(0.15, 0.25, 0.55), false, 0.6)
	esc.mesh = em
	esc.position = Vector3(0, 7.0, -1.5)
	esc.rotation.x = PI / 2.0
	r.add_child(esc)
	r.add_child(balista())
	return r

## Balista no alto da torre: suporte, trilho, arco largo e um dardo. Gira em Y para mirar.
static func balista() -> Node3D:
	var b := Node3D.new()
	b.name = "Balista"
	b.position = Vector3(0, 6.55, 0)
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	tora(b, Vector3(0, 0, 0), Vector3(0, 0.85, 0), 0.09, me)
	caixa(b, Vector3(0, 0.95, 0.1), Vector3(0.18, 0.14, 1.5), m)
	for lado in [-1.0, 1.0]:
		tora(b, Vector3(0, 0.98, 0.7), Vector3(lado * 0.85, 1.0, 0.45), 0.045, me)
	var corda := mat(CORDA, false)
	for lado in [-1.0, 1.0]:
		tora(b, Vector3(lado * 0.85, 1.0, 0.45), Vector3(0, 1.0, -0.1), 0.01, corda)
	tora(b, Vector3(0, 1.05, -0.1), Vector3(0, 1.05, 0.95), 0.025, mat(Color(0.3, 0.3, 0.32), false, 0.5))
	var ponta := Marker3D.new()
	ponta.name = "Ponta"
	ponta.position = Vector3(0, 1.05, 1.0)
	b.add_child(ponta)
	return b
