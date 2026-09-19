extends SceneTree
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures+=1; push_error(message)
func run() -> void:
	game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false)
	var den=game.support.spawn_friend(3,Vector3.ZERO); den.recruit()
	den.tick(1); check(den.stomps==0 and den.den_action.phase=="follow","empty field does not spend a stomp")
	for point in [Vector3(6,0,0),Vector3(7,0,1),Vector3(7,0,-1)]:
		var e=game.create_enemy({"type":"normal","index":0},point,0); e.health=100
	den.tick(0.5); var locked: Vector3=den.den_action.landing
	check(locked.distance_to(game.player.position)<=6 and den.den_action.phase=="prepare","cluster selects nearby landing")
	game.player.position=Vector3(0,0,4); den.tick(0.3)
	check(den.den_action.phase=="jump" and den.position.y>0 and den.den_action.landing==locked,"jump and fixed destination")
	den.tick(0.3); check(den.stomps==1 and den.stomp_hits==3,"land once and report successful pushes")
	den.tick(4); check(den.stomps==1,"no backlog burst")
	game.support.clear(); game.clear_enemies(); game.switch_terrain(true)
	var boss=game.create_enemy({"type":"final","index":1,"phase":1},Vector3(0,0,-6),0)
	boss.set_physics_process(false)
	var points=[Vector3.ZERO,Vector3(-18,0,0),Vector3(18,0,0),Vector3(6,0,8),Vector3(-6,0,-8),Vector3(-22,0,-22),Vector3(22,0,22),Vector3(22,0,-22),Vector3(-22,0,22)]
	for second in [false,true]:
		boss.enraged=second
		for seed_value in range(4):
			game.rng.seed=seed_value
			for point in points:
				game.player.position=point; boss.cancel_attacks(); boss.attack_index=1
				check(boss.begin_attack(),"safe wall plan at "+str(point))
				check(boss.warning_left==2.4 and boss.ice_walls.can_escape(point),"2.4 seconds and reachable safe floor")
				check(boss.ice_walls.columns.size()==(2 if second else 1),"phase wall count")
				var gap: float=boss.ice_walls.gap; game.player.position=point+Vector3(0,0,0.2)
				boss._physics_process(1); check(boss.ice_walls.gap==gap and not boss.ice_walls.active,"fixed gap during warning")
				boss._physics_process(1.4); check(boss.ice_walls.active,"release after full warning")
				var x: float=boss.ice_walls.columns[0].x; boss._physics_process(0.5)
				check(is_equal_approx(absf(boss.ice_walls.columns[0].x-x),1.75 if second else 1.5),"wall speed")
				check(not boss.ice_walls.touches(Vector3(0,0,gap),Vector3(0,0,gap),-8,8),"safe gap at low FPS")
				check(boss.ice_walls.touches(Vector3.ZERO,Vector3.ZERO,-8,8) if absf(gap)>2.42 else boss.ice_walls.touches(Vector3(0,0,10),Vector3(0,0,10),-8,8),"swept hit across player")
				boss._physics_process(20); check(not boss.wall_busy and boss.attack_index==2 and boss.recovery_left==2,"completion and recovery")
	boss.enraged=false; game.player.position=Vector3.ZERO; boss.attack_index=1; boss.begin_attack()
	game.player.training_invincible=false; game.player.support_damage_multiplier=0.7
	game.player.health=100; game.player.invulnerability=0
	var attack=boss.ice_walls; attack.gap=8; attack.columns[0].x=-2; attack.columns[0].direction=1
	attack.set_meta("difficulty_id","expert"); attack.start(); attack.tick(1)
	check(game.player.health==76,"wall damage uses difficulty then bear: 24 -> 34 -> 24")
	game.player.invulnerability=0; attack.columns[0].x=-2; attack.tick(1); check(game.player.health==76,"once per column")
	boss.cancel_attacks(); check(not boss.wall_busy and not is_instance_valid(boss.ice_walls),"cancel removes all walls")
	boss.attack_index=1; boss.begin_attack(); var age: float=boss.ice_walls.age
	paused=true; await process_frame; await process_frame; paused=false
	check(boss.ice_walls.age==age,"pause keeps wall clock")
	boss._enter_phase_two(); check(not boss.wall_busy,"phase change cancels walls")
	game.free(); await process_frame
	print("DEN / NOCTIS UPGRADE TEST: %d failures"%failures); quit(failures)
