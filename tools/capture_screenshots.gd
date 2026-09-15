extends SceneTree
# Reproducible gameplay screenshots using the real scene and renderer.
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/%s.png" % name)
func run() -> void:
	var opening = load("res://scenes/title.tscn").instantiate()
	root.add_child(opening)
	current_scene = opening
	await frames(3)
	await capture("title")
	opening.queue_free()
	await frames(3)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.rng.seed = 144
	game.elapsed = 230
	game.level = 6
	game.kills = 160
	game.experience = 32
	game.xp_needed = game.Difficulty.xp_for_level(6)
	for id in ["whip", "orbit", "beam", "seeker", "lightning"]:
		game.armory.acquire(id)
	game.player.invulnerability = 999
	game.armory.tick(0.01)
	for i in range(25):
		var enemy = game.spawn_enemy(i % 4)
		if enemy != null:
			var angle := i * TAU / 25
			enemy.position = Vector3(cos(angle), 0, sin(angle)) * (5.5 + (i % 4) * 1.5)
	game.spawn_cooldown = 99
	game.next_boss_at = 360
	await frames(30)
	# Hold a visible cast while preserving the real attack geometry.
	game.armory.fire("lightning")
	await frames(17)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.body.visible = true
	game._update_hud()
	await capture("gameplay")
	game.experience = game.xp_needed
	game.open_weapon_choice()
	await frames(3)
	await capture("weapon-choice")
	game.choose_weapon(0)
	game.elapsed = 600
	game._start_final_boss()
	game.active_boss.position = Vector3(-3, 0, -3)
	game.active_boss.attack_cooldown = 0
	game.active_boss._physics_process(0.01)
	game.active_boss.set_physics_process(false)
	game._update_hud()
	await frames(3)
	await capture("final-boss")
	print("README SCREENSHOTS CAPTURED; AUDIO DRIVER: " + AudioServer.get_driver_name())
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
