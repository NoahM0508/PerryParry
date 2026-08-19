extends PanelContainer

@onready var bar: TextureProgressBar = $MarginContainer/HBoxContainer/VBoxContainer/HealthBar
@onready var label: Label = $MarginContainer/HBoxContainer/VBoxContainer/Label

func set_health(current:int, maximum:int):

	bar.max_value = maximum
	bar.value = current

	label.text = "%d / %d" % [current, maximum]
