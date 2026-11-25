extends SceneTree
# Prints do jogo neste ambiente: xvfb-run -a godot --path godot-proto -s ../scripts/godot_captura.gd -- saida.png FRAMES "expr" ["x,y,z" câmera] ["x,y,z" alvo]
# uso: godot --path . -s captura.gd -- saida.png frames "expr" [cam "x,y,z"] [alvo "x,y,z"]
var _n := 0
var _main: Node
var _args := OS.get_cmdline_user_args()
func _v(s: String) -> Vector3:
	var p := s.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))
func _initialize() -> void:
	_main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
func _process(_d: float) -> bool:
	_n += 1
	var fim := int(_args[1]) if _args.size() > 1 else 90
	if _n == 5 and _args.size() > 2 and _args[2] != "":
		var ex := Expression.new()
		ex.parse(_args[2], ["m"])
		ex.execute([_main], self)
	if _n == fim - 3 and _args.size() > 4:
		var c := Camera3D.new()
		c.far = 2000.0
		root.add_child(c)
		c.global_position = _v(_args[3])
		c.look_at(_v(_args[4]))
		c.current = true
		_main.get_node("HUD").visible = false
	if _n == fim:
		print("POS ", _main.player.global_position, " ", _main.mundo.regiao_atual, " ", _main.mundo.regioes.golems.visible, " ", _main.mundo.regioes.escuridao.visible)
		root.get_viewport().get_texture().get_image().save_png(_args[0])
		quit()
	return false
