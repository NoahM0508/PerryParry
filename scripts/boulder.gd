extends Area2D
class_name Boulder

@export var speed: float = 300.0
@export var damage: int = 25
@export var lifetime: float = 5.0
@export var rotation_speed: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null
var is_parried: bool = false
var has_hit_player: bool = false
var has_hit_target: bool = false

func _ready() -> void:
	add_to_group("Projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Auto-despawn after lifetime seconds
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation += rotation_speed * delta

func _on_body_entered(body: Node) -> void:
	if has_hit_target:
		return

	if not is_parried:
		# Hits player (only ONCE!)
		if body.is_in_group("Player") and not has_hit_player:
			has_hit_player = true
			has_hit_target = true
			if body.has_method("take_damage"):
				body.take_damage(damage)
			destroy_boulder()
		elif body is TileMap or body.is_in_group("Walls"):
			destroy_boulder()
	else:
		# Parried boulder hits boss or enemies!
		if body != shooter and body.has_method("take_damage"):
			has_hit_target = true
			body.take_damage(damage * 2)
			destroy_boulder()
		elif body is TileMap or body.is_in_group("Walls"):
			destroy_boulder()

func _on_area_entered(area: Area2D) -> void:
	if has_hit_target:
		return

	if is_parried and area.owner and area.owner != shooter and area.owner.has_method("take_damage"):
		has_hit_target = true
		area.owner.take_damage(damage * 2)
		destroy_boulder()

func get_parried(new_shooter: Node) -> void:
	if is_parried:
		return
	is_parried = true
	shooter = new_shooter
	direction = -direction
	modulate = Color(0.3, 0.8, 1.0) # Glow blue when parried!

func destroy_boulder() -> void:
	# Disable collision immediately to guarantee no multi-hits
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
