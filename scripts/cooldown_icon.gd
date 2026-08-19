extends Control

@onready var icon = $Icon
@onready var overlay = $CooldownOverlay
@onready var timer_label = $TimerLabel
@onready var animation = $AnimationPlayer

var cooldown: float = 0.0
var remaining: float = 0.0

func _ready():
	if overlay:
		overlay.max_value = 1.0
		overlay.value = 1.0
	if timer_label:
		timer_label.text = ""
	set_process(false)

func set_icon(texture: Texture2D):
	if icon:
		icon.texture = texture

func start_cooldown(time: float):
	if time <= 0.0:
		set_ready()
		return

	cooldown = time
	remaining = time
	if timer_label:
		timer_label.text = "%.1f" % remaining
	if overlay:
		overlay.value = 0.0
	set_process(true)

func set_ready():
	remaining = 0.0
	if overlay:
		overlay.value = 1.0
	if timer_label:
		timer_label.text = ""
	set_process(false)
	if animation and animation.has_animation("ReadyFlash"):
		animation.play("ReadyFlash")

func _process(delta: float):
	if remaining <= 0.0:
		set_ready()
		return

	remaining -= delta
	if remaining <= 0.0:
		set_ready()
		return

	if overlay and cooldown > 0.0:
		overlay.value = clamp(1.0 - (remaining / cooldown), 0.0, 1.0)

	if timer_label:
		timer_label.text = "%.1f" % max(0.0, remaining)
