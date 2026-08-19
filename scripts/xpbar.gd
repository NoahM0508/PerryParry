extends PanelContainer

@onready var title = $MarginContainer/HBoxContainer/VBoxContainer/TopRow/Title
@onready var level = $MarginContainer/HBoxContainer/VBoxContainer/TopRow/Level
@onready var progress = $MarginContainer/HBoxContainer/VBoxContainer/Progress

func setup(
	bar_title:String,
	bar_level:int,
	current_xp:int,
	required_xp:int,
):
	title.text = bar_title
	level.text = "Lv.%d" % bar_level

	progress.max_value = required_xp
	progress.value = current_xp
