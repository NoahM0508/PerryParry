extends CanvasLayer

func _ready() -> void:
	# Hide the menu by default
	visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# Assuming your upgrade screen is added to a CanvasLayer group or you have a reference to it
		var upgrade_screen = get_tree().get_first_node_in_group("UpgradeScreen")
		
		# If the upgrade screen exists and is currently visible, IGNORE the pause button!
		if upgrade_screen and upgrade_screen.visible:
			return 
			
		# Otherwise, run your normal pause menu logic here...
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
