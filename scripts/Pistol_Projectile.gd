extends Area2D

@export var damage: int = 10
@export var speed: float = 800.0 # pixels per second
@export var max_range: float = 1000.0

var direction: Vector2 = Vector2.RIGHT
var shooter = null
var start_pos: Vector2

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
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
