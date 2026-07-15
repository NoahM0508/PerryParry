extends CharacterBody2D

@export_category("Weapon System")
@export var master_weapon_scene: PackedScene
@export var starting_weapon_stats: Resource # This will hold your starter_pistol.tres

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
		
		# Connect weapon ammo/reload signals to re-emit for UI (Godot 4 Syntax)
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

	# Movement Logic
	var input_direction: Vector2 = Vector2(
		Input.get_axis("Left", "Right"),
		Input.get_axis("Up", "Down")
	).normalized()

	if input_direction.length_squared() > 0.0:
		last_direction = input_direction

	# Dash Input
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

func pick_up_weapon(weapon) -> bool:
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = weapon
			active_weapon_index = i
			# Connect signals using clean Godot 4 syntax
			if weapon.has_signal("ammo_changed") and not weapon.ammo_changed.is_connected(_on_weapon_ammo_changed):
				weapon.ammo_changed.connect(_on_weapon_ammo_changed)
			if weapon.has_signal("reload_finished") and not weapon.reload_finished.is_connected(_on_weapon_reload_finished):
				weapon.reload_finished.connect(_on_weapon_reload_finished)
			emit_signal("inventory_changed")
			return true
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
