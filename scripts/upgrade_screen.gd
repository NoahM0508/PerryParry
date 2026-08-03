extends CanvasLayer

signal upgrade_selected(card_data: UpgradeCardData)

const CARD_SCENE := preload("res://PerryParry/scenes/upgrade_card.tscn")

@onready var card_container = $ColorRect/CenterContainer/VBoxContainer/CardContainer
@onready var animation_player = $AnimationPlayer

var player_upgrades: PlayerUpgrades

func open_upgrade_screen(upgrades: PlayerUpgrades) -> void:

	player_upgrades = upgrades

	show()

	if animation_player:
		animation_player.play("Open")

	get_tree().paused = true

	for child in card_container.get_children():
		child.queue_free()

	var cards = UpgradeManager.generate_player_cards(player_upgrades)

	for card_data in cards:

		var card = CARD_SCENE.instantiate()

		card_container.add_child(card)

		card.setup(card_data)

		card.selected.connect(_on_card_selected)

func _on_card_selected(card_data: UpgradeCardData) -> void:

	var dict = UpgradeManager.get_dictionary(
		card_data.upgrade.type,
		player_upgrades
	)

	dict[card_data.upgrade.id] = dict.get(
		card_data.upgrade.id,
		0
	) + 1

	if animation_player:
		animation_player.play("Close")

	await get_tree().process_frame

	hide()

	get_tree().paused = false

	upgrade_selected.emit(card_data)
	
func _input(event):

	if !visible:
		return

	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
