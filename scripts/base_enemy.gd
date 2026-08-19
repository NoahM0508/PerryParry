extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, COVER, HEAL, DEAD }

@export_category("Enemy Stats")
@export var max_health: int = 50
@export var move_speed: float = 120.0
@export var attack_range: float = 350.0
@export var low_health_percent: float = 0.30
@export_range(1, 10, 1) var ai_level: int = 1
@onready var health_bar: ProgressBar = $EnemyHealth

@export_category("Combat & Healing")
@export var attack_cooldown: float = 1.0 
@export var heal_amount: int = 5
@export var heal_interval: float = 0.5
@export var minimum_range: float = 110.0
@export var strafe_speed_multiplier: float = 0.8


@export_category("Drops")
@export var xp_shard_scene: PackedScene
@export var floor_weapon_scene: PackedScene
@export var drop_chance: float = .10 # 10% chance to drop a weapon

@export_category("Loot Settings")
@export var weapons_folder: String = "res://PerryParry/resources/weapons/"

@onready var player_detector: RayCast2D = $PlayerDetector
@onready var state_timer: Timer = $StateTimer
@onready var weapon = $Weapon
@onready var animated_sprite: Sprite2D = $Sprite2D


var current_state: State = State.IDLE
var current_health: int
var can_attack: bool = true 
var player_ref: CharacterBody2D = null
var damage_multiplier: float = 1.0
var health_multiplier: float = 1.0
var strafe_direction: int = 1
var burst_shots_remaining: int = 0

const AI_DAMAGE_MULTIPLIERS := [0.0, 1.0, 1.0, 1.1, 1.15, 1.2, 1.25, 1.35, 1.45, 1.6, 1.8]
const AI_HEALTH_MULTIPLIERS := [0.0, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 2.0]

func _ready() -> void:
	add_to_group("Enemies")
	apply_ai_scaling()
	current_health = max_health
	equip_random_weapon()
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_ref = players[0]

	state_timer.wait_time = heal_interval
	state_timer.timeout.connect(_on_state_timer_timeout)
	if player_detector:
		player_detector.add_exception(self)
	
	change_state(State.IDLE)


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
	
	update_animation()
	move_and_slide()


func process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	if can_see_player() or (player_exists() and get_tree().current_scene and ("arena" in get_tree().current_scene.name.to_lower() or "arena" in get_tree().current_scene.scene_file_path.to_lower())):
		change_state(State.CHASE)

func process_chase(_delta: float) -> void:
	if !player_exists():
		change_state(State.IDLE)
		return

	if is_low_health():
		change_state(State.COVER)
		return

	if try_dodge_projectile():
		return

	if distance_to_player() <= attack_range and can_see_player():
		change_state(State.ATTACK)
		return

	var direction = get_chase_direction()
	velocity = direction * move_speed

func process_attack(delta: float) -> void:
	if !player_exists():
		change_state(State.IDLE)
		return

	if is_low_health():
		change_state(State.COVER)
		return

	if try_dodge_projectile():
		return

	if distance_to_player() > attack_range or !can_see_player():
		change_state(State.CHASE)
		return

	velocity = Vector2.ZERO
	if ai_level >= 3:
		strafe_around_player()
	if ai_level >= 4 and distance_to_player() < minimum_range:
		var back_away = player_ref.global_position.direction_to(global_position)
		velocity = back_away * move_speed
	if ai_level >= 6 and burst_shots_remaining <= 0:
		burst_shots_remaining = 3
	fire_weapon()

func process_cover(_delta: float) -> void:
	if !player_exists():
		change_state(State.IDLE)
		return

	var direction = get_cover_direction()
	velocity = direction * move_speed

	if !can_see_player() or distance_to_player() > attack_range * 1.5:
		change_state(State.HEAL)

func process_heal(_delta: float) -> void:
	velocity = Vector2.ZERO
	if can_see_player():
		if is_low_health():
			change_state(State.COVER)
		else:
			change_state(State.CHASE)


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

func apply_ai_scaling() -> void:
	if UpgradeManager != null:
		ai_level = UpgradeManager.get_current_ai_level()

	ai_level = clamp(ai_level, 1, 10)
	var hp_mult: float = AI_HEALTH_MULTIPLIERS[ai_level] if ai_level < AI_HEALTH_MULTIPLIERS.size() else 1.5
	var dmg_mult: float = AI_DAMAGE_MULTIPLIERS[ai_level] if ai_level < AI_DAMAGE_MULTIPLIERS.size() else 1.5

	health_multiplier = hp_mult
	damage_multiplier = dmg_mult
	max_health = int(round(max_health * hp_mult))
	current_health = max_health
	if ai_level >= 10:
		heal_amount = int(round(heal_amount * 1.5))


func player_exists() -> bool:
	return player_ref != null and is_instance_valid(player_ref)

func distance_to_player() -> float:
	if !player_exists():
		return INF
	return global_position.distance_to(player_ref.global_position)

func is_low_health() -> bool:
	if ai_level < 10:
		return ai_level >= 5 and current_health <= max_health * low_health_percent
	return current_health <= max_health * low_health_percent

func get_chase_direction() -> Vector2:
	if ai_level >= 9:
		var flank_direction = get_flank_direction()
		if flank_direction.length_squared() > 0.0:
			return flank_direction
	return global_position.direction_to(player_ref.global_position)

func get_flank_direction() -> Vector2:
	var to_player = global_position.direction_to(player_ref.global_position)
	var side = Vector2(-to_player.y, to_player.x) * strafe_direction
	var desired = (to_player + side * 0.7).normalized()
	return desired

func strafe_around_player() -> void:
	var to_player = global_position.direction_to(player_ref.global_position)
	var strafe = Vector2(-to_player.y, to_player.x) * strafe_direction
	velocity = strafe * move_speed * strafe_speed_multiplier
	if randf() < 0.01:
		strafe_direction *= -1

func get_cover_direction() -> Vector2:
	var best_cover: Node2D = null
	var best_distance := INF
	for cover in get_tree().get_nodes_in_group("Cover"):
		if not cover is Node2D:
			continue
		var distance = global_position.distance_to(cover.global_position)
		if distance < best_distance:
			best_distance = distance
			best_cover = cover

	if best_cover:
		return global_position.direction_to(best_cover.global_position)
	return player_ref.global_position.direction_to(global_position)

func try_dodge_projectile() -> bool:
	if ai_level < 7 or !player_exists():
		return false

	var threat = find_incoming_projectile()
	if threat == null:
		return false

	var away = threat.global_position.direction_to(global_position)
	if away.length_squared() == 0.0:
		away = global_position.direction_to(player_ref.global_position).orthogonal()
	velocity = away.normalized() * move_speed * 1.25
	return true

func find_incoming_projectile() -> Area2D:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return null

	for projectile in scene_root.find_children("*", "Area2D", true, false):
		if projectile == null:
			continue
		if projectile.get("shooter") != player_ref:
			continue
		if projectile.global_position.distance_to(global_position) <= 90.0:
			return projectile
	return null

func can_see_player() -> bool:
	if !player_exists():
		return false
	
	player_detector.target_position = to_local(player_ref.global_position)
	player_detector.force_raycast_update()
	
	var collider = player_detector.get_collider()
	
	if collider != null:
		if collider == player_ref or collider.owner == player_ref:
			return true
			
	return false

func roll_weapon_rarity() -> String:
	var roll: float = randf() # Rolls a number between 0.00 and 1.00
	
	if roll <= 0.50:
		return "Common"      # 50% chance
	elif roll <= 0.75:
		return "Uncommon"    # 25% chance
	elif roll <= 0.90:
		return "Rare"        # 15% chance
	elif roll <= 0.97:
		return "Epic"        # 7% chance
	elif roll <= 0.995:
		return "Legendary"   # 2.5% chance
	else:
		return "Mythic"      # 0.5% chance


func equip_random_weapon() -> void:
	var rarity_folder: String = roll_weapon_rarity()
	
	var folder_path: String = "res://PerryParry/resources/weapons/" + rarity_folder + "/"
	var dir = DirAccess.open(folder_path)
	
	if dir:
		var files = dir.get_files()
		var weapon_files = []
		
		for file in files:
			if file.ends_with(".tres") or file.ends_with(".tres.remap"):
				weapon_files.append(file.replace(".remap", ""))
		
		if weapon_files.size() > 0:
			var random_file = weapon_files[randi() % weapon_files.size()]
			var weapon_stats = load(folder_path + random_file)
			
			if weapon_stats and weapon != null:
				weapon.stats = weapon_stats
				weapon.wielder = self
				weapon._ready() 
	else:
		printerr("Enemy AI Error: Could not open weapon folder at ", folder_path)

func fire_weapon() -> void:
	if not can_attack or not player_exists() or weapon == null:
		return
		
	can_attack = false
	
	var direction = get_aim_direction()
	
	weapon.rotation = direction.angle()
	
	if weapon.sprite:
		weapon.sprite.flip_v = (direction.x < 0)
	
	if weapon.has_method("fire_weapon"):
		weapon.fire_weapon(direction, self)
	if ai_level >= 6 and burst_shots_remaining > 0:
		burst_shots_remaining -= 1
	
	# Start cooldown timer dynamically
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func get_aim_direction() -> Vector2:
	if ai_level < 8 or player_ref == null:
		return global_position.direction_to(player_ref.global_position)

	var projectile_speed := 450.0
	if weapon and weapon.has_method("get_projectile_speed"):
		projectile_speed = weapon.get_projectile_speed()
	var distance = global_position.distance_to(player_ref.global_position)
	var lead_time = distance / max(1.0, projectile_speed)
	var predicted_position = player_ref.global_position + player_ref.velocity * lead_time
	return global_position.direction_to(predicted_position)


@export_category("Audio SFX")
@export var hit_sound: AudioStream = preload("res://PerryParry/assets/audio/player/hurt.mp3")
@export var death_sound: AudioStream = preload("res://PerryParry/assets/audio/player/die.mp3")

func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null or get_tree() == null or get_tree().current_scene == null:
		return
	var sfx_player = AudioStreamPlayer2D.new()
	sfx_player.stream = stream
	sfx_player.volume_db = -4.0
	sfx_player.pitch_scale = pitch
	sfx_player.global_position = global_position
	get_tree().current_scene.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	current_health -= amount
	play_hurt_animation()
	play_sfx(hit_sound, randf_range(1.15, 1.35))

	if health_bar: health_bar.value = current_health
	
	if current_health <= 0:
		die()
		return

	# Flash Red
	modulate = Color.RED
	await get_tree().create_timer(0.08).timeout
	modulate = Color.WHITE

	if is_low_health():
		change_state(State.COVER)
	elif current_state == State.IDLE or current_state == State.HEAL:
		# If we get shot while idling or healing, fight back!
		change_state(State.CHASE)

func die():
	change_state(State.DEAD)
	remove_from_group("Enemies")
	play_sfx(death_sound, randf_range(0.85, 1.05))

	if UpgradeManager != null:
		UpgradeManager.record_kill()

	velocity = Vector2.ZERO

	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	if animated_sprite and "sprite_frames" in animated_sprite:
		var frames = animated_sprite.get("sprite_frames")
		if frames and frames.has_method("has_animation") and frames.has_animation("Death"):
			frames.set_animation_loop("Death", false)
			animated_sprite.call("play", "Death")
		await get_tree().create_timer(0.45).timeout

	if xp_shard_scene:
		var shard = xp_shard_scene.instantiate()
		shard.global_position = global_position
		var scale_mult: int = 1 if ai_level <= 1 else (ai_level - 1) * 4
		if "xp_amount" in shard:
			shard.xp_amount = int(shard.xp_amount * scale_mult)
		get_tree().current_scene.call_deferred("add_child", shard)

	if floor_weapon_scene and weapon != null:
		if randf() <= drop_chance:
			var drop = floor_weapon_scene.instantiate()
			print("Weapon Dropped!")
			drop.global_position = global_position
			if "stats" in weapon:
				drop.stats = weapon.stats
			get_tree().current_scene.call_deferred("add_child", drop)

	call_deferred("queue_free")

func _on_state_timer_timeout() -> void:
	if current_state != State.HEAL:
		return

	current_health = clamp(current_health + heal_amount, 0, max_health)
	if health_bar: health_bar.value = current_health
	print("Healing: ", current_health)

	if current_health >= max_health:
		change_state(State.CHASE)


func update_animation() -> void:
	if animated_sprite == null or not animated_sprite.has_method("play"):
		return

	# Dead overrides everything
	if current_state == State.DEAD:
		if animated_sprite.get("animation") != "Death":
			animated_sprite.call("play", "Death")
		return

	# Flip based on movement
	if velocity.x != 0 and "flip_h" in animated_sprite:
		animated_sprite.flip_h = velocity.x < 0

	# Walk or Idle
	if velocity.length() > 5:
		if animated_sprite.get("animation") != "Walk":
			animated_sprite.call("play", "Walk")
	else:
		if animated_sprite.get("animation") != "Idle":
			animated_sprite.call("play", "Idle")


func play_hurt_animation() -> void:
	if animated_sprite == null or not animated_sprite.has_method("play"):
		return

	animated_sprite.call("play", "Hurt")
	if animated_sprite.has_signal("animation_finished"):
		await animated_sprite.animation_finished

	if current_state != State.DEAD:
		update_animation()
