extends SceneTree
const Roster=preload("res://scripts/character_roster.gd")
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func run() -> void:
	check(Roster.selected()=="classic","Default is classic")
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	current_scene=title
	title.select_character("pink")
	check(title.hero.get_meta("character_id")=="pink" and title.selection_buttons[1].button_pressed,"Title selection replaces preview")
	title.start_game()
	title.select_character("classic")
	title.start_game()
	await create_timer(0.4).timeout
	var game=current_scene
	game.set_physics_process(false)
	game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	check(game.player.character_id=="pink" and game.armory.levels=={"heart":1},"Pink starts with only heart after duplicate start")
	check(not game.fire_at_nearest() and not game.player.has_frost,"No hidden frost shooting")
	var enemies: Array=[]
	for x in [2,4,6,8,13]:
		var enemy=game.spawn_enemy(0)
		enemy.position=Vector3(x,0,0)
		enemy.health=20
		enemies.append(enemy)
	game.armory.fire("heart")
	var heart=get_nodes_in_group("weapon_attacks")[0]
	check(heart.damage==2 and heart.speed==13 and heart.radius==0.35,"Heart base stats")
	var locked: Vector3=heart.direction
	enemies[4].position=Vector3(0,0,10)
	check(heart.direction==locked,"Heart aim remains fixed after launch")
	heart._physics_process(0.8)
	check(enemies[0].health==18 and enemies[1].health==18 and enemies[2].health==18 and enemies[3].health==20 and heart.is_queued_for_deletion(),"Low FPS sweep pierces exactly three enemies")
	var long_shot=preload("res://scripts/heart_projectile.gd").new()
	long_shot.position=Vector3(0,1,3)
	long_shot.direction=Vector3.RIGHT
	game.actors.add_child(long_shot)
	long_shot._physics_process(2)
	check(is_equal_approx(long_shot.distance_travelled,12) and long_shot.is_queued_for_deletion(),"Large time step stops at twelve metres")
	var mole=game.spawn_enemy(8)
	mole.position=Vector3(0,0,2)
	mole.remove_from_group("enemies")
	var buried_hp: int=mole.health
	var shot=preload("res://scripts/heart_projectile.gd").new()
	shot.position=Vector3(0,1,0)
	shot.direction=Vector3.BACK
	game.actors.add_child(shot)
	shot._physics_process(0.3)
	check(mole.health==buried_hp,"Underground mole excluded")
	var repeat_shot=preload("res://scripts/heart_projectile.gd").new()
	repeat_shot.position=Vector3(2,1,0)
	repeat_shot.direction=Vector3.RIGHT
	game.actors.add_child(repeat_shot)
	var hp_before: int=enemies[0].health
	repeat_shot._physics_process(0.01)
	repeat_shot._physics_process(0.01)
	check(enemies[0].health==hp_before-1,"One hit per enemy per projectile")
	game.armory.acquire("frost")
	check(game.player.has_frost and game.fire_at_nearest(),"Acquired frost fires normally")
	game.armory.acquire("heart")
	check(not game.armory.mounts.has("heart"),"Pink wand not duplicated on upgrade")
	for id in game.Catalog.ITEMS: game.armory.acquire(id)
	game._update_hud()
	check(game.armory.levels.size()==19,"All nineteen weapons available")
	var victory=preload("res://scripts/victory_screen.gd").new()
	victory.results={"character_id":"pink","elapsed":600,"level":19,"kills":999,"weapons":game.armory.levels}
	game.add_child(victory)
	check(victory.characters[0].get_meta("character_id")=="pink","Victory uses selected model")
	reload_current_scene()
	await create_timer(0.15).timeout
	check(current_scene.player.character_id=="pink" and current_scene.armory.levels=={"heart":1},"Retry preserves character and resets weapons")
	change_scene_to_file("res://scenes/title.tscn")
	await create_timer(0.15).timeout
	check(current_scene.hero.get_meta("character_id")=="pink","Title return retains selection")
	current_scene.select_character("classic")
	current_scene.start_game()
	await create_timer(0.4).timeout
	check(current_scene.armory.levels=={"frost":1},"Classic retains original starter")
	current_scene.queue_free()
	await process_frame
	print("PINK CHARACTER TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
