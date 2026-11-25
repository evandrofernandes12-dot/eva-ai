extends Node
class_name Ceu
## Ciclo de dia e noite (10 min reais = 24 h do jogo) e chuva.
## Move o sol (DirectionalLight "Sol" da cena) e a lua (luz criada aqui), muda o céu (shaders/ceu.gdshader),
## a luz ambiente, a neblina e acende os lampiões. Chove a cada 3 dias, alternando: de dia, depois de noite.

const DIA_SEG := 600.0            # duração de um dia completo em segundos reais
const CICLO_LUA := 8              # dias para a lua ir de cheia a cheia
signal mudou_periodo(noite: bool)

var hora := 9.0                   # 0..24 (o jogo começa de manhã)
var dia := 0                      # dias que já passaram
var chuva := 0.0                  # 0..1 (intensidade, com transição suave)
var noite := false
var reg_cor := Color(0, 0, 0)       # neblina da região onde o jogador está (mundo.gd)
var reg_peso := 0.0                 # 0 fora, 1 no meio da região
var reg_dens := 0.0                 # neblina extra
var reg_ceu := 0.0                  # quanto a neblina da região cobre o céu
var reg_escuro := 0.0               # quanto a região escurece (Floresta da Escuridão)
var fator_noite := 0.0            # 0 = dia claro, 1 = noite fechada (lampiões, ambiente)

var sol: DirectionalLight3D
var lua: DirectionalLight3D
var env: Environment
var mat_ceu: ShaderMaterial
var _gotas: CPUParticles3D
var _camera: Camera3D
var lampioes: Array = []           # [material do vidro, OmniLight3D ou null]
var _grupo_t := 0.0

func iniciar(luz_sol: DirectionalLight3D, ambiente: Environment, camera: Camera3D) -> void:
	sol = luz_sol
	env = ambiente
	_camera = camera
	lua = DirectionalLight3D.new()
	lua.name = "Lua"
	lua.light_color = Color(0.62, 0.7, 0.95)
	lua.shadow_enabled = false
	add_child(lua)
	mat_ceu = ShaderMaterial.new()
	mat_ceu.shader = preload("res://shaders/ceu.gdshader")
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.008
	ruido.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	nt.noise = ruido
	mat_ceu.set_shader_parameter("nuvens_tex", nt)
	var sky := Sky.new()
	sky.sky_material = mat_ceu
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_sky_affect = 0.0   # a neblina NÃO cobre o céu (por padrão cobria tudo: sol, lua, estrelas e nuvens sumiam)
	_criar_chuva()
	_atualizar(0.0)

## Hora e dia salvos (main.gd chama ao carregar).
func definir(h: float, d: int) -> void:
	hora = fposmod(h, 24.0)
	dia = d

func fase_lua() -> float:   # 1 = cheia
	return 0.5 + 0.5 * cos(TAU * float(dia % CICLO_LUA) / CICLO_LUA)

func lua_cheia() -> bool:
	return dia % CICLO_LUA == 0

func _process(delta: float) -> void:
	hora += delta * 24.0 / DIA_SEG
	if hora >= 24.0:
		hora -= 24.0
		dia += 1
	_atualizar(delta)

## Chove no 3º dia de cada bloco de 3, alternando: blocos pares de dia (9h às 15h), ímpares de noite (21h às 3h).
func _quer_chuva() -> bool:
	if dia % 3 != 2:
		return false
	if (dia / 3) % 2 == 0:
		return hora > 9.0 and hora < 15.0
	return hora > 21.0 or hora < 3.0

func _atualizar(delta: float) -> void:
	var ang := (hora - 6.0) / 24.0 * TAU            # 0 = nascer (6h), PI/2 = meio-dia, PI = pôr (18h)
	var dir_sol := Vector3(cos(ang) * 0.85, sin(ang), cos(ang) * 0.35 + 0.4).normalized()
	# lua: caminho baixo no céu (no máx. ~28°), do lado para onde a câmera olha (-Z), para aparecer na tela
	var dir_lua := Vector3(-cos(ang) * 0.85, -sin(ang) * 0.42, -0.8).normalized()
	sol.look_at_from_position(Vector3.ZERO, -dir_sol, Vector3.UP if absf(dir_sol.y) < 0.99 else Vector3.FORWARD)
	lua.look_at_from_position(Vector3.ZERO, -dir_lua, Vector3.UP if absf(dir_lua.y) < 0.99 else Vector3.FORWARD)
	var alto := dir_sol.y
	var claro := smoothstep(-0.08, 0.3, alto)        # 0 de noite, 1 de dia
	chuva = move_toward(chuva, 1.0 if _quer_chuva() else 0.0, delta / 20.0)   # 20 s para fechar/abrir o tempo
	var fl := fase_lua()
	sol.light_energy = 1.15 * claro * (1.0 - chuva * 0.6)
	sol.light_color = Color(1.0, 0.62, 0.38).lerp(Color(1.0, 0.97, 0.92), smoothstep(0.0, 0.4, alto))
	sol.visible = alto > -0.05
	sol.shadow_enabled = alto > 0.05
	lua.light_energy = 0.22 * (1.0 - claro) * (0.4 + 0.6 * fl) * (1.0 - chuva * 0.7)
	lua.visible = lua.light_energy > 0.01
	fator_noite = 1.0 - claro
	var agora_noite := fator_noite > 0.6
	if agora_noite != noite:
		noite = agora_noite
		mudou_periodo.emit(noite)
	env.ambient_light_color = Color(0.12, 0.15, 0.26).lerp(Color(0.58, 0.62, 0.7), claro).lerp(Color(0.4, 0.42, 0.46), chuva * 0.5)
	env.ambient_light_energy = lerpf(0.55, 0.7, claro)
	env.fog_light_color = Color(0.05, 0.06, 0.1).lerp(Color(0.72, 0.82, 0.9), claro).lerp(Color(0.45, 0.48, 0.52), chuva * 0.7)
	env.fog_density = 0.006 + chuva * 0.012
	if reg_peso > 0.0:
		env.fog_light_color = env.fog_light_color.lerp(reg_cor * lerpf(1.0, 0.35, fator_noite), reg_peso)
		env.fog_density += reg_dens
		env.ambient_light_color = env.ambient_light_color.lerp(Color(0.1, 0.08, 0.16), reg_escuro * 0.8)
		sol.light_energy *= 1.0 - reg_escuro * 0.75
	env.fog_sky_affect = reg_ceu
	mat_ceu.set_shader_parameter("sol_dir", dir_sol)
	mat_ceu.set_shader_parameter("lua_dir", dir_lua)
	mat_ceu.set_shader_parameter("chuva", chuva)
	mat_ceu.set_shader_parameter("fase_lua", fl)
	var acesa := smoothstep(0.35, 0.7, fator_noite)
	for l: Array in lampioes:
		var m: StandardMaterial3D = l[0]
		m.emission_energy_multiplier = lerpf(0.3, 2.2, acesa)
		if l[1] != null:
			var o: OmniLight3D = l[1]
			o.light_energy = 1.4 * acesa
			o.visible = acesa > 0.02
	_grupo_t -= delta
	if _grupo_t <= 0.0:   # braseiros das torres e outros fogos que só acendem à noite
		_grupo_t = 1.0
		for n in get_tree().get_nodes_in_group("luz_noite"):
			if n is OmniLight3D:
				(n as OmniLight3D).visible = acesa > 0.05
				(n as OmniLight3D).light_energy = 1.6 * acesa
			elif n is CPUParticles3D:
				(n as CPUParticles3D).emitting = acesa > 0.3 and chuva < 0.6
	if _gotas != null:
		_gotas.emitting = chuva > 0.15
		if _camera != null:
			_gotas.global_position = _camera.global_position + Vector3(0, 6, 0)

## Gotas de chuva: riscos finos caindo em volta da câmera (CPU, leve).
func _criar_chuva() -> void:
	_gotas = CPUParticles3D.new()
	_gotas.amount = 700
	_gotas.lifetime = 1.0
	_gotas.local_coords = false
	_gotas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_gotas.emission_box_extents = Vector3(14, 1, 14)
	_gotas.direction = Vector3(0.1, -1, 0.05)
	_gotas.spread = 3.0
	_gotas.gravity = Vector3(0, -12, 0)
	_gotas.initial_velocity_min = 11.0
	_gotas.initial_velocity_max = 14.0
	var q := QuadMesh.new()
	q.size = Vector2(0.025, 0.55)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.82, 0.95, 0.45)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	q.material = m
	_gotas.mesh = q
	_gotas.emitting = false
	add_child(_gotas)
