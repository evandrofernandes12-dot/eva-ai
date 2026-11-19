class_name MenuController
extends Control
## Menu principal: título, botões (Jogar / Controles / Sair) e kart do Chaves girando.

var _controls_panel: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UIStyle.gradient_bg(Color(0.98, 0.72, 0.35), Color(0.55, 0.28, 0.15)))

	var preview := KartPreview.new()
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.offset_left = 520.0
	preview.offset_top = 120.0
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	preview.set_racer(Global.racers[0] if not Global.racers.is_empty() else null)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := UIStyle.label("CHAVINHO'S KART", 88, UIStyle.YELLOW, 18)
	box.add_child(title)
	box.add_child(UIStyle.label("Corrida maluca pela Vila!", 32, Color.WHITE, 8))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	box.add_child(spacer)

	var play: Button = UIStyle.button("JOGAR", 34)
	play.pressed.connect(Global.goto_select)
	box.add_child(play)
	var controls: Button = UIStyle.button("CONTROLES", 30)
	controls.pressed.connect(_toggle_controls)
	box.add_child(controls)
	var quit: Button = UIStyle.button("SAIR", 30)
	quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit)

	var footer := UIStyle.label("Projeto de fã sem fins lucrativos - Godot 4", 16, Color(1, 1, 1, 0.8), 4)
	footer.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(60, 680)
	add_child(footer)

	_build_controls_panel()
	play.grab_focus()


func _build_controls_panel() -> void:
	_controls_panel = Control.new()
	_controls_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.visible = false
	add_child(_controls_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.add_child(cc)
	var panel: PanelContainer = UIStyle.panel(Color(0.12, 0.07, 0.03, 0.95))
	cc.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(UIStyle.label("CONTROLES", 44, UIStyle.YELLOW, 8))
	var lines: Array[String] = [
		"W / Seta ↑ ........ Acelerar",
		"S / Seta ↓ ........ Frear / Ré",
		"A D / Setas ← → .... Virar",
		"ESPAÇO / SHIFT ..... Drift (segure em curva; solte para o mini-turbo)",
		"E / ENTER .......... Usar item",
		"R .................. Voltar para a pista",
		"ESC ................ Pausar",
	]
	for line in lines:
		col.add_child(UIStyle.label(line, 24, Color.WHITE, 4))
	var back: Button = UIStyle.button("VOLTAR", 28, Vector2(240, 56))
	back.pressed.connect(_toggle_controls)
	col.add_child(back)


func _toggle_controls() -> void:
	_controls_panel.visible = not _controls_panel.visible
	if _controls_panel.visible:
		for b in _controls_panel.find_children("*", "Button", true, false):
			(b as Button).grab_focus()
			break
