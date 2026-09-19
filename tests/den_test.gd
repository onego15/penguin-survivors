extends SceneTree
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, caption: String) -> void:
	if not ok: print("FAIL: "+caption)
	if not ok: failures+=1
func enemy_at(point: Vector3, kind:=0) -> Node3D:
	var enemy=game.create_enemy({"type":"normal","index":kind},point,0)
	enemy.set_physics_process(false); enemy.health=100; enemy.max_health=100
	return enemy
func run() -> void:
	game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false)
	var manager=game.support
	for seed_value in range(16):
		game.rng.seed=seed_value; manager.bag.clear(); manager.last_kind=-1
		for cycle in range(6):
			var seen:={}
			for i in range(4):
				var previous: int=manager.last_kind
				var kind: int=manager.draw_kind()
				check(kind!=previous,"no adjacent repeats")
				seen[kind]=true
			check(seen.size()==4,"four unique friends")
	var den=manager.spawn_friend(3,Vector3.ZERO)
	var near=enemy_at(Vector3(2,0,0))
	var far=enemy_at(Vector3(12,0,0))
	var underground=enemy_at(Vector3.ZERO,8); underground.targetable=false
	den.recruit(); den.tick(0.59)
	check(den.stomps==0,"first attack waits 0.6 seconds")
	den.tick(0.01)
	check(near.health==98 and far.health==100 and underground.health==100,"range, single damage and underground exclusion")
	check(near.is_knocked_back(),"ordinary enemy knocked back")
	var start: Vector3=near.position; near.control_step(0.6)
	check(is_equal_approx(start.distance_to(near.position),4.0),"four metre push over 0.6 seconds")
	den.tick(0.1); check(near.health==98,"expanding ring has no extra damage")
	for i in range(1800):
		near.position=Vector3(2,0,0); near.control_step(1.0/60); den.tick(1.0/60)
	check(den.stomps==5 and den.state=="leaving" and not den.stomp_effect.visible,"five attacks and clean expiry")
	manager.clear(); await process_frame
	for enemy in get_nodes_in_group("all_enemies"): enemy.free()
	den=manager.spawn_friend(3,Vector3.ZERO); den.recruit()
	near=enemy_at(Vector3(2,0,0)); near.apply_control("freeze",1.0)
	den._stomp(); check(near.control.frozen==1 and near.is_knocked_back(),"frozen enemies can be pushed")
	var lock: float=near.control.knock_lock
	den._stomp(); check(near.control.knock_lock==lock and near.health==96,"push lock shared, damage still applies")
	var boss=enemy_at(Vector3(-2,0,0)); boss.is_miniboss=true
	den._stomp(); check(boss.health==98 and not boss.is_knocked_back(),"boss takes damage only")
	var minion=load("res://scripts/boss_minion.gd").new()
	minion.position=Vector3(0,0,-2); game.actors.add_child(minion); minion.set_physics_process(false)
	den._stomp(); check(minion.health==8 and minion.is_knocked_back(),"final minions can be pushed")
	var cloud=load("res://scripts/enemy_cloud.gd").new()
	game.actors.add_child(cloud)
	den._stomp(); check(not cloud.is_queued_for_deletion(),"stomp leaves independent hazards")
	var victim=enemy_at(Vector3(0,0,2)); victim.health=1
	var kills: int=game.kills; var gauge: int=game.ultimate.charge
	den._stomp(); check(game.kills==kills+1 and game.ultimate.charge>gauge,"support kill rewards include ultimate charge")
	var before: float=den.follow_age
	paused=true; await create_timer(0.05,true).timeout
	check(den.follow_age==before,"paused attack clock")
	paused=false
	game.support.begin_final(); check(manager.active==den,"following support survives boss transition")
	game.player.health=0; den.tick(1)
	check(den.state=="leaving" and not den.stomp_effect.visible,"death cancels pending attack")
	game.player.health=100; manager.clear(); await process_frame
	game.switch_terrain(true)
	den=manager.spawn_friend(3,Vector3(6,0,0)); den.recruit()
	var blocked=enemy_at(Vector3(10,0,0))
	den._stomp(); check(blocked.health==100,"castle wall blocks stomp")
	manager.clear(); await process_frame
	den=manager.spawn_friend(3,Vector3(7,0,0))
	manager.begin_final(); check(not is_instance_valid(manager.active),"waiting support removed at boss transition")
	check(ResourceLoader.exists("res://assets/audio/den_stomp.wav"),"dedicated sound exists")
	game.free(); await process_frame
	print("DEN TEST: ",failures," failures"); quit(failures)
