extends SceneTree
const T=preload("res://scripts/difficulty_tiers.gd")
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/difficulty-"+name+".png")
func run() -> void:
	T.selected_id="normal"
	var title=load("res://scenes/title.tscn").instantiate(); root.add_child(title); current_scene=title
	await snap("title"); title.free(); await process_frame
	T.selected_id="expert"; preload("res://scripts/stage_catalog.gd").selected_id="castle"
	var game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_process(false); game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	game.elapsed=600; game._start_final_boss(); game._finish_presentation(); game.active_boss.position=Vector3(4,0,-5); game._update_hud()
	await snap("hud")
	root.get_node("Settings").open_menu(); await snap("pause"); root.get_node("Settings").close_menu()
	game.player.health=0; game._physics_process(0); await snap("defeat")
	game.free(); await process_frame
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_process(false); game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	game.final_boss_defeated=true; game._physics_process(0); await snap("victory"); game.free(); await process_frame
	game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.menu.open_menu()
	var tabs=game.menu.panel.find_children("*","TabContainer",true,false)[0]; tabs.current_tab=2
	await snap("sandbox"); paused=false; game.free(); quit()
