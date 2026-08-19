extends CanvasLayer

@onready var health_panel = %HealthPanel
@onready var xp_panel = %XPPanel
@onready var inventory_panel = %WeaponInventoryPanel
@onready var ammo_panel = %AmmoPanel
@onready var cooldown_panel = %CooldownPanel

@onready var wave_label: Label = %WaveLabel
@onready var boss_box: VBoxContainer = %BossBox
@onready var boss_name_label: Label = %BossNameLabel
@onready var boss_progress_bar: ProgressBar = %BossProgressBar
@onready var survival_label: Label = %SurvivalLabel
@onready var banner_label: Label = %BannerLabel

var banner_timer: float = 0.0
var in_arena_room: bool = false
var in_boss_room: bool = false
var boss_defeated: bool = false
var is_overtime: bool = false
var survival_elapsed: float = 0.0
var arena_cleared_recorded: bool = false

var boss_ref: Node = null

func _ready() -> void:
	add_to_group("HUD")
	var current_scene_name = get_tree().current_scene.name if get_tree().current_scene else ""
	var current_scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""

	in_boss_room = "boss" in current_scene_name.to_lower() or "boss" in current_scene_path.to_lower()
	in_arena_room = ("arena" in current_scene_name.to_lower() or "arena" in current_scene_path.to_lower()) and not in_boss_room

	if wave_label: wave_label.visible = in_arena_room
	if boss_box: boss_box.visible = in_boss_room

func initialize(player):
	health_panel.set_health(player.health, player.max_health)
	if not player.health_changed.is_connected(health_panel.set_health):
		player.health_changed.connect(health_panel.set_health)

	xp_panel.set_player(player)
	inventory_panel.set_inventory(player.weapon_inventory)
	cooldown_panel.initialize(player)

	ammo_panel.set_weapon(player.weapon_holder.get_weapon())
	if not player.weapon_holder.weapon_changed.is_connected(ammo_panel.set_weapon):
		player.weapon_holder.weapon_changed.connect(ammo_panel.set_weapon)

func show_banner_message(text_msg: String, color: Color = Color.RED, duration: float = 3.0) -> void:
	if banner_label:
		banner_label.text = text_msg
		banner_label.add_theme_color_override("font_color", color)
		banner_label.visible = true
		banner_timer = duration

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0 and banner_label:
			banner_label.visible = false

	# --- ARENA ROOM WAVE TRACKING ---
	if in_arena_room and wave_label:
		var director = get_tree().get_first_node_in_group("RunDirector")
		var wave_str: String = ""
		var remaining_count: int = 0

		if director:
			var cur_w: int = (director.get("current_wave_index") + 1) if director.get("current_wave_index") != null else 1
			var total_w: int = director.get("wave_enemy_counts").size() if director.get("wave_enemy_counts") != null else 1
			wave_str = "WAVE %d/%d - " % [cur_w, total_w]

			var active_list = director.get("active_wave_enemies")
			if active_list is Array:
				for e in active_list:
					if is_instance_valid(e) and not e.is_queued_for_deletion():
						if e.get("current_state") != null and e.get("current_state") == e.State.DEAD:
							continue
						remaining_count += 1
		else:
			var enemies = get_tree().get_nodes_in_group("Enemies")
			remaining_count = enemies.size()

		wave_label.text = wave_str + "ENEMIES: " + str(remaining_count)

	# --- BOSS ROOM & BOSS HP TRACKING ---
	if in_boss_room:
		if boss_ref == null or not is_instance_valid(boss_ref):
			var bosses = get_tree().get_nodes_in_group("Boss")
			if bosses.size() > 0:
				boss_ref = bosses[0]

		if boss_ref and is_instance_valid(boss_ref) and boss_progress_bar and not boss_defeated:
			var max_hp = boss_ref.get("max_health")
			var cur_hp = boss_ref.get("current_health")
			if max_hp != null and cur_hp != null and max_hp > 0:
				boss_progress_bar.value = clamp((float(cur_hp) / float(max_hp)) * 100.0, 0.0, 100.0)

			if cur_hp != null and cur_hp <= 0:
				on_boss_defeated()

	# --- OVERTIME SURVIVAL TIMER ---
	if is_overtime:
		survival_elapsed += delta
		if UpgradeManager != null:
			UpgradeManager.update_survival_time(survival_elapsed)

		if survival_label:
			var mins: int = int(survival_elapsed / 60.0)
			var secs: float = fmod(survival_elapsed, 60.0)
			survival_label.text = "SURVIVAL TIME: %02d:%04.1f" % [mins, secs]

func on_boss_defeated() -> void:
	if boss_defeated:
		return
	boss_defeated = true
	if boss_progress_bar:
		boss_progress_bar.value = 0.0
	if boss_box:
		boss_box.visible = false
	show_banner_message("YOU WON!", Color.GREEN, 2.5)

	await get_tree().create_timer(2.5).timeout
	show_banner_message("SURVIVE!", Color.RED, 3.0)

	is_overtime = true
	if survival_label:
		survival_label.visible = true

	var director = get_tree().get_first_node_in_group("RunDirector")
	if director and director.has_method("start_overtime"):
		director.start_overtime()
