extends SceneTree
var game: Node3D
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+caption)
	if not ok: failures+=1
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.elapsed=600
	var friend=game.support.spawn_friend(1,Vector3.ZERO)
	friend.recruit()
	game._start_final_boss()
	var boss=game.active_boss
	boss.set_physics_process(false)
	check(game.run_state=="boss_intro" and not game.actors.can_process(),"Final arrival freezes the combat actor tree")
	var hp: int=boss.health
	var remaining: float=friend.remaining
	game.player.take_damage(40)
	boss.take_damage(50)
	game._physics_process(1)
	check(game.elapsed==600 and friend.remaining==remaining and boss.health==hp and game.player.health==100,"Cinematic freezes time, support duration and damage")
	game.experience=game.xp_needed
	game.open_weapon_choice()
	check(not game.choice_open,"Weapon menus cannot interrupt a cinematic")
	game.experience=0
	game._process(1.99)
	check(game.run_state=="boss_intro","Intro lasts its complete two seconds")
	game._process(0.01)
	check(game.run_state=="combat" and game.camera.size==20 and not boss.cinematic_locked,"Intro restores combat and the previous zoom exactly once")
	var before=game.active_boss
	game._start_final_boss()
	check(game.active_boss==before and game.run_state=="combat","Repeated final arrival cannot replay the intro")
	boss.attack_kind="dash"
	boss.dash_left=8
	var bolt=preload("res://scripts/boss_projectile.gd").new()
	bolt.target=game.player
	game.actors.add_child(bolt)
	boss.take_damage(701)
	check(bolt.is_queued_for_deletion() and not bolt.can_process(),"Phase transition cancels existing hostile projectiles")
	check(boss.enraged and game.run_state=="phase_transition" and boss.dash_left==0 and boss.phase_armor.visible,"Half health cancels the current attack and reveals persistent phase-two armor")
	check(game.sound.track=="final_boss_phase2" and game.sound.fade_left==0.8,"Phase two switches to its synchronized music arrangement")
	game._process(2)
	boss.position=Vector3.ZERO
	game.player.position=Vector3(0,0,20)
	boss._physics_process(1.99)
	check(boss.warning_left==0,"Phase two leaves two seconds before its first windup")
	boss._physics_process(0.02)
	check(boss.attack_kind=="quake" and boss.warning_left==3 and boss.quake_warning.visible,"The first second-phase attack is a three-second great quake")
	var center: Vector3=boss.quake_center
	var boss_start: Vector3=boss.position
	game.player.position=center+Vector3(15,0,0)
	boss._physics_process(2.99)
	check(boss.position==boss_start and boss.quake_center==center and game.player.health==100,"Quake remains fixed and does not deal early damage")
	boss._physics_process(0.02)
	check(game.player.health==100 and boss.recovery_left==2,"Leaving the quake radius avoids damage and grants two seconds of recovery")
	boss._physics_process(0.46)
	check(not boss.quake_area.visible and not boss.quake_ice.visible,"Quake graphics expire after 0.45 seconds")
	boss.quake_center=boss.position
	game.player.position=boss.position+Vector3(0,0,2)
	game.player.invulnerability=0
	boss._release_attack()
	check(game.player.health==72,"Quake's forty damage uses the common thirty-percent bear reduction")
	game.player.invulnerability=0
	boss._physics_process(0.1)
	check(game.player.health==72,"Quake has no lingering damage")
	game.player.invulnerability=1
	boss._release_attack()
	check(game.player.health==72,"Existing invulnerability blocks the great quake")
	for index in range(1,5):
		boss.cancel_attacks()
		boss.attack_cooldown=0
		game.player.position=boss.position+Vector3(0,0,4)
		boss._physics_process(0)
		check(boss.attack_kind==["shards","dash","slam","quake"][index-1],"Second-phase rotation step %d" % index)
	for point in [Vector3.ZERO,Vector3(23,0,0),Vector3(23,0,23)]:
		var escape: Vector3=Vector3(-1,0,-1).normalized() if point.x>0 else Vector3.RIGHT
		var destination: Vector3=point+escape*game.player.SPEED*3
		destination.x=clampf(destination.x,-23,23)
		destination.z=clampf(destination.z,-23,23)
		check(destination.distance_to(point)>9.42,"Three-second escape is possible at %s" % point)
	var repeats: String=game.run_state
	boss.take_damage(1)
	check(game.run_state==repeats,"Further damage never retriggers the phase transition")
	for id in game.Catalog.ITEMS: game.armory.levels[id]=3
	game.player.health=100
	boss.take_damage(9999)
	game._physics_process(0)
	check(game.victory and is_instance_valid(game.victory_screen) and game.victory_screen.characters.size()==5,"Victory shows penguin and all four friends")
	check(game.victory_screen.results.weapons.size()==game.Catalog.ITEMS.size() and not is_instance_valid(game.support.active),"Victory carries all weapon results and clears combat support")
	var hero_y: float=game.victory_screen.characters[0].position.y
	game.victory_screen._process(0.2)
	check(game.victory_screen.characters[0].position.y!=hero_y,"Celebration animates independently of the frozen battle")
	game.sound._process(game.sound.clips.victory.get_length()+0.1)
	check(game.sound.track=="celebration" and game.sound.music.playing,"Fanfare leads into looping celebration music")
	game.victory_screen.play_again.emit()
	await process_frame
	await process_frame
	game=current_scene
	check(game.run_state=="combat" and not game.final_boss_spawned and game.sound.track=="snowfield","Play again resets the run and music")
	game.set_physics_process(false)
	game._start_final_boss()
	game._finish_presentation()
	game.active_boss.take_damage(9999)
	game._physics_process(0)
	game.victory_screen.return_title.emit()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path=="res://scenes/title.tscn","Victory's title button returns to the opening")
	current_scene.queue_free()
	await process_frame
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game._start_final_boss()
	game._finish_presentation()
	game.active_boss.take_damage(9999)
	check(not is_instance_valid(game.presentation),"Lethal damage skips the second-phase cinematic")
	game.player.health=0
	game._physics_process(0)
	check(game.game_over and not game.victory and not is_instance_valid(game.victory_screen),"Simultaneous death takes priority over the celebration")
	game.queue_free()
	await create_timer(0.3).timeout
	print("FINALE SHOWCASE TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
