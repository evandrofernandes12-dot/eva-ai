class_name Podium
extends Node3D
## Pódio 3D com os três primeiros colocados + tabela de resultados.


func _ready() -> void:
	var results: Array[Dictionary] = Global.race_results
	if results.is_empty():
		results = _fake_results() # permite abrir a cena isoladamente (F6) para testar

	_build_world()
	var order: Array[Dictionary] = []
	order.assign(results)
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["place"]) < int(b["place"]))
	# posições: 1º centro (alto), 2º esquerda, 3º direita
	var layout: Array[Vector2] = [Vector2(0.0, 2.2), Vector2(-3.6, 1.5), Vector2(3.6, 1.0)]
	for i in mini(3, order.size()):
		_build_block(order[i], layout[i], i)
	_build_ui(order)


func _build_world() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.2, 0.15, 0.4)
	sky_mat.sky_horizon_color = Color(0.95, 0.6, 0.35)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 25.0, 0.0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0, 3.6, 11.5), Vector3(0, 2.0, 0), Vector3.UP)
	ProcMesh.box(self, Vector3(60, 0.4, 40), Vector3(0, -0.2, 0), Color(0.45, 0.32, 0.22), Vector3.ZERO, 1.0)
	_build_confetti()


func _build_block(entry: Dictionary, lay: Vector2, rank_idx: int) -> void:
	var h: float = lay.y
	var gold: Array[Color] = [Color(0.95, 0.78, 0.2), Color(0.75, 0.78, 0.82), Color(0.8, 0.5, 0.25)]
	ProcMesh.box(self, Vector3(3.0, h, 3.0), Vector3(lay.x, h / 2.0, 0), gold[rank_idx], Vector3.ZERO, 0.4, 0.5)
	var num := Label3D.new()
	num.text = str(rank_idx + 1)
	num.font_size = 200
	num.pixel_size = 0.01
	num.modulate = Color.WHITE
	num.outline_size = 24
	num.position = Vector3(lay.x, h / 2.0, 1.52)
	add_child(num)
	var visuals := KartVisuals.new()
	visuals.position = Vector3(lay.x, h, 0)
	visuals.rotation.y = PI + (0.3 if lay.x < 0.0 else (-0.3 if lay.x > 0.0 else 0.0))
	add_child(visuals)
	visuals.build(entry["stats"] as RacerStats)
	var tag := Label3D.new()
	tag.text = str(entry["name"])
	tag.font_size = 72
	tag.pixel_size = 0.01
	tag.modulate = UIStyle.YELLOW if bool(entry["is_player"]) else Color.WHITE
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(lay.x, h + 3.2, 0)
	add_child(tag)


func _build_confetti() -> void:
	var p := CPUParticles3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.18, 0.02, 0.12)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = material
	p.mesh = m
	p.amount = 120
	p.lifetime = 4.0
	p.position = Vector3(0, 9, 2)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(7, 0.2, 3)
	p.direction = Vector3(0, -1, 0)
	p.spread = 15.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, -3.0, 0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.3, 0.3), Color(1, 0.9, 0.2), Color(0.3, 0.7, 1), Color(0.4, 1, 0.5)])
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	p.color_initial_ramp = g
	p.emitting = true
	add_child(p)


func _build_ui(order: Array[Dictionary]) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	layer.add_child(margin)
	var root := HBoxContainer.new()
	margin.add_child(root)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(left)
	var winner: String = str(order[0]["name"]) if not order.is_empty() else ""
	left.add_child(UIStyle.label("PÓDIO", 72, UIStyle.YELLOW, 14))
	left.add_child(UIStyle.label("Vencedor: %s" % winner, 32, Color.WHITE, 8))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)
	var again: Button = UIStyle.button("CORRER DE NOVO", 26, Vector2(300, 56))
	again.pressed.connect(Global.goto_race)
	left.add_child(again)
	var pick: Button = UIStyle.button("ESCOLHER PILOTO", 26, Vector2(300, 56))
	pick.pressed.connect(Global.goto_select)
	left.add_child(pick)
	var menu: Button = UIStyle.button("MENU PRINCIPAL", 26, Vector2(300, 56))
	menu.pressed.connect(Global.goto_menu)
	left.add_child(menu)
	again.grab_focus()

	var panel: PanelContainer = UIStyle.panel()
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	col.add_child(UIStyle.label("RESULTADOS", 30, UIStyle.YELLOW, 6))
	for e in order:
		var is_player: bool = bool(e["is_player"])
		var line: String = "%dº  %-16s %s" % [int(e["place"]), str(e["name"]), Global.format_time(float(e["time"]))]
		col.add_child(UIStyle.label(line, 22, UIStyle.YELLOW if is_player else Color.WHITE, 4))


func _fake_results() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in mini(Global.TOTAL_RACERS, Global.racers.size()):
		out.append({"stats": Global.racers[i], "name": Global.racers[i].display_name, "place": i + 1, "time": 80.0 + float(i) * 2.3, "is_player": i == 0})
	return out
