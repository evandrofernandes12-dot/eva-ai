class_name MenuController
extends Control
## Menu principal: modos de jogo (Corrida, Copa, Batalha, Desafios, Online), opções e controles.

var _controls_panel: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UIStyle.gradient_bg(Color(0.98, 0.72, 0.35), Color(0.5, 0.25, 0.14)))

	var preview := KartPreview.new()
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.offset_left = 560.0
	preview.offset_top = 90.0
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	preview.set_racer(Global.selected_racer if Global.selected_racer != null else Global.racers[0])

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.add_theme_constant_override("margin_right", 40)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title: Label = UIStyle.label("CHAVINHO'S KART", 76, UIStyle.YELLOW, 16)
	box.add_child(title)
	box.add_child(UIStyle.label("Corrida maluca pela Vila!", 26, Color.WHITE, 7))
	box.add_child(UIStyle.label("Ouro %d  ·  Prata %d  ·  Bronze %d  ·  Desafios %d/%d" % [
		Save.trophy_count("gold"), Save.trophy_count("silver"), Save.trophy_count("bronze"),
		Save.challenges_done_count(), ChallengeDefs.LIST.size()], 18, Color(1, 1, 0.85), 4))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap)

	var first: Button = _mode_button(box, "CORRIDA RÁPIDA", _go_mode.bind(Global.Mode.QUICK))
	_mode_button(box, "COPA DA VILA (4 pistas)", _go_mode.bind(Global.Mode.CUP))
	_mode_button(box, "BATALHA DE BALÕES", _go_mode.bind(Global.Mode.BATTLE))
	_mode_button(box, "DESAFIOS", _go_mode.bind(Global.Mode.CHALLENGE))
	_mode_button(box, "JOGAR ONLINE", Global.goto_online)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var opt: Button = UIStyle.button("OPÇÕES", 24, Vector2(150, 54))
	opt.pressed.connect(_open_options)
	row.add_child(opt)
	var ctl: Button = UIStyle.button("CONTROLES", 24, Vector2(170, 54))
	ctl.pressed.connect(_toggle_controls)
	row.add_child(ctl)
	var quit: Button = UIStyle.button("SAIR", 24, Vector2(110, 54))
	quit.pressed.connect(func() -> void: get_tree().quit())
	row.add_child(quit)

	_build_controls_panel()
	first.grab_focus()
	await get_tree().process_frame
	UIStyle.pulse(title, 0.025, 2.2)


func _mode_button(parent: Control, text: String, action: Callable) -> Button:
	var b: Button = UIStyle.button(text, 28, Vector2(420, 56))
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _go_mode(mode: int) -> void:
	Global.mode = mode
	if mode == Global.Mode.CHALLENGE:
		Global.goto_challenges()
	else:
		Global.goto_select()


func _open_options() -> void:
	add_child(OptionsPanel.new())


func _build_controls_panel() -> void:
	_controls_panel = Control.new()
	_controls_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.visible = false
	add_child(_controls_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.add_child(cc)
	var panel: PanelContainer = UIStyle.card(Color(0.12, 0.07, 0.03, 0.97))
	cc.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(UIStyle.label("CONTROLES", 44, UIStyle.YELLOW, 8))
	var lines: Array[String] = [
		"TECLADO:  W/↑ acelerar  ·  S/↓ frear  ·  A D/← → virar",
		"Espaço/Shift: drift (segure na curva, solte p/ mini-turbo)",
		"E/Enter: usar item  ·  R: voltar à pista  ·  Esc: pausa",
		"",
		"TOQUE (tablet/celular): botões na tela",
		"◀ ▶ virar  ·  ACEL / FREIO  ·  DRIFT  ·  ITEM  ·  VOLTAR  ·  II pausa",
		"Ajuste tamanho e opacidade em OPÇÕES.",
	]
	for line in lines:
		col.add_child(UIStyle.label(line, 22, Color.WHITE, 4))
	var back: Button = UIStyle.button("VOLTAR", 28, Vector2(240, 56))
	back.pressed.connect(_toggle_controls)
	col.add_child(back)


func _toggle_controls() -> void:
	_controls_panel.visible = not _controls_panel.visible
	if _controls_panel.visible:
		for b in _controls_panel.find_children("*", "Button", true, false):
			(b as Button).grab_focus()
			break
