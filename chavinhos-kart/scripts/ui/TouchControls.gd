class_name TouchControls
extends Control
## Controles de toque (tablet/celular): injeta as mesmas ações do Input Map usadas no teclado.
## Multitoque: cada botão trata o próprio dedo, então dá para virar e acelerar ao mesmo tempo.
## Fica oculto até detectar uma tela de toque (ou o primeiro toque).

signal pause_pressed

var _buttons: Array[TouchButton] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# esquerda: volante
	_add("◀", "steer_left", 30, 40, 180, false)
	_add("▶", "steer_right", 230, 40, 180, false)
	_add("VOLTAR", "reset_kart", 30, 240, 100, false, 18)
	# direita: pedais e ações
	_add("ACEL", "accelerate", 30, 30, 200, true)
	_add("FREIO", "brake", 250, 30, 150, true)
	_add("DRIFT", "drift", 30, 250, 150, true)
	_add("ITEM", "use_item", 200, 215, 130, true, 24)
	var pause: TouchButton = _add("II", "", 20, 0, 80, true, 34)
	pause.from_top = 150.0
	pause.tapped.connect(func() -> void: pause_pressed.emit())
	get_viewport().size_changed.connect(_layout)
	_layout()
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


## Posiciona os botões em coordenadas absolutas da tela (independe do tamanho do pai).
func _layout() -> void:
	var vs: Vector2 = get_viewport_rect().size
	for b in _buttons:
		var x: float = vs.x - b.margin - b.size_px if b.right_side else b.margin
		var y: float = b.from_top if b.from_top >= 0.0 else vs.y - b.bottom - b.size_px
		b.position = Vector2(x, y)
		b.size = Vector2(b.size_px, b.size_px)


func _input(event: InputEvent) -> void:
	if not visible and event is InputEventScreenTouch:
		visible = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		for b in _buttons:
			b.release()


func _add(text: String, action: String, margin: float, bottom: float, size_px: float, right_side: bool, font: int = 28) -> TouchButton:
	var b := TouchButton.new()
	b.action = action
	b.label_text = text
	b.font_size = font
	b.margin = margin
	b.bottom = bottom
	b.size_px = size_px
	b.right_side = right_side
	add_child(b)
	_buttons.append(b)
	return b


## Botão redondo que mantém a ação do Input pressionada enquanto o dedo estiver sobre ele.
class TouchButton extends Control:
	signal tapped

	var action: String = ""
	var label_text: String = ""
	var font_size: int = 28
	var margin: float = 0.0
	var bottom: float = 0.0
	var size_px: float = 100.0
	var right_side: bool = true
	var from_top: float = -1.0
	var _touch_index: int = -99
	var _down: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var t: InputEventScreenTouch = event
			if t.pressed and not _down:
				_touch_index = t.index
				_set_down(true)
			elif not t.pressed and t.index == _touch_index:
				_set_down(false)
			accept_event()
		elif event is InputEventMouseButton:
			# mouse (e toque emulado como mouse): só vale se não houver toque nativo ativo
			var m: InputEventMouseButton = event
			if m.button_index == MOUSE_BUTTON_LEFT:
				if m.pressed and not _down:
					_touch_index = -1
					_set_down(true)
				elif not m.pressed and _touch_index == -1:
					_set_down(false)
				accept_event()

	func _set_down(v: bool) -> void:
		if _down == v:
			return
		_down = v
		if action != "":
			if v:
				Input.action_press(action, 1.0)
			else:
				Input.action_release(action)
		elif v:
			tapped.emit()
		queue_redraw()

	func release() -> void:
		_set_down(false)

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var col: Color = Color(1.0, 0.85, 0.3, 0.7) if _down else Color(0.1, 0.06, 0.02, 0.45)
		draw_circle(c, minf(size.x, size.y) * 0.5, col)
		draw_arc(c, minf(size.x, size.y) * 0.5 - 2.0, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 4.0, true)
		var font: Font = ThemeDB.fallback_font
		var ts: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(c.x - ts.x * 0.5, c.y + ts.y * 0.3), label_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE if not _down else Color(0.2, 0.1, 0.0))
