class_name TouchControls
extends Control
## Controles de toque (tablet/celular): injeta as mesmas ações do Input Map usadas no teclado.
## Multitoque: cada botão trata o próprio dedo, então dá para virar e acelerar ao mesmo tempo.
## Fica oculto até detectar uma tela de toque (ou o primeiro toque).

signal pause_pressed

var _buttons: Array[TouchButton] = []
var _steer_buttons: Array[TouchButton] = []
var _joystick: Joystick


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# esquerda: joystick invisível (aparece onde o dedo tocar) — criado primeiro para ficar por baixo dos botões
	_joystick = Joystick.new()
	add_child(_joystick)
	# ...ou botões de direção (opção "Botões" nas Opções)
	var left_b: TouchButton = _add("", "steer_left", 20, 24, 150, false)
	left_b.arrow = -1
	var right_b: TouchButton = _add("", "steer_right", 184, 24, 150, false)
	right_b.arrow = 1
	_steer_buttons = [left_b, right_b]
	_add("VOLTAR", "reset_kart", 20, 215, 78, false, 15)
	# direita: pedais e ações
	_add("ACEL", "accelerate", 20, 20, 150, true, 24)
	_add("FREIO", "brake", 184, 20, 112, true, 20)
	_add("DRIFT", "drift", 20, 186, 112, true, 20)
	_add("ITEM", "use_item", 148, 182, 98, true, 19)
	var pause: TouchButton = _add("II", "", 0, 0, 62, false, 24)
	pause.from_top = 20.0
	pause.center_x = true
	pause.tapped.connect(func() -> void: pause_pressed.emit())
	get_viewport().size_changed.connect(_layout)
	refresh()


## Reaplica as opções salvas (modo, tamanho e opacidade).
func refresh() -> void:
	var mode: int = int(Save.get_setting("touch_mode", 0))
	var auto_on: bool = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	visible = (mode == 1) or (mode == 0 and auto_on)
	modulate.a = float(Save.get_setting("touch_alpha", 1.0))
	var joystick_mode: bool = int(Save.get_setting("steer_mode", 0)) == 0
	_joystick.visible = joystick_mode
	for b in _steer_buttons:
		b.visible = not joystick_mode
		if joystick_mode:
			b.release()
	if not joystick_mode:
		_joystick.release()
	_layout()


## Posiciona os botões em coordenadas absolutas da tela (independe do tamanho do pai).
func _layout() -> void:
	var vs: Vector2 = get_viewport_rect().size
	var sc: float = float(Save.get_setting("touch_scale", 1.0))
	for b in _buttons:
		var sz: float = b.size_px * sc
		var x: float = vs.x - b.margin - sz if b.right_side else b.margin
		if b.center_x: # pausa: no topo, ao lado direito do ícone do item
			sz = b.size_px
			x = vs.x * 0.5 + 75.0
		var y: float = b.from_top if b.from_top >= 0.0 else vs.y - b.bottom * sc - sz
		b.position = Vector2(x, y)
		b.size = Vector2(sz, sz)
	# área do joystick: metade esquerda, abaixo do minimapa
	_joystick.position = Vector2(0, vs.y * 0.3)
	_joystick.size = Vector2(vs.x * 0.46, vs.y * 0.7)
	_joystick.radius = 78.0 * sc


func _input(event: InputEvent) -> void:
	if not visible and event is InputEventScreenTouch and int(Save.get_setting("touch_mode", 0)) != 2:
		visible = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		for b in _buttons:
			b.release()
		_joystick.release()


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
	var center_x: bool = false
	var arrow: int = 0 # -1 seta para a esquerda, 1 para a direita (desenhada, sem fonte)
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
		if arrow != 0:
			var r: float = minf(size.x, size.y) * 0.22
			var tip := Vector2(c.x + r * float(arrow), c.y)
			var back_x: float = c.x - r * 0.8 * float(arrow)
			var col_a: Color = Color.WHITE if not _down else Color(0.2, 0.1, 0.0)
			draw_colored_polygon(PackedVector2Array([tip, Vector2(back_x, c.y - r), Vector2(back_x, c.y + r)]), col_a)
			return
		var font: Font = ThemeDB.fallback_font
		var ts: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(c.x - ts.x * 0.5, c.y + ts.y * 0.3), label_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE if not _down else Color(0.2, 0.1, 0.0))



## Joystick flutuante: invisível até tocar; nasce onde o dedo encostou e vira o kart conforme o
## arraste para os lados (analógico: quanto mais longe, mais vira).
class Joystick extends Control:
	var radius: float = 78.0
	var _touch: int = -99
	var _center: Vector2 = Vector2.ZERO
	var _knob: Vector2 = Vector2.ZERO
	var _active: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var t: InputEventScreenTouch = event
			if t.pressed and not _active:
				_begin(t.index, t.position)
			elif not t.pressed and t.index == _touch:
				release()
			accept_event()
		elif event is InputEventScreenDrag:
			var d: InputEventScreenDrag = event
			if _active and d.index == _touch:
				_move(d.position)
			accept_event()
		elif event is InputEventMouseButton:
			# mouse / toque emulado como mouse (só se nenhum dedo já controla o joystick)
			var m: InputEventMouseButton = event
			if m.button_index == MOUSE_BUTTON_LEFT:
				if m.pressed and not _active:
					_begin(-1, m.position)
				elif not m.pressed and _touch == -1:
					release()
				accept_event()
		elif event is InputEventMouseMotion and _active and _touch == -1:
			_move((event as InputEventMouseMotion).position)

	func _begin(index: int, pos: Vector2) -> void:
		_touch = index
		_active = true
		_center = pos
		_knob = pos
		_apply()
		queue_redraw()

	func _move(pos: Vector2) -> void:
		var off: Vector2 = pos - _center
		if off.length() > radius * 1.6: # o centro acompanha o dedo se ele for longe demais
			_center = pos - off.normalized() * radius * 1.6
			off = pos - _center
		if off.length() > radius:
			off = off.normalized() * radius
		_knob = _center + off
		_apply()
		queue_redraw()

	func release() -> void:
		_active = false
		_touch = -99
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		queue_redraw()

	func _apply() -> void:
		var x: float = clampf((_knob.x - _center.x) / (radius * 0.8), -1.0, 1.0)
		if absf(x) < 0.12: # zona morta
			x = 0.0
		if x > 0.0:
			Input.action_press("steer_right", x)
			Input.action_release("steer_left")
		elif x < 0.0:
			Input.action_press("steer_left", -x)
			Input.action_release("steer_right")
		else:
			Input.action_release("steer_left")
			Input.action_release("steer_right")

	func _draw() -> void:
		if not _active:
			# dica bem discreta de onde tocar
			var hint := Vector2(radius + 30.0, size.y - radius - 30.0)
			draw_arc(hint, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.18), 3.0, true)
			_arrows(hint, Color(1, 1, 1, 0.22))
			return
		draw_circle(_center, radius, Color(0.08, 0.05, 0.02, 0.35))
		draw_arc(_center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.75), 4.0, true)
		_arrows(_center, Color(1, 1, 1, 0.6))
		draw_circle(_knob, radius * 0.42, Color(1.0, 0.85, 0.3, 0.85))
		draw_arc(_knob, radius * 0.42, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 3.0, true)

	func _arrows(c: Vector2, col: Color) -> void:
		var r: float = radius * 0.16
		for side: float in [-1.0, 1.0]:
			var tip := Vector2(c.x + side * radius * 0.82, c.y)
			var back: float = tip.x - side * r * 1.4
			draw_colored_polygon(PackedVector2Array([tip, Vector2(back, c.y - r), Vector2(back, c.y + r)]), col)
