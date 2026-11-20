class_name ItemProjectile
extends ItemBase
## Projétil teleguiado (Chinelo da Dona Florinda / Bola Quadrada): persegue o kart mais próximo à
## frente, some ao bater na parede e faz o alvo rodopiar.

@export var kind: String = "chinelo" # "chinelo" | "bola"
@export var speed: float = 48.0
@export var turn_rate: float = 2.6

var direction: Vector3 = Vector3.FORWARD
var target: KartController
var _mesh_root: Node3D


func _ready() -> void:
	lifetime = 6.0
	arm_time = 0.35
	super._ready()


func _build_visual() -> void:
	_mesh_root = Node3D.new()
	add_child(_mesh_root)
	if kind == "bola":
		# bola "quadrada": cubo com faixas vermelha / amarela / azul
		ProcMesh.box(_mesh_root, Vector3(0.3, 0.9, 0.9), Vector3(-0.3, 0, 0), Color(0.9, 0.2, 0.2), Vector3.ZERO, 0.4)
		ProcMesh.box(_mesh_root, Vector3(0.3, 0.9, 0.9), Vector3(0.0, 0, 0), Color(0.95, 0.8, 0.15), Vector3.ZERO, 0.4)
		ProcMesh.box(_mesh_root, Vector3(0.3, 0.9, 0.9), Vector3(0.3, 0, 0), Color(0.2, 0.4, 0.9), Vector3.ZERO, 0.4)
	else:
		# chinelo: sola + tira
		ProcMesh.cyl(_mesh_root, 0.28, 0.08, Vector3(0, 0, 0), Color(0.2, 0.55, 0.85), Vector3.ZERO, -1.0, 0.8).scale = Vector3(1.0, 1.0, 1.9)
		ProcMesh.box(_mesh_root, Vector3(0.5, 0.06, 0.12), Vector3(0, 0.07, -0.1), Color(0.95, 0.9, 0.9))


func activate(kart: KartController) -> void:
	super.activate(kart)
	var fwd: Vector3 = -kart.global_transform.basis.z
	fwd.y = 0.0
	direction = fwd.normalized()
	global_position = kart.global_position + direction * 2.8 + Vector3(0, 0.7, 0)
	target = _find_target(kart)
	AudioManager.play_sfx("throw", -2.0)


func _find_target(kart: KartController) -> KartController:
	var best: KartController = null
	var best_d: float = 90.0
	var fwd: Vector3 = -kart.global_transform.basis.z
	for node in get_tree().get_nodes_in_group("karts"):
		var other: KartController = node as KartController
		if other == null or other == kart or other.finished or other.eliminated:
			continue
		var ahead: float
		if kart.path == null: # arena: alvo mais próximo dentro do cone frontal
			var to: Vector3 = other.global_position - kart.global_position
			to.y = 0.0
			ahead = to.length() if to.normalized().dot(fwd) > 0.3 else -1.0
		else:
			ahead = kart.path.signed_delta(kart.path_dist, other.path_dist)
		if ahead > 0.0 and ahead < best_d:
			best_d = ahead
			best = other
	return best


func _tick(delta: float) -> void:
	if is_instance_valid(target) and not target.finished and not target.eliminated:
		var to: Vector3 = target.global_position - global_position
		to.y = 0.0
		if to.length() > 0.5:
			var ang: float = direction.signed_angle_to(to.normalized(), Vector3.UP)
			ang = clampf(ang, -turn_rate * delta, turn_rate * delta)
			direction = direction.rotated(Vector3.UP, ang)
	var motion: Vector3 = direction * speed * delta
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position, global_position + motion + direction * 0.8, 2)
	if not space.intersect_ray(query).is_empty():
		_explode()
		return
	global_position += motion
	_mesh_root.rotation.y += delta * 12.0


func _hit_kart(k: KartController) -> void:
	k.spin_out(1.3)
	AudioManager.play_sfx("hit")
	_explode()


func _explode() -> void:
	monitoring = false
	queue_free()
