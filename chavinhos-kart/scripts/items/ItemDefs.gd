class_name ItemDefs
extends RefCounted
## Definições estáticas dos itens: tipos, nomes, cenas e sorteio balanceado por posição.

enum Type { NONE, SANDUICHE, BOLA_QUADRADA, BALDE, BARRIL, CHINELO }

const SCENES: Dictionary = {
	Type.SANDUICHE: "res://scenes/items/SanduichePresunto.tscn",
	Type.BOLA_QUADRADA: "res://scenes/items/BolaQuadrada.tscn",
	Type.BALDE: "res://scenes/items/BaldeAgua.tscn",
	Type.BARRIL: "res://scenes/items/Barril.tscn",
	Type.CHINELO: "res://scenes/items/ChineloDonaFlorinda.tscn",
}

const NAMES: Dictionary = {
	Type.NONE: "",
	Type.SANDUICHE: "Sanduíche de Presunto",
	Type.BOLA_QUADRADA: "Bola Quadrada",
	Type.BALDE: "Balde de Água",
	Type.BARRIL: "Barril",
	Type.CHINELO: "Chinelo da Dona Florinda",
}


static func item_name(type: int) -> String:
	return str(NAMES.get(type, ""))


## Sorteia um item. Quem está na frente recebe mais itens defensivos; quem está atrás, ofensivos.
static func roll(place: int, total: int) -> int:
	var t: float = float(place - 1) / maxf(float(total - 1), 1.0) # 0 = líder, 1 = último
	var weights: Dictionary = {
		Type.SANDUICHE: 3.0,
		Type.BOLA_QUADRADA: 1.0 + t * 3.0,
		Type.CHINELO: 1.0 + t * 2.5,
		Type.BALDE: 2.5 - t * 2.0,
		Type.BARRIL: 2.5 - t * 2.0,
	}
	var total_weight: float = 0.0
	for k in weights:
		total_weight += float(weights[k])
	var r: float = randf() * total_weight
	for k in weights:
		r -= float(weights[k])
		if r <= 0.0:
			return int(k)
	return Type.SANDUICHE


## Instancia o item no mundo (irmão do kart) e o ativa.
static func spawn(kart: Node3D, type: int) -> void:
	if not SCENES.has(type):
		return
	var scene: PackedScene = load(str(SCENES[type])) as PackedScene
	if scene == null:
		return
	var inst: Node = scene.instantiate()
	kart.get_parent().add_child(inst)
	inst.call("activate", kart) # ItemBase.activate(kart)
