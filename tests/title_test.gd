extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
func run() -> void:
	var title = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	await create_timer(0.15).timeout
	check(get_nodes_in_group("enemies").is_empty() and title.start_button.has_focus(), "Title waits safely without enemies and focuses Start")
	check(ProjectSettings.get_setting("application/config/name") == "Penguin Survivors" and ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/title.tscn", "Project starts at the renamed title scene")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	title._unhandled_key_input(event)
	title.start_game()
	check(title.starting and title.start_button.disabled, "Keyboard starts once and rejects duplicate activation")
	await create_timer(0.45).timeout
	var game = current_scene
	check(game.scene_file_path == "res://scenes/main.tscn" and game.player.health == 100 and game.elapsed < 1 and game.armory.levels.size() == 1, "Start enters a fresh playable run")
	check(get_nodes_in_group("game_audio").size() == 1, "Scene transition leaves only one music controller")
	game.player.health = 0
	game._physics_process(0.01)
	event.physical_keycode = KEY_ESCAPE
	game._unhandled_input(event)
	await create_timer(0.15).timeout
	check(current_scene.scene_file_path == "res://scenes/title.tscn", "Escape returns to the opening after game over")
	print("TITLE TEST: %d failure(s)" % failures)
	current_scene.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
