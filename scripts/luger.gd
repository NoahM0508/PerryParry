extends Node2D


signal ammo_changed(current: int, max: int)
signal reload_started()
signal reload_finished()

@export var fire_rate: float = 5.0 # shots per second
@export var magazine_size: int = 8
@export var projectile_script_path: String = "res://PerryParry/scripts/Pistol Projectile.gd"
@export var muzzle_node_path: NodePath = NodePath("Muzzle")
@export var fire_timer_node_path: NodePath = NodePath("Timer")
@export var reload_time: float = 1.2
@export var reload_timer_node_path: NodePath = NodePath("ReloadTimer")

var current_ammo: int
var is_reloading: bool = false
var can_shoot: bool = true
var projectile_script

@onready var muzzle := get_node_or_null(muzzle_node_path)
@onready var fire_timer := get_node_or_null(fire_timer_node_path) as Timer
@onready var reload_timer := get_node_or_null(reload_timer_node_path) as Timer

@export var aim_at_cursor: bool = true
@export var sprite_node_path: NodePath = NodePath("Sprite")

var aim_direction: Vector2 = Vector2.RIGHT
var _orig_sprite_scale_x: float = 1.0

@onready var sprite := get_node_or_null(sprite_node_path)

func _ready() -> void:
	current_ammo = magazine_size
	projectile_script = load(projectile_script_path)
	if projectile_script == null:
		printerr("luger.gd: failed to load projectile script at ", projectile_script_path)
		projectile_script = load("res://PerryParry/scripts/Pistol Projectile.gd")
		if projectile_script == null:
			printerr("luger.gd: fallback failed to load projectile script at res://PerryParry/scripts/Pistol Projectile.gd")
	else:
		print("luger.gd: projectile script loaded, ammo=", current_ammo, "/", magazine_size)
	if fire_timer == null:
		fire_timer = get_node_or_null("Timer") as Timer
	if fire_timer:
		print("luger.gd: fire_timer found at ", fire_timer.get_path())
		fire_timer.one_shot = true
		fire_timer.wait_time = 1.0 / max(0.0001, fire_rate)
		fire_timer.connect("timeout", Callable(self, "_on_fire_timer_timeout"))
	else:
		printerr("luger.gd: no fire timer found; set fire_timer_node_path to the Timer node")

	if reload_timer:
		reload_timer.one_shot = true
		reload_timer.wait_time = max(0.01, reload_time)
		reload_timer.connect("timeout", Callable(self, "_on_reload_complete"))

	# fallback lookup for nodes that may have a different name in the scene
	if muzzle == null:
		muzzle = get_node_or_null("Muzzle")
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")

	# Emit initial ammo state for UI
	emit_signal("ammo_changed", current_ammo, magazine_size)

	# store original sprite scale x for flipping and enable processing for aiming
	if sprite:
		_orig_sprite_scale_x = sprite.scale.x

	set_process(true)


func _on_fire_timer_timeout() -> void:
	can_shoot = true
	print("luger.gd: fire timer timeout, can_shoot=", can_shoot)


func _process(delta: float) -> void:
	if not aim_at_cursor:
		return
	var mouse_pos = get_global_mouse_position()
	var origin = muzzle.global_position if muzzle != null else global_position
	var dir = (mouse_pos - origin)
	if dir.length_squared() == 0:
		return
	aim_direction = dir.normalized()
	rotation = aim_direction.angle()
	# no additional flip; rotation alone handles cursor aiming reliably
	# sprite.scale.x = abs(_orig_sprite_scale_x) * (aim_direction.x < 0 ? -1 : 1)


func can_fire() -> bool:
	return can_shoot and not is_reloading and current_ammo > 0 and projectile_script != null


func fire_weapon(direction: Vector2 = Vector2.RIGHT, shooter = null) -> void:
	print("fire_weapon called", "can_shoot=", can_shoot, "is_reloading=", is_reloading, "ammo=", current_ammo, "projectile=", projectile_script)
	if not can_fire():
		print("fire_weapon blocked: can_fire() false")
		return

	# if caller didn't provide a direction and we're aiming at cursor, use aim_direction
	if aim_at_cursor and (direction == Vector2.RIGHT or direction.length_squared() == 0):
		direction = aim_direction

	var proj = projectile_script.new()
	if proj == null:
		return

	# Position and direction
	if muzzle != null:
		proj.global_position = muzzle.global_position
		proj.rotation = muzzle.global_rotation
	else:
		proj.global_position = global_position
		proj.rotation = rotation

	# Set shooter and direction on projectile if those properties exist
	# Set projectile direction and shooter
	proj.set("direction", direction.normalized())
	proj.set("shooter", shooter)

	# Add to scene root
	var root = get_tree().get_current_scene()
	if root:
		root.add_child(proj)
		print("PROJECTILE ADDED TO TREE")
	else:
		get_parent().add_child(proj)
	
	print("PROJECTILE CREATED")
	current_ammo -= 1
	emit_signal("ammo_changed", current_ammo, magazine_size)
	can_shoot = false
	if fire_timer:
		fire_timer.start()


func reload() -> void:
	if is_reloading:
		return
	is_reloading = true
	emit_signal("reload_started")
	if reload_timer:
		reload_timer.start()
		return

	# fallback: use scene timer
	await get_tree().create_timer(reload_time).timeout
	_on_reload_complete()


func get_ammo() -> Dictionary:
	return {"current": current_ammo, "max": magazine_size}


func _set_fire_rate(new_rate: float) -> void:
	fire_rate = new_rate
	if fire_timer:
		fire_timer.wait_time = 1.0 / max(0.0001, fire_rate)


func _on_reload_complete() -> void:
	current_ammo = magazine_size
	is_reloading = false
	emit_signal("ammo_changed", current_ammo, magazine_size)
	emit_signal("reload_finished")
