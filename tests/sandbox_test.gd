extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)
func run() -> void:
	var roster=preload("res://scripts/character_roster.gd")
	var original=roster.selected()
	var game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	check(game.armory.levels.size()==1,"starter weapon")
	check(get_nodes_in_group("all_enemies").is_empty(),"no automatic enemies or preview enemies")
	game.menu.open_menu()
	check(paused,"menu pauses")
	game.menu.close_menu()
	var tab:=InputEventKey.new(); tab.physical_keycode=KEY_TAB; tab.pressed=true
	game.menu._input(tab); check(paused,"Tab opens menu")
	game.menu._input(tab); check(not paused,"Tab resumes")
	game.settings.weapons={}
	game.rebuild_player()
	for id in game.Catalog.ITEMS:
		game.set_weapon(id,5)
	check(game.armory.levels.size()==22,"22 weapons")
	for id in game.Catalog.ITEMS: check(game.armory.levels[id]==5,"rank "+id)
	game.settings.character="pink"; game.rebuild_player(true)
	check(game.player.character_id=="pink" and roster.selected()==original,"character isolation")
	game.settings.weapons={}; game.rebuild_player()
	check(not game.player.has_frost and not game.player.weapon.visible,"unequip starter")
	game.player.take_damage(20); check(game.player.health==100,"invincible")
	game.player.training_invincible=false; game.player.take_damage(20)
	check(game.player.health==80 and game.received==20,"damage counter")
	game.set_stopped(true)
	for i in range(15):
		game.clear_enemies()
		var enemy=game.create_enemy({"type":"normal","index":i},Vector3(0,0,8),0)
		check(enemy!=null,"normal spawn")
		check(not enemy.is_physics_processing(),"stopped")
		enemy.apply_control("freeze",1)
		enemy.apply_control("knockback",3,Vector3.BACK)
		var start=enemy.position
		game._physics_process(0.3)
		check(enemy.position.distance_to(start)>0.1,"control works while AI stopped")
		game.menu.select_enemy(i)
		check(get_nodes_in_group("all_enemies").size()==1,"preview isolated")
	for i in range(8):
		game.clear_enemies()
		var enemy=game.create_enemy({"type":"mid","index":i},Vector3(0,0,10),0)
		check(enemy.is_miniboss,"midboss")
	for i in range(2):
		for phase in [1,2]:
			game.clear_enemies(); game.switch_terrain(i==1)
			var boss=game.create_enemy({"type":"final","index":i,"phase":phase},Vector3(0,0,12),0)
			check(boss.enraged==(phase==2),"initial phase")
			boss.take_damage(boss.health-1)
			check(boss.enraged==(phase==2),"locked phase")
			boss.take_damage(10)
			check(not game.victory and not game.final_boss_defeated,"no victory")
			await process_frame
	game.clear_enemies(); game.switch_terrain(false)
	game.player.position=Vector3.ZERO
	var spec={"type":"normal","index":0,"refill":true}
	check(game.place_batch(spec,Vector3(0,0,8),3)==3,"batch")
	var enemy=get_nodes_in_group("all_enemies")[0]
	enemy.take_damage(1000)
	check(game.pending.size()==1,"refill scheduled")
	game.set_formation_refill(0,false)
	check(game.pending.is_empty(),"refill toggle cancels queue")
	game.set_formation_refill(0,true)
	game.pending.append({"spec":game.formations[0].spec,"center":Vector3(0,0,8),"left":3.0})
	await process_frame
	game._physics_process(2.9)
	check(get_nodes_in_group("all_enemies").size()==2,"refill waits")
	game._physics_process(0.2)
	check(get_nodes_in_group("all_enemies").size()==3,"refill replaces")
	check(not game.valid_position(Vector3(30,0,0),1),"outer bound")
	check(not game.valid_position(game.player.position,1),"player overlap")
	game.clear_enemies()
	check(game.pending.is_empty() and game.formations.is_empty(),"clear cancels refill")
	game.place_batch({"type":"normal","index":0},Vector3(0,0,10),100)
	game.place_batch({"type":"normal","index":0},Vector3(0,0,-10),100)
	check(get_nodes_in_group("all_enemies").size()<=100,"cap100")
	game.clear_enemies()
	game.rng.seed=471
	check(game.place_random(50,{"type":"normal","index":0},true)==50,"random fifty")
	var kinds: Dictionary={}
	var scattered=get_nodes_in_group("all_enemies")
	for foe in scattered:
		kinds[foe.kind]=true
		check(foe.position.distance_to(game.player.position)>=5,"random player clearance")
		for other in scattered:
			if foe!=other: check(foe.position.distance_to(other.position)>=foe.hit_radius+other.hit_radius,"random no overlap")
	check(kinds.size()>1,"mixed roster")
	check(game.place_random(100,{"type":"normal","index":0},false)==50,"random remaining slots")
	check(game.place_random(20,{"type":"normal","index":0},true)==0,"random full cap")
	game.clear_enemies(); game.switch_terrain(true)
	check(game.place_random(30,{"type":"normal","index":5},false)==30,"selected kind scatter")
	for foe in get_nodes_in_group("all_enemies"):
		check(foe.kind==5 and game.obstacles.clear(foe.position,foe.hit_radius),"scatter respects castle")
	game.clear_enemies(); game.switch_terrain(false)
	game.menu.start_placing(1)
	var click:=InputEventMouseButton.new(); click.pressed=true; click.button_index=MOUSE_BUTTON_LEFT; click.position=Vector2(640,450)
	game.menu.point=Vector3(0,0,8); game.menu._input(click)
	check(game.menu.placing and game.menu.placement_count==1,"continuous single placement")
	game.menu.point=Vector3(0,0,8); game.menu._input(click)
	check(game.menu.placing and game.menu.placement_count==1,"invalid click stays in mode")
	game.menu.open_menu()
	game.clear_enemies()
	# Exercise actual boss AI and obstacle clocks without the campaign director.
	game.set_stopped(false)
	game.settings.invincible=true
	for boss_index in range(2):
		game.switch_terrain(boss_index==1)
		var boss=game.create_enemy({"type":"final","index":boss_index,"phase":2},Vector3(0,0,10),0)
		for frame in range(900):
			game._physics_process(1.0/60)
			boss._physics_process(1.0/60)
		check(not game.game_over and boss.enraged,"sandbox boss AI")
		game.clear_enemies()
	game.ultimate.uses=0; game.ultimate.reward(200)
	game.menu.open_menu(); check(not game.ultimate.activate(),"paused ultimate")
	var age=game.training_time
	await physics_frame
	check(game.training_time==age,"pause clocks")
	game.menu.close_menu()
	check(game.ultimate.activate(),"ultimate after resume")
	game.player.health=0; game._physics_process(0.1)
	check(game.game_over and paused,"death pause")
	game.reset_trial(); game.menu.close_menu()
	check(game.player.health==100 and not game.game_over,"restart")
	game.save_settings()
	var saved_character=game.settings.character
	game.free(); paused=false
	game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	check(game.settings.character==saved_character,"session settings")
	check(roster.selected()==original,"campaign selection unchanged")
	game.free()
	await process_frame
	print("SANDBOX TEST: ",failures," failures")
	quit(1 if failures else 0)
