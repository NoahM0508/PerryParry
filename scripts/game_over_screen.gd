extends CanvasLayer
class_name GameOverScreen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	var restart_btn = find_child("RestartButton", true, false)
	if restart_btn is Button:
		restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		restart_btn.pressed.connect(_on_restart_pressed)

	var menu_btn = find_child("MainMenuButton", true, false)
	if menu_btn is Button:
		menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		menu_btn.pressed.connect(_on_main_menu_pressed)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	var players = get_tree().get_nodes_in_group("Player")
	var player_node: Node = players[0] if players.size() > 0 else null
	if UpgradeManager != null:
		UpgradeManager.reset_run_state(player_node)
	get_tree().change_scene_to_file("res://PerryParry/scenes/lvl_1.tscn")
	queue_free()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	var players = get_tree().get_nodes_in_group("Player")
	var player_node: Node = players[0] if players.size() > 0 else null
	if UpgradeManager != null:
		UpgradeManager.reset_run_state(player_node)
	get_tree().change_scene_to_file("res://PerryParry/scenes/main_menu.tscn")
	queue_free()
