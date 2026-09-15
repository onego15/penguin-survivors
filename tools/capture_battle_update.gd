extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.elapsed=430
	game.level=10
	game.xp_needed=game.Difficulty.xp_for_level(10)
	game.next_boss_at=480
	game.rng.seed=41
	game.director.advance()
	var deer=game.spawn_enemy(9)
	deer.set_physics_process(false)
	deer.position=Vector3(-5,0,-5)
	deer.cooldown=0
	deer._physics_process(0)
	deer._physics_process(0.4)
	for entry in [["storm",Vector3(3,0,-3),2.6,3.2,1.2],["whip",Vector3.ZERO,3.8,0.35,0.17],["trail",Vector3(-2,0,3),1.25,4,0.5],["nova",Vector3(5,0,4),3.0,0.7,0.5]]:
		var attack=load("res://scripts/advanced_attack.gd" if entry[0] in ["whip","trail"] else "res://scripts/weapon_attack.gd").new()
		attack.mode=entry[0]
		attack.position=entry[1]
		attack.area_radius=entry[2]
		attack.lifetime=entry[3]
		attack.player=game.player
		attack.direction=Vector3.BACK
		attack.damage=0
		game.actors.add_child(attack)
		attack.set_physics_process(false)
		attack._physics_process(entry[4])
	game._update_hud()
	await snap("weapon-flourishes")
	deer._physics_process(0.8)
	for shot in get_nodes_in_group("regular_projectiles"):
		shot.set_physics_process(false)
		shot._physics_process(0.5)
	await snap("deer-shockwave")
	game.elapsed=600
	game._start_final_boss()
	game._finish_presentation()
	await process_frame
	var boss=game.active_boss
	boss.set_physics_process(false)
	boss.position=Vector3(0,0,-4)
	game.camera.size=24
	for phase in [1,2]:
		if phase==2:
			boss.take_damage(701)
			game._finish_presentation()
		game.support.clear()
		game.support.spawn_friend(phase-1,Vector3(7,0,1))
		for i in range(2):
			var minion=preload("res://scripts/boss_minion.gd").new()
			minion.second_phase=phase==2
			minion.target=game.player
			minion.position=Vector3(-4+i*8,0,-2)
			game.actors.add_child(minion)
			minion.set_physics_process(false)
		game._update_hud()
		await snap("boss-minions-%d" % phase)
		if phase==2:
			boss.attack_cooldown=0
			boss._physics_process(0)
			boss._physics_process(1)
			game._update_hud()
			await snap("boss-remote-quake")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
