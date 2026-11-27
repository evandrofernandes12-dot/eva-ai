extends Node
class_name Som
## Som do jogo: música (troca com transição suave), ambientes em camadas (mar, pássaros, grilos, chuva,
## vento, fogueira) que sobem e descem conforme o lugar e a hora, e efeitos 3D no ponto onde acontecem.
## Uso: Som.efeito("espada", posição) de qualquer script (há uma instância única em Som.eu).

const S := "res://assets/sons/"
const VARIACOES := {"espada": 3, "rugido": 3, "grunhido": 3, "osso": 3, "respingo": 2}   # sorteia espada1..3 etc.
static var eu: Som

var jogo: Node
var _mus: Array = []          # dois tocadores para a transição
var _mus_atual := ""
var _mus_i := 0
var _amb := {}                # nome -> AudioStreamPlayer
var _streams := {}
var _batalha_t := 0.0
var musica_forcada := ""      # cena especial (abertura, lua cheia) manda na música

func _ready() -> void:
	eu = self
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_mus.append(p)
	for n: String in ["mar", "praia", "passaros", "grilos", "chuva", "vento", "fogueira", "rio"]:
		var a := AudioStreamPlayer.new()
		a.stream = _carregar("amb/" + n, true)
		a.volume_db = -80.0
		add_child(a)
		a.play()
		_amb[n] = a

func _carregar(nome: String, laco := false) -> AudioStream:
	if _streams.has(nome):
		return _streams[nome]
	var st := load(S + nome + ".ogg") as AudioStreamOggVorbis
	if st != null and laco:
		st = st.duplicate() as AudioStreamOggVorbis
		st.loop = true
	_streams[nome] = st
	return st

## Toca uma música (em laço), com transição de 2 s.
func musica(nome: String) -> void:
	if nome == _mus_atual:
		return
	_mus_atual = nome
	var velho: AudioStreamPlayer = _mus[_mus_i]
	_mus_i = 1 - _mus_i
	var novo: AudioStreamPlayer = _mus[_mus_i]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(velho, "volume_db", -80.0, 2.0)
	if nome != "":
		novo.stream = _carregar("musica/" + nome, true)
		novo.volume_db = -40.0
		novo.play()
		tw.tween_property(novo, "volume_db", -9.0 if nome != "abertura" else -5.0, 2.0)

## Efeito sonoro. Com posição: som 3D que diminui com a distância; sem posição: direto no ouvido.
static func efeito(nome: String, pos = null, volume := 0.0, alcance := 30.0) -> void:
	if eu == null:
		return
	var n := nome
	if VARIACOES.has(nome):
		n = nome + str(randi() % int(VARIACOES[nome]) + 1)
	var st := eu._carregar("sfx/" + n)
	if st == null:
		return
	var p: Node
	if pos == null:
		var p2 := AudioStreamPlayer.new()
		p2.stream = st
		p2.volume_db = volume
		p2.pitch_scale = randf_range(0.94, 1.06)
		p = p2
	else:
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = st
		p3.volume_db = volume
		p3.unit_size = 6.0
		p3.max_distance = alcance
		p3.pitch_scale = randf_range(0.92, 1.08)
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p = p3
	eu.add_child(p)
	if pos != null:
		(p as Node3D).global_position = pos
	p.call("play")
	p.connect("finished", p.queue_free)

## Combate por perto: a música de batalha entra (e sai uns segundos depois que acaba).
func em_batalha() -> void:
	_batalha_t = 6.0

func _process(delta: float) -> void:
	if jogo == null or jogo.player == null:
		return
	_batalha_t -= delta
	var pj: Vector3 = jogo.player.global_position
	var ceu = jogo.ceu
	var noite: float = ceu.fator_noite if ceu != null else 0.0
	var chuva: float = ceu.chuva if ceu != null else 0.0
	var dentro: bool = jogo._dentro != ""
	var reg: String = jogo.mundo.regiao_atual if jogo.mundo != null else ""
	# música
	if musica_forcada != "":
		musica(musica_forcada)
	elif _batalha_t > 0.0:
		musica("batalha")
	else:
		musica("aldeia")
	# ambientes: volume alvo (0..1) de cada camada
	var costa := 1.0 - smoothstep(30.0, 110.0, absf(pj.x - 262.0)) if pj.x > 150.0 else 0.0
	var ilha := 1.0 - smoothstep(110.0, 170.0, Vector2(pj.x - 560.0, pj.z).length())
	var mar := maxf(costa, ilha)
	if jogo.mundo != null and not jogo.mundo._viagem.is_empty():
		mar = 1.0
	var alvo := {
		"mar": mar * 0.9,
		"praia": maxf(1.0 - smoothstep(10.0, 45.0, absf(pj.x - 262.0)), 1.0 - smoothstep(2.0, 30.0, absf(Vector2(pj.x - 560.0, pj.z).length() - 130.0))) * 0.8,
		"passaros": (1.0 - noite) * (1.0 - chuva) * (0.0 if reg in ["escuridao", "cemiterio", "golems"] else 0.55),
		"grilos": noite * (1.0 - chuva * 0.7) * 0.6,
		"chuva": chuva * 0.9,
		"vento": 0.8 if reg == "golems" else (0.35 if reg == "escuridao" else 0.0),
		"fogueira": (1.0 - smoothstep(4.0, 22.0, pj.distance_to(Vector3(0, 0, 0.5)))) * 0.8,
		"rio": (1.0 - smoothstep(4.0, 14.0, absf(Vector2(pj.x, pj.z).length() - 76.0))) * 0.6,
	}
	for n: String in _amb:
		var a: AudioStreamPlayer = _amb[n]
		var v: float = float(alvo.get(n, 0.0)) * (0.35 if dentro and n != "chuva" else (0.5 if dentro else 1.0))
		var db := linear_to_db(maxf(v, 0.0001)) - 6.0
		a.volume_db = move_toward(a.volume_db, db, 40.0 * delta)
