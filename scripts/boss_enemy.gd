extends "res://PerryParry/scripts/base_enemy.gd"
class_name BossEnemy

@export_category("Boss Settings")
@export var boss_scale: Vector2 = Vector2(2.5, 2.5)
@export var boss_base_hp: int = 5000

@export_category("Boss Attacks")
@export var boulder_scene: PackedScene
@export var throw_interval: float = 2.0

var throw_timer: Timer

func _ready() -> void:
	max_health = boss_base_hp
	current_health = boss_base_hp
	scale = boss_scale
	
	super()
	add_to_group("Boss")

	# Fallback boulder scene if none assigned in Inspector
	if boulder_scene == null:
		boulder_scene = load("res://PerryParry/scenes/boulder.tscn")

	# Setup Boulder Throw Timer
	throw_timer = Timer.new()
	throw_timer.one_shot = false
	throw_timer.wait_time = throw_interval
	throw_timer.timeout.connect(throw_boulder)
	add_child(throw_timer)
	throw_timer.start()

func throw_boulder() -> void:
	if current_state == State.DEAD:
		return

	if boulder_scene == null:
		boulder_scene = load("res://PerryParry/scenes/boulder.tscn")
	if boulder_scene == null:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player_ref = players[0]
	if player_ref == null:
		return

	var scene_root = get_tree().current_scene
	if scene_root == null:
		return

	var boulder = boulder_scene.instantiate()
	boulder.global_position = global_position
	
	var dir = global_position.direction_to(player_ref.global_position)
	if "direction" in boulder:
		boulder.direction = dir
	if "shooter" in boulder:
		boulder.shooter = self

	scene_root.call_deferred("add_child", boulder)

func update_animation() -> void:
	# Plain Sprite2D boss has no AnimatedSprite2D animations!
	pass

func play_hurt_animation() -> void:
	# Plain Sprite2D boss has no Hurt animation
	pass

func die() -> void:
	if throw_timer: throw_timer.stop()

	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("on_boss_defeated"):
		hud.on_boss_defeated()

	super()
