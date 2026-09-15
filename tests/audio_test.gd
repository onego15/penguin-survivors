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
	check(sound.track == "snowfield" and sound.music.playing and sound.clips.size() == 28, "Five music tracks and twenty-three effects load and start")
	for id in sound.MUSIC:
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
	game.director.introduced_at[2]=90
	game.elapsed = 120
	game._tick_director(0.01)
	check(sound.track == "boss" and sound.cues.stream == sound.clips.warning, "Boss arrival changes music and plays warning")
	game.active_boss.take_damage(9999)
	check(sound.track == "snowfield", "Miniboss defeat restores field music")
	game._start_final_boss()
	game._finish_presentation()
	check(sound.track == "final_boss", "Final duel uses dedicated music")
	check(sound.clips.final_boss.get_length()==48 and sound.clips.final_boss_phase2.get_length()==48,"Both final-boss arrangements have identical 48-second loops")
	sound.music.seek(12)
	sound.set_track("final_boss_phase2")
	check(absf(sound.music.get_playback_position()-sound.fading.get_playback_position())<0.1,"Crossfade preserves playback position")
	sound._process(0.8)
	check(not sound.fading.playing and sound.music.volume_db==0,"Crossfade completes after 0.8 seconds")
	sound.finish(true)
	check(not sound.music.playing and sound.cues.stream == sound.clips.victory, "Victory stops the loop and plays its ending")
	sound.finish(false)
	check(sound.cues.stream == sound.clips.game_over, "Defeat has a separate ending")
	print("AUDIO TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
