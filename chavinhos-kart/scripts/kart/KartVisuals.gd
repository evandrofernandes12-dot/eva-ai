class_name KartVisuals
extends Node3D
## Gera proceduralmente o kart + piloto a partir de RacerStats (primitivas via ProcMesh) e
## anima rodas, esterçamento, inclinação, drift, fumaça e faíscas.
## PONTO DE TROCA: para usar modelos .glb reais, substitua build() por um instanciador de
## PackedScene que exponha os mesmos nós de roda (ver _wheel()).
## Convenção: a frente do kart é -Z; comprimento ~2.6, largura ~1.8.

const DARK: Color = Color(0.13, 0.13, 0.15)
const RUST: Color = Color(0.48, 0.27, 0.17)
const METAL: Color = Color(0.55, 0.57, 0.6)
const SKIN: Color = Color(0.96, 0.76, 0.6)

var stats: RacerStats
var _body: Node3D
var _steer_pivots: Array[Node3D] = []
var _spin_nodes: Array[Node3D] = []
var _spin_radii: Array[float] = []
var _smoke: CPUParticles3D
var _sparks: CPUParticles3D
var _exhaust_pos: Vector3 = Vector3(0.5, 0.8, 1.3)
var _prop: Node3D
var _hover: bool = false
var _bob_t: float = 0.0
var _spin_angle: float = 0.0
var _lean: float = 0.0
var _steer_vis: float = 0.0


func build(s: RacerStats) -> void:
	stats = s
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_steer_pivots.clear()
	_spin_nodes.clear()
	_spin_radii.clear()
	_prop = null
	_hover = false
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var seat: Vector3 = _build_kart(s.kart_style, s.body_color, s.accent_color)
	var rig: Dictionary = _rig(s.kart_style, seat)
	_build_controls(rig, s.id)
	_build_driver(s.id, rig)
	_build_fx()


# ===================================================================== animação

func update_visuals(delta: float, speed: float, steer: float, drifting: bool, drift_dir: float,
		drift_level: int, boosting: bool, spinning: bool, offroad: bool, top_speed: float) -> void:
	if _body == null:
		return
	# rodas giram / esterçam
	for i in _spin_nodes.size():
		_spin_nodes[i].rotation.x -= speed * delta / _spin_radii[i]
	_steer_vis = lerpf(_steer_vis, steer, clampf(delta * 10.0, 0.0, 1.0))
	for p in _steer_pivots:
		p.rotation.y = -_steer_vis * 0.5
	if _prop != null:
		_prop.rotation.y += delta * (14.0 + absf(speed))

	# inclinação e ângulo de drift
	var ratio: float = clampf(absf(speed) / maxf(top_speed, 1.0), 0.0, 1.0)
	var lean_t: float = steer * ratio * 0.1
	var yaw_t: float = 0.0
	if drifting:
		yaw_t = -drift_dir * 0.38
		lean_t = drift_dir * 0.14
	_lean = lerpf(_lean, lean_t, clampf(delta * 8.0, 0.0, 1.0))
	_body.rotation.z = _lean
	_body.rotation.y = lerpf(_body.rotation.y, yaw_t, clampf(delta * 9.0, 0.0, 1.0))

	# rodopio ao ser atingido
	if spinning:
		_spin_angle += delta * 14.0
		rotation.y = _spin_angle
	else:
		if absf(_spin_angle) > 0.0:
			_spin_angle = wrapf(_spin_angle, -PI, PI)
			_spin_angle = lerp_angle(_spin_angle, 0.0, clampf(delta * 12.0, 0.0, 1.0))
			if absf(_spin_angle) < 0.01:
				_spin_angle = 0.0
			rotation.y = _spin_angle

	if _hover:
		_bob_t += delta * 3.0
		_body.position.y = 0.3 + sin(_bob_t) * 0.08

	# partículas
	if _smoke != null:
		_smoke.emitting = absf(speed) > 2.0
		if boosting:
			_smoke.color = Color(1.0, 0.55, 0.15, 0.9)
		elif offroad:
			_smoke.color = Color(0.55, 0.42, 0.28, 0.7)
		else:
			_smoke.color = Color(0.45, 0.45, 0.47, 0.5)
	if _sparks != null:
		_sparks.emitting = drifting
		_sparks.color = _drift_color(drift_level)


func _drift_color(level: int) -> Color:
	match level:
		1:
			return Color(0.35, 0.7, 1.0)
		2:
			return Color(1.0, 0.55, 0.15)
		3:
			return Color(0.8, 0.35, 1.0)
		_:
			return Color(1.0, 0.95, 0.6)


# ===================================================================== helpers

func _wheel(pos: Vector3, radius: float, width: float, tire: Color, hub: Color, steer: bool, spokes: bool = true) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	_body.add_child(pivot)
	var spinner := Node3D.new()
	pivot.add_child(spinner)
	# pneu redondo (anel) achatado para a largura da roda + cubo no meio
	var tire_mesh: MeshInstance3D = ProcMesh.torus(spinner, radius * 0.5, radius, Vector3.ZERO, tire, Vector3(0, 0, 90))
	tire_mesh.scale = Vector3(1.0, maxf(width / (radius * 0.5), 0.3), 1.0)
	ProcMesh.cyl(spinner, radius * 0.6, width * 0.9, Vector3.ZERO, hub, Vector3(0, 0, 90), -1.0, 0.4, 0.6)
	if spokes:
		ProcMesh.rbox(spinner, Vector3(width + 0.05, radius * 1.7, 0.07), Vector3.ZERO, hub.darkened(0.35))
	if steer:
		_steer_pivots.append(pivot)
	_spin_nodes.append(spinner)
	_spin_radii.append(radius)


func _engine(pos: Vector3, color: Color = Color(0.2, 0.2, 0.22)) -> void:
	ProcMesh.rbox(_body, Vector3(0.6, 0.5, 0.55), pos, color, Vector3.ZERO, 0.6, 0.4)
	ProcMesh.rbox(_body, Vector3(0.5, 0.18, 0.45), pos + Vector3(0, 0.33, 0), METAL, Vector3.ZERO, 0.4, 0.7)
	for i in 3:
		ProcMesh.rbox(_body, Vector3(0.62, 0.04, 0.5), pos + Vector3(0, -0.05 + 0.1 * float(i), 0), DARK)


func _exhaust(start: Vector3, color: Color = RUST) -> void:
	ProcMesh.cyl(_body, 0.08, 0.7, start, color, Vector3(90, 0, 0), -1.0, 0.7, 0.5)
	ProcMesh.cyl(_body, 0.13, 0.35, start + Vector3(0, 0.0, 0.5), color.darkened(0.15), Vector3(90, 0, 0), -1.0, 0.7, 0.5)
	_exhaust_pos = start + Vector3(0, 0.05, 0.75)


# ===================================================================== estilos de kart
# Cada função devolve a posição do assento (onde o piloto é montado).

func _build_kart(style: String, c1: Color, c2: Color) -> Vector3:
	match style:
		"barrel": return _style_barrel(c1, c2)
		"plank": return _style_plank(c1, c2)
		"trike": return _style_trike(c1, c2)
		"armored": return _style_armored(c1, c2)
		"pinkcar": return _style_pinkcar(c1, c2)
		"crate": return _style_crate(c1, c2, false)
		"mail": return _style_crate(c1, c2, true)
		"teacup": return _style_teacup(c1, c2)
		"vintage": return _style_vintage(c1, c2)
		"broom": return _style_broom(c1, c2)
	return _style_barrel(c1, c2)


func _style_barrel(wood: Color, _c2: Color) -> Vector3:
	ProcMesh.cyl(_body, 0.52, 1.7, Vector3(0, 0.62, 0.05), wood, Vector3(90, 0, 0))
	for z: float in [-0.65, 0.0, 0.7]:
		ProcMesh.cyl(_body, 0.55, 0.12, Vector3(0, 0.62, z), DARK, Vector3(90, 0, 0), -1.0, 0.5, 0.5)
	# tábuas (frisos) no tampo frontal
	ProcMesh.rbox(_body, Vector3(0.05, 0.9, 0.04), Vector3(0, 0.62, -0.92), wood.darkened(0.3))
	_engine(Vector3(0, 0.8, 1.25), RUST)
	_exhaust(Vector3(0.45, 1.0, 1.0))
	_wheel(Vector3(-0.8, 0.3, -0.8), 0.3, 0.2, DARK, wood.lightened(0.1), true)
	_wheel(Vector3(0.8, 0.3, -0.8), 0.3, 0.2, DARK, wood.lightened(0.1), true)
	_wheel(Vector3(-0.9, 0.42, 0.95), 0.42, 0.34, DARK, METAL, false)
	_wheel(Vector3(0.9, 0.42, 0.95), 0.42, 0.34, DARK, METAL, false)
	return Vector3(0, 0.78, -0.05)


func _style_plank(wood: Color, accent: Color) -> Vector3:
	ProcMesh.rbox(_body, Vector3(1.1, 0.12, 2.5), Vector3(0, 0.36, 0.05), wood)
	for i in 5: # adesivos coloridos
		var cols: Array[Color] = [Color(0.9, 0.3, 0.8), Color(0.3, 0.8, 0.4), Color(0.95, 0.8, 0.2), Color(0.3, 0.6, 0.95), Color(0.95, 0.4, 0.2)]
		ProcMesh.cyl(_body, 0.1, 0.02, Vector3(-0.35 + 0.17 * float(i), 0.43, -0.5 + 0.35 * float(i % 3)), cols[i])
	# cadeira escolar atrás
	ProcMesh.rbox(_body, Vector3(0.7, 0.07, 0.6), Vector3(0, 0.78, 0.55), wood.lightened(0.1))
	ProcMesh.rbox(_body, Vector3(0.7, 0.55, 0.07), Vector3(0, 1.05, 0.88), wood.lightened(0.1))
	for sx: float in [-0.3, 0.3]:
		ProcMesh.cyl(_body, 0.03, 0.45, Vector3(sx, 0.55, 0.5), METAL)
	ProcMesh.rbox(_body, Vector3(0.5, 0.4, 0.5), Vector3(0, 0.62, 1.1), accent.darkened(0.5), Vector3.ZERO, 0.5, 0.5)
	_exhaust(Vector3(0.35, 0.8, 1.0), RUST)
	_wheel(Vector3(-0.5, 0.2, -1.05), 0.2, 0.15, DARK, Color(0.85, 0.7, 0.2), true, false)
	_wheel(Vector3(0.5, 0.2, -1.05), 0.2, 0.15, DARK, Color(0.85, 0.7, 0.2), true, false)
	_wheel(Vector3(-0.8, 0.45, 1.0), 0.45, 0.34, DARK, METAL, false)
	_wheel(Vector3(0.8, 0.45, 1.0), 0.45, 0.34, DARK, METAL, false)
	return Vector3(0, 0.84, 0.5)


func _style_trike(red: Color, gold: Color) -> Vector3:
	ProcMesh.rbox(_body, Vector3(0.75, 0.38, 1.6), Vector3(0, 0.62, 0.35), red, Vector3.ZERO, 0.25, 0.3)
	ProcMesh.rbox(_body, Vector3(0.7, 0.04, 1.62), Vector3(0, 0.82, 0.35), gold, Vector3.ZERO, 0.3, 0.8)
	# garfo dianteiro (o guidão alto vem do rig)
	ProcMesh.cyl(_body, 0.05, 0.8, Vector3(0, 0.62, -0.95), red, Vector3(0, 0, 0), -1.0, 0.25, 0.3)
	# para-lamas
	ProcMesh.rbox(_body, Vector3(0.3, 0.05, 0.9), Vector3(-0.78, 0.9, 0.9), red, Vector3.ZERO, 0.25, 0.3)
	ProcMesh.rbox(_body, Vector3(0.3, 0.05, 0.9), Vector3(0.78, 0.9, 0.9), red, Vector3.ZERO, 0.25, 0.3)
	ProcMesh.cyl(_body, 0.05, 0.6, Vector3(0.42, 0.9, 1.35), METAL.lightened(0.3), Vector3(90, 0, 0), -1.0, 0.2, 0.9)
	_exhaust_pos = Vector3(0.42, 0.92, 1.7)
	_wheel(Vector3(0, 0.42, -0.95), 0.42, 0.22, DARK, METAL.lightened(0.3), true)
	_wheel(Vector3(-0.82, 0.45, 0.95), 0.45, 0.5, DARK, METAL.lightened(0.3), false, false)
	_wheel(Vector3(0.82, 0.45, 0.95), 0.45, 0.5, DARK, METAL.lightened(0.3), false, false)
	return Vector3(0, 0.82, 0.5)


func _style_armored(steel: Color, trim: Color) -> Vector3:
	ProcMesh.rbox(_body, Vector3(1.5, 0.7, 1.4), Vector3(0, 0.85, -0.45), steel, Vector3.ZERO, 0.5, 0.6)  # capô
	ProcMesh.rbox(_body, Vector3(1.0, 0.1, 0.2), Vector3(0, 0.92, -1.17), trim, Vector3.ZERO, 0.4, 0.8)    # grade dourada
	ProcMesh.rbox(_body, Vector3(0.9, 0.35, 0.05), Vector3(0, 0.92, -1.17), DARK)
	ProcMesh.rbox(_body, Vector3(1.55, 0.2, 0.3), Vector3(0, 0.45, -1.3), METAL, Vector3.ZERO, 0.4, 0.7)   # para-choque
	for sx: float in [-0.6, 0.6]:
		ProcMesh.rbox(_body, Vector3(0.25, 0.22, 0.1), Vector3(sx, 1.05, -1.17), Color(1.0, 0.95, 0.7), Vector3.ZERO, 0.2, 0.0, 1.5)
	ProcMesh.rbox(_body, Vector3(1.5, 0.12, 1.3), Vector3(0, 0.55, 0.85), steel.darkened(0.2), Vector3.ZERO, 0.5, 0.6) # base traseira
	# gaiola traseira
	for sx: float in [-0.7, 0.7]:
		for sz: float in [0.3, 1.4]:
			ProcMesh.cyl(_body, 0.045, 1.0, Vector3(sx, 1.15, sz), trim.darkened(0.2), Vector3.ZERO, -1.0, 0.5, 0.6)
	for i in 4:
		ProcMesh.cyl(_body, 0.03, 1.1, Vector3(-0.7 + 0.0, 1.15, 0.3 + 0.37 * float(i)), METAL)
	ProcMesh.rbox(_body, Vector3(1.5, 0.08, 1.2), Vector3(0, 1.68, 0.85), steel, Vector3.ZERO, 0.5, 0.6)
	ProcMesh.rbox(_body, Vector3(0.45, 0.4, 0.4), Vector3(0, 0.9, 1.1), Color(0.85, 0.7, 0.3)) # saco de dinheiro
	# escapamentos duplos
	_exhaust(Vector3(0.6, 0.95, 1.2))
	ProcMesh.cyl(_body, 0.08, 0.7, Vector3(0.78, 0.95, 1.2), RUST, Vector3(90, 0, 0), -1.0, 0.7, 0.5)
	# faixa lateral
	ProcMesh.rbox(_body, Vector3(1.56, 0.1, 0.9), Vector3(0, 0.62, 0.0), trim)
	_wheel(Vector3(-0.85, 0.5, -0.8), 0.5, 0.45, DARK, METAL, true)
	_wheel(Vector3(0.85, 0.5, -0.8), 0.5, 0.45, DARK, METAL, true)
	_wheel(Vector3(-0.85, 0.5, 0.9), 0.5, 0.45, DARK, METAL, false)
	_wheel(Vector3(0.85, 0.5, 0.9), 0.5, 0.45, DARK, METAL, false)
	return Vector3(0, 0.95, 0.05)


func _style_pinkcar(pink: Color, lilac: Color) -> Vector3:
	ProcMesh.rbox(_body, Vector3(1.3, 0.45, 2.3), Vector3(0, 0.55, 0.0), pink, Vector3.ZERO, 0.3)
	ProcMesh.sphere(_body, 0.65, Vector3(0, 0.62, -0.95), pink, Vector3(1.0, 0.55, 1.0), 0.3)
	for sx: float in [-0.45, 0.45]:
		ProcMesh.sphere(_body, 0.16, Vector3(sx, 0.7, -1.5), Color(1.0, 0.92, 0.4), Vector3.ONE, 0.2, 1.0)
	ProcMesh.rbox(_body, Vector3(0.7, 0.2, 0.06), Vector3(0, 0.55, -1.62), lilac)
	ProcMesh.rbox(_body, Vector3(1.0, 0.8, 0.2), Vector3(0, 1.05, 0.95), pink.lightened(0.15), Vector3(-10, 0, 0), 0.4) # encosto
	ProcMesh.rbox(_body, Vector3(0.9, 0.08, 0.7), Vector3(0, 0.82, 0.55), pink.darkened(0.1))
	for sx: float in [-0.65, 0.65]: # corações
		ProcMesh.sphere(_body, 0.1, Vector3(sx, 0.62, -0.1), Color(0.95, 0.2, 0.4), Vector3(1, 1, 0.3))
	ProcMesh.rbox(_body, Vector3(0.45, 0.4, 0.5), Vector3(0, 0.8, 1.2), Color(0.8, 0.15, 0.4), Vector3.ZERO, 0.4, 0.2)
	_exhaust(Vector3(0.4, 0.75, 1.2), lilac)
	_wheel(Vector3(-0.72, 0.33, -0.85), 0.33, 0.26, DARK, pink.lightened(0.2), true)
	_wheel(Vector3(0.72, 0.33, -0.85), 0.33, 0.26, DARK, pink.lightened(0.2), true)
	_wheel(Vector3(-0.72, 0.33, 0.85), 0.33, 0.26, DARK, pink.lightened(0.2), false)
	_wheel(Vector3(0.72, 0.33, 0.85), 0.33, 0.26, DARK, pink.lightened(0.2), false)
	return Vector3(0, 0.82, 0.45)


func _style_crate(frame: Color, wood: Color, mail: bool) -> Vector3:
	# triciclo estilo bicicleta (2 rodas dianteiras) + caixote de madeira + motor traseiro
	var crate_z: float = -0.25 if mail else 0.15
	ProcMesh.rbox(_body, Vector3(1.0, 0.5, 0.9), Vector3(0, 0.65, crate_z), wood, Vector3.ZERO, 0.9)
	for i in 3:
		ProcMesh.rbox(_body, Vector3(1.02, 0.05, 0.92), Vector3(0, 0.52 + 0.14 * float(i), crate_z), wood.darkened(0.25), Vector3.ZERO, 0.9)
	if mail: # cartas e pacotes
		ProcMesh.rbox(_body, Vector3(0.5, 0.12, 0.35), Vector3(0.0, 0.95, crate_z), Color(0.95, 0.92, 0.8), Vector3(0, 12, 0))
		ProcMesh.rbox(_body, Vector3(0.4, 0.3, 0.35), Vector3(-0.25, 1.0, crate_z + 0.1), Color(0.75, 0.6, 0.4))
	# quadro da bicicleta
	ProcMesh.cyl(_body, 0.04, 1.8, Vector3(0, 0.7, -0.2), frame, Vector3(90, 0, 0), -1.0, 0.5, 0.3)
	ProcMesh.cyl(_body, 0.04, 0.9, Vector3(0, 0.98, -0.95), frame, Vector3(-25, 0, 0), -1.0, 0.5, 0.3)
	ProcMesh.rbox(_body, Vector3(0.3, 0.07, 0.4), Vector3(0, 1.0, 0.6), Color(0.45, 0.28, 0.15))
	_engine(Vector3(0, 0.8, 1.2), Color(0.8, 0.15, 0.1))
	ProcMesh.cyl(_body, 0.1, 0.25, Vector3(-0.15, 1.12, 1.15), Color(0.4, 0.5, 0.3)) # tanque
	_exhaust(Vector3(0.4, 0.95, 1.05), RUST)
	_wheel(Vector3(-0.55, 0.38, -1.0), 0.38, 0.1, DARK, METAL, true)
	_wheel(Vector3(0.55, 0.38, -1.0), 0.38, 0.1, DARK, METAL, true)
	_wheel(Vector3(0, 0.45, 1.2), 0.45, 0.5, DARK, METAL, false, false)
	return Vector3(0, 0.98, 0.55)


func _style_teacup(blue: Color, pink: Color) -> Vector3:
	var porcelain: Color = blue.lightened(0.25)
	ProcMesh.cyl(_body, 1.0, 0.1, Vector3(0, 0.38, 0.0), Color(0.93, 0.95, 1.0), Vector3.ZERO, 1.05, 0.2, 0.2)   # pires
	ProcMesh.cyl(_body, 0.78, 0.7, Vector3(0, 0.78, 0.1), porcelain, Vector3.ZERO, 0.95, 0.2, 0.2)               # xícara
	ProcMesh.cyl(_body, 0.7, 0.04, Vector3(0, 1.13, 0.1), Color(0.85, 0.7, 0.3), Vector3.ZERO, -1.0, 0.3, 0.8)    # borda dourada
	ProcMesh.cyl(_body, 0.62, 0.05, Vector3(0, 1.0, 0.1), Color(0.3, 0.1, 0.1))                                    # interior escuro
	ProcMesh.torus(_body, 0.08, 0.3, Vector3(0.0, 0.85, 1.05), porcelain, Vector3(0, 90, 0))                       # alça
	ProcMesh.cyl(_body, 0.2, 0.7, Vector3(0, 0.8, -0.9), porcelain, Vector3(-70, 0, 0), 0.1, 0.2, 0.2)             # bico do bule
	ProcMesh.rbox(_body, Vector3(0.8, 0.5, 0.06), Vector3(0, 0.75, -0.6), Color(0.7, 0.72, 0.75), Vector3.ZERO, 0.3, 0.8)  # grade
	ProcMesh.rbox(_body, Vector3(1.4, 0.05, 0.5), Vector3(0, 1.3, 1.3), porcelain, Vector3(-10, 0, 0), 0.2, 0.2)   # aerofólio
	for sx: float in [-0.5, 0.5]:
		ProcMesh.rbox(_body, Vector3(0.05, 0.4, 0.05), Vector3(sx, 1.1, 1.3), METAL)
	for sx: float in [-0.6, 0.6]:
		ProcMesh.sphere(_body, 0.1, Vector3(sx, 0.55, -0.6), pink, Vector3(1, 1, 0.4))
	ProcMesh.rbox(_body, Vector3(0.7, 0.45, 0.15), Vector3(0, 1.0, 0.8), Color(0.65, 0.12, 0.18)) # banco
	_exhaust_pos = Vector3(-0.6, 0.6, 1.2)
	_wheel(Vector3(-0.85, 0.4, -0.85), 0.4, 0.3, DARK, pink, true)
	_wheel(Vector3(0.85, 0.4, -0.85), 0.4, 0.3, DARK, pink, true)
	_wheel(Vector3(-0.85, 0.4, 0.85), 0.4, 0.3, DARK, pink, false)
	_wheel(Vector3(0.85, 0.4, 0.85), 0.4, 0.3, DARK, pink, false)
	return Vector3(0, 0.8, 0.2)


func _style_vintage(burgundy: Color, _c2: Color) -> Vector3:
	ProcMesh.rbox(_body, Vector3(0.95, 0.65, 1.7), Vector3(0, 0.75, -0.55), burgundy, Vector3.ZERO, 0.25, 0.4)    # capô longo
	ProcMesh.rbox(_body, Vector3(0.7, 0.55, 0.1), Vector3(0, 0.78, -1.45), METAL.lightened(0.3), Vector3.ZERO, 0.2, 0.9) # radiador
	for i in 5:
		ProcMesh.rbox(_body, Vector3(0.03, 0.5, 0.05), Vector3(-0.25 + 0.125 * float(i), 0.78, -1.5), DARK)
	for sx: float in [-0.5, 0.5]:
		ProcMesh.sphere(_body, 0.17, Vector3(sx, 0.95, -1.45), Color(0.85, 0.7, 0.25), Vector3.ONE, 0.2, 0.0)
		ProcMesh.cyl(_body, 0.03, 0.35, Vector3(sx, 0.75, -1.25), DARK)
	ProcMesh.rbox(_body, Vector3(1.0, 0.45, 1.2), Vector3(0, 0.6, 0.8), burgundy.darkened(0.3), Vector3.ZERO, 0.25, 0.4)  # cockpit
	ProcMesh.rbox(_body, Vector3(0.7, 0.55, 0.15), Vector3(0, 1.0, 1.25), Color(0.4, 0.25, 0.12))                          # banco
	ProcMesh.cyl(_body, 0.1, 0.25, Vector3(0.58, 1.0, -0.25), Color(0.85, 0.7, 0.25), Vector3(0, 0, 90), 0.18, 0.2, 0.9) # buzina
	ProcMesh.cyl(_body, 0.06, 1.6, Vector3(0.6, 0.35, 0.3), METAL.lightened(0.3), Vector3(90, 0, 0), -1.0, 0.2, 0.9)     # escapamento lateral
	_exhaust_pos = Vector3(0.6, 0.35, 1.15)
	_wheel(Vector3(-0.78, 0.46, -0.95), 0.46, 0.2, DARK, Color(0.85, 0.7, 0.25), true)
	_wheel(Vector3(0.78, 0.46, -0.95), 0.46, 0.2, DARK, Color(0.85, 0.7, 0.25), true)
	_wheel(Vector3(-0.78, 0.46, 1.0), 0.46, 0.22, DARK, Color(0.85, 0.7, 0.25), false)
	_wheel(Vector3(0.78, 0.46, 1.0), 0.46, 0.22, DARK, Color(0.85, 0.7, 0.25), false)
	for sx: float in [-0.78, 0.78]: # faixa branca nos pneus (anel nas laterais dos pneus)
		for sz: float in [-0.95, 1.0]:
			for side: float in [-1.0, 1.0]:
				var ring: MeshInstance3D = ProcMesh.torus(_body, 0.27, 0.36, Vector3(sx + side * 0.09, 0.46, sz), Color(0.96, 0.96, 0.92), Vector3(0, 0, 90))
				ring.scale = Vector3(1.0, 0.25, 1.0)
	return Vector3(0, 0.9, 0.85)


func _style_broom(navy: Color, purple: Color) -> Vector3:
	_hover = true
	var wood: Color = Color(0.32, 0.2, 0.12)
	ProcMesh.cyl(_body, 0.2, 2.4, Vector3(0, 0.6, -0.1), wood, Vector3(90, 0, 0), -1.0, 0.9)
	ProcMesh.sphere(_body, 0.2, Vector3(0, 0.6, -1.3), wood.lightened(0.1))
	ProcMesh.cyl(_body, 0.5, 1.0, Vector3(0, 0.6, 1.6), Color(0.72, 0.55, 0.25), Vector3(-90, 0, 0), 0.15, 1.0)  # cerdas
	ProcMesh.cyl(_body, 0.22, 0.25, Vector3(0, 0.6, 1.0), Color(0.55, 0.4, 0.2), Vector3(90, 0, 0), -1.0, 1.0)    # amarra
	ProcMesh.rbox(_body, Vector3(0.8, 0.1, 0.8), Vector3(0, 0.82, 0.3), Color(0.25, 0.15, 0.1))                     # plataforma
	ProcMesh.rbox(_body, Vector3(0.7, 0.8, 0.1), Vector3(0, 1.3, 0.75), navy.darkened(0.2))                         # encosto da cadeira
	ProcMesh.rbox(_body, Vector3(0.25, 0.25, 0.04), Vector3(0.15, 1.35, 0.69), Color(0.7, 0.55, 0.3))               # remendo
	ProcMesh.rbox(_body, Vector3(0.7, 0.1, 0.65), Vector3(0, 0.95, 0.3), navy.darkened(0.2))                        # assento
	for sx: float in [-0.35, 0.35]:
		ProcMesh.rbox(_body, Vector3(0.06, 0.8, 0.06), Vector3(sx, 1.3, 0.75), wood)
	# caldeirão roxo borbulhante
	ProcMesh.sphere(_body, 0.45, Vector3(0, 1.15, 1.2), Color(0.18, 0.2, 0.25), Vector3(1, 0.85, 1), 0.4)
	ProcMesh.cyl(_body, 0.34, 0.05, Vector3(0, 1.5, 1.2), purple.lightened(0.3), Vector3.ZERO, -1.0, 0.2, 0.0, 2.0)
	# cristais roxos brilhantes
	for sx: float in [-0.3, 0.3]:
		ProcMesh.rbox(_body, Vector3(0.18, 0.18, 0.7), Vector3(sx, 0.4, -0.7), purple, Vector3(10, sx * 40.0, 0), 0.2, 0.0, 2.5)
	# lanternas penduradas
	for sx: float in [-0.45, 0.45]:
		ProcMesh.cyl(_body, 0.01, 0.35, Vector3(sx, 0.4, -0.35), METAL)
		ProcMesh.sphere(_body, 0.12, Vector3(sx, 0.18, -0.35), Color(1.0, 0.85, 0.4), Vector3(1, 1.3, 1), 0.2, 2.0)
	_exhaust_pos = Vector3(0, 0.6, 2.0)
	return Vector3(0, 0.95, 0.3)


# ===================================================================== rig (volante/guidão e pés)

## Onde ficam as mãos e os pés de cada estilo de kart (coordenadas do kart; frente = -Z).
##  ctrl: "wheel" (volante redondo), "bar" (guidão), "lever" (alavanca da vassoura)
##  grip: centro das mãos; gw: meia distância entre as mãos; anchor: base da coluna de direção
##  feet: centro dos pés (y = altura do piso/apoio); feet_x: afastamento lateral dos pés
func _rig(style: String, seat: Vector3) -> Dictionary:
	var r: Dictionary = {"seat": seat, "ctrl": "wheel", "gw": 0.17, "feet_x": 0.15,
		"grip": seat + Vector3(0, 0.46, -0.5), "anchor": seat + Vector3(0, 0.15, -0.85),
		"feet": seat + Vector3(0, -0.4, -0.5)}
	match style:
		"barrel":
			r["anchor"] = Vector3(0, 1.0, -0.85)
			r["feet"] = Vector3(0, 0.35, -0.6) # dentro do barril
		"plank":
			r["ctrl"] = "bar"
			r["gw"] = 0.3
			r["grip"] = seat + Vector3(0, 0.38, -0.5)
			r["anchor"] = Vector3(0, 0.42, -0.6)
			r["feet"] = Vector3(0, 0.42, -0.25) # pés na prancha
		"trike":
			r["ctrl"] = "bar"
			r["gw"] = 0.32
			r["grip"] = seat + Vector3(0, 0.55, -0.5)
			r["anchor"] = Vector3(0, 1.0, -0.95)
			r["feet"] = Vector3(0, 0.58, -0.45)
			r["feet_x"] = 0.22
		"armored":
			r["grip"] = seat + Vector3(0, 0.45, -0.5)
			r["anchor"] = Vector3(0, 1.2, -0.8)
			r["feet"] = Vector3(0, 0.6, -0.55)
		"pinkcar":
			r["ctrl"] = "bar"
			r["gw"] = 0.28
			r["grip"] = seat + Vector3(0, 0.45, -0.5)
			r["anchor"] = Vector3(0, 0.78, -0.6)
			r["feet"] = Vector3(0, 0.8, -0.35)
		"crate", "mail":
			r["ctrl"] = "bar"
			r["gw"] = 0.32
			r["grip"] = seat + Vector3(0, 0.4, -0.5)
			r["anchor"] = Vector3(0, 1.05, -0.85)
			r["feet"] = Vector3(0, 0.62, -0.35)
			r["feet_x"] = 0.24
		"teacup":
			r["gw"] = 0.16
			r["grip"] = seat + Vector3(0, 0.45, -0.45)
			r["anchor"] = Vector3(0, 0.95, -0.55)
			r["feet"] = Vector3(0, 0.45, -0.45)
		"vintage":
			r["grip"] = seat + Vector3(0, 0.45, -0.5)
			r["anchor"] = Vector3(0, 1.05, 0.1)
			r["feet"] = Vector3(0, 0.45, 0.3)
		"broom":
			r["ctrl"] = "lever"
			r["gw"] = 0.18
			r["grip"] = seat + Vector3(0, 0.42, -0.5)
			r["anchor"] = Vector3(0, 0.78, -0.65)
			r["feet"] = Vector3(0, 0.5, -0.2) # pés para FORA da vassoura, nos apoios
			r["feet_x"] = 0.34
	return r


## Volante / guidão / alavanca na frente do piloto, preso ao kart por uma coluna.
func _build_controls(rig: Dictionary, id: String) -> void:
	var grip: Vector3 = rig["grip"]
	var anchor: Vector3 = rig["anchor"]
	var gw: float = rig["gw"]
	match str(rig["ctrl"]):
		"wheel":
			_limb(_body, anchor, grip + Vector3(0, -0.02, 0.06), 0.035, DARK)
			ProcMesh.torus(_body, 0.165, 0.215, grip, DARK, Vector3(60, 0, 0))
			ProcMesh.rbox(_body, Vector3(0.36, 0.035, 0.04), grip, METAL, Vector3(60, 0, 0), 0.4, 0.6)
			ProcMesh.sphere(_body, 0.05, grip, METAL)
		"bar":
			_limb(_body, anchor, grip, 0.04, METAL)
			ProcMesh.cyl(_body, 0.03, gw * 2.0 + 0.3, grip, METAL, Vector3(0, 0, 90), -1.0, 0.3, 0.8)
			for sx: float in [-1.0, 1.0]:
				ProcMesh.cyl(_body, 0.045, 0.14, grip + Vector3(sx * (gw + 0.06), 0, 0), Color(0.1, 0.1, 0.1), Vector3(0, 0, 90))
			if id == "quico": # buzina de corneta
				ProcMesh.cyl(_body, 0.03, 0.28, grip + Vector3(-gw - 0.12, 0.1, -0.05), Color(0.8, 0.82, 0.85), Vector3(0, 0, 0), 0.11, 0.2, 0.9)
				ProcMesh.sphere(_body, 0.08, grip + Vector3(gw + 0.2, 0, 0), Color.BLACK)
			if id == "popis": # fitinhas no guidão
				for sx: float in [-1.0, 1.0]:
					ProcMesh.rbox(_body, Vector3(0.03, 0.3, 0.06), grip + Vector3(sx * (gw + 0.16), -0.15, 0), Color(0.95, 0.4, 0.75) if sx < 0.0 else Color(0.5, 0.8, 0.95))
		"lever":
			_limb(_body, anchor, grip, 0.045, Color(0.4, 0.26, 0.15))
			ProcMesh.cyl(_body, 0.035, gw * 2.0 + 0.2, grip, Color(0.45, 0.3, 0.18), Vector3(0, 0, 90))
			# apoios dos pés dos dois lados da vassoura
			var feet: Vector3 = rig["feet"]
			var fx: float = rig["feet_x"]
			for sx: float in [-1.0, 1.0]:
				ProcMesh.rbox(_body, Vector3(0.26, 0.04, 0.34), Vector3(sx * fx, feet.y - 0.02, feet.z), METAL, Vector3.ZERO, 0.4, 0.7)
				_limb(_body, Vector3(sx * fx * 0.55, 0.62, feet.z), Vector3(sx * fx, feet.y - 0.02, feet.z), 0.025, METAL)


## Cilindro de pontas arredondadas (cápsula) ligando os pontos a e b. Usado em braços, pernas e colunas.
func _limb(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var dvec: Vector3 = b - a
	var length: float = dvec.length()
	if length < 0.001:
		return
	var y: Vector3 = dvec / length
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = length + radius * 2.0
	m.radial_segments = 12
	m.rings = 3
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = ProcMesh.mat(color)
	mi.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
	parent.add_child(mi)


# ===================================================================== piloto

func _build_driver(id: String, rig: Dictionary) -> void:
	var seat: Vector3 = rig["seat"]
	var d := Node3D.new()
	d.name = "Driver"
	d.position = seat
	_body.add_child(d)
	var shirt: Color = Color(0.9, 0.9, 0.9)
	var hair: Color = Color(0.25, 0.15, 0.1)
	match id:
		"chaves": shirt = Color(0.92, 0.92, 0.88)
		"chiquinha": shirt = Color(0.85, 0.12, 0.12)
		"quico": shirt = Color(0.08, 0.08, 0.1)
		"nhonho": shirt = Color(0.85, 0.25, 0.2)
		"popis": shirt = Color(1.0, 0.55, 0.75)
		"madruga": shirt = Color(0.1, 0.1, 0.12)
		"jaiminho": shirt = Color(0.28, 0.38, 0.6)
		"florinda": shirt = Color(0.9, 0.5, 0.55)
		"girafales": shirt = Color(0.28, 0.18, 0.12)
		"barriga": shirt = Color(0.45, 0.28, 0.14)
		"bruxa": shirt = Color(0.2, 0.32, 0.58)
	if id in ["jaiminho", "girafales", "bruxa"]:
		hair = Color(0.7, 0.7, 0.72)
	if id in ["nhonho", "barriga"]:
		hair = Color(0.08, 0.06, 0.05)
	var big: float = 1.15 if (id == "nhonho" or id == "barriga") else 1.0
	# corpo
	ProcMesh.rbox(d, Vector3(0.55 * big, 0.55, 0.38 * big), Vector3(0, 0.3, 0), shirt)
	if id == "nhonho": # camiseta listrada
		var stripes: Array[Color] = [Color(0.95, 0.8, 0.15), Color(0.2, 0.7, 0.3), Color(0.25, 0.5, 0.9)]
		for i in 3:
			ProcMesh.rbox(d, Vector3(0.6 * big, 0.08, 0.42 * big), Vector3(0, 0.15 + 0.14 * float(i), 0), stripes[i])
	if id == "girafales" or id == "barriga":
		ProcMesh.rbox(d, Vector3(0.1, 0.35, 0.05), Vector3(0, 0.38, -0.2), Color(0.8, 0.1, 0.12) if id == "girafales" else Color(0.1, 0.1, 0.1)) # gravata
	# cabeça
	ProcMesh.sphere(d, 0.27 * big, Vector3(0, 0.82, 0), SKIN)
	ProcMesh.sphere(d, 0.285 * big, Vector3(0, 0.87, 0.05), hair, Vector3(1, 0.95, 0.95))
	for sx: float in [-0.1, 0.1]:
		ProcMesh.sphere(d, 0.055, Vector3(sx, 0.85, -0.25 * big), Color.WHITE)
		ProcMesh.sphere(d, 0.03, Vector3(sx, 0.85, -0.295 * big), Color.BLACK)
	ProcMesh.sphere(d, 0.05, Vector3(0, 0.78, -0.28 * big), Color(0.95, 0.65, 0.5)) # nariz
	_build_limbs(d, id, rig, shirt, big)
	# acessórios por personagem
	match id:
		"chaves":
			var green: Color = Color(0.3, 0.6, 0.25)
			ProcMesh.rbox(d, Vector3(0.62, 0.2, 0.6), Vector3(0, 1.07, 0.0), green)
			ProcMesh.rbox(d, Vector3(0.5, 0.05, 0.25), Vector3(0, 1.0, -0.38), green.darkened(0.2))
			for sx: float in [-0.32, 0.32]:
				ProcMesh.rbox(d, Vector3(0.08, 0.34, 0.42), Vector3(sx, 0.85, 0.0), green)
			ProcMesh.rbox(d, Vector3(0.12, 0.45, 0.04), Vector3(-0.2, 0.3, -0.2), Color(0.9, 0.55, 0.15)) # suspensório
			ProcMesh.rbox(d, Vector3(0.12, 0.45, 0.04), Vector3(0.2, 0.3, -0.2), Color(0.9, 0.55, 0.15))
		"chiquinha":
			ProcMesh.sphere(d, 0.13, Vector3(-0.36, 0.98, 0.05), hair)
			ProcMesh.sphere(d, 0.13, Vector3(0.36, 0.98, 0.05), hair)
			ProcMesh.sphere(d, 0.05, Vector3(-0.3, 0.98, 0.05), Color(0.95, 0.85, 0.2))
			ProcMesh.sphere(d, 0.05, Vector3(0.3, 0.98, 0.05), Color(0.95, 0.85, 0.2))
			for sx: float in [-0.12, 0.12]:
				ProcMesh.torus(d, 0.075, 0.115, Vector3(sx, 0.86, -0.27), Color.BLACK, Vector3(90, 0, 0))
		"quico":
			ProcMesh.sphere(d, 0.3, Vector3(0, 1.0, 0.0), Color(0.2, 0.35, 0.8), Vector3(1, 0.7, 1))
			ProcMesh.rbox(d, Vector3(0.18, 0.2, 0.55), Vector3(0, 1.08, 0.0), Color(0.95, 0.8, 0.15))
			ProcMesh.rbox(d, Vector3(0.18, 0.18, 0.5), Vector3(-0.2, 1.05, 0.0), Color(0.85, 0.15, 0.15))
			_prop = Node3D.new()
			_prop.position = Vector3(0, 1.33, 0.0)
			d.add_child(_prop)
			ProcMesh.cyl(d, 0.015, 0.1, Vector3(0, 1.26, 0.0), Color.BLACK)
			ProcMesh.rbox(_prop, Vector3(0.8, 0.02, 0.09), Vector3.ZERO, Color(0.2, 0.4, 0.85))
			ProcMesh.rbox(d, Vector3(0.34, 0.07, 0.05), Vector3(0, 0.62, -0.2), Color(0.85, 0.12, 0.15)) # lenço
		"nhonho":
			pass
		"popis":
			ProcMesh.sphere(d, 0.13, Vector3(-0.15, 1.12, 0.0), Color(1.0, 0.45, 0.7), Vector3(1.3, 1, 0.6))
			ProcMesh.sphere(d, 0.13, Vector3(0.15, 1.12, 0.0), Color(1.0, 0.45, 0.7), Vector3(1.3, 1, 0.6))
			ProcMesh.sphere(d, 0.07, Vector3(0, 1.12, 0.0), Color(0.95, 0.3, 0.55))
		"madruga":
			ProcMesh.cyl(d, 0.3, 0.22, Vector3(0, 1.08, 0.0), Color(0.45, 0.62, 0.85), Vector3.ZERO, 0.26)
			ProcMesh.cyl(d, 0.44, 0.04, Vector3(0, 0.98, 0.0), Color(0.4, 0.57, 0.8))
			ProcMesh.rbox(d, Vector3(0.3, 0.06, 0.05), Vector3(0, 0.72, -0.27), Color(0.1, 0.07, 0.05)) # bigode
		"jaiminho":
			ProcMesh.cyl(d, 0.3, 0.2, Vector3(0, 1.06, 0.0), Color(0.28, 0.38, 0.58), Vector3.ZERO, 0.28)
			ProcMesh.rbox(d, Vector3(0.45, 0.05, 0.25), Vector3(0, 0.99, -0.34), Color(0.15, 0.2, 0.3))
			ProcMesh.rbox(d, Vector3(0.3, 0.06, 0.05), Vector3(0, 0.72, -0.27), Color(0.75, 0.75, 0.78))
			ProcMesh.rbox(d, Vector3(0.45, 0.4, 0.18), Vector3(0.38, 0.2, 0.15), Color(0.5, 0.32, 0.18)) # bolsa de cartas
			ProcMesh.rbox(d, Vector3(0.3, 0.12, 0.05), Vector3(0.38, 0.45, 0.06), Color(0.95, 0.92, 0.8))
		"florinda":
			var cols: Array[Color] = [Color(0.95, 0.4, 0.65), Color(0.95, 0.85, 0.3)]
			for i in 7:
				var ang: float = TAU * float(i) / 7.0
				ProcMesh.cyl(d, 0.075, 0.2, Vector3(sin(ang) * 0.27, 1.02, cos(ang) * 0.24), cols[i % 2], Vector3(0, 0, 90) if i % 2 == 0 else Vector3(90, 0, 0))
			ProcMesh.rbox(d, Vector3(0.6, 0.35, 0.05), Vector3(0, 0.28, -0.2), Color(0.95, 0.9, 0.8)) # avental
		"girafales":
			ProcMesh.cyl(d, 0.44, 0.04, Vector3(0, 0.99, 0.0), Color(0.35, 0.22, 0.14))
			ProcMesh.cyl(d, 0.26, 0.26, Vector3(0, 1.12, 0.0), Color(0.35, 0.22, 0.14))
			ProcMesh.cyl(d, 0.025, 0.28, Vector3(0.06, 0.7, -0.36), Color(0.45, 0.28, 0.14), Vector3(90, 0, 0)) # charuto
			ProcMesh.sphere(d, 0.03, Vector3(0.06, 0.7, -0.5), Color(1.0, 0.5, 0.1), Vector3.ONE, 0.5, 2.0)
			ProcMesh.rbox(d, Vector3(0.3, 0.06, 0.05), Vector3(0, 0.74, -0.27), Color(0.6, 0.6, 0.62))
		"barriga":
			ProcMesh.rbox(d, Vector3(0.32, 0.06, 0.05), Vector3(0, 0.72, -0.31), Color(0.1, 0.07, 0.05))
			for sx: float in [-0.12, 0.12]:
				ProcMesh.torus(d, 0.07, 0.11, Vector3(sx, 0.87, -0.31), Color.BLACK, Vector3(90, 0, 0))
		"bruxa":
			ProcMesh.cyl(d, 0.58, 0.04, Vector3(0, 0.99, 0.0), Color(0.18, 0.3, 0.55))
			ProcMesh.cyl(d, 0.32, 0.65, Vector3(0, 1.32, 0.0), Color(0.18, 0.3, 0.55), Vector3.ZERO, 0.05)
			ProcMesh.cyl(d, 0.34, 0.1, Vector3(0, 1.08, 0.0), Color(0.45, 0.25, 0.6))
			ProcMesh.cyl(d, 0.06, 0.28, Vector3(0, 0.74, -0.38), SKIN, Vector3(-90, 0, 0), 0.01) # nariz de bruxa
			ProcMesh.sphere(d, 0.2, Vector3(0.1, 1.0, 0.45), Color(0.05, 0.05, 0.07), Vector3(1, 0.8, 1.3)) # gato preto
			for sx: float in [0.02, 0.18]:
				ProcMesh.cyl(d, 0.05, 0.1, Vector3(sx, 1.2, 0.4), Color(0.05, 0.05, 0.07), Vector3.ZERO, 0.0)
				ProcMesh.sphere(d, 0.025, Vector3(sx, 1.08, 0.27), Color(0.95, 0.85, 0.2), Vector3.ONE, 0.2, 1.5)


## Braços até as mãos no volante/guidão e pernas sentadas até o piso, com as roupas de cada personagem.
func _build_limbs(d: Node3D, id: String, rig: Dictionary, shirt: Color, big: float) -> void:
	var seat: Vector3 = rig["seat"]
	var grip: Vector3 = (rig["grip"] as Vector3) - seat     # em coordenadas do piloto
	var feet: Vector3 = (rig["feet"] as Vector3) - seat
	var gw: float = rig["gw"]
	var fx: float = rig["feet_x"]
	var pants: Color = Color(0.25, 0.2, 0.15)
	var shin: Color = pants
	var shoe: Color = Color(0.1, 0.08, 0.07)
	var skirt: Color = Color(0, 0, 0, 0)
	var bare_forearm: bool = false
	match id:
		"chaves":
			pants = Color(0.5, 0.33, 0.2)
			shin = pants
			shoe = Color(0.35, 0.22, 0.12)
			bare_forearm = true
		"chiquinha":
			pants = SKIN
			shin = Color(0.96, 0.96, 0.96)
			skirt = Color(0.2, 0.6, 0.3)
		"quico":
			pants = Color(0.08, 0.08, 0.1)
			shin = Color(0.96, 0.96, 0.96)
		"nhonho":
			pants = Color(0.12, 0.12, 0.14)
			shin = Color(0.96, 0.96, 0.96)
			bare_forearm = true
		"popis":
			pants = SKIN
			shin = Color(0.96, 0.96, 0.96)
			skirt = Color(1.0, 0.65, 0.82)
		"madruga":
			pants = Color(0.3, 0.42, 0.6)
			shin = pants
			shoe = Color(0.55, 0.5, 0.4)
			bare_forearm = true
		"jaiminho":
			pants = Color(0.28, 0.36, 0.55)
			shin = pants
		"florinda":
			pants = SKIN
			shin = SKIN
			skirt = Color(0.9, 0.5, 0.55)
		"girafales":
			pants = Color(0.25, 0.16, 0.1)
			shin = pants
		"barriga":
			pants = Color(0.42, 0.26, 0.13)
			shin = pants
			shoe = Color(0.3, 0.17, 0.08)
		"bruxa":
			pants = Color(0.2, 0.32, 0.58) # vestido comprido
			shin = Color(0.08, 0.08, 0.1)  # botas
	# quadril
	ProcMesh.rbox(d, Vector3(0.5 * big, 0.2, 0.42 * big), Vector3(0, 0.02, 0.02), pants)
	if skirt.a > 0.0:
		ProcMesh.cyl(d, 0.36 * big, 0.26, Vector3(0, 0.02, -0.04), skirt, Vector3.ZERO, 0.27 * big)
	# pernas: coxa para a frente, canela até o pé no piso
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * 0.13 * big, 0.02, -0.05)
		var foot := Vector3(side * fx, feet.y + 0.07, feet.z)
		var knee := Vector3(side * lerpf(0.14 * big, fx, 0.5), maxf(foot.y + 0.3, 0.05), lerpf(-0.05, foot.z, 0.75))
		_limb(d, hip, knee, 0.085 * big, pants)
		_limb(d, knee, foot, 0.068 * big, shin)
		ProcMesh.rbox(d, Vector3(0.15, 0.11, 0.26), foot + Vector3(0, -0.02, -0.06), shoe)
	# braços: ombro -> cotovelo -> mão no volante/guidão
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * 0.31 * big, 0.48, -0.02)
		var hand := Vector3(grip.x + side * gw, grip.y, grip.z + 0.03)
		var elbow: Vector3 = shoulder.lerp(hand, 0.5) + Vector3(side * 0.09, -0.1, 0.04)
		_limb(d, shoulder, elbow, 0.07 * big, shirt)
		_limb(d, elbow, hand, 0.06 * big, SKIN if bare_forearm else shirt)
		ProcMesh.sphere(d, 0.075, hand, SKIN)


# ===================================================================== efeitos

func _make_particles(color: Color, amount: int, lifetime: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.emitting = false
	p.local_coords = false
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 2.0
	m.radial_segments = 6
	m.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material = material
	p.mesh = m
	p.color = color
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	return p


func _build_fx() -> void:
	_smoke = _make_particles(Color(0.45, 0.45, 0.47, 0.5), 22, 0.7, 0.14)
	_smoke.position = _exhaust_pos
	_smoke.direction = Vector3(0, 0.6, 1.0)
	_smoke.spread = 25.0
	_smoke.initial_velocity_min = 1.5
	_smoke.initial_velocity_max = 3.0
	_smoke.gravity = Vector3(0, 1.2, 0)
	_body.add_child(_smoke)
	_sparks = _make_particles(Color(1.0, 0.95, 0.6), 30, 0.4, 0.07)
	_sparks.position = Vector3(0, 0.2, 1.0)
	_sparks.direction = Vector3(0, 1.0, 0.8)
	_sparks.spread = 50.0
	_sparks.initial_velocity_min = 2.0
	_sparks.initial_velocity_max = 5.0
	_sparks.gravity = Vector3(0, -9.0, 0)
	_body.add_child(_sparks)
