extends Control
## Direcional de toque. Escreve o vetor em `value` (-1..1).

var value := Vector2.ZERO
var _id := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# Usa _input (e não _gui_input) para o dedo continuar valendo mesmo fora do círculo.
func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed and _id == -1 and get_global_rect().grow(30).has_point(e.position):
			_id = e.index
			_move(e.position - global_position)
			get_viewport().set_input_as_handled()
		elif not e.pressed and e.index == _id:
			_release()
	elif e is InputEventScreenDrag and e.index == _id:
		_move(e.position - global_position)

func _notification(what: int) -> void:
	# se o app perder o foco ou o direcional sumir, solta o direcional
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		_release()

func _release() -> void:
	_id = -1
	value = Vector2.ZERO
	queue_redraw()

func _move(p: Vector2) -> void:
	var r := size.x * 0.5
	value = ((p - size * 0.5) / r).limit_length(1.0)
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5
	draw_circle(c, r, Color(0.08, 0.05, 0.02, 0.45))
	draw_arc(c, r - 2, 0, TAU, 48, Color(0.89, 0.75, 0.41, 0.9), 3.0)
	draw_circle(c + value * r * 0.55, r * 0.38, Color(0.54, 0.37, 0.19, 0.95))
