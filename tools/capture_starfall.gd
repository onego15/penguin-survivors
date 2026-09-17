extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title); current_scene=title
	var ui=title.weapon_list.get_parent()
	for item in ui.get_children():
		if item is Button and item.text=="出現武器16種を見る": item.pressed.emit()
	await snap("stage-weapon-list")
	title.free()
	var game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	game.settings.weapons={"orbit":5}; game.rebuild_player()
	game.armory.fire("orbit")
	game.armory.orbit_attack.set_physics_process(false)
	game.armory.orbit_attack._physics_process(0.2)
	game.camera.size=14
	await snap("six-pearls")
	game.settings.weapons={"starfall":5}; game.rebuild_player()
	for i in range(6):
		var e=game.create_enemy({"type":"normal","index":i},Vector3(-3+i*1.2,0,-6),0)
		e.health=100; e.max_health=100; e.set_physics_process(false)
	game.armory.cooldowns.starfall=0; game.armory.fire("starfall")
	var attack=get_nodes_in_group("weapon_attacks")[0]; attack.set_physics_process(false)
	attack._physics_process(0.85)
	await snap("starfall-warning")
	attack._physics_process(0.6)
	await snap("starfall-impact")
	for id in game.Catalog.ITEMS: game.settings.weapons[id]=5
	game.rebuild_player()
	game.menu.open_menu()
	for id in game.menu.weapon_options: game.menu.weapon_options[id].select(5)
	await snap("twenty-three-weapons")
	paused=false; game.free(); await process_frame; quit()
