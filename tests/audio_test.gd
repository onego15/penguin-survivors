extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + caption)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var sound = game.sound
	check(sound.track == "snowfield" and sound.music.playing and sound.clips.size() == 20, "Music and all eighteen effects load and start")
	for id in ["snowfield", "boss"]:
		check(sound.clips[id].loop_mode == AudioStreamWAV.LOOP_FORWARD and sound.clips[id].loop_end > 0, "Music has a full-length loop: " + id)
	for i in range(100): sound.play_effect("shot")
	var count := 0
	for voice in sound.voices:
		if voice.playing: count += 1
	check(count == 1 and sound.voices.size() == 8, "Burst effects are throttled within a bounded pool")
	game.experience = game.xp_needed
	game.open_weapon_choice()
	check(paused and sound.cues.playing and sound.cues.stream == sound.clips.level_up and sound.music.can_process(), "Level-up cue and music work during selection pause")
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = KEY_M
	sound._input(event)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music can be muted during selection")
	sound._input(event)
	game.choose_weapon(0)
	check(not paused and sound.cues.stream == sound.clips.choose, "Selection confirmation resumes gameplay with a cue")
	game.elapsed = 120
	game._tick_director(0.01)
	check(sound.track == "boss" and sound.cues.stream == sound.clips.warning, "Boss arrival changes music and plays warning")
	game.active_boss.take_damage(9999)
	check(sound.track == "snowfield", "Miniboss defeat restores field music")
	game._start_final_boss()
	check(sound.track == "boss", "Final duel uses boss music")
	sound.finish(true)
	check(not sound.music.playing and sound.cues.stream == sound.clips.victory, "Victory stops the loop and plays its ending")
	sound.finish(false)
	check(sound.cues.stream == sound.clips.game_over, "Defeat has a separate ending")
	print("AUDIO TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
