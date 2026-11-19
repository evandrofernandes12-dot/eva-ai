class_name TrackBase
extends Node3D
## Base de uma pista procedural. A subclasse define a linha central (_make_centerline) e o
## cenário (_build_scenery); aqui são gerados chão, asfalto, zebras, paredes com colisão,
## linha de largada, caixas de item, grid de largada e ambiente/iluminação.
## Camadas de física: 1 = mundo (chão), 2 = paredes.

@export var road_half_width: float = 9.0
@export var wall_offset: float = 15.0
@export var track_title: String = "Pista"

var path: TrackPath
var start_transforms: Array[Transform3D] = []
var item_box_dists: Array[float] = [0.08, 0.28, 0.5, 0.72, 0.9]

# Cores do tema (a subclasse pode sobrescrever em _init_theme)
var ground_color: Color = Color(0.55, 0.4, 0.26)
var road_color: Color = Color(0.3, 0.3, 0.34)
var wall_colors: Array[Color] = [Color(0.88, 0.72, 0.5), Color(0.78, 0.5, 0.35)]
var sky_top: Color = Color(0.25, 0.45, 0.8)
var sky_horizon: Color = Color(0.95, 0.7, 0.45)
var sun_color: Color = Color(1.0, 0.88, 0.7)


func _ready() -> void:
	_init_theme()
	path = TrackPath.new(_make_centerline(), road_half_width)
	_build_environment()
	_build_ground()
	_build_road()
	_build_walls()
	_build_start_line()
	_build_item_boxes()
	_compute_grid()
	_build_scenery()


# ---------- a sobrescrever

func _init_theme() -> void:
	pass


func _make_centerline() -> PackedVector3Array:
	return PackedVector3Array()


func _build_scenery() -> void:
	pass


# ---------- ambiente

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = sky_horizon
	sky_mat.ground_horizon_color = sky_horizon
	sky_mat.ground_bottom_color = ground_color.darkened(0.4)
	sky_mat.sun_angle_max = 25.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = sky_horizon
	env.fog_density = 0.0012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	sun.light_color = sun_color
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110.0
	add_child(sun)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1200.0, 2.0, 1200.0)
	shape.shape = box
	shape.position = Vector3(0, -1.0, 0)
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1200.0, 1200.0)
	mesh.mesh = plane
	mesh.material_override = ProcMesh.mat(ground_color, 1.0)
	body.add_child(mesh)


# ---------- malhas de faixa (ribbon) ao longo da linha central

func _ribbon_mesh(inner: float, outer: float, y: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in path.count:
		var j: int = (i + 1) % path.count
		var a: Vector3 = path.points[i]
		var b: Vector3 = path.points[j]
		var ra: Vector3 = path.tangents[i].cross(Vector3.UP)
		var rb: Vector3 = path.tangents[j].cross(Vector3.UP)
		var up := Vector3(0, y, 0)
		var a0: Vector3 = a + ra * inner + up
		var a1: Vector3 = a + ra * outer + up
		var b0: Vector3 = b + rb * inner + up
		var b1: Vector3 = b + rb * outer + up
		for v: Vector3 in [a0, a1, b1, a0, b1, b0]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


func _flat_mat(color: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m: StandardMaterial3D = ProcMesh.mat(color, rough).duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _build_road() -> void:
	var road := MeshInstance3D.new()
	road.name = "Road"
	road.mesh = _ribbon_mesh(-road_half_width, road_half_width, 0.03)
	road.material_override = _flat_mat(road_color)
	add_child(road)
	# zebras vermelhas/brancas nas bordas (segmentos alternados)
	var red := SurfaceTool.new()
	var white := SurfaceTool.new()
	red.begin(Mesh.PRIMITIVE_TRIANGLES)
	white.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in path.count:
		var st: SurfaceTool = red if (i / 2) % 2 == 0 else white
		var j: int = (i + 1) % path.count
		for side: float in [-1.0, 1.0]:
			var a: Vector3 = path.points[i]
			var b: Vector3 = path.points[j]
			var ra: Vector3 = path.tangents[i].cross(Vector3.UP) * side
			var rb: Vector3 = path.tangents[j].cross(Vector3.UP) * side
			var up := Vector3(0, 0.05, 0)
			var a0: Vector3 = a + ra * road_half_width + up
			var a1: Vector3 = a + ra * (road_half_width + 1.0) + up
			var b0: Vector3 = b + rb * road_half_width + up
			var b1: Vector3 = b + rb * (road_half_width + 1.0) + up
			for v: Vector3 in [a0, a1, b1, a0, b1, b0]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	for pair: Array in [[red, Color(0.85, 0.15, 0.15)], [white, Color(0.95, 0.95, 0.95)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = (pair[0] as SurfaceTool).commit()
		mi.material_override = _flat_mat(pair[1] as Color, 0.8)
		add_child(mi)
	# linha central tracejada
	var dash := SurfaceTool.new()
	dash.begin(Mesh.PRIMITIVE_TRIANGLES)
	var d: float = 0.0
	while d < path.length:
		var p0: Vector3 = path.point_at(d)
		var p1: Vector3 = path.point_at(d + 4.0)
		var r0: Vector3 = path.right_at(d) * 0.22
		var r1: Vector3 = path.right_at(d + 4.0) * 0.22
		var up := Vector3(0, 0.06, 0)
		for v: Vector3 in [p0 - r0 + up, p0 + r0 + up, p1 + r1 + up, p0 - r0 + up, p1 + r1 + up, p1 - r1 + up]:
			dash.set_normal(Vector3.UP)
			dash.add_vertex(v)
		d += 11.0
	var dm := MeshInstance3D.new()
	dm.mesh = dash.commit()
	dm.material_override = _flat_mat(Color(0.95, 0.9, 0.6), 0.8)
	add_child(dm)


# ---------- paredes (visual + colisão)

func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "Walls"
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	var sts: Array[SurfaceTool] = []
	for c in wall_colors:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts.append(st)
	var height: float = 2.4
	for i in path.count:
		var j: int = (i + 1) % path.count
		var st: SurfaceTool = sts[(i / 5) % sts.size()]
		for side: float in [-1.0, 1.0]:
			var a: Vector3 = path.points[i] + path.tangents[i].cross(Vector3.UP) * side * wall_offset
			var b: Vector3 = path.points[j] + path.tangents[j].cross(Vector3.UP) * side * wall_offset
			var n: Vector3 = (path.points[i] - a).normalized() # aponta para a pista
			n.y = 0.0
			var a_top: Vector3 = a + Vector3(0, height, 0)
			var b_top: Vector3 = b + Vector3(0, height, 0)
			for v: Vector3 in [a, a_top, b_top, a, b_top, b]:
				st.set_normal(n)
				st.add_vertex(v)
	for k in sts.size():
		var mesh: ArrayMesh = sts[k].commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _flat_mat(wall_colors[k], 0.9)
		body.add_child(mi)
		var shape := CollisionShape3D.new()
		var concave: ConcavePolygonShape3D = mesh.create_trimesh_shape() as ConcavePolygonShape3D
		concave.backface_collision = true
		shape.shape = concave
		body.add_child(shape)


# ---------- largada / chegada

func _build_start_line() -> void:
	var origin: Vector3 = path.point_at(0.0)
	var tangent: Vector3 = path.tangent_at(0.0)
	var root := Node3D.new()
	root.name = "StartLine"
	root.transform = Transform3D(Basis.looking_at(tangent, Vector3.UP), origin)
	add_child(root)
	var cols: int = int(road_half_width * 2.0 / 1.5)
	for cx in cols:
		for rz in 2:
			var white: bool = (cx + rz) % 2 == 0
			ProcMesh.box(root, Vector3(1.5, 0.05, 1.5),
				Vector3(-road_half_width + 0.75 + 1.5 * float(cx), 0.07, -0.75 + 1.5 * float(rz)),
				Color(0.95, 0.95, 0.95) if white else Color(0.08, 0.08, 0.08), Vector3.ZERO, 0.8)
	# pórtico
	for sx: float in [-1.0, 1.0]:
		ProcMesh.box(root, Vector3(0.6, 7.0, 0.6), Vector3(sx * (road_half_width + 1.5), 3.5, 0), Color(0.75, 0.2, 0.2))
	ProcMesh.box(root, Vector3((road_half_width + 1.5) * 2.0 + 0.6, 1.4, 0.5), Vector3(0, 7.0, 0), Color(0.15, 0.15, 0.2))
	var banner := Label3D.new()
	banner.text = "LARGADA / CHEGADA"
	banner.font_size = 96
	banner.pixel_size = 0.012
	banner.modulate = Color(1.0, 0.9, 0.3)
	banner.outline_modulate = Color.BLACK
	banner.outline_size = 14
	banner.position = Vector3(0, 7.0, 0.3)
	root.add_child(banner)
	var back := banner.duplicate() as Label3D
	back.position = Vector3(0, 7.0, -0.3)
	back.rotation.y = PI
	root.add_child(back)


func _build_item_boxes() -> void:
	var scene: PackedScene = load("res://scenes/items/ItemBox.tscn") as PackedScene
	if scene == null:
		return
	var holder := Node3D.new()
	holder.name = "ItemBoxes"
	add_child(holder)
	for f in item_box_dists:
		var d: float = f * path.length
		for lane: float in [-5.0, 0.0, 5.0]:
			var box: Node3D = scene.instantiate() as Node3D
			holder.add_child(box)
			box.global_position = path.point_at(d) + path.right_at(d) * lane


func _compute_grid() -> void:
	start_transforms.clear()
	for slot in Global.TOTAL_RACERS:
		var row: int = slot / 2
		var col: int = slot % 2
		var d: float = path.length - 7.0 - 6.5 * float(row) - (3.0 if col == 1 else 0.0)
		var lateral: float = -3.2 if col == 0 else 3.2
		var pos: Vector3 = path.point_at(d) + path.right_at(d) * lateral + Vector3(0, 0.25, 0)
		start_transforms.append(Transform3D(Basis.looking_at(path.tangent_at(d), Vector3.UP), pos))


# ---------- utilitário para o cenário

## Lado (+1 = direita da pista, -1 = esquerda) que fica longe do centro do mapa.
func outside_side(d: float) -> float:
	var p: Vector3 = path.point_at(d)
	var flat_out: Vector3 = Vector3(p.x, 0.0, p.z).normalized()
	return 1.0 if path.right_at(d).dot(flat_out) > 0.0 else -1.0


## Posição do lado de fora da parede (lado oposto ao centro do mapa).
func outside_point(d: float, extra: float) -> Vector3:
	return path.point_at(d) + path.right_at(d) * outside_side(d) * (wall_offset + extra)
