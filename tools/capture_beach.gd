extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(label: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/beach-"+label+".png")
func run() -> void:
	var title=load("res://scenes/title.tscn").instantiate(); root.add_child(title); current_scene=title
	title.select_stage("beach"); await snap("title"); title.free(); await process_frame
	var game=load("res://scenes/main.tscn").instantiate(); game.stage_id="beach"
	root.add_child(game); current_scene=game; game.set_physics_process(false); game.set_process(false)
	game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.elapsed=300; game.player.position=Vector3(0,0,3)
	game._update_camera(); game.director.advance(); game._update_hud()
	for i in range(6):
		var enemy=game.spawn_enemy(15+i); enemy.position=Vector3(-6+(i%3)*6,0,-4+(i/3)*9)
		if enemy.kind==18: enemy.cancel_control_action()
	for id in ["shell_wave","bubble","crab_claw"]: game.armory.acquire(id)
	game.armory.tick(0.01)
	for attack in get_nodes_in_group("weapon_attacks"):
		if attack.get_meta("weapon_id","") in ["shell_wave","bubble","crab_claw"]: attack._physics_process(0.25)
	game.beach.command(); game.beach.tick(2); game._update_hud(); await snap("weapons")
	game.player.statuses.apply("ink")
	var warning=preload("res://scripts/beach_hazard.gd").new(); warning.target=game.player; warning.position=Vector3(-7,0,-2); game.actors.add_child(warning)
	await snap("ink")
	game.player.statuses.clear(); game.elapsed=600; game._tick_director(0); await process_frame
	game.presentation.tick(0.8); await snap("intro")
	game._finish_presentation(); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	game.active_boss.position=Vector3(0,0,-5); game.active_boss.initialize_training_phase(true)
	game.active_boss.tentacles(); game._update_hud(); await snap("octo")
	game.final_boss_defeated=true; game._physics_process(0); await snap("result")
	game.free(); await process_frame
	var gallery=load("res://scenes/beach_gallery.tscn").instantiate(); root.add_child(gallery); current_scene=gallery; await snap("models"); gallery.free(); await process_frame
	quit()
