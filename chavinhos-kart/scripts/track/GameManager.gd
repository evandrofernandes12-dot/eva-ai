class_name GameManager
extends Node3D
## Orquestra a corrida em todos os modos: Corrida/Copa/Desafio (voltas), Batalha de Balões e Online.
## Online: cada peer simula o próprio kart; o anfitrião simula os bots e decide o resultado.

const PLAYER_SCENE: PackedScene = preload("res://scenes/karts/PlayerKart.tscn")
const AI_SCENE: PackedScene = preload("res://scenes/karts/AIKart.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")
const PLAYER_GRID_SLOT: int = 5 # largada no fundo do grid: dá o desafio de remontar

var track: TrackBase
var karts: Array[KartController] = []
var player: KartController
var lap_manager: LapManager
var battle: BattleManager
var checkpoints: CheckpointSystem
var challenge_tracker: ChallengeTracker
var hud: Node

var is_battle: bool = false
var online: bool = false
var is_host: bool = true
var total_laps: int = 3
var _band_timer: float = 0.0
var _ready_peers: Dictionary = {}
var _started: bool = false
var _concluded: bool = false


func _ready() -> void:
	Global.new_record = false
	Global.challenge_result = {}
	online = NetworkManager.active and Global.mode == Global.Mode.ONLINE
	is_host = (not online) or multiplayer.is_server()
	var cfg: Dictionary = NetworkManager.config if online else {}
	is_battle = Global.mode == Global.Mode.BATTLE or (online and bool(cfg.get("battle", false)))
	total_laps = int(cfg.get("laps", Global.laps)) if online else Global.laps

	_build_track(int(cfg.get("track", Global.track_index)))
	var slots: Array[Dictionary] = _build_slots(cfg)
	_spawn_karts(slots)
	_setup_mode()

	if player != null:
		hud = HUD_SCENE.instantiate()
		add_child(hud)
		hud.call("bind", self) # HUDController.bind(game)

	_debug_report()
	if online:
		multiplayer.peer_disconnected.connect(_on_peer_left)
		NetworkManager.disconnected_from_host.connect(Global.goto_menu)
	_start_sequence()


# ===================================================================== montagem

func _build_track(index: int) -> void:
	var path: String = TrackCatalog.ARENA_SCENE if is_battle else str(TrackCatalog.info(index)["scene"])
	track = (load(path) as PackedScene).instantiate() as TrackBase
	add_child(track)


## Lista de largada: { stats, peer, human }  (peer 0 = bot; offline: peer -1 = jogador local)
func _build_slots(cfg: Dictionary) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	if online:
		for s in cfg["slots"]:
			slots.append({"stats": Global.get_racer(str(s["racer"])), "peer": int(s["peer"]), "name": str(s["name"])})
		return slots
	var player_stats: RacerStats = Global.selected_racer if Global.selected_racer != null else Global.racers[0]
	var opponents: Array[RacerStats] = Global.pick_opponents()
	var opp: int = 0
	for slot in Global.TOTAL_RACERS:
		if slot == PLAYER_GRID_SLOT:
			slots.append({"stats": player_stats, "peer": -1, "name": player_stats.display_name})
		elif opp < opponents.size():
			slots.append({"stats": opponents[opp], "peer": 0, "name": opponents[opp].display_name})
			opp += 1
	return slots


func _spawn_karts(slots: Array[Dictionary]) -> void:
	var karts_root := Node3D.new()
	karts_root.name = "Karts"
	add_child(karts_root)
	var my_id: int = multiplayer.get_unique_id() if online else 1
	for i in slots.size():
		var s: Dictionary = slots[i]
		var peer: int = int(s["peer"])
		var local_human: bool = (peer == -1) or (online and peer == my_id and not NetworkManager.dedicated)
		var kart: KartController
		if local_human:
			kart = PLAYER_SCENE.instantiate() as KartController
			player = kart
		else:
			kart = AI_SCENE.instantiate() as KartController
			if online:
				# humanos remotos e bots de OUTRO anfitrião são só recebidos pela rede
				kart.is_remote = not (peer == 0 and is_host)
		kart.name = "Kart_%d" % i
		kart.net_slot = i
		kart.stats = s["stats"] as RacerStats
		if online:
			kart.set_multiplayer_authority(peer if peer > 0 else 1)
		if not local_human and peer == 0:
			kart.speed_mult = kart.stats.ai_skill
		kart.offroad_factor = track.offroad_factor
		kart.path = null if is_battle else track.path
		kart.transform = track.start_transforms[i]
		karts_root.add_child(kart)
		if is_battle:
			var ai: Node = kart.get_node_or_null("KartAI")
			if ai != null:
				ai.set("battle_mode", true)
		karts.append(kart)
	for k in karts:
		k.refresh_path_position()


func _setup_mode() -> void:
	if is_battle:
		battle = BattleManager.new()
		battle.name = "BattleManager"
		add_child(battle)
		battle.setup(karts)
		battle.net_client = online and not is_host
		battle.countdown_tick.connect(_on_countdown_tick)
		battle.battle_finished.connect(_on_finished)
		return
	checkpoints = CheckpointSystem.new()
	checkpoints.name = "CheckpointSystem"
	add_child(checkpoints)
	checkpoints.setup(track.path, karts, total_laps)
	lap_manager = LapManager.new()
	lap_manager.name = "LapManager"
	add_child(lap_manager)
	lap_manager.setup(karts, checkpoints, total_laps, track.path)
	lap_manager.countdown_tick.connect(_on_countdown_tick)
	lap_manager.race_finished.connect(_on_finished)
	if Global.mode == Global.Mode.CHALLENGE and player != null:
		challenge_tracker = ChallengeTracker.new()
		add_child(challenge_tracker)
		challenge_tracker.setup(Global.challenge, player)


# ===================================================================== largada

func _start_sequence() -> void:
	await get_tree().create_timer(1.2).timeout
	if not online:
		_begin()
		return
	if is_host:
		var waited: float = 0.0
		while waited < 8.0 and not _all_ready():
			await get_tree().process_frame
			waited += get_process_delta_time()
		net_go.rpc()
		_begin()
	else:
		net_ready.rpc_id(1)
		await get_tree().create_timer(15.0).timeout
		_begin() # garantia caso o sinal do anfitrião se perca


func _all_ready() -> bool:
	for id in NetworkManager.players:
		if int(id) != 1 and not _ready_peers.has(int(id)):
			return false
	return true


func _begin() -> void:
	if _started:
		return
	_started = true
	if battle != null:
		battle.start_countdown()
	else:
		lap_manager.start_countdown()


func _on_countdown_tick(value: int) -> void:
	if value > 0:
		AudioManager.play_sfx("beep")
	else:
		AudioManager.play_sfx("go")


func _physics_process(delta: float) -> void:
	if is_battle or player == null and not online:
		return
	_band_timer += delta
	if _band_timer < 0.5 or lap_manager == null or not lap_manager.running or not is_host:
		return
	_band_timer = 0.0
	# Rubber band: bots atrás aceleram um pouco, bots muito à frente aliviam.
	var lead: float = 0.0
	if player != null:
		lead = player.race_progress
	else:
		for k in karts:
			lead = maxf(lead, k.race_progress)
	for k in karts:
		if k.is_player or k.is_remote or not k.is_multiplayer_authority() and online:
			continue
		if k.get_node_or_null("KartAI") == null:
			continue
		var diff: float = lead - k.race_progress # > 0 = atrás de quem lidera
		k.speed_mult = k.stats.ai_skill * clampf(1.0 + diff * 0.55, 0.92, 1.12)


# ===================================================================== fim

func _on_finished(results: Array) -> void:
	if _concluded:
		return
	if online and not is_host:
		# o anfitrião manda o resultado oficial; se não vier, usa o local
		await get_tree().create_timer(12.0).timeout
		if not _concluded:
			_conclude(results)
		return
	if online:
		var arr: Array = []
		for e in results:
			arr.append({"slot": int(e["slot"]), "place": int(e["place"]), "time": float(e["time"]), "score_text": str(e.get("score_text", ""))})
		net_results.rpc(arr)
	_conclude(results)


func _conclude(results: Array) -> void:
	if _concluded:
		return
	_concluded = true
	var typed: Array[Dictionary] = []
	typed.assign(results)
	Global.race_results = typed
	if not online:
		Global.record_race(typed)
		_save_progress(typed)
	await get_tree().create_timer(1.5).timeout
	if NetworkManager.dedicated:
		await get_tree().create_timer(12.0).timeout
		NetworkManager.return_to_lobby()
		return
	Global.goto_podium()


func _save_progress(typed: Array[Dictionary]) -> void:
	Global.challenge_result = {}
	if player == null:
		return
	if not is_battle and Global.mode != Global.Mode.CHALLENGE and is_finite(player.best_lap):
		Global.new_record = Save.submit_time(TrackCatalog.track_id(Global.track_index), player.best_lap)
	if challenge_tracker != null:
		var res: Dictionary = challenge_tracker.evaluate(player.place, player.finish_time, player.finished)
		Global.challenge_result = res
		if bool(res["done"]):
			Save.mark_challenge(str(Global.challenge["id"]))


# ===================================================================== rede (RPCs do jogo)

func kart_by_slot(slot: int) -> KartController:
	for k in karts:
		if k.net_slot == slot:
			return k
	return null


# ---- repasse de eventos: clientes falam só com o servidor; o servidor repassa aos outros.
# kind: "state" (posição do kart), "item" (item lançado), "hit" (item acertou alguém).

## Envia um evento. Em qualquer aparelho, chame sempre este método.
func send_net(kind: String, slot: int, data: Array) -> void:
	if not online:
		return
	if multiplayer.is_server():
		_broadcast(kind, slot, data, 0)
	else:
		up_msg.rpc_id(1, kind, slot, data)


@rpc("any_peer", "call_remote", "reliable")
func up_msg(kind: String, slot: int, data: Array) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	var k: KartController = kart_by_slot(slot)
	if kind != "hit" and (k == null or k.get_multiplayer_authority() != sender):
		return # só o dono do kart pode mandar o estado/itens dele
	_apply(kind, slot, data)
	_broadcast(kind, slot, data, sender)


func _broadcast(kind: String, slot: int, data: Array, except: int) -> void:
	for id in multiplayer.get_peers():
		if int(id) != except:
			down_msg.rpc_id(int(id), kind, slot, data)


@rpc("authority", "call_remote", "reliable")
func down_msg(kind: String, slot: int, data: Array) -> void:
	_apply(kind, slot, data)


func _apply(kind: String, slot: int, data: Array) -> void:
	if kind == "state":
		var k: KartController = kart_by_slot(slot)
		if k != null:
			k.apply_net_state(data)
	elif kind == "item":
		var k2: KartController = kart_by_slot(slot)
		if k2 != null:
			ItemDefs.spawn(k2, int(data[0]), int(data[1]))
	elif kind == "hit":
		for n in get_tree().get_nodes_in_group("net_items"):
			if int(n.get("net_id")) == int(data[0]):
				n.queue_free()


@rpc("any_peer", "call_remote", "reliable")
func net_ready() -> void:
	if multiplayer.is_server():
		_ready_peers[multiplayer.get_remote_sender_id()] = true


@rpc("authority", "call_remote", "reliable")
func net_go() -> void:
	_begin()


@rpc("authority", "call_remote", "reliable")
func net_results(arr: Array) -> void:
	var out: Array[Dictionary] = []
	for e in arr:
		var k: KartController = kart_by_slot(int(e["slot"]))
		if k == null:
			continue
		out.append({
			"slot": int(e["slot"]), "stats": k.stats, "name": k.stats.display_name, "place": int(e["place"]),
			"time": float(e["time"]), "is_player": k.is_player, "score_text": str(e["score_text"]),
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["place"]) < int(b["place"]))
	_conclude(out)


@rpc("authority", "call_remote", "reliable")
func net_takeover(slot: int) -> void:
	var k: KartController = kart_by_slot(slot)
	if k != null:
		k.set_multiplayer_authority(1)


## Servidor: um jogador saiu no meio da corrida e o kart dele vira bot.
func _on_peer_left(id: int) -> void:
	if not multiplayer.is_server():
		return
	for k in karts:
		if k.get_multiplayer_authority() == id:
			k.set_multiplayer_authority(1)
			k.is_remote = false
			k.speed_mult = k.stats.ai_skill
			net_takeover.rpc(k.net_slot)


# ---- DIAGNÓSTICO TEMPORÁRIO (remover)
func _debug_report() -> void:
	print("DBG pista=", track.name, " grid=", track.start_transforms.size(), " len=", track.path.length)
	for n in track.find_children("*", "CollisionShape3D", true, false):
		var cs: CollisionShape3D = n as CollisionShape3D
		print("DBG colisao ", cs.get_parent().name, " shape=", cs.shape, " pos=", cs.global_position, " disabled=", cs.disabled)
	for k in karts:
		print("DBG kart ", k.name, " pos=", k.global_position)
	var meshes: int = 0
	var far_meshes: int = 0
	for n in track.find_children("*", "MeshInstance3D", true, false):
		meshes += 1
		var mi: MeshInstance3D = n as MeshInstance3D
		var aabb: AABB = mi.get_aabb()
		if aabb.size.length() > 300.0:
			far_meshes += 1
			print("DBG malha grande ", mi.get_parent().name, "/", mi.name, " size=", aabb.size, " pos=", mi.global_position, " scale=", mi.scale)
	print("DBG malhas=", meshes, " grandes=", far_meshes)
	for i in 6:
		await get_tree().create_timer(1.0).timeout
		if player != null:
			print("DBG t=", i + 1, " player=", player.global_position, " vel=", player.velocity, " floor=", player.is_on_floor())
			var cam: Camera3D = get_viewport().get_camera_3d()
			if cam != null:
				print("DBG cam=", cam.name, " pos=", cam.global_position, " rot=", cam.global_rotation, " fov=", cam.fov, " near=", cam.near, " far=", cam.far, " parent=", cam.get_parent().name)
			else:
				print("DBG cam=NULL")
