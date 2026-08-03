extends Area2D

# The data file containing all our modular stats and visuals
@export var stats: WeaponStats

@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var rarity_label: Label = $RarityLabel
@onready var glow_particles: GPUParticles2D = $GlowParticles

var is_player_near: bool = false
var player_ref: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Double-check that we actually received a weapon data file before trying to read it
	if stats != null:
		setup_visuals()
	else:
		printerr("Floor Weapon Error: Spawned without WeaponStats!")

func _process(_delta: float) -> void:
	if not is_player_near or player_ref == null:
		return

	var pickup_pressed := Input.is_action_just_pressed("E")
	if pickup_pressed and player_ref.has_method("pick_up_weapon"):
		var success = player_ref.pick_up_weapon(stats)
		if success:
			queue_free()

func setup_visuals() -> void:
	# 1. Update the actual pixel art of the gun
	if stats.weapon_texture:
		weapon_sprite.texture = stats.weapon_texture
		
	rarity_label.text = stats.weapon_name
	rarity_label.add_theme_color_override("font_color", stats.rarity_color)
	
	glow_particles.modulate = stats.rarity_color

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		is_player_near = true
		player_ref = body

func _on_body_exited(body: Node) -> void:
	if body == player_ref:
		is_player_near = false
		player_ref = null
