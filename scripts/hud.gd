extends CanvasLayer

@export var player_node_path: NodePath = NodePath("../Perry") # Make sure this path points to your Player in the main scene!

@onready var player = get_node_or_null(player_node_path)
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/WeaponLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel

func _ready() -> void:
	if player:
		# Connect the signals from your Perry script
		player.health_changed.connect(_on_health_changed)
		player.inventory_changed.connect(_on_inventory_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		
		# Initialize the HUD with the starting values
		_on_health_changed(player.health, player.max_health)
		_on_inventory_changed()

func _on_health_changed(current: int, max_val: int) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current
		
		# Optional: Change color if health is low
		if current <= (max_val * 0.3):
			health_bar.modulate = Color.RED
		else:
			health_bar.modulate = Color.GREEN

func _on_inventory_changed() -> void:
	if not player: return
	var active_weapon = player.get_active_weapon()
	if weapon_label:
		if active_weapon and active_weapon.stats:
			# Use the weapon name and rarity color from our WeaponStats resource!
			weapon_label.text = "Weapon: " + active_weapon.stats.weapon_name
			weapon_label.modulate = active_weapon.stats.rarity_color
		else:
			weapon_label.text = "Weapon: Unarmed"
			weapon_label.modulate = Color.WHITE

func _on_ammo_changed(current: int, max_val: int) -> void:
	if ammo_label:
		ammo_label.text = "Ammo: " + str(current) + " / " + str(max_val)		
