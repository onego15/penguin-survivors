extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.body.rotation.y = PI
	game.elapsed = 200
	game.kills = 120
	game.level = 5
	game.next_boss_at = 240
	for id in ["beam", "rear_fan", "rear_bomb"]:
		game.armory.acquire(id)
	game.armory.tick(0.01)
	for actor in game.actors.get_children():
		if actor != game.player: actor.free()
	for point in [Vector3(7,0,-2), Vector3(0,0,5), Vector3(-3,0,7), Vector3(4,0,6)]:
		var enemy = game.spawn_enemy(0)
		enemy.position = point
		enemy.set_physics_process(false)
	game._update_camera()
	await frames(3)
	# Force only the beam's cast target for a clear side-by-side demonstration.
	game.armory.fire("beam")
	game.armory.fire("rear_fan")
	game.armory.fire("rear_bomb")
	for attack in get_nodes_in_group("weapon_attacks"):
		attack.set_physics_process(false)
		attack._physics_process(0.22)
	game._update_hud()
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/rear-prism.png")
	print("REAR WEAPONS AND PRISM RENDERED")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
