class_name Lobby
extends Control
## Sala online: lista de jogadores, escolha de piloto e (anfitrião) modo/pista/voltas + iniciar.

var _players_box: VBoxContainer
var _preview: KartPreview
var _racer_opt: OptionButton
var _mode_opt: OptionButton
var _track_opt: OptionButton
var _laps_opt: OptionButton
var _start_btn: Button
var _ready_btn: Button
var _info: Label
var _updating: bool = false


func _ready() -> void:
	if not NetworkManager.active:
		Global.goto_online()
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UIStyle.gradient_bg(Color(0.25, 0.45, 0.8), Color(0.12, 0.15, 0.35)))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	root.add_child(UIStyle.label("SALA: %s" % NetworkManager.room_name, 46, UIStyle.YELLOW, 10))
	_info = UIStyle.label("", 18, Color(0.85, 0.95, 1.0), 3)
	root.add_child(_info)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	# ---- jogadores
	var pcard: PanelContainer = UIStyle.card()
	pcard.custom_minimum_size = Vector2(430, 0)
	row.add_child(pcard)
	var pcol := VBoxContainer.new()
	pcard.add_child(pcol)
	pcol.add_child(UIStyle.label("Jogadores", 28, Color.WHITE, 6))
	_players_box = VBoxContainer.new()
	_players_box.add_theme_constant_override("separation", 6)
	pcol.add_child(_players_box)

	# ---- meu piloto + prévia
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	_preview = KartPreview.new()
	_preview.custom_minimum_size = Vector2(380, 240)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(_preview)
	_racer_opt = OptionButton.new()
	_racer_opt.custom_minimum_size = Vector2(360, 52)
	_racer_opt.add_theme_font_size_override("font_size", 22)
	for r in Global.racers:
		_racer_opt.add_item(r.display_name)
	var my: String = Global.selected_racer.id if Global.selected_racer != null else Global.racers[0].id
	for i in Global.racers.size():
		if Global.racers[i].id == my:
			_racer_opt.select(i)
	_racer_opt.item_selected.connect(_on_racer)
	mid.add_child(UIStyle.label("Seu piloto", 22, Color.WHITE, 4))
	mid.add_child(_racer_opt)

	# ---- configurações da corrida
	var scard: PanelContainer = UIStyle.card()
	row.add_child(scard)
	var scol := VBoxContainer.new()
	scol.add_theme_constant_override("separation", 8)
	scard.add_child(scol)
	scol.add_child(UIStyle.label("Corrida", 28, Color.WHITE, 6))
	_mode_opt = _option(scol, "Modo", ["Corrida", "Batalha de Balões"])
	(_mode_opt.get_parent() as Control).visible = false # batalha ainda é só offline
	var tracks: Array[String] = []
	for i in TrackCatalog.count():
		tracks.append(TrackCatalog.track_name(i))
	_track_opt = _option(scol, "Pista", tracks)
	_laps_opt = _option(scol, "Voltas", ["3", "5", "7"])
	var editable: bool = NetworkManager.is_host and not NetworkManager.dedicated
	for o in [_mode_opt, _track_opt, _laps_opt]:
		(o as OptionButton).disabled = not editable
		(o as OptionButton).item_selected.connect(_on_settings_changed)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	root.add_child(bottom)
	var leave: Button = UIStyle.button("SAIR DA SALA", 24, Vector2(260, 58))
	leave.pressed.connect(_leave)
	bottom.add_child(leave)
	_start_btn = UIStyle.button("INICIAR CORRIDA", 28, Vector2(340, 58))
	_start_btn.pressed.connect(NetworkManager.start_race)
	bottom.add_child(_start_btn)
	_ready_btn = UIStyle.button("PRONTO", 28, Vector2(260, 58))
	_ready_btn.toggle_mode = true
	_ready_btn.toggled.connect(func(on: bool) -> void: NetworkManager.set_ready(on))
	bottom.add_child(_ready_btn)
	_start_btn.visible = NetworkManager.is_host and not NetworkManager.dedicated
	_ready_btn.visible = NetworkManager.dedicated or not NetworkManager.is_host

	NetworkManager.lobby_updated.connect(_refresh)
	NetworkManager.disconnected_from_host.connect(_on_host_gone)
	_on_racer(_racer_opt.selected)
	_refresh()
	_start_btn.grab_focus()


func _exit_tree() -> void:
	if NetworkManager.lobby_updated.is_connected(_refresh):
		NetworkManager.lobby_updated.disconnect(_refresh)
	if NetworkManager.disconnected_from_host.is_connected(_on_host_gone):
		NetworkManager.disconnected_from_host.disconnect(_on_host_gone)


func _option(parent: Control, label: String, items: Array[String]) -> OptionButton:
	var r := HBoxContainer.new()
	var l: Label = UIStyle.label(label, 22, Color.WHITE, 4)
	l.custom_minimum_size = Vector2(110, 0)
	r.add_child(l)
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(300, 50)
	o.add_theme_font_size_override("font_size", 20)
	for it in items:
		o.add_item(it)
	r.add_child(o)
	parent.add_child(r)
	return o


func _on_racer(i: int) -> void:
	var stats: RacerStats = Global.racers[i]
	Global.select_racer(stats)
	_preview.set_racer(stats)
	NetworkManager.set_my_racer(stats.id)


func _on_settings_changed(_i: int) -> void:
	if _updating:
		return
	NetworkManager.set_settings({
		"battle": false,
		"track": _track_opt.selected,
		"laps": int(_laps_opt.get_item_text(_laps_opt.selected)),
	})


func _refresh() -> void:
	for c in _players_box.get_children():
		c.queue_free()
	for id in NetworkManager.players:
		var p: Dictionary = NetworkManager.players[id]
		var racer: RacerStats = Global.get_racer(str(p["racer"]))
		var tag: String = " (anfitrião)" if int(id) == 1 else ""
		var ready_mark: String = "  [PRONTO]" if bool(p["ready"]) and (NetworkManager.dedicated or int(id) != 1) else ""
		var me: bool = int(id) == NetworkManager.my_id()
		_players_box.add_child(UIStyle.label("%s - %s%s%s" % [str(p["name"]), racer.display_name, tag, ready_mark],
			22, UIStyle.YELLOW if me else Color.WHITE, 4))
	if NetworkManager.players.is_empty():
		_players_box.add_child(UIStyle.label("Aguardando jogadores...", 20, Color(0.8, 0.8, 0.8), 3))
	var s: Dictionary = NetworkManager.settings
	_updating = true
	_mode_opt.select(0)
	_track_opt.select(clampi(int(s["track"]), 0, TrackCatalog.count() - 1))
	for i in _laps_opt.item_count:
		if int(_laps_opt.get_item_text(i)) == int(s["laps"]):
			_laps_opt.select(i)
	_updating = false
	_track_opt.disabled = (not NetworkManager.is_host) or NetworkManager.dedicated
	_laps_opt.disabled = _track_opt.disabled
	var ips: PackedStringArray = NetworkManager.local_addresses()
	if NetworkManager.is_host:
		_info.text = "Amigos na mesma rede veem a sala sozinhos. Endereço: %s  (porta %d)" % [", ".join(ips) if not ips.is_empty() else "?", NetworkManager.PORT]
	elif NetworkManager.dedicated or not NetworkManager.is_host:
		_info.text = "Conectado. Aguarde o anfitrião iniciar a corrida." if not _ready_btn.visible else "Marque PRONTO quando quiser começar."
	if _start_btn.visible:
		_start_btn.disabled = false


func _leave() -> void:
	NetworkManager.leave()
	Global.goto_online()


func _on_host_gone() -> void:
	Global.goto_online()
