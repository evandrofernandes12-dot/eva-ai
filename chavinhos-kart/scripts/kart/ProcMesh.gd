class_name ProcMesh
extends RefCounted
## Fábrica de primitivas estilizadas (caixas, cilindros, esferas...) com materiais em cache.
## Todo visual do jogo passa por aqui: para trocar por modelos .glb reais, basta substituir
## o conteúdo de KartVisuals.build() / dos _build_visual() dos itens por instâncias de PackedScene.

static var _mat_cache: Dictionary = {}
static var _rbox_cache: Dictionary = {}


static func mat(color: Color, rough: float = 0.7, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var key: String = "%s_%s_%s_%s" % [color.to_html(true), rough, metal, glow]
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	if color.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_cache[key] = m
	return m


static func _add(parent: Node3D, mesh: Mesh, pos: Vector3, rot_deg: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, rough: float = 0.7, metal: float = 0.0, glow: float = 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _add(parent, m, pos, rot_deg, mat(color, rough, metal, glow))


static func cyl(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, top_radius: float = -1.0, rough: float = 0.7, metal: float = 0.0, glow: float = 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top_radius < 0.0 else top_radius
	m.height = height
	m.radial_segments = 20
	m.rings = 1
	return _add(parent, m, pos, rot_deg, mat(color, rough, metal, glow))


static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, scale_v: Vector3 = Vector3.ONE, rough: float = 0.7, glow: float = 0.0) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 16
	m.rings = 8
	var mi: MeshInstance3D = _add(parent, m, pos, Vector3.ZERO, mat(color, rough, 0.0, glow))
	mi.scale = scale_v
	return mi


static func capsule(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	return _add(parent, m, pos, rot_deg, mat(color))


static func torus(parent: Node3D, inner: float, outer: float, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, metal: float = 0.0) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 24
	m.ring_segments = 12
	return _add(parent, m, pos, rot_deg, mat(color, 0.4, metal))


## Caixa com cantos arredondados (mesma assinatura de box + raio opcional).
## radius < 0 = automático (25% da menor dimensão).
static func rbox(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, rough: float = 0.7, metal: float = 0.0, glow: float = 0.0, radius: float = -1.0) -> MeshInstance3D:
	var r: float = radius if radius >= 0.0 else minf(size.x, minf(size.y, size.z)) * 0.25
	return _add(parent, rounded_box_mesh(size, r), pos, rot_deg, mat(color, rough, metal, glow))


## Gera (e guarda em cache) a malha: cubo subdividido com bordas projetadas numa esfera de raio r.
static func rounded_box_mesh(size: Vector3, radius: float) -> ArrayMesh:
	var key: String = "%s_%s" % [size, radius]
	if _rbox_cache.has(key):
		return _rbox_cache[key] as ArrayMesh
	var h: Vector3 = size * 0.5
	var r: float = clampf(radius, 0.001, minf(h.x, minf(h.y, h.z)) * 0.95)
	var inner: Vector3 = h - Vector3(r, r, r)
	var faces: Array[Array] = [
		[Vector3.RIGHT, Vector3.BACK, Vector3.UP], [Vector3.LEFT, Vector3.BACK, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK], [Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
		[Vector3.BACK, Vector3.RIGHT, Vector3.UP], [Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var hn: float = absf(n.dot(h))
		var su: PackedFloat32Array = _rbox_samples(absf(u.dot(h)), r)
		var sv: PackedFloat32Array = _rbox_samples(absf(v.dot(h)), r)
		for i in su.size() - 1:
			for j in sv.size() - 1:
				var q: Array[Vector3] = [
					n * hn + u * su[i] + v * sv[j], n * hn + u * su[i + 1] + v * sv[j],
					n * hn + u * su[i + 1] + v * sv[j + 1], n * hn + u * su[i] + v * sv[j + 1],
				]
				_rbox_tri(st, q[0], q[1], q[2], inner, r, n)
				_rbox_tri(st, q[0], q[2], q[3], inner, r, n)
	var mesh: ArrayMesh = st.commit()
	_rbox_cache[key] = mesh
	return mesh


static func _rbox_samples(half: float, r: float) -> PackedFloat32Array:
	var inner: float = half - r
	var out := PackedFloat32Array()
	var k: int = 2
	for i in k + 1:
		out.append(-inner - r * cos(float(i) / float(k) * PI * 0.5))
	for i in range(k, -1, -1):
		out.append(inner + r * cos(float(i) / float(k) * PI * 0.5))
	return out


static func _rbox_point(p: Vector3, inner: Vector3, r: float) -> Array[Vector3]:
	var c: Vector3 = p.clamp(-inner, inner)
	var d: Vector3 = p - c
	var nrm: Vector3 = d.normalized() if d.length() > 0.00001 else Vector3.UP
	return [c + nrm * r, nrm]


static func _rbox_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inner: Vector3, r: float, face_n: Vector3) -> void:
	var pa: Array[Vector3] = _rbox_point(a, inner, r)
	var pb: Array[Vector3] = _rbox_point(b, inner, r)
	var pc: Array[Vector3] = _rbox_point(c, inner, r)
	var cr: Vector3 = (pb[0] - pa[0]).cross(pc[0] - pa[0])
	if cr.length_squared() < 0.0000001:
		return # triângulo degenerado
	# Godot: face da frente em sentido horário vista de fora (normal da mão direita aponta para dentro)
	if cr.dot(face_n) > 0.0:
		var tmp: Array[Vector3] = pb
		pb = pc
		pc = tmp
	for pt in [pa, pb, pc]:
		st.set_normal(pt[1] as Vector3)
		st.add_vertex(pt[0] as Vector3)
