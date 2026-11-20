class_name Podium
extends Node3D
## Pódio 3D com os três primeiros + painel de resultados. Adapta-se ao modo:
## Corrida (recorde), Copa (pontos e troféu), Batalha (balões), Desafio (cumprido?) e Online (voltar à sala).

var _cup_final: bool = false
var _trophy_kind: String = ""


func _ready() -> void:
	var results: Array[Dictionary] = Global.race_results
	if results.is_empty():
		results = _fake_results() # permite abrir a cena isoladamente (F6) para testar

	var order: Array[Dictionary] = []
	order.assign(results)
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["place"]) < int(b["place"]))

	var standings: Array[Dictionary] = []
	if Global.mode == Global.Mode.CUP:
		standings = Global.cup_standings()
		_cup_final = not Global.cup_has_next()
		if _cup_final:
			_trophy_kind = _compute_trophy(standings)
			if _trophy_kind != "":
				Save.add_trophy(_trophy_kind)
			# o pódio final mostra a classificação geral
			var final_order: Array[Dictionary] = []
			for i in standings.size():
				var e: Dictionary = standings[i].duplicate()
				e["place"] = i + 1
				e["time"] = 0.0
				final_order.append(e)
			order = final_order

	_build_world()
	var layout: Array[Vector2] = [Vector2(0.0, 2.2), Vector2(-3.6, 1.5), Vector2(3.6, 1.0)]
	for i in mini(3, order.size()):
		_build_block(order[i], layout[i], i)
	if _cup_final and _trophy_kind != "":
		_build_trophy()
	_build_ui(order, standings)


func _compute_trophy(standings: Array[Dictionary]) -> String:
	for i in standings.size():
		if bool(standings[i]["is_player"]):
			if i == 0:
				return "gold"
			if i == 1:
				return "silver"
			if i == 2:
				return "bronze"
	return ""


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


func _build_trophy() -> void:
	var col: Color = Color(0.95, 0.78, 0.2)
	if _trophy_kind == "silver":
		col = Color(0.8, 0.83, 0.88)
	elif _trophy_kind == "bronze":
		col = Color(0.8, 0.5, 0.25)
	var t := Node3D.new()
	t.position = Vector3(-8.0, 0.0, 3.0)
	add_child(t)
	ProcMesh.box(t, Vector3(2.0, 0.5, 2.0), Vector3(0, 0.25, 0), Color(0.2, 0.15, 0.1), Vector3.ZERO, 0.5, 0.3)
	ProcMesh.cyl(t, 0.25, 1.2, Vector3(0, 1.1, 0), col, Vector3.ZERO, -1.0, 0.25, 0.9)
	ProcMesh.cyl(t, 1.1, 1.4, Vector3(0, 2.4, 0), col, Vector3.ZERO, 0.5, 0.25, 0.9, 0.3)
	for sx: float in [-1.15, 1.15]:
		ProcMesh.torus(t, 0.08, 0.4, Vector3(sx, 2.5, 0), col, Vector3(0, 0, 90), 0.9)


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


func _headline() -> Array:
	if Global.mode == Global.Mode.CUP:
		if _cup_final:
			var titles: Dictionary = {
				"gold": "CAMPEÃO DA COPA!", "silver": "VICE-CAMPEÃO!",
				"bronze": "TERCEIRO LUGAR NA COPA!", "": "FIM DA COPA",
			}
			var names: Dictionary = {"gold": "OURO", "silver": "PRATA", "bronze": "BRONZE", "": "nenhum desta vez"}
			return [str(titles[_trophy_kind]), "Troféu: %s" % str(names[_trophy_kind])]
		return ["COPA - ETAPA %d/%d" % [Global.cup_stage + 1, Global.CUP_TRACKS.size()], TrackCatalog.track_name(Global.track_index)]
	if Global.mode == Global.Mode.BATTLE:
		return ["BATALHA ENCERRADA", ""]
	if Global.mode == Global.Mode.CHALLENGE:
		var done: bool = bool(Global.challenge_result.get("done", false))
		return ["DESAFIO CUMPRIDO!" if done else "DESAFIO NÃO CUMPRIDO", str(Global.challenge_result.get("text", ""))]
	if Global.mode == Global.Mode.ONLINE:
		return ["RESULTADO ONLINE", ""]
	return ["PÓDIO", "NOVO RECORDE DE VOLTA!" if Global.new_record else TrackCatalog.track_name(Global.track_index)]


func _build_ui(order: Array[Dictionary], standings: Array[Dictionary]) -> void:
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
	var head: Array = _headline()
	left.add_child(UIStyle.label(str(head[0]), 54, UIStyle.YELLOW, 12))
	if str(head[1]) != "":
		var sub: Label = UIStyle.label(str(head[1]), 24, Color(1, 1, 0.85), 6)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.custom_minimum_size = Vector2(420, 0)
		left.add_child(sub)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)

	var first: Button = null
	if Global.mode == Global.Mode.ONLINE:
		if NetworkManager.active and NetworkManager.is_host:
			first = _btn(left, "VOLTAR À SALA", NetworkManager.return_to_lobby)
		else:
			left.add_child(UIStyle.label("Aguardando o anfitrião...", 24, Color.WHITE, 5))
		_btn(left, "SAIR DA SALA", func() -> void:
			NetworkManager.leave()
			Global.goto_menu())
	elif Global.mode == Global.Mode.CUP:
		if Global.cup_has_next():
			first = _btn(left, "PRÓXIMA PISTA", Global.cup_next_race)
		else:
			first = _btn(left, "NOVA COPA", Global.start_cup)
		_btn(left, "MENU PRINCIPAL", Global.goto_menu)
	else:
		first = _btn(left, "CORRER DE NOVO", Global.goto_race)
		_btn(left, "ESCOLHER PILOTO", Global.goto_select)
		_btn(left, "MENU PRINCIPAL", Global.goto_menu)
	if first != null:
		first.grab_focus()

	var panel: PanelContainer = UIStyle.card(Color(0.1, 0.06, 0.02, 0.85))
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	col.add_child(UIStyle.label("CLASSIFICAÇÃO GERAL" if Global.mode == Global.Mode.CUP else "RESULTADOS", 28, UIStyle.YELLOW, 6))
	if Global.mode == Global.Mode.CUP:
		for i in standings.size():
			var e: Dictionary = standings[i]
			col.add_child(UIStyle.label("%dº  %-16s %3d pts" % [i + 1, str(e["name"]), int(e["points"])], 22,
				UIStyle.YELLOW if bool(e["is_player"]) else Color.WHITE, 4))
	else:
		for e in order:
			var extra: String = str(e.get("score_text", ""))
			if extra == "":
				extra = Global.format_time(float(e["time"]))
			col.add_child(UIStyle.label("%dº  %-16s %s" % [int(e["place"]), str(e["name"]), extra], 22,
				UIStyle.YELLOW if bool(e["is_player"]) else Color.WHITE, 4))


func _btn(parent: Control, text: String, action: Callable) -> Button:
	var b: Button = UIStyle.button(text, 26, Vector2(320, 56))
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _fake_results() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in mini(Global.TOTAL_RACERS, Global.racers.size()):
		out.append({"stats": Global.racers[i], "name": Global.racers[i].display_name, "place": i + 1, "time": 80.0 + float(i) * 2.3, "is_player": i == 0, "score_text": ""})
	return out
