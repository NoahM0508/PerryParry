extends CanvasLayer

signal upgrade_selected(card_data: UpgradeCardData)


# Make sure this path matches your UI tree!
@onready var card_container = $ColorRect/CenterContainer/VBoxContainer/CardContainer
const card_scene := preload("res://PerryParry/scenes/upgrade_card.tscn")

var current_cards : Array[UpgradeCardData]

func open_upgrade_screen(upgrades: PlayerUpgrades) -> void:
	get_tree().paused = true
	self.show()
	
	# 1. Clear out any old cards left over from the previous level up
	for child in card_container.get_children():
		child.queue_free()
		
	# 2. Ask our powerful UpgradeManager to generate the loot!
	var generated_cards: Array[UpgradeCardData] = UpgradeManager.generate_player_cards(upgrades)
	
	# 3. Instantiate and setup the visual cards
	for card_data in generated_cards:
		var card_instance = card_scene.instantiate()
		card_container.add_child(card_instance)
		
		# Hand the pre-calculated data over to the visual card
		card_instance.setup(card_data)
		
		# Listen for when the player clicks this specific card, and pass the upgrades resource along
		card_instance.selected.connect(_on_card_selected.bind(upgrades))

func _on_card_selected(card_data: UpgradeCardData, upgrades: PlayerUpgrades) -> void:
	print("Player chose: ", card_data.upgrade.title)
	
	# 1. Find the correct dictionary (Player, Parry, or Core) using our Manager helper
	var dict: Dictionary = UpgradeManager.get_dictionary(card_data.upgrade.type, upgrades)
	
	# 2. Add +1 to the specific upgrade's level
	var current_level: int = dict.get(card_data.upgrade.id, 0)
	dict[card_data.upgrade.id] = current_level + 1
	
	emit_signal("upgrade_selected", card_data)
	
	self.hide()
	get_tree().paused = false

func show_cards(cards : Array[UpgradeCardData]):

	current_cards = cards

	show()
	$AnimationPlayer.play("Open")
	
	get_tree().paused = true

	for child in card_container.get_children():
		child.queue_free()

	for card in cards:

		var ui = card_scene.instantiate()

		ui.setup(card)

		ui.selected.connect(_on_card_selected)

		card_container.add_child(ui)
