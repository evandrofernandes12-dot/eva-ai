extends SkeletonModifier3D
## Abaixa a cabeça e o pescoço devagar (cena de ajoelhar diante do Rei). `peso` de 0 a 1.

var peso := 0.0
const ANGULO := 0.7   # radianos no total (pescoço + cabeça)

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or peso <= 0.001:
		return
	for n: String in ["neck_01", "Head"]:
		var i := sk.find_bone(n)
		if i < 0:
			i = sk.find_bone(n.to_lower())
		if i < 0:
			continue
		var g := sk.get_bone_global_pose(i)
		var esq := (sk.get_bone_global_pose(sk.find_bone("upperarm_l")).origin - sk.get_bone_global_pose(sk.find_bone("upperarm_r")).origin).normalized() if sk.find_bone("upperarm_l") >= 0 else Vector3.RIGHT
		g.basis = Basis(esq, ANGULO * 0.5 * peso) * g.basis
		sk.set_bone_global_pose(i, g)
		sk.force_update_bone_child_transform(i)
