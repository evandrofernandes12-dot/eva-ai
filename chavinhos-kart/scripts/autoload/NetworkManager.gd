extends Node
## Online. Duas formas de jogar:
##  - Servidor oficial (WebSocket/wss): funciona no navegador e em qualquer aparelho. É o padrão.
##  - Sala na rede local (ENet/UDP): só em PC/tablet/celular nativo, com busca automática de salas.
##
## Modelo: o servidor (dedicado ou um jogador no modo LAN) repassa o estado de cada kart a todos.
## Cada jogador simula o próprio kart e envia o estado 20x/s. Bots são simulados pelo servidor.

signal lobby_updated
signal connected_ok
signal connect_failed
signal disconnected_from_host
signal rooms_updated

## Mude a cada alteração que afete a rede. Cliente e servidor precisam ter a mesma versão.
const GAME_VERSION: String = "2.1"
## Endereço do servidor oficial (Render). Troque pelo endereço real depois de criar o serviço.
const DEFAULT_SERVER_URL: String = "wss://chavinhos-kart.onrender.com"
const PORT: int = 47320
const DISCOVERY_PORT: int = 47321
const MAX_HUMANS: int = 8

var active: bool = false
var is_host: bool = false
var dedicated: bool = false
var room_name: String = "Sala"
var players: Dictionary = {}   # peer_id -> { name, racer, ready }
var settings: Dictionary = {"battle": false, "track": 0, "laps": 3}
var config: Dictionary = {}    # configuração da corrida em andamento
var rooms: Dictionary = {}     # ip -> { name, port, count, seen }
var racing: bool = false
var last_error: String = ""

var _my_name: String = "Jogador"
var _my_racer: String = "chaves"
var _udp_tx: PacketPeerUDP
var _udp_rx: PacketPeerUDP
var _bcast_t: float = 0.0
var _auto_t: float = -1.0


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)


static func is_web() -> bool:
	return OS.has_feature("web")


func my_id() -> int:
	return multiplayer.get_unique_id() if active else 1


# ===================================================================== conexão

## Sala na rede local (somente nativo). Retorna código de erro.
func host_game(room: String, player_name: String, racer_id: String) -> int:
	if is_web():
		return ERR_UNAVAILABLE
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_server(PORT, MAX_HUMANS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = true
	dedicated = false
	room_name = room if room != "" else "Sala de %s" % player_name
	players = {1: {"name": player_name, "racer": racer_id, "ready": true}}
	_start_broadcast()
	lobby_updated.emit()
	return OK


## Servidor oficial: roda com `--headless -- --server` (ver Dockerfile). Usa WebSocket para
## o navegador conseguir conectar. Na nuvem a porta vem da variável PORT.
func host_dedicated() -> int:
	leave()
	var port: int = PORT
	var env_port: String = OS.get_environment("PORT")
	if env_port != "":
		port = int(env_port)
	var peer := WebSocketMultiplayerPeer.new()
	var err: int = peer.create_server(port)
	if err != OK:
		push_error("Não foi possível abrir a porta %d" % port)
		return err
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = true
	dedicated = true
	room_name = "Servidor Chavinho"
	players = {}
	settings = {"battle": false, "track": 0, "laps": 3}
	print("Servidor dedicado (WebSocket) ouvindo na porta ", port, " - versão ", GAME_VERSION)
	return OK


## address: "" ou "oficial" = servidor oficial; ws(s)://... ; host (no navegador vira wss://host);
## IP ou IP:porta (somente nativo, rede local, via ENet).
func join_game(address: String, player_name: String, racer_id: String) -> int:
	leave()
	_my_name = player_name
	_my_racer = racer_id
	last_error = ""
	var addr: String = address.strip_edges()
	if addr == "" or addr == "oficial":
		addr = DEFAULT_SERVER_URL
	var peer: MultiplayerPeer
	var err: int
	if addr.begins_with("ws://") or addr.begins_with("wss://"):
		var ws := WebSocketMultiplayerPeer.new()
		err = ws.create_client(addr)
		peer = ws
	elif is_web():
		var ws2 := WebSocketMultiplayerPeer.new()
		err = ws2.create_client("wss://" + addr)
		peer = ws2
	else:
		var host: String = addr
		var port: int = PORT
		if ":" in host:
			var parts: PackedStringArray = host.split(":")
			host = parts[0]
			port = int(parts[1])
		var enet := ENetMultiplayerPeer.new()
		err = enet.create_client(host, port)
		peer = enet
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = false
	dedicated = false
	return OK


func leave() -> void:
	stop_discovery()
	_udp_tx = null
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	active = false
	is_host = false
	dedicated = false
	racing = false
	players = {}
	config = {}
	_auto_t = -1.0


func _on_connected() -> void:
	# Só vira "conectado" quando o servidor aceita (_net_welcome), para mostrar erros de versão.
	_net_register.rpc_id(1, _my_name, _my_racer, GAME_VERSION)


func _on_connection_failed() -> void:
	leave()
	if last_error == "":
		last_error = "Não consegui conectar. Verifique o endereço e a internet."
	connect_failed.emit()


func _on_server_gone() -> void:
	leave()
	disconnected_from_host.emit()


func _on_peer_disconnected(id: int) -> void:
	if is_host and players.has(id):
		players.erase(id)
		_sync()


func _kick_later(id: int) -> void:
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if multiplayer.multiplayer_peer != null and multiplayer.get_peers().has(id):
			multiplayer.multiplayer_peer.disconnect_peer(id))


# ===================================================================== lobby

func set_my_racer(racer_id: String) -> void:
	_my_racer = racer_id
	if not active:
		return
	if is_host and not dedicated:
		players[1]["racer"] = racer_id
		_sync()
	elif not is_host:
		_net_set_racer.rpc_id(1, racer_id)


func set_ready(value: bool) -> void:
	if active and not is_host:
		_net_set_ready.rpc_id(1, value)


func set_settings(s: Dictionary) -> void:
	if not is_host:
		return
	settings = s
	_sync()


func _sync() -> void:
	lobby_updated.emit()
	if active and is_host:
		_net_sync.rpc(players, settings, room_name)


@rpc("any_peer", "call_remote", "reliable")
func _net_register(pname: String, racer_id: String, version: String) -> void:
	if not is_host:
		return
	var id: int = multiplayer.get_remote_sender_id()
	if version != GAME_VERSION:
		_net_rejected.rpc_id(id, "Versão diferente (sua %s, servidor %s). Atualize a página (Ctrl+F5)." % [version, GAME_VERSION])
		_kick_later(id)
		return
	if players.size() >= MAX_HUMANS or racing:
		_net_rejected.rpc_id(id, "Sala cheia ou corrida em andamento. Tente de novo em instantes.")
		_kick_later(id)
		return
	players[id] = {"name": pname.substr(0, 16), "racer": racer_id, "ready": false}
	_net_welcome.rpc_id(id)
	_sync()


@rpc("authority", "call_remote", "reliable")
func _net_welcome() -> void:
	connected_ok.emit()


@rpc("authority", "call_remote", "reliable")
func _net_rejected(msg: String) -> void:
	last_error = msg
	leave()
	connect_failed.emit()


@rpc("any_peer", "call_remote", "reliable")
func _net_set_racer(racer_id: String) -> void:
	var id: int = multiplayer.get_remote_sender_id()
	if is_host and players.has(id):
		players[id]["racer"] = racer_id
		_sync()


@rpc("any_peer", "call_remote", "reliable")
func _net_set_ready(value: bool) -> void:
	var id: int = multiplayer.get_remote_sender_id()
	if is_host and players.has(id):
		players[id]["ready"] = value
		_sync()


@rpc("authority", "call_remote", "reliable")
func _net_sync(p: Dictionary, s: Dictionary, room: String) -> void:
	players = p
	settings = s
	room_name = room
	lobby_updated.emit()


# ===================================================================== início / fim da corrida

func start_race() -> void:
	if not active or not is_host or racing or (players.is_empty() and not dedicated):
		return
	racing = true
	_auto_t = -1.0
	var used: Dictionary = {}
	var slots: Array = []
	for id in players:
		var info: Dictionary = players[id]
		used[str(info["racer"])] = true
		slots.append({"peer": int(id), "racer": str(info["racer"]), "name": str(info["name"])})
	var pool: Array[RacerStats] = []
	pool.append_array(Global.racers)
	pool.shuffle()
	for r in pool:
		if slots.size() >= Global.TOTAL_RACERS:
			break
		if not used.has(r.id):
			slots.append({"peer": 0, "racer": r.id, "name": r.display_name})
			used[r.id] = true
	slots.shuffle()
	var cfg: Dictionary = {
		"battle": false,  # Batalha de Balões ainda não é online
		"track": int(settings["track"]),
		"laps": int(settings["laps"]),
		"slots": slots,
	}
	if dedicated:
		cfg["track"] = randi() % TrackCatalog.count()
		cfg["laps"] = 3
	config = cfg
	Global.mode = Global.Mode.ONLINE
	_net_begin_race.rpc(cfg)
	Global.goto_race()


@rpc("authority", "call_remote", "reliable")
func _net_begin_race(cfg: Dictionary) -> void:
	config = cfg
	racing = true
	Global.mode = Global.Mode.ONLINE
	Global.goto_race()


## Anfitrião: todos voltam para a sala.
func return_to_lobby() -> void:
	if not active:
		Global.goto_lobby()
		return
	if not is_host:
		return
	racing = false
	for id in players:
		players[id]["ready"] = (int(id) == 1 and not dedicated)
	_net_return_lobby.rpc()
	_sync()
	Global.goto_lobby()


@rpc("authority", "call_remote", "reliable")
func _net_return_lobby() -> void:
	racing = false
	Global.goto_lobby()


# ===================================================================== descoberta de salas (LAN, nativo)

func local_addresses() -> PackedStringArray:
	var out := PackedStringArray()
	if is_web():
		return out
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254."):
			out.append(a)
	return out


func start_discovery() -> void:
	stop_discovery()
	rooms.clear()
	if is_web():
		return
	_udp_rx = PacketPeerUDP.new()
	if _udp_rx.bind(DISCOVERY_PORT) != OK:
		_udp_rx = null


func stop_discovery() -> void:
	if _udp_rx != null:
		_udp_rx.close()
		_udp_rx = null


func _start_broadcast() -> void:
	_udp_tx = PacketPeerUDP.new()
	_udp_tx.set_broadcast_enabled(true)
	_udp_tx.set_dest_address("255.255.255.255", DISCOVERY_PORT)


func _process(delta: float) -> void:
	if _udp_tx != null and active and is_host and not racing:
		_bcast_t -= delta
		if _bcast_t <= 0.0:
			_bcast_t = 1.0
			var msg: String = "CHK1|%s|%d|%d" % [room_name.replace("|", " "), PORT, players.size()]
			_udp_tx.put_packet(msg.to_utf8_buffer())
	if _udp_rx != null:
		var changed: bool = false
		while _udp_rx.get_available_packet_count() > 0:
			var text: String = _udp_rx.get_packet().get_string_from_utf8()
			var ip: String = _udp_rx.get_packet_ip()
			var parts: PackedStringArray = text.split("|")
			if parts.size() >= 4 and parts[0] == "CHK1":
				rooms[ip] = {"name": parts[1], "port": int(parts[2]), "count": int(parts[3]), "seen": Time.get_ticks_msec()}
				changed = true
		var now: int = Time.get_ticks_msec()
		for ip in rooms.keys():
			if now - int(rooms[ip]["seen"]) > 4500:
				rooms.erase(ip)
				changed = true
		if changed:
			rooms_updated.emit()
	# servidor: inicia sozinho quando todos estiverem prontos
	if dedicated and is_host and not racing:
		var all_ready: bool = not players.is_empty()
		for id in players:
			if not bool(players[id]["ready"]):
				all_ready = false
		if all_ready:
			if _auto_t < 0.0:
				_auto_t = 4.0
			_auto_t -= delta
			if _auto_t <= 0.0:
				start_race()
		else:
			_auto_t = -1.0
