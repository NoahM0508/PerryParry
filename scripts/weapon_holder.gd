extends Node2D
class_name WeaponHolder

signal weapon_changed(new_weapon: Node2D)

@export var weapon_socket: NodePath = NodePath(".")
@export var master_weapon_scene: PackedScene

@onready var inventory: WeaponInventory = $"../WeaponInventory"

var current_weapon: Node2D
var owner_character

func initialize(character) -> void:
	owner_character = character
	inventory.equipped_weapon_changed.connect(_on_equipped_weapon_changed)
	_on_equipped_weapon_changed() # Instantly spawn starting weapon

func _on_equipped_weapon_changed() -> void:
	var stats = inventory.slots[inventory.equipped_slot]
	update_weapon(stats)

func update_weapon(stats: Resource) -> void:
	for child in get_children():
		child.queue_free()
	current_weapon = null

	if stats == null:
		weapon_changed.emit(null)
		return
		
	if master_weapon_scene:
		current_weapon = master_weapon_scene.instantiate()
		current_weapon.stats = stats 
		add_child(current_weapon)
		
		current_weapon.position = Vector2.ZERO
		current_weapon.rotation = 0
		current_weapon.wielder = owner_character
		
		weapon_changed.emit(current_weapon)

func fire() -> void:
	if current_weapon and current_weapon.has_method("fire_weapon"):
		current_weapon.fire_weapon(current_weapon.aim_direction, owner_character)

func reload() -> void:
	if current_weapon and current_weapon.has_method("reload"):
		current_weapon.reload()

func get_weapon() -> Node2D:
	return current_weapon
