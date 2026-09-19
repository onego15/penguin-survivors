extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
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
		await snap("evolution-rich-"+id)
	game.clear_enemies(); game.settings.weapons={"rainbow_heart":5}; game.rebuild_player(); game.player.set_physics_process(false)
	var target=game.create_enemy({"type":"normal","index":3},Vector3(6,0,-3),0); target.health=10000; target.max_health=10000; target.set_physics_process(false)
	game.armory.tick(0)
	for node in game.actors.get_children():
		if node.get_meta("weapon_id","")=="rainbow_heart":
			node.process_mode=Node.PROCESS_MODE_DISABLED; node._physics_process(1.22)
	await snap("evolution-rich-prism-finale")
	game.clear_enemies(); game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false)
	for i in range(5):
		var enemy=game.create_enemy({"type":"normal","index":5},Vector3(4+i*0.4,0,2+i%2),0); enemy.health=100; enemy.max_health=100; enemy.set_physics_process(false)
	var den=game.support.spawn_friend(3,Vector3(-2,0,0)); den.recruit(); den.tick(0.4); game.support.notice.refresh(0)
	await snap("den-targeted-jump")
	den.tick(0.2); den.tick(0.18); game.support.notice.refresh(0)
	await snap("den-targeted-stomp")
	game.support.clear(); game.clear_enemies(); game.switch_terrain(true)
	var boss=game.create_enemy({"type":"final","index":1,"phase":2},Vector3(3,0,-5),0); boss.set_physics_process(false)
	boss.attack_index=1; boss.begin_attack(); await snap("noctis-wall-warning")
	boss.warning_left=0; boss.release(); boss._physics_process(0.5); await snap("noctis-moving-walls")
	game.free(); await process_frame
	var gallery=load("res://scenes/weapon_gallery.tscn").instantiate(); root.add_child(gallery); current_scene=gallery
	await snap("weapon-models-31"); gallery.free(); await process_frame; quit()
