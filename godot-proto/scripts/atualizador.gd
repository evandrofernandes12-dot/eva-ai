extends Control
## Primeira cena do jogo: mostra a logo, procura atualização no GitHub do projeto e, se houver, baixa o
## pacote com o que mudou (patch .pck) e aplica antes de abrir o jogo. Sem internet, usa o último pacote
## baixado. O APK só precisa ser reinstalado quando a BASE mudar (troca de versão do Godot, por exemplo).

const BASE := 67   # versão que vai dentro do APK/Web (o patch é sempre em relação a ela)
const URL := "https://raw.githubusercontent.com/evandrofernandes12-dot/eva-ai/claude/godot-character-creator-fixes-hf5ksp/godot-proto/atualizacoes/"
const PACOTE := "user://atualizacao.pck"
const INFO := "user://atualizacao.json"
const JOGO := "res://main.tscn"

var _http: HTTPRequest
var _texto: Label
var _remota := {}

func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.04, 0.07)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var logo := TextureRect.new()
	logo.texture = load("res://logo.png")
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(logo)
	_texto = Label.new()
	_texto.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_texto.offset_top = -70
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.add_theme_font_size_override("font_size", 22)
	_texto.add_theme_color_override("font_outline_color", Color.BLACK)
	_texto.add_theme_constant_override("outline_size", 8)
	add_child(_texto)
	if OS.has_feature("web") or OS.has_feature("editor"):   # Web atualiza pelo itch.io; no editor não precisa
		_abrir_jogo()
		return
	_texto.text = "Procurando atualizações..."
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_versao_recebida)
	if _http.request(URL + "versao.json?t=%d" % Time.get_unix_time_from_system()) != OK:
		_abrir_jogo()

func _local() -> Dictionary:
	if not FileAccess.file_exists(INFO):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(INFO))
	return d if d is Dictionary else {}

func _versao_recebida(res: int, codigo: int, _h: PackedStringArray, corpo: PackedByteArray) -> void:
	if res != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		_abrir_jogo()   # sem internet: joga com o que já tem
		return
	var d = JSON.parse_string(corpo.get_string_from_utf8())
	if not d is Dictionary:
		_abrir_jogo()
		return
	_remota = d
	if int(d.get("base", BASE)) != BASE:
		_texto.text = "Há uma versão nova completa do jogo. Peça o APK novo!"
		await get_tree().create_timer(2.5).timeout
		_abrir_jogo()
		return
	var tem := int(_local().get("versao", BASE))
	var nova := int(d.get("versao", BASE))
	if nova <= tem or String(d.get("patch", "")) == "":
		_abrir_jogo()
		return
	_texto.text = "Baixando a versão %d..." % nova
	_http.request_completed.disconnect(_versao_recebida)
	_http.request_completed.connect(_pacote_recebido)
	_http.timeout = 0.0
	_http.download_file = PACOTE + ".tmp"
	_http.request(URL + String(d.patch))
	set_process(true)

func _process(_d: float) -> void:
	if _http != null and _http.download_file != "" and _http.get_body_size() > 0:
		_texto.text = "Baixando a versão %d... %d%%" % [int(_remota.get("versao", 0)), int(100.0 * _http.get_downloaded_bytes() / _http.get_body_size())]

func _pacote_recebido(res: int, codigo: int, _h: PackedStringArray, _c: PackedByteArray) -> void:
	set_process(false)
	if res == HTTPRequest.RESULT_SUCCESS and codigo == 200:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(PACOTE + ".tmp"), ProjectSettings.globalize_path(PACOTE))
		var f := FileAccess.open(INFO, FileAccess.WRITE)
		f.store_string(JSON.stringify({"versao": int(_remota.get("versao", BASE))}))
		f.close()
		_texto.text = "Atualizado!"
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PACOTE + ".tmp"))
	_abrir_jogo()

## Aplica o pacote baixado (se houver) e abre o jogo.
func _abrir_jogo() -> void:
	if not OS.has_feature("editor") and FileAccess.file_exists(PACOTE) and int(_local().get("versao", BASE)) > BASE:
		if not ProjectSettings.load_resource_pack(PACOTE, true):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PACOTE))   # pacote estragado: apaga e segue
	get_tree().change_scene_to_file.call_deferred(JOGO)
