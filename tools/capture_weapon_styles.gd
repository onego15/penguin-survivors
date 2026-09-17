extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+filename+".png")
func run() -> void:
	var gallery=load("res://scenes/weapon_gallery.tscn").instantiate()
	root.add_child(gallery); current_scene=gallery
	await snap("weapon-models-23")
	gallery.free()
	var game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.set_physics_process(false)
	var label:=Label.new()
	label.position=Vector2(20,60); label.add_theme_font_size_override("font_size",26)
	label.add_theme_color_override("font_color",Color("234455"))
	var ui:=CanvasLayer.new(); game.add_child(ui); ui.add_child(label)
	for id in game.Catalog.ITEMS:
		for enemy in get_nodes_in_group("all_enemies"): enemy.free()
		game.settings.weapons={id:1}; game.rebuild_player()
		game.player.set_physics_process(false)
		game.player.body.rotation.y=PI
		game.player.velocity=Vector3(0,0,-2)
		game.camera.size=20
		for i in range(4):
			var point:=Vector3((i%2-0.5)*4,0,-5 if i<2 else 5)
			var enemy=game.create_enemy({"type":"normal","index":i},point,0)
			enemy.health=1000; enemy.max_health=1000; enemy.set_physics_process(false)
		game.armory.cooldowns[id]=0; game.armory.tick(0)
		if id=="frost":
			var bullet=load("res://scripts/projectile.gd").new()
			bullet.position=Vector3(0,1,-2); bullet.direction=Vector3.FORWARD; game.actors.add_child(bullet)
		var duration:=0.15
		if id in ["nova","storm","orbit","udon"]: duration=0.45
		if id=="lightning": duration=0.3
		if id=="starfall": duration=0.85
		if id=="ember": duration=0.4
		for step in range(ceili(duration*60)):
			for attack in game.actors.get_children():
				if attack==game.player or attack.is_in_group("all_enemies") or attack.is_queued_for_deletion(): continue
				attack.set_physics_process(false)
				if attack.has_method("_physics_process"): attack._physics_process(1.0/60)
		for attack in game.actors.get_children(): attack.set_physics_process(false)
		label.text=game.Catalog.ITEMS[id].name+"  /  Lv.1"
		await snap("weapon-style-"+id)
	game.settings.weapons={}
	for id in load("res://scripts/stage_catalog.gd").weapon_pool("castle"): game.settings.weapons[id]=5
	game.rebuild_player(); game.player.set_physics_process(false)
	game.player.velocity=Vector3(0,0,-2)
	game.armory.cooldowns.starfall=0; game.armory.tick(0)
	for attack in game.actors.get_children():
		attack.set_physics_process(false)
		if attack!=game.player and not attack.is_in_group("all_enemies") and attack.has_method("_physics_process"): attack._physics_process(0.3)
	var warning=load("res://scripts/combat_visuals.gd").warning(game.actors,3.0)
	warning.position=Vector3(3,0,-2)
	label.text="城の16武器 / 敵予告との重なり"
	await snap("weapon-style-overlap")
	var choices: Array[String]=["fan","nova","orbit"]
	game.choice_ui.show_choices(choices,{},2)
	await snap("weapon-style-choices")
	game.choice_ui.close()
	game.free(); await process_frame
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title); current_scene=title
	await snap("weapon-style-title")
	title.free(); await process_frame; quit()
