class_name OptionsPanel
extends Control
## Painel de opções (volume, controles de toque, nome do jogador). Usado no menu e na pausa.

signal closed

var _name_edit: LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var card: PanelContainer = UIStyle.card(Color(0.12, 0.07, 0.03, 0.97))
	cc.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	col.add_child(UIStyle.label("OPÇÕES", 46, UIStyle.YELLOW, 8))

	col.add_child(_row("Seu nome", _make_name()))
	col.add_child(_row("Volume geral", _make_slider("vol_master", 0.9, 0.0, 1.0)))
	col.add_child(_row("Volume efeitos", _make_slider("vol_sfx", 1.0, 0.0, 1.0)))
	col.add_child(_row("Som do motor", _make_slider("vol_engine", 0.6, 0.0, 1.0)))

	var mode := OptionButton.new()
	mode.custom_minimum_size = Vector2(320, 48)
	mode.add_item("Automático (só em telas de toque)", 0)
	mode.add_item("Sempre mostrar", 1)
	mode.add_item("Nunca mostrar", 2)
	mode.select(int(Save.get_setting("touch_mode", 0)))
	mode.item_selected.connect(func(i: int) -> void: Save.set_setting("touch_mode", i))
	col.add_child(_row("Botões de toque", mode))
	col.add_child(_row("Tamanho dos botões", _make_slider("touch_scale", 1.0, 0.7, 1.4)))
	col.add_child(_row("Opacidade dos botões", _make_slider("touch_alpha", 1.0, 0.3, 1.0)))

	var back: Button = UIStyle.button("VOLTAR", 28, Vector2(260, 58))
	back.pressed.connect(_close)
	col.add_child(back)
	back.grab_focus()


func _row(text: String, control: Control) -> HBoxContainer:
	var r := HBoxContainer.new()
	var l: Label = UIStyle.label(text, 22, Color.WHITE, 4)
	l.custom_minimum_size = Vector2(260, 0)
	r.add_child(l)
	r.add_child(control)
	return r


func _make_name() -> LineEdit:
	_name_edit = LineEdit.new()
	_name_edit.text = Save.player_name()
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(320, 48)
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.text_changed.connect(func(t: String) -> void: Save.set_setting("player_name", t if t != "" else "Jogador"))
	return _name_edit


func _make_slider(key: String, default_v: float, lo: float, hi: float) -> HSlider:
	var s: HSlider = UIStyle.slider(lo, hi, float(Save.get_setting(key, default_v)))
	s.value_changed.connect(func(v: float) -> void:
		Save.set_setting(key, v)
		AudioManager.apply_settings())
	return s


func _close() -> void:
	closed.emit()
	queue_free()
