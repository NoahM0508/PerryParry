extends PanelContainer

@onready var slot1 = $MarginContainer/HBoxContainer/Slot1
@onready var slot2 = $MarginContainer/HBoxContainer/Slot2

var inventory : WeaponInventory

func set_inventory(inv : WeaponInventory):

	inventory = inv

	update_slots()

	inventory.inventory_changed.connect(update_slots)
	inventory.equipped_weapon_changed.connect(update_slots)

func update_slots():

	slot1.setup(
		inventory.slots[0],
		inventory.equipped_slot == 0
	)

	slot2.setup(
		inventory.slots[1],
		inventory.equipped_slot == 1
	)
