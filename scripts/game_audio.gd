extends Node
## Original generated music and bounded, rate-limited sound effects.
const EFFECTS := ["shot", "magic", "hit", "defeat", "hurt", "blast", "thunder", "slash", "level_up", "choose", "warning", "victory", "game_over", "support_arrive", "support_join", "support_heal", "support_guard", "support_leave"]
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var cues: AudioStreamPlayer
var clips := {}
var last_play := {}
var track := ""
var ended := false
var status: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_audio")
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_volume_db(index, -8 if bus == "Music" else -10)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	cues = AudioStreamPlayer.new()
	cues.bus = "SFX"
	add_child(cues)
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		voice.volume_db = -8
		add_child(voice)
		voices.append(voice)
	for id in EFFECTS + ["snowfield", "boss"]:
		var clip: AudioStreamWAV = load("res://assets/audio/%s.wav" % id)
		if id in ["snowfield", "boss"]:
			clip = clip.duplicate()
			clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
			clip.loop_begin = 0
			clip.loop_end = int(clip.get_length() * clip.mix_rate)
		clips[id] = clip
	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(980, 690)
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("233f50"))
	layer.add_child(status)
	_refresh_status()
	set_track("snowfield")

func _process(delta: float) -> void:
	music.volume_db = move_toward(music.volume_db, -10.0 if get_tree().paused else 0.0, delta * 30)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_M, KEY_N]:
			var bus := AudioServer.get_bus_index("Music" if event.physical_keycode == KEY_M else "SFX")
			AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))
			_refresh_status()
			get_viewport().set_input_as_handled()

func _refresh_status() -> void:
	status.text = "M: BGM %s   /   N: SFX %s" % ["OFF" if AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) else "ON", "OFF" if AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) else "ON"]

func set_track(id: String) -> void:
	if ended or id == track:
		return
	track = id
	music.stream = clips[id]
	music.play()

func play_effect(id: String) -> void:
	if not clips.has(id):
		return
	var important := id in ["level_up", "choose", "warning", "victory", "game_over", "hurt"]
	if ended and id not in ["victory", "game_over"]:
		return
	var now := Time.get_ticks_msec()
	var gap := 120 if id in ["hit", "defeat"] else 80
	if now - int(last_play.get(id, -1000)) < gap:
		return
	last_play[id] = now
	if important:
		cues.stream = clips[id]
		cues.play()
		return
	for voice in voices:
		if not voice.playing:
			voice.stream = clips[id]
			voice.play()
			return # Drop excess effects instead of creating unbounded audio players.

func finish(won: bool) -> void:
	ended = true
	music.stop()
	for voice in voices:
		voice.stop()
	play_effect("victory" if won else "game_over")

func _exit_tree() -> void:
	for voice in voices + [music, cues]:
		voice.stop()
		voice.stream = null
	clips.clear()
