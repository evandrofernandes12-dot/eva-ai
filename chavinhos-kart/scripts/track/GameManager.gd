class_name GameManager
extends Node3D
## Orquestra a corrida: instancia pista, karts, HUD, checkpoints e gerenciador de voltas,
## faz o rubber band da IA e encerra no pódio.

const TRACK_SCENE: PackedScene = preload("res://scenes/tracks/TrackVila.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/karts/PlayerKart.tscn")
const AI_SCENE: PackedScene = preload("res://scenes/karts/AIKart.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")

const PLAYER_GRID_SLOT: int = 5 # largada no fundo do grid: dá o desafio de remontar

var track: TrackBase
var karts: Array[KartController] = []
var player: KartController
var lap_manager: LapManager
var checkpoints: CheckpointSystem
var hud: Node
var _band_timer: float = 0.0


func _ready() -> void:
	track = TRACK_SCENE.instantiate() as TrackBase
	add_child(track)

	var karts_root := Node3D.new()
	karts_root.name = "Karts"
	add_child(karts_root)

	var player_stats: RacerStats = Global.selected_racer
	if player_stats == null:
		player_stats = Global.racers[0]
	var opponents: Array[RacerStats] = Global.pick_opponents()

	var slot_opp: int = 0
	for slot in Global.TOTAL_RACERS:
		var is_player: bool = slot == PLAYER_GRID_SLOT
		if not is_player and slot_opp >= opponents.size():
			break
		var kart: KartController
		if is_player:
			kart = PLAYER_SCENE.instantiate() as KartController
			kart.stats = player_stats
			player = kart
		else:
			kart = AI_SCENE.instantiate() as KartController
			kart.stats = opponents[slot_opp]
			kart.speed_mult = kart.stats.ai_skill
			slot_opp += 1
		kart.path = track.path
		kart.transform = track.start_transforms[slot]
		karts_root.add_child(kart)
		kart.refresh_path_position()
		karts.append(kart)

	checkpoints = CheckpointSystem.new()
	checkpoints.name = "CheckpointSystem"
	add_child(checkpoints)
	checkpoints.setup(track.path, karts, Global.TOTAL_LAPS)

	lap_manager = LapManager.new()
	lap_manager.name = "LapManager"
	add_child(lap_manager)
	lap_manager.setup(karts, checkpoints, Global.TOTAL_LAPS, track.path)
	lap_manager.countdown_tick.connect(_on_countdown_tick)
	lap_manager.race_finished.connect(_on_race_finished)

	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.call("bind", self) # HUDController.bind(game)

	# pequena pausa antes da contagem para o jogador se situar
	get_tree().create_timer(1.2).timeout.connect(lap_manager.start_countdown)


func _physics_process(delta: float) -> void:
	_band_timer += delta
	if _band_timer < 0.5 or player == null or not lap_manager.running:
		return
	_band_timer = 0.0
	# Rubber band: IA atrás do jogador acelera um pouco, IA muito à frente alivia.
	for k in karts:
		if k.is_player:
			continue
		var diff: float = player.race_progress - k.race_progress # > 0 = IA atrás
		var band: float = clampf(1.0 + diff * 0.55, 0.92, 1.12)
		k.speed_mult = k.stats.ai_skill * band


func _on_countdown_tick(value: int) -> void:
	if value > 0:
		AudioManager.play_sfx("beep")
	else:
		AudioManager.play_sfx("go")


func _on_race_finished(_results: Array) -> void:
	await get_tree().create_timer(1.5).timeout
	Global.goto_podium()
