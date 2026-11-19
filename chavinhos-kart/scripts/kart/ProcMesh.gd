class_name ProcMesh
extends RefCounted
## Fábrica de primitivas estilizadas (caixas, cilindros, esferas...) com materiais em cache.
## Todo visual do jogo passa por aqui: para trocar por modelos .glb reais, basta substituir
## o conteúdo de KartVisuals.build() / dos _build_visual() dos itens por instâncias de PackedScene.

static var _mat_cache: Dictionary = {}


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
	return _add(parent, m, pos, rot_deg, mat(color, 0.4, metal))
