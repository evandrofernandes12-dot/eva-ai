class_name ChallengeDefs
extends RefCounted
## Desafios especiais. type: no_items | eat | drift | hits | time | place.

const LIST: Array[Dictionary] = [
	{"id": "ch_noitems", "title": "Na Raça", "desc": "Vença a corrida sem usar nenhum item.",
		"type": "no_items", "target": 1, "track": 0, "laps": 3},
	{"id": "ch_eat", "title": "Fome de Sanduíche", "desc": "Use 4 Sanduíches de Presunto numa mesma corrida.",
		"type": "eat", "target": 4, "track": 1, "laps": 3},
	{"id": "ch_drift", "title": "Mestre do Drift", "desc": "Solte 6 mini-turbos de drift (nível azul ou mais).",
		"type": "drift", "target": 6, "track": 2, "laps": 3},
	{"id": "ch_hits", "title": "Chinelada Geral", "desc": "Acerte 4 rivais com seus itens.",
		"type": "hits", "target": 4, "track": 3, "laps": 3},
	{"id": "ch_time", "title": "Contra o Relógio", "desc": "Termine 3 voltas no Circuito da Vila em menos de 1:45.",
		"type": "time", "target": 105, "track": 0, "laps": 3},
	{"id": "ch_podium", "title": "Subida de Rampa", "desc": "Largue em último e chegue no pódio (top 3) em Acapulco.",
		"type": "place", "target": 3, "track": 1, "laps": 3},
]


static func by_id(id: String) -> Dictionary:
	for c in LIST:
		if str(c["id"]) == id:
			return c
	return {}
