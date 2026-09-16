extends SceneTree
const Stages=preload("res://scripts/stage_catalog.gd")
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok: failures+=1
func clear_actors() -> void:
	for actor in game.actors.get_children():
		if actor!=game.player: actor.free()
func run() -> void:
	Stages.selected_id="castle"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.invulnerability=999
	for seed_value in range(12):
		game.rng.seed=seed_value
		game.director=load("res://scripts/wave_director.gd").new()
		game.director.game=game
		game.director.waves=Stages.CASTLE_WAVES
		game.elapsed=0
		game.spawn_cooldown=0
		for step in range(1200):
			game.elapsed=step*0.5
			game.director.tick(0.5,false)
			clear_actors()
		var times: Dictionary=game.director.introduced_at
		check(times.has(13) and times[13]>=420 and times[13]<=430 and times[2]>=90 and times[2]<=100,"Seed %d preserves goat/boar introductions"%seed_value)
		check(game.director.introduced.size()==11,"Castle introduces exactly eleven kinds, seed %d"%seed_value)
	game.elapsed=0
	game.player.position=Vector3(6.5,0,0)
	var o=game.obstacles
	# All 19 weapon entry points are exercised near a wall.
	for id in game.Catalog.ITEMS:
		var enemy=game.spawn_enemy(0)
		enemy.position=Vector3(9.2,0,0)
		enemy.health=1000
		enemy.set_physics_process(false)
		game.armory.acquire(id)
		game.player.body.rotation.y=-PI/2 if id in ["rear_fan","rear_bomb"] else PI/2
		game.player.velocity=Vector3.RIGHT
		game.armory.last_trail=Vector3.INF
		if id=="frost": game.fire_at_nearest()
		else: game.armory.fire(id)
		check(enemy.health==1000,"Weapon starts without wall-crossing instant damage: "+id)
		for attack in get_nodes_in_group("weapon_attacks"):
			check(o.clear(attack.position,0.01),"Weapon placement outside walls: "+id)
		for step in range(30):
			for actor in game.actors.get_children():
				if actor==enemy or actor==game.player or actor.is_queued_for_deletion(): continue
				if actor.has_method("_physics_process"): actor._physics_process(0.1)
			for actor in game.actors.get_children():
				if actor.is_queued_for_deletion(): actor.free()
		if id not in ["ember","lightning","storm","rear_bomb"]:
			check(enemy.health==1000,"Full attack simulation respects wall: "+id)
		clear_actors()
	var bounce=load("res://scripts/advanced_attack.gd").new()
	bounce.mode="bounce"
	bounce.position=Vector3(6,1,0)
	bounce.direction=Vector3.RIGHT
	game.actors.add_child(bounce)
	bounce._physics_process(0.2)
	check(bounce.direction.x<0 and bounce.position.x<7.1,"Ice billiard reflects from castle wall")
	clear_actors()
	var fish=load("res://scripts/weapon_attack.gd").new()
	fish.mode="boomerang"
	fish.player=game.player
	fish.position=Vector3(5,1,0)
	fish.direction=Vector3.RIGHT
	game.actors.add_child(fish)
	fish._physics_process(0.7)
	check(fish.is_queued_for_deletion(),"Elliptical boomerang disappears at wall")
	clear_actors()
	var enemy=game.spawn_enemy(0)
	enemy.position=Vector3(10,0,0)
	enemy.health=1000
	enemy.set_physics_process(false)
	var meteor=load("res://scripts/weapon_attack.gd").new()
	meteor.mode="meteor"
	meteor.position=enemy.position
	meteor.damage=20
	game.actors.add_child(meteor)
	meteor._explode()
	check(enemy.health==980,"Air attack lands on floor beyond wall")
	game.ultimate.reward(200)
	game.ultimate.activate()
	check(enemy.health==880,"Ultimate crosses castle wall unchanged")
	clear_actors()
	game.player.position=Vector3.ZERO
	for encounter in range(4):
		game.boss_encounters=encounter
		var boss=game.spawn_enemy(-1,true)
		boss.set_physics_process(false)
		boss.position=Vector3(0,0,-5)
		game.active_boss=boss
		check(boss.kind==10+encounter and boss.health==100+80*encounter,"Dedicated castle miniboss %d keeps health budget"%encounter)
		o.command(8)
		o.tick(0.1)
		check(not o.commanding(),"Miniboss forces gates open %d"%encounter)
		boss.start_attack()
		for i in range(240): boss._physics_process(1.0/60)
		check(o.clear(boss.position,boss.hit_radius-0.01),"Castle miniboss remains on floor %d"%encounter)
		clear_actors()
	game.active_boss=null
	game.elapsed=500
	for kind in [10,11,12,13]:
		for i in range(10): game.spawn_enemy(kind)
		var count:=0
		for e in get_nodes_in_group("all_enemies"):
			if e.kind==kind: count+=1
		check(count==(2 if kind==13 else 3),"New enemy kind cap %d"%kind)
	check(get_nodes_in_group("all_enemies").size()<=12,"Special population remains bounded")
	clear_actors()
	game.elapsed=70
	o.command(8)
	var before: float=o.gates[0].left+o.gates[1].left
	paused=true
	o.tick(10)
	check(is_equal_approx(before,o.gates[0].left+o.gates[1].left),"Weapon pause freezes gate countdown")
	paused=false
	game.run_state="boss_intro"
	o.tick(10)
	check(is_equal_approx(before,o.gates[0].left+o.gates[1].left),"Cinematic freezes gate countdown")
	game.run_state="combat"
	game.player.position=Vector3.ZERO
	var safe:=true
	for i in range(30):
		var point: Vector3=game.support.find_safe_position()
		if point!=Vector3.INF and not o.reachable(game.player.position,point): safe=false
	check(safe,"Support placements are walkable and reachable")
	game.free()
	Stages.selected_id="snowfield"
	await process_frame
	print("CASTLE RULES TEST: %d failure(s)"%failures)
	quit(1 if failures else 0)
