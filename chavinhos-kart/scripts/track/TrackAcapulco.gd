class_name TrackAcapulco
extends TrackBase
## Pista 2: Acapulco Sunset. Deque de madeira à beira-mar; a areia ao redor reduz muito a velocidade.


func _init_theme() -> void:
	track_title = "ACAPULCO SUNSET"
	offroad_factor = 0.45
	ground_color = Color(0.95, 0.82, 0.58)       # areia
	road_color = Color(0.62, 0.42, 0.25)         # tábuas do deque
	wall_colors = [Color(0.95, 0.95, 0.9), Color(0.25, 0.65, 0.8)]  # muretas branca/azul
	wall_height = 1.6
	sky_top = Color(0.35, 0.3, 0.6)
	sky_horizon = Color(1.0, 0.55, 0.35)
	sun_color = Color(1.0, 0.7, 0.45)
	sun_energy = 1.2
	fog_density = 0.0009


func _make_centerline() -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n: int = 240
	for i in n:
		var t: float = TAU * float(i) / float(n)
		pts.append(Vector3(190.0 * cos(t) + 14.0 * cos(3.0 * t), 0.0, 100.0 * sin(t)))
	return pts


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var root := Node3D.new()
	root.name = "Scenery"
	add_child(root)
	# mar a oeste
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400.0, 1200.0)
	sea.mesh = plane
	sea.material_override = ProcMesh.mat(Color(0.12, 0.45, 0.65), 0.15, 0.3)
	sea.position = Vector3(-470.0, 0.05, 0.0)
	root.add_child(sea)
	# sol poente (disco brilhante distante)
	ProcMesh.sphere(root, 28.0, Vector3(-640.0, 38.0, 40.0), Color(1.0, 0.85, 0.5), Vector3.ONE, 0.5, 3.0)
	# palmeiras e guarda-sóis ao longo da pista
	var d: float = 6.0
	while d < path.length:
		var p: Vector3 = outside_point(d, 5.0 + rng.randf_range(0.0, 10.0))
		_palm(root, p, rng.randf_range(7.0, 11.0), rng)
		d += rng.randf_range(18.0, 34.0)
	d = 20.0
	while d < path.length:
		var inner: Vector3 = path.point_at(d) - path.right_at(d) * outside_side(d) * (wall_offset - 2.0)
		if rng.randf() < 0.5:
			_umbrella(root, inner, rng)
		else:
			ProcMesh.box(root, Vector3(2.2, 0.5, 0.8), inner + Vector3(0, 0.3, 0), Color(0.9, 0.5, 0.3), Vector3(0, rng.randf_range(0, 180), 0), 0.9)
		d += rng.randf_range(30.0, 55.0)
	_build_hotel(root)
	_build_pool(root)


func _palm(root: Node3D, pos: Vector3, h: float, rng: RandomNumberGenerator) -> void:
	var tilt: float = rng.randf_range(-8.0, 8.0)
	var palm := Node3D.new()
	palm.position = pos
	palm.rotation_degrees = Vector3(tilt, rng.randf_range(0.0, 360.0), 0.0)
	root.add_child(palm)
	ProcMesh.cyl(palm, 0.45, h, Vector3(0, h / 2.0, 0), Color(0.5, 0.35, 0.2), Vector3.ZERO, 0.3, 0.95)
	for i in 7:
		var ang: float = TAU * float(i) / 7.0
		var leaf := Node3D.new()
		leaf.position = Vector3(0, h, 0)
		leaf.rotation = Vector3(0, ang, 0)
		palm.add_child(leaf)
		ProcMesh.box(leaf, Vector3(0.7, 0.1, 4.2), Vector3(0, -0.4, -2.0), Color(0.2, 0.6, 0.25), Vector3(-22, 0, 0), 0.9)
	ProcMesh.sphere(palm, 0.35, Vector3(0.3, h - 0.5, 0.2), Color(0.35, 0.22, 0.1))


func _umbrella(root: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var cols: Array[Color] = [Color(0.95, 0.3, 0.3), Color(0.95, 0.85, 0.2), Color(0.3, 0.7, 0.95), Color(0.95, 0.5, 0.75)]
	var col: Color = cols[rng.randi() % cols.size()]
	ProcMesh.cyl(root, 0.06, 3.0, pos + Vector3(0, 1.5, 0), Color(0.9, 0.9, 0.9))
	ProcMesh.cyl(root, 1.6, 0.5, pos + Vector3(0, 3.1, 0), col, Vector3.ZERO, 0.05, 0.8)


func _build_hotel(root: Node3D) -> void:
	# prédios e luzes na orla leste
	for i in 5:
		var h: float = 22.0 + 7.0 * float(i % 3)
		var pos := Vector3(330.0, h / 2.0, -160.0 + 80.0 * float(i))
		ProcMesh.box(root, Vector3(36.0, h, 30.0), pos, Color(0.95, 0.9, 0.82), Vector3.ZERO, 0.9)
		for f in int(h / 5.0):
			ProcMesh.box(root, Vector3(0.3, 2.2, 24.0), pos + Vector3(-18.0, -h / 2.0 + 4.0 + 5.0 * float(f), 0), Color(1.0, 0.85, 0.5), Vector3.ZERO, 0.3, 0.0, 1.2)


func _build_pool(root: Node3D) -> void:
	var c := Vector3(0, 0, 0)
	ProcMesh.box(root, Vector3(70.0, 0.4, 36.0), c + Vector3(0, 0.2, 0), Color(0.88, 0.8, 0.7), Vector3.ZERO, 0.9)
	ProcMesh.box(root, Vector3(54.0, 0.45, 22.0), c + Vector3(0, 0.22, 0), Color(0.25, 0.75, 0.9, 0.9), Vector3.ZERO, 0.1, 0.0, 0.4)
	for i in 6:
		ProcMesh.box(root, Vector3(1.2, 0.5, 3.0), c + Vector3(-24.0 + 9.0 * float(i), 0.55, 15.0), Color(0.95, 0.95, 0.95), Vector3.ZERO, 0.9)
