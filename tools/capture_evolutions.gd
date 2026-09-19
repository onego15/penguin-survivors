extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	var title=load("res://scenes/title.tscn").instantiate(); root.add_child(title); current_scene=title
	await snap("evolution-title")
	title.free()
	var game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	game.armory.acquire("frost"); game.experience=game.xp_needed; game.open_weapon_choice()
	await snap("evolution-choice")
	game.choose_weapon(0); await snap("evolution-branches")
	game.choose_evolution("pop_cannon")
	root.get_node("Settings").open_menu(); root.get_node("Settings").menu.evolution_book.show_book(game)
	await snap("evolution-recipes")
	root.get_node("Settings").menu.evolution_book.hide(); root.get_node("Settings").close_menu()
	game.free()
	game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	for id in game.Catalog.Evolution.ITEMS:
		game.clear_enemies(); game.settings.weapons={id:game.Catalog.max_rank(id)}; game.rebuild_player(); game.player.set_physics_process(false)
		for i in range(9):
			var unit=game.create_enemy({"type":"normal","index":i%4},Vector3((i%3-1)*2.1,0,4.0+floori(i/3)*2.4),0)
			unit.health=10000; unit.max_health=10000; unit.set_physics_process(false)
		game.armory.tick(0)
		for node in game.actors.get_children():
			if node.get_meta("weapon_id","")==id:
				node.process_mode=Node.PROCESS_MODE_DISABLED
				if id=="pearl_chime": node.core._physics_process(0.18)
				node._physics_process(0.24 if game.Catalog.Evolution.is_single(id) else (0.08 if id!="thunder_dome" else 0.51))
		if id=="pearl_chime":
			for node in game.actors.get_children():
				if node.get_meta("weapon_id","")==id: node._physics_process(0.3)
		await snap("evolution-"+id)
	game.menu.open_menu()
	for id in game.menu.weapon_options:
		game.menu.weapon_options[id].select(game.menu.weapon_options[id].get_item_index(game.settings.weapons.get(id,0)))
	var option=game.menu.weapon_options.thunder_dome
	option.grab_focus()
	await process_frame
	option.get_parent().get_parent().ensure_control_visible(option)
	await snap("evolution-sandbox")
	paused=false; game.free(); await process_frame; quit()
