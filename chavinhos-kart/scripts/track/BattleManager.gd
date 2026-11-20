class_name BattleManager
extends Node
## Batalha de Balões: cada kart tem 3 balões; cada rodopio (acerto) estoura um. Vence o último vivo
## ou, ao fim do tempo, quem tiver mais balões.

signal countdown_tick(value: int)
signal battle_started
signal balloon_popped(kart: KartController, remaining: int)
signal kart_eliminated(kart: KartController)
signal battle_finished(results: Array)

const START_BALLOONS: int = 3
const DURATION: float = 120.0

var karts: Array[KartController] = []
var balloons: Dictionary = {}   # kart -> int
var time_left: float = DURATION
var running: bool = false
var is_over: bool = false
var net_client: bool = false    # online: quem decide o resultado é o anfitrião

var _elim_order: Array[KartController] = []
var _elim_time: Dictionary = {}
var _elapsed: float = 0.0
var _visuals: Dictionary = {}   # kart -> Array[Node3D]
var _rank_t: float = 0.0


func setup(ks: Array[KartController]) -> void:
	karts = ks
	for k in karts:
		balloons[k] = START_BALLOONS
		_make_balloons(k)
		k.spun_out.connect(_on_spun.bind(k))
	_update_places()


func start_countdown() -> void:
	for v in [3, 2, 1]:
		countdown_tick.emit(v)
		await get_tree().create_timer(1.0).timeout
	countdown_tick.emit(0)
	running = true
	for k in karts:
		k.controls_locked = false
	battle_started.emit()


func alive_count() -> int:
	var n: int = 0
	for k in karts:
		if not k.eliminated:
			n += 1
	return n


func _make_balloons(k: KartController) -> void:
	var root := Node3D.new()
	root.name = "Balloons"
	k.add_child(root)
	var list: Array[Node3D] = []
	var cols: Array[Color] = [k.stats.body_color.lightened(0.25), k.stats.accent_color, Color(1.0, 0.9, 0.3)]
	for i in START_BALLOONS:
		var b := Node3D.new()
		b.position = Vector3((float(i) - 1.0) * 0.75, 3.1 + (0.25 if i == 1 else 0.0), 0.2)
		root.add_child(b)
		ProcMesh.sphere(b, 0.34, Vector3.ZERO, cols[i], Vector3(1, 1.25, 1), 0.25)
		ProcMesh.cyl(b, 0.012, 1.3, Vector3(0, -0.95, 0), Color(0.9, 0.9, 0.9))
		list.append(b)
	_visuals[k] = list


func _on_spun(k: KartController) -> void:
	if not running or is_over or k.eliminated:
		return
	balloons[k] = int(balloons[k]) - 1
	var list: Array = _visuals[k]
	var idx: int = int(balloons[k])
	if idx >= 0 and idx < list.size():
		(list[idx] as Node3D).visible = false
	balloon_popped.emit(k, int(balloons[k]))
	if k.is_player:
		AudioManager.play_sfx("hit")
	if int(balloons[k]) <= 0:
		k.eliminated = true
		k.visible = false
		k.collision_layer = 0
		_elim_order.append(k)
		_elim_time[k] = _elapsed
		kart_eliminated.emit(k)
	_update_places()
	if alive_count() <= 1:
		_finish()


func _physics_process(delta: float) -> void:
	if not running or is_over:
		return
	_elapsed += delta
	time_left -= delta
	_rank_t -= delta
	if _rank_t <= 0.0:
		_rank_t = 0.25
		_update_places()
	if time_left <= 0.0:
		time_left = 0.0
		_finish()


func _ranking() -> Array[KartController]:
	var alive: Array[KartController] = []
	for k in karts:
		if not k.eliminated:
			alive.append(k)
	alive.sort_custom(func(a: KartController, b: KartController) -> bool:
		return int(balloons[a]) > int(balloons[b]))
	var out: Array[KartController] = []
	out.append_array(alive)
	for i in range(_elim_order.size() - 1, -1, -1): # quem caiu por último fica melhor
		out.append(_elim_order[i])
	return out


func _update_places() -> void:
	var order: Array[KartController] = _ranking()
	for i in order.size():
		order[i].place = i + 1


func _finish() -> void:
	if is_over:
		return
	is_over = true
	running = false
	_update_places()
	var results: Array[Dictionary] = []
	for k in _ranking():
		var bal: int = int(balloons[k])
		results.append({
			"slot": k.net_slot, "stats": k.stats, "name": k.stats.display_name, "place": k.place,
			"time": float(_elim_time.get(k, _elapsed)), "is_player": k.is_player,
			"score_text": "%d balão(ões)" % bal if bal > 0 else "eliminado",
		})
	Global.race_results = results
	battle_finished.emit(results)
