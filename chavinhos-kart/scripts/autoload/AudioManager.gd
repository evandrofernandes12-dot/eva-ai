extends Node
## Áudio 100% procedural (sem arquivos .wav):
##  - Motor: AudioStreamGenerator preenchido em tempo real (pitch segue a velocidade).
##  - SFX: AudioStreamWAV sintetizado uma vez no início (beeps, itens, batidas...).

const MIX_RATE: int = 22050
const SFX_VOICES: int = 8

var sfx: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _voice_idx: int = 0

var _engine_player: AudioStreamPlayer
var _engine_playback: AudioStreamGeneratorPlayback
var _engine_phase: float = 0.0
var _engine_freq: float = 50.0
var _engine_vol: float = 0.0
var _target_freq: float = 50.0
var _target_vol: float = 0.0
var sfx_volume: float = 1.0
var engine_volume: float = 0.6
var _wave: PackedFloat32Array = PackedFloat32Array()


## Lê o volume salvo (Opções) e aplica no barramento principal.
func apply_settings() -> void:
	var master: float = float(Save.get_setting("vol_master", 0.9))
	sfx_volume = float(Save.get_setting("vol_sfx", 1.0))
	engine_volume = float(Save.get_setting("vol_engine", 0.6))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master, 0.0001)))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_voices.append(p)
	_build_sfx()
	_build_wave()
	_setup_engine()
	apply_settings()


# ---------------------------------------------------------------- SFX

func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sfx.has(sfx_name) or _voices.is_empty():
		return
	var p: AudioStreamPlayer = _voices[_voice_idx]
	_voice_idx = (_voice_idx + 1) % _voices.size()
	p.stream = sfx[sfx_name] as AudioStream
	p.volume_db = volume_db - 6.0 + linear_to_db(maxf(sfx_volume, 0.0001))
	p.pitch_scale = pitch
	p.play()


func _synth(duration: float, gen: Callable) -> AudioStreamWAV:
	var n: int = int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var v: float = clampf(float(gen.call(t, float(i) / float(n))), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w


func _build_sfx() -> void:
	# Contagem regressiva
	sfx["beep"] = _synth(0.22, func(t: float, p: float) -> float:
		return sin(TAU * 660.0 * t) * 0.55 * (1.0 - p))
	sfx["go"] = _synth(0.55, func(t: float, p: float) -> float:
		return (sin(TAU * 1320.0 * t) * 0.5 + sin(TAU * 1980.0 * t) * 0.2) * (1.0 - p * p))
	# Caixa de item: arpejo ascendente
	sfx["pickup"] = _synth(0.3, func(t: float, p: float) -> float:
		var f: float = 520.0 * pow(2.0, floorf(p * 4.0) / 4.0 * 1.5)
		return (1.0 if fmod(t * f, 1.0) < 0.5 else -1.0) * 0.28 * (1.0 - p))
	# Turbo (sanduíche / drift)
	sfx["boost"] = _synth(0.7, func(t: float, p: float) -> float:
		var f: float = 180.0 + 700.0 * p
		return (sin(TAU * f * t) * 0.35 + (randf() * 2.0 - 1.0) * 0.3) * sin(p * PI))
	# Batida
	sfx["hit"] = _synth(0.35, func(t: float, p: float) -> float:
		return (sin(TAU * (130.0 - 90.0 * p) * t) * 0.8 + (randf() * 2.0 - 1.0) * 0.4 * (1.0 - p)) * pow(1.0 - p, 1.5))
	# Giro / rodopio
	sfx["spin"] = _synth(0.8, func(t: float, p: float) -> float:
		return sin(TAU * (300.0 + 180.0 * sin(t * 28.0)) * t) * 0.4 * (1.0 - p))
	# Arremesso
	sfx["throw"] = _synth(0.25, func(t: float, p: float) -> float:
		return (randf() * 2.0 - 1.0) * 0.4 * sin(p * PI))
	# Splash (balde)
	sfx["splash"] = _synth(0.45, func(t: float, p: float) -> float:
		return (randf() * 2.0 - 1.0) * 0.5 * pow(1.0 - p, 2.0))
	# Faísca de drift (nível subiu)
	sfx["tick"] = _synth(0.09, func(t: float, p: float) -> float:
		return sin(TAU * 1500.0 * t) * 0.4 * (1.0 - p))
	# Volta completada
	sfx["lap"] = _synth(0.6, func(t: float, p: float) -> float:
		var f: float = 523.0 if p < 0.33 else (659.0 if p < 0.66 else 784.0)
		return (1.0 if fmod(t * f, 1.0) < 0.5 else -1.0) * 0.25 * (1.0 - p * 0.6))
	# Chegada
	sfx["finish"] = _synth(1.2, func(t: float, p: float) -> float:
		var f: float = 392.0 if p < 0.2 else (523.0 if p < 0.4 else (659.0 if p < 0.6 else 784.0))
		return (sin(TAU * f * t) * 0.4 + sin(TAU * f * 2.0 * t) * 0.15) * (1.0 - p * 0.8))
	# Botões de menu
	sfx["click"] = _synth(0.08, func(t: float, p: float) -> float:
		return sin(TAU * 880.0 * t) * 0.35 * (1.0 - p))


# ---------------------------------------------------------------- Motor

## Uma volta da onda do motor: soma de harmônicos (som "cheio" que aparece em alto-falante pequeno,
## sem o chiado de uma onda serrilhada crua).
func _build_wave() -> void:
	var n: int = 512
	_wave.resize(n)
	var peak: float = 0.0
	for i in n:
		var ph: float = TAU * float(i) / float(n)
		var v: float = 0.0
		for hrm in range(1, 9):
			v += sin(ph * float(hrm)) / pow(float(hrm), 1.1)
		_wave[i] = v
		peak = maxf(peak, absf(v))
	for i in n:
		_wave[i] /= peak


func _setup_engine() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = float(MIX_RATE)
	gen.buffer_length = 0.3 if OS.has_feature("web") else 0.12 # navegador: buffer maior evita estalos
	_engine_player = AudioStreamPlayer.new()
	_engine_player.stream = gen
	_engine_player.volume_db = -8.0
	add_child(_engine_player)
	_engine_player.play()
	_engine_playback = _engine_player.get_stream_playback() as AudioStreamGeneratorPlayback


## ratio: 0 (parado) .. ~1.2 (turbo). active=false silencia o motor.
func set_engine(ratio: float, active: bool) -> void:
	_target_freq = 85.0 + 190.0 * clampf(ratio, 0.0, 1.3)
	_target_vol = (0.18 + 0.32 * clampf(ratio, 0.0, 1.0)) * engine_volume if active else 0.0


func _process(delta: float) -> void:
	if _engine_playback == null:
		return
	_engine_freq = lerpf(_engine_freq, _target_freq, clampf(delta * 8.0, 0.0, 1.0))
	_engine_vol = lerpf(_engine_vol, _target_vol, clampf(delta * 6.0, 0.0, 1.0))
	if get_tree().paused:
		_target_vol = 0.0
	var frames: int = _engine_playback.get_frames_available()
	if _engine_vol < 0.002 and _target_vol <= 0.0:
		for i in frames: # silêncio barato (mantém o buffer cheio, sem zumbido)
			_engine_playback.push_frame(Vector2.ZERO)
		return
	for i in frames:
		_engine_phase = fmod(_engine_phase + _engine_freq / float(MIX_RATE), 1.0)
		var idx: float = _engine_phase * 512.0
		var i0: int = int(idx) % 512
		var fr: float = idx - floorf(idx)
		var w: float = lerpf(_wave[i0], _wave[(i0 + 1) % 512], fr)
		var s: float = w * 0.7 * _engine_vol
		_engine_playback.push_frame(Vector2(s, s))
