extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	var game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.settings.weapons={"gust":1}; game.rebuild_player()
	game.set_physics_process(false); game.player.set_physics_process(false)
	game.player.body.rotation.y=PI
	game.armory.fire("gust")
	var fan=game.armory.gust_attack; fan.set_physics_process(false)
	for side in [-1,1]:
		fan.age=1 if side==1 else 3
		fan.update_wind(); game.armory.tick(0.1)
		await snap("fan-sweep-right" if side==1 else "fan-sweep-left")
	game.settings.weapons={}; game.rebuild_player()
	for i in range(4):
		var enemy=game.create_enemy({"type":"normal","index":0 if i<2 else 2},Vector3((i-1.5)*2.1,0,-3),0)
		enemy.set_physics_process(false)
		if i%2==1: enemy.apply_control("freeze",1.4)
	await snap("frozen-body-colors")
	game.free(); await process_frame; quit()
