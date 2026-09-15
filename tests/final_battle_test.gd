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
	var order_ok:=true
	for seed_value in range(12):
		game.rng.seed=seed_value
		game.director=preload("res://scripts/wave_director.gd").new()
		game.director.game=game
		game.director.introduced={0:true,1:true,3:true,4:true}
		game.spawn_cooldown=0
		for t in range(89,121):
			game.elapsed=t
			game.director.tick(1,false)
			order_ok=order_ok and (t>=90 or not game.director.introduced.has(2))
			if t<120: order_ok=order_ok and not game.director.eligible(2)
			for enemy in get_nodes_in_group("all_enemies"): enemy.free()
		order_ok=order_ok and game.director.first_boss_ready()
	check(order_ok,"12 seeds introduce one boar at 90s before the 120s boss, preserving grace")
	game.director.introduced_at[2]=130.0
	game.elapsed=149.99
	check(not game.director.first_boss_ready(),"Delayed introduction blocks the miniboss for the full 20s")
	game.elapsed=150
	check(game.director.first_boss_ready(),"Delayed first boss becomes eligible after 20s")
	game.elapsed=600
	game._start_final_boss()
	game._finish_presentation()
	var boss=game.active_boss
	boss.set_physics_process(false)
	var d=game.final_director
	var sum_r2:=0.0
	var valid:=true
	for seed_value in range(20):
		game.rng.seed=seed_value
		for i in range(100):
			var p: Vector3=boss.sample_quake_center(Vector3.ZERO)
			sum_r2+=p.length_squared()
			valid=valid and p.length()<=2.5
		for center in [Vector3(23,0,23),Vector3(23,0,0),Vector3.ZERO]:
			var p: Vector3=boss.sample_quake_center(center)
			valid=valid and absf(p.x)<=23 and absf(p.z)<=23
			# Find a straight, legal escape at player speed within the full warning.
			var escape:=false
			for angle in range(72):
				var end: Vector3=center+Vector3(cos(angle*TAU/72),0,sin(angle*TAU/72))*game.player.SPEED*3
				if absf(end.x)<=23 and absf(end.z)<=23 and end.distance_to(p)>9.42: escape=true
			valid=valid and escape
	check(valid and absf(sum_r2/2000-3.125)<0.2,"20 seeds: quake disk is uniform, in bounds, escapable at center/edge/corner")
	d.tick(5.99)
	check(get_nodes_in_group("final_minions").is_empty(),"No minions before six seconds")
	d.tick(0.01)
	check(get_nodes_in_group("final_minions").size()==2,"First phase spawns two seals at six seconds")
	d.tick(1.99)
	check(not is_instance_valid(game.support.active),"No support before eight seconds")
	d.tick(0.02)
	check(d.support_count==1 and is_instance_valid(game.support.active),"Phase one provides one safe visit")
	var friend=game.support.active
	friend.recruit()
	var spawned:=get_nodes_in_group("final_minions")
	var spawn_ok:=true
	for enemy in spawned:
		var range_to_player: float=enemy.position.distance_to(game.player.position)
		spawn_ok=spawn_ok and range_to_player>=12 and range_to_player<=16 and absf(enemy.position.x)<=23 and absf(enemy.position.z)<=23
	var dir_a: Vector3=(spawned[0].position-game.player.position).normalized()
	var dir_b: Vector3=(spawned[1].position-game.player.position).normalized()
	check(spawn_ok and dir_a.dot(dir_b)>=-0.5,"Minion batch stays 12-16m away, inside the arena, within one 120-degree sector")
	var minion=get_nodes_in_group("final_minions")[0]
	minion.set_physics_process(false)
	check(minion.health==10 and minion.speed==2.2 and minion.contact_damage==8,"Seal stats have no late-game multiplier")
	minion._physics_process(0.1)
	var xp: int=game.experience
	minion.take_damage(999)
	check(game.experience==xp+2,"Seal defeat uses the shared XP path")
	await process_frame
	d.tick(12)
	d.tick(12)
	d.tick(12)
	check(get_nodes_in_group("final_minions").size()==6,"Repeated batches respect the combined six-minion cap")
	boss.warning_left=1
	d.next_minions=d.clock
	var spawn_at: float=d.next_minions
	d.tick(2)
	check(d.next_minions==spawn_at,"Boss windup defers minion spawning")
	boss.warning_left=0
	var prior_clock: float=d.clock
	game.run_state="phase_transition"
	d.tick(20)
	check(d.clock==prior_clock,"Cinematics freeze the independent final-battle clock")
	game.run_state="combat"
	paused=true
	d.tick(20)
	check(d.clock==prior_clock,"Weapon selection freezes the final-battle clock")
	paused=false
	xp=game.experience
	d.begin_phase(2)
	check(get_nodes_in_group("final_minions").is_empty() and game.experience==xp,"Phase change dismisses seals without rewards")
	d.tick(6)
	var mix:=get_nodes_in_group("final_minions")
	check(mix.size()==2 and mix[0].second_phase!=mix[1].second_phase,"Phase two introduces one seal and one leopard")
	minion=mix[1] if mix[1].second_phase else mix[0]
	check(minion.health==14 and minion.speed==3.2 and minion.reward_value==3,"Leopard keeps fixed stats and reward")
	d.tick(2)
	check(d.support_count==0 and game.support.active==friend,"Carried companion does not consume phase-two visit")
	game.support.clear()
	d.tick(0)
	d.tick(2.99)
	check(d.support_count==0,"Support waits three seconds after departure")
	d.tick(0.01)
	check(d.support_count==1 and is_instance_valid(game.support.active),"Phase-two first visit follows the carried companion")
	d.tick(3.99)
	check(get_nodes_in_group("final_minions").size()==2,"Second phase waits nine seconds between batches")
	d.tick(0.01)
	check(get_nodes_in_group("final_minions").size()==4,"Second phase adds another mixed batch after nine seconds")
	game.support.active.recruit()
	game.support.tick(30)
	game.support.tick(0.5)
	d.tick(0)
	d.tick(3)
	check(d.support_count==2 and is_instance_valid(game.support.active),"Second phase provides a second visit after thirty-second companionship")
	game.support.clear()
	d.tick(0)
	d.tick(100)
	check(d.support_count==2 and not is_instance_valid(game.support.active),"Phase two cannot exceed two support visits")
	check(get_nodes_in_group("final_minions").size()==6,"Second phase also caps minions at six")
	var removed=get_nodes_in_group("final_minions")[0]
	var removed_type: bool=removed.second_phase
	removed.free()
	d.next_minions=d.clock
	d.tick(0)
	var count_type:=0
	for e in get_nodes_in_group("final_minions"):
		if e.second_phase==removed_type: count_type+=1
	check(get_nodes_in_group("final_minions").size()==6 and count_type==3,"Single free slot restores the underrepresented species")
	xp=game.experience
	boss.take_damage(99999)
	game._physics_process(0)
	check(game.victory and get_nodes_in_group("final_minions").is_empty() and game.experience==xp,"Boss defeat clears living minions without requiring their defeat")
	game.queue_free()
	await create_timer(0.3).timeout
	print("FINAL BATTLE TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
