extends Node

# List of every upgrade in the game
var player_upgrades: Array[UpgradeData] = []
var parry_upgrades: Array[UpgradeData] = []
var core_upgrades: Array[UpgradeData] = []

# Rarity weights
const RARITY_WEIGHTS = {
	UpgradeData.Rarity.COMMON: 58.9,
	UpgradeData.Rarity.UNCOMMON: 25,
	UpgradeData.Rarity.RARE: 10,
	UpgradeData.Rarity.EPIC: 5,
	UpgradeData.Rarity.LEGENDARY: 1,
	UpgradeData.Rarity.MYTHIC: 0.1
}

const RARITY_MULTIPLIERS = {
	UpgradeData.Rarity.COMMON: 1.0,
	UpgradeData.Rarity.UNCOMMON: 2.0,
	UpgradeData.Rarity.RARE: 4.0,
	UpgradeData.Rarity.EPIC: 8.0,
	UpgradeData.Rarity.LEGENDARY: 12.0,
	UpgradeData.Rarity.MYTHIC: 16.0
}

func load_upgrade_folder(path: String):

	var dir := DirAccess.open(path)

	if dir == null:
		return

	dir.list_dir_begin()

	var file = dir.get_next()

	while file != "":

		if !dir.current_is_dir() and file.ends_with(".tres"):

			var upgrade = load(path + file)

			if upgrade is UpgradeData:

				match upgrade.type:

					UpgradeData.UpgradeType.PLAYER:
						player_upgrades.append(upgrade)

					UpgradeData.UpgradeType.PARRY:
						parry_upgrades.append(upgrade)

					UpgradeData.UpgradeType.CORE:
						core_upgrades.append(upgrade)

		file = dir.get_next()

	dir.list_dir_end()

func _ready():

	load_upgrade_folder("res://PerryParry/resources/Upgrades/Player/")
	load_upgrade_folder("res://PerryParry/resources/Upgrades/Parry/")
	load_upgrade_folder("res://PerryParry/resources/Upgrades/Core/")

	print("Loaded ", player_upgrades.size(), " player upgrades.")
	print("Loaded ", parry_upgrades.size(), " parry upgrades.")

func get_dictionary(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> Dictionary:
	match type:
		UpgradeData.UpgradeType.PLAYER:
			return upgrades.player_levels

		UpgradeData.UpgradeType.PARRY:
			return upgrades.parry_levels

		UpgradeData.UpgradeType.CORE:
			return upgrades.core_levels

	push_error("Unknown UpgradeType: %s" % [type])
	return {}

func get_pool(type: UpgradeData.UpgradeType) -> Array[UpgradeData]:
	match type:
		UpgradeData.UpgradeType.PLAYER:
			return player_upgrades

		UpgradeData.UpgradeType.PARRY:
			return parry_upgrades

		UpgradeData.UpgradeType.CORE:
			return core_upgrades

	push_error("Unknown UpgradeType: %s" % [type])
	return []

func get_used_slots(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> int:
	var dictionary := get_dictionary(type, upgrades)

	var count := 0

	for level in dictionary.values():
		if level > 0:
			count += 1

	return count

func get_owned_upgrades(
	type: UpgradeData.UpgradeType,
	upgrades: PlayerUpgrades
	) -> Array[UpgradeData]:

	var owned: Array[UpgradeData] = []

	var dictionary := get_dictionary(type, upgrades)
	var pool := get_pool(type)

	for upgrade in pool:
		if dictionary.has(upgrade.id):
			owned.append(upgrade)

	return owned

func get_available_upgrades(
	type: UpgradeData.UpgradeType,
	upgrades: PlayerUpgrades
	) -> Array[UpgradeData]:

	var available: Array[UpgradeData] = []

	var dictionary := get_dictionary(type, upgrades)
	var pool := get_pool(type)

	for upgrade in pool:
		if !dictionary.has(upgrade.id):
			available.append(upgrade)

	return available


func get_candidate_pool(
	type: UpgradeData.UpgradeType,
	upgrades: PlayerUpgrades
) -> Array[UpgradeData]:

	var owned = get_owned_upgrades(type, upgrades)

	if get_used_slots(type, upgrades) < 6:
		owned.append_array(
			get_available_upgrades(type, upgrades)
		)

	return owned

func remove_maxed(
	pool: Array[UpgradeData],
	upgrades: PlayerUpgrades
) -> Array[UpgradeData]:

	var filtered : Array[UpgradeData] = []

	for upgrade in pool:
		
		var level = upgrades.get_upgrade_level(
			upgrade.id,
			upgrade.type
		)

		if level < upgrade.max_level:
			filtered.append(upgrade)

	return filtered

func roll_rarity() -> UpgradeData.Rarity:

	var total_weight := 0.0

	for weight in RARITY_WEIGHTS.values():
		total_weight += weight

	var roll := randf_range(0.0, total_weight)

	var running := 0

	for rarity in RARITY_WEIGHTS.keys():

		running += RARITY_WEIGHTS[rarity]

		if roll <= running:
			return rarity

	return UpgradeData.Rarity.COMMON
	
func build_card(
	upgrade: UpgradeData,
	upgrades: PlayerUpgrades
) -> UpgradeCardData:

	var card := UpgradeCardData.new()

	card.upgrade = upgrade
	card.rarity = roll_rarity()

	card.current_level = upgrades.get_upgrade_level(
		upgrade.id,
		upgrade.type 
	)

	card.next_level = card.current_level + 1

	card.rarity_multiplier = RARITY_MULTIPLIERS[card.rarity]

	card.bonus_amount = (
		upgrade.increase_amount
		* card.rarity_multiplier
	)

	return card

func generate_player_cards(
	upgrades: PlayerUpgrades
) -> Array[UpgradeCardData]:

	var cards : Array[UpgradeCardData] = []

	var pool = get_candidate_pool(
		UpgradeData.UpgradeType.PLAYER,
		upgrades
	)

	# Add CORE upgrades (Parry Accuracy)
	pool.append_array(core_upgrades)

	pool = remove_maxed(pool, upgrades)

	pool.shuffle()

	while cards.size() < 3 and pool.size() > 0:

		var upgrade = pool.pop_front()

		cards.append(
			build_card(upgrade, upgrades)
		)

	return cards
