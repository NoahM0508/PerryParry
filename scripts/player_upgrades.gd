extends Resource
class_name PlayerUpgrades


@export_category("Upgrade Dictionaries")
## Stores player upgrades 
@export var player_levels: Dictionary = {}

## Stores parry-specific upgrades 
@export var parry_levels: Dictionary = {}

@export var core_levels: Dictionary = {}

@export_category("Upgrade Limits")
@export var active_player_upgrades: Array[String] = []
@export var active_parry_upgrades: Array[String] = []
@export var max_upgrade_slots: int = 6

@export var player_bonus_values: Dictionary = {}
@export var parry_bonus_values: Dictionary = {}
@export var core_bonus_values: Dictionary = {}


func get_upgrade_level(
	id: String,
	type: UpgradeData.UpgradeType
) -> int:

	match type:
		UpgradeData.UpgradeType.PLAYER:
			return player_levels.get(id, 0)

		UpgradeData.UpgradeType.PARRY:
			return parry_levels.get(id, 0)

		UpgradeData.UpgradeType.CORE:
			return core_levels.get(id, 0)

	push_error("Unknown UpgradeType")
	return 0

func reset_upgrades() -> void:
	player_levels.clear()
	parry_levels.clear()
	core_levels.clear()
	active_player_upgrades.clear()
	active_parry_upgrades.clear()
	player_bonus_values.clear()
	parry_bonus_values.clear()
	core_bonus_values.clear()
