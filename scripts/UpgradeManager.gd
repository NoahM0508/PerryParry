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
	if dir == null: return
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
	print("Loaded ", core_upgrades.size(), " core upgrades.")

func get_dictionary(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> Dictionary:
	match type:
		UpgradeData.UpgradeType.PLAYER: return upgrades.player_levels
		UpgradeData.UpgradeType.PARRY: return upgrades.parry_levels
		UpgradeData.UpgradeType.CORE: return upgrades.core_levels
	push_error("Unknown UpgradeType: %s" % [type])
	return {}

# Holds the actual applied stat amount for each upgrade (rarity already baked in).
# Kept separate from get_dictionary()'s level counts so rarity can scale power
# per-pick without also inflating how many "levels" a card counts as.
func get_bonus_dictionary(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> Dictionary:
	match type:
		UpgradeData.UpgradeType.PLAYER: return upgrades.player_bonus_values
		UpgradeData.UpgradeType.PARRY: return upgrades.parry_bonus_values
		UpgradeData.UpgradeType.CORE: return upgrades.core_bonus_values
	push_error("Unknown UpgradeType: %s" % [type])
	return {}

func get_pool(type: UpgradeData.UpgradeType) -> Array[UpgradeData]:
	match type:
		UpgradeData.UpgradeType.PLAYER: return player_upgrades
		UpgradeData.UpgradeType.PARRY: return parry_upgrades
		UpgradeData.UpgradeType.CORE: return core_upgrades
	push_error("Unknown UpgradeType: %s" % [type])
	return []

func get_used_slots(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> int:
	var dictionary := get_dictionary(type, upgrades)
	var count := 0
	for level in dictionary.values():
		if level > 0: count += 1
	return count

func get_owned_upgrades(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> Array[UpgradeData]:
	var owned: Array[UpgradeData] = []
	var dictionary := get_dictionary(type, upgrades)
	var pool := get_pool(type)
	for upgrade in pool:
		if dictionary.has(upgrade.id):
			owned.append(upgrade)
	return owned

func get_available_upgrades(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> Array[UpgradeData]:
	var available: Array[UpgradeData] = []
	var dictionary := get_dictionary(type, upgrades)
	var pool := get_pool(type)
	for upgrade in pool:
		if !dictionary.has(upgrade.id):
			available.append(upgrade)
	return available

func get_candidate_pool(type: UpgradeData.UpgradeType, upgrades: PlayerUpgrades) -> Array[UpgradeData]:
	var owned = get_owned_upgrades(type, upgrades)
	if get_used_slots(type, upgrades) < 6:
		owned.append_array(get_available_upgrades(type, upgrades))
	return owned

func remove_maxed(pool: Array[UpgradeData], upgrades: PlayerUpgrades) -> Array[UpgradeData]:
	var filtered : Array[UpgradeData] = []
	for upgrade in pool:
		var level = upgrades.get_upgrade_level(upgrade.id, upgrade.type)
		if upgrade.stat_name == "parry_accuracy" or level < upgrade.max_level:
			filtered.append(upgrade)
	return filtered

func roll_rarity() -> UpgradeData.Rarity:
	var total_weight := 0.0
	for weight in RARITY_WEIGHTS.values(): total_weight += weight
	var roll := randf_range(0.0, total_weight)
	var running := 0.0

	for rarity in RARITY_WEIGHTS.keys():
		running += RARITY_WEIGHTS[rarity]
		if roll <= running: return rarity
	return UpgradeData.Rarity.COMMON

func build_card(upgrade: UpgradeData, upgrades: PlayerUpgrades) -> UpgradeCardData:
	var card := UpgradeCardData.new()
	card.upgrade = upgrade
	card.rarity = roll_rarity()
	card.current_level = upgrades.get_upgrade_level(upgrade.id, upgrade.type)
	card.next_level = card.current_level + 1
	card.rarity_multiplier = RARITY_MULTIPLIERS[card.rarity]
	card.bonus_amount = upgrade.increase_amount * card.rarity_multiplier
	return card

func generate_player_cards(upgrades: PlayerUpgrades) -> Array[UpgradeCardData]:
	var cards : Array[UpgradeCardData] = []
	var pool: Array[UpgradeData] = []

	pool.append_array(get_candidate_pool(UpgradeData.UpgradeType.PLAYER, upgrades))

	pool.append_array(get_candidate_pool(UpgradeData.UpgradeType.CORE, upgrades))

	pool = remove_maxed(pool, upgrades)
	pool.shuffle()

	while cards.size() < 3 and pool.size() > 0:
		var upgrade = pool.pop_front()
		cards.append(build_card(upgrade, upgrades))
	return cards

func generate_parry_cards(upgrades: PlayerUpgrades) -> Array[UpgradeCardData]:
	var cards : Array[UpgradeCardData] = []
	var pool: Array[UpgradeData] = []

	pool.append_array(get_candidate_pool(UpgradeData.UpgradeType.PARRY, upgrades))

	pool.append_array(get_candidate_pool(UpgradeData.UpgradeType.CORE, upgrades))

	pool = remove_maxed(pool, upgrades)
	pool.shuffle()

	while cards.size() < 3 and pool.size() > 0:
		var upgrade = pool.pop_front()
		cards.append(build_card(upgrade, upgrades))
	return cards

func get_upgrade_by_id(id:String) -> UpgradeData:
	for pool in [player_upgrades, parry_upgrades, core_upgrades]:
		for upgrade in pool:
			if upgrade.id == id: return upgrade
	return null

func apply_all_upgrades(upgrades: PlayerUpgrades, stats: CombatStats):
	# Walk PLAYER, PARRY, and CORE upgrades (previously only PLAYER was applied,
	# which is why parry/core upgrades like parry_accuracy never had any effect).
	for type in [UpgradeData.UpgradeType.PLAYER, UpgradeData.UpgradeType.PARRY, UpgradeData.UpgradeType.CORE]:
		var bonus_dict = get_bonus_dictionary(type, upgrades)

		for id in bonus_dict.keys():
			var amount = bonus_dict[id]
			var upgrade = get_upgrade_by_id(id)

			if upgrade == null:
				continue

			apply_single_upgrade(upgrade, amount, stats)

func apply_single_upgrade(upgrade: UpgradeData, amount: float, stats: CombatStats) -> void:
	match upgrade.stat_name:
		# === PLAYER UPGRADES ===
		"damage":
			stats.bonus_damage += amount
		"armor":
			stats.armor_rating += int(amount)
		"evasion":
			stats.evasion_chance += amount / 100.0
		"fire_rate":
			stats.fire_rate_multiplier += amount
		"life_steal":
			stats.life_steal += amount
		"max_hp":
			stats.bonus_max_health += int(amount)
		"movement_speed":
			stats.bonus_move_speed += amount
		"passive_regen":
			stats.passive_regen += amount

		# === PARRY UPGRADES ===
		"crit_overload":
			stats.has_crit_overload = true
		"duplication_count":
			stats.duplication_count += int(amount)
		"explosive":
			stats.has_explosive = true
		"heal_deflect":
			stats.heal_on_deflect += amount
		"shockwave":
			stats.has_shockwave = true
		"window_extension":
			stats.window_extension += amount

		# === CORE UPGRADES ===
		"parry_accuracy":
			stats.parry_accuracy_level += int(amount)

# =====================================================
# PERSISTENT PLAYER & RUN STATE ACROSS SCENE TRANSITIONS
# =====================================================

var saved_player_data: Dictionary = {}
var has_saved_data: bool = false
var return_spawn_position: Vector2 = Vector2.ZERO
var return_door_id: int = 0
var target_door_id: int = 0
var is_returning_to_maze: bool = false
var cleared_arena_rooms_count: int = 0
var best_survival_time: float = 0.0
var current_survival_time: float = 0.0
var total_kills: int = 0
var ai_level: int = 1

func reset_run_state(player: Node = null) -> void:
	has_saved_data = false
	saved_player_data.clear()
	scene_dropped_weapons.clear()
	return_spawn_position = Vector2.ZERO
	return_door_id = 0
	target_door_id = 0
	is_returning_to_maze = false
	cleared_arena_rooms_count = 0
	current_survival_time = 0.0
	total_kills = 0
	ai_level = 1

	if player != null and player.get("upgrades") != null:
		var upg = player.get("upgrades")
		if upg.has_method("reset_upgrades"):
			upg.reset_upgrades()
		if player.has_method("rebuild_stats"):
			player.rebuild_stats()

func record_kill() -> void:
	total_kills += 1
	var calc_level: int = clamp(1 + int(total_kills / 6.0), 1, 10)
	if calc_level != ai_level:
		ai_level = calc_level
		print("Global AI Level increased! Current AI Level: ", ai_level)

func get_current_ai_level() -> int:
	return ai_level

func record_arena_room_cleared() -> void:
	cleared_arena_rooms_count += 1
	print("Cleared Arena Room! Total cleared: ", cleared_arena_rooms_count)

func update_survival_time(elapsed: float) -> void:
	current_survival_time = elapsed
	if current_survival_time > best_survival_time:
		best_survival_time = current_survival_time

func save_player_state(player: Node) -> void:
	if player == null:
		return
	has_saved_data = true
	saved_player_data = {
		"health": player.get("health"),
		"max_health": player.get("max_health"),
		"player_level": player.get("player_level"),
		"current_xp": player.get("current_xp"),
		"xp_to_next_level": player.get("xp_to_next_level"),
		"parry_level": player.get("parry_level"),
		"current_parry_xp": player.get("current_parry_xp"),
		"parry_xp_to_next": player.get("parry_xp_to_next"),
		"upgrades": player.get("upgrades")
	}

	if player.get("weapon_inventory") != null:
		var inv = player.weapon_inventory
		var weapon_slots: Array = []
		for slot in inv.slots:
			weapon_slots.append(slot)
		saved_player_data["inventory_slots"] = weapon_slots
		saved_player_data["equipped_slot"] = inv.equipped_slot

func restore_player_state(player: Node) -> void:
	if not has_saved_data or player == null:
		return

	if saved_player_data.has("upgrades") and saved_player_data["upgrades"] != null:
		player.upgrades = saved_player_data["upgrades"]

	player.set("player_level", saved_player_data.get("player_level", 1))
	player.set("current_xp", saved_player_data.get("current_xp", 0))
	player.set("xp_to_next_level", saved_player_data.get("xp_to_next_level", 100))
	player.set("parry_level", saved_player_data.get("parry_level", 1))
	player.set("current_parry_xp", saved_player_data.get("current_parry_xp", 0))
	player.set("parry_xp_to_next", saved_player_data.get("parry_xp_to_next", 4))

	if player.has_method("rebuild_stats"):
		player.rebuild_stats()

	var saved_hp = saved_player_data.get("health", player.get("max_health"))
	player.set("health", saved_hp)

	if saved_player_data.has("inventory_slots") and player.get("weapon_inventory") != null:
		var inv = player.weapon_inventory
		var slots_data: Array = saved_player_data["inventory_slots"]
		for i in range(min(slots_data.size(), inv.MAX_SLOTS)):
			inv.slots[i] = slots_data[i]
		var equipped_idx: int = saved_player_data.get("equipped_slot", 0)
		inv.equipped_slot = equipped_idx
		if inv.has_signal("equipped_weapon_changed"):
			inv.equipped_weapon_changed.emit()

	if player.has_signal("health_changed"):
		player.emit_signal("health_changed", player.get("health"), player.get("max_health"))

# =====================================================
# SCENE WORLD STATE PERSISTENCE (FLOOR WEAPONS & OBJECTS)
# =====================================================

var scene_dropped_weapons: Dictionary = {}

func save_current_scene_state(scene_root: Node) -> void:
	if scene_root == null:
		return
	var scene_file: String = scene_root.scene_file_path
	if scene_file.is_empty():
		return

	var dropped_data: Array = []
	for node in scene_root.get_tree().get_nodes_in_group("FloorWeapons"):
		if node is Node2D and is_instance_valid(node) and node.get("stats") != null:
			dropped_data.append({
				"stats": node.get("stats"),
				"position": node.global_position
			})
	scene_dropped_weapons[scene_file] = dropped_data

func restore_current_scene_state(scene_root: Node) -> void:
	if scene_root == null:
		return
	var scene_file: String = scene_root.scene_file_path
	if not scene_dropped_weapons.has(scene_file):
		return

	# Remove any default un-saved floor weapons in scene
	for existing in scene_root.get_tree().get_nodes_in_group("FloorWeapons"):
		if is_instance_valid(existing):
			existing.queue_free()

	var floor_weapon_scene = load("res://PerryParry/scenes/floor_weapon.tscn")
	if floor_weapon_scene == null:
		return

	var saved_list: Array = scene_dropped_weapons.get(scene_file, [])
	for item in saved_list:
		if item.has("stats") and item["stats"] != null:
			var drop = floor_weapon_scene.instantiate()
			drop.stats = item["stats"]
			drop.global_position = item["position"]
			scene_root.call_deferred("add_child", drop)
