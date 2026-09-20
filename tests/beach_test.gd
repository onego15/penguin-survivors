extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func run() -> void:
	var status=preload("res://scripts/player_status.gd").new()
	check(status.apply("sand") and status.apply("shock") and not status.apply("ink"),"ink exclusive")
	check(is_equal_approx(status.move_rate(),0.8) and is_equal_approx(status.attack_rate(),1/1.2),"status multipliers")
	status.tick(1); check(not status.apply("sand") and status.active.sand==1.5,"no refresh")
	check(status.cleanse() and not status.cleanse() and not status.apply("sand"),"cleanse immunity")
	status.tick(3); check(status.apply("ink") and not status.apply("shock"),"ink excludes shock")
	status.tick(2); check(not status.apply("ink"),"natural expiry immunity")
	var stages=preload("res://scripts/stage_catalog.gd")
	var catalog=preload("res://scripts/weapon_catalog.gd")
	check(catalog.ITEMS.size()==26 and catalog.all_ids().size()==34,"weapon count")
	for id in stages.STAGES:
		check(stages.weapon_pool(id).size()==16,"16 pool "+id)
		for weapon in stages.weapon_pool(id): check(catalog.ITEMS.has(weapon),"valid weapon")
	var game=load("res://scenes/main.tscn").instantiate(); game.stage_id="beach"
	root.add_child(game); current_scene=game; game.set_physics_process(false); game.set_process(false)
	game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	check(game.beach!=null and game.director.waves==stages.BEACH_WAVES,"stage connected")
	for kind in range(15,21):
		var enemy=game.spawn_enemy(kind)
		check(enemy.kind==kind and enemy.health>0,"normal spawn %d"%kind)
		enemy.position=Vector3(0,0,4); enemy.anchor=enemy.position; enemy.choose_destination()
		for i in range(60): enemy._physics_process(1.0/30)
		check(absf(enemy.position.x)<24 and absf(enemy.position.z)<24,"patrol in arena")
		enemy.free()
	for i in range(4):
		game.boss_encounters=i
		var boss=game.spawn_enemy(0,true)
		check(boss.max_health==100+i*80,"midboss health")
		boss.free()
	game.active_boss=null; game.elapsed=60
	game.beach.command(); game.beach.tick(2)
	check(game.beach.state=="flow" and game.beach.flow(Vector3(0,0,8)).length()>1,"flow starts")
	check(game.beach.flow(Vector3.ZERO)==Vector3.ZERO,"dry land")
	game.player.position=Vector3(-14,0,-16); game.player.statuses.apply("sand"); game.beach.tick(0.01)
	check(game.player.statuses.active.is_empty() and game.beach.pool_wait[0]>14,"spring")
	game.run_state="phase_transition"; var clock: float=game.beach.clock; game.beach.tick(2)
	check(game.beach.clock==clock,"cinematic pause")
	game.run_state="combat"
	for id in ["shell_wave","bubble","crab_claw"]:
		game.armory.acquire(id); check(game.armory.fire(id),"new weapon fire "+id)
		for attack in get_nodes_in_group("weapon_attacks"):
			if attack.get_meta("weapon_id","")==id:
				for i in range(10): attack._physics_process(0.02)
	game.elapsed=570; game._tick_director(0); game.beach.tick(0.01)
	check(game.beach.state=="idle","cleanup stops tide")
	game.elapsed=600; game._tick_director(0); await process_frame
	check(game.active_boss.boss_name.contains("オクト") and game.active_boss.max_health==1600,"final boss")
	game._finish_presentation(); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	var boss=game.active_boss
	boss.begin_attack(); check(boss.attack_kind=="tide","tide first")
	boss._physics_process(8); check(boss.attack_index==1,"tentacle next")
	boss.begin_attack(); check(boss.hazards.size()==1,"one tentacle")
	boss.cancel_attacks(); boss.take_damage(800); check(boss.enraged and game.run_state=="phase_transition","half phase")
	game._finish_presentation(); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	boss.begin_attack(); boss._physics_process(5); check(boss.hazards.size()==2,"phase2 tide plus double tentacle")
	boss.cancel_attacks(); check(game.beach.state=="idle" and not boss.wall_busy,"cancel")
	game.free(); await process_frame
	print("BEACH TEST: %d failures"%failures); quit(1 if failures else 0)
