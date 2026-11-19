class_name FollowCamera
extends Camera3D
## Câmera de perseguição suave: fica atrás do kart, atrasa um pouco nas curvas/drift,
## abre o FOV com a velocidade e treme levemente em batidas.

@export var distance: float = 7.5
@export var height: float = 3.5
@export var look_height: float = 1.2

var target: KartController
var _heading: Vector3 = Vector3.FORWARD
var _shake: float = 0.0


func _ready() -> void:
	target = get_parent() as KartController
	if target == null:
		return
	_heading = -target.global_transform.basis.z
	_heading.y = 0.0
	_heading = _heading.normalized()
	global_position = target.global_position - _heading * distance + Vector3.UP * height
	target.hit_wall.connect(func(impact: float) -> void: _shake = clampf(impact * 0.02, 0.0, 0.5))
	target.bumped.connect(func() -> void: _shake = 0.15)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var fwd: Vector3 = -target.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() > 0.01:
		var rate: float = 3.2 if target.drifting else 6.5
		_heading = _heading.slerp(fwd.normalized(), clampf(delta * rate, 0.0, 1.0)).normalized()
	var dist: float = distance + (0.8 if target.boost_timer > 0.0 else 0.0)
	var desired: Vector3 = target.global_position - _heading * dist + Vector3.UP * height
	global_position = global_position.lerp(desired, clampf(delta * 9.0, 0.0, 1.0))
	var look_at_pos: Vector3 = target.global_position + Vector3.UP * look_height + _heading * 3.0
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		look_at_pos += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake
	look_at(look_at_pos, Vector3.UP)
	var ratio: float = clampf(absf(target.speed) / maxf(target.stats.max_speed, 1.0), 0.0, 1.3)
	var fov_target: float = 68.0 + ratio * 8.0 + (10.0 if target.boost_timer > 0.0 else 0.0)
	fov = lerpf(fov, fov_target, clampf(delta * 4.0, 0.0, 1.0))
