extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	preload("res://scripts/character_roster.gd").selected_id="classic"
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.body.rotation.y=0
	game.camera.size=14
	game.armory.acquire("gust")
	game.armory.acquire("popsicle")
	game.armory.levels.gust=3
	game.armory.levels.popsicle=3
	game.armory.cooldowns.gust=999
	game.armory.cooldowns.popsicle=999
	game.armory.tick(0)
	var enemies: Array[Node3D]=[]
	for i in range(4):
		var enemy=game.spawn_enemy(i)
		enemy.position=Vector3(-2+i*1.3,0,3.2+absf(i-1.5)*0.2)
		enemy.health=100
		enemy.max_health=100
		enemy.set_physics_process(false)
		enemies.append(enemy)
	game.armory.fire("gust")
	for attack in get_nodes_in_group("control_attacks"):
		attack.set_physics_process(false)
		attack._physics_process(0.12)
	for enemy in enemies: enemy.control_step(0.12)
	game._update_hud()
	await snap("knockback-fan")
	for attack in get_nodes_in_group("control_attacks"): attack.free()
	for enemy in enemies:
		enemy.control_step(1.1)
		enemy.apply_control("freeze",1.2)
	var ice=load("res://scripts/control_attack.gd").new()
	ice.mode="popsicle"
	ice.stats=game.Catalog.stats("popsicle",3)
	ice.position=Vector3(1,1,1)
	game.actors.add_child(ice)
	ice.set_physics_process(false)
	await snap("ice-candy-freeze")
	game.armory.levels.gust=2
	game.armory.levels.popsicle=2
	var ids: Array[String]=["gust","popsicle","udon"]
	game.choice_ui.show_choices(ids,game.armory.levels,6)
	await snap("control-upgrades")
	game.choice_ui.close()
	for id in game.Catalog.ITEMS: game.armory.acquire(id)
	game._update_hud()
	await snap("twenty-two-weapons")
	var victory=load("res://scripts/victory_screen.gd").new()
	victory.results={"character_id":"classic","elapsed":650,"level":22,"kills":999,"weapons":game.armory.levels.duplicate()}
	game.add_child(victory)
	await snap("twenty-two-clear")
	game.free()
	await process_frame
	quit()
