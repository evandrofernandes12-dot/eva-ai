extends Node
## Estado global: pilotos, modo de jogo, copa, desafios, resultados e navegação entre cenas.

signal racer_selected(stats: RacerStats)

enum Mode { QUICK, CUP, BATTLE, CHALLENGE, ONLINE }

const RACER_IDS: Array[String] = [
	"chaves", "chiquinha", "quico", "nhonho", "popis", "madruga",
	"jaiminho", "florinda", "girafales", "barriga", "bruxa",
]
const TOTAL_RACERS: int = 8
const DEFAULT_LAPS: int = 3
const CUP_TRACKS: Array[int] = [0, 1, 2, 3]
const CUP_POINTS: Array[int] = [15, 12, 10, 8, 6, 4, 2, 1]

const SCENE_MENU: String = "res://scenes/main/MainMenu.tscn"
const SCENE_SELECT: String = "res://scenes/ui/CharacterSelect.tscn"
const SCENE_TRACKS: String = "res://scenes/ui/TrackSelect.tscn"
const SCENE_CHALLENGES: String = "res://scenes/ui/ChallengeSelect.tscn"
const SCENE_ONLINE: String = "res://scenes/ui/OnlineMenu.tscn"
const SCENE_LOBBY: String = "res://scenes/ui/Lobby.tscn"
const SCENE_RACE: String = "res://scenes/main/GameManager.tscn"
const SCENE_PODIUM: String = "res://scenes/ui/Podium.tscn"

var racers: Array[RacerStats] = []
var selected_racer: RacerStats
## Cada entrada: { stats, name, place, time, is_player, score_text }
var race_results: Array[Dictionary] = []

var mode: int = Mode.QUICK
var track_index: int = 0
var laps: int = DEFAULT_LAPS

# ---- Copa
var cup_stage: int = 0
var cup_points: Dictionary = {}       # id do piloto -> pontos
var cup_stats: Dictionary = {}        # id do piloto -> RacerStats
var cup_opponents: Array[RacerStats] = []

# ---- Desafio
var challenge: Dictionary = {}
var challenge_result: Dictionary = {}  # { done: bool, text: String }
var new_record: bool = false


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
	if "--server" in OS.get_cmdline_args() or "--server" in OS.get_cmdline_user_args():
		call_deferred("_start_dedicated_server")


func _start_dedicated_server() -> void:
	NetworkManager.host_dedicated()
	goto_lobby()


func get_racer(id: String) -> RacerStats:
	for r in racers:
		if r.id == id:
			return r
	return racers[0]


func select_racer(stats: RacerStats) -> void:
	selected_racer = stats
	racer_selected.emit(stats)


## Adversários da corrida (na Copa, são os mesmos nas 4 etapas).
func pick_opponents() -> Array[RacerStats]:
	if mode == Mode.CUP and not cup_opponents.is_empty():
		return cup_opponents
	var pool: Array[RacerStats] = []
	for r in racers:
		if r != selected_racer:
			pool.append(r)
	pool.shuffle()
	var count: int = mini(TOTAL_RACERS - 1, pool.size())
	var picked: Array[RacerStats] = []
	picked.assign(pool.slice(0, count))
	return picked


# ===================================================================== modos

## Depois de escolher o piloto, cada modo segue seu caminho.
func after_character_select() -> void:
	match mode:
		Mode.QUICK:
			goto_tracks()
		Mode.CUP:
			start_cup()
		Mode.BATTLE:
			start_battle()
		Mode.CHALLENGE:
			start_challenge_race()
		_:
			goto_menu()


func start_quick(index: int, lap_count: int = DEFAULT_LAPS) -> void:
	mode = Mode.QUICK
	track_index = index
	laps = lap_count
	goto_race()


func start_cup() -> void:
	mode = Mode.CUP
	cup_stage = 0
	cup_points.clear()
	cup_stats.clear()
	cup_opponents.clear()
	cup_opponents = _random_opponents()
	track_index = CUP_TRACKS[0]
	laps = DEFAULT_LAPS
	goto_race()


func start_battle() -> void:
	mode = Mode.BATTLE
	goto_race()


func start_challenge_race() -> void:
	mode = Mode.CHALLENGE
	track_index = int(challenge.get("track", 0))
	laps = int(challenge.get("laps", DEFAULT_LAPS))
	goto_race()


func _random_opponents() -> Array[RacerStats]:
	var pool: Array[RacerStats] = []
	for r in racers:
		if r != selected_racer:
			pool.append(r)
	pool.shuffle()
	var out: Array[RacerStats] = []
	out.assign(pool.slice(0, mini(TOTAL_RACERS - 1, pool.size())))
	return out


## Chamado ao fim de cada corrida (offline): soma os pontos da Copa.
func record_race(results: Array[Dictionary]) -> void:
	if mode != Mode.CUP:
		return
	for e in results:
		var st: RacerStats = e["stats"] as RacerStats
		var idx: int = clampi(int(e["place"]) - 1, 0, CUP_POINTS.size() - 1)
		cup_points[st.id] = int(cup_points.get(st.id, 0)) + CUP_POINTS[idx]
		cup_stats[st.id] = st


func cup_standings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in cup_points:
		var st: RacerStats = cup_stats[id] as RacerStats
		out.append({"stats": st, "name": st.display_name, "points": int(cup_points[id]), "is_player": st == selected_racer})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["points"]) > int(b["points"]))
	return out


func cup_has_next() -> bool:
	return cup_stage + 1 < CUP_TRACKS.size()


func cup_next_race() -> void:
	cup_stage += 1
	track_index = CUP_TRACKS[clampi(cup_stage, 0, CUP_TRACKS.size() - 1)]
	goto_race()


# ===================================================================== navegação

func _go(path: String) -> void:
	get_tree().paused = false
	Transition.go(path)


func goto_menu() -> void:
	_go(SCENE_MENU)


func goto_select() -> void:
	_go(SCENE_SELECT)


func goto_tracks() -> void:
	_go(SCENE_TRACKS)


func goto_challenges() -> void:
	_go(SCENE_CHALLENGES)


func goto_online() -> void:
	_go(SCENE_ONLINE)


func goto_lobby() -> void:
	_go(SCENE_LOBBY)


func goto_race() -> void:
	_go(SCENE_RACE)


func goto_podium() -> void:
	_go(SCENE_PODIUM)


static func format_time(t: float) -> String:
	var minutes: int = int(t) / 60
	var seconds: float = fmod(t, 60.0)
	return "%d:%06.3f" % [minutes, seconds]
