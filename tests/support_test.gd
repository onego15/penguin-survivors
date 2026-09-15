extends SceneTree
var failures := 0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+caption)
	if not ok: failures+=1
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var manager=game.support
	check(manager.next_at>=75 and manager.next_at<=95,"First visit is scheduled at 75-95 seconds")
	var bags_ok:=true
	for i in range(20):
		var picks := {}
		for j in range(3):
			var previous: int=manager.last_kind
			var kind: int=manager.draw_kind()
			bags_ok=bags_ok and kind!=previous
			picks[kind]=true
		bags_ok=bags_ok and picks.size()==3
	check(bags_ok,"Every bag contains all three friends without adjacent repeats")
	var locations_ok:=true
	for corner in [Vector3.ZERO,Vector3(23,0,23),Vector3(-23,0,-23)]:
		game.player.position=corner
		game._update_camera()
		for i in range(12):
			var point: Vector3=manager.find_safe_position()
			locations_ok=locations_ok and point!=Vector3.INF and manager.position_safe(point)
	check(locations_ok,"Visits remain visible, in bounds and six to nine metres away, even at corners")
	game.player.position=Vector3.ZERO
	game._update_camera()
	var safe: Vector3=manager.find_safe_position()
	var blocker=game.spawn_enemy(0)
	blocker.set_physics_process(false)
	blocker.position=safe
	check(not manager.position_safe(safe),"A nearby enemy makes a visit position unsafe")
	blocker.free()
	var cloud=preload("res://scripts/enemy_cloud.gd").new()
	cloud.position=safe
	game.actors.add_child(cloud)
	check(not manager.position_safe(safe),"A dangerous cloud makes a visit position unsafe")
	cloud.free()
	game.elapsed=100
	manager.next_at=0
	game.last_event_at=95
	manager.tick(0.1)
	check(not is_instance_valid(manager.active),"Enemy and boss notifications postpone support arrivals")
	game.last_event_at=0
	manager.tick(0.1)
	check(is_instance_valid(manager.active),"Support arrives when the event grace period has ended")
	check(manager.notice.visible and manager.notice.banner_left==4,"Arrival displays a four-second banner")
	manager.clear()
	await process_frame
	var unattended=manager.spawn_friend(0,Vector3(7,0,0))
	game.camera.size=12
	unattended.position=Vector3(23,0,0)
	manager.notice.refresh(0)
	check(manager.notice.guide.visible,"An off-screen support has a directional portrait guide")
	unattended.position=Vector3(7,0,0)
	game.camera.size=20
	manager.notice.refresh(0)
	check(not manager.notice.guide.visible,"The guide hides when the support is on-screen")
	unattended.tick(29)
	check(unattended.state=="waiting","Unrecruited support remains for the first 29 seconds")
	unattended.tick(1)
	check(unattended.state=="leaving" and game.player.health==100,"Unrecruited support leaves after thirty seconds without penalty")
	manager.clear()
	await process_frame
	var friend=manager.spawn_friend(0,Vector3(7,0,0))
	friend.tick(1)
	check(friend.state=="waiting","Friend waits for the player to approach")
	game.player.health=70
	game.player.position=Vector3(6,0,0)
	friend.tick(0.01)
	check(friend.state=="following" and game.player.health==75,"Approaching within two metres recruits and heals immediately")
	check(manager.notice.joined and manager.notice.banner_left==3 and not friend.beacon.visible,"Recruitment changes the banner and removes the waiting beacon")
	friend.tick(24)
	check(game.player.health==95,"Bird heals exactly twenty-five HP across five pulses")
	friend.tick(6)
	check(friend.state=="leaving","Support ends after thirty active seconds")
	manager.tick(0.51)
	check(not is_instance_valid(manager.active) and manager.next_at-game.elapsed>=110 and manager.next_at-game.elapsed<=140,"Next visit starts 110-140 seconds after departure")
	friend=manager.spawn_friend(0,game.player.position)
	game.player.health=100
	friend.recruit()
	friend.tick(6)
	check(game.player.health==100,"Healing does not accumulate above maximum")
	game.player.health=0
	friend.tick(6)
	check(game.player.health==0,"Healing cannot revive the defeated player")
	manager.clear()
	await process_frame
	game.player.health=100
	friend=manager.spawn_friend(1,game.player.position)
	friend.recruit()
	game.player.take_damage(10)
	check(game.player.health==93,"Bear reduces incoming damage by thirty percent")
	game.player.take_damage(50)
	check(game.player.health==93,"Invulnerability takes precedence over damage reduction")
	game.player.invulnerability=0
	game.player.take_damage(1)
	check(game.player.health==92,"Reduced damage rounds up with a minimum of one")
	game.experience=game.xp_needed
	game.open_weapon_choice()
	var remaining: float=friend.remaining
	var banner_before: float=manager.notice.banner_left
	game.set_physics_process(true)
	await create_timer(0.1).timeout
	check(friend.remaining==remaining and manager.notice.banner_left==banner_before,"Weapon selection freezes support duration and announcement")
	game.set_physics_process(false)
	game.choose_weapon(0)
	game._start_final_boss()
	game._finish_presentation()
	check(manager.active==friend and game.player.support_damage_multiplier==0.7,"Recruited support survives the final-boss transition")
	friend.tick(30)
	check(game.player.support_damage_multiplier==1,"Bear reduction is removed on expiry")
	manager.clear()
	await process_frame
	game.final_boss_spawned=false
	friend=manager.spawn_friend(2,game.player.position)
	friend.recruit()
	var enemy=game.active_boss
	enemy.set_physics_process(false)
	enemy.position=game.player.position+Vector3(0,0,3)
	enemy.health=1
	friend.tick(0.01)
	var shot=game.actors.get_children().back()
	shot.set_physics_process(false)
	shot._physics_process(0.2)
	check(game.final_boss_defeated,"Chick attacks through the normal projectile and defeat pipeline")
	manager.clear()
	await process_frame
	friend=manager.spawn_friend(2,Vector3(-8,0,0))
	manager.begin_final()
	check(not is_instance_valid(manager.active),"Waiting support leaves at the final transition")
	game.final_boss_spawned=true
	manager.next_at=0
	manager.tick(10)
	check(not is_instance_valid(manager.active),"Normal schedule is suppressed during final battle (phase visits use their own director)")
	game.final_boss_spawned=false
	game.elapsed=570
	manager.tick(1)
	check(not is_instance_valid(manager.active),"New visits stop at nine minutes thirty seconds")
	game.player.health=100
	game.player.invulnerability=0
	friend=manager.spawn_friend(1,game.player.position)
	friend.recruit()
	game.player.health=0
	game._physics_process(0.01)
	check(game.game_over and game.player.support_damage_multiplier==1 and not is_instance_valid(manager.active),"Death clears active support and all damage reduction")
	print("SUPPORT TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
