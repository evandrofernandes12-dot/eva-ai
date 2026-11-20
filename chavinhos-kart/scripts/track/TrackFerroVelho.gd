class_name TrackFerroVelho
extends TrackBase
## Pista 4: Ferro-Velho do Seu Barriga. Pilhas de pneus, carros amassados, guindaste e terra solta.


func _init_theme() -> void:
	track_title = "FERRO-VELHO DO SEU BARRIGA"
	offroad_factor = 0.5
	ground_color = Color(0.45, 0.38, 0.3)
	road_color = Color(0.34, 0.3, 0.27)
	wall_colors = [Color(0.6, 0.25, 0.18), Color(0.3, 0.4, 0.55), Color(0.75, 0.6, 0.2)]
	wall_height = 3.0
	sky_top = Color(0.45, 0.5, 0.6)
	sky_horizon = Color(0.85, 0.72, 0.55)
	sun_color = Color(1.0, 0.85, 0.65)
	fog_density = 0.0016


func _make_centerline() -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n: int = 240
	for i in n:
		var t: float = TAU * float(i) / float(n)
		var r: float = 120.0 + 26.0 * cos(2.0 * t + 1.0) + 22.0 * sin(3.0 * t)
		pts.append(Vector3(r * cos(t), 0.0, r * sin(t)))
	return pts


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var root := Node3D.new()
	root.name = "Scenery"
	add_child(root)
	var d: float = 4.0
	var idx: int = 0
	while d < path.length:
		var side: float = outside_side(d)
		var inner: Vector3 = path.point_at(d) - path.right_at(d) * side * (wall_offset - 2.0)
		var outer: Vector3 = outside_point(d, 4.0 + rng.randf_range(0.0, 8.0))
		_tire_stack(root, inner, rng.randi_range(2, 4))
		match idx % 4:
			0: _wreck(root, outer, path.tangent_at(d), rng)
			1: _container(root, outer, path.tangent_at(d), rng)
			2: _crate_pile(root, outer, rng)
			3: _wreck(root, outer, path.tangent_at(d), rng)
		idx += 1
		d += rng.randf_range(16.0, 28.0)
	# guindaste no centro
	_crane(root, Vector3(0, 0, 0))
	# placa
	var sign_post := Node3D.new()
	sign_post.position = Vector3(0, 0, -45.0)
	root.add_child(sign_post)
	ProcMesh.box(sign_post, Vector3(0.6, 9.0, 0.6), Vector3(-9, 4.5, 0), Color(0.3, 0.2, 0.12))
	ProcMesh.box(sign_post, Vector3(0.6, 9.0, 0.6), Vector3(9, 4.5, 0), Color(0.3, 0.2, 0.12))
	ProcMesh.box(sign_post, Vector3(22.0, 5.0, 0.5), Vector3(0, 9.0, 0), Color(0.15, 0.4, 0.2))
	var label := Label3D.new()
	label.text = "FERRO-VELHO\n14 MESES"
	label.font_size = 120
	label.pixel_size = 0.025
	label.modulate = Color(1.0, 0.9, 0.3)
	label.outline_size = 16
	label.position = Vector3(0, 9.0, 0.35)
	sign_post.add_child(label)


func _tire_stack(root: Node3D, pos: Vector3, n: int) -> void:
	for i in n:
		ProcMesh.torus(root, 0.28, 0.85, pos + Vector3(0, 0.3 + 0.55 * float(i), 0), Color(0.08, 0.08, 0.09))


func _wreck(root: Node3D, pos: Vector3, tangent: Vector3, rng: RandomNumberGenerator) -> void:
	var cols: Array[Color] = [Color(0.6, 0.2, 0.15), Color(0.25, 0.4, 0.6), Color(0.8, 0.7, 0.25), Color(0.4, 0.45, 0.4)]
	var c: Color = cols[rng.randi() % cols.size()]
	var w := Node3D.new()
	w.transform = Transform3D(Basis.looking_at(tangent, Vector3.UP), pos)
	w.rotate_object_local(Vector3.FORWARD, rng.randf_range(-0.2, 0.2))
	root.add_child(w)
	ProcMesh.box(w, Vector3(4.0, 1.3, 8.0), Vector3(0, 1.1, 0), c, Vector3.ZERO, 0.8, 0.3)
	ProcMesh.box(w, Vector3(3.4, 1.1, 4.0), Vector3(0, 2.2, 0.5), c.darkened(0.15), Vector3.ZERO, 0.8, 0.3)
	ProcMesh.box(w, Vector3(3.2, 0.1, 3.8), Vector3(0, 2.8, 0.5), Color(0.5, 0.65, 0.7), Vector3.ZERO, 0.2)
	for sx: float in [-1.9, 1.9]:
		for sz: float in [-2.6, 2.6]:
			ProcMesh.cyl(w, 0.6, 0.5, Vector3(sx, 0.6, sz), Color(0.08, 0.08, 0.09), Vector3(0, 0, 90))


func _container(root: Node3D, pos: Vector3, tangent: Vector3, rng: RandomNumberGenerator) -> void:
	var cols: Array[Color] = [Color(0.2, 0.45, 0.6), Color(0.65, 0.25, 0.2), Color(0.3, 0.5, 0.3)]
	var c := Node3D.new()
	c.transform = Transform3D(Basis.looking_at(tangent, Vector3.UP), pos)
	root.add_child(c)
	ProcMesh.box(c, Vector3(5.0, 5.0, 14.0), Vector3(0, 2.5, 0), cols[rng.randi() % cols.size()], Vector3.ZERO, 0.8, 0.3)
	if rng.randf() < 0.5:
		ProcMesh.box(c, Vector3(5.0, 5.0, 14.0), Vector3(0, 7.6, 0), cols[rng.randi() % cols.size()], Vector3.ZERO, 0.8, 0.3)


func _crate_pile(root: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	for i in 4:
		var o := Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3))
		ProcMesh.box(root, Vector3(2.5, 2.5, 2.5), pos + o + Vector3(0, 1.25, 0), Color(0.55, 0.4, 0.2), Vector3(0, rng.randf_range(0, 90), 0), 0.9)
	ProcMesh.cyl(root, 0.8, 1.6, pos + Vector3(4, 0.8, 1), Color(0.75, 0.2, 0.15), Vector3.ZERO, -1.0, 0.5, 0.4)


func _crane(root: Node3D, pos: Vector3) -> void:
	var c := Node3D.new()
	c.position = pos
	root.add_child(c)
	ProcMesh.box(c, Vector3(6.0, 1.5, 6.0), Vector3(0, 0.75, 0), Color(0.8, 0.65, 0.15), Vector3.ZERO, 0.6, 0.3)
	ProcMesh.box(c, Vector3(2.0, 26.0, 2.0), Vector3(0, 14.0, 0), Color(0.85, 0.7, 0.15), Vector3.ZERO, 0.6, 0.3)
	ProcMesh.box(c, Vector3(34.0, 1.6, 1.6), Vector3(10.0, 27.0, 0), Color(0.85, 0.7, 0.15), Vector3.ZERO, 0.6, 0.3)
	ProcMesh.cyl(c, 0.08, 14.0, Vector3(24.0, 19.5, 0), Color(0.15, 0.15, 0.15))
	ProcMesh.cyl(c, 2.2, 1.0, Vector3(24.0, 12.0, 0), Color(0.3, 0.3, 0.33), Vector3.ZERO, -1.0, 0.5, 0.7)
