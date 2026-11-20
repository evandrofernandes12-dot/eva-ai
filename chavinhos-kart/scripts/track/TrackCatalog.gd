class_name TrackCatalog
extends RefCounted
## Catálogo das pistas de corrida. Para adicionar uma pista: crie a cena (herdando TrackBase) e liste aqui.

const ARENA_SCENE: String = "res://scenes/tracks/BattleArena.tscn"

const TRACKS: Array[Dictionary] = [
	{
		"id": "vila", "name": "Circuito da Vila",
		"desc": "A praça com chafariz e a casa #71. Curvas largas e retas longas: ótima para começar.",
		"scene": "res://scenes/tracks/TrackVila.tscn",
	},
	{
		"id": "acapulco", "name": "Acapulco Sunset",
		"desc": "Deque de madeira à beira-mar. Cuidado: a areia ao lado da pista segura muito o kart!",
		"scene": "res://scenes/tracks/TrackAcapulco.tscn",
	},
	{
		"id": "bruxa", "name": "Casa da Bruxa do 71",
		"desc": "Corredores assombrados, caldeirões e pouca luz. Pista curta e cheia de curvas.",
		"scene": "res://scenes/tracks/TrackBruxa.tscn",
	},
	{
		"id": "ferro", "name": "Ferro-Velho do Seu Barriga",
		"desc": "Pilhas de pneus, carros amassados e um guindaste. Terra solta fora da pista.",
		"scene": "res://scenes/tracks/TrackFerroVelho.tscn",
	},
]


static func count() -> int:
	return TRACKS.size()


static func info(index: int) -> Dictionary:
	return TRACKS[clampi(index, 0, TRACKS.size() - 1)]


static func track_name(index: int) -> String:
	return str(info(index)["name"])


static func track_id(index: int) -> String:
	return str(info(index)["id"])


## Pontos da linha central (para desenhar o contorno nos menus) sem precisar montar a pista.
static func preview_points(index: int) -> PackedVector3Array:
	var scene: PackedScene = load(str(info(index)["scene"])) as PackedScene
	if scene == null:
		return PackedVector3Array()
	var node: TrackBase = scene.instantiate() as TrackBase
	if node == null:
		return PackedVector3Array()
	var pts: PackedVector3Array = node._make_centerline()
	node.free()
	return pts
