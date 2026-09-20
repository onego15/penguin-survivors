extends Node
## Original generated music and bounded, rate-limited sound effects.
const EFFECTS := ["pearl_wave", "bubble_aquarium", "crab_udon", "tide", "cleanse", "sea_cast", "sea_hit", "evolve", "den_stomp", "star_fall", "star_impact", "gust", "ice_cast", "ice_break", "shot", "magic", "hit", "defeat", "hurt", "blast", "thunder", "slash", "level_up", "choose", "warning", "victory", "game_over", "support_arrive", "support_join", "support_heal", "support_guard", "support_leave", "boss_roar", "boss_transform", "quake_charge", "quake_impact", "ultimate", "bloom", "gate", "castle_throw", "noctis_cast", "noctis_roar"]
const MUSIC := ["beach","octo","octo_phase2","snowfield","boss","final_boss","final_boss_phase2","celebration","castle","noctis","noctis_phase2"]
var fading: AudioStreamPlayer
var fade_left := 0.0
var celebration_left := -1.0
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
	fading=AudioStreamPlayer.new()
	fading.bus="Music"
	add_child(fading)
	cues = AudioStreamPlayer.new()
	cues.bus = "SFX"
	add_child(cues)
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		voice.volume_db = -8
		add_child(voice)
		voices.append(voice)
	for id in EFFECTS + MUSIC:
		var clip: AudioStreamWAV = load("res://assets/audio/%s.wav" % id)
		if id in MUSIC:
			clip = clip.duplicate()
			clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
			clip.loop_begin = 0
			clip.loop_end = int(clip.get_length() * clip.mix_rate)
		clips[id] = clip
	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(860, 690)
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("233f50"))
	layer.add_child(status)
	Settings.changed.connect(_refresh_status)
	Settings.apply_audio()
	_refresh_status()
	set_track("snowfield")

func _process(delta: float) -> void:
	if fade_left>0:
		fade_left=maxf(0,fade_left-delta)
		music.volume_db=linear_to_db(maxf(0.001,1-fade_left/0.8))
		fading.volume_db=linear_to_db(maxf(0.001,fade_left/0.8))
		if fade_left<=0: fading.stop()
	else:
		music.volume_db = move_toward(music.volume_db, -10.0 if get_tree().paused else 0.0, delta * 30)
	if celebration_left>=0:
		celebration_left-=delta
		if celebration_left<=0:
			celebration_left=-1
			track="celebration"
			music.stream=clips.celebration
			music.volume_db=0
			music.play()

func _input(event: InputEvent) -> void:
	if Settings.opened or event.is_echo(): return
	if event.is_action_pressed("mute_music") or event.is_action_pressed("mute_sfx"):
		if event.is_action_pressed("mute_music"): Settings.music_muted=not Settings.music_muted
		else: Settings.sfx_muted=not Settings.sfx_muted
		Settings.save_preferences()
		get_viewport().set_input_as_handled()

func _refresh_status() -> void:
	status.text="%s: BGM %s / %s: SFX %s / Esc: 設定" % [Settings.binding_label("mute_music"),"OFF" if Settings.music_muted else "ON",Settings.binding_label("mute_sfx"),"OFF" if Settings.sfx_muted else "ON"]

func set_track(id: String) -> void:
	if ended or id == track:
		return
	var offset:=0.0
	if (id=="final_boss_phase2" and track=="final_boss") or (id=="noctis_phase2" and track=="noctis") or (id=="octo_phase2" and track=="octo"):
		offset=fmod(music.get_playback_position(),clips[id].get_length())
		fading.stream=music.stream
		fading.volume_db=0
		fading.play(offset)
		fade_left=0.8
	else:
		fading.stop()
		fade_left=0
	track = id
	music.volume_db=-60 if fade_left>0 else 0
	music.stream = clips[id]
	music.play(offset)

func play_effect(id: String) -> void:
	if not clips.has(id):
		return
	var important := id in ["evolve", "level_up", "choose", "warning", "victory", "game_over", "hurt", "support_arrive", "support_join", "boss_roar", "boss_transform", "quake_charge", "quake_impact", "ultimate", "bloom", "gate", "castle_throw", "noctis_cast", "noctis_roar"]
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
	fading.stop()
	fade_left=0
	celebration_left=clips.victory.get_length() if won else -1
	for voice in voices:
		voice.stop()
	play_effect("victory" if won else "game_over")

func _exit_tree() -> void:
	for voice in voices + [music, fading, cues]:
		voice.stop()
		voice.stream = null
	clips.clear()
