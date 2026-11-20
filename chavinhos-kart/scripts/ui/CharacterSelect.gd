class_name CharacterSelect
extends Control
## Seleção de piloto: grade de personagens, prévia 3D giratória e barras de atributos.

var _preview: KartPreview
var _name_label: Label
var _desc_label: Label
var _bars: Dictionary = {}
var _buttons: Dictionary = {}
var _current: RacerStats


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UIStyle.gradient_bg(Color(0.35, 0.55, 0.85), Color(0.95, 0.75, 0.45)))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	root.add_child(UIStyle.label("ESCOLHA SEU PILOTO  -  %s" % _mode_title(), 52, UIStyle.YELLOW, 12))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 30)
	root.add_child(row)

	# ---- grade de pilotos
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	row.add_child(grid)
	for stats in Global.racers:
		var b: Button = UIStyle.button(stats.display_name, 20, Vector2(190, 84))
		b.focus_entered.connect(_select.bind(stats))
		b.mouse_entered.connect(_select.bind(stats))
		b.pressed.connect(_start.bind(stats))
		grid.add_child(b)
		_buttons[stats.id] = b

	# ---- painel direito: prévia + atributos
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	_preview = KartPreview.new()
	_preview.custom_minimum_size = Vector2(560, 300)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_preview)
	_name_label = UIStyle.label("", 46, Color.WHITE, 10)
	right.add_child(_name_label)
	_desc_label = UIStyle.label("", 22, Color(1, 1, 0.9), 5)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(540, 60)
	right.add_child(_desc_label)
	for key in ["Velocidade", "Aceleração", "Manobra", "Peso"]:
		var line := HBoxContainer.new()
		var key_label: Label = UIStyle.label(key, 22, Color.WHITE, 5)
		key_label.custom_minimum_size = Vector2(170, 0)
		line.add_child(key_label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(300, 22)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.max_value = 1.0
		line.add_child(bar)
		right.add_child(line)
		_bars[key] = bar

	var back: Button = UIStyle.button("VOLTAR", 24, Vector2(220, 56))
	back.pressed.connect(Global.goto_menu)
	root.add_child(back)

	var start_stats: RacerStats = Global.selected_racer if Global.selected_racer != null else Global.racers[0]
	_select(start_stats)
	(_buttons[start_stats.id] as Button).grab_focus()


func _select(stats: RacerStats) -> void:
	if stats == _current:
		return
	_current = stats
	_preview.set_racer(stats)
	_name_label.text = stats.display_name
	_desc_label.text = stats.description
	(_bars["Velocidade"] as ProgressBar).value = inverse_lerp(24.0, 32.0, stats.max_speed)
	(_bars["Aceleração"] as ProgressBar).value = inverse_lerp(10.0, 20.0, stats.acceleration)
	(_bars["Manobra"] as ProgressBar).value = inverse_lerp(1.5, 2.6, stats.handling)
	(_bars["Peso"] as ProgressBar).value = inverse_lerp(0.4, 1.7, stats.weight)


func _start(stats: RacerStats) -> void:
	Global.select_racer(stats)
	Global.after_character_select()


func _mode_title() -> String:
	if Global.mode == Global.Mode.CUP:
		return "COPA DA VILA"
	if Global.mode == Global.Mode.BATTLE:
		return "BATALHA DE BALÕES"
	if Global.mode == Global.Mode.CHALLENGE:
		return "DESAFIO: %s" % str(Global.challenge.get("title", ""))
	return "CORRIDA RÁPIDA"
