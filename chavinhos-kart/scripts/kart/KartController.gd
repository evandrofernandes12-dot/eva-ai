class_name KartController
extends CharacterBody3D
## Física arcade de kart (CharacterBody3D): aceleração, curva, drift com mini-turbo, off-road,
## itens e efeitos. As entradas (in_*) vêm do teclado (is_player) ou do KartAI.
## Convenção: a frente do kart é -Z; steer > 0 = direita.

signal item_changed(item: int)
signal item_roll_started
signal boosted(power: float)
signal spun_out
signal drift_started
signal drift_boost_released(level: int)
signal hit_wall(impact: float)
signal bumped

const GRAVITY: float = 30.0
const OFFROAD_FACTOR: float = 0.55
const DRIFT_LEVEL_TIMES: Array[float] = [0.8, 1.7, 2.8]
const DRIFT_BOOST_TIMES: Array[float] = [0.8, 1.3, 1.9]
const KART_RADIUS: float = 1.9

@export var stats: RacerStats
@export var is_player: bool = false

# ---- Entradas (preenchidas pelo jogador ou pela IA)
var in_throttle: float = 0.0
var in_brake: float = 0.0
var in_steer: float = 0.0
var in_drift: bool = false
var controls_locked: bool = true

# ---- Estado de movimento
var speed: float = 0.0
var speed_mult: float = 1.0 # rubber band / habilidade da IA
var boost_timer: float = 0.0
var boost_power: float = 0.0
var spin_timer: float = 0.0
var invuln_timer: float = 0.0
var bump_cooldown: float = 0.0
var offroad: bool = false

# ---- Drift
var drifting: bool = false
var drift_dir: float = 0.0
var drift_time: float = 0.0
var drift_level: int = 0

# ---- Itens
var held_item: int = ItemDefs.Type.NONE
var item_rolling: bool = false
var _roll_timer: float = 0.0

# ---- Corrida
var path: TrackPath
var path_idx: int = -1
var path_dist: float = 0.0
var lateral: float = 0.0
var race_progress: float = -1.0 # em voltas (fração); < 0 = antes da linha de largada
var laps_completed: int = 0
var current_lap: int = 1
var place: int = 1
var finished: bool = false
var finish_time: float = 0.0
var best_lap: float = INF

@onready var visuals: KartVisuals = $Visuals


func _ready() -> void:
	add_to_group("karts")
	collision_layer = 4 # karts
	collision_mask = 3  # mundo + paredes
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(50.0)
	if stats != null and visuals != null:
		visuals.build(stats)


func speed_kmh() -> float:
	return absf(speed) * 3.6


# ===================================================================== entrada

func _gather_input() -> void:
	if not is_player:
		return
	in_throttle = Input.get_action_strength("accelerate")
	in_brake = Input.get_action_strength("brake")
	in_steer = Input.get_axis("steer_left", "steer_right")
	in_drift = Input.is_action_pressed("drift")
	if Input.is_action_just_pressed("use_item"):
		use_item()
	if Input.is_action_just_pressed("reset_kart"):
		reset_to_track()


# ===================================================================== loop principal

func _physics_process(delta: float) -> void:
	if stats == null:
		return
	_gather_input()
	_update_timers(delta)
	_update_track_position()

	var spinning: bool = spin_timer > 0.0
	var can_drive: bool = not controls_locked and not spinning
	var throttle: float = in_throttle if can_drive else 0.0
	var brake: float = in_brake if can_drive else 0.0
	var steer: float = in_steer if can_drive else 0.0
	if finished and is_player:
		throttle = 0.0
		brake = 0.35
		steer = 0.0

	# ---- velocidade máxima atual
	var top: float = stats.max_speed * speed_mult
	if offroad:
		top *= OFFROAD_FACTOR
	if boost_timer > 0.0:
		top += boost_power

	# ---- aceleração / freio
	var accel: float = stats.acceleration * lerpf(1.0, 0.35, clampf(absf(speed) / maxf(top, 1.0), 0.0, 1.0))
	if boost_timer > 0.0:
		accel *= 3.0
	if throttle > 0.0:
		speed = move_toward(speed, top, accel * throttle * delta)
	elif brake > 0.0:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, 38.0 * brake * delta)
		else:
			speed = move_toward(speed, -top * 0.3, accel * brake * delta)
	else:
		speed = move_toward(speed, 0.0, 6.0 * delta)
	if spinning:
		speed = move_toward(speed, 0.0, 16.0 * delta)
	if speed > top:
		speed = move_toward(speed, top, 25.0 * delta)

	# ---- drift
	_update_drift(delta, steer, can_drive)

	# ---- rotação (curva)
	var speed_ratio: float = clampf(absf(speed) / (stats.max_speed * 0.4), 0.0, 1.0)
	var dir_sign: float = 1.0 if speed >= 0.0 else -1.0
	var turn: float
	if drifting:
		var s: float = clampf(drift_dir * 0.9 + steer * 0.7, -1.6, 1.6)
		turn = stats.handling * 0.85 * s * speed_ratio
	else:
		var hi_speed_penalty: float = 1.0 - 0.25 * clampf(speed / maxf(stats.max_speed, 1.0), 0.0, 1.0)
		turn = stats.handling * steer * speed_ratio * dir_sign * hi_speed_penalty
	rotation.y -= turn * delta

	# ---- velocidade horizontal com aderência (derrapagem no drift)
	var fwd: Vector3 = -global_transform.basis.z
	var hv := Vector3(velocity.x, 0.0, velocity.z)
	var target_v: Vector3 = fwd * speed
	var grip: float = 9.0
	if drifting:
		target_v = fwd.rotated(Vector3.UP, drift_dir * 0.45) * speed
		grip = 4.0
	elif spinning:
		grip = 2.0
	elif offroad:
		grip = 6.0
	hv = hv.lerp(target_v, clampf(grip * delta, 0.0, 1.0))
	velocity.x = hv.x
	velocity.z = hv.z
	if is_on_floor() and velocity.y <= 0.0:
		velocity.y = -1.0
	else:
		velocity.y -= GRAVITY * delta

	_separate_from_karts()

	var before: Vector3 = hv
	move_and_slide()
	_handle_collisions(before)

	# ---- visuais e áudio
	if visuals != null:
		visuals.update_visuals(delta, speed, steer, drifting, drift_dir, drift_level,
			boost_timer > 0.0, spinning, offroad, stats.max_speed)
	if is_player:
		AudioManager.set_engine(absf(speed) / (stats.max_speed + 8.0), not controls_locked or speed > 1.0)


func _update_timers(delta: float) -> void:
	if boost_timer > 0.0:
		boost_timer -= delta
		if boost_timer <= 0.0:
			boost_power = 0.0
	if spin_timer > 0.0:
		spin_timer -= delta
	if invuln_timer > 0.0:
		invuln_timer -= delta
	if bump_cooldown > 0.0:
		bump_cooldown -= delta
	if item_rolling:
		_roll_timer -= delta
		if _roll_timer <= 0.0:
			item_rolling = false
			var total: int = get_tree().get_nodes_in_group("karts").size()
			held_item = ItemDefs.roll(place, total)
			item_changed.emit(held_item)


func _update_track_position() -> void:
	if path == null:
		return
	var info: Dictionary = path.locate(global_position, path_idx)
	path_idx = int(info["idx"])
	path_dist = float(info["dist"])
	lateral = float(info["lateral"])
	offroad = absf(lateral) > path.half_width


## Posiciona o kart na pista (busca global). Chamado no spawn.
func refresh_path_position() -> void:
	if path == null:
		return
	path_idx = -1
	_update_track_position()


# ===================================================================== drift

func _update_drift(delta: float, steer: float, can_drive: bool) -> void:
	if not drifting:
		if in_drift and can_drive and absf(steer) > 0.3 and speed > stats.max_speed * 0.5 and is_on_floor():
			drifting = true
			drift_dir = signf(steer)
			drift_time = 0.0
			drift_level = 0
			velocity.y = 4.0 # pulinho de início
			drift_started.emit()
		return
	if not in_drift or speed < stats.max_speed * 0.3 or not can_drive:
		_end_drift()
		return
	drift_time += delta
	var lvl: int = 0
	for i in DRIFT_LEVEL_TIMES.size():
		if drift_time >= DRIFT_LEVEL_TIMES[i]:
			lvl = i + 1
	if lvl > drift_level:
		drift_level = lvl
		if is_player:
			AudioManager.play_sfx("tick", 0.0, 1.0 + 0.2 * float(lvl))


func _end_drift() -> void:
	if not drifting:
		return
	drifting = false
	if drift_level > 0:
		var idx: int = drift_level - 1
		apply_boost(7.0 + 3.0 * float(drift_level), DRIFT_BOOST_TIMES[idx] * stats.drift_boost)
		drift_boost_released.emit(drift_level)
	drift_level = 0
	drift_time = 0.0


# ===================================================================== colisões

func _handle_collisions(before: Vector3) -> void:
	for i in get_slide_collision_count():
		var col: KinematicCollision3D = get_slide_collision(i)
		var n: Vector3 = col.get_normal()
		if n.y < 0.5:
			var impact: float = maxf(0.0, -before.dot(n))
			if impact > 2.0:
				speed *= clampf(1.0 - impact / maxf(absf(speed), 1.0) * 0.8, 0.3, 1.0)
				hit_wall.emit(impact)
				if is_player and impact > 6.0:
					AudioManager.play_sfx("hit", -4.0)


## Colisão suave entre karts (evita travar um no outro): separa e troca um pouco de velocidade.
func _separate_from_karts() -> void:
	for node in get_tree().get_nodes_in_group("karts"):
		var other: KartController = node as KartController
		if other == null or other == self:
			continue
		var d: Vector3 = global_position - other.global_position
		d.y = 0.0
		var dist: float = d.length()
		if dist < KART_RADIUS and dist > 0.001:
			global_position += d / dist * (KART_RADIUS - dist) * 0.5
			if dist < KART_RADIUS * 0.85 and bump_cooldown <= 0.0:
				bump_cooldown = 0.35
				var other_share: float = other.stats.weight / (stats.weight + other.stats.weight)
				speed *= 1.0 - 0.12 * other_share
				bumped.emit()
				if is_player or other.is_player:
					AudioManager.play_sfx("hit", -8.0, 1.4)


# ===================================================================== itens e efeitos

func begin_item_roll() -> void:
	if held_item != ItemDefs.Type.NONE or item_rolling:
		return
	item_rolling = true
	_roll_timer = 1.0
	item_roll_started.emit()


func use_item() -> void:
	if held_item == ItemDefs.Type.NONE or controls_locked or spin_timer > 0.0:
		return
	var it: int = held_item
	held_item = ItemDefs.Type.NONE
	item_changed.emit(ItemDefs.Type.NONE)
	ItemDefs.spawn(self, it)


func apply_boost(power: float, duration: float) -> void:
	boost_power = maxf(boost_power, power)
	boost_timer = maxf(boost_timer, duration)
	speed = maxf(speed, stats.max_speed * 0.6)
	boosted.emit(power)
	if is_player:
		AudioManager.play_sfx("boost")


func spin_out(duration: float = 1.2) -> void:
	if spin_timer > 0.0 or invuln_timer > 0.0 or finished:
		return
	spin_timer = duration
	invuln_timer = duration + 1.2
	drifting = false
	drift_level = 0
	boost_timer = 0.0
	boost_power = 0.0
	speed *= 0.35
	spun_out.emit()
	if is_player:
		AudioManager.play_sfx("spin")


func reset_to_track() -> void:
	if path == null:
		return
	var tangent: Vector3 = path.tangent_at(path_dist)
	var p: Vector3 = path.point_at(path_dist) + Vector3(0.0, 0.3, 0.0)
	global_transform = Transform3D(Basis.looking_at(tangent, Vector3.UP), p)
	velocity = Vector3.ZERO
	speed = 0.0
	drifting = false
	drift_level = 0
	spin_timer = 0.0
	path_idx = -1
	_update_track_position()
