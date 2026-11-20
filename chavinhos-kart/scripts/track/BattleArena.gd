class_name BattleArena
extends TrackBase
## Arena circular para a Batalha de Balões: sem voltas, parede em volta, chafariz e pilares no meio.

const ARENA_RADIUS: float = 72.0


func _init_theme() -> void:
	track_title = "ARENA DA VILA"
	ground_color = Color(0.6, 0.45, 0.3)
	road_color = Color(0.5, 0.4, 0.32)
	wall_colors = [Color(0.9, 0.74, 0.52), Color(0.82, 0.52, 0.36)]
	wall_height = 3.0
	road_half_width = 1000.0


## Só usada pelo minimapa (aro da arena).
func _make_centerline() -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in 120:
		var t: float = TAU * float(i) / 120.0
		pts.append(Vector3((ARENA_RADIUS - 4.0) * cos(t), 0.0, (ARENA_RADIUS - 4.0) * sin(t)))
	return pts


func _build_road() -> void:
	var disk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = ARENA_RADIUS
	cyl.bottom_radius = ARENA_RADIUS
	cyl.height = 0.1
	cyl.radial_segments = 64
	disk.mesh = cyl
	disk.position = Vector3(0, 0.03, 0)
	disk.material_override = ProcMesh.mat(road_color, 0.95)
	add_child(disk)
	for r: float in [20.0, 45.0, 68.0]:
		ProcMesh.torus(self, r - 0.4, r + 0.4, Vector3(0, 0.1, 0), Color(0.95, 0.9, 0.6), Vector3.ZERO)


func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "Walls"
	body.collision_layer = 2
	add_child(body)
	var segs: int = 96
	var sts: Array[SurfaceTool] = []
	for c in wall_colors:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts.append(st)
	for i in segs:
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		var a := Vector3(cos(a0), 0, sin(a0)) * (ARENA_RADIUS + 1.0)
		var b := Vector3(cos(a1), 0, sin(a1)) * (ARENA_RADIUS + 1.0)
		var n: Vector3 = -a.normalized()
		var st: SurfaceTool = sts[(i / 4) % sts.size()]
		for v: Vector3 in [a, a + Vector3(0, wall_height, 0), b + Vector3(0, wall_height, 0), a, b + Vector3(0, wall_height, 0), b]:
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


func _build_start_line() -> void:
	pass


func _build_item_boxes() -> void:
	var scene: PackedScene = load("res://scenes/items/ItemBox.tscn") as PackedScene
	if scene == null:
		return
	var holder := Node3D.new()
	holder.name = "ItemBoxes"
	add_child(holder)
	for ring: float in [24.0, 50.0]:
		var count: int = 5 if ring < 30.0 else 7
		for i in count:
			var a: float = TAU * (float(i) + (0.5 if ring > 30.0 else 0.0)) / float(count)
			var box: Node3D = scene.instantiate() as Node3D
			holder.add_child(box)
			box.global_position = Vector3(cos(a) * ring, 0, sin(a) * ring)


func _compute_grid() -> void:
	start_transforms.clear()
	for slot in Global.TOTAL_RACERS:
		var a: float = TAU * float(slot) / float(Global.TOTAL_RACERS)
		var pos := Vector3(cos(a) * 52.0, 0.25, sin(a) * 52.0)
		start_transforms.append(Transform3D(Basis.looking_at(-pos.normalized(), Vector3.UP), pos))


func _build_scenery() -> void:
	# chafariz central sólido + pilares (obstáculos)
	var body := StaticBody3D.new()
	body.collision_layer = 2
	add_child(body)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 9.0
	cyl.height = 4.0
	cs.shape = cyl
	cs.position = Vector3(0, 2.0, 0)
	body.add_child(cs)
	ProcMesh.cyl(self, 9.0, 0.9, Vector3(0, 0.45, 0), Color(0.62, 0.6, 0.58), Vector3.ZERO, -1.0, 0.9)
	ProcMesh.cyl(self, 8.0, 0.2, Vector3(0, 0.85, 0), Color(0.3, 0.6, 0.85, 0.9), Vector3.ZERO, -1.0, 0.1)
	ProcMesh.cyl(self, 1.1, 4.0, Vector3(0, 2.2, 0), Color(0.7, 0.68, 0.65), Vector3.ZERO, 0.8, 0.9)
	for i in 4:
		var a: float = TAU * (float(i) + 0.5) / 4.0
		var p := Vector3(cos(a) * 36.0, 0.0, sin(a) * 36.0)
		var pb := StaticBody3D.new()
		pb.collision_layer = 2
		pb.position = p
		add_child(pb)
		var pcs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(5.0, 5.0, 5.0)
		pcs.shape = box
		pcs.position = Vector3(0, 2.5, 0)
		pb.add_child(pcs)
		ProcMesh.box(pb, Vector3(5.0, 5.0, 5.0), Vector3(0, 2.5, 0), Color(0.6, 0.42, 0.22), Vector3.ZERO, 0.9)
		ProcMesh.box(pb, Vector3(5.3, 0.5, 5.3), Vector3(0, 5.1, 0), Color(0.85, 0.3, 0.25), Vector3.ZERO, 0.9)
