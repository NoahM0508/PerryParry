extends Area2D

@export var xp_amount: int = 10
@export var magnet_range: float = 50.0
@export var move_speed: float = 400.0

var target: Node2D = null

func _ready() -> void:
	# Ensure the shard can detect the player entering its core hitbox
	body_entered.connect(_on_body_entered)
	# Find the player using the group we set up earlier
	target = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if target:
		var distance = global_position.distance_to(target.global_position)
		# If the player is close enough, magnetic pull activates!
		if distance <= magnet_range:
			var direction = (target.global_position - global_position).normalized()
			global_position += direction * move_speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if body.has_method("gain_xp"):
			body.call("gain_xp", xp_amount)
		queue_free()
