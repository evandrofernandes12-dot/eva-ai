class_name PathPreview
extends Control
## Desenha o contorno de uma pista (lista de pontos) dentro do controle.

var _pts: PackedVector3Array = PackedVector3Array()


func set_points(p: PackedVector3Array) -> void:
	_pts = p
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	if _pts.size() < 3:
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in _pts:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	var ext: Vector2 = hi - lo
	var sc: float = minf((size.x - 30.0) / maxf(ext.x, 1.0), (size.y - 30.0) / maxf(ext.y, 1.0))
	var off: Vector2 = (size - ext * sc) * 0.5
	var line := PackedVector2Array()
	for p in _pts:
		line.append((Vector2(p.x, p.z) - lo) * sc + off)
	line.append(line[0])
	draw_polyline(line, Color(0.05, 0.05, 0.08, 0.95), 14.0, true)
	draw_polyline(line, Color(0.95, 0.85, 0.5), 8.0, true)
	draw_circle(line[0], 9.0, Color.WHITE)
	draw_circle(line[0], 6.0, Color(0.3, 0.9, 0.4))
