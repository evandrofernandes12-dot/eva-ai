class_name ItemSanduiche
extends ItemBase
## Sanduíche de Presunto: turbo de velocidade instantâneo.

const BOOST_POWER: float = 11.0
const BOOST_TIME: float = 2.0


func _build_visual() -> void:
	ProcMesh.capsule(self, 0.26, 1.1, Vector3.ZERO, Color(0.85, 0.6, 0.3), Vector3(0, 0, 90))
	ProcMesh.rbox(self, Vector3(0.85, 0.06, 0.34), Vector3(0, 0.1, 0), Color(0.95, 0.55, 0.6))   # presunto
	ProcMesh.rbox(self, Vector3(0.8, 0.04, 0.36), Vector3(0, 0.16, 0), Color(0.3, 0.7, 0.25))    # alface
	ProcMesh.rbox(self, Vector3(0.75, 0.04, 0.3), Vector3(0, 0.05, 0), Color(1.0, 0.85, 0.3))    # queijo


func activate(kart: KartController) -> void:
	super.activate(kart)
	kart.apply_boost(BOOST_POWER, BOOST_TIME)
	set_deferred("monitoring", false)
	global_position = kart.global_position + Vector3(0, 2.0, 0)
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tw.tween_callback(queue_free)
