extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/cleanup-"+name+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate(); game.stage_id="castle"
	root.add_child(game); current_scene=game; game.set_physics_process(false); game.set_process(false)
	game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.elapsed=569
	for i in range(12):
		var enemy=game.spawn_enemy(0); enemy.position=Vector3(-5+i%4*3,0,-3+i/4*3)
	var boss=game.spawn_enemy(0,true); boss.health=boss.max_health/4; boss.position=Vector3(0,0,-9); game.active_boss=boss
	game.elapsed=570; game._tick_director(0); game._update_hud(); await snap("hud")
	game.sweep.targets[0].position=Vector3(22,0,22); game.elapsed=578; game._update_hud(); await snap("guide")
	root.get_node("Settings").open_menu(); await snap("pause"); root.get_node("Settings").close_menu()
	game.elapsed=600; game._tick_director(0); game.presentation.tick(0.8); await snap("intro")
	game._finish_presentation(); game.final_boss_defeated=true; game._physics_process(0); await snap("result")
	game.free(); await process_frame
	var title=load("res://scenes/title.tscn").instantiate(); root.add_child(title); current_scene=title; await snap("title")
	title.free(); quit()
