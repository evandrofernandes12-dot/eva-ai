extends Node
## Estado global: lista de pilotos, seleção, resultados e navegação entre cenas.

signal racer_selected(stats: RacerStats)

const RACER_IDS: Array[String] = [
	"chaves", "chiquinha", "quico", "nhonho", "popis", "madruga",
	"jaiminho", "florinda", "girafales", "barriga", "bruxa",
]
const TOTAL_RACERS: int = 8
const TOTAL_LAPS: int = 3

const SCENE_MENU: String = "res://scenes/main/MainMenu.tscn"
const SCENE_SELECT: String = "res://scenes/ui/CharacterSelect.tscn"
const SCENE_RACE: String = "res://scenes/main/GameManager.tscn"
const SCENE_PODIUM: String = "res://scenes/ui/Podium.tscn"

var racers: Array[RacerStats] = []
var selected_racer: RacerStats
## Cada entrada: { stats: RacerStats, name: String, place: int, time: float, is_player: bool }
var race_results: Array[Dictionary] = []


func _ready() -> void:
	randomize()
	for id in RACER_IDS:
		var res: RacerStats = load("res://resources/racers/%s.tres" % id) as RacerStats
		if res != null:
			racers.append(res)
		else:
			push_warning("Piloto não encontrado: %s" % id)
	if not racers.is_empty():
		selected_racer = racers[0]


func select_racer(stats: RacerStats) -> void:
	selected_racer = stats
	racer_selected.emit(stats)


## Sorteia os adversários (todos menos o jogador), limitado ao total de corredores - 1.
func pick_opponents() -> Array[RacerStats]:
	var pool: Array[RacerStats] = []
	for r in racers:
		if r != selected_racer:
			pool.append(r)
	pool.shuffle()
	var count: int = mini(TOTAL_RACERS - 1, pool.size())
	var picked: Array[RacerStats] = []
	picked.assign(pool.slice(0, count))
	return picked


func goto_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_MENU)


func goto_select() -> void:
	get_tree().change_scene_to_file(SCENE_SELECT)


func goto_race() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_RACE)


func goto_podium() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_PODIUM)


static func format_time(t: float) -> String:
	var minutes: int = int(t) / 60
	var seconds: float = fmod(t, 60.0)
	return "%d:%06.3f" % [minutes, seconds]
