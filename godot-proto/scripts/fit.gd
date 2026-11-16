class_name Fit
## Ajuda para modelos GLB: tamanho padrão e busca de animações.

static func find_node_of(root: Node, type_name: String) -> Node:
	if root.is_class(type_name):
		return root
	for c in root.get_children():
		var r := find_node_of(c, type_name)
		if r:
			return r
	return null

static func _collect(root: Node, out: Array) -> void:
	if root is MeshInstance3D:
		out.append(root)
	for c in root.get_children():
		_collect(c, out)

## Caixa (AABB) do modelo no espaço de `root`.
static func bounds(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	var sk := find_node_of(root, "Skeleton3D") as Skeleton3D
	if sk and sk.get_bone_count() > 3:
		for i in sk.get_bone_count():
			var p: Vector3 = inv * (sk.global_transform * sk.get_bone_global_pose(i).origin)
			if first:
				box = AABB(p, Vector3.ZERO)
				first = false
			else:
				box = box.expand(p)
		return box.grow(box.size.y * 0.06)
	var meshes: Array = []
	_collect(root, meshes)
	for m: MeshInstance3D in meshes:
		var b: AABB = (inv * m.global_transform) * m.get_aabb()
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box

## Escala o modelo para ter `height` metros e apoia os pés no chão.
static func to_height(model: Node3D, height: float) -> void:
	var b := bounds(model)
	if b.size.y <= 0.0001:
		return
	var s := height / b.size.y
	model.scale *= s
	model.position.y -= b.position.y * s

## Procura uma animação cujo nome contenha uma das palavras (na ordem de preferência).
static func find_anim(ap: AnimationPlayer, keys: Array) -> StringName:
	if ap == null:
		return &""
	var names := ap.get_animation_list()
	for k: String in keys:
		for n in names:
			var short := String(n).get_slice("|", String(n).get_slice_count("|") - 1).to_lower()
			if short == k.to_lower():
				return n
	for k: String in keys:
		for n in names:
			if String(n).to_lower().contains(k.to_lower()):
				return n
	return &""

static func play(ap: AnimationPlayer, anim: StringName, loop := true, speed := 1.0) -> void:
	if ap == null or anim == &"":
		return
	var a := ap.get_animation(anim)
	if a:
		a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if ap.current_animation != anim or not ap.is_playing():
		ap.play(anim, 0.15, speed)
