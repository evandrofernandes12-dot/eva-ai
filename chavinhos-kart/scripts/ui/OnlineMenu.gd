class_name OnlineMenu
extends Control
## Menu online: criar sala, entrar numa sala encontrada na rede local ou digitar IP/endereço.

var _status: Label
var _rooms_box: VBoxContainer
var _ip_edit: LineEdit
var _busy: bool = false


func _ready() -> void:
	NetworkManager.leave()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UIStyle.gradient_bg(Color(0.2, 0.4, 0.75), Color(0.1, 0.18, 0.35)))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	root.add_child(UIStyle.label("JOGAR ONLINE", 56, UIStyle.YELLOW, 12))
	root.add_child(UIStyle.label("Você joga como: %s  (mude o nome em Opções)" % Save.player_name(), 20, Color.WHITE, 4))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	# ---- criar sala
	var left: PanelContainer = UIStyle.card()
	row.add_child(left)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 10)
	left.add_child(lcol)
	lcol.add_child(UIStyle.label("Criar sala", 30, Color.WHITE, 6))
	var info: Label = UIStyle.label("Seus amigos entram pela mesma rede Wi-Fi\n(a sala aparece sozinha na lista deles).", 18, Color(1, 1, 0.9), 3)
	lcol.add_child(info)
	var host: Button = UIStyle.button("CRIAR SALA", 28, Vector2(340, 62))
	host.pressed.connect(_host)
	lcol.add_child(host)
	lcol.add_child(UIStyle.label("Pela internet: use o IP público + porta UDP %d\n(ou uma VPN como Tailscale) e passe o endereço aos amigos." % NetworkManager.PORT, 16, Color(0.8, 0.9, 1.0), 3))

	# ---- entrar
	var right: PanelContainer = UIStyle.card()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", 8)
	right.add_child(rcol)
	rcol.add_child(UIStyle.label("Salas na rede local", 30, Color.WHITE, 6))
	_rooms_box = VBoxContainer.new()
	_rooms_box.custom_minimum_size = Vector2(480, 150)
	rcol.add_child(_rooms_box)
	rcol.add_child(UIStyle.label("Ou digite o endereço (IP, IP:porta ou ws://...)", 18, Color(1, 1, 0.9), 3))
	var ip_row := HBoxContainer.new()
	ip_row.add_theme_constant_override("separation", 8)
	rcol.add_child(ip_row)
	_ip_edit = LineEdit.new()
	_ip_edit.placeholder_text = "192.168.0.10"
	_ip_edit.text = str(Save.get_setting("last_ip", ""))
	_ip_edit.custom_minimum_size = Vector2(300, 52)
	_ip_edit.add_theme_font_size_override("font_size", 24)
	ip_row.add_child(_ip_edit)
	var join: Button = UIStyle.button("ENTRAR", 24, Vector2(160, 52))
	join.pressed.connect(func() -> void: _join(_ip_edit.text))
	ip_row.add_child(join)

	_status = UIStyle.label("", 22, Color(1.0, 0.85, 0.4), 5)
	root.add_child(_status)
	var back: Button = UIStyle.button("VOLTAR", 24, Vector2(220, 56))
	back.pressed.connect(Global.goto_menu)
	root.add_child(back)

	NetworkManager.rooms_updated.connect(_refresh_rooms)
	NetworkManager.connected_ok.connect(_on_connected)
	NetworkManager.connect_failed.connect(_on_failed)
	NetworkManager.start_discovery()
	_refresh_rooms()
	host.grab_focus()


func _exit_tree() -> void:
	NetworkManager.stop_discovery()
	if NetworkManager.rooms_updated.is_connected(_refresh_rooms):
		NetworkManager.rooms_updated.disconnect(_refresh_rooms)
	if NetworkManager.connected_ok.is_connected(_on_connected):
		NetworkManager.connected_ok.disconnect(_on_connected)
	if NetworkManager.connect_failed.is_connected(_on_failed):
		NetworkManager.connect_failed.disconnect(_on_failed)


func _refresh_rooms() -> void:
	for c in _rooms_box.get_children():
		c.queue_free()
	if NetworkManager.rooms.is_empty():
		_rooms_box.add_child(UIStyle.label("Procurando salas...", 20, Color(0.8, 0.8, 0.8), 3))
		return
	for ip in NetworkManager.rooms:
		var r: Dictionary = NetworkManager.rooms[ip]
		var b: Button = UIStyle.button("%s  (%d jogador(es))" % [str(r["name"]), int(r["count"])], 22, Vector2(460, 50))
		b.pressed.connect(_join.bind("%s:%d" % [str(ip), int(r["port"])]))
		_rooms_box.add_child(b)


func _host() -> void:
	if _busy:
		return
	var racer: RacerStats = Global.selected_racer if Global.selected_racer != null else Global.racers[0]
	var err: int = NetworkManager.host_game("", Save.player_name(), racer.id)
	if err != OK:
		_status.text = "Não foi possível criar a sala (porta %d em uso?)." % NetworkManager.PORT
		return
	Global.mode = Global.Mode.ONLINE
	Global.goto_lobby()


func _join(address: String) -> void:
	if _busy or address.strip_edges() == "":
		return
	_busy = true
	Save.set_setting("last_ip", address)
	var racer: RacerStats = Global.selected_racer if Global.selected_racer != null else Global.racers[0]
	var err: int = NetworkManager.join_game(address, Save.player_name(), racer.id)
	if err != OK:
		_busy = false
		_status.text = "Endereço inválido."
		return
	_status.text = "Conectando a %s ..." % address


func _on_connected() -> void:
	Global.mode = Global.Mode.ONLINE
	Global.goto_lobby()


func _on_failed() -> void:
	_busy = false
	_status.text = "Não consegui conectar. Verifique o endereço e se estão na mesma rede."
