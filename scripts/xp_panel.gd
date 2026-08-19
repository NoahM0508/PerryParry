extends PanelContainer

@onready var player_bar = $MarginContainer/VBoxContainer/PlayerXPBar
@onready var parry_bar = $MarginContainer/VBoxContainer/ParryXPBar

var player

func set_player(p):
	player = p

	update_player_xp()
	update_parry_xp()

	if not player.xp_changed.is_connected(update_player_xp):
		player.xp_changed.connect(update_player_xp.unbind(3))
		
	if player.has_signal("parry_xp_changed") and not player.parry_xp_changed.is_connected(update_parry_xp):
		player.parry_xp_changed.connect(update_parry_xp.unbind(3)) 

func update_player_xp():
	player_bar.setup(
		"Player XP",
		player.player_level, 
		player.current_xp,
		player.xp_to_next_level,
	)

func update_parry_xp():
	parry_bar.setup(
		"Parry XP",
		player.parry_level, 
		player.current_parry_xp,
		player.parry_xp_to_next,
	)
