class_name TrackPath
extends RefCounted
## Linha central fechada da pista. Usada por IA, progresso de volta, minimapa e detecção de off-road.

var points: PackedVector3Array = PackedVector3Array()
var tangents: PackedVector3Array = PackedVector3Array()
var cum: PackedFloat32Array = PackedFloat32Array() # distância acumulada até cada ponto (cum[count] = comprimento)
var length: float = 0.0
var half_width: float = 9.0
var count: int = 0


func _init(pts: PackedVector3Array, p_half_width: float) -> void:
	points = pts
	half_width = p_half_width
	count = pts.size()
	cum.resize(count + 1)
	tangents.resize(count)
	var acc: float = 0.0
	for i in count:
		cum[i] = acc
		var nxt: Vector3 = points[(i + 1) % count]
		var seg: Vector3 = nxt - points[i]
		seg.y = 0.0
		acc += seg.length()
		tangents[i] = seg.normalized()
	cum[count] = acc
	length = acc


## Localiza a posição na pista. hint = índice anterior (busca local); -1 = busca global.
## Retorna { idx: int, dist: float, lateral: float } — lateral > 0 = lado direito.
func locate(pos: Vector3, hint: int = -1) -> Dictionary:
	var best: Dictionary = _search(pos, hint)
	if hint >= 0 and float(best["d2"]) > 3600.0:
		best = _search(pos, -1) # teleportado/perdido: busca global
	return best


func _search(pos: Vector3, hint: int) -> Dictionary:
	var best_d2: float = INF
	var best_i: int = 0
	var best_t: float = 0.0
	var best_lat: float = 0.0
	var start: int = 0 if hint < 0 else hint - 14
	var steps: int = count if hint < 0 else 29
	for k in steps:
		var i: int = posmod(start + k, count)
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % count]
		var ab: Vector3 = b - a
		ab.y = 0.0
		var ap: Vector3 = pos - a
		ap.y = 0.0
		var denom: float = maxf(ab.length_squared(), 0.0001)
		var t: float = clampf(ap.dot(ab) / denom, 0.0, 1.0)
		var closest: Vector3 = a + ab * t
		var off: Vector3 = pos - closest
		off.y = 0.0
		var d2: float = off.length_squared()
		if d2 < best_d2:
			best_d2 = d2
			best_i = i
			best_t = t
			best_lat = off.dot(tangents[i].cross(Vector3.UP))
	var seg_len: float = cum[best_i + 1] - cum[best_i]
	return {
		"idx": best_i,
		"dist": cum[best_i] + best_t * seg_len,
		"lateral": best_lat,
		"d2": best_d2,
	}


func _index_at(d: float) -> int:
	return clampi(cum.bsearch(d, false) - 1, 0, count - 1)


func _wrap(d: float) -> float:
	return fposmod(d, length)


func point_at(d: float) -> Vector3:
	var dd: float = _wrap(d)
	var i: int = _index_at(dd)
	var seg_len: float = maxf(cum[i + 1] - cum[i], 0.0001)
	var t: float = (dd - cum[i]) / seg_len
	return points[i].lerp(points[(i + 1) % count], t)


func tangent_at(d: float) -> Vector3:
	var dd: float = _wrap(d)
	var i: int = _index_at(dd)
	var j: int = (i + 1) % count
	var seg_len: float = maxf(cum[i + 1] - cum[i], 0.0001)
	var t: float = (dd - cum[i]) / seg_len
	return tangents[i].lerp(tangents[j], t).normalized()


func right_at(d: float) -> Vector3:
	return tangent_at(d).cross(Vector3.UP)


## Diferença com sinal entre duas distâncias ao longo da pista, em [-length/2, length/2].
func signed_delta(from_d: float, to_d: float) -> float:
	return fposmod(to_d - from_d + length * 0.5, length) - length * 0.5


## Ângulo (rad) de curva entre a posição d e d + ahead — usado pela IA para frear.
func turn_angle(d: float, ahead: float) -> float:
	var t0: Vector3 = tangent_at(d)
	var t1: Vector3 = tangent_at(d + ahead)
	return absf(t0.signed_angle_to(t1, Vector3.UP))
