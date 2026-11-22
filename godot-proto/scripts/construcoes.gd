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

# ---------- adereços da aldeia ----------
## Colisão simples (caixa) para adereços grandes.
static func solido(pai: Node3D, pos: Vector3, tam: Vector3) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = tam
	cs.shape = sh
	sb.add_child(cs)
	sb.position = pos
	pai.add_child(sb)

## Poste com lampião (vidro com brilho próprio, sem luz de verdade para não pesar no tablet).
static func lampiao() -> Node3D:
	var r := Node3D.new()
	var me := mat(MADEIRA_ESCURA)
	var ferro := mat(Color(0.12, 0.12, 0.13), false, 0.5)
	tora(r, Vector3.ZERO, Vector3(0, 3.0, 0), 0.08, me)
	tora(r, Vector3(0, 2.85, 0), Vector3(0.55, 2.85, 0), 0.035, me)
	tora(r, Vector3(0.55, 2.85, 0), Vector3(0.55, 2.6, 0), 0.008, ferro)
	caixa(r, Vector3(0.55, 2.45, 0), Vector3(0.24, 0.04, 0.24), ferro)
	caixa(r, Vector3(0.55, 2.2, 0), Vector3(0.22, 0.04, 0.22), ferro)
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color(1.0, 0.75, 0.35)
	vidro.emission_enabled = true
	vidro.emission = Color(1.0, 0.62, 0.22)
	vidro.emission_energy_multiplier = 1.6
	caixa(r, Vector3(0.55, 2.32, 0), Vector3(0.17, 0.22, 0.17), vidro)
	return r

## Placa de direção com tábuas apontando para os lugares.
static func placa(nomes: Array, giros: Array) -> Node3D:
	var r := Node3D.new()
	var m := mat(MADEIRA)
	tora(r, Vector3.ZERO, Vector3(0, 2.6, 0), 0.07, mat(MADEIRA_ESCURA))
	for i in nomes.size():
		var braco := Node3D.new()
		braco.position.y = 2.3 - i * 0.38
		braco.rotation.y = giros[i]
		r.add_child(braco)
		caixa(braco, Vector3(0, 0, 0.55), Vector3(0.05, 0.26, 1.0), m)
		var t := Label3D.new()
		t.text = nomes[i]
		t.font_size = 40
		t.pixel_size = 0.004
		t.modulate = Color(0.15, 0.08, 0.03)
		t.outline_size = 0
		t.position = Vector3(0.03, 0, 0.55)
		t.rotation.y = PI / 2.0
		braco.add_child(t)
		var t2 := t.duplicate() as Label3D
		t2.position.x = -0.03
		t2.rotation.y = -PI / 2.0
		braco.add_child(t2)
	return r

## Fardos de feno empilhados.
static func feno() -> Node3D:
	var r := Node3D.new()
	var m := mat(Color(0.86, 0.72, 0.38))
	var corda := mat(CORDA, false)
	var pos := [Vector3(0, 0.3, 0), Vector3(1.05, 0.3, 0.05), Vector3(0.5, 0.9, 0.0), Vector3(-0.2, 0.3, 0.9)]
	for i in pos.size():
		var p: Vector3 = pos[i]
		var gy := 0.15 * sin(i * 2.3)
		caixa(r, p, Vector3(1.0, 0.6, 0.62), m, gy)
		for dx in [-0.25, 0.25]:
			var f := caixa(r, p + Vector3(dx, 0, 0).rotated(Vector3.UP, gy), Vector3(0.04, 0.62, 0.64), corda, gy)
			f.scale = Vector3.ONE
	solido(r, Vector3(0.4, 0.6, 0.3), Vector3(2.2, 1.2, 1.8))
	return r

## Caixote de madeira com reforços nas bordas.
static func caixote(tam := 0.7) -> Node3D:
	var r := Node3D.new()
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	caixa(r, Vector3(0, tam * 0.5, 0), Vector3.ONE * tam, m)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			caixa(r, Vector3(sx * tam * 0.48, tam * 0.5, sz * tam * 0.48), Vector3(0.07, tam + 0.02, 0.07), me)
	caixa(r, Vector3(0, tam * 0.5, tam * 0.5), Vector3(tam * 0.95, 0.07, 0.03), me).rotation.z = PI / 4.0
	return r

## Pilha de lenha (toras deitadas) com um toco e machado.
static func lenha() -> Node3D:
	var r := Node3D.new()
	var m := mat(Color(0.48, 0.33, 0.2))
	var corte := mat(Color(0.78, 0.62, 0.42), false)
	for fila in 3:
		for k in 5 - fila:
			var x := (k - (4 - fila) * 0.5) * 0.32
			var y := 0.15 + fila * 0.27
			tora(r, Vector3(x, y, -0.6), Vector3(x, y, 0.6), 0.14, m)
			for z in [-0.6, 0.6]:
				caixa(r, Vector3(x, y, z), Vector3(0.24, 0.24, 0.01), corte)
	tora(r, Vector3(1.2, 0, 0.2), Vector3(1.2, 0.5, 0.2), 0.28, m)
	tora(r, Vector3(1.2, 0.5, 0.2), Vector3(1.4, 1.05, 0.25), 0.03, mat(MADEIRA_ESCURA))
	caixa(r, Vector3(1.22, 0.55, 0.22), Vector3(0.04, 0.16, 0.26), mat(Color(0.5, 0.5, 0.52), false, 0.4)).rotation.z = 0.35
	solido(r, Vector3(0.3, 0.45, 0), Vector3(2.2, 0.9, 1.3))
	return r

## Varal com roupas entre dois postes (de `a` a `b`, no chão).
static func varal(a: Vector3, b: Vector3) -> Node3D:
	var r := Node3D.new()
	var me := mat(MADEIRA_ESCURA)
	tora(r, a, a + Vector3(0, 2.0, 0), 0.06, me)
	tora(r, b, b + Vector3(0, 2.0, 0), 0.06, me)
	tora(r, a + Vector3(0, 1.9, 0), b + Vector3(0, 1.9, 0), 0.01, mat(CORDA, false))
	var cores := [Color(0.9, 0.88, 0.8), Color(0.55, 0.65, 0.8), Color(0.8, 0.45, 0.35), Color(0.85, 0.8, 0.55)]
	var giro := atan2((b - a).x, (b - a).z)
	for i in 4:
		var p := a.lerp(b, (i + 0.7) / 5.0) + Vector3(0, 1.55, 0)
		caixa(r, p, Vector3(0.02, 0.65, 0.55), mat(cores[i], false, 1.0), giro)
	return r

## Cocho de água para os animais.
static func cocho() -> Node3D:
	var r := Node3D.new()
	var m := mat(MADEIRA)
	caixa(r, Vector3(0, 0.25, 0), Vector3(1.8, 0.08, 0.6), m)
	for s in [-1.0, 1.0]:
		caixa(r, Vector3(0, 0.45, s * 0.28), Vector3(1.8, 0.45, 0.06), m)
		caixa(r, Vector3(s * 0.88, 0.45, 0), Vector3(0.06, 0.45, 0.6), m)
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.25, 0.42, 0.5)
	agua.roughness = 0.05
	agua.metallic = 0.3
	caixa(r, Vector3(0, 0.58, 0), Vector3(1.7, 0.02, 0.5), agua)
	solido(r, Vector3(0, 0.4, 0), Vector3(1.8, 0.8, 0.6))
	return r

## Banca de feira com toldo listrado e mercadorias.
static func banca(cor: Color) -> Node3D:
	var r := Node3D.new()
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	for sx in [-1.2, 1.2]:
		for sz in [-0.7, 0.7]:
			tora(r, Vector3(sx, 0, sz), Vector3(sx, 2.3 if sz < 0 else 2.0, sz), 0.06, me)
	caixa(r, Vector3(0, 0.9, 0.2), Vector3(2.5, 0.1, 1.0), m)
	caixa(r, Vector3(0, 0.5, 0.68), Vector3(2.5, 0.8, 0.05), m)
	for i in 6:   # toldo listrado inclinado
		var tl := caixa(r, Vector3(-1.25 + (i + 0.5) * 2.6 / 6.0, 2.2, 0.0), Vector3(2.6 / 6.0, 0.03, 1.8), mat(cor if i % 2 == 0 else Color(0.93, 0.9, 0.82), false, 1.0))
		tl.rotation.x = 0.17
	var frutas := [Color(0.8, 0.2, 0.15), Color(0.95, 0.7, 0.2), Color(0.4, 0.6, 0.25)]
	for i in 3:
		var cesto := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.3
		cm.bottom_radius = 0.22
		cm.height = 0.2
		cm.material = mat(Color(0.6, 0.45, 0.25))
		cesto.mesh = cm
		cesto.position = Vector3(-0.8 + i * 0.8, 1.05, 0.25)
		r.add_child(cesto)
		var sm := SphereMesh.new()
		sm.radius = 0.24
		sm.height = 0.2
		sm.material = mat(frutas[i], false, 0.5)
		var f := MeshInstance3D.new()
		f.mesh = sm
		f.position = cesto.position + Vector3(0, 0.12, 0)
		r.add_child(f)
	solido(r, Vector3(0, 0.6, 0.2), Vector3(2.6, 1.2, 1.2))
	return r

## Faixa de terra batida (caminho) de `a` a `b`, rente ao chão.
static func caminho(pai: Node3D, a: Vector3, b: Vector3, largura: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(largura, a.distance_to(b))
	var m := mat(Color(0.56, 0.47, 0.35))
	pm.material = m
	mi.mesh = pm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = (a + b) * 0.5 + Vector3(0, 0.025, 0)
	mi.rotation.y = atan2((b - a).x, (b - a).z)
	pai.add_child(mi)

# ---------- estilo das casas (referências: enxaimel, reboco creme, telhado de ardósia azul) ----------
const ESTILO := {
	"RoofTiles": Color(0.24, 0.32, 0.5), "RoofTiles_Red": Color(0.24, 0.32, 0.5),
	"Plaster": Color(0.9, 0.84, 0.7), "Beige": Color(0.9, 0.84, 0.7),
	"Wood": Color(0.38, 0.24, 0.13), "DarkWood": Color(0.3, 0.19, 0.1), "Wood_Light": Color(0.52, 0.35, 0.19), "Wood_Side": Color(0.62, 0.47, 0.3),
	"Stone_Light": Color(0.66, 0.67, 0.68), "Stone_Dark": Color(0.47, 0.49, 0.52), "Stone": Color(0.38, 0.38, 0.41),
}

## Troca as cores lisas dos prédios (Quaternius) por cores das referências, com textura triplanar.
static func estilo_casa(raiz: Node) -> void:
	var malhas: Array = []
	Fit._collect(raiz, malhas)
	for mi: MeshInstance3D in malhas:
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var orig := mi.mesh.surface_get_material(i)
			if orig == null or not ESTILO.has(orig.resource_name):
				continue
			var k := "casa/" + orig.resource_name
			if not _mats.has(k):
				var m := StandardMaterial3D.new()
				m.albedo_color = ESTILO[orig.resource_name]
				m.roughness = 0.9
				m.albedo_texture = textura_veios()
				m.uv1_triplanar = true
				m.uv1_scale = Vector3(0.7, 0.7, 0.7) if orig.resource_name.begins_with("Stone") or orig.resource_name.begins_with("Roof") else Vector3(0.35, 1.6, 0.35)
				_mats[k] = m
			mi.set_surface_override_material(i, _mats[k])
