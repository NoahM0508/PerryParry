extends PanelContainer

@onready var ammo_icon = $MarginContainer/HBoxContainer/AmmoIcon
@onready var ammo_label = $MarginContainer/HBoxContainer/VBoxContainer/AmmoLabel
@onready var weapon_label = $MarginContainer/HBoxContainer/VBoxContainer/WeaponLabel
@onready var reload_indicator = $MarginContainer/HBoxContainer/ReloadingIndicator

var current_weapon = null

func set_weapon(weapon):
	
	if current_weapon and current_weapon.ammo_changed.is_connected(update_ammo):
		current_weapon.ammo_changed.disconnect(update_ammo)
		
	current_weapon = weapon

	if weapon == null:
		ammo_icon.texture = null
		weapon_label.text = "Unarmed"
		ammo_label.text = "--"
		return

	weapon_label.text = weapon.stats.weapon_name
	ammo_icon.texture = weapon.stats.ammo_icon
	update_ammo(weapon.current_ammo, weapon.stats.magazine_size)
	
	weapon.ammo_changed.connect(update_ammo)

func update_ammo(current:int, max_ammo:int):
	ammo_label.text = "%d / %d" % [current, max_ammo]
