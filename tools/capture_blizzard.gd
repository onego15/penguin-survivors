extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.elapsed=430
	game.director.advance()
	game.armory.acquire("nova")
	game.ultimate.reward(200)
	game.ultimate._process(0.1)
	game._update_hud()
	var deer=game.spawn_enemy(9)
	deer.position=Vector3(-5,0,-5)
	deer.cooldown=0
	deer._physics_process(0)
	deer.set_physics_process(false)
	var visual=preload("res://scripts/blizzard_visual.gd").new()
	visual.radius=4.2
	game.actors.add_child(visual)
	visual.animate(0.43,0.9)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/chime-cold.png")
	visual.free()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/ultimate-ready.png")
	game.ultimate.activate()
	game.player._animate(0)
	for child in game.actors.get_children():
		if child.get_script()==preload("res://scripts/ultimate_visual.gd"):
			child.set_physics_process(false)
			child.animate(0.55,2.2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/emperor-blizzard.png")
	game.queue_free()
	await process_frame
	quit()
