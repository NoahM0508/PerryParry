extends CanvasLayer

@export var player_node_path: NodePath = NodePath("%Player") 

@onready var player = get_node_or_null(player_node_path)
@onready var health_label: Label = $"MarginContainer/VBoxContainer/Health Panel/MarginContainer/VBoxContainer/HealthBar/HealthLabel"
@onready var health_bar: TextureProgressBar = $"MarginContainer/VBoxContainer/Health Panel/MarginContainer/VBoxContainer/HealthBar"

@onready var weapon_panel = $MarginContainer/VBoxContainer/WeaponPanel
@onready var weapon_texture = $MarginContainer/VBoxContainer/WeaponPanel/MarginContainer/HBoxContainer/WeaponSprite
@onready var weapon_name: Label = $MarginContainer/VBoxContainer/WeaponPanel/MarginContainer/HBoxContainer/VBoxContainer/WeaponName

@onready var ammo_label: Label = $"MarginContainer/VBoxContainer/Ammo Panel/MarginContainer/HBoxContainer/AmmoLabel"
@onready var ammo_icon: TextureRect = $"MarginContainer/VBoxContainer/Ammo Panel/MarginContainer/HBoxContainer/AmmoIcon"


func _ready() -> void:
	if player:
		# Connect the signals from your Perry script
		player.health_changed.connect(_on_health_changed)
		player.inventory_changed.connect(_on_inventory_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		
		# Initialize the HUD with the starting values
		_on_health_changed(player.health, player.max_health)
		_on_inventory_changed()

func _on_health_changed(current:int,max_health:int):

	health_bar.max_value = max_health
	health_bar.value = current

	health_label.text = "%d / %d" % [current,max_health]

	if current < max_health * .3:
		health_bar.tint_progress = Color.RED
	else:
		health_bar.tint_progress = Color.GREEN

func _on_inventory_changed():
	var weapon = player.get_active_weapon()

	# 1. Grab the current stylebox and duplicate it so we don't overwrite everything else
	var panel_style = weapon_panel.get_theme_stylebox("panel").duplicate()

	# 2. Handle the Unarmed State
	if weapon == null:
		weapon_name.text = "Unarmed"
		weapon_texture.texture = null
		ammo_icon.texture = null
		
		# Set to Black with 0 Alpha (Completely transparent)
		panel_style.bg_color = Color(0, 0, 0, 0)
		weapon_panel.add_theme_stylebox_override("panel", panel_style)
		return

	# 3. Extract the Stats
	var stats = null
	if weapon is Node2D and "stats" in weapon:
		stats = weapon.stats
	elif weapon is WeaponStats:
		stats = weapon
	elif weapon is Resource and "weapon_name" in weapon:
		stats = weapon

	# 4. Fallback if stats fail to load
	if stats == null:
		weapon_name.text = "Unarmed"
		weapon_texture.texture = null
		ammo_icon.texture = null
		
		panel_style.bg_color = Color(0, 0, 0, 0)
		weapon_panel.add_theme_stylebox_override("panel", panel_style)
		return

	# 5. Handle the Equipped State
	weapon_name.text = stats.weapon_name
	weapon_texture.texture = stats.weapon_texture
	ammo_icon.texture = stats.ammo_icon
	
	# Set to Rarity Color with an alpha of 120 (which is ~0.47 in Godot's 0-1 scale)
	panel_style.bg_color = Color(stats.rarity_color, 0.6)
	weapon_panel.add_theme_stylebox_override("panel", panel_style)

func _on_ammo_changed(current,max_ammo):
	ammo_label.text = "%d / %d" % [current,max_ammo]		
