extends CharacterBody2D

@export_category("Weapon System")
@export var master_weapon_scene: PackedScene
@export var starting_weapon_stats: Resource 

@export_category("Movement Stats")
@export var move_speed: float = 180.0
@export var dash_speed: float = 420.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

@export_category("Combat Stats")
@export var max_health: int = 100
@export var invincibility_duration: float = 0.35
@export var fire_action: String = "shoot"
@export var reload_action: String = "reload"

@export_category("Spawners")
@export var floor_weapon_scene: PackedScene 

@export_category("Parry Settings")
@export var parry_duration: float = 0.9  # How long the active parry frames last
@export var parry_cooldown: float = 0.1  # How long until you can parry again

@onready var parry_hitbox: Area2D = $ParryHitbox
@onready var dash_particles = $DashParticles2D

signal health_changed(current: int, max: int)
signal inventory_changed()
signal ammo_changed(current: int, max: int)
signal weapon_reloaded(slot_index: int)

var health: int = max_health
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var invincibility_timer: float = 0.0
var is_dashing: bool = false
var last_direction: Vector2 = Vector2.RIGHT
var current_xp: int = 0
var is_parrying: bool = false
var parry_cooldown_timer: float = 0.0

var inventory: Array = [null, null]
var active_weapon_index: int = 0

func _ready() -> void:
	health = max_health

	# --- NEW MODULAR WEAPON LOADING ---
	if master_weapon_scene and starting_weapon_stats:
		var w = master_weapon_scene.instantiate()
		w.stats = starting_weapon_stats # Inject the stats BEFORE it enters the tree!
		add_child(w)
		inventory[0] = w
		active_weapon_index = 0
		
		# Connect weapon ammo/reload signals to re-emit for UI 
		if w.has_signal("ammo_changed"):
			w.ammo_changed.connect(_on_weapon_ammo_changed)
		if w.has_signal("reload_finished"):
			w.reload_finished.connect(_on_weapon_reload_finished)
	else:
		printerr("Player Error: Master Weapon Scene or Starting Stats missing in Inspector!")

	emit_signal("inventory_changed")
	emit_signal("health_changed", health, max_health)

func _physics_process(delta: float) -> void:
	# Dash Timer Logic
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
		dash_particles.emitting = is_dashing
	if parry_cooldown_timer > 0.0:
		parry_cooldown_timer -= delta

	# Movement Logic
	var input_direction: Vector2 = Vector2(
		Input.get_axis("Left", "Right"),
		Input.get_axis("Up", "Down")
	).normalized()

	if input_direction.length_squared() > 0.0:
		last_direction = input_direction

	# Dash Input
	var dash_pressed: bool = Input.is_action_just_pressed("L_Shift")
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

	# --- WEAPON INPUT LOGIC ---
	var w = get_active_weapon()
	if w:
		# continuous fire while holding
		if Input.is_action_pressed("Left Click"):
			if w.has_method("fire_weapon"):
				w.call("fire_weapon", Vector2.ZERO, self)
		# reload on press
		if Input.is_action_just_pressed("Reload"):
			if w.has_method("reload"):
				w.call("reload")

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

	emit_signal("health_changed", health, max_health)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	emit_signal("health_changed", health, max_health)

func die() -> void:
	print("Player died")
	queue_free()

func pick_up_weapon(weapon_stats: Resource) -> bool:
	for i in range(inventory.size()):
		if inventory[i] == null:
			var new_weapon = null
			if master_weapon_scene:
				new_weapon = master_weapon_scene.instantiate()
				new_weapon.stats = weapon_stats
				add_child(new_weapon)
			else:
				new_weapon = weapon_stats
			
			inventory[i] = new_weapon
			active_weapon_index = i
			
			if new_weapon is Node and new_weapon.has_signal("ammo_changed") and not new_weapon.ammo_changed.is_connected(_on_weapon_ammo_changed):
				new_weapon.ammo_changed.connect(_on_weapon_ammo_changed)
			if new_weapon is Node and new_weapon.has_signal("reload_finished") and not new_weapon.reload_finished.is_connected(_on_weapon_reload_finished):
				new_weapon.reload_finished.connect(_on_weapon_reload_finished)
			
			emit_signal("inventory_changed")
			print("Equipped new weapon!")
			return true
	
	print("Inventory is full!")
	return false

func _on_weapon_ammo_changed(current: int, max: int) -> void:
	emit_signal("ammo_changed", current, max)

func _on_weapon_reload_finished() -> void:
	emit_signal("weapon_reloaded", active_weapon_index)

func equip_weapon(index: int) -> void:
	if index >= 0 and index < inventory.size():
		if inventory[index] != null:
			active_weapon_index = index
			if inventory[active_weapon_index].has_method("on_equip"):
				inventory[active_weapon_index].call("on_equip")
				
			var w = inventory[active_weapon_index]
			if w.has_signal("ammo_changed") and not w.ammo_changed.is_connected(_on_weapon_ammo_changed):
				w.ammo_changed.connect(_on_weapon_ammo_changed)
			if w.has_signal("reload_finished") and not w.reload_finished.is_connected(_on_weapon_reload_finished):
				w.reload_finished.connect(_on_weapon_reload_finished)
				
			# Emit current ammo for HUD
			if w.has_method("get_ammo"):
				var a = w.call("get_ammo")
				if typeof(a) == TYPE_DICTIONARY and a.has("current") and a.has("max"):
					emit_signal("ammo_changed", a["current"], a["max"])
			emit_signal("inventory_changed")

func swap_weapon_slots() -> void:
	var tmp = inventory[0]
	inventory[0] = inventory[1]
	inventory[1] = tmp
	active_weapon_index = 1 if active_weapon_index == 0 else 0

func get_active_weapon():
	if active_weapon_index >= 0 and active_weapon_index < inventory.size():
		return inventory[active_weapon_index]
	return null

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("Space") and parry_cooldown_timer <= 0.0 and not is_dashing:
		execute_parry()
	if Input.is_action_just_pressed("Q"):
		drop_active_weapon()
	elif Input.is_action_just_pressed("E"):
		var swap_index: int = 1 if active_weapon_index == 0 else 0
		if inventory[swap_index] != null:
			equip_weapon(swap_index)

func drop_active_weapon() -> void:
	var active_weapon = inventory[active_weapon_index]
	
	if active_weapon != null:
		# Spawn the floor weapon scene
		var drop = floor_weapon_scene.instantiate()
		drop.global_position = global_position
		
		# THE FIX: Check if the inventory item is a Node, and extract its stats!
		if active_weapon is Node2D and "stats" in active_weapon:
			drop.stats = active_weapon.stats
		else:
			# Fallback in case your inventory is holding the raw Resource
			drop.stats = active_weapon
			
		get_tree().current_scene.add_child(drop)
		
		# Clear the slot in our inventory
		inventory[active_weapon_index] = null
		
		# If your active_weapon is a Node that stays in the tree, you might want to hide it
		if active_weapon is Node2D:
			active_weapon.hide() # Hides the gun visually since you dropped it
			
		emit_signal("inventory_changed")
		print("Dropped weapon!")

func execute_parry() -> void:
	is_parrying = true
	parry_cooldown_timer = parry_cooldown
	
	# Turn on the hitbox
	parry_hitbox.set_deferred("monitoring", true)
	
	
	# Visual cue (turns Perry briefly blue/cyan so you know it's active)
	modulate = Color(0.806, 0.102, 0.0, 1.0) 
	
	# Wait for the active frames to finish
	await get_tree().create_timer(parry_duration).timeout

	# Turn off the hitbox and return color to normal
	parry_hitbox.set_deferred("monitoring", false)
	is_parrying = false
	modulate = Color(1.0, 1.0, 1.0)

func gain_xp(amount: int) -> void:
	current_xp += amount
	print("Gained XP! Total: ", current_xp)
	# We will build out the level-up logic later!


func _on_parry_hitbox_area_entered(area: Area2D) -> void:
	# Check if the object entering our hitbox has our new parry function
	if area.has_method("get_parried"):
		# Make sure we don't parry our own bullets as they spawn!
		if area.shooter != self:
			print("Parry successful!")
			$"ParryHitbox/ParrySparks".restart()
			area.get_parried(self)
