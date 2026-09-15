extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var error:=root.get_texture().get_image().save_png("res://docs/screenshots/%s.png" % name)
	if error!=OK: push_error("Screenshot failed: "+name)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.elapsed=600
	game.level=10
	game.xp_needed=game.Difficulty.xp_for_level(10)
	game.kills=684
	game._start_final_boss()
	var boss=game.active_boss
	boss.set_physics_process(false)
	game._update_hud()
	game.presentation.tick(0.8)
	await snap("boss-entrance")
	game._finish_presentation()
	boss.position=Vector3(0,0,-5)
	boss.take_damage(701)
	game.presentation.tick(0.8)
	game._update_hud()
	await snap("boss-phase2")
	game._finish_presentation()
	boss.attack_cooldown=0
	boss._physics_process(0)
	boss._physics_process(1.3)
	game._update_hud()
	await snap("boss-quake-warning")
	boss._physics_process(1.7)
	await snap("boss-quake-impact")
	for id in game.Catalog.ITEMS: game.armory.levels[id]=3
	game.player.health=100
	boss.take_damage(9999)
	game._physics_process(0)
	await process_frame
	await process_frame
	game.victory_screen._process(0.4)
	await snap("victory-celebration")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
