extends CharacterBody2D

# =====================================================
# ENEMY STATE MACHINE
# =====================================================

enum State { IDLE, CHASE, ATTACK, COVER, HEAL, DEAD }

# =====================================================
# SETTINGS
# =====================================================

@export_category("Enemy Stats")
@export var max_health: int = 50
@export var move_speed: float = 120.0
@export var attack_range: float = 350.0
@export var low_health_percent: float = 0.30
@onready var health_bar: ProgressBar = $EnemyHealth

@export_category("Combat & Healing")
@export var attack_cooldown: float = 1.0 # Wait 1 second between shots
@export var heal_amount: int = 5
@export var heal_interval: float = 0.5

# =====================================================
# NODES
# =====================================================

@onready var player_detector: RayCast2D = $PlayerDetector
@onready var state_timer: Timer = $StateTimer
@onready var weapon: Node2D = $WeaponRoot

# =====================================================
# VARIABLES
# =====================================================

var current_state: State = State.IDLE
var current_health: int
var can_attack: bool = true # Prevents the 60 FPS rapid-fire bug
var player_ref: CharacterBody2D = null

# =====================================================
# READY
# =====================================================

func _ready() -> void:
	current_health = max_health

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_ref = players[0]

	state_timer.wait_time = heal_interval
	state_timer.timeout.connect(_on_state_timer_timeout)
# Stop the RayCast from hitting the enemy itself!
	if player_detector:
		player_detector.add_exception(self)
	
	change_state(State.IDLE)

# =====================================================
# MAIN LOOP
# =====================================================

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.CHASE:
			process_chase(delta)
		State.ATTACK:
			process_attack(delta)
		State.COVER:
			process_cover(delta)
		State.HEAL:
			process_heal(delta)
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

# =====================================================
# STATE LOGIC
# =====================================================

func process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	if can_see_player():
		change_state(State.CHASE)

func process_chase(_delta: float) -> void:
	if !player_exists():
		change_state(State.IDLE)
		return

	if is_low_health():
		change_state(State.COVER)
		return

	if distance_to_player() <= attack_range and can_see_player():
		change_state(State.ATTACK)
		return

	# Move toward the player
	var direction = global_position.direction_to(player_ref.global_position)
	velocity = direction * move_speed

func process_attack(_delta: float) -> void:
	if !player_exists():
		change_state(State.IDLE)
		return

	if is_low_health():
		change_state(State.COVER)
		return

	if distance_to_player() > attack_range or !can_see_player():
		change_state(State.CHASE)
		return

	velocity = Vector2.ZERO
	fire_weapon()

func process_cover(_delta: float) -> void:
	if !player_exists():
		change_state(State.IDLE)
		return

	# Run directly away from the player
	var direction = player_ref.global_position.direction_to(global_position)
	velocity = direction * move_speed

	# Heal when we break line of sight (hiding behind a wall) OR get far enough away
	if !can_see_player() or distance_to_player() > attack_range * 1.5:
		change_state(State.HEAL)

func process_heal(_delta: float) -> void:
	velocity = Vector2.ZERO
	# Stop healing and run/attack if the player finds us!
	if can_see_player():
		if is_low_health():
			change_state(State.COVER)
		else:
			change_state(State.CHASE)

# =====================================================
# STATE CHANGES
# =====================================================

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_timer.stop()

	match current_state:
		State.IDLE: print("State -> IDLE")
		State.CHASE: print("State -> CHASE")
		State.ATTACK: print("State -> ATTACK")
		State.COVER: print("State -> COVER")
		State.HEAL: 
			print("State -> HEAL")
			state_timer.start()
		State.DEAD: print("State -> DEAD")

# =====================================================
# HELPER FUNCTIONS
# =====================================================

func player_exists() -> bool:
	return player_ref != null and is_instance_valid(player_ref)

func distance_to_player() -> float:
	if !player_exists():
		return INF
	return global_position.distance_to(player_ref.global_position)

func is_low_health() -> bool:
	return current_health <= max_health * low_health_percent

func can_see_player() -> bool:
	if !player_exists():
		return false
	
	player_detector.target_position = to_local(player_ref.global_position)
	player_detector.force_raycast_update()
	
	var collider = player_detector.get_collider()
	
	if collider != null:
		# Check if the raycast hit the Player directly OR hit an Area2D belonging to the Player
		if collider == player_ref or collider.owner == player_ref:
			return true
			
	return false

# =====================================================
# WEAPON
# =====================================================

func fire_weapon() -> void:
	if not can_attack or not player_exists() or weapon == null:
		return
		
	can_attack = false
	
	# 1. Calculate the exact direction to the player
	var direction = global_position.direction_to(player_ref.global_position)
	
	# 2. Rotate the gun visually so the barrel points at the player
	weapon.rotation = direction.angle()
	
	# 3. Pull the trigger! We pass 'direction' for the bullet, and 'self' so the bullet knows the enemy fired it
	if weapon.has_method("fire_weapon"):
		weapon.fire_weapon(direction, self)
	
	# Start cooldown timer dynamically
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# =====================================================
# DAMAGE & DEATH
# =====================================================

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	current_health -= amount
	if health_bar: health_bar.value = current_health
	
	if current_health <= 0:
		die()
		return

	# Flash Red
	modulate = Color.RED
	await get_tree().create_timer(0.08).timeout
	modulate = Color.WHITE

	# --- THE FIX: WAKE UP AND FIGHT! ---
	if is_low_health():
		change_state(State.COVER)
	elif current_state == State.IDLE or current_state == State.HEAL:
		# If we get shot while idling or healing, fight back!
		change_state(State.CHASE)

func die() -> void:
	current_health = 0
	change_state(State.DEAD)
	# TODO: Phase 8 - Spawn loot pickup here before queue_free!
	queue_free()

func _on_state_timer_timeout() -> void:
	if current_state != State.HEAL:
		return

	current_health = clamp(current_health + heal_amount, 0, max_health)
	if health_bar: health_bar.value = current_health
	print("Healing: ", current_health)

	if current_health >= max_health:
		change_state(State.CHASE)
