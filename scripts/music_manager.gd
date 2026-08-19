extends Node

@export var main_theme: AudioStream
@export var arena_theme: AudioStream
@export var boss_theme: AudioStream
@export var ui_click_sound: AudioStream

var default_bgm: AudioStream = preload("res://PerryParry/assets/audio/music/Backgroundmusic.mp3")
var default_arena_bgm: AudioStream = preload("res://PerryParry/assets/audio/music/arena music.mp3")
var default_boss_bgm: AudioStream = preload("res://PerryParry/assets/audio/music/boss music.mp3")

var audio_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var generated_click: AudioStreamWAV

var current_track_name: String = ""
var music_volume_db: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Music Player
	audio_player = AudioStreamPlayer.new()
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player.finished.connect(_on_audio_player_finished)
	add_child(audio_player)

	# UI Click SFX Player
	click_player = AudioStreamPlayer.new()
	click_player.process_mode = Node.PROCESS_MODE_ALWAYS
	click_player.volume_db = -6.0
	add_child(click_player)

	generated_click = create_ui_click_sound()

	if main_theme == null: main_theme = default_bgm
	if arena_theme == null: arena_theme = default_arena_bgm
	if boss_theme == null: boss_theme = default_boss_bgm

	enable_stream_loop(main_theme)
	enable_stream_loop(arena_theme)
	enable_stream_loop(boss_theme)
	enable_stream_loop(default_bgm)
	enable_stream_loop(default_arena_bgm)
	enable_stream_loop(default_boss_bgm)

	get_tree().node_added.connect(_on_node_added)
	if get_tree().current_scene:
		call_deferred("update_music_for_current_scene", get_tree().current_scene)

func enable_stream_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	if "loop" in stream:
		stream.set("loop", true)

func _on_audio_player_finished() -> void:
	if current_track_name != "" and audio_player and audio_player.stream:
		audio_player.play()

func create_ui_click_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050

	var sample_count: int = int(22050 * 0.04) # 40ms duration
	var data = PackedByteArray()
	data.resize(sample_count)

	for i in range(sample_count):
		var t: float = float(i) / float(sample_count)
		var freq: float = 1200.0 - t * 600.0
		var val: float = sin(float(i) * freq * 0.0003) * (1.0 - t)
		data[i] = clamp(int((val * 0.3 + 0.5) * 255.0), 0, 255)

	stream.data = data
	return stream

func play_button_click() -> void:
	if click_player:
		click_player.stream = ui_click_sound if ui_click_sound != null else generated_click
		click_player.play()

func set_music_volume_db(value_db: float) -> void:
	music_volume_db = clamp(value_db, -80.0, 6.0)
	if audio_player:
		audio_player.volume_db = music_volume_db

func set_music_volume_linear(value_linear: float) -> void:
	if value_linear <= 0.0:
		set_music_volume_db(-80.0)
	else:
		set_music_volume_db(linear_to_db(clamp(value_linear, 0.0001, 1.0)))

func get_music_volume_linear() -> float:
	if music_volume_db <= -79.0:
		return 0.0
	return db_to_linear(music_volume_db)

func play_track(stream: AudioStream, track_name: String) -> void:
	if stream == null:
		stream = default_bgm
	enable_stream_loop(stream)
	if current_track_name == track_name and audio_player.playing:
		return

	current_track_name = track_name
	audio_player.stream = stream
	audio_player.volume_db = music_volume_db
	audio_player.play()

func play_main_theme() -> void:
	play_track(main_theme, "main")

func play_arena_theme() -> void:
	play_track(arena_theme, "arena")

func play_boss_theme() -> void:
	play_track(boss_theme, "boss")

func stop_music() -> void:
	audio_player.stop()
	current_track_name = ""

func _on_node_added(node: Node) -> void:
	if node is Button:
		if not node.pressed.is_connected(play_button_click):
			node.pressed.connect(play_button_click)

	if node == get_tree().current_scene:
		call_deferred("update_music_for_current_scene", node)

func update_music_for_current_scene(scene_node: Node) -> void:
	if scene_node == null:
		return
	var scene_name: String = scene_node.name.to_lower()
	var scene_path: String = scene_node.scene_file_path.to_lower() if scene_node.scene_file_path else ""

	if "boss" in scene_name or "boss" in scene_path:
		play_boss_theme()
	elif "arena" in scene_name or "arena" in scene_path:
		play_arena_theme()
	else:
		play_main_theme()
