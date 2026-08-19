extends Area2D
class_name Projectile

@export var damage: int = 10
@export var speed: float = 100.0 # pixels per second
@export var max_range: float = 1000.0

var direction: Vector2 = Vector2.RIGHT
var shooter = null
var start_pos: Vector2
var piercing_remaining: int = 0
var is_parried: bool = false
var is_duplicate: bool = false

func _ready() -> void:
	start_pos = global_position
	area_entered.connect(Callable(self, "_on_area_entered"))
	body_entered.connect(Callable(self, "_on_body_entered"))
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if direction == null:
		return
	global_position += direction.normalized() * speed * delta
	if start_pos.distance_to(global_position) >= max_range:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == shooter:
		return
	if area.has_method("take_damage"):
		area.call("take_damage", damage)
		handle_hit(area)

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
		handle_hit(body)
	else:
		queue_free()

func handle_hit(target: Node) -> void:
	notify_kill_if_needed(target)
	if piercing_remaining > 0:
		piercing_remaining -= 1
		return
	queue_free()

func notify_kill_if_needed(target: Node) -> void:
	if shooter == null or not is_instance_valid(shooter):
		return
	if not shooter.has_method("on_enemy_killed"):
		return
	var target_health = target.get("current_health")
	if target_health != null and target_health <= 0:
		shooter.on_enemy_killed(target)
	
func get_parried(new_shooter: Node) -> void:
	shooter = new_shooter
	is_parried = true
