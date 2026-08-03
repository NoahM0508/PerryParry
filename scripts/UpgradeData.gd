extends Resource
class_name UpgradeData

enum UpgradeType {
	PLAYER,
	PARRY,
	CORE
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC
}

@export var id: String
@export var title: String
@export_multiline var description: String


@export var type: UpgradeType = UpgradeType.PLAYER

@export var icon: Texture2D

@export var max_level: int = 20

# This is the stat this upgrade modifies
@export var stat_name: String

# How much is added every level
@export var increase_amount: float = 1.0
