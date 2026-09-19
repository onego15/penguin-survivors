extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run() -> void:
	preload("res://scripts/stage_catalog.gd").selected_id="castle"
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=600
	game._start_final_boss()
	game._finish_presentation()
	var boss=game.active_boss
	boss.set_physics_process(false)
	boss.position=Vector3(4,0,8)
	game.player.position=Vector3(14,0,4)
	boss.attack_index=0
	boss.begin_attack()
	game.obstacles.tick(2.1)
	boss._physics_process(2.1)
	check(boss.attack_kind=="vault" and boss.warning_left==0.8,"Gate command leads to warned vault")
	var finish: Vector3=boss.flight_end
	check(game.obstacles.clear(finish,boss.hit_radius) and finish.x>8,"Vault chooses floor across gate")
	boss._physics_process(0.8)
	check(boss.dash_left==0.9 and not boss.targetable and not boss.is_in_group("enemies"),"Vault enters untargetable transit with reinforcements deferred")
	boss._physics_process(0.45)
	check(is_equal_approx(boss.position.x,8) and boss.model.position.y>3,"Visible flight passes above gate")
	var hp: int=boss.health
	boss.take_damage(50)
	check(boss.health==hp,"No ground hitbox during flight")
	boss._physics_process(0.45)
	check(boss.position.is_equal_approx(finish) and boss.targetable and boss.attack_index==1,"Landing restores target and continues moving-wall attack")
	boss.position=Vector3(4,0,8)
	game.player.position=Vector3(14,0,4)
	boss.attack_index=0
	boss.begin_attack()
	boss.release()
	boss.release()
	boss._physics_process(0.4)
	boss.cancel_attacks()
	check(boss.dash_left==0 and boss.targetable and game.obstacles.clear(boss.position,boss.hit_radius),"Cancelled vault returns to safe floor")
	game.obstacles.gates[3].state="closed"
	game.player.position=Vector3(11,0,8)
	boss.position=Vector3(6,0,8)
	boss.attack_index=2
	boss.begin_attack()
	var locked: Vector3=boss.locked
	game.player.position=Vector3(11,0,9)
	boss.release()
	var phased:=0
	for bolt in get_nodes_in_group("hostile_projectiles"):
		bolt.set_physics_process(false)
		if bolt.pass_gates: phased+=1
	check(phased==5 and boss.locked==locked,"Five gate-piercing feathers retain locked aim")
	var bolt=preload("res://scripts/boss_projectile.gd").new()
	bolt.position=Vector3(6,1,8)
	bolt.direction=Vector3.RIGHT
	bolt.pass_gates=true
	game.actors.add_child(bolt)
	bolt.set_physics_process(false)
	bolt._physics_process(0.7)
	check(bolt.position.x>9 and not bolt.is_queued_for_deletion(),"Feather crosses closed gate")
	bolt.position=Vector3(6,1,0)
	bolt._physics_process(0.7)
	check(bolt.is_queued_for_deletion() and bolt.position.x<8,"Solid wall still blocks feather")
	check(boss.attack_visible(Vector3(6,0,8),Vector3(10,0,8)) and not boss.attack_visible(Vector3(6,0,0),Vector3(10,0,0)),"Ring damage and escape checks share gate-piercing visibility")
	game.free()
	await process_frame
	preload("res://scripts/stage_catalog.gd").selected_id="snowfield"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var enemy=game.spawn_enemy(0)
	enemy.position=Vector3(0,0,10)
	enemy.health=2
	enemy.max_health=2
	enemy.set_physics_process(false)
	game.armory.acquire("udon")
	check(game.armory.fire("udon"),"Udon acquires enemy ten metres away at level one")
	var noodle=get_nodes_in_group("weapon_attacks")[0]
	noodle.set_physics_process(false)
	noodle._physics_process(0.35)
	noodle._physics_process(0.8)
	check(enemy.health==1 and enemy.position.z<6.5 and noodle.grip.visible,"Weak enemy survives until visibly reeled in with noodle grip")
	noodle._physics_process(0.1)
	check(enemy.dead and game.kills==1,"Return damage finishes once after tug and rewards kill")
	game.free()
	await process_frame
	print("CASTLE CONTROL REBALANCE: %d failure(s)"%failures)
	quit(1 if failures else 0)
