class_name CheckpointSystem
extends Node
## Acompanha o progresso de cada kart ao longo da pista. race_progress é monotônico (em voltas):
## começa levemente negativo (atrás da linha), cruza 0 na largada e +1 a cada volta completa.
## Andar de ré ou voltar pela linha não gera voltas falsas (só conta a maior volta alcançada).

signal checkpoint_passed(kart: KartController, sector: int)
signal lap_crossed(kart: KartController, laps_completed: int)

@export var sector_count: int = 4

var path: TrackPath
var karts: Array[KartController] = []
var total_laps: int = 3
var _last_f: Dictionary = {}
var _sector: Dictionary = {}


func setup(p: TrackPath, ks: Array[KartController], laps: int) -> void:
	path = p
	karts = ks
	total_laps = laps
	for k in karts:
		var f: float = k.path_dist / path.length
		_last_f[k] = f
		_sector[k] = 0
		k.race_progress = (f - 1.0) if f > 0.5 else f
		k.laps_completed = 0
		k.current_lap = 1


func _physics_process(_delta: float) -> void:
	if path == null:
		return
	for k in karts:
		var f: float = k.path_dist / path.length
		var d: float = f - float(_last_f[k])
		if d < -0.5:
			d += 1.0
		elif d > 0.5:
			d -= 1.0
		_last_f[k] = f
		k.race_progress += d
		var whole: int = floori(k.race_progress)
		if whole >= 1 and whole > k.laps_completed:
			k.laps_completed = whole
			lap_crossed.emit(k, whole)
		k.current_lap = clampi(whole + 1, 1, total_laps)
		# setores (para efeitos/HUD)
		var sec: int = int(fposmod(k.race_progress, 1.0) * float(sector_count))
		if sec != int(_sector[k]):
			if sec == (int(_sector[k]) + 1) % sector_count:
				checkpoint_passed.emit(k, sec)
			_sector[k] = sec
