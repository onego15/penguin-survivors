extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game); current_scene=game
	for i in range(8): await process_frame
	root.get_node("Settings").open_menu()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/pause-settings.png")
	var menu=root.get_node("Settings").menu
	menu.key_buttons.move_up.get_parent().get_parent().get_parent().current_tab=1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/settings-controls.png")
	root.get_node("Settings").close_menu()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	for i in range(6):
		var enemy=game.spawn_enemy(i%4)
		enemy.position=Vector3(-4+i*1.6,0,-3)
		enemy.set_physics_process(false)
	for id in ["storm","nova","whip"]: game.armory.acquire(id)
	game.armory.tick(0.2)
	var warning=load("res://scripts/combat_visuals.gd").warning(game.actors,2.5)
	warning.position=Vector3(1,0,0)
	root.get_node("Settings").effect_opacity=0.4
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/friendly-opacity.png")
	root.get_node("Settings").effect_opacity=1
	game.free(); await process_frame; quit()
