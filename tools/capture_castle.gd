extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+file+".png")
func run() -> void:
	preload("res://scripts/stage_catalog.gd").selected_id="castle"
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	await snap("castle-title")
	title.free()
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position=Vector3(0,0,2)
	game.elapsed=465
	game.director.advance()
	game.camera.size=30
	game._update_camera()
	game.obstacles.command(8)
	for i in range(10):
		var enemy=game.spawn_enemy([10,11,12,13,4,5][i%6])
		if enemy==null: continue
		enemy.position=[Vector3(-4,0,-4),Vector3(4,0,-6),Vector3(-12,0,8),Vector3(12,0,-8),Vector3(3,0,7),Vector3(-3,0,8),Vector3(-15,0,4),Vector3(15,0,4),Vector3(4,0,10),Vector3(4,0,-10)][i]
		enemy.set_physics_process(false)
		if enemy.kind==13: enemy.cooldown=0; enemy._physics_process(0)
	for id in ["heart","orbit","whip"]: game.armory.acquire(id)
	game.armory.fire("orbit")
	game.support.spawn_friend(0,Vector3(4,0,4))
	game.obstacles.tick(0.25)
	game._update_hud()
	await snap("castle-gates")
	for i in range(130): game.obstacles.tick(1.0/60)
	await snap("castle-closed-gates")
	game.elapsed=600
	game._start_final_boss()
	game._cancel_presentation()
	game.run_state="combat"
	var boss=game.active_boss
	boss.cinematic_locked=false
	boss.position=Vector3(0,0,-7)
	boss.take_damage(860)
	game._cancel_presentation()
	game.run_state="combat"
	boss.cinematic_locked=false
	boss.attack_index=2
	boss.begin_attack()
	boss.set_physics_process(false)
	game.camera.size=27
	game._update_camera()
	game._update_hud()
	await process_frame
	await snap("castle-noctis")
	var celebration=preload("res://scripts/victory_screen.gd").new()
	celebration.results={"stage_name":game.stage.name,"boss_name":game.stage.boss_name,"character_id":"pink","elapsed":651.3,"kills":980,"level":16,"weapons":{}}
	for id in game.Catalog.ITEMS: celebration.results.weapons[id]=3
	game.add_child(celebration)
	await snap("castle-clear")
	game.free()
	var display:=Node3D.new()
	root.add_child(display)
	preload("res://scripts/castle_models.gd").arena(display)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=24
	camera.position=Vector3(0,19,25)
	display.add_child(camera)
	camera.look_at(Vector3(0,0,2))
	camera.current=true
	for i in range(4):
		var model=preload("res://scripts/castle_models.gd").animal(display,10+i)
		model.position=Vector3(-9+i*6,0,-3)
		label(display,["コウモリ","アライグマ","オコジョ","ヤギ"][i],model.position+Vector3(0,2.2,0))
		var mini=preload("res://scripts/castle_miniboss.gd").new()
		mini.encounter=i
		mini.position=Vector3(-9+i*6,0,5)
		display.add_child(mini)
		mini.set_physics_process(false)
		label(display,mini.boss_name,mini.position+Vector3(0,4.1,0))
	await snap("castle-gallery")
	display.free()
	await process_frame
	quit()
func label(parent: Node3D,text: String,point: Vector3) -> void:
	var caption:=Label3D.new()
	caption.text=text
	caption.position=point
	caption.font_size=40
	caption.pixel_size=0.01
	caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(caption)
