class_name UIStyle
extends RefCounted
## Fábrica de widgets estilizados (labels com contorno, botões arredondados, fundo em degradê).

const YELLOW: Color = Color(1.0, 0.86, 0.2)
const BROWN: Color = Color(0.35, 0.2, 0.08)


static func label(text: String, size: int = 24, color: Color = Color.WHITE, outline: int = 6) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.0))
	l.add_theme_constant_override("outline_size", outline)
	return l


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(4)
	s.set_corner_radius_all(14)
	s.set_content_margin_all(10.0)
	return s


static func button(text: String, size: int = 28, min_size: Vector2 = Vector2(300, 64)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	b.add_theme_constant_override("outline_size", 6)
	b.add_theme_stylebox_override("normal", _box(Color(0.82, 0.5, 0.12), BROWN))
	b.add_theme_stylebox_override("hover", _box(Color(0.95, 0.65, 0.2), Color(1, 0.95, 0.7)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.65, 0.38, 0.08), BROWN))
	b.add_theme_stylebox_override("focus", _box(Color(0.95, 0.65, 0.2), Color.WHITE))
	b.pressed.connect(func() -> void: AudioManager.play_sfx("click"))
	return b


static func panel(bg: Color = Color(0.1, 0.06, 0.02, 0.8)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(bg, BROWN))
	return p


static func gradient_bg(top: Color, bottom: Color) -> TextureRect:
	var g := Gradient.new()
	g.colors = PackedColorArray([top, bottom])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect


## Cartão arredondado (lista de salas, desafios, etc.).
static func card(bg: Color = Color(0.16, 0.1, 0.05, 0.85), border: Color = Color(0.9, 0.65, 0.2)) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(16)
	s.set_content_margin_all(14.0)
	p.add_theme_stylebox_override("panel", s)
	return p


static func slider(min_v: float, max_v: float, value: float, step: float = 0.05) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(320, 40)
	return s


## Faz o título "respirar" (escala suave contínua).
static func pulse(node: Control, amount: float = 0.04, period: float = 1.6) -> void:
	node.pivot_offset = node.size * 0.5
	var tw: Tween = node.create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2.ONE * (1.0 + amount), period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, period * 0.5).set_trans(Tween.TRANS_SINE)
