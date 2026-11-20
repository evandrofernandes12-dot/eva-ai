class_name TrackSelect
extends Control
## Escolha da pista para a Corrida Rápida: contorno, descrição, melhor volta e nº de voltas.

var _preview: PathPreview
var _name_label: Label
var _desc_label: Label
var _best_label: Label
var _laps_opt: OptionButton
var _index: int = 0
var _buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UIStyle.gradient_bg(Color(0.3, 0.5, 0.8), Color(0.95, 0.7, 0.4)))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	root.add_child(UIStyle.label("ESCOLHA A PISTA", 56, UIStyle.YELLOW, 12))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 30)
	root.add_child(row)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	row.add_child(list)
	for i in TrackCatalog.count():
		var b: Button = UIStyle.button(TrackCatalog.track_name(i), 24, Vector2(430, 84))
		b.focus_entered.connect(_select.bind(i))
		b.mouse_entered.connect(_select.bind(i))
		b.pressed.connect(_start)
		list.add_child(b)
		_buttons.append(b)

	var card: PanelContainer = UIStyle.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	_preview = PathPreview.new()
	_preview.custom_minimum_size = Vector2(400, 250)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_preview)
	_name_label = UIStyle.label("", 38, Color.WHITE, 8)
	col.add_child(_name_label)
	_desc_label = UIStyle.label("", 20, Color(1, 1, 0.9), 4)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(400, 70)
	col.add_child(_desc_label)
	_best_label = UIStyle.label("", 22, Color(0.7, 1.0, 0.7), 4)
	col.add_child(_best_label)
	var laps_row := HBoxContainer.new()
	laps_row.add_child(UIStyle.label("Voltas: ", 24, Color.WHITE, 5))
	_laps_opt = OptionButton.new()
	_laps_opt.custom_minimum_size = Vector2(120, 46)
	for n in [3, 5, 7]:
		_laps_opt.add_item(str(n), n)
	laps_row.add_child(_laps_opt)
	col.add_child(laps_row)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	root.add_child(bottom)
	var back: Button = UIStyle.button("VOLTAR", 24, Vector2(220, 56))
	back.pressed.connect(Global.goto_select)
	bottom.add_child(back)
	var go: Button = UIStyle.button("CORRER!", 28, Vector2(260, 56))
	go.pressed.connect(_start)
	bottom.add_child(go)

	_select(0)
	_buttons[0].grab_focus()


func _select(i: int) -> void:
	_index = i
	var info: Dictionary = TrackCatalog.info(i)
	_name_label.text = str(info["name"])
	_desc_label.text = str(info["desc"])
	var best: float = Save.best_time(str(info["id"]))
	_best_label.text = "Melhor volta: %s" % Global.format_time(best) if best > 0.0 else "Melhor volta: --"
	_preview.set_points(TrackCatalog.preview_points(i))


func _start() -> void:
	Global.start_quick(_index, _laps_opt.get_selected_id())
