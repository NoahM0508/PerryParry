extends CanvasLayer

signal upgrade_selected(card_data: UpgradeCardData)

const CARD_SCENE := preload("res://PerryParry/scenes/upgrade_card.tscn")

@onready var card_container = $ColorRect/CenterContainer/VBoxContainer/CardContainer
@onready var animation_player = $AnimationPlayer


var player_upgrades: PlayerUpgrades

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func open_upgrade_screen(upgrades: PlayerUpgrades, pool_type: String = "player") -> void:

	player_upgrades = upgrades

	show()

	if animation_player:
		animation_player.play("Open")

	get_tree().paused = true

	for child in card_container.get_children():
		child.queue_free()

	var cards: Array[UpgradeCardData]
	if pool_type == "parry":
		cards = UpgradeManager.generate_parry_cards(player_upgrades)
	else:
		cards = UpgradeManager.generate_player_cards(player_upgrades)

	for card_data in cards:

		var card = CARD_SCENE.instantiate()

		card_container.add_child(card)

		card.setup(card_data)

		card.selected.connect(_on_card_selected)

func _on_card_selected(card_data: UpgradeCardData) -> void:

	var level_dict = UpgradeManager.get_dictionary(
		card_data.upgrade.type,
		player_upgrades
	)
	var bonus_dict = UpgradeManager.get_bonus_dictionary(
		card_data.upgrade.type,
		player_upgrades
	)

	level_dict[card_data.upgrade.id] = level_dict.get(
		card_data.upgrade.id,
		0
	) + 1

	bonus_dict[card_data.upgrade.id] = bonus_dict.get(
		card_data.upgrade.id,
		0.0
	) + card_data.bonus_amount

	if animation_player:
		animation_player.play("Close")

	if animation_player:
		await animation_player.animation_finished

	hide()

	get_tree().paused = false

	upgrade_selected.emit(card_data)
	
func _input(event):

	if !visible:
		return

	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
