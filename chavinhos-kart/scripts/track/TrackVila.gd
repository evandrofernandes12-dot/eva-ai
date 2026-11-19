class_name TrackVila
extends TrackBase
## Pista 1: Circuito da Vila. Um laço de 917 m ao redor da praça com chafariz, casas coloridas
## (incluindo a casa #71), barris e caixotes decorativos. Curva mais fechada: ~30 m de raio.


func _init_theme() -> void:
	track_title = "CIRCUITO DA VILA"
	ground_color = Color(0.58, 0.42, 0.27)
	road_color = Color(0.32, 0.31, 0.34)
	wall_colors = [Color(0.9, 0.74, 0.52), Color(0.82, 0.52, 0.36)]


func _make_centerline() -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n: int = 240
	for i in n:
		var t: float = TAU * float(i) / float(n)
		var r: float = 125.0 + 38.0 * sin(2.0 * t + 0.6) + 24.0 * cos(3.0 * t) + 9.0 * sin(5.0 * t + 1.0)
		pts.append(Vector3(r * cos(t), 0.0, r * sin(t)))
	return pts


func _build_scenery() -> void:
	_build_fountain()
	_build_houses()
	_build_props()


func _build_fountain() -> void:
	var root := Node3D.new()
	root.name = "Fountain"
	add_child(root)
	ProcMesh.cyl(root, 9.0, 0.9, Vector3(0, 0.45, 0), Color(0.62, 0.6, 0.58), Vector3.ZERO, -1.0, 0.9)
	ProcMesh.cyl(root, 8.0, 0.2, Vector3(0, 0.85, 0), Color(0.3, 0.6, 0.85, 0.9), Vector3.ZERO, -1.0, 0.1)
	ProcMesh.cyl(root, 1.1, 4.0, Vector3(0, 2.2, 0), Color(0.7, 0.68, 0.65), Vector3.ZERO, 0.8, 0.9)
	ProcMesh.cyl(root, 3.0, 0.4, Vector3(0, 3.6, 0), Color(0.66, 0.64, 0.6), Vector3.ZERO, -1.0, 0.9)
	ProcMesh.sphere(root, 0.7, Vector3(0, 4.5, 0), Color(0.45, 0.75, 0.95, 0.85), Vector3.ONE, 0.1)
	# bancos de madeira e caixotes em volta
	for i in 8:
		var ang: float = TAU * float(i) / 8.0
		ProcMesh.box(root, Vector3(2.4, 0.4, 0.7), Vector3(cos(ang) * 14.0, 0.5, sin(ang) * 14.0), Color(0.45, 0.3, 0.16), Vector3(0, -rad_to_deg(ang) + 90.0, 0), 0.9)


func _build_houses() -> void:
	var palette: Array[Color] = [
		Color(0.92, 0.78, 0.4), Color(0.85, 0.45, 0.35), Color(0.55, 0.75, 0.8),
		Color(0.9, 0.62, 0.3), Color(0.7, 0.8, 0.5), Color(0.9, 0.55, 0.65),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var root := Node3D.new()
	root.name = "Houses"
	add_child(root)
	var d: float = 8.0
	var number: int = 1
	while d < path.length:
		var side: float = outside_side(d)
		var pos: Vector3 = outside_point(d, 14.0 + rng.randf_range(0.0, 5.0))
		var h: float = rng.randf_range(8.0, 13.0)
		var w: float = rng.randf_range(15.0, 20.0) # largura ao longo da pista (eixo Z local)
		var color: Color = palette[rng.randi() % palette.size()]
		var house := Node3D.new()
		# eixo X local = direita da pista; Z local = ao longo da pista
		house.transform = Transform3D(Basis.looking_at(path.tangent_at(d), Vector3.UP), pos)
		root.add_child(house)
		ProcMesh.box(house, Vector3(13.0, h, w), Vector3(0, h / 2.0, 0), color, Vector3.ZERO, 0.95)
		ProcMesh.box(house, Vector3(14.5, 1.2, w + 1.5), Vector3(0, h + 0.6, 0), Color(0.62, 0.25, 0.18), Vector3.ZERO, 0.9)
		var face_x: float = -side * 6.6 # fachada voltada para a pista
		ProcMesh.box(house, Vector3(0.3, 4.0, 2.4), Vector3(face_x, 2.0, -w * 0.2), Color(0.35, 0.22, 0.12))
		for wz: float in [0.1, 0.32]:
			ProcMesh.box(house, Vector3(0.2, 2.2, 2.0), Vector3(face_x, h * 0.55, w * wz), Color(0.6, 0.8, 0.95), Vector3.ZERO, 0.2, 0.0, 0.3)
		var label := Label3D.new()
		label.text = "#%d" % (71 if number == 3 else 60 + number)
		label.font_size = 64
		label.pixel_size = 0.02
		label.modulate = Color(0.1, 0.1, 0.12)
		label.position = Vector3(face_x - side * 0.25, 4.8, -w * 0.2)
		label.rotation.y = -side * PI / 2.0
		house.add_child(label)
		number += 1
		d += w + rng.randf_range(6.0, 12.0)


func _build_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var root := Node3D.new()
	root.name = "Props"
	add_child(root)
	var d: float = 14.0
	while d < path.length:
		# barris e caixotes encostados do lado de dentro da parede
		var inner: Vector3 = path.point_at(d) - (outside_point(d, 0.0) - path.point_at(d)).normalized() * (wall_offset - 1.6)
		if rng.randf() < 0.55:
			ProcMesh.cyl(root, 0.6, 1.1, inner + Vector3(0, 0.55, 0), Color(0.45, 0.28, 0.13), Vector3.ZERO, 0.55, 0.9)
		else:
			ProcMesh.box(root, Vector3(1.2, 1.2, 1.2), inner + Vector3(0, 0.6, 0), Color(0.6, 0.42, 0.22), Vector3(0, rng.randf_range(0.0, 90.0), 0), 0.9)
		d += rng.randf_range(35.0, 70.0)
