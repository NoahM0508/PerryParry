extends StaticBody2D
class_name DestructibleWall

signal destroyed(wall: DestructibleWall)

@export var max_health: int = 35
@export var destroy_on_player_touch: bool = false
@export var destroy_delay: float = 0.2

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var current_health: int
var is_broken: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("DestructibleWalls")
	update_frame()

func take_damage(amount: int) -> void:
	if is_broken:
		return

	current_health -= amount
	update_frame()

	if current_health <= 0:
		destroy()

func update_frame() -> void:
	if animated_sprite == null or max_health <= 0:
		return

	var ratio: float = float(current_health) / float(max_health)
	if ratio > 0.66:
		animated_sprite.frame = 0
	elif ratio > 0.33:
		animated_sprite.frame = 1
	elif ratio > 0.0:
		animated_sprite.frame = 2
	else:
		animated_sprite.frame = 3

func destroy() -> void:
	if is_broken:
		return
	is_broken = true

	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if animated_sprite:
		animated_sprite.frame = 3

	destroyed.emit(self)

	if destroy_delay > 0.0:
		await get_tree().create_timer(destroy_delay).timeout

	queue_free()

func _on_body_entered(body: Node) -> void:
	if destroy_on_player_touch and body.is_in_group("Player"):
		destroy()
