extends Area2D
class_name ArenaDoor

signal door_entered(door: ArenaDoor)

@export var door_id: int = 1
@export var is_boss_door: bool = false
@export var is_exit_door: bool = false
@export var target_scene: PackedScene
@export_file("*.tscn") var target_scene_path: String = ""
@export var is_unlocked: bool = false

@onready var label: Label = get_node_or_null("Label")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	add_to_group("Doors")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	update_door_visuals()

func update_door_visuals() -> void:
	if label:
		if is_boss_door:
			label.text = "BOSS DOOR " + ("[UNLOCKED]" if is_unlocked else "[LOCKED: Clear 3 Arena Rooms]")
		elif is_exit_door:
			label.text = "MAZE EXIT DOOR " + ("[OPEN]" if is_unlocked else "[LOCKED: Defeat Wave]")
		else:
			label.text = "ARENA DOOR " + str(door_id) + (" [OPEN]" if is_unlocked else " [ENTER]")

func unlock() -> void:
	is_unlocked = true
	update_door_visuals()

func _on_body_entered(body: Node) -> void:
	if not (body.is_in_group("Player") or body.name == "Perry" or body.has_method("execute_parry")):
		return

	var director = get_tree().get_first_node_in_group("RunDirector")
	if is_boss_door:
		var can_enter: bool = (UpgradeManager.cleared_arena_rooms_count >= 2) if UpgradeManager != null else is_unlocked
		if can_enter:
			unlock()
			change_to_target_scene()
		else:
			print("Boss door is locked! Defeat the 2 trial chambers before entering.")
			var hud = get_tree().get_first_node_in_group("HUD")
			if hud and hud.has_method("show_banner_message"):
				hud.show_banner_message("Defeat the 2 trial chambers before entering", Color.RED, 3.0)
			update_door_visuals()
	elif is_exit_door:
		var enemies_remain: bool = get_tree().get_nodes_in_group("Enemies").size() > 0
		if enemies_remain and not is_unlocked:
			print("Exit door is locked until all arena enemies are defeated!")
			return
		unlock()
		change_to_target_scene()
	else:
		change_to_target_scene()

func change_to_target_scene() -> void:
	door_entered.emit(self)
	UpgradeManager.save_current_scene_state(get_tree().current_scene)

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var p = players[0]
		UpgradeManager.save_player_state(p)
		if not is_exit_door:
			UpgradeManager.return_spawn_position = p.global_position
			UpgradeManager.target_door_id = door_id
			UpgradeManager.is_returning_to_maze = false
		else:
			UpgradeManager.target_door_id = 0
			UpgradeManager.is_returning_to_maze = true

	if target_scene != null:
		get_tree().change_scene_to_packed(target_scene)
	elif target_scene_path != "":
		get_tree().change_scene_to_file(target_scene_path)
	else:
		print("Door interacted, but no target_scene or target_scene_path assigned!")
