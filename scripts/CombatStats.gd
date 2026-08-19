extends Node
class_name CombatStats

# === NEW DEFENSIVE STATS ===
@export var armor_rating: int = 0
@export var evasion_chance: float = 0.0
@export var life_steal: float = 0.0
@export var passive_regen: float = 0.0

# === NEW PARRY STATS ===
@export var has_crit_overload: bool = false
@export var duplication_count: int = 0
@export var has_explosive: bool = false
@export var heal_on_deflect: float = 0.0
@export var has_shockwave: bool = false
@export var window_extension: float = 0.0

# === CORE STATS ===
@export var parry_accuracy_level: int = 0

# --- BASE STATS ---
var base_max_health: int = 100
var base_move_speed: float = 180.0
var base_damage: float = 10.0
var base_attack_speed: float = 1.0

# --- FLAT BONUSES ---
var bonus_max_health: int = 0
var bonus_move_speed: float = 0.0
var bonus_damage: float = 0.0
var bonus_attack_speed: float = 0.0

var magazine_size_bonus: int = 0
var projectile_speed_bonus: float = 0.0 
var reload_speed_bonus: float = 0.0 
var piercing_bonus: int = 0 # NEW: Prevents piercing crash!

# --- MULTIPLIERS (Added by upgrades, 1.0 = 100%) ---
var max_health_multiplier: float = 1.0
var move_speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0

var magazine_size_multiplier: float = 1.0
var projectile_speed_multiplier: float = 1.0 
var reload_speed_multiplier: float = 1.0 
var piercing_multiplier: float = 1.0

# Wipes the slate clean every time you pick a new card!
func reset():
	armor_rating = 0
	evasion_chance = 0.0
	life_steal = 0.0
	passive_regen = 0.0
	has_crit_overload = false
	duplication_count = 0
	has_explosive = false
	heal_on_deflect = 0.0
	has_shockwave = false
	window_extension = 0.0
	parry_accuracy_level = 0

	bonus_max_health = 0
	bonus_move_speed = 0.0
	bonus_damage = 0.0
	bonus_attack_speed = 0.0
	magazine_size_bonus = 0
	projectile_speed_bonus = 0.0 
	reload_speed_bonus = 0.0 
	piercing_bonus = 0
	
	max_health_multiplier = 1.0
	move_speed_multiplier = 1.0
	damage_multiplier = 1.0
	fire_rate_multiplier = 1.0
	magazine_size_multiplier = 1.0
	projectile_speed_multiplier = 1.0 
	reload_speed_multiplier = 1.0 
	piercing_multiplier = 1.0

func get_max_health() -> int:
	return int((base_max_health + bonus_max_health) * max_health_multiplier)

func get_move_speed() -> float:
	return (base_move_speed + bonus_move_speed) * move_speed_multiplier
	
func get_damage() -> float:
	return (base_damage + bonus_damage) * damage_multiplier
	
func get_attack_speed() -> float:
	return (base_attack_speed + bonus_attack_speed) * fire_rate_multiplier

func get_effective_evasion_chance() -> float:
	if evasion_chance <= 0.0:
		return 0.0
	# Asymptotic diminishing returns curve: x / (x + 50.0)
	return evasion_chance / (evasion_chance + 50.0)
