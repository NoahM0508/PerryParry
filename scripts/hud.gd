extends CanvasLayer

@export var player_node_path: NodePath = NodePath("../Player")

@onready var player = get_node_or_null(player_node_path)
@onready var health_label = $HealthLabel
@onready var weapon1_label = $Weapon1Label
@onready var weapon2_label = $Weapon2Label
@onready var ammo_label = $AmmoLabel

func _ready() -> void:
	if player:
		player.connect("health_changed", Callable(self, "_on_health_changed"))
		player.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
		player.connect("ammo_changed", Callable(self, "_on_ammo_changed"))
		# initialize
		_on_health_changed(player.health, player.max_health)
		_on_inventory_changed()

func _on_health_changed(current: int, max: int) -> void:
	if health_label:
		health_label.text = str(current) + " / " + str(max)

func _on_inventory_changed() -> void:
	if not player:
		return
	var inv = player.inventory
	if weapon1_label:
		weapon1_label.text = inv[0] != null and inv[0].name or "Empty"
	if weapon2_label:
		weapon2_label.text = inv[1] != null and inv[1].name or "Empty"

func _on_ammo_changed(current: int, max: int) -> void:
	if ammo_label:
		ammo_label.text = str(current) + " / " + str(max)
