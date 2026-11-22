class_name ItemHazard
extends ItemBase
## Obstáculo deixado atrás do kart (Barril / Balde de Água): quem encostar rodopia.

@export var kind: String = "barril" # "barril" | "balde"


func _ready() -> void:
	lifetime = 30.0
	arm_time = 0.7
	super._ready()


func _build_visual() -> void:
	if kind == "balde":
		ProcMesh.cyl(self, 0.38, 0.75, Vector3(0, 0.38, 0), Color(0.62, 0.65, 0.68), Vector3.ZERO, 0.45, 0.35, 0.7)
		ProcMesh.cyl(self, 0.4, 0.04, Vector3(0, 0.74, 0), Color(0.3, 0.6, 0.95, 0.9), Vector3.ZERO, -1.0, 0.1)
		ProcMesh.torus(self, 0.02, 0.4, Vector3(0, 0.78, 0), Color(0.5, 0.52, 0.55), Vector3.ZERO, 0.8)
	else:
		ProcMesh.cyl(self, 0.5, 1.0, Vector3(0, 0.5, 0), Color(0.45, 0.27, 0.12), Vector3.ZERO, 0.5)
		for y: float in [0.2, 0.8]:
			ProcMesh.cyl(self, 0.53, 0.1, Vector3(0, y, 0), Color(0.15, 0.15, 0.17), Vector3.ZERO, 0.5, 0.5, 0.5)


func activate(kart: KartController) -> void:
	super.activate(kart)
	var fwd: Vector3 = -kart.global_transform.basis.z
	fwd.y = 0.0
	global_position = kart.global_position - fwd.normalized() * 3.2
	global_position.y = 0.0
	rotation.y = randf() * TAU
	AudioManager.play_sfx("throw", -4.0, 0.7)


func _hit_kart(k: KartController) -> void:
	k.spin_out(1.2 if kind == "barril" else 0.9)
	AudioManager.play_sfx("splash" if kind == "balde" else "hit")
	set_deferred("monitoring", false)
	queue_free()
