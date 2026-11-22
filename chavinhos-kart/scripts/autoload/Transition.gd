extends CanvasLayer
## Troca de cena com fade preto.

var _rect: ColorRect
var _busy: bool = false
var _rotate_hint: Control


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.04, 0.02, 0.0, 0.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_build_rotate_hint()


## Em celular de pé o jogo fica apertado: pede para girar o aparelho.
func _build_rotate_hint() -> void:
	_rotate_hint = ColorRect.new()
	(_rotate_hint as ColorRect).color = Color(0.08, 0.05, 0.02, 0.96)
	_rotate_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotate_hint.visible = false
	add_child(_rotate_hint)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotate_hint.add_child(cc)
	var l: Label = UIStyle.label("Gire o aparelho\npara a horizontal", 44, UIStyle.YELLOW, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cc.add_child(l)


func _process(_delta: float) -> void:
	if _rotate_hint == null:
		return
	var s: Vector2 = get_viewport().get_visible_rect().size
	_rotate_hint.visible = s.y > s.x * 1.05


func go(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw: Tween = create_tween()
	tw.tween_property(_rect, "color:a", 1.0, 0.2)
	await tw.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2: Tween = create_tween()
	tw2.tween_property(_rect, "color:a", 0.0, 0.25)
	await tw2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
