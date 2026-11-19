class_name LapManager
extends Node
## Máquina de estados da corrida: contagem regressiva, cronômetro, voltas, ranking e resultados.

signal countdown_tick(value: int) # 3, 2, 1, 0 (0 = VAI!)
signal race_started
signal lap_completed(kart: KartController, lap: int, lap_time: float)
signal final_lap(kart: KartController)
signal kart_finished(kart: KartController, place: int, time: float)
signal race_finished(results: Array)

const FINISH_GRACE_TIME: float = 4.0 # tempo extra depois do jogador cruzar a chegada

var total_laps: int = 3
var karts: Array[KartController] = []
var checkpoints: CheckpointSystem
var path: TrackPath
var race_time: float = 0.0
var running: bool = false
var is_over: bool = false
var finished_order: Array[KartController] = []
var _lap_start: Dictionary = {}


func setup(ks: Array[KartController], cps: CheckpointSystem, laps: int, p: TrackPath) -> void:
	karts = ks
	checkpoints = cps
	total_laps = laps
	path = p
	for k in karts:
		_lap_start[k] = 0.0
	checkpoints.lap_crossed.connect(_on_lap_crossed)


func start_countdown() -> void:
	for v in [3, 2, 1]:
		countdown_tick.emit(v)
		await get_tree().create_timer(1.0).timeout
	countdown_tick.emit(0)
	_go()


func _go() -> void:
	running = true
	for k in karts:
		k.controls_locked = false
	race_started.emit()


func _physics_process(delta: float) -> void:
	if is_over:
		return
	if running:
		race_time += delta
	_update_ranking() # antes da largada, o ranking segue a ordem do grid


func _update_ranking() -> void:
	var active: Array[KartController] = []
	for k in karts:
		if not k.finished:
			active.append(k)
	active.sort_custom(func(a: KartController, b: KartController) -> bool:
		return a.race_progress > b.race_progress)
	var place: int = finished_order.size() + 1
	for k in active:
		k.place = place
		place += 1


func _on_lap_crossed(kart: KartController, laps_done: int) -> void:
	if kart.finished:
		return
	var lap_time: float = race_time - float(_lap_start[kart])
	_lap_start[kart] = race_time
	kart.best_lap = minf(kart.best_lap, lap_time)
	lap_completed.emit(kart, laps_done, lap_time)
	if laps_done >= total_laps:
		_finish_kart(kart)
	elif laps_done == total_laps - 1:
		final_lap.emit(kart)
	if kart.is_player and laps_done < total_laps:
		AudioManager.play_sfx("lap")


func _finish_kart(kart: KartController) -> void:
	kart.finished = true
	kart.finish_time = race_time
	finished_order.append(kart)
	kart.place = finished_order.size()
	kart_finished.emit(kart, kart.place, race_time)
	if kart.is_player:
		AudioManager.play_sfx("finish")
		get_tree().create_timer(FINISH_GRACE_TIME).timeout.connect(_end_race)
	if finished_order.size() >= karts.size():
		_end_race()


func _end_race() -> void:
	if is_over:
		return
	is_over = true
	running = false
	# estima o tempo de quem não terminou, pelo progresso restante
	var rest: Array[KartController] = []
	for k in karts:
		if not k.finished:
			rest.append(k)
	rest.sort_custom(func(a: KartController, b: KartController) -> bool:
		return a.race_progress > b.race_progress)
	var results: Array[Dictionary] = []
	for k in finished_order:
		results.append(_entry(k, k.place, k.finish_time))
	var next_place: int = finished_order.size() + 1
	for k in rest:
		var remaining: float = (float(total_laps) - k.race_progress) * path.length
		var est: float = race_time + remaining / maxf(k.stats.max_speed * 0.8, 10.0)
		results.append(_entry(k, next_place, est))
		next_place += 1
	Global.race_results = results
	race_finished.emit(results)


func _entry(k: KartController, place: int, time: float) -> Dictionary:
	return {
		"stats": k.stats,
		"name": k.stats.display_name,
		"place": place,
		"time": time,
		"is_player": k.is_player,
	}
