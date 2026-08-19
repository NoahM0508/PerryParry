extends Area2D

@export var xp_amount: int = 20
@export var magnet_range: float = 50.0
@export var move_speed: float = 400.0

var target: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	target = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if target:
		var distance = global_position.distance_to(target.global_position)
		if distance <= magnet_range:
			var direction = (target.global_position - global_position).normalized()
			global_position += direction * move_speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if body.has_method("gain_xp"):
			body.call("gain_xp", xp_amount)
		queue_free()
