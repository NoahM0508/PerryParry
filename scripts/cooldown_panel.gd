extends PanelContainer

@onready var dash = $HBoxContainer/Dash
@onready var parry = $HBoxContainer/Parry

func initialize(player):

	dash.set_icon(load("res://PerryParry/assets/Icons/Speed.png"))
	parry.set_icon(load("res://PerryParry/assets/Icons/ParryIcon.png"))

	player.dash_started.connect(_on_dash)
	player.parry_started.connect(_on_parry)

func _on_dash(time):

	dash.start_cooldown(time)

func _on_parry(time):

	parry.start_cooldown(time)
