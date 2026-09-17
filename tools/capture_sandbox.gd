extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+file+".png")
func run() -> void:
	var game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.menu.open_menu()
	await snap("sandbox-weapons")
	game.menu.panel.get_child(0).get_child(0).get_child(1).current_tab=1
	game.menu.enemy_picker.select(26); game.menu.select_enemy(26)
	await snap("sandbox-enemies")
	game.switch_terrain(true)
	game.create_enemy({"type":"final","index":1,"phase":2},Vector3(0,0,10),0)
	game.settings.weapons={"heart":3,"gust":3,"popsicle":3}
	game.settings.character="pink"; game.rebuild_player(true)
	game.set_stopped(true)
	game.place_batch({"type":"normal","index":14},Vector3(0,0,-10),100)
	game.place_batch({"type":"normal","index":5},Vector3(0,0,10),100)
	game.menu.close_menu()
	for x in range(-18,19,3):
		for z in range(-18,19,3):
			if game.valid_position(Vector3(x,0,z),0.6): game.place_batch({"type":"normal","index":0},Vector3(x,0,z),1)
	for enemy in get_nodes_in_group("all_enemies"): enemy.health=10000; enemy.max_health=10000
	for i in range(60): await process_frame
	var begin:=Time.get_ticks_msec()
	for i in range(120): await process_frame
	print("CAPTURE frame mean ms=",float(Time.get_ticks_msec()-begin)/120)
	print("CAPTURE enemies=",get_nodes_in_group("all_enemies").size()," fps=",Engine.get_frames_per_second())
	await snap("sandbox-field")
	game.menu.open_menu()
	game.menu.current_spec={"type":"normal","index":0}
	game.menu.placing=true; game.menu.panel.hide(); game.menu.cursor.show(); game.menu.placement_actions.show()
	Input.warp_mouse(Vector2(640,360))
	await snap("sandbox-placement")
	paused=false; game.free()
	await process_frame
	quit()
