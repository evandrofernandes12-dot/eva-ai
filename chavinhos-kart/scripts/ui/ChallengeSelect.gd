class_name ChallengeSelect
extends Control
## Lista de desafios especiais, com marca de concluído.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UIStyle.gradient_bg(Color(0.55, 0.3, 0.7), Color(0.95, 0.6, 0.35)))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	root.add_child(UIStyle.label("DESAFIOS  (%d/%d)" % [Save.challenges_done_count(), ChallengeDefs.LIST.size()], 52, UIStyle.YELLOW, 12))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	var first: Button
	for c in ChallengeDefs.LIST:
		var done: bool = Save.challenge_done(str(c["id"]))
		var card: PanelContainer = UIStyle.card(Color(0.1, 0.25, 0.1, 0.9) if done else Color(0.16, 0.1, 0.05, 0.9), Color(0.5, 1.0, 0.5) if done else Color(0.9, 0.65, 0.2))
		grid.add_child(card)
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(560, 0)
		card.add_child(col)
		col.add_child(UIStyle.label(("[OK] " if done else "") + str(c["title"]), 30, Color(0.6, 1.0, 0.6) if done else Color.WHITE, 6))
		var d: Label = UIStyle.label(str(c["desc"]), 20, Color(1, 1, 0.9), 3)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(540, 56)
		col.add_child(d)
		col.add_child(UIStyle.label("Pista: %s" % TrackCatalog.track_name(int(c["track"])), 18, Color(0.8, 0.9, 1.0), 3))
		var b: Button = UIStyle.button("JOGAR", 22, Vector2(200, 48))
		b.pressed.connect(_play.bind(c))
		col.add_child(b)
		if first == null:
			first = b
	var back: Button = UIStyle.button("VOLTAR", 24, Vector2(220, 56))
	back.pressed.connect(Global.goto_menu)
	root.add_child(back)
	if first != null:
		first.grab_focus()


func _play(c: Dictionary) -> void:
	Global.challenge = c
	Global.mode = Global.Mode.CHALLENGE
	Global.goto_select()
