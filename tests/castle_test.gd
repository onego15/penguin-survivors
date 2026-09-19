extends SceneTree
const Stages=preload("res://scripts/stage_catalog.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failures+=1; push_error("FAIL: "+label)
func run() -> void:
	Stages.selected_id="castle"
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.invulnerability=999
	var o=game.obstacles
	check(o!=null and game.director.waves.size()==10,"Castle selected with ten waves")
	check(o.walls.size()==6 and o.gates.size()==4,"Two walls with four gate openings")
	check(not o.clear(Vector3(8,0,0)) and o.clear(Vector3(8,0,8)),"Wall solid, open gate traversable")
	check(o.sweep(Vector3.ZERO,Vector3(12,0,0),0.5).point.x<7.1,"Swept wall collision")
	check(not o.path(Vector3.ZERO,Vector3(15,0,0),0.5).is_empty(),"Path around wall through gate")
	game.elapsed=59
	o.tick(59)
	check(not o.commanding(),"All gates open before 60 seconds")
	game.elapsed=60
	o.tick(1)
	check(o.commanding(),"Gate warning begins at 60 seconds")
	for i in range(121): o.tick(1.0/60)
	check(o.gates[0].state=="closed" and o.gates[3].state=="closed","Diagonal gates close")
	check(o.gates[1].state=="open" and o.gates[2].state=="open","Other diagonal stays open")
	check(not o.path(Vector3(-18,0,-18),Vector3(18,0,18),1.7).is_empty(),"Boss-size route remains connected")
	o.open_all()
	game.player.position=Vector3(-8,0,8)
	o.command(8)
	for i in range(250): o.tick(1.0/60)
	check(o.gates[1].state=="open","Occupied gate cancels without pushing")
	check(game.player.position==Vector3(-8,0,8),"Gate never displaces player")
	o.open_all()
	game.player.position=Vector3.ZERO
	game.elapsed=0
	for kind in [10,11,12,13]:
		var enemy=game.spawn_enemy(kind)
		check(enemy!=null and enemy.health==[3,5,4,8][kind-10],"New enemy base health %d"%kind)
		if enemy!=null:
			enemy.set_physics_process(false)
			enemy.position=Vector3(12,0,0)
			for i in range(300): enemy._physics_process(1.0/60)
			check(o.clear(enemy.position,enemy.hit_radius-0.01),"Enemy stays outside walls %d"%kind)
			enemy.free()
	var walker=game.spawn_enemy(0)
	walker.position=Vector3(12,0,0)
	walker.set_physics_process(false)
	for i in range(1800): walker._physics_process(1.0/60)
	check(walker.position.distance_to(game.player.position)<2,"Pursuer actually traverses gate and reaches target")
	walker.free()
	for bomb in get_nodes_in_group("castle_bombs"): bomb.free()
	game.player.position=Vector3(5,0,0)
	var enemy=game.spawn_enemy(0)
	enemy.set_physics_process(false)
	enemy.position=Vector3(10,0,0)
	enemy.health=100
	var shot=load("res://scripts/weapon_attack.gd").new()
	shot.position=Vector3(5,1,0)
	shot.direction=Vector3.RIGHT
	shot.damage=20
	shot.piercing=true
	game.actors.add_child(shot)
	shot._physics_process(1)
	check(enemy.health==100 and shot.is_queued_for_deletion(),"Piercing shot stops at first wall")
	var area=load("res://scripts/weapon_attack.gd").new()
	area.mode="nova"
	area.position=Vector3(6,0,0)
	area.damage=20
	game.actors.add_child(area)
	area._area_hit(12,false)
	check(enemy.health==100,"Ground AOE cannot cross wall")
	game.elapsed=600
	game._start_final_boss()
	check(game.active_boss.boss_name.contains("ノクティス") and game.active_boss.health==1600,"Castle has dedicated final boss")
	game._cancel_presentation()
	game.run_state="combat"
	game.actors.process_mode=Node.PROCESS_MODE_INHERIT
	var boss=game.active_boss
	boss.cinematic_locked=false
	boss.set_physics_process(false)
	game.player.position=Vector3.ZERO
	boss.position=Vector3(0,0,-6)
	boss.begin_attack()
	check(boss.attack_kind=="gates" and o.commanding(),"Noctis starts with gates")
	for i in range(150): o.tick(1.0/60); boss._physics_process(1.0/60)
	check(boss.attack_index==1,"Gate command finishes exactly once")
	boss.cancel_attacks(); boss.begin_attack()
	check(boss.attack_kind=="walls" and boss.wall_busy,"Moving walls follow gate command")
	boss.release(); boss.warning_left=0; boss._physics_process(20)
	check(boss.attack_index==2 and not boss.wall_busy,"Wall recovery advances to feathers")
	boss.begin_attack()
	check(boss.attack_kind=="fan" and is_equal_approx(boss.warning_left,1.2),"Fan follows gate command")
	boss.release()
	check(get_nodes_in_group("hostile_projectiles").size()==5,"Phase one fan has five feathers")
	boss.warning_left=0
	boss.begin_attack()
	check(boss.attack_kind=="rings" and boss.centers.size()==1,"Phase one fixed ice ring")
	var center: Vector3=boss.centers[0]
	game.player.position=Vector3(0,0,2)
	check(boss.centers[0]==center,"Ring does not track player")
	boss.take_damage(801)
	check(boss.enraged and game.run_state=="phase_transition","Half health starts phase transition")
	game._cancel_presentation()
	game.run_state="combat"
	boss.cinematic_locked=false
	boss.attack_index=3
	check(boss.begin_attack() and boss.centers.size()==3,"Phase two has three escapable rings")
	game.free()
	Stages.selected_id="snowfield"
	await process_frame
	print("CASTLE TEST FAILURES: ",failures)
	quit(1 if failures else 0)
