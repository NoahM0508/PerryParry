extends Area2D
class_name BossHazard

@export var damage: int = 15
@export var lifetime: float = 6.0
@export var arm_time: float = 0.15

var armed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(arm_time).timeout
	armed = true
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	if not armed:
		return
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
