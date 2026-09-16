extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+file+".png")
func run() -> void:
	preload("res://scripts/character_roster.gd").selected_id="pink"
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	await snap("bloom-title")
	title.free()
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var enemy=game.spawn_enemy(9)
	enemy.position=Vector3(-6,0,-5)
	enemy.health=500
	enemy.max_health=500
	enemy.cooldown=0
	enemy._physics_process(0)
	enemy.set_physics_process(false)
	game.ultimate.reward(200)
	game.ultimate._process(0.1)
	await snap("bloom-ready")
	game.player.health=70
	game.ultimate.activate()
	game.player._animate(0)
	for fx in get_nodes_in_group("ultimate_effects"):
		fx.set_physics_process(false)
		fx.animate(0.5,2.2)
	game._update_hud()
	await snap("lovely-bloom")
	game.queue_free()
	await process_frame
	quit()
