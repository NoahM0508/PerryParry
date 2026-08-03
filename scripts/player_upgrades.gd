extends Resource
class_name PlayerUpgrades

# ==========================
# Upgrade Progress (The Dictionaries)
# ==========================
@export_category("Upgrade Dictionaries")
## Stores player upgrades 
@export var player_levels: Dictionary = {}

## Stores parry-specific upgrades 
@export var parry_levels: Dictionary = {}

@export var core_levels: Dictionary = {}

# ==========================
# Upgrade Limits
# ==========================
@export_category("Upgrade Limits")
@export var active_player_upgrades: Array[String] = []
@export var active_parry_upgrades: Array[String] = []
@export var max_upgrade_slots: int = 6

# ==========================
# Base Stats
# ==========================
@export_category("Base Player Stats")
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 1.0
@export var base_move_speed: float = 180.0
@export var base_max_health: int = 100

# ==========================
# Helper Functions (The Engine Room)
# ==========================

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
