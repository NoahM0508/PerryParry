extends CanvasLayer

@onready var music_slider: HSlider = get_node_or_null("ColorRect/VBoxContainer/MusicSlider") as HSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if music_slider:
		music_slider.value = MusicManager.get_music_volume_linear() if MusicManager != null else 1.0
		if not music_slider.value_changed.is_connected(_on_music_slider_changed):
			music_slider.value_changed.connect(_on_music_slider_changed)

func _on_music_slider_changed(val: float) -> void:
	if MusicManager != null:
		MusicManager.set_music_volume_linear(val)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var upgrade_screen = get_tree().get_first_node_in_group("UpgradeScreen")
		if upgrade_screen and upgrade_screen.visible:
			return

		get_viewport().set_input_as_handled()
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused

	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.visible = not is_paused

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_quit_to_menu_button_pressed() -> void:
	get_tree().paused = false
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.visible = true

	var players = get_tree().get_nodes_in_group("Player")
	var player_node: Node = players[0] if players.size() > 0 else null
	if UpgradeManager != null:
		UpgradeManager.reset_run_state(player_node)
	get_tree().change_scene_to_file("res://PerryParry/scenes/main_menu.tscn")
