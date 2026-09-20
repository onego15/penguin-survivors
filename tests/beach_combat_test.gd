extends SceneTree
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func enemy(point: Vector3) -> Node3D:
	var e=game.spawn_enemy(15); e.position=point; e.health=1000; e.max_health=1000; return e
func attack(id: String) -> Node3D:
	var a=preload("res://scripts/beach_attack.gd").new(); a.mode=id; a.stats=game.Catalog.stats(id,1); a.direction=Vector3.BACK; a.set_meta("weapon_id",id); game.actors.add_child(a); return a
func clear() -> void:
	for node in game.actors.get_children():
		if node!=game.player: node.free()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate(); game.stage_id="beach"; root.add_child(game); current_scene=game
	game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	var player=game.player
	var bolt=preload("res://scripts/boss_projectile.gd").new(); bolt.target=player; bolt.position=Vector3(0,1,-2); bolt.direction=Vector3.BACK; bolt.status_effect="ink"; bolt.damage=8; game.actors.add_child(bolt)
	player.invulnerability=1; bolt._physics_process(0.5); check(player.health==100 and player.statuses.active.is_empty(),"invulnerability blocks status")
	bolt.free(); bolt=preload("res://scripts/boss_projectile.gd").new(); bolt.target=player; bolt.position=Vector3(0,1,-2); bolt.direction=Vector3.BACK; bolt.status_effect="ink"; bolt.damage=8; game.actors.add_child(bolt)
	player.invulnerability=0; bolt._physics_process(0.5); check(player.health==92 and player.statuses.active.has("ink"),"accepted damage adds ink")
	clear(); player.statuses.clear()
	var a=enemy(Vector3(0,0,3)); var b=enemy(Vector3(0,0,6)); var far=enemy(Vector3(5,0,4))
	var wave=attack("shell_wave"); wave._physics_process(1); wave._physics_process(0.1)
	check(a.health==994 and b.health==994 and far.health==1000,"low FPS wave pierces once, outside excluded")
	clear(); a=enemy(Vector3(-2,0,0)); b=enemy(Vector3(2,0,0)); far=enemy(Vector3(0,0,4))
	var claw=attack("crab_claw"); claw._physics_process(0.2); claw._physics_process(0.1)
	check(a.health==992 and b.health==992 and far.health==1000,"claws sides once and front excluded")
	clear(); a=enemy(Vector3(0,0,2)); b=enemy(Vector3(0.8,0,2))
	var bubble=attack("bubble"); bubble.stats.count=1
	var item: Dictionary=bubble.bubbles[1]; bubble.pop(item); bubble._physics_process(0.1)
	check(a.health==1000,"pop excludes remote target")
	clear(); a=enemy(Vector3(0,0,0.7)); b=enemy(Vector3(0.6,0,0.7)); bubble=attack("bubble")
	bubble.pop(bubble.bubbles[1]); check(a.health==997 and b.health==997,"bubble splash once per bubble")
	clear(); a=enemy(Vector3(0,0,8)); a.apply_control("freeze",1.0)
	game.elapsed=70; game.beach.command(); game.beach.tick(2); var p: Vector3=a.position; game.beach.tick(0.1)
	check(a.position==p,"frozen creature not swept by current")
	clear(); var flying=game.spawn_enemy(18); flying.position=Vector3(0,0,8); flying.set_physics_process(true); p=flying.position; game.beach.tick(0.1)
	check(flying.position==p,"flying fish ignores current")
	clear(); game.free(); await process_frame
	for seed_value in [17,28,99]:
		game=load("res://scenes/main.tscn").instantiate(); game.stage_id="beach"; root.add_child(game); current_scene=game
		game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.rng.seed=seed_value
		for second in range(571):
			game.elapsed=second; game.director.tick(1,false)
			check(game.director.budget>=0 and game.director.budget<=6,"budget bounded")
			for e in get_nodes_in_group("all_enemies"): e.free()
		var seen: Dictionary=game.director.introduced_at
		for pair in [[15,0],[16,60],[18,120],[17,180],[19,240],[4,300],[20,420]]:
			check(seen.has(pair[0]) and seen[pair[0]]>=pair[1] and seen[pair[0]]<=pair[1]+10,"introduction guarantee %d seed %d"%[pair[0],seed_value])
		check(not seen.has(2) and game.director.first_boss_ready(),"no boar prerequisite")
		print("BEACH WAVE seed=%d introductions=%s budget_spent=%.0f"%[seed_value,str(seen),game.director.spent])
		game.free(); await process_frame
	var sandbox=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(sandbox); current_scene=sandbox; sandbox.set_physics_process(false)
	sandbox.switch_terrain(false,true)
	check(sandbox.beach!=null and sandbox.obstacles==null,"sandbox shore")
	var boss=sandbox.create_enemy({"type":"final","index":2,"phase":2},Vector3(0,0,-8),0)
	check(boss.enraged and boss.health==boss.max_health/2,"sandbox phase2")
	for point in [Vector3.ZERO,Vector3(23,0,0),Vector3(-23,0,0),Vector3(23,0,23),Vector3(-23,0,-23),Vector3(0,0,23)]:
		sandbox.player.position=point; boss.position=point-point.normalized()*7 if point.length()>0 else Vector3(0,0,-7)
		check(boss.tentacles(),"safe double lanes from edge/corner")
		check(boss.puddles(),"safe puddles from edge/corner")
		boss.cancel_attacks()
	boss.take_damage(99999); check(not sandbox.victory,"sandbox no automatic victory")
	sandbox.switch_terrain(false); check(sandbox.beach==null,"sandbox terrain clears")
	sandbox.free(); await process_frame
	print("BEACH COMBAT TEST: %d failures"%failures); quit(1 if failures else 0)
