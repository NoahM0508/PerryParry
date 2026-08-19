extends PanelContainer

@onready var weapon_sprite = $MarginContainer/VBoxContainer/WeaponFrame/WeaponSprite
@onready var weapon_name = $MarginContainer/VBoxContainer/WeaponLabel
@onready var ammo_label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var equipped_border = $MarginContainer/VBoxContainer/WeaponFrame/EquippedGlow

func set_empty():
	if weapon_sprite:
		weapon_sprite.texture = null
		weapon_sprite.visible = false
	if weapon_name:
		weapon_name.text = "Empty"
	if ammo_label:
		ammo_label.text = "--"
	if equipped_border:
		equipped_border.visible = false
	remove_theme_stylebox_override("panel")

func setup(stats: WeaponStats, equipped: bool):
	if stats == null:
		set_empty()
		return

	if weapon_sprite:
		weapon_sprite.texture = stats.weapon_texture
		weapon_sprite.visible = true

	if weapon_name:
		weapon_name.text = stats.weapon_name

	if equipped_border:
		equipped_border.visible = equipped

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = stats.rarity_color
	style.bg_color.a = 0.4
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", style)
