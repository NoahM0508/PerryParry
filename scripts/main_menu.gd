extends Control

@onready var options_menu = $OptionsMenu

func _ready() -> void:
	# Ensure options is hidden when we boot up
	options_menu.visible = false

# Connected from StartButton
func _on_start_button_pressed() -> void:
	# Replace the path with the actual path to your game's main level!
	get_tree().change_scene_to_file("res://PerryParry/scenes/lvl_1.tscn")

# Connected from OptionsButton
func _on_options_button_pressed() -> void:
	options_menu.visible = true

# Connected from QuitButton
func _on_quit_button_pressed() -> void:
	get_tree().quit()

# Connected from the BackButton INSIDE the OptionsMenu
func _on_back_button_pressed() -> void:
	options_menu.visible = false
