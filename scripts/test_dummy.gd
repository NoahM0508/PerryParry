extends StaticBody2D

# Keep track of the math
var total_damage_taken: int = 0

@onready var sprite = $Sprite2D
@onready var damage_label = $DamageLabel
@onready var hit_timer = $HitTimer

func _ready() -> void:
	# Initialize the label text
	damage_label.text = "Hit Me!"
	
	# Connect the timer signal via code to keep it clean
	if hit_timer:
		hit_timer.timeout.connect(_on_hit_timer_timeout)

# This is the function your area_2d.gd bullets are looking for!
func take_damage(amount: int) -> void:
	total_damage_taken += amount
	
	# Update the floating text
	if damage_label:
		damage_label.text = "Hit: " + str(amount) + "\nTotal: " + str(total_damage_taken)
	
	# Print to the output console for deep debugging
	print("Dummy took ", amount, " damage. Total: ", total_damage_taken)
	
	# Visual feedback: Flash red!
	if sprite:
		sprite.modulate = Color(1, 0, 0) # Pure red
		hit_timer.start()

func _on_hit_timer_timeout() -> void:
	# Reset the sprite back to its normal color
	if sprite:
		sprite.modulate = Color(1, 1, 1) # White (Default)
