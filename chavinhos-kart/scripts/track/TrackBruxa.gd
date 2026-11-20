class_name TrackBruxa
extends TrackBase
## Pista 3: Casa da Bruxa do 71. Interior escuro e assombrado: caldeirões, portais, lanternas e teias.


func _init_theme() -> void:
	track_title = "CASA DA BRUXA DO 71"
	indoor = true
	offroad_factor = 0.6
	road_half_width = 8.0
	wall_offset = 13.0
	ground_color = Color(0.22, 0.15, 0.1)
	road_color = Color(0.42, 0.29, 0.18)
	wall_colors = [Color(0.32, 0.2, 0.14), Color(0.25, 0.17, 0.22)]
	wall_height = 6.0
	sky_top = Color(0.06, 0.03, 0.1)        # fundo (teto/escuridão)
	sky_horizon = Color(0.45, 0.3, 0.6)     # ambiente roxo
	sun_color = Color(0.7, 0.55, 1.0)
	sun_energy = 0.45
	ambient_energy = 0.75
	fog_density = 0.006
	item_box_dists = [0.1, 0.35, 0.6, 0.85]


func _make_centerline() -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n: int = 240
	for i in n:
		var t: float = TAU * float(i) / float(n)
		var r: float = 90.0 + 16.0 * sin(3.0 * t + 0.4)
		pts.append(Vector3(r * cos(t), 0.0, r * sin(t)))
	return pts


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var root := Node3D.new()
	root.name = "Scenery"
	add_child(root)
	# teto
	var ceiling := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(700.0, 700.0)
	ceiling.mesh = plane
	ceiling.rotation_degrees = Vector3(180, 0, 0)
	ceiling.position = Vector3(0, 18.0, 0)
	ceiling.material_override = ProcMesh.mat(Color(0.12, 0.08, 0.1), 1.0)
	root.add_child(ceiling)
	# caldeirão central com brilho
	_cauldron(root, Vector3.ZERO, 5.0, Color(0.7, 0.3, 1.0), true)
	# caldeirões, lanternas, estantes e portais ao longo da pista
	var d: float = 5.0
	var idx: int = 0
	while d < path.length:
		var side: float = outside_side(d)
		var inner: Vector3 = path.point_at(d) - path.right_at(d) * side * (wall_offset - 2.2)
		var outer: Vector3 = outside_point(d, 3.0)
		match idx % 4:
			0:
				_cauldron(root, inner, 1.3, Color(0.5, 1.0, 0.4) if idx % 8 == 0 else Color(0.8, 0.35, 1.0), idx % 3 == 0)
				_portal(root, outer, path.tangent_at(d), side)
			1:
				_lantern(root, inner + Vector3(0, 5.0, 0), idx % 2 == 0)
				_bookshelf(root, outer, path.tangent_at(d))
			2:
				ProcMesh.box(root, Vector3(2.0, 2.0, 2.0), inner + Vector3(0, 1.0, 0), Color(0.4, 0.27, 0.15), Vector3(0, rng.randf_range(0.0, 90.0), 0), 0.9)
				_web(root, inner + Vector3(0, 4.5, 0), rng)
			3:
				_lantern(root, inner + Vector3(0, 4.5, 0), false)
				_cauldron(root, outer, 1.8, Color(0.4, 0.9, 1.0), false)
		idx += 1
		d += rng.randf_range(22.0, 32.0)
	# luzes pontuais perto da largada
	for k in 4:
		var dd: float = path.length * (0.0 + 0.25 * float(k))
		_light(root, path.point_at(dd) + Vector3(0, 6.0, 0), Color(1.0, 0.7, 0.35) if k % 2 == 0 else Color(0.7, 0.45, 1.0))


func _light(root: Node3D, pos: Vector3, color: Color) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = 2.2
	l.omni_range = 38.0
	root.add_child(l)


func _cauldron(root: Node3D, pos: Vector3, scale_f: float, glow: Color, with_light: bool) -> void:
	var c := Node3D.new()
	c.position = pos
	root.add_child(c)
	ProcMesh.sphere(c, 1.0 * scale_f, Vector3(0, 1.0 * scale_f, 0), Color(0.12, 0.13, 0.16), Vector3(1, 0.85, 1), 0.4)
	ProcMesh.cyl(c, 0.78 * scale_f, 0.06 * scale_f, Vector3(0, 1.75 * scale_f, 0), glow, Vector3.ZERO, -1.0, 0.2, 0.0, 2.5)
	for i in 3:
		var a: float = TAU * float(i) / 3.0
		ProcMesh.cyl(c, 0.12 * scale_f, 0.6 * scale_f, Vector3(cos(a) * 0.7 * scale_f, 0.25 * scale_f, sin(a) * 0.7 * scale_f), Color(0.1, 0.1, 0.12))
	if with_light:
		var l := OmniLight3D.new()
		l.position = Vector3(0, 3.0 * scale_f, 0)
		l.light_color = glow
		l.light_energy = 1.8
		l.omni_range = 26.0
		c.add_child(l)


func _lantern(root: Node3D, pos: Vector3, warm: bool) -> void:
	ProcMesh.cyl(root, 0.03, 8.0, pos + Vector3(0, 4.0, 0), Color(0.15, 0.15, 0.15))
	ProcMesh.sphere(root, 0.4, pos, Color(1.0, 0.8, 0.4) if warm else Color(0.6, 0.9, 1.0), Vector3(1, 1.3, 1), 0.2, 3.0)
	ProcMesh.box(root, Vector3(0.7, 0.1, 0.7), pos + Vector3(0, 0.55, 0), Color(0.15, 0.12, 0.1))


func _portal(root: Node3D, pos: Vector3, tangent: Vector3, side: float) -> void:
	var p := Node3D.new()
	p.transform = Transform3D(Basis.looking_at(tangent, Vector3.UP), pos + Vector3(0, 4.5, 0))
	root.add_child(p)
	p.rotate_object_local(Vector3.UP, side * PI / 2.0)
	ProcMesh.torus(p, 0.5, 3.2, Vector3.ZERO, Color(0.45, 0.5, 1.0), Vector3(90, 0, 0))
	ProcMesh.cyl(p, 2.6, 0.1, Vector3.ZERO, Color(0.55, 0.3, 1.0), Vector3(90, 0, 0), -1.0, 0.2, 0.0, 2.2)


func _bookshelf(root: Node3D, pos: Vector3, tangent: Vector3) -> void:
	var s := Node3D.new()
	s.transform = Transform3D(Basis.looking_at(tangent, Vector3.UP), pos)
	root.add_child(s)
	ProcMesh.box(s, Vector3(2.0, 9.0, 8.0), Vector3(0, 4.5, 0), Color(0.3, 0.2, 0.12), Vector3.ZERO, 0.9)
	for i in 5:
		ProcMesh.box(s, Vector3(0.4, 0.9, 7.0), Vector3(-1.1, 1.2 + 1.7 * float(i), 0), Color(0.6, 0.2 + 0.1 * float(i), 0.3), Vector3.ZERO, 0.9)


func _web(root: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	ProcMesh.box(root, Vector3(3.0, 0.02, 3.0), pos, Color(0.9, 0.9, 0.95, 0.35), Vector3(rng.randf_range(-20, 20), rng.randf_range(0, 360), 0), 0.9)
