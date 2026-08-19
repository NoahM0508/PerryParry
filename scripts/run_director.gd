extends Node
class_name RunDirector

signal wave_started(wave_index: int, total_waves: int)
signal wave_cleared(wave_index: int, total_waves: int)
signal all_waves_cleared()
signal overtime_started()

@export_category("Scene References")
@export var enemy_scene: PackedScene
@export var spawn_points_path: NodePath = NodePath("SpawnPoints")
@export var exit_door_path: NodePath

@export_category("Wave Configuration")
## List of enemy counts for each wave in this arena.
## e.g., [10, 20, 30] for 3 waves in Arena 1
## e.g., [10, 20, 25, 30, 35, 45] for 6 waves in Arena 2
@export var wave_enemy_counts: Array[int] = [10, 20, 30]

## Time in seconds between individual enemy spawns during a wave
@export var spawn_interval: float = 1.0

@export_category("Overtime Settings")
@export var overtime_wave_delay: float = 4.0

var current_wave_index: int = 0
var enemies_spawned_in_wave: int = 0
var active_wave_enemies: Array[Node] = []
var is_spawning: bool = false
var arena_completed: bool = false
var is_overtime_active: bool = false

var spawn_timer: Timer
var overtime_timer: Timer
@onready var spawn_points_node: Node = get_node_or_null(spawn_points_path)

func _ready() -> void:
	add_to_group("RunDirector")

	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.wait_time = max(0.2, spawn_interval)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	overtime_timer = Timer.new()
	overtime_timer.one_shot = false
	overtime_timer.wait_time = overtime_wave_delay
	overtime_timer.timeout.connect(_on_overtime_timer_timeout)
	add_child(overtime_timer)

	lock_exit_door()

	await get_tree().create_timer(1.0).timeout
	start_wave(0)

func lock_exit_door() -> void:
	var door = get_node_or_null(exit_door_path)
	if door == null:
		var doors = get_tree().get_nodes_in_group("Doors")
		for d in doors:
			if d.get("is_exit_door") == true:
				door = d
				break
	if door and door.has_method("update_door_visuals"):
		door.is_unlocked = false
		door.update_door_visuals()

func unlock_exit_door() -> void:
	var doors = get_tree().get_nodes_in_group("Doors")
	for d in doors:
		if d.get("is_exit_door") == true and d.has_method("unlock"):
			d.unlock()

func start_wave(wave_index: int) -> void:
	if wave_index >= wave_enemy_counts.size():
		on_all_waves_completed()
		return

	current_wave_index = wave_index
	enemies_spawned_in_wave = 0
	active_wave_enemies.clear()
	is_spawning = true
	wave_started.emit(current_wave_index + 1, wave_enemy_counts.size())
	print("--- STARTING WAVE ", current_wave_index + 1, "/", wave_enemy_counts.size(), " (Target: ", wave_enemy_counts[current_wave_index], " enemies) ---")
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if current_wave_index >= wave_enemy_counts.size():
		spawn_timer.stop()
		return

	var target_count: int = wave_enemy_counts[current_wave_index]
	if enemies_spawned_in_wave < target_count:
		spawn_single_enemy()
		enemies_spawned_in_wave += 1
		print("RunDirector: Spawned enemy ", enemies_spawned_in_wave, "/", target_count, " for Wave ", current_wave_index + 1)

	if enemies_spawned_in_wave >= target_count:
		is_spawning = false
		spawn_timer.stop()
		print("RunDirector: All ", target_count, " enemies spawned for Wave ", current_wave_index + 1)

func spawn_single_enemy() -> void:
	var scene_to_spawn = enemy_scene
	if scene_to_spawn == null:
		scene_to_spawn = load("res://PerryParry/scenes/Enemy.tscn")
	if scene_to_spawn == null:
		printerr("RunDirector Error: Could not load enemy scene!")
		return

	var instance = scene_to_spawn.instantiate()
	var points = get_spawn_points()
	var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	if points.size() > 0:
		var pt = points[randi() % points.size()]
		instance.global_position = pt.global_position + offset
	else:
		instance.global_position = Vector2(500, 300) + offset

	active_wave_enemies.append(instance)
	instance.tree_exiting.connect(func():
		active_wave_enemies.erase(instance)
	)

	get_tree().current_scene.call_deferred("add_child", instance)

	if instance.has_method("change_state") and "State" in instance:
		instance.call_deferred("change_state", instance.State.CHASE)

func get_spawn_points() -> Array[Node2D]:
	var points: Array[Node2D] = []
	var p_node = spawn_points_node if spawn_points_node else get_node_or_null(spawn_points_path)
	if p_node == null:
		p_node = get_tree().current_scene.find_child("SpawnPoints", true, false)
	if p_node:
		for child in p_node.get_children():
			if child is Node2D:
				points.append(child)
	return points

func _process(_delta: float) -> void:
	if arena_completed or is_spawning or current_wave_index >= wave_enemy_counts.size():
		return

	# Count alive enemies specifically belonging to this wave
	var alive_count: int = 0
	for enemy in active_wave_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			if enemy.get("current_state") != null and enemy.current_state == enemy.State.DEAD:
				continue
			alive_count += 1

	if alive_count == 0 and enemies_spawned_in_wave >= wave_enemy_counts[current_wave_index]:
		print("--- WAVE ", current_wave_index + 1, " CLEARED! ---")
		wave_cleared.emit(current_wave_index + 1, wave_enemy_counts.size())
		var next_index = current_wave_index + 1
		if next_index < wave_enemy_counts.size():
			start_wave(next_index)
		else:
			on_all_waves_completed()

func on_all_waves_completed() -> void:
	if arena_completed:
		return
	arena_completed = true
	all_waves_cleared.emit()
	if UpgradeManager != null:
		UpgradeManager.record_arena_room_cleared()
	unlock_exit_door()

	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("show_banner_message"):
		var is_boss: bool = hud.get("in_boss_room") == true
		if not is_boss:
			hud.show_banner_message("ARENA CLEARED! EXIT OPEN", Color.GREEN, 4.0)

func start_overtime() -> void:
	is_overtime_active = true
	overtime_started.emit()
	overtime_timer.start()

func _on_overtime_timer_timeout() -> void:
	if not is_overtime_active:
		return
	for i in range(3):
		spawn_single_enemy()
