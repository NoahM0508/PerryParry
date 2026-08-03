extends Control

signal selected(card_data: UpgradeCardData)

var card_data: UpgradeCardData

@export var hover_scale := 1.08


# --- NODE REFERENCES ---
# Adjust these paths if Scene Tree differs slightly
@onready var title_label = $CardButton/CardPanel/MarginContainer/VBoxContainer/Title
@onready var desc_label = $CardButton/CardPanel/MarginContainer/VBoxContainer/Description
@onready var bonus_label = $CardButton/CardPanel/MarginContainer/VBoxContainer/BonusLabel
@onready var level_label = $CardButton/CardPanel/MarginContainer/VBoxContainer/LevelLabel
@onready var rarity_label = $CardButton/CardPanel/MarginContainer/VBoxContainer/RarityLabel
@onready var icon_rect = $CardButton/CardPanel/MarginContainer/VBoxContainer/Icon

@onready var border = $CardButton/CardPanel
@onready var click_button = $CardButton
@onready var animation: AnimationPlayer = $AnimationPlayer

func _ready():

	click_button.mouse_entered.connect(_on_mouse_entered)
	click_button.mouse_exited.connect(_on_mouse_exited)
	click_button.pressed.connect(_on_pressed)
	
func setup(card: UpgradeCardData) -> void:
	card_data = card

	title_label.text = card.upgrade.title
	desc_label.text = card.upgrade.description
	icon_rect.texture = card.upgrade.icon
	level_label.text = "Lv %d → Lv %d" % [
		card.current_level,
		card.next_level
	]
	bonus_label.text = "+%s" % card.bonus_amount

	update_rarity()

func update_rarity():

	var color = get_rarity_color(card_data.rarity)

	border.modulate = color

	rarity_label.text = get_rarity_name(card_data.rarity)

	rarity_label.modulate = color

func get_rarity_name(rarity: UpgradeData.Rarity) -> String:
	match rarity:
		UpgradeData.Rarity.COMMON:
			return "COMMON"
		UpgradeData.Rarity.UNCOMMON:
			return "UNCOMMON"
		UpgradeData.Rarity.RARE:
			return "RARE"
		UpgradeData.Rarity.EPIC:
			return "EPIC"
		UpgradeData.Rarity.LEGENDARY:
			return "LEGENDARY"
		UpgradeData.Rarity.MYTHIC:
			return "MYTHIC"

	return "UNKNOWN"

func get_rarity_color(rarity: UpgradeData.Rarity) -> Color:

	match rarity:

		UpgradeData.Rarity.COMMON:
			return Color("808080")

		UpgradeData.Rarity.UNCOMMON:
			return Color("1b9b00")

		UpgradeData.Rarity.RARE:
			return Color("007aff")

		UpgradeData.Rarity.EPIC:
			return Color("8000ff")

		UpgradeData.Rarity.LEGENDARY:
			return Color("ffff00ff")

		UpgradeData.Rarity.MYTHIC:
			return Color("ff0000ff")

	return Color.WHITE

func _on_mouse_entered():

	animation.play("Hover")

func _on_mouse_exited():

	animation.play_backwards("Hover")

func _on_pressed():

	animation.play("Select")

	await animation.animation_finished

	selected.emit(card_data)
