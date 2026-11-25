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
	for z: float in [-0.32, 0.32]:
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
	for lado: float in [-1.0, 1.0]:
		tora(b, Vector3(0, 0.98, 0.7), Vector3(lado * 0.85, 1.0, 0.45), 0.045, me)
	var corda := mat(CORDA, false)
	for lado: float in [-1.0, 1.0]:
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
## Vidro dos lampiões: um material só, para o Ceu acender/apagar todos de uma vez.
static func vidro_lampiao() -> StandardMaterial3D:
	if not _mats.has("vidro_lampiao"):
		var vidro := StandardMaterial3D.new()
		vidro.albedo_color = Color(1.0, 0.75, 0.35)
		vidro.emission_enabled = true
		vidro.emission = Color(1.0, 0.62, 0.22)
		vidro.emission_energy_multiplier = 0.3
		_mats["vidro_lampiao"] = vidro
	return _mats["vidro_lampiao"]

static func lampiao(com_luz := false) -> Node3D:
	var r := Node3D.new()
	var me := mat(MADEIRA_ESCURA)
	var ferro := mat(Color(0.12, 0.12, 0.13), false, 0.5)
	tora(r, Vector3.ZERO, Vector3(0, 3.0, 0), 0.08, me)
	tora(r, Vector3(0, 2.85, 0), Vector3(0.55, 2.85, 0), 0.035, me)
	tora(r, Vector3(0.55, 2.85, 0), Vector3(0.55, 2.6, 0), 0.008, ferro)
	caixa(r, Vector3(0.55, 2.45, 0), Vector3(0.24, 0.04, 0.24), ferro)
	caixa(r, Vector3(0.55, 2.2, 0), Vector3(0.22, 0.04, 0.22), ferro)
	caixa(r, Vector3(0.55, 2.32, 0), Vector3(0.17, 0.22, 0.17), vidro_lampiao())
	if com_luz:   # luz de verdade (acende à noite pelo Ceu); só em poucos lampiões, para não pesar
		var o := OmniLight3D.new()
		o.name = "Luz"
		o.position = Vector3(0.55, 2.2, 0)
		o.light_color = Color(1.0, 0.7, 0.4)
		o.omni_range = 9.0
		o.light_energy = 0.0
		o.visible = false
		r.add_child(o)
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
		for dx: float in [-0.25, 0.25]:
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
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
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
			for z: float in [-0.6, 0.6]:
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
	for s: float in [-1.0, 1.0]:
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
	for sx: float in [-1.2, 1.2]:
		for sz: float in [-0.7, 0.7]:
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

## Terra batida PBR (ambientCG Ground037), em coordenadas do mundo (não estica nos caminhos compridos).
static func mat_terra() -> StandardMaterial3D:
	if _mats.has("terra_pbr"):
		return _mats["terra_pbr"]
	const T := "res://assets/textures/ground/Ground037/Ground037_1K-JPG_"
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(T + "Color.jpg")
	m.albedo_color = Color(0.95, 0.9, 0.85)
	m.normal_enabled = true
	m.normal_texture = load(T + "NormalGL.jpg")
	m.roughness_texture = load(T + "Roughness.jpg")
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.33
	_mats["terra_pbr"] = m
	return m

## Faixa de terra batida (caminho) de `a` a `b`, rente ao chão.
static func caminho(pai: Node3D, a: Vector3, b: Vector3, largura: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(largura, a.distance_to(b))
	pm.material = mat_terra()
	mi.mesh = pm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = (a + b) * 0.5 + Vector3(0, 0.007, 0)
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

# ---------- riacho e pontes ----------
## Ponte em arco ao longo de X (centrada), `comp` de comprimento e `larg` de largura.
## Madeira: tábuas, vigas em arco e corrimão com postes. Pedra: tabuleiro e muretas de pedra.
## Tem colisão em rampas para o personagem subir por cima.
static func ponte(comp: float, larg: float, pedra: bool) -> Node3D:
	var r := Node3D.new()
	var subida := 0.7
	var n := 10
	var m := mat(Color(0.6, 0.6, 0.62) if pedra else MADEIRA, true)
	var me := mat(Color(0.45, 0.45, 0.48) if pedra else MADEIRA_ESCURA, true)
	var y_de := func(x: float) -> float: return subida * cos(PI * x / comp) - 0.15   # arco: alto no meio; pontas um pouco enterradas (sem degrau)
	for i in n:
		var x0 := -comp * 0.5 + comp * i / n
		var x1 := x0 + comp / n
		var p0 := Vector3(x0, y_de.call(x0), 0)
		var p1 := Vector3(x1, y_de.call(x1), 0)
		var meio := (p0 + p1) * 0.5
		var incl := atan2(p1.y - p0.y, x1 - x0)
		var seg := comp / n / cos(incl)
		var tab := caixa(r, meio + Vector3(0, -0.04 if pedra else 0.08, 0), Vector3(seg + 0.02, 0.4 if pedra else 0.16, larg), m)   # topo sempre em meio + 0,16
		tab.rotation.z = incl
		if not pedra:
			for k in 3:   # frestas entre as tábuas
				var fr := caixa(r, meio + Vector3((k - 1) * seg / 3.0, 0.165, 0), Vector3(0.03, 0.01, larg), me)
				fr.rotation.z = incl
			for s: float in [-1.0, 1.0]:   # vigas em arco por baixo das bordas
				var vg := caixa(r, meio + Vector3(0, -0.12, s * (larg * 0.5 - 0.15)), Vector3(seg + 0.02, 0.25, 0.22), me)
				vg.rotation.z = incl
		for lado_b: float in [-1.0, 1.0]:   # barreira invisível no corrimão: quem está na ponte só sai pelas pontas
			var bb := StaticBody3D.new()
			var bc := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(seg + 0.05, 1.4, 0.2)
			bc.shape = bs
			bb.add_child(bc)
			bb.position = meio + Vector3(0, 0.85, lado_b * (larg * 0.5 - 0.1))
			bb.rotation.z = incl
			r.add_child(bb)
		for s: float in [-1.0, 1.0]:   # corrimão (madeira) ou mureta (pedra)
			if pedra:
				var mu := caixa(r, meio + Vector3(0, 0.55, s * (larg * 0.5 - 0.2)), Vector3(seg + 0.02, 0.7, 0.4), me)
				mu.rotation.z = incl
			else:
				var cr := caixa(r, meio + Vector3(0, 1.05, s * (larg * 0.5 - 0.08)), Vector3(seg + 0.02, 0.1, 0.1), me)
				cr.rotation.z = incl
				tora(r, Vector3(x0, y_de.call(x0), s * (larg * 0.5 - 0.08)), Vector3(x0, y_de.call(x0) + 1.1, s * (larg * 0.5 - 0.08)), 0.06, me)
		var sb := StaticBody3D.new()   # rampa com colisão: a face de cima coincide com o tabuleiro
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(seg + 0.05, 0.3, larg - 0.3)
		cs.shape = sh
		sb.add_child(cs)
		var normal := Vector3(-sin(incl), cos(incl), 0)
		var topo := 0.16
		sb.position = meio + normal * (topo - 0.15)
		sb.rotation.z = incl
		r.add_child(sb)
	if pedra:   # pilares nas margens
		for s: float in [-1.0, 1.0]:
			caixa(r, Vector3(s * comp * 0.36, -0.2, 0), Vector3(0.8, 0.8, larg + 0.2), me)
	return r

## Riacho em anel (raio que ondula com o ângulo), com margem de terra. Sem colisão: é raso.
static func riacho(raio: Callable, larg: float) -> Node3D:
	var r := Node3D.new()
	r.name = "Riacho"
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.2, 0.36, 0.42)
	agua.roughness = 0.06
	agua.metallic = 0.25
	agua.cull_mode = BaseMaterial3D.CULL_DISABLED
	var margem := mat(Color(0.42, 0.35, 0.25)).duplicate() as StandardMaterial3D
	margem.cull_mode = BaseMaterial3D.CULL_DISABLED
	for camada in [[larg + 2.2, 0.03, margem], [larg, 0.05, agua]]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 240
		var lw: float = camada[0]
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var r0: float = raio.call(a0)
			var r1: float = raio.call(a1)
			var y: float = camada[1]
			var q := [Vector3(cos(a0) * (r0 - lw * 0.5), y, sin(a0) * (r0 - lw * 0.5)), Vector3(cos(a0) * (r0 + lw * 0.5), y, sin(a0) * (r0 + lw * 0.5)),
				Vector3(cos(a1) * (r1 - lw * 0.5), y, sin(a1) * (r1 - lw * 0.5)), Vector3(cos(a1) * (r1 + lw * 0.5), y, sin(a1) * (r1 + lw * 0.5))]
			for k: int in [0, 2, 1, 1, 2, 3]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(float(i) / 8.0, float(k % 2)))
				st.add_vertex(q[k])
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = camada[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r.add_child(mi)
	return r

# ---------- texturas procedurais para interiores (realismo sem arquivos novos) ----------
static var _tex := {}

## Tábuas de assoalho: faixas de madeira com tons diferentes, frestas escuras e veios.
static func textura_tabuas() -> ImageTexture:
	if _tex.has("tabuas"):
		return _tex["tabuas"]
	var n := FastNoiseLite.new()
	n.frequency = 0.08
	var img := Image.create(256, 256, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tons: Array = []
	for k in 8:
		tons.append(rng.randf_range(0.78, 1.05))
	for y in 256:
		for x in 256:
			var tab := x / 32
			var fresta := (x % 32) < 2 or ((y + tab * 97) % 256) < 2
			var veio := 0.88 + 0.12 * n.get_noise_2d(x * 0.35, y * 2.5)
			var v: float = 0.25 if fresta else float(tons[tab]) * veio
			img.set_pixel(x, y, Color(v, v * 0.97, v * 0.93))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex["tabuas"] = t
	return t

## Pedras/tijolos assentados com argamassa (paredes da forja, lareiras).
static func textura_pedras() -> ImageTexture:
	if _tex.has("pedras"):
		return _tex["pedras"]
	var n := FastNoiseLite.new()
	n.frequency = 0.06
	var img := Image.create(256, 256, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var tons := {}
	for y in 256:
		var fila := y / 32
		var desloc := 32 if fila % 2 == 1 else 0
		for x in 256:
			var col := ((x + desloc) % 256) / 64
			var lx := (x + desloc) % 64
			var ly := y % 32
			var junta := lx < 3 or ly < 3
			var k := fila * 8 + col
			if not tons.has(k):
				tons[k] = rng.randf_range(0.72, 1.08)
			var ruido := 0.85 + 0.15 * n.get_noise_2d(x, y)
			var v: float = 0.42 if junta else float(tons[k]) * ruido
			img.set_pixel(x, y, Color(v, v, v * 0.98))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex["pedras"] = t
	return t

## Torre redonda de pedra do castelo: corpo com pedras assentadas, ameias, telhado cônico azul,
## janelinhas e um estandarte azul. Tem colisão.
static func torre_pedra(raio: float, alt: float) -> Node3D:
	var r := Node3D.new()
	var pedra := StandardMaterial3D.new()
	pedra.albedo_color = Color(0.68, 0.67, 0.66)
	pedra.albedo_texture = textura_pedras()
	pedra.uv1_triplanar = true
	pedra.uv1_scale = Vector3.ONE * 0.42
	pedra.roughness = 0.95
	var corpo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raio
	cm.bottom_radius = raio * 1.08
	cm.height = alt
	cm.radial_segments = 20
	cm.material = pedra
	corpo.mesh = cm
	corpo.position.y = alt * 0.5
	r.add_child(corpo)
	var anel := MeshInstance3D.new()   # parapeito largo no alto
	var am := CylinderMesh.new()
	am.top_radius = raio * 1.15
	am.bottom_radius = raio * 1.15
	am.height = 0.6
	am.radial_segments = 20
	am.material = pedra
	anel.mesh = am
	anel.position.y = alt + 0.3
	r.add_child(anel)
	for i in 10:   # ameias
		var a := TAU * i / 10.0
		var me := caixa(r, Vector3(cos(a) * raio * 1.1, alt + 0.95, sin(a) * raio * 1.1), Vector3(0.55, 0.7, 0.4), pedra)
		me.rotation.y = -a
	var tel := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.0
	tm.bottom_radius = raio * 1.2
	tm.height = raio * 2.2
	tm.radial_segments = 16
	tm.material = mat(Color(0.24, 0.32, 0.5))
	tel.mesh = tm
	tel.position.y = alt + 1.3 + raio * 1.1
	r.add_child(tel)
	var escuro := mat(Color(0.08, 0.08, 0.1), false)
	for k in 3:   # janelinhas (seteiras)
		var a := 0.4 + k * 2.1
		var j := caixa(r, Vector3(cos(a) * raio * 1.01, alt * (0.35 + k * 0.2), sin(a) * raio * 1.01), Vector3(0.18, 0.9, 0.5), escuro)
		j.rotation.y = -a
	tora(r, Vector3(0, alt + 1.3 + raio * 2.2, 0), Vector3(0, alt + 3.6 + raio * 2.2, 0), 0.05, mat(MADEIRA_ESCURA))
	caixa(r, Vector3(0.55, alt + 3.0 + raio * 2.2, 0), Vector3(1.0, 0.65, 0.03), mat(Color(0.13, 0.22, 0.52), false, 1.0))
	solido(r, Vector3(0, alt * 0.5, 0), Vector3(raio * 1.6, alt, raio * 1.6))
	return r

# ---------- evolução: pedra e braseiros ----------
## Pedra assentada (paredes de pedra da muralha e da torre), em coordenadas do mundo.
static func mat_pedra() -> StandardMaterial3D:
	if not _mats.has("pedra_muro"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.72, 0.7, 0.66)
		m.albedo_texture = textura_pedras()
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * 0.45
		m.roughness = 0.95
		_mats["pedra_muro"] = m
	return _mats["pedra_muro"]

## Braseiro de ferro com fogo: acende à noite (Ceu procura o grupo "luz_noite").
static func braseiro() -> Node3D:
	var r := Node3D.new()
	var ferro := mat(Color(0.12, 0.12, 0.13), false, 0.5)
	tora(r, Vector3.ZERO, Vector3(0, 0.6, 0), 0.05, ferro)
	var tigela := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.38
	cm.bottom_radius = 0.18
	cm.height = 0.3
	cm.material = ferro
	tigela.mesh = cm
	tigela.position.y = 0.72
	r.add_child(tigela)
	var p := CPUParticles3D.new()
	p.name = "Fogo"
	p.amount = 24
	p.lifetime = 0.7
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3(0, 2.0, 0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.8
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.9, 0.5, 0.0))
	g.set_color(1, Color(0.7, 0.1, 0.02, 0.0))
	g.add_point(0.25, Color(1.0, 0.6, 0.15, 0.95))
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.55)
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
	p.position.y = 0.95
	p.emitting = false
	p.add_to_group("luz_noite")
	r.add_child(p)
	var o := OmniLight3D.new()
	o.light_color = Color(1.0, 0.62, 0.3)
	o.omni_range = 14.0
	o.position.y = 1.3
	o.visible = false
	o.add_to_group("luz_noite")
	r.add_child(o)
	return r

## Torre de vigia conforme o nível: 1 = troncos; 2 = troncos com braseiro; 3 = pedra com ameias e braseiro.
## Todas têm a balista (nó "Balista").
static func torre_nivel(nivel: int) -> Node3D:
	if nivel < 3:
		var t := torre_vigia()
		if nivel >= 2:
			var b := braseiro()
			b.position = Vector3(1.0, 6.55, 1.0)
			t.add_child(b)
		return t
	var r := Node3D.new()
	r.name = "TorreVigia"
	var pedra := mat_pedra()
	var alt := 6.6
	var corpo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.9
	cm.bottom_radius = 2.2
	cm.height = alt
	cm.radial_segments = 16
	cm.material = pedra
	corpo.mesh = cm
	corpo.position.y = alt * 0.5
	r.add_child(corpo)
	var anel := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 2.25
	am.bottom_radius = 2.25
	am.height = 0.45
	am.radial_segments = 16
	am.material = pedra
	anel.mesh = am
	anel.position.y = alt + 0.2
	r.add_child(anel)
	for i in 10:   # ameias
		var a := TAU * i / 10.0
		caixa(r, Vector3(cos(a) * 2.05, alt + 0.75, sin(a) * 2.05), Vector3(0.6, 0.65, 0.4), pedra, -a)
	var escuro := mat(Color(0.06, 0.06, 0.08), false)
	for k in 4:   # seteiras e porta
		var a := 0.3 + k * TAU / 4.0
		caixa(r, Vector3(cos(a) * 2.05, 2.5 + (k % 2) * 2.0, sin(a) * 2.05), Vector3(0.18, 0.9, 0.5), escuro, -a)
	caixa(r, Vector3(0, 1.0, 2.15), Vector3(1.0, 2.0, 0.12), mat(MADEIRA_ESCURA))
	var bal := balista()
	bal.position = Vector3(0, alt + 0.42, 0)
	r.add_child(bal)
	for s: float in [-1.0, 1.0]:
		var b := braseiro()
		b.position = Vector3(s * 1.3, alt + 0.42, -1.0)
		r.add_child(b)
	var esc := MeshInstance3D.new()   # estandarte azul
	var em := BoxMesh.new()
	em.size = Vector3(0.9, 1.3, 0.04)
	em.material = mat(Color(0.13, 0.22, 0.52), false, 1.0)
	esc.mesh = em
	esc.position = Vector3(0, alt - 1.2, 2.25)
	r.add_child(esc)
	return r

## Armazém: galpão de madeira sobre base de pedra, telhado azul, frente aberta. Na frente, três pilhas
## (toras, pedras, sacos de comida) que crescem com o estoque (main.gd mostra/esconde os itens: nós "Pilha_*").
static func armazem(nivel: int) -> Node3D:
	var r := Node3D.new()
	r.name = "Armazem"
	var w := 7.0 + nivel
	var d := 5.0
	var h := 3.2
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	caixa(r, Vector3(0, 0.25, 0), Vector3(w + 0.4, 0.5, d + 0.4), mat_pedra())                 # base de pedra
	caixa(r, Vector3(0, h * 0.5 + 0.5, -d * 0.5), Vector3(w, h, 0.2), m)                       # fundo e laterais
	for s: float in [-1.0, 1.0]:
		caixa(r, Vector3(s * w * 0.5, h * 0.5 + 0.5, 0), Vector3(0.2, h, d), m)
	for x in int(w / 2.0) + 1:   # pilares da frente
		var px := -w * 0.5 + x * w / int(w / 2.0)
		tora(r, Vector3(px, 0.5, d * 0.5), Vector3(px, h + 0.5, d * 0.5), 0.13, me)
	caixa(r, Vector3(0, h + 0.55, d * 0.5), Vector3(w + 0.3, 0.25, 0.25), me)
	for s: float in [-1.0, 1.0]:   # telhado de duas águas, azul ardósia
		var tel := caixa(r, Vector3(0, h + 1.35, s * d * 0.27), Vector3(w + 0.8, 0.15, d * 0.62), mat(Color(0.24, 0.32, 0.5)))
		tel.rotation.x = -s * 0.55
	for s: float in [-1.0, 1.0]:   # empena
		var em := caixa(r, Vector3(s * w * 0.5, h + 1.2, 0), Vector3(0.18, 1.3, d * 0.75), m)
		em.scale = Vector3.ONE
	for k in 3:   # prateleiras com caixotes e barris lá dentro
		caixa(r, Vector3(-w * 0.3 + k * w * 0.3, 1.6, -d * 0.35), Vector3(w * 0.25, 0.08, 0.8), me)
		var cx := caixote(0.55)
		cx.position = Vector3(-w * 0.3 + k * w * 0.3, 1.64, -d * 0.35)
		r.add_child(cx)
	var placa := Label3D.new()
	placa.text = "ARMAZÉM"
	placa.font_size = 64
	placa.pixel_size = 0.008
	placa.modulate = Color(0.2, 0.1, 0.04)
	placa.outline_size = 0
	placa.position = Vector3(0, h + 0.55, d * 0.5 + 0.14)
	r.add_child(placa)
	# pilhas do estoque, na frente (até 6 itens cada)
	var casca := mat(Color(0.45, 0.31, 0.18))
	var pedra := mat(Color(0.55, 0.55, 0.57), true, 0.95)
	var saco := mat(Color(0.75, 0.65, 0.45), true, 1.0)
	var pilhas := {"Pilha_madeira": Vector3(-w * 0.3, 0, d * 0.5 + 1.4), "Pilha_pedra": Vector3(0, 0, d * 0.5 + 1.4), "Pilha_comida": Vector3(w * 0.3, 0, d * 0.5 + 1.4)}
	for nome: String in pilhas:
		var p := Node3D.new()
		p.name = nome
		p.position = pilhas[nome]
		r.add_child(p)
		for i in 6:
			var it := Node3D.new()
			it.name = "Item%d" % i
			p.add_child(it)
			var fila := i / 3
			var col := i % 3
			if nome == "Pilha_madeira":
				var y := 0.18 + fila * 0.32
				tora(it, Vector3(-0.35 + col * 0.35, y, -0.6), Vector3(-0.35 + col * 0.35, y, 0.6), 0.16, casca)
			elif nome == "Pilha_pedra":
				caixa(it, Vector3(-0.35 + col * 0.35, 0.18 + fila * 0.34, 0), Vector3(0.36, 0.34, 0.4), pedra, i * 0.7)
			else:
				var sm := SphereMesh.new()
				sm.radius = 0.24
				sm.height = 0.55
				sm.material = saco
				var mi := MeshInstance3D.new()
				mi.mesh = sm
				mi.position = Vector3(-0.35 + col * 0.35, 0.27 + fila * 0.42, 0)
				it.add_child(mi)
	return r

# ---------- aldeia que funciona: estoques, oficinas, horta, curral e ferramentas ----------
static func _placa(r: Node3D, texto: String, pos: Vector3) -> void:
	var p := Label3D.new()
	p.text = texto
	p.font_size = 64
	p.pixel_size = 0.008
	p.modulate = Color(0.2, 0.1, 0.04)
	p.outline_size = 0
	p.position = pos
	r.add_child(p)
	var t := p.duplicate() as Label3D   # dá para ler de longe (rótulo flutuante)
	t.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	t.modulate = Color(1.0, 0.92, 0.7)
	t.outline_size = 10
	t.font_size = 44
	t.pixel_size = 0.012
	t.position = pos + Vector3(0, 2.2, 0)
	t.visibility_range_end = 45.0
	r.add_child(t)

## Item de estoque (uma unidade da pilha) conforme o tipo.
static func _item_estoque(tipo: String, i: int) -> Node3D:
	var it := Node3D.new()
	var fila := i / 3
	var col := i % 3
	var x := -0.42 + col * 0.42
	match tipo:
		"madeira":
			var y := 0.18 + fila * 0.32
			tora(it, Vector3(x, y, -0.7), Vector3(x, y, 0.7), 0.16, mat(Color(0.45, 0.31, 0.18)))
		"pedra":
			caixa(it, Vector3(x, 0.18 + fila * 0.34, 0), Vector3(0.38, 0.34, 0.42), mat(Color(0.55, 0.55, 0.57), true, 0.95), i * 0.7)
		"carne":   # pernis e peças penduradas num cavalete
			var sm := SphereMesh.new()
			sm.radius = 0.16
			sm.height = 0.42
			sm.material = mat(Color(0.6, 0.18, 0.15), false, 0.6)
			var mi := MeshInstance3D.new()
			mi.mesh = sm
			mi.position = Vector3(x, 1.3 - fila * 0.5, 0)
			it.add_child(mi)
		_:   # comida: cestos com frutas e legumes
			var cm := CylinderMesh.new()
			cm.top_radius = 0.2
			cm.bottom_radius = 0.15
			cm.height = 0.22
			cm.material = mat(Color(0.6, 0.45, 0.25))
			var c := MeshInstance3D.new()
			c.mesh = cm
			c.position = Vector3(x, 0.11 + fila * 0.26, 0)
			it.add_child(c)
			var fr := SphereMesh.new()
			fr.radius = 0.17
			fr.height = 0.16
			fr.material = mat([Color(0.95, 0.5, 0.1), Color(0.8, 0.15, 0.12), Color(0.35, 0.6, 0.2)][i % 3], false, 0.5)
			var f := MeshInstance3D.new()
			f.mesh = fr
			f.position = c.position + Vector3(0, 0.12, 0)
			it.add_child(f)
	return it

## Galpão de estoque com nome (Pedreira, Madeireira, Mantimentos, Açougue). Pilha de 9 itens na frente ("Pilha").
static func galpao(nome: String, tipo: String) -> Node3D:
	var r := armazem(1)
	for n in ["Pilha_madeira", "Pilha_pedra", "Pilha_comida"]:
		var p := r.get_node_or_null(n)
		if p != null:
			p.free()
	for c in r.get_children():   # troca o nome da placa
		if c is Label3D:
			c.free()
	_placa(r, nome.to_upper(), Vector3(0, 3.75, 2.64))
	var pilha := Node3D.new()
	pilha.name = "Pilha"
	pilha.position = Vector3(0, 0, 3.9)
	r.add_child(pilha)
	if tipo == "carne":   # cavalete para pendurar as carnes
		var me := mat(MADEIRA_ESCURA)
		for s: float in [-0.75, 0.75]:
			tora(pilha, Vector3(s, 0, 0), Vector3(s, 1.65, 0), 0.06, me)
		tora(pilha, Vector3(-0.8, 1.6, 0), Vector3(0.8, 1.6, 0), 0.05, me)
	for i in 9:
		var it := _item_estoque(tipo, i)
		it.name = "Item%d" % i
		it.visible = false
		pilha.add_child(it)
	return r

## Cozinha: casa de pedra com chaminé, fogão a lenha e caldeirão na frente, balcão de servir e mesa comprida com bancos.
static func cozinha() -> Node3D:
	var r := Node3D.new()
	var pedra := mat_pedra()
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	caixa(r, Vector3(0, 1.6, -1.5), Vector3(7.0, 3.2, 4.0), pedra)
	for s: float in [-1.0, 1.0]:
		var tel := caixa(r, Vector3(0, 3.75, -1.5 + s * 1.05), Vector3(7.6, 0.15, 2.5), mat(Color(0.24, 0.32, 0.5)))
		tel.rotation.x = -s * 0.55
	caixa(r, Vector3(2.4, 4.4, -2.2), Vector3(0.8, 2.0, 0.8), pedra)   # chaminé
	caixa(r, Vector3(0, 1.1, 0.52), Vector3(1.4, 2.2, 0.06), me)       # porta
	_placa(r, "COZINHA", Vector3(0, 2.6, 0.56))
	# fogão e caldeirão na frente
	caixa(r, Vector3(-2.4, 0.45, 1.6), Vector3(1.4, 0.9, 1.0), pedra)
	var cal := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.7
	sm.material = mat(Color(0.1, 0.1, 0.11), false, 0.4)
	cal.mesh = sm
	cal.position = Vector3(-2.4, 1.15, 1.6)
	r.add_child(cal)
	caixa(r, Vector3(-2.4, 1.38, 1.6), Vector3(0.6, 0.02, 0.6), mat(Color(0.75, 0.55, 0.25), false, 0.3))   # sopa
	# balcão de servir (fila de frente para ele) com pratos e panelas
	caixa(r, Vector3(1.2, 0.5, 2.2), Vector3(3.0, 1.0, 0.7), m)
	for i in 4:
		cilindro_mesh(r, Vector3(0.1 + i * 0.7, 1.02, 2.2), 0.16, 0.03, Color(0.9, 0.88, 0.82))
	# mesa comprida com bancos (onde comem)
	var mz := 6.0
	caixa(r, Vector3(0, 0.78, mz), Vector3(6.0, 0.1, 1.1), m)
	for x: float in [-2.6, 2.6]:
		for z: float in [-0.4, 0.4]:
			caixa(r, Vector3(x, 0.37, mz + z), Vector3(0.1, 0.74, 0.1), me)
	for z: float in [-0.95, 0.95]:
		caixa(r, Vector3(0, 0.45, mz + z), Vector3(6.0, 0.08, 0.35), m)
	solido(r, Vector3(0, 1.6, -1.5), Vector3(7.0, 3.2, 4.0))
	solido(r, Vector3(1.2, 0.5, 2.2), Vector3(3.0, 1.0, 0.7))
	return r

static func cilindro_mesh(pai: Node3D, pos: Vector3, raio: float, alt: float, cor: Color) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = raio
	cm.bottom_radius = raio
	cm.height = alt
	cm.material = mat(cor, false, 0.6)
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.position = pos
	pai.add_child(mi)
	return mi

## Ateliê da artesã: casa de madeira com tear, varal de tecidos coloridos e manequim com roupa.
static func artesa() -> Node3D:
	var r := Node3D.new()
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	caixa(r, Vector3(0, 0.2, -1.5), Vector3(6.4, 0.4, 4.4), mat_pedra())
	caixa(r, Vector3(0, 1.8, -1.5), Vector3(6.0, 2.9, 4.0), mat(Color(0.88, 0.82, 0.68)))
	for s: float in [-1.0, 1.0]:
		var tel := caixa(r, Vector3(0, 3.6, -1.5 + s * 1.05), Vector3(6.6, 0.15, 2.5), mat(Color(0.24, 0.32, 0.5)))
		tel.rotation.x = -s * 0.55
	caixa(r, Vector3(0, 1.1, 0.52), Vector3(1.3, 2.0, 0.06), me)
	_placa(r, "ARTESÃ", Vector3(0, 2.5, 0.56))
	# tear
	var tx := -2.0
	for s: float in [-0.7, 0.7]:
		tora(r, Vector3(tx + s, 0, 2.0), Vector3(tx + s, 1.6, 2.0), 0.05, me)
	tora(r, Vector3(tx - 0.75, 1.55, 2.0), Vector3(tx + 0.75, 1.55, 2.0), 0.04, me)
	tora(r, Vector3(tx - 0.75, 0.6, 2.0), Vector3(tx + 0.75, 0.6, 2.0), 0.06, me)
	caixa(r, Vector3(tx, 1.08, 2.0), Vector3(1.3, 0.9, 0.02), mat(Color(0.6, 0.15, 0.2), false, 1.0))
	# varal com tecidos
	var cores := [Color(0.15, 0.3, 0.6), Color(0.2, 0.45, 0.2), Color(0.8, 0.6, 0.2), Color(0.55, 0.2, 0.5), Color(0.85, 0.85, 0.8)]
	tora(r, Vector3(0.8, 0, 2.6), Vector3(0.8, 1.9, 2.6), 0.05, me)
	tora(r, Vector3(3.2, 0, 2.6), Vector3(3.2, 1.9, 2.6), 0.05, me)
	tora(r, Vector3(0.8, 1.85, 2.6), Vector3(3.2, 1.85, 2.6), 0.01, mat(CORDA, false))
	for i in 5:
		caixa(r, Vector3(1.05 + i * 0.48, 1.45, 2.6), Vector3(0.4, 0.8, 0.02), mat(cores[i], false, 1.0))
	# manequim com capa
	tora(r, Vector3(3.2, 0, 0.9), Vector3(3.2, 1.2, 0.9), 0.04, me)
	caixa(r, Vector3(3.2, 1.35, 0.9), Vector3(0.5, 0.6, 0.3), mat(Color(0.3, 0.15, 0.4), false, 1.0))
	solido(r, Vector3(0, 1.6, -1.5), Vector3(6.4, 3.2, 4.4))
	return r

## Canteiro da horta (2 x 6 m) com uma cultura. tipo: alface, tomate, abobora, melancia, cenoura.
static func canteiro(tipo: String) -> Node3D:
	var r := Node3D.new()
	var terra := mat(Color(0.32, 0.22, 0.14), true, 1.0)
	caixa(r, Vector3(0, 0.06, 0), Vector3(2.0, 0.12, 6.0), terra)
	for s: float in [-1.0, 1.0]:   # bordas de madeira
		caixa(r, Vector3(s * 1.02, 0.1, 0), Vector3(0.06, 0.2, 6.0), mat(MADEIRA_ESCURA))
	var verde := mat(Color(0.3, 0.6, 0.2), false, 0.7)
	for i in 10:
		for j in 2:
			var p := Vector3(-0.45 + j * 0.9, 0.12, -2.6 + i * 0.58)
			match tipo:
				"alface":
					var s := SphereMesh.new()
					s.radius = 0.2
					s.height = 0.22
					s.material = mat(Color(0.45, 0.75, 0.3), false, 0.7)
					var mi := MeshInstance3D.new()
					mi.mesh = s
					mi.position = p + Vector3(0, 0.08, 0)
					r.add_child(mi)
				"tomate":
					tora(r, p, p + Vector3(0, 1.0, 0), 0.02, mat(MADEIRA))
					var s2 := SphereMesh.new()
					s2.radius = 0.16
					s2.height = 0.5
					s2.material = verde
					var f := MeshInstance3D.new()
					f.mesh = s2
					f.position = p + Vector3(0, 0.55, 0)
					r.add_child(f)
					for k in 3:
						var t := SphereMesh.new()
						t.radius = 0.05
						t.height = 0.1
						t.material = mat(Color(0.85, 0.12, 0.08), false, 0.4)
						var tm := MeshInstance3D.new()
						tm.mesh = t
						tm.position = p + Vector3(cos(k * 2.1) * 0.13, 0.4 + k * 0.15, sin(k * 2.1) * 0.13)
						r.add_child(tm)
				"abobora", "melancia":
					if (i + j) % 2 == 0:
						var s3 := SphereMesh.new()
						s3.radius = 0.24 if tipo == "abobora" else 0.22
						s3.height = 0.34 if tipo == "abobora" else 0.4
						s3.material = mat(Color(0.95, 0.5, 0.1) if tipo == "abobora" else Color(0.15, 0.4, 0.12), false, 0.6)
						var a := MeshInstance3D.new()
						a.mesh = s3
						a.position = p + Vector3(0, 0.15, 0)
						a.scale = Vector3(1, 1, 1.0 if tipo == "abobora" else 1.4)
						r.add_child(a)
					var fo := SphereMesh.new()
					fo.radius = 0.18
					fo.height = 0.1
					fo.material = verde
					var fm := MeshInstance3D.new()
					fm.mesh = fo
					fm.position = p + Vector3(0.2, 0.06, 0.1)
					r.add_child(fm)
				_:   # cenoura: folhinhas
					for k in 3:
						tora(r, p + Vector3(k * 0.04 - 0.04, 0, 0), p + Vector3(k * 0.06 - 0.06, 0.3, 0.02), 0.012, verde)
	return r

## Árvore frutífera pequena: copa com frutas coloridas (laranja ou maçã).
static func frutifera(cor_fruta: Color) -> Node3D:
	var r := Node3D.new()
	tora(r, Vector3.ZERO, Vector3(0, 1.6, 0), 0.12, mat(Color(0.4, 0.27, 0.16)))
	var copa := SphereMesh.new()
	copa.radius = 1.2
	copa.height = 2.0
	copa.material = mat(Color(0.22, 0.48, 0.18), true, 0.9)
	var c := MeshInstance3D.new()
	c.mesh = copa
	c.position.y = 2.4
	r.add_child(c)
	for k in 14:
		var a := TAU * k / 14.0
		var f := SphereMesh.new()
		f.radius = 0.09
		f.height = 0.18
		f.material = mat(cor_fruta, false, 0.4)
		var mi := MeshInstance3D.new()
		mi.mesh = f
		mi.position = Vector3(cos(a) * 1.1, 2.0 + 0.6 * sin(k * 1.7), sin(a) * 1.1)
		r.add_child(mi)
	solido(r, Vector3(0, 0.8, 0), Vector3(0.4, 1.6, 0.4))
	return r

## Parreira: armação de madeira com cachos de uva.
static func parreira() -> Node3D:
	var r := Node3D.new()
	var me := mat(MADEIRA_ESCURA)
	for x: float in [-2.0, 0.0, 2.0]:
		tora(r, Vector3(x, 0, 0), Vector3(x, 1.8, 0), 0.05, me)
	tora(r, Vector3(-2.0, 1.75, 0), Vector3(2.0, 1.75, 0), 0.04, me)
	var folha := mat(Color(0.25, 0.5, 0.18), false, 0.8)
	for i in 9:
		var p := Vector3(-1.8 + i * 0.45, 1.6, 0)
		caixa(r, p, Vector3(0.5, 0.35, 0.35), folha, i * 0.4)
		if i % 2 == 0:
			for k in 5:
				var u := SphereMesh.new()
				u.radius = 0.05
				u.height = 0.1
				u.material = mat(Color(0.35, 0.1, 0.4), false, 0.3)
				var mi := MeshInstance3D.new()
				mi.mesh = u
				mi.position = p + Vector3((k % 2) * 0.06 - 0.03, -0.25 - k * 0.05, 0.12)
				r.add_child(mi)
	return r

## Cerca retangular de madeira (w x d) com abertura de porteira no lado +Z. Tem colisão.
static func cerca(w: float, d: float) -> Node3D:
	var r := Node3D.new()
	var m := mat(MADEIRA)
	var lados := [[Vector3(-w * 0.5, 0, -d * 0.5), Vector3(w * 0.5, 0, -d * 0.5)], [Vector3(w * 0.5, 0, -d * 0.5), Vector3(w * 0.5, 0, d * 0.5)],
		[Vector3(-w * 0.5, 0, -d * 0.5), Vector3(-w * 0.5, 0, d * 0.5)], [Vector3(-w * 0.5, 0, d * 0.5), Vector3(-1.2, 0, d * 0.5)], [Vector3(1.2, 0, d * 0.5), Vector3(w * 0.5, 0, d * 0.5)]]
	for l: Array in lados:
		var a: Vector3 = l[0]
		var b: Vector3 = l[1]
		var n := maxi(1, int(a.distance_to(b) / 1.8))
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			tora(r, p, p + Vector3(0, 1.2, 0), 0.07, m)
		for y: float in [0.5, 1.0]:
			tora(r, a + Vector3(0, y, 0), b + Vector3(0, y, 0), 0.04, m)
		solido(r, (a + b) * 0.5 + Vector3(0, 0.6, 0), Vector3(absf(b.x - a.x) + 0.15, 1.2, absf(b.z - a.z) + 0.15))
	return r

## Galinheiro: casinha de madeira sobre pés, com rampa e ninhos.
static func galinheiro() -> Node3D:
	var r := Node3D.new()
	var m := mat(MADEIRA)
	var me := mat(MADEIRA_ESCURA)
	for x: float in [-0.9, 0.9]:
		for z: float in [-0.6, 0.6]:
			tora(r, Vector3(x, 0, z), Vector3(x, 0.6, z), 0.05, me)
	caixa(r, Vector3(0, 1.1, 0), Vector3(2.0, 1.0, 1.4), m)
	var tel := caixa(r, Vector3(0, 1.75, 0), Vector3(2.3, 0.1, 1.7), mat(Color(0.6, 0.35, 0.2)))
	tel.rotation.x = 0.2
	var rampa := caixa(r, Vector3(0, 0.3, 1.2), Vector3(0.4, 0.04, 1.2), m)
	rampa.rotation.x = 0.55
	caixa(r, Vector3(0, 1.0, 0.71), Vector3(0.4, 0.4, 0.02), mat(Color(0.05, 0.04, 0.03), false))
	solido(r, Vector3(0, 0.9, 0), Vector3(2.0, 1.8, 1.4))
	return r

# ---------- ferramentas dos trabalhadores (cabo em +Y, ponta em cima; presas na mão por trabalhador.gd) ----------
static func ferramenta(nome: String) -> Node3D:
	var r := Node3D.new()
	var cabo := mat(Color(0.5, 0.35, 0.2))
	var ferro := mat(Color(0.45, 0.46, 0.48), false, 0.35)
	match nome:
		"martelo":
			tora(r, Vector3(0, -0.15, 0), Vector3(0, 0.25, 0), 0.02, cabo)
			caixa(r, Vector3(0, 0.27, 0), Vector3(0.06, 0.07, 0.16), ferro)
		"enxada":
			tora(r, Vector3(0, -0.5, 0), Vector3(0, 0.8, 0), 0.022, cabo)
			caixa(r, Vector3(0, 0.78, 0.09), Vector3(0.2, 0.03, 0.18), ferro)
		"colher":
			tora(r, Vector3(0, -0.25, 0), Vector3(0, 0.35, 0), 0.015, cabo)
			var s := SphereMesh.new()
			s.radius = 0.07
			s.height = 0.05
			s.material = cabo
			var mi := MeshInstance3D.new()
			mi.mesh = s
			mi.position.y = 0.4
			r.add_child(mi)
		"prato":
			var p := cilindro_mesh(r, Vector3(0, 0.1, 0), 0.15, 0.03, Color(0.9, 0.88, 0.82))
			p.rotation.x = PI * 0.5
		"cesto":
			cilindro_mesh(r, Vector3(0, 0.0, 0.0), 0.2, 0.25, Color(0.6, 0.45, 0.25))
			var fr := SphereMesh.new()
			fr.radius = 0.17
			fr.height = 0.14
			fr.material = mat(Color(0.95, 0.5, 0.1), false, 0.5)
			var f := MeshInstance3D.new()
			f.mesh = fr
			f.position.y = 0.13
			r.add_child(f)
		"varinha":
			tora(r, Vector3(0, -0.2, 0), Vector3(0, 0.35, 0), 0.012, mat(Color(0.3, 0.2, 0.35)))
			var g := SphereMesh.new()
			g.radius = 0.04
			g.height = 0.08
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.5, 0.8, 1.0)
			gm.emission_enabled = true
			gm.emission = Color(0.3, 0.6, 1.0)
			g.material = gm
			var gi := MeshInstance3D.new()
			gi.mesh = g
			gi.position.y = 0.38
			r.add_child(gi)
	return r

## Carrinho de mão (frente em +Z): caçamba de tábuas inclinadas com cintas de ferro, roda com aro, cubo e raios,
## dois braços compridos com pegadores e dois pés com travas. Nó "Carga" com pedras ou toras amarradas.
static func carrinho() -> Node3D:
	var r := Node3D.new()
	var tabua := mat(Color(0.62, 0.46, 0.3))
	var braco := mat(Color(0.42, 0.29, 0.17))
	var ferro := mat(Color(0.18, 0.18, 0.2), false, 0.45)
	# braços: da roda até os pegadores, por baixo da caçamba
	for s2: float in [-1.0, 1.0]:
		tora(r, Vector3(s2 * 0.2, 0.3, 0.72), Vector3(s2 * 0.3, 0.62, -1.0), 0.03, braco)
		tora(r, Vector3(s2 * 0.3, 0.62, -1.0), Vector3(s2 * 0.31, 0.64, -1.18), 0.035, mat(Color(0.25, 0.17, 0.1)))   # pegador
		tora(r, Vector3(s2 * 0.26, 0.48, -0.35), Vector3(s2 * 0.28, 0.0, -0.42), 0.025, braco)                       # pé
		tora(r, Vector3(s2 * 0.27, 0.1, -0.41), Vector3(s2 * 0.22, 0.38, -0.05), 0.012, ferro)                        # trava do pé
	tora(r, Vector3(-0.28, 0.06, -0.42), Vector3(0.28, 0.06, -0.42), 0.015, ferro)
	# caçamba: fundo + laterais inclinadas + frente inclinada + traseira
	var fundo_y := 0.5
	for k in 4:
		caixa(r, Vector3(-0.21 + k * 0.14, fundo_y, 0.05), Vector3(0.13, 0.03, 0.8), tabua)
	for s2: float in [-1.0, 1.0]:
		for k in 3:
			var lado := caixa(r, Vector3(s2 * (0.32 + k * 0.025), fundo_y + 0.07 + k * 0.08, 0.05), Vector3(0.025, 0.075, 0.82 - k * 0.04), tabua)
			lado.rotation.z = s2 * 0.35
		var cinta := caixa(r, Vector3(s2 * 0.4, fundo_y + 0.2, 0.05), Vector3(0.012, 0.025, 0.84), ferro)
		cinta.rotation.z = s2 * 0.35
	for k in 3:
		var fr := caixa(r, Vector3(0, fundo_y + 0.08 + k * 0.08, 0.47 + k * 0.05), Vector3(0.62 + k * 0.05, 0.075, 0.025), tabua)
		fr.rotation.x = -0.6
	caixa(r, Vector3(0, fundo_y + 0.12, -0.36), Vector3(0.62, 0.2, 0.025), tabua)
	# roda: aro de ferro, aro de madeira, cubo e 8 raios, eixo nos braços
	var c := Vector3(0, 0.3, 0.72)
	var aro := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.25
	t.outer_radius = 0.3
	t.rings = 24
	t.ring_segments = 8
	t.material = ferro
	aro.mesh = t
	aro.position = c
	aro.rotation.z = PI * 0.5
	r.add_child(aro)
	var aro2 := aro.duplicate() as MeshInstance3D
	var t2 := TorusMesh.new()
	t2.inner_radius = 0.22
	t2.outer_radius = 0.26
	t2.rings = 24
	t2.ring_segments = 8
	t2.material = braco
	aro2.mesh = t2
	r.add_child(aro2)
	var cubo := tora(r, c + Vector3(-0.05, 0, 0), c + Vector3(0.05, 0, 0), 0.05, braco)
	cubo.name = "Cubo"
	for k in 8:
		var a := TAU * k / 8.0
		tora(r, c, c + Vector3(0, cos(a) * 0.23, sin(a) * 0.23), 0.012, braco)
	tora(r, c + Vector3(-0.22, 0, 0), c + Vector3(0.22, 0, 0), 0.015, ferro)
	for nm: String in ["PegaE", "PegaD"]:   # pontos onde as mãos seguram (maos_alvo.gd)
		var mk := Marker3D.new()
		mk.name = nm
		mk.position = Vector3(0.31 if nm == "PegaE" else -0.31, 0.64, -1.12)
		r.add_child(mk)
	var carga := Node3D.new()
	carga.name = "Carga"
	r.add_child(carga)
	return r

static func encher_carrinho(c: Node3D, tipo: String) -> void:
	var carga := c.get_node("Carga") as Node3D
	for x in carga.get_children():
		x.queue_free()
	if tipo == "":
		return
	for i in 4:
		if tipo == "madeira":
			tora(carga, Vector3(-0.22 + (i % 2) * 0.22, 0.6 + (i / 2) * 0.15, -0.15), Vector3(-0.22 + (i % 2) * 0.22, 0.6 + (i / 2) * 0.15, 0.65), 0.08, mat(Color(0.45, 0.31, 0.18)))
		else:
			caixa(carga, Vector3(-0.15 + (i % 2) * 0.3, 0.58 + (i / 2) * 0.17, 0.1 + (i % 3) * 0.12), Vector3(0.25, 0.2, 0.25), mat(Color(0.55, 0.55, 0.57), true, 0.95), i * 0.6)
	for z: float in [0.05, 0.45]:   # corda amarrando a carga
		caixa(carga, Vector3(0, 0.75, z), Vector3(0.72, 0.02, 0.03), mat(CORDA, false))
