class_name KartPreview
extends SubViewportContainer
## Miniatura 3D giratória de um kart (SubViewport próprio), usada no menu e na seleção de pilotos.

var _viewport: SubViewport
var _pivot: Node3D
var _visuals: KartVisuals
var spin_speed: float = 0.8


func _ready() -> void:
	stretch = true
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.85)
	env.ambient_light_energy = 0.9
	var cam := Camera3D.new()
	cam.environment = env
	cam.fov = 38.0
	_viewport.add_child(cam)
	cam.look_at_from_position(Vector3(3.6, 2.6, 4.6), Vector3(0, 0.8, 0), Vector3.UP)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40.0, -30.0, 0.0)
	light.light_energy = 1.3
	_viewport.add_child(light)

	_pivot = Node3D.new()
	_viewport.add_child(_pivot)


func set_racer(stats: RacerStats) -> void:
	if _visuals != null:
		_pivot.remove_child(_visuals)
		_visuals.queue_free()
	_visuals = KartVisuals.new()
	_pivot.add_child(_visuals)
	_visuals.build(stats)
	_pivot.rotation.y = 0.5


func _process(delta: float) -> void:
	if _pivot != null:
		_pivot.rotation.y += delta * spin_speed
