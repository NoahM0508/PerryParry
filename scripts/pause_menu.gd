extends CanvasLayer

func _ready() -> void:
	# Hide the menu by default
	visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	# Flip the paused state
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	# Show or hide the menu based on the state
	visible = is_paused

# Connected to ResumeButton
func _on_resume_button_pressed() -> void:
	toggle_pause()

# Connected to QuitToMenuButton
func _on_quit_to_menu_button_pressed() -> void:
	# Unpause the game before leaving, otherwise the main menu will be frozen!
	get_tree().paused = false
	get_tree().change_scene_to_file("res://PerryParry/scenes/main_menu.tscn")
