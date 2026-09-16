extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.camera.size=19
	game.player.body.rotation.y=0
	game.armory.acquire("gust")
	game.armory.acquire("udon")
	game.armory.cooldowns.gust=999
	game.armory.cooldowns.udon=999
	game.armory.tick(0)
	for i in range(5):
		var enemy=game.spawn_enemy(i%4)
		enemy.position=Vector3((i-2)*1.8,0,4.5)
		enemy.health=100
		enemy.max_health=100
		enemy.set_physics_process(false)
	game.armory.fire("gust")
	for attack in get_nodes_in_group("weapon_attacks"):
		attack.set_physics_process(false)
		attack._physics_process(0.3)
	for enemy in get_nodes_in_group("all_enemies"): enemy.control_step(0.3)
	game._update_hud()
	await snap("wide-fan")
	for attack in get_nodes_in_group("weapon_attacks"): attack.free()
	for enemy in get_nodes_in_group("all_enemies"): enemy.free()
	var fox=game.spawn_enemy(0)
	fox.position=Vector3(0,0,10)
	fox.set_physics_process(false)
	game.armory.fire("udon")
	for attack in get_nodes_in_group("weapon_attacks"):
		attack.set_physics_process(false)
		attack._physics_process(1.1)
	await snap("long-udon-pull")
	game.free()
	preload("res://scripts/stage_catalog.gd").selected_id="castle"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=600
	game._start_final_boss()
	game._finish_presentation()
	game.player.position=Vector3(14,0,4)
	game.camera.size=22
	game._update_camera()
	var boss=game.active_boss
	boss.set_physics_process(false)
	boss.position=Vector3(4,0,8)
	boss.attack_index=0
	boss.begin_attack()
	game.obstacles.tick(2.1)
	game.obstacles.tick(0.01)
	boss._physics_process(2.1)
	boss._physics_process(0.8)
	boss._physics_process(0.45)
	game._update_hud()
	await snap("noctis-gate-vault")
	boss._physics_process(0.45)
	boss.position=Vector3(6,0,8)
	game.player.position=Vector3(14,0,8)
	boss.attack_index=1
	boss.begin_attack()
	boss.release()
	for bolt in get_nodes_in_group("hostile_projectiles"):
		bolt.set_physics_process(false)
		bolt._physics_process(0.5)
	await snap("noctis-gate-feathers")
	game.free()
	await process_frame
	quit()
