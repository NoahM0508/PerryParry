extends CharacterBody2D

@export_category("Weapon System")
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
@export var parry_duration: float = 0.22
@export var parry_whiff_cooldown: float = 0.55
@export var parry_xp_reward: int = 5
@export var parries_for_level_two: int = 8
@export var parries_required_increase: int = 4

@export_category("Parry Cone & Aiming")
@export var base_parry_cone_angle: float = 90.0   ## Full cone width in degrees
@export var parry_range: float = 80.0              ## Pixel reach of the cone
@export var sweet_spot_angle: float = 20.0         ## Center wedge for Perfect Parry
@export var sweet_spot_window: float = 0.08        ## Seconds at start for Perfect Parry

@export_category("Parry Effects")
@export var crit_overload_duration: float = 1.0
@export var crit_overload_bonus: float = 0.5
@export var parry_duplicate_spread_degrees: float = 24.0
@export var explosive_retaliation_radius: float = 80.0
@export var explosive_retaliation_damage: int = 30
@export var shockwave_radius: float = 90.0
@export var shockwave_damage: int = 12
@export var shockwave_push_distance: float = 32.0
@export var perfect_parry_damage_multiplier: float = 2.5

@export_category("Parry Combo")
@export var combo_timeout: float = 1.5           ## Seconds before combo resets
@export var combo_max_stacks: int = 5
@export var combo_damage_per_stack: float = 0.15  ## +15% deflection damage per stack
@export var combo_speed_per_stack: float = 0.05   ## +5% move speed per stack

@export var upgrades: PlayerUpgrades
@export var hud: CanvasLayer

@onready var parry_hitbox: Area2D = $ParryHitbox
@onready var parry_arc_visual: Node2D = $ParryArcVisual
@onready var dash_particles = $DashParticles2D
@onready var combat_stats: CombatStats = $Combat_stats

@onready var weapon_inventory: WeaponInventory = $WeaponInventory
@onready var weapon_holder: WeaponHolder = $WeaponHolder

# --- ANIMATION & AUDIO NODES ---
@onready var anim = $AnimatedSprite2D
@onready var audio_dash = $Audio/DashAudio
@onready var audio_parry = $Audio/ParryAudio
@onready var audio_flinch = $Audio/FlinchAudio
@onready var audio_die = $Audio/DieAudio

const upgrade_screen = preload("res://PerryParry/scenes/upgrade_screen.tscn")

signal health_changed(current: int, max: int)
signal ammo_changed(current: int, max: int)
signal weapon_reloaded(slot_index: int)
signal xp_changed(current, required, level)
signal parry_xp_changed(current, required, level)
signal dash_started(time: float)
signal parry_started(time: float)

var health: int = max_health
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var invincibility_timer: float = 0.0
var is_dashing: bool = false
var last_direction: Vector2 = Vector2.RIGHT
var player_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100
var parry_level: int = 1
var current_parry_xp: int = 0
var parry_xp_to_next: int = 4
var is_parrying: bool = false
var parry_cooldown_timer: float = 0.0
var pending_upgrade_queue: Array[String] = []
var upgrade_in_progress: bool = false
var passive_regen_bank: float = 0.0
var crit_overload_timer: float = 0.0

# --- DIRECTIONAL PARRY STATE ---
var parry_aim_direction: Vector2 = Vector2.RIGHT
var parried_in_current_window: bool = false
var parry_active_timer: float = 0.0   ## Counts UP from 0 during active parry window
var is_perfect_parry: bool = false

# --- PARRY COMBO STATE ---
var combo_count: int = 0
var combo_timer: float = 0.0


func _ready() -> void:
	add_to_group("Player")
	if combat_stats:
		combat_stats.base_max_health = max_health
		combat_stats.base_move_speed = move_speed
	parry_xp_to_next = parries_for_level_two
	rebuild_stats()
	health = max_health

	# Restore state if returning from an Arena scene transition!
	if UpgradeManager.has_saved_data:
		UpgradeManager.restore_player_state(self)
		UpgradeManager.restore_current_scene_state(get_tree().current_scene)

	# 1. If returning to maze level from an Arena exit door
	if UpgradeManager.is_returning_to_maze and UpgradeManager.return_spawn_position != Vector2.ZERO:
		global_position = UpgradeManager.return_spawn_position + Vector2(0, 32)
		UpgradeManager.return_spawn_position = Vector2.ZERO
		UpgradeManager.is_returning_to_maze = false
	# 2. Otherwise, if entering an Arena room, position player right in front of the Arena door in the new scene
	elif not UpgradeManager.is_returning_to_maze:
		var doors = get_tree().get_nodes_in_group("Doors")
		var matched_door: Node2D = null
		for d in doors:
			if d is Node2D:
				if d.get("is_exit_door") == true or d.get("door_id") == UpgradeManager.target_door_id:
					matched_door = d
					break
		if matched_door != null:
			global_position = matched_door.global_position + Vector2(0, 48)
		UpgradeManager.target_door_id = 0

	# Listen for new physical weapons to hook up their UI signals
	weapon_holder.weapon_changed.connect(_on_weapon_changed)

	weapon_holder.initialize(self)

	# Only equip starting weapon on a fresh run when no saved data exists!
	if not UpgradeManager.has_saved_data and starting_weapon_stats and weapon_inventory.slots[0] == null:
		weapon_inventory.equip_weapon(starting_weapon_stats, 0)

	# Initialize the HUD if we linked it in the editor!
	if hud:
		hud.initialize(self)
		hud.visible = true
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
	if crit_overload_timer > 0.0:
		crit_overload_timer -= delta

	# Track how long parry has been active (for sweet spot window detection)
	if is_parrying:
		parry_active_timer += delta

	# Combo timer decay
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0

	process_passive_regen(delta)

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
		var speed_bonus: float = 1.0 + (combo_count * combo_speed_per_stack)
		velocity = input_direction * combat_stats.get_move_speed() * speed_bonus

	move_and_slide()

	# --- ANIMATION & FACING LOGIC ---
	if not is_dashing:
		var is_facing_left: bool = (get_global_mouse_position().x < global_position.x)
		anim.flip_h = !is_facing_left

		if not is_parrying:
			if velocity.length_squared() > 0:
				anim.play("Walk")
			else:
				anim.play("Idle")


	if Input.is_action_pressed("Left Click"):
		weapon_holder.fire()
	if Input.is_action_just_pressed("Reload"):
		weapon_holder.reload()

func start_dash(direction: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	invincibility_timer = invincibility_duration
	last_direction = direction.normalized() if direction.length_squared() > 0.0 else last_direction
	modulate.a = 0.6
	velocity = last_direction * dash_speed

	anim.play("Dash")
	if audio_dash: audio_dash.play()

	emit_signal("dash_started", dash_cooldown)

func take_damage(amount: int) -> void:
	if invincibility_timer > 0.0 or health <= 0:
		return

	var effective_evasion: float = combat_stats.get_effective_evasion_chance()
	if effective_evasion > 0.0 and randf() < effective_evasion:
		return

	var final_damage: int = max(0, amount - combat_stats.armor_rating)
	if final_damage <= 0:
		return

	health = max(0, health - final_damage)
	invincibility_timer = invincibility_duration
	modulate.a = 0.6

	if health > 0:
		anim.play("Flinch")
		if audio_flinch: audio_flinch.play()
	else:
		die()
	
	emit_signal("health_changed", health, max_health)

func heal(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = min(max_health, health + amount)
	emit_signal("health_changed", health, max_health)

func process_passive_regen(delta: float) -> void:
	if combat_stats.passive_regen <= 0.0 or health <= 0 or health >= max_health:
		passive_regen_bank = 0.0
		return

	passive_regen_bank += combat_stats.passive_regen * delta
	var whole_heal := int(passive_regen_bank)
	if whole_heal <= 0:
		return

	passive_regen_bank -= whole_heal
	heal(whole_heal)

func on_enemy_killed(_enemy: Node) -> void:
	if combat_stats.life_steal <= 0.0:
		return
	heal(int(combat_stats.life_steal))

func has_crit_overload_bonus() -> bool:
	return combat_stats.has_crit_overload and crit_overload_timer > 0.0

func get_crit_overload_bonus() -> float:
	return crit_overload_bonus if has_crit_overload_bonus() else 0.0

func die() -> void:
	print("Player died")
	is_parrying = false
	if parry_hitbox:
		parry_hitbox.set_deferred("monitoring", false)
	set_physics_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	if anim:
		anim.play("Die")
	if audio_die: audio_die.play()

	await get_tree().create_timer(0.5).timeout
	show_game_over_screen()

func show_game_over_screen() -> void:
	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.layer = 100
	canvas.script = load("res://PerryParry/scripts/game_over_screen.gd")

	var color_rect = ColorRect.new()
	color_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.color = Color(0, 0, 0, 0.7)
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(color_rect)

	var center = CenterContainer.new()
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title = Label.new()
	title.process_mode = Node.PROCESS_MODE_ALWAYS
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(title)

	if UpgradeManager != null and UpgradeManager.current_survival_time > 0.0:
		var time_label = Label.new()
		time_label.process_mode = Node.PROCESS_MODE_ALWAYS
		var mins: int = int(UpgradeManager.current_survival_time / 60.0)
		var secs: float = fmod(UpgradeManager.current_survival_time, 60.0)
		time_label.text = "SURVIVED: %02d:%04.1f" % [mins, secs]
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.add_theme_font_size_override("font_size", 28)
		time_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
		vbox.add_child(time_label)

	var restart_btn = Button.new()
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_btn.name = "RestartButton"
	restart_btn.text = "RESTART"
	restart_btn.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(restart_btn)

	var menu_btn = Button.new()
	menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_btn.name = "MainMenuButton"
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(menu_btn)

	get_tree().current_scene.add_child(canvas)

func pick_up_weapon(weapon_stats: Resource) -> bool:
	for i in range(weapon_inventory.MAX_SLOTS):
		if weapon_inventory.slots[i] == null:
			weapon_inventory.equip_weapon(weapon_stats, i)
			print("Equipped new weapon!")
			return true
	
	print("Inventory is full!")
	return false

# Hooks up the new weapon's signals dynamically when WeaponHolder creates it
func _on_weapon_changed(new_weapon: Node2D) -> void:
	if new_weapon:
		if new_weapon.has_signal("ammo_changed") and not new_weapon.ammo_changed.is_connected(_on_weapon_ammo_changed):
			new_weapon.ammo_changed.connect(_on_weapon_ammo_changed)
		if new_weapon.has_signal("reload_finished") and not new_weapon.reload_finished.is_connected(_on_weapon_reload_finished):
			new_weapon.reload_finished.connect(_on_weapon_reload_finished)

		# Force an immediate UI update for the newly held weapon
		if new_weapon.has_method("get_ammo"):
			var a = new_weapon.call("get_ammo")
			if typeof(a) == TYPE_DICTIONARY and a.has("current") and a.has("max"):
				emit_signal("ammo_changed", a["current"], a["max"])

func _on_weapon_ammo_changed(current: int, max: int) -> void:
	emit_signal("ammo_changed", current, max)

func _on_weapon_reload_finished() -> void:
	emit_signal("weapon_reloaded", weapon_inventory.equipped_slot)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Space") and parry_cooldown_timer <= 0.0 and not is_parrying and not is_dashing and health > 0:
		execute_parry()
	if Input.is_action_just_pressed("Q"):
		drop_active_weapon()
	elif Input.is_action_just_pressed("Swap_Weapon"):
		weapon_inventory.swap()

func drop_active_weapon() -> void:
	var active_stats = weapon_inventory.slots[weapon_inventory.equipped_slot]

	if active_stats != null:
		var drop = floor_weapon_scene.instantiate()
		drop.global_position = global_position
		drop.stats = active_stats
			
		get_tree().current_scene.add_child(drop)

		# Clear out the slot in the inventory
		weapon_inventory.equip_weapon(null, weapon_inventory.equipped_slot)
		print("Dropped weapon!")

func execute_parry() -> void:
	is_parrying = true
	parried_in_current_window = false
	parry_active_timer = 0.0
	is_perfect_parry = false

	# Record the aim direction toward the cursor at the moment of activation
	var mouse_pos = get_global_mouse_position()
	parry_aim_direction = global_position.direction_to(mouse_pos)
	if parry_aim_direction.length_squared() == 0.0:
		parry_aim_direction = Vector2.RIGHT

	parry_hitbox.set_deferred("monitoring", true)

	modulate = Color(1.0, 0.45, 0.45, modulate.a)
	emit_signal("parry_started", parry_whiff_cooldown)

	# Activate the procedural arc visual
	if parry_arc_visual and parry_arc_visual.has_method("activate"):
		parry_arc_visual.activate(
			parry_aim_direction,
			get_current_cone_angle(),
			parry_range,
			sweet_spot_angle
		)

	anim.play("Parry")
	if audio_parry: audio_parry.play()

	await get_tree().create_timer(get_parry_window()).timeout

	# --- Parry window expired ---
	parry_hitbox.set_deferred("monitoring", false)
	is_parrying = false

	# Deactivate the arc visual
	if parry_arc_visual and parry_arc_visual.has_method("deactivate"):
		parry_arc_visual.deactivate()

	if not is_dashing and invincibility_timer <= 0.0:
		modulate = Color(1.0, 1.0, 1.0, modulate.a)

	# --- WHIFF PENALTY: If nothing was parried, apply the long cooldown ---
	if not parried_in_current_window:
		parry_cooldown_timer = parry_whiff_cooldown
	# If something WAS parried, cooldown was already reset to 0.0 inside the
	# deflection handler, so the player can immediately parry again.

func get_parry_window() -> float:
	return parry_duration + combat_stats.window_extension

func get_current_cone_angle() -> float:
	## Returns the current cone angle in degrees, narrowed by parry_accuracy upgrades.
	## Each parry_accuracy level narrows the cone by 6 degrees (matching the old spread reduction).
	var narrowing: float = combat_stats.parry_accuracy_level * 6.0
	return max(20.0, base_parry_cone_angle - narrowing)

func is_in_parry_cone(target_position: Vector2) -> bool:
	## Check if a target position falls within the current directional parry cone.
	var to_target: Vector2 = global_position.direction_to(target_position)
	var angle_diff: float = abs(parry_aim_direction.angle_to(to_target))
	var half_cone_rad: float = deg_to_rad(get_current_cone_angle() / 2.0)
	var distance: float = global_position.distance_to(target_position)
	return angle_diff <= half_cone_rad and distance <= parry_range

func check_perfect_parry(target_position: Vector2) -> bool:
	## Returns true if this deflection qualifies as a Perfect Parry.
	## Condition 1: Within the first sweet_spot_window seconds of activation.
	## Condition 2: OR target is within the center sweet_spot_angle degrees.
	if parry_active_timer <= sweet_spot_window:
		return true
	var to_target: Vector2 = global_position.direction_to(target_position)
	var angle_diff: float = abs(parry_aim_direction.angle_to(to_target))
	var half_sweet_rad: float = deg_to_rad(sweet_spot_angle / 2.0)
	return angle_diff <= half_sweet_rad

func increment_combo() -> void:
	combo_count = min(combo_count + 1, combo_max_stacks)
	combo_timer = combo_timeout
	spawn_combo_popup()

func spawn_combo_popup() -> void:
	## Spawns a floating combo text above the player.
	if combo_count < 2:
		return

	var popup = Label.new()
	popup.text = "x%d COMBO!" % combo_count
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 18 + (combo_count * 2))

	# Color escalates with combo count
	var t: float = float(combo_count - 1) / float(max(1, combo_max_stacks - 1))
	popup.add_theme_color_override("font_color", Color(1.0, 1.0 - t * 0.6, 0.2, 1.0))

	popup.global_position = global_position + Vector2(-40, -50)
	popup.z_index = 200

	get_tree().current_scene.add_child(popup)

	# Animate the popup floating up and fading out
	var tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 40, 0.6)
	tween.tween_property(popup, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(popup.queue_free)

func get_combo_damage_multiplier() -> float:
	## Returns the current combo damage bonus as a multiplier (1.0 = no bonus).
	return 1.0 + (combo_count * combo_damage_per_stack)

func gain_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next_level:
		level_up()
	emit_signal("xp_changed", current_xp, xp_to_next_level, player_level)

func level_up() -> void:
	player_level += 1
	current_xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.15)

	pending_upgrade_queue.append("player")

	if !upgrade_in_progress:
		process_upgrade_queue()

func process_upgrade_queue() -> void:
	upgrade_in_progress = true

	while pending_upgrade_queue.size() > 0:
		var pool_type: String = pending_upgrade_queue.pop_front()

		get_tree().paused = true

		var screen = upgrade_screen.instantiate()
		get_tree().current_scene.add_child(screen)

		screen.open_upgrade_screen(upgrades, pool_type)

		await screen.upgrade_selected

		rebuild_stats()

	get_tree().paused = false
	upgrade_in_progress = false
	invincibility_timer = max(invincibility_timer, 0.5)

func gain_parry_xp(amount: int) -> void:
	current_parry_xp += amount
	while current_parry_xp >= parry_xp_to_next:
		parry_level_up()
	emit_signal("parry_xp_changed", current_parry_xp, parry_xp_to_next, parry_level)

func parry_level_up() -> void:
	parry_level += 1
	current_parry_xp -= parry_xp_to_next
	parry_xp_to_next += parries_required_increase + (parry_level * 2)

	pending_upgrade_queue.append("parry")

	if !upgrade_in_progress:
		process_upgrade_queue()

func _on_parry_hitbox_area_entered(area: Area2D) -> void:
	if area.get("is_parried") == true or area.get("is_duplicate") == true:
		return
	if not area.has_method("get_parried"):
		return
	if area.shooter == self:
		return

	# --- DIRECTIONAL CONE CHECK ---
	# Bullet must be within the parry cone aimed at the cursor
	if not is_in_parry_cone(area.global_position):
		return

	area.set("is_parried", true)
	var original_shooter = area.shooter
	$"ParryHitbox/ParrySparks".restart()

	# Check for Perfect Parry BEFORE deflecting
	is_perfect_parry = check_perfect_parry(area.global_position)

	deflect_projectile(area)
	area.get_parried(self)

	apply_parry_success_effects(area, original_shooter)

	# --- CHAIN PARRY: Reset cooldown instantly on successful deflection ---
	parried_in_current_window = true
	parry_cooldown_timer = 0.0

	# --- COMBO SYSTEM ---
	increment_combo()

	var parry_xp_gained: int = 1 + max(0, combat_stats.parry_accuracy_level - 10)
	if is_perfect_parry:
		parry_xp_gained += 1  # Bonus XP for perfect parries
	gain_parry_xp(parry_xp_gained)

func deflect_projectile(bullet: Area2D) -> void:
	if upgrades == null:
		printerr("Parry Math Failed: Upgrades resource not slotted!")
		return

	bullet.set("is_parried", true)

	# --- DEFLECTION DIRECTION: Aim toward the parry cone direction with accuracy spread ---
	var accuracy_level: int = clamp(combat_stats.parry_accuracy_level, 0, 10)
	var current_spread: float = max(0.0, 60.0 - (accuracy_level * 6.0))
	var random_angle_degrees: float = randf_range(-current_spread, current_spread)
	var random_angle_radians: float = deg_to_rad(random_angle_degrees)

	# Deflect toward where the player is aiming (cursor) instead of just reversing
	bullet.direction = parry_aim_direction.rotated(random_angle_radians)
	bullet.shooter = self

	# --- COMBO DAMAGE BONUS ---
	var damage_mult: float = get_combo_damage_multiplier()

	# --- PERFECT PARRY BONUS ---
	if is_perfect_parry:
		damage_mult *= perfect_parry_damage_multiplier
		# Perfect parries grant piercing
		if bullet.get("piercing_remaining") != null:
			bullet.piercing_remaining += 2

	# Apply damage scaling to the deflected bullet
	if bullet.get("damage") != null:
		bullet.damage = int(bullet.damage * damage_mult)

	spawn_duplicate_parry_bullets(bullet, bullet.direction)

func apply_parry_success_effects(bullet: Area2D, original_shooter) -> void:
	if combat_stats.has_crit_overload:
		crit_overload_timer = crit_overload_duration
	if combat_stats.heal_on_deflect > 0.0:
		heal(int(combat_stats.heal_on_deflect))
	if combat_stats.has_explosive:
		var origin: Vector2 = bullet.global_position if is_instance_valid(bullet) else global_position
		if is_instance_valid(original_shooter) and original_shooter is Node2D:
			origin = original_shooter.global_position
		damage_nearby_enemies(origin, explosive_retaliation_radius, explosive_retaliation_damage, false)
		spawn_vfx_ring(origin, explosive_retaliation_radius, Color(1.0, 0.35, 0.1, 0.75))
	if combat_stats.has_shockwave:
		damage_nearby_enemies(global_position, shockwave_radius, shockwave_damage, true)
		spawn_vfx_ring(global_position, shockwave_radius, Color(0.1, 0.75, 1.0, 0.75))

func spawn_vfx_ring(center_pos: Vector2, target_radius: float, color: Color) -> void:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return

	var ring = Node2D.new()
	ring.global_position = center_pos
	scene_root.add_child(ring)

	var duration: float = 0.35
	var tween = ring.create_tween()
	
	ring.draw.connect(func():
		if is_instance_valid(ring):
			var elapsed: float = tween.get_total_elapsed_time()
			var progress: float = clamp(elapsed / duration, 0.0, 1.0)
			var current_radius: float = target_radius * progress
			var alpha: float = (1.0 - progress) * color.a
			var fill_color = Color(color.r, color.g, color.b, alpha * 0.4)
			var line_color = Color(color.r, color.g, color.b, alpha)
			ring.draw_circle(Vector2.ZERO, current_radius, fill_color)
			ring.draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, line_color, 4.0)
	)

	tween.tween_method(func(_val: float):
		if is_instance_valid(ring):
			ring.queue_redraw()
	, 0.0, 1.0, duration)

	tween.finished.connect(func():
		if is_instance_valid(ring):
			ring.queue_free()
	)

func spawn_duplicate_parry_bullets(bullet: Area2D, base_direction: Vector2) -> void:
	if combat_stats.duplication_count <= 0:
		return

	var scene_root = get_tree().current_scene
	if scene_root == null:
		return

	var count: int = combat_stats.duplication_count
	var spread_rad: float = deg_to_rad(parry_duplicate_spread_degrees)
	for i in range(count):
		var copy = bullet.duplicate()
		if copy == null:
			continue
		copy.set("is_parried", true)
		copy.set("is_duplicate", true)
		var offset_index: float = i - ((count - 1) / 2.0)
		var angle: float = offset_index * spread_rad
		copy.global_position = bullet.global_position
		copy.rotation = bullet.rotation + angle
		if copy.get("direction") != null:
			copy.direction = base_direction.rotated(angle)
		if copy.get("shooter") != null:
			copy.shooter = self
		scene_root.call_deferred("add_child", copy)

func damage_nearby_enemies(origin: Vector2, radius: float, amount: int, push: bool) -> void:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return

	for node in scene_root.find_children("*", "CharacterBody2D", true, false):
		if node == self or not node.has_method("take_damage"):
			continue
		if node.global_position.distance_to(origin) > radius:
			continue

		node.take_damage(amount)
		if push and node is CharacterBody2D:
			var direction: Vector2 = origin.direction_to(node.global_position)
			if direction.length_squared() > 0.0:
				node.move_and_collide(direction.normalized() * shockwave_push_distance)

func rebuild_stats():
	var old_max = max_health

	combat_stats.reset()

	if upgrades:
		UpgradeManager.apply_all_upgrades(upgrades, combat_stats)

	max_health = combat_stats.get_max_health()
	move_speed = combat_stats.get_move_speed()

	if max_health > old_max:
		health += (max_health - old_max)

	var current_weapon = weapon_holder.get_weapon()
	if current_weapon:
		current_weapon.refresh_stats()

	health_changed.emit(health, max_health)
