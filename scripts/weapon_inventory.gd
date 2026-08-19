extends Node
class_name WeaponInventory

signal inventory_changed
signal equipped_weapon_changed

const MAX_SLOTS: int = 2

var slots: Array[Resource] = [null, null]
var equipped_slot: int = 0

func equip_weapon(stats: Resource, slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
		
	slots[slot] = stats
	inventory_changed.emit()
	
	if slot == equipped_slot:
		equipped_weapon_changed.emit()

func swap() -> void:
	equipped_slot = 1 - equipped_slot
	equipped_weapon_changed.emit()
