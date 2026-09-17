extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	game.camera.size=15
	var den=game.support.spawn_friend(3,Vector3(4,0,0))
	game.support.notice.refresh(0)
	await snap("den-arrival")
	den.recruit(); den.tick(0.58)
	for i in range(4):
		var enemy=game.spawn_enemy(i)
		enemy.position=den.position+Vector3(cos(i*TAU/4),0,sin(i*TAU/4))*3.2
		enemy.health=100; enemy.max_health=100; enemy.set_physics_process(false)
	den.tick(0.02); den.stomp_effect.tick(0.3)
	for enemy in get_nodes_in_group("all_enemies"): enemy.control_step(0.2)
	var warning=load("res://scripts/combat_visuals.gd").warning(game.actors,2.0)
	warning.position=Vector3(4,0,1)
	game.support.notice.refresh(0)
	await snap("den-stomp")
	game.support.clear()
	var victory=load("res://scripts/victory_screen.gd").new()
	victory.results={"elapsed":660,"level":12,"kills":800,"weapons":{"frost":5,"beam":3},"character_id":"classic"}
	game.add_child(victory)
	await snap("den-celebration")
	game.free(); await process_frame; quit()
