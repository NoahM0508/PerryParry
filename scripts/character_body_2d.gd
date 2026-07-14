extends CharacterBody2D

@export var move_speed: float = 180.0
@export var dash_speed: float = 420.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var invincibility_duration: float = 0.35
@export var max_health: int = 100

var health: int = max_health
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var invincibility_timer: float = 0.0
var is_dashing: bool = false
var last_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			modulate.a = 1.0

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		if invincibility_timer <= 0.0:
			modulate.a = 1.0

	var input_direction: Vector2 = Vector2(
		Input.get_axis("Left", "Right"),
		Input.get_axis("Up", "Down")
	).normalized()

	if input_direction.length_squared() > 0.0:
		last_direction = input_direction

	var dash_pressed: bool = Input.is_action_just_pressed("L_Shift") or Input.is_action_just_pressed("ui_accept")
	if dash_pressed and dash_cooldown_timer <= 0.0:
		if input_direction.length_squared() > 0.0:
			start_dash(input_direction)
		elif last_direction.length_squared() > 0.0:
			start_dash(last_direction)

	if is_dashing:
		velocity = last_direction * dash_speed
	else:
		velocity = input_direction * move_speed

	move_and_slide()


func start_dash(direction: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	invincibility_timer = invincibility_duration
	last_direction = direction.normalized() if direction.length_squared() > 0.0 else last_direction
	modulate.a = 0.6
	velocity = last_direction * dash_speed


func take_damage(amount: int) -> void:
	if invincibility_timer > 0.0:
		return

	health = max(0, health - amount)
	invincibility_timer = invincibility_duration
	modulate.a = 0.6

	if health <= 0:
		die()


func heal(amount: int) -> void:
	health = min(max_health, health + amount)


func die() -> void:
	print("Player died")
	queue_free()
