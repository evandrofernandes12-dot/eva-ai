class_name HUDController
extends CanvasLayer
## HUD de corrida: posição, voltas/balões, tempo, item, velocímetro, drift, minimapa, ranking ao vivo,
## meta do desafio, contagem regressiva, mensagens e menu de pausa (com opções).

var game: GameManager
var player: KartController
var lap_manager: LapManager
var battle: BattleManager

var _place_label: Label
var _place_sub: Label
var _lap_label: Label
var _time_label: Label
var _best_label: Label
var _goal_label: Label
var _speed_label: Label
var _speed_bar: ProgressBar
var _drift_bar: ProgressBar
var _item_icon: ItemIcon
var _item_name: Label
var _pips: Pips
var _center_label: Label
var _msg_label: Label
var _wrong_way: Label
var _minimap: MiniMap
var _pause_panel: Control
var _msg_tween: Tween
var _touch: TouchControls
var _top_left: VBoxContainer
var _top_center: VBoxContainer
var _top_right: VBoxContainer
var _speed_box: VBoxContainer
var _info_box: VBoxContainer
var _board_rows: Array[Label] = []
var _touch_layout: bool = false
var _board_t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_ui()


func bind(g: GameManager) -> void:
	game = g
	player = g.player
	lap_manager = g.lap_manager
	battle = g.battle
	_minimap.setup(g)
	if g.online:
		var rb: Node = _pause_panel.find_child("Restart", true, false)
		if rb != null:
			(rb as Control).visible = false
	if battle != null:
		battle.countdown_tick.connect(_on_countdown)
		battle.balloon_popped.connect(_on_balloon_popped)
		battle.kart_eliminated.connect(_on_eliminated)
		battle.battle_finished.connect(func(_r: Array) -> void: _flash("FIM DA BATALHA!", UIStyle.YELLOW, 3.0))
		_pips.visible = true
		_best_label.visible = false
	else:
		lap_manager.countdown_tick.connect(_on_countdown)
		lap_manager.lap_completed.connect(_on_lap_completed)
		lap_manager.final_lap.connect(_on_final_lap)
		lap_manager.kart_finished.connect(_on_kart_finished)
	if g.challenge_tracker != null:
		g.challenge_tracker.progress_changed.connect(func(t: String) -> void: _goal_label.text = t)
		_goal_label.text = g.challenge_tracker.progress_text()
	_goal_label.visible = g.challenge_tracker != null


# ===================================================================== construção

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# ---- linha superior
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top)

	_top_left = VBoxContainer.new()
	_top_left.custom_minimum_size = Vector2(300, 0)
	top.add_child(_top_left)
	var place_row := HBoxContainer.new()
	place_row.add_theme_constant_override("separation", 6)
	_top_left.add_child(place_row)
	_place_label = UIStyle.label("1º", 84, UIStyle.YELLOW, 14)
	place_row.add_child(_place_label)
	_place_sub = UIStyle.label("/8", 36, Color.WHITE, 8)
	_place_sub.size_flags_vertical = Control.SIZE_SHRINK_END
	place_row.add_child(_place_sub)
	_pips = Pips.new()
	_pips.custom_minimum_size = Vector2(140, 34)
	_pips.visible = false
	_top_left.add_child(_pips)

	top.add_child(_expander())
	_top_center = VBoxContainer.new()
	_top_center.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(_top_center)
	_item_icon = ItemIcon.new()
	_item_icon.custom_minimum_size = Vector2(100, 100)
	_top_center.add_child(_item_icon)
	_item_name = UIStyle.label("", 16, Color.WHITE, 5)
	_item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_center.add_child(_item_name)
	top.add_child(_expander())

	_top_right = VBoxContainer.new()
	_top_right.custom_minimum_size = Vector2(300, 0)
	top.add_child(_top_right)
	var info_card: PanelContainer = UIStyle.card(Color(0.08, 0.05, 0.02, 0.7), Color(0.9, 0.65, 0.2))
	_top_right.add_child(info_card)
	var info := VBoxContainer.new()
	_info_box = info
	info_card.add_child(info)
	_lap_label = UIStyle.label("Volta 1/3", 38, Color.WHITE, 8)
	_lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(_lap_label)
	_time_label = UIStyle.label("0:00.000", 26, Color(0.95, 0.95, 0.8), 6)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(_time_label)
	_best_label = UIStyle.label("", 18, Color(0.7, 1.0, 0.7), 4)
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(_best_label)
	_goal_label = UIStyle.label("", 18, Color(1.0, 0.85, 0.4), 4)
	_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_label.custom_minimum_size = Vector2(280, 0)
	_goal_label.visible = false
	_top_right.add_child(_goal_label)
	for i in 5: # ranking ao vivo
		var row: Label = UIStyle.label("", 18, Color.WHITE, 4)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_top_right.add_child(row)
		_board_rows.append(row)

	vbox.add_child(_expander(true))

	# ---- linha inferior
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom)
	_minimap = MiniMap.new()
	_minimap.custom_minimum_size = Vector2(220, 220)
	bottom.add_child(_minimap)
	bottom.add_child(_expander())
	_speed_box = VBoxContainer.new()
	_speed_box.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_child(_speed_box)
	_speed_label = UIStyle.label("0 km/h", 40, Color.WHITE, 9)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_speed_box.add_child(_speed_label)
	_speed_bar = ProgressBar.new()
	_speed_bar.custom_minimum_size = Vector2(280, 18)
	_speed_bar.show_percentage = false
	_speed_bar.max_value = 1.0
	_speed_box.add_child(_speed_bar)
	_drift_bar = ProgressBar.new()
	_drift_bar.custom_minimum_size = Vector2(280, 12)
	_drift_bar.show_percentage = false
	_drift_bar.max_value = 3.0
	_speed_box.add_child(_drift_bar)

	# ---- mensagens centrais
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(col)
	_center_label = UIStyle.label("", 180, UIStyle.YELLOW, 24)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.pivot_offset = Vector2(100, 120)
	col.add_child(_center_label)
	_msg_label = UIStyle.label("", 54, Color.WHITE, 12)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_msg_label)
	_wrong_way = UIStyle.label("CONTRAMÃO!", 64, Color(1.0, 0.2, 0.15), 14)
	_wrong_way.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wrong_way.visible = false
	col.add_child(_wrong_way)

	_build_pause_menu()

	_touch = TouchControls.new()
	_touch.visibility_changed.connect(_apply_touch_layout)
	_touch.pause_pressed.connect(_toggle_pause)
	add_child(_touch)
	move_child(_touch, _pause_panel.get_index())
	_apply_touch_layout()


## No toque os botões ocupam os cantos de baixo: minimapa e velocidade sobem para o topo.
func _apply_touch_layout() -> void:
	var want: bool = _touch.visible
	if want == _touch_layout:
		return
	_touch_layout = want
	if want:
		_minimap.reparent(_top_left)
		_minimap.custom_minimum_size = Vector2(150, 150)
		_speed_label.reparent(_info_box)
		_speed_label.add_theme_font_size_override("font_size", 24)
		for row in _board_rows: # o ranking ficaria embaixo dos botões
			row.visible = false
		_speed_bar.visible = false
		_drift_bar.reparent(_top_center)
	else:
		_minimap.custom_minimum_size = Vector2(220, 220)


func _expander(vertical: bool = false) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if vertical:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _build_pause_menu() -> void:
	_pause_panel = Control.new()
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.visible = false
	add_child(_pause_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(cc)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	cc.add_child(box)
	box.add_child(UIStyle.label("PAUSADO", 72, UIStyle.YELLOW, 12))
	var resume: Button = UIStyle.button("CONTINUAR")
	resume.pressed.connect(_toggle_pause)
	box.add_child(resume)
	var opt: Button = UIStyle.button("OPÇÕES")
	opt.pressed.connect(_open_options)
	box.add_child(opt)
	var restart: Button = UIStyle.button("REINICIAR CORRIDA")
	restart.pressed.connect(Global.goto_race)
	restart.name = "Restart"
	box.add_child(restart)
	var quit: Button = UIStyle.button("MENU PRINCIPAL")
	quit.pressed.connect(_quit_to_menu)
	box.add_child(quit)


func _open_options() -> void:
	var panel := OptionsPanel.new()
	panel.closed.connect(func() -> void: _touch.refresh())
	add_child(panel)


func _quit_to_menu() -> void:
	if game != null and game.online:
		NetworkManager.leave()
	Global.goto_menu()


# ===================================================================== atualização

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	var now: bool = not _pause_panel.visible
	_pause_panel.visible = now
	if game == null or not game.online:
		get_tree().paused = now # online não congela o jogo dos outros
	if now:
		AudioManager.set_engine(0.0, false)
	if now:
		for child in _pause_panel.find_children("*", "Button", true, false):
			(child as Button).grab_focus()
			break


func _process(delta: float) -> void:
	if player == null:
		return
	var total: int = game.karts.size()
	_place_label.text = "%dº" % player.place
	_place_sub.text = "/%d" % total
	var kmh: int = int(player.speed_kmh())
	_speed_label.text = "%d km/h" % kmh
	_speed_bar.value = clampf(absf(player.speed) / (player.stats.max_speed * 1.3), 0.0, 1.0)

	if battle != null:
		_lap_label.text = "Vivos: %d" % battle.alive_count()
		var t: int = int(ceilf(battle.time_left))
		_time_label.text = "%d:%02d" % [t / 60, t % 60]
		_pips.count = int(battle.balloons.get(player, 0))
		_pips.queue_redraw()
	elif lap_manager != null:
		_lap_label.text = "Volta %d/%d" % [player.current_lap, game.total_laps]
		_time_label.text = Global.format_time(lap_manager.race_time)

	_drift_bar.visible = player.drifting
	if player.drifting:
		_drift_bar.value = minf(player.drift_time, 3.0)
		match player.drift_level:
			1: _drift_bar.modulate = Color(0.4, 0.7, 1.0)
			2: _drift_bar.modulate = Color(1.0, 0.55, 0.15)
			3: _drift_bar.modulate = Color(0.85, 0.4, 1.0)
			_: _drift_bar.modulate = Color.WHITE

	# item (com "roleta" enquanto sorteia)
	if player.item_rolling:
		_item_icon.item = int(Time.get_ticks_msec() / 90) % 5 + 1
		_item_name.text = "..."
	else:
		_item_icon.item = player.held_item
		_item_name.text = ItemDefs.item_name(player.held_item)
	_item_icon.queue_redraw()

	# contramão (só em pistas com percurso)
	var wrong: bool = false
	if player.path != null and player.speed > 3.0 and not player.finished:
		var tg: Vector3 = player.path.tangent_at(player.path_dist)
		wrong = (-player.global_transform.basis.z).dot(tg) < -0.3
	_wrong_way.visible = wrong and int(Time.get_ticks_msec() / 300) % 2 == 0

	_board_t -= delta
	if _board_t <= 0.0:
		_board_t = 0.25
		_update_board()


func _update_board() -> void:
	var order: Array[KartController] = []
	order.append_array(game.karts)
	order.sort_custom(func(a: KartController, b: KartController) -> bool: return a.place < b.place)
	var shown: Array[KartController] = []
	for i in mini(5, order.size()):
		shown.append(order[i])
	if not shown.has(player) and not shown.is_empty():
		shown[shown.size() - 1] = player
	for i in _board_rows.size():
		if i < shown.size():
			var k: KartController = shown[i]
			_board_rows[i].text = "%d. %s" % [k.place, k.stats.display_name]
			_board_rows[i].add_theme_color_override("font_color", UIStyle.YELLOW if k == player else Color.WHITE)
		else:
			_board_rows[i].text = ""


# ===================================================================== eventos

func _on_countdown(value: int) -> void:
	_center_label.text = str(value) if value > 0 else "VAI!"
	_center_label.scale = Vector2(1.6, 1.6)
	_center_label.modulate = Color.WHITE
	var tw: Tween = create_tween()
	tw.tween_property(_center_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if value == 0:
		tw.tween_interval(0.6)
		tw.tween_property(_center_label, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func() -> void: _center_label.text = "")


func _on_lap_completed(kart: KartController, lap: int, lap_time: float) -> void:
	if not kart.is_player:
		return
	_best_label.text = "Melhor: %s" % Global.format_time(kart.best_lap)
	if lap < game.total_laps:
		_flash("VOLTA %d  %s" % [lap, Global.format_time(lap_time)], Color(0.8, 1.0, 0.8))


func _on_final_lap(kart: KartController) -> void:
	if kart.is_player:
		_flash("ÚLTIMA VOLTA!", Color(1.0, 0.5, 0.2))


func _on_kart_finished(kart: KartController, place: int, _time: float) -> void:
	if kart.is_player:
		_flash("CHEGOU! %dº LUGAR" % place, UIStyle.YELLOW, 3.5)


func _on_balloon_popped(kart: KartController, remaining: int) -> void:
	if kart.is_player:
		_flash("Estourou um balão! Restam %d" % remaining, Color(1.0, 0.5, 0.4), 1.5)


func _on_eliminated(kart: KartController) -> void:
	if kart.is_player:
		_flash("VOCÊ FOI ELIMINADO!", Color(1.0, 0.3, 0.2), 3.0)
	else:
		_flash("%s foi eliminado!" % kart.stats.display_name, Color(0.9, 1.0, 0.7), 1.8)


func _flash(text: String, color: Color, hold: float = 1.8) -> void:
	_msg_label.text = text
	_msg_label.modulate = color
	if _msg_tween != null:
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(hold)
	_msg_tween.tween_callback(func() -> void: _msg_label.text = "")


# ===================================================================== widgets internos

## Ícone do item: moldura arredondada + formas simples desenhadas com _draw (sem texturas).
class ItemIcon extends Control:
	var item: int = 0

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.05, 0.02, 0.65)
		sb.border_color = Color(1.0, 0.85, 0.35, 0.95) if item != 0 else Color(1, 1, 1, 0.5)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(18)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		match item:
			ItemDefs.Type.SANDUICHE:
				draw_rect(Rect2(c.x - 32, c.y - 18, 64, 12), Color(0.85, 0.6, 0.3))
				draw_rect(Rect2(c.x - 34, c.y - 6, 68, 6), Color(0.3, 0.7, 0.25))
				draw_rect(Rect2(c.x - 34, c.y, 68, 8), Color(0.95, 0.55, 0.6))
				draw_rect(Rect2(c.x - 30, c.y + 8, 60, 5), Color(1.0, 0.85, 0.3))
				draw_rect(Rect2(c.x - 32, c.y + 13, 64, 12), Color(0.8, 0.55, 0.28))
			ItemDefs.Type.BOLA_QUADRADA:
				draw_rect(Rect2(c.x - 27, c.y - 27, 18, 54), Color(0.9, 0.2, 0.2))
				draw_rect(Rect2(c.x - 9, c.y - 27, 18, 54), Color(0.95, 0.8, 0.15))
				draw_rect(Rect2(c.x + 9, c.y - 27, 18, 54), Color(0.2, 0.4, 0.9))
			ItemDefs.Type.BALDE:
				draw_colored_polygon(PackedVector2Array([
					Vector2(c.x - 24, c.y - 22), Vector2(c.x + 24, c.y - 22),
					Vector2(c.x + 17, c.y + 26), Vector2(c.x - 17, c.y + 26)]), Color(0.65, 0.68, 0.72))
				draw_rect(Rect2(c.x - 22, c.y - 26, 44, 9), Color(0.3, 0.6, 0.95))
			ItemDefs.Type.BARRIL:
				draw_rect(Rect2(c.x - 24, c.y - 28, 48, 56), Color(0.5, 0.3, 0.14))
				draw_rect(Rect2(c.x - 25, c.y - 18, 50, 7), Color(0.15, 0.15, 0.17))
				draw_rect(Rect2(c.x - 25, c.y + 10, 50, 7), Color(0.15, 0.15, 0.17))
			ItemDefs.Type.CHINELO:
				draw_set_transform(c, 0.0, Vector2(0.6, 1.0))
				draw_circle(Vector2.ZERO, 28.0, Color(0.2, 0.55, 0.85))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_rect(Rect2(c.x - 14, c.y - 6, 28, 8), Color(0.95, 0.92, 0.92))
			_:
				pass


## Balões restantes (Batalha).
class Pips extends Control:
	var count: int = 3

	func _draw() -> void:
		for i in 3:
			var p := Vector2(18.0 + 36.0 * float(i), 17.0)
			var on: bool = i < count
			draw_circle(p, 14.0, Color(0.05, 0.05, 0.08, 0.9))
			draw_circle(p, 11.0, Color(0.95, 0.3, 0.35) if on else Color(0.3, 0.3, 0.3, 0.6))


## Minimapa: contorno da pista + pontinhos dos karts.
class MiniMap extends Control:
	var _game: GameManager
	var _path: TrackPath
	var _min: Vector2 = Vector2.ZERO
	var _extent: float = 1.0

	func setup(g: GameManager) -> void:
		_game = g
		var path: TrackPath = g.track.path
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for p in path.points:
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
		_min = lo
		var extent: Vector2 = hi - lo
		_extent = maxf(maxf(extent.x, extent.y), 1.0)
		_path = path

	func _to_map(p: Vector3) -> Vector2:
		var sc: float = (minf(size.x, size.y) - 24.0) / _extent
		return (Vector2(p.x, p.z) - _min) * sc + Vector2(12, 12)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.35)
		sb.set_corner_radius_all(16)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		if _path == null:
			return
		var pts := PackedVector2Array()
		for p in _path.points:
			pts.append(_to_map(p))
		pts.append(pts[0])
		draw_polyline(pts, Color(0.05, 0.05, 0.08, 0.9), 12.0, true)
		draw_polyline(pts, Color(0.95, 0.85, 0.5), 6.0, true)
		if _game == null:
			return
		for k in _game.karts:
			if k.is_player or k.eliminated:
				continue
			var pos: Vector2 = _to_map(k.global_position)
			draw_circle(pos, 6.0, Color(0.1, 0.1, 0.1))
			draw_circle(pos, 4.5, k.stats.body_color.lightened(0.2))
		if _game.player != null:
			var pp: Vector2 = _to_map(_game.player.global_position)
			draw_circle(pp, 9.0, Color.WHITE)
			draw_circle(pp, 6.5, UIStyle.YELLOW)
