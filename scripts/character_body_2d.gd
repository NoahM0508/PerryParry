extends CharacterBody2D

@export var move_speed: float = 180.0
@export var dash_speed: float = 420.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var invincibility_duration: float = 0.35
@export var max_health: int = 100

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

	# Give player a starting weapon if a scene exists
	var luger_scene = load("res://PerryParry/scenes/luger.tscn")
	if luger_scene:
		var w = luger_scene.instantiate()
		add_child(w)
		inventory[0] = w
		active_weapon_index = 0
		# Connect weapon ammo/reload signals to re-emit for UI
		if w.has_signal("ammo_changed"):
			w.connect("ammo_changed", Callable(self, "_on_weapon_ammo_changed"))
		if w.has_signal("reload_finished"):
			w.connect("reload_finished", Callable(self, "_on_weapon_reload_finished"))
	else:
		printerr("character_body_2d.gd: failed to load player weapon scene res://PerryParry/scenes/luger.tscn")

	emit_signal("inventory_changed")
	emit_signal("health_changed", health, max_health)


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

	# Weapon input: fire and reload
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
			# connect weapon signals to player for UI updates
			if weapon.has_signal("ammo_changed") and not weapon.is_connected("ammo_changed", self, "_on_weapon_ammo_changed"):
				weapon.connect("ammo_changed", Callable(self, "_on_weapon_ammo_changed"))
			if weapon.has_signal("reload_finished") and not weapon.is_connected("reload_finished", self, "_on_weapon_reload_finished"):
				weapon.connect("reload_finished", Callable(self, "_on_weapon_reload_finished"))
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
			# ensure connected for UI updates
			var w = inventory[active_weapon_index]
			if w.has_signal("ammo_changed") and not w.is_connected("ammo_changed", self, "_on_weapon_ammo_changed"):
				w.connect("ammo_changed", Callable(self, "_on_weapon_ammo_changed"))
			if w.has_signal("reload_finished") and not w.is_connected("reload_finished", self, "_on_weapon_reload_finished"):
				w.connect("reload_finished", Callable(self, "_on_weapon_reload_finished"))
			# emit current ammo for HUD
			if w.has_method("get_ammo"):
				var a = w.call("get_ammo")
				if typeof(a) == TYPE_DICTIONARY and a.has("current") and a.has("max"):
					emit_signal("ammo_changed", a["current"], a["max"])
			emit_signal("inventory_changed")


func swap_weapon_slots() -> void:
	var tmp = inventory[0]
	inventory[0] = inventory[1]
	inventory[1] = tmp
	if active_weapon_index == 0:
		active_weapon_index = 1
	elif active_weapon_index == 1:
		active_weapon_index = 0


func get_active_weapon():
	if active_weapon_index >= 0 and active_weapon_index < inventory.size():
		return inventory[active_weapon_index]
	return null
