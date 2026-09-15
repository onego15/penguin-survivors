extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/%s.png" % name)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.rng.seed=41
	game.elapsed=430
	game.level=8
	game.xp_needed=game.Difficulty.xp_for_level(8)
	game.director.advance()
	game.player.position=Vector3(0,0,2)
	game._update_camera()
	var deer=game.spawn_enemy(9)
	deer.set_physics_process(false)
	deer.position=Vector3.ZERO
	deer.cooldown=0
	deer._physics_process(0)
	deer._physics_process(0.4)
	game.player.position=Vector3(-2,0,-1)
	var mole=game.spawn_enemy(8)
	mole.set_physics_process(false)
	mole.position=Vector3(-5,0,-4)
	mole.cooldown=0
	mole._physics_process(0)
	game.rng.seed=0
	mole._physics_process(0.4)
	game.active_boss=game.spawn_enemy(-1,true)
	game.active_boss.set_physics_process(false)
	game.active_boss.position=Vector3(9,0,-4)
	game.support.spawn_friend(0,Vector3(6,0,3))
	game._update_hud()
	await snap("deer-growth")
	game.support.active.recruit()
	game.support.tick(0.5)
	await snap("support-card")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
