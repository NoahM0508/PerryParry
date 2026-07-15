extends Node2D

# --- SIGNALS ---
signal ammo_changed(current: int, max: int)
signal reload_started()
signal reload_finished()

# --- MODULAR DATA ---
@export_category("Weapon Configuration")
@export var stats: WeaponStats
@export var projectile_scene: PackedScene

# --- NODES ---
@export_category("Node References")
@export var muzzle_node_path: NodePath = NodePath("Muzzle")
@export var fire_timer_node_path: NodePath = NodePath("FireTimer")
@export var reload_timer_node_path: NodePath = NodePath("ReloadTimer")
@export var sprite_node_path: NodePath = NodePath("Sprite2D")

# --- VISUALS ---
@export_category("Visuals & Settings")
@export var aim_at_cursor: bool = true
@export var reload_texture: Texture2D 
@export var reload_icon_scale: float = 0.5 

var current_ammo: int
var is_reloading: bool = false
var can_shoot: bool = true
var aim_direction: Vector2 = Vector2.RIGHT
var _orig_sprite_scale_x: float = 1.0

@onready var muzzle := get_node_or_null(muzzle_node_path)
@onready var fire_timer := get_node_or_null(fire_timer_node_path) as Timer
@onready var reload_timer := get_node_or_null(reload_timer_node_path) as Timer
@onready var sprite := get_node_or_null(sprite_node_path) as Sprite2D

var reload_sprite: Sprite2D

func _ready() -> void:
	if stats == null:
		printerr("Weapon Error: No WeaponStats resource assigned in the Inspector!")
		return
		
	current_ammo = stats.magazine_size
	
	# --- Swap artwork and move the muzzle dynamically! ---
	if sprite:
		if stats.weapon_texture:
			sprite.texture = stats.weapon_texture
		_orig_sprite_scale_x = sprite.scale.x
		
	if muzzle:
		muzzle.position = stats.muzzle_position
	
	# Configure our timers dynamically using the Resource data!
	if fire_timer:
		fire_timer.wait_time = 1.0 / max(0.0001, stats.fire_rate)
		fire_timer.one_shot = true
		fire_timer.timeout.connect(_on_fire_timer_timeout)
		
	if reload_timer:
		reload_timer.wait_time = stats.reload_time
		reload_timer.one_shot = true
		reload_timer.timeout.connect(_on_reload_complete)

	# Setup Reload Visual Node
	if reload_texture:
		reload_sprite = Sprite2D.new()
		reload_sprite.texture = reload_texture
		reload_sprite.top_level = true 
		reload_sprite.visible = false
		reload_sprite.z_index = 100 
		reload_sprite.scale = Vector2(reload_icon_scale, reload_icon_scale)
		add_child(reload_sprite)
		
	emit_signal("ammo_changed", current_ammo, stats.magazine_size)

func _process(delta: float) -> void:
	# Handle spinning reload cursor
	if is_reloading and reload_sprite and reload_sprite.visible:
		reload_sprite.global_position = get_global_mouse_position()
		reload_sprite.rotation += 10.0 * delta # Adjust this multiplier for spin speed

	# Handle cursor aiming
	if not aim_at_cursor:
		return
		
	var mouse_pos = get_global_mouse_position()
	var origin = muzzle.global_position if muzzle else global_position
	var dir = mouse_pos - origin
	
	if dir.length_squared() > 0:
		aim_direction = dir.normalized()
		rotation = aim_direction.angle()

func can_fire() -> bool:
	return can_shoot and not is_reloading and current_ammo > 0 and projectile_scene != null and stats != null

func fire_weapon(direction: Vector2 = Vector2.RIGHT, shooter = null) -> void:
	if not can_fire():
		return
		
	# Override direction if aiming at cursor
	if aim_at_cursor and (direction == Vector2.RIGHT or direction.length_squared() == 0):
		direction = aim_direction
		
	var base_dir = direction.normalized()
	var spread_rad = deg_to_rad(stats.spread_angle) # Godot math uses radians!
	
	# Loop to spawn the correct number of projectiles
	for i in range(stats.number_of_projectiles):
		var projectile = projectile_scene.instantiate()
		if not projectile: continue
		
		# Placement
		if muzzle:
			projectile.global_position = muzzle.global_position
			projectile.rotation = muzzle.global_rotation
		else:
			projectile.global_position = global_position
			projectile.rotation = rotation
			
		# --- PHASE 4: FIRE PATTERN MATH ---
		var final_dir = base_dir
		
		if stats.fire_pattern == WeaponStats.FirePattern.SHOTGUN and stats.number_of_projectiles > 1:
			var step = spread_rad / (stats.number_of_projectiles - 1)
			var start_angle = -spread_rad / 2.0
			var current_angle = start_angle + (step * i)
			final_dir = base_dir.rotated(current_angle)
			
		# Pass the advanced stats to the bullet!
		if "damage" in projectile:
			projectile.damage = stats.damage
		if "speed" in projectile:
			projectile.speed = stats.projectile_speed
		if "direction" in projectile:
			projectile.direction = final_dir # Pass our calculated spread direction!
		if "shooter" in projectile:
			projectile.shooter = shooter 
			
		# Spawning
		var scene_root = get_tree().get_current_scene()
		if scene_root:
			scene_root.add_child(projectile)
		else:
			get_parent().add_child(projectile)
			
	# State Management (Only costs 1 ammo per trigger pull, even if it shoots 5 pellets)
	current_ammo -= 1
	can_shoot = false
	emit_signal("ammo_changed", current_ammo, stats.magazine_size)
	
	if fire_timer:
		fire_timer.start()
	
	# Auto-reload check
	if current_ammo <= 0:
		reload()

func reload() -> void:
	if is_reloading or current_ammo == stats.magazine_size:
		return
		
	is_reloading = true
	emit_signal("reload_started")
	
	if reload_sprite:
		reload_sprite.visible = true
		
	if reload_timer:
		reload_timer.start()

func _on_reload_complete() -> void:
	current_ammo = stats.magazine_size
	is_reloading = false
	
	if reload_sprite:
		reload_sprite.visible = false
		
	emit_signal("ammo_changed", current_ammo, stats.magazine_size)
	emit_signal("reload_finished")

func _on_fire_timer_timeout() -> void:
	can_shoot = true
	
func get_ammo() -> Dictionary:
	return {"current": current_ammo, "max": stats.magazine_size}
