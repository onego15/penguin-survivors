extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	for id in ["rainbow_heart","blizzard_fan","thunder_dome"]:
		game.clear_enemies(); game.settings.weapons={id:2}; game.rebuild_player(); game.player.set_physics_process(false)
		for i in range(9):
			var enemy=game.create_enemy({"type":"normal","index":i%4},Vector3((i%3-1)*2,0,4+floori(i/3)*2),240)
			enemy.health=10000; enemy.max_health=10000; enemy.set_physics_process(false)
		game.armory.tick(0)
		for attack in game.actors.get_children():
			if attack.get_meta("weapon_id","")==id:
				attack.process_mode=Node.PROCESS_MODE_DISABLED
				attack._physics_process(0.51 if id=="thunder_dome" else 0.1)
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/evolution-balanced-"+id+".png")
	game.free(); await process_frame; quit()
