extends Node2D

# --- SIGNALS ---
signal ammo_changed(current: int, max: int)
signal reload_started()
signal reload_finished()

# --- MODULAR DATA ---
@export_category("Weapon Configuration")
@export var stats: WeaponStats

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

var wielder : CharacterBody2D

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
	var legacy_revolver = get_node_or_null("Revolver")
	if legacy_revolver:
		legacy_revolver.queue_free()

	if stats == null:
		printerr("Weapon Error: No WeaponStats resource assigned!")
		return
		
	current_ammo = get_magazine_size()
	
	if sprite:
		if stats.weapon_texture:
			sprite.texture = stats.weapon_texture
		_orig_sprite_scale_x = sprite.scale.x
		
	if muzzle:
		muzzle.position = stats.muzzle_position
	
	if fire_timer:
		fire_timer.one_shot = true
		fire_timer.timeout.connect(_on_fire_timer_timeout)
		update_fire_rate()
		
	if reload_timer:
		reload_timer.one_shot = true
		reload_timer.timeout.connect(_on_reload_complete)
		update_reload_speed()

	if reload_texture and reload_sprite == null:
		reload_sprite = Sprite2D.new()
		reload_sprite.texture = reload_texture
		reload_sprite.visible = false
		reload_sprite.z_index = 100
		get_tree().current_scene.call_deferred("add_child", reload_sprite)

func _exit_tree() -> void:
	if reload_sprite and is_instance_valid(reload_sprite):
		reload_sprite.queue_free()

func _process(delta: float) -> void:
	if is_reloading and reload_sprite and is_instance_valid(reload_sprite):
		reload_sprite.visible = true
		reload_sprite.global_position = get_global_mouse_position()
		reload_sprite.rotation += 10.0 * delta

	if not aim_at_cursor:
		return
		
	var mouse_pos = get_global_mouse_position()
	var origin = muzzle.global_position if muzzle else global_position
	var dir = mouse_pos - origin
	
	if dir.length_squared() > 0:
		aim_direction = dir.normalized()
		rotation = aim_direction.angle()

	if sprite:
		sprite.flip_v = (cos(rotation) < 0.0)

func can_fire() -> bool:
	return can_shoot and not is_reloading and current_ammo > 0 and stats != null and stats.projectile_scene != null

func update_fire_rate() -> void:
	if fire_timer:
		fire_timer.wait_time = 1.0 / max(0.001, get_fire_rate())

func update_reload_speed() -> void:
	if reload_timer:
		reload_timer.wait_time = max(0.01, get_reload_time())

func refresh_stats() -> void:
	update_fire_rate()
	update_reload_speed()
	emit_signal("ammo_changed", current_ammo, get_magazine_size())

func fire_weapon(direction: Vector2 = Vector2.RIGHT, shooter = null) -> void:
	if not can_fire():
		return
		
	if aim_at_cursor and (direction == Vector2.RIGHT or direction.length_squared() == 0):
		direction = aim_direction
		
	var base_dir = direction.normalized()
	var spread_rad = deg_to_rad(stats.spread_angle)
	
	for i in range(stats.number_of_projectiles):
		var projectile = stats.projectile_scene.instantiate()
		if not projectile: continue
		
		if muzzle:
			projectile.global_position = muzzle.global_position
			projectile.rotation = muzzle.global_rotation
		else:
			projectile.global_position = global_position
			projectile.rotation = rotation
			
		var final_dir = base_dir
		
		if stats.fire_pattern == WeaponStats.FirePattern.SHOTGUN and stats.number_of_projectiles > 1:
			var step = spread_rad / (stats.number_of_projectiles - 1)
			var start_angle = -spread_rad / 2.0
			var current_angle = start_angle + (step * i)
			final_dir = base_dir.rotated(current_angle)
			
		if "damage" in projectile:
			projectile.damage = get_damage()
		if "speed" in projectile:
			projectile.speed = get_projectile_speed()
		if "piercing_remaining" in projectile:
			projectile.piercing_remaining = get_piercing()
		if "direction" in projectile:
			projectile.direction = final_dir
		if "shooter" in projectile:
			projectile.shooter = shooter 
			
		var scene_root = get_tree().get_current_scene()
		if scene_root:
			scene_root.add_child(projectile)
		else:
			get_parent().add_child(projectile)
			
	current_ammo -= 1
	can_shoot = false
	emit_signal("ammo_changed", current_ammo, get_magazine_size())

	if stats and stats.fire_sound:
		var audio := AudioStreamPlayer2D.new()
		audio.stream = stats.fire_sound
		audio.volume_db = stats.fire_sound_volume_db
		audio.global_position = global_position
		get_tree().current_scene.add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)

	if fire_timer:
		fire_timer.start()
	
	if current_ammo <= 0:
		reload()

func reload() -> void:
	if is_reloading or current_ammo == get_magazine_size():
		return
		
	is_reloading = true
	emit_signal("reload_started")
	
	if reload_sprite:
		reload_sprite.visible = true
		
	if reload_timer:
		reload_timer.start()

func _on_reload_complete() -> void:
	current_ammo = get_magazine_size()
	is_reloading = false
	if reload_sprite: reload_sprite.visible = false
	emit_signal("ammo_changed", current_ammo, get_magazine_size())
	emit_signal("reload_finished")

func _on_fire_timer_timeout() -> void:
	can_shoot = true
	

func get_ammo() -> Dictionary:
	return {"current": current_ammo, "max": get_magazine_size()}

func get_fire_rate() -> float:
	var rate = stats.fire_rate
	if wielder:
		var wielder_stats = wielder.get("combat_stats")
		if wielder_stats:
			rate = (rate + wielder_stats.bonus_attack_speed) * wielder_stats.fire_rate_multiplier
	return rate

func get_damage() -> float:
	var dmg = stats.damage
	if wielder:
		var wielder_stats = wielder.get("combat_stats")
		if wielder_stats:
			dmg = (dmg + wielder_stats.bonus_damage) * wielder_stats.damage_multiplier
		else:
			var enemy_damage_multiplier = wielder.get("damage_multiplier")
			if enemy_damage_multiplier != null:
				dmg *= enemy_damage_multiplier
	var crit_chance := stats.critical_chance
	if wielder and wielder.has_method("get_crit_overload_bonus"):
		crit_chance += wielder.get_crit_overload_bonus()
	if randf() < clamp(crit_chance, 0.0, 1.0):
		dmg *= stats.critical_damage
	return dmg

func get_projectile_speed() -> float:
	var speed = stats.projectile_speed
	if wielder:
		var wielder_stats = wielder.get("combat_stats")
		if wielder_stats:
			speed = (speed + wielder_stats.projectile_speed_bonus) * wielder_stats.projectile_speed_multiplier
	return speed

func get_magazine_size() -> int:
	var mag = stats.magazine_size
	if wielder:
		var wielder_stats = wielder.get("combat_stats")
		if wielder_stats:
			mag = int((mag + wielder_stats.magazine_size_bonus) * wielder_stats.magazine_size_multiplier)
	return mag

func get_reload_time() -> float:
	var reload = stats.reload_time
	if wielder:
		var wielder_stats = wielder.get("combat_stats")
		if wielder_stats:
			# We subtract bonuses (flat reduction) and divide by the multiplier (2.0 mult = half the time)
			reload = max(0.01, (reload - wielder_stats.reload_speed_bonus) / wielder_stats.reload_speed_multiplier)
	return reload

func get_piercing() -> int:
	var pierce = stats.piercing
	if wielder:
		var wielder_stats = wielder.get("combat_stats")
		if wielder_stats:
			pierce = int((pierce + wielder_stats.piercing_bonus) * wielder_stats.piercing_multiplier)
	return pierce
