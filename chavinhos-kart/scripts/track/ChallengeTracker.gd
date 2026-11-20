class_name ChallengeTracker
extends Node
## Acompanha as regras de um desafio durante a corrida e avalia quando ela termina.

signal progress_changed(text: String)

var def: Dictionary = {}
var kart: KartController
var count: int = 0
var items_used: int = 0


func setup(d: Dictionary, k: KartController) -> void:
	def = d
	kart = k
	kart.item_used.connect(_on_item_used)
	kart.drift_boost_released.connect(_on_drift)
	kart.rival_hit.connect(_on_hit)
	_emit()


func _on_item_used(type: int) -> void:
	items_used += 1
	if str(def["type"]) == "eat" and type == ItemDefs.Type.SANDUICHE:
		count += 1
	_emit()


func _on_drift(level: int) -> void:
	if str(def["type"]) == "drift" and level >= 1:
		count += 1
	_emit()


func _on_hit() -> void:
	if str(def["type"]) == "hits":
		count += 1
	_emit()


func progress_text() -> String:
	var t: String = str(def.get("type", ""))
	var target: int = int(def.get("target", 0))
	match t:
		"eat", "drift", "hits":
			return "%s: %d/%d" % [str(def["title"]), count, target]
		"no_items":
			return "%s: itens usados %d" % [str(def["title"]), items_used]
		"time":
			return "%s: meta %s" % [str(def["title"]), Global.format_time(float(target))]
		_:
			return str(def["title"])


func _emit() -> void:
	progress_changed.emit(progress_text())


## Avalia ao fim da corrida. Retorna { done: bool, text: String }.
func evaluate(place: int, finish_time: float, finished: bool) -> Dictionary:
	var t: String = str(def["type"])
	var target: int = int(def["target"])
	var done: bool = false
	var text: String = ""
	match t:
		"no_items":
			done = finished and place == 1 and items_used == 0
			text = "Venceu sem itens!" if done else "Precisa vencer sem usar itens (usou %d)." % items_used
		"eat":
			done = count >= target
			text = "Sanduíches usados: %d/%d" % [count, target]
		"drift":
			done = count >= target
			text = "Mini-turbos: %d/%d" % [count, target]
		"hits":
			done = count >= target
			text = "Rivais atingidos: %d/%d" % [count, target]
		"time":
			done = finished and finish_time <= float(target)
			text = "Seu tempo: %s (meta %s)" % [Global.format_time(finish_time), Global.format_time(float(target))]
		"place":
			done = finished and place <= target
			text = "Você terminou em %dº (meta: top %d)." % [place, target]
	return {"done": done, "text": text}
