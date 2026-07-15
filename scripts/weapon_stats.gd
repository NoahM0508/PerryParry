extends Resource
class_name WeaponStats

# Define our Rarity dropdown options
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }
enum FirePattern { SINGLE_SHOT, SHOTGUN, LASER, BURST_SHOT }

@export_category("Visuals & Identity")
@export var weapon_name: String = "New Weapon"
@export var weapon_type: String = "Pistol"
@export var weapon_texture: Texture2D
@export var muzzle_position: Vector2 = Vector2(10, -2) # The X,Y coordinates of the barrel
@export var rarity: Rarity = Rarity.COMMON
@export var rarity_color: Color = Color(0.5, 0.5, 0.5) # Default Gray

@export_category("Basic Stats")
@export var fire_pattern: FirePattern = FirePattern.SINGLE_SHOT
@export var damage: float = 10.0
@export var fire_rate: float = 5.0
@export var magazine_size: int = 8
@export var reload_time: float = 1.2
@export var accuracy: float = 1.0 
@export var projectile_speed: float = 800.0
@export var max_range: float = 1000.0
@export var knockback: float = 50.0
@export var critical_chance: float = 0.05
@export var critical_damage: float = 2.0
@export var ammo_type: String = "Standard"

@export_category("Advanced Stats")
@export var projectile_lifetime: float = 3.0
@export var bullet_size: float = 1.0
@export var piercing: int = 0
@export var ricochet_count: int = 0
@export var explosion_radius: float = 0.0
@export var number_of_projectiles: int = 1
@export var spread_angle: float = 0.0
@export var burst_count: int = 1
@export var burst_delay: float = 0.1
@export var charge_time: float = 0.0
@export var heat_generation: float = 0.0
@export var recoil: float = 0.0
