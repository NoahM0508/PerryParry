extends Control

@onready var options_menu = $OptionsMenu
@onready var music_slider: HSlider = get_node_or_null("OptionsMenu/VBoxContainer/MusicSlider") as HSlider

func _ready() -> void:
	options_menu.visible = false

	if music_slider:
		music_slider.value = MusicManager.get_music_volume_linear() if MusicManager != null else 1.0
		if not music_slider.value_changed.is_connected(_on_music_volume_changed):
			music_slider.value_changed.connect(_on_music_volume_changed)

	if UpgradeManager != null and UpgradeManager.best_survival_time > 0.0:
		var best_lbl = Label.new()
		var mins: int = int(UpgradeManager.best_survival_time / 60.0)
		var secs: float = fmod(UpgradeManager.best_survival_time, 60.0)
		best_lbl.text = "BEST SURVIVAL TIME: %02d:%04.1f" % [mins, secs]
		best_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
		best_lbl.add_theme_font_size_override("font_size", 20)
		best_lbl.position = Vector2(20, 20)
		add_child(best_lbl)

func _on_music_volume_changed(value: float) -> void:
	if MusicManager != null:
		MusicManager.set_music_volume_linear(value)

# Connected from StartButton
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://PerryParry/scenes/lvl_1.tscn")

# Connected from OptionsButton
func _on_options_button_pressed() -> void:
	options_menu.visible = true

# Connected from QuitButton
func _on_quit_button_pressed() -> void:
	get_tree().quit()

# Connected from BackButton inside OptionsMenu
func _on_back_button_pressed() -> void:
	options_menu.visible = false
