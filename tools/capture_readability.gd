extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/%s.png" % name)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=330
	game.director.advance()
	game._update_camera()
	var skunk=game.spawn_enemy(6)
	skunk.position=Vector3(3,0,2)
	skunk.set_physics_process(false)
	skunk.cooldown=0
	skunk._physics_process(0)
	var mole=game.spawn_enemy(8)
	mole.position=Vector3(-3,0,-1)
	mole.set_physics_process(false)
	mole.cooldown=0
	mole._physics_process(0)
	mole._physics_process(0.2)
	game._update_hud()
	await snap("mole-digging")
	mole._physics_process(0.2)
	game.player.position=Vector3(-3,0,2)
	mole._physics_process(0.35)
	var owl=game.spawn_enemy(4)
	owl.position=Vector3(4,0,-4)
	owl.set_physics_process(false)
	owl.cooldown=0
	owl._physics_process(0)
	owl._fire(Vector3(-1,0,1).normalized())
	for actor in get_nodes_in_group("hostile_projectiles"): actor.set_physics_process(false)
	var attack=preload("res://scripts/weapon_attack.gd").new()
	attack.mode="lightning"
	attack.position=Vector3(-5,0,-2)
	attack.player=game.player
	game.actors.add_child(attack)
	attack.set_physics_process(false)
	var trail=preload("res://scripts/advanced_attack.gd").new()
	trail.mode="trail"
	trail.tint=Color("ffbf5a")
	trail.position=Vector3(-3,0,4)
	trail.player=game.player
	game.actors.add_child(trail)
	trail.set_physics_process(false)
	await snap("combat-readability")
	game.support.spawn_friend(2,Vector3(6,0,3))
	game._update_hud()
	await snap("support-arrival")
	game.support.active.position=Vector3(23,0,0)
	game.camera.size=12
	game.support.notice.refresh(4.1)
	print("GUIDE: ",game.support.notice.guide.visible," ",game.support.notice.guide.position)
	await snap("support-guide")
	game.queue_free()
	await create_timer(0.3).timeout
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	current_scene=title
	await snap("title")
	title.queue_free()
	await create_timer(0.3).timeout
	quit()
