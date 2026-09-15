extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/%s.png" % path)
func run() -> void:
	var gallery=load("res://scenes/character_gallery.tscn").instantiate()
	root.add_child(gallery)
	current_scene=gallery
	await create_timer(0.15).timeout
	await snap("creature-gallery")
	gallery.queue_free()
	await process_frame
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=430
	game.level=8
	game.xp_needed=game.Difficulty.xp_for_level(8)
	game.next_boss_at=480
	game.kills=310
	game.director.advance()
	for id in ["rear_fan","rear_bomb","seeker","orbit","beam"]: game.armory.acquire(id)
	game.armory.tick(0.01)
	for actor in game.actors.get_children():
		if actor!=game.player: actor.free()
	for i in range(6):
		var kind: int=[9,5,0,1,5,0][i]
		var enemy=game.spawn_enemy(kind)
		if enemy==null: continue
		enemy.position=Vector3(cos(i*TAU/6),0,sin(i*TAU/6))*(8.0+(i%2)*2)
		enemy.set_physics_process(false)
		if kind>=4:
			enemy.cooldown=0
			enemy._physics_process(0.01)
			if kind==8: enemy._physics_process(1.3)
	game._update_camera()
	for kind in range(3):
		game.support.clear()
		await process_frame
		var friend=game.support.spawn_friend(kind,Vector3(-2,0,1))
		friend.recruit()
		game.support.tick(0.8)
		game._update_hud()
		await process_frame
		await snap("support-%d" % kind)
	game.support.clear()
	await process_frame
	var safe: Vector3=game.support.find_safe_position()
	if safe!=Vector3.INF: game.support.spawn_friend(0,safe)
	game._update_hud()
	await process_frame
	await snap("support-visit")
	print("TEN ENEMIES AND THREE FRIENDS RENDERED")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
