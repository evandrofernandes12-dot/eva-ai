extends Node
## Configurações e progresso salvos em user://chavinho_save.cfg (recordes, desafios, troféus, opções).

const PATH: String = "user://chavinho_save.cfg"

var _cfg := ConfigFile.new()


func _ready() -> void:
	_cfg.load(PATH) # sem arquivo ainda = tudo no padrão


func save() -> void:
	_cfg.save(PATH)


# ---- opções
func get_setting(key: String, default_value: Variant) -> Variant:
	return _cfg.get_value("settings", key, default_value)


func set_setting(key: String, value: Variant) -> void:
	_cfg.set_value("settings", key, value)
	save()


func player_name() -> String:
	return str(get_setting("player_name", "Jogador"))


# ---- recordes por pista
func best_time(track_id: String) -> float:
	return float(_cfg.get_value("best", track_id, 0.0))


## Retorna true se for novo recorde.
func submit_time(track_id: String, t: float) -> bool:
	var best: float = best_time(track_id)
	if best <= 0.0 or t < best:
		_cfg.set_value("best", track_id, t)
		save()
		return true
	return false


# ---- desafios
func challenge_done(id: String) -> bool:
	return bool(_cfg.get_value("challenges", id, false))


func mark_challenge(id: String) -> void:
	_cfg.set_value("challenges", id, true)
	save()


func challenges_done_count() -> int:
	if not _cfg.has_section("challenges"):
		return 0
	return _cfg.get_section_keys("challenges").size()


# ---- troféus da copa: "gold" | "silver" | "bronze"
func trophy_count(kind: String) -> int:
	return int(_cfg.get_value("trophies", kind, 0))


func add_trophy(kind: String) -> void:
	_cfg.set_value("trophies", kind, trophy_count(kind) + 1)
	save()
