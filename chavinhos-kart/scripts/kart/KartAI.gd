class_name KartAI
extends Node
## Piloto automático: segue a linha central com faixa (lane) própria, freia em curvas fechadas,
## desvia de karts à frente, destrava quando preso e usa itens depois de um atraso aleatório.

var kart: KartController
var lane_offset: float = 0.0
var _avoid: float = 0.0
var _wobble: float = 0.0
var _item_delay: float = 2.0
var _item_timer: float = 0.0
var _stuck_timer: float = 0.0
var _time: float = 0.0
var battle_mode: bool = false


func _ready() -> void:
	kart = get_parent() as KartController
	lane_offset = randf_range(-4.5, 4.5)
	_wobble = randf() * 10.0
	_item_delay = randf_range(1.5, 4.5)


func _physics_process(delta: float) -> void:
	if kart == null or kart.stats == null or kart.is_remote or not kart.is_multiplayer_authority():
		return
	if kart.eliminated:
		return
	_time += delta
	if battle_mode:
		_battle_step(delta)
		_handle_stuck(delta)
		_handle_items(delta)
		return
	if kart.path == null:
		return
	var path: TrackPath = kart.path
	var speed_abs: float = absf(kart.speed)

	# ---- alvo à frente na pista
	var look: float = 12.0 + speed_abs * 0.55
	var target_d: float = kart.path_dist + look
	var max_lane: float = path.half_width - 2.5
	var lane: float = clampf(lane_offset + sin(_time * 0.45 + _wobble) * 1.8 + _avoid, -max_lane, max_lane)
	var target: Vector3 = path.point_at(target_d) + path.right_at(target_d) * lane
	var to: Vector3 = target - kart.global_position
	to.y = 0.0
	var basis: Basis = kart.global_transform.basis
	var ang: float = atan2(to.dot(basis.x), to.dot(-basis.z))
	kart.in_steer = clampf(ang * 1.8, -1.0, 1.0)

	# ---- acelerador / freio conforme a curva adiante
	var curve: float = path.turn_angle(kart.path_dist + 8.0, 28.0)
	var too_fast: bool = speed_abs > kart.stats.max_speed * (0.95 - curve * 0.6)
	if curve > 0.45 and too_fast:
		kart.in_throttle = 0.0
		kart.in_brake = clampf((curve - 0.35) * 1.2, 0.2, 0.7)
	else:
		kart.in_throttle = 1.0
		kart.in_brake = 0.0
	if kart.finished:
		kart.in_throttle = 0.7
	kart.in_drift = false

	_avoid_karts(delta)
	_handle_stuck(delta)
	_handle_items(delta)


## Batalha: persegue o rival mais próximo, evita o chafariz central e as paredes.
func _battle_step(_delta: float) -> void:
	var pos: Vector3 = kart.global_position
	pos.y = 0.0
	var target: KartController = _nearest_rival()
	var aim: Vector3 = -pos
	if target != null and pos.length() < 62.0:
		aim = target.global_position - pos
	if pos.length() < 15.0:
		aim = pos # perto do chafariz: afasta
	aim.y = 0.0
	var b: Basis = kart.global_transform.basis
	var ang: float = atan2(aim.dot(b.x), aim.dot(-b.z))
	kart.in_steer = clampf(ang * 1.8, -1.0, 1.0)
	kart.in_throttle = 1.0
	kart.in_brake = 0.0
	kart.in_drift = false


func _nearest_rival() -> KartController:
	var best: KartController = null
	var best_d: float = INF
	for node in get_tree().get_nodes_in_group("karts"):
		var other: KartController = node as KartController
		if other == null or other == kart or other.eliminated:
			continue
		var d: float = kart.global_position.distance_to(other.global_position)
		if d < best_d:
			best_d = d
			best = other
	return best


func _avoid_karts(delta: float) -> void:
	var push: float = 0.0
	for node in get_tree().get_nodes_in_group("karts"):
		var other: KartController = node as KartController
		if other == null or other == kart:
			continue
		var ahead: float = kart.path.signed_delta(kart.path_dist, other.path_dist)
		if ahead > 0.0 and ahead < 14.0 and absf(other.lateral - kart.lateral) < 2.6:
			var side: float = signf(kart.lateral - other.lateral)
			if side == 0.0:
				side = 1.0 if randf() > 0.5 else -1.0
			push += side * 3.5
	_avoid = lerpf(_avoid, clampf(push, -4.0, 4.0), clampf(delta * 3.0, 0.0, 1.0))


func _handle_stuck(delta: float) -> void:
	if kart.controls_locked or kart.finished:
		_stuck_timer = 0.0
		return
	if absf(kart.speed) < 1.5 and kart.spin_timer <= 0.0:
		_stuck_timer += delta
		if _stuck_timer > 2.5:
			kart.reset_to_track()
			_stuck_timer = 0.0
	else:
		_stuck_timer = 0.0


func _handle_items(delta: float) -> void:
	if kart.held_item == ItemDefs.Type.NONE or kart.controls_locked or kart.finished:
		_item_timer = 0.0
		return
	_item_timer += delta
	if _item_timer >= _item_delay:
		if battle_mode and (kart.held_item == ItemDefs.Type.BOLA_QUADRADA or kart.held_item == ItemDefs.Type.CHINELO):
			var rival: KartController = _nearest_rival()
			if rival == null or kart.global_position.distance_to(rival.global_position) > 55.0:
				return
		_item_timer = 0.0
		_item_delay = randf_range(1.5, 5.0)
		kart.use_item()
