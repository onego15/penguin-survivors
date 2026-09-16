extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for stage in ["snowfield","castle"]:
		preload("res://scripts/stage_catalog.gd").selected_id=stage
		var game=load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		current_scene=game
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		game.player.invulnerability=999
		game.elapsed=540
		game.rng.seed=73
		game.director.advance()
		game._update_hud()
		for i in range(48):
			var enemy=game.spawn_enemy(0)
			enemy.health=100000
			enemy.max_health=enemy.health
		for id in game.Catalog.ITEMS: game.armory.acquire(id)
		for frame in range(60):
			game.armory.tick(1.0/60)
			await RenderingServer.frame_post_draw
		var start:=Time.get_ticks_usec()
		var peak:=0
		for frame in range(180):
			game.armory.tick(1.0/60)
			if game.obstacles!=null: game.obstacles.tick(1.0/60)
			await RenderingServer.frame_post_draw
			peak=maxi(peak,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		print("CASTLE PROFILE stage=%s enemies=48 weapons=19 average_ms=%.2f peak_draw_calls=%d"%[stage,(Time.get_ticks_usec()-start)/180000.0,peak])
		root.get_texture().get_image().save_png("res://docs/screenshots/castle-stress-"+stage+".png")
		game.free()
		await process_frame
	quit()
