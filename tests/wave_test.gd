extends SceneTree
const Director=preload("res://scripts/wave_director.gd")
var game: Node3D
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+caption)
	if not ok: failures+=1
func clean() -> void:
	for actor in game.actors.get_children():
		if actor!=game.player: actor.free()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var all_pairs:={}
	var valid:=true
	for seed_value in range(40):
		game.rng.seed=seed_value
		var d:=Director.new()
		d.game=game
		var prior: Array=[]
		for wave in range(10):
			game.elapsed=wave*60
			d.advance()
			valid=valid and d.wave==wave and (wave==0 or d.pair!=prior)
			if wave>0:
				valid=valid and Director.WAVES[wave].pairs.has(d.pair)
				all_pairs[str(d.pair)]=true
			prior=d.pair.duplicate()
	check(valid and all_pairs.size()>=12,"Forty seeds select valid, varied compositions without consecutive repeats")
	game.director=Director.new()
	game.director.game=game
	game.spawn_cooldown=3
	game.elapsed=0
	var first_seen:={0:0.0}
	var unlocked_at:={1:30,3:60,4:60,2:90,5:120,6:180,7:240,8:300,9:420}
	var embargo_ok:=true
	var spending_ok:=true
	var earned:=0.0
	for step in range(1200):
		game.elapsed=step*0.5
		earned+=game.Difficulty.profile(game.elapsed).rate*0.5
		game.director.tick(0.5,false)
		spending_ok=spending_ok and game.director.spent<=earned+0.01 and game.director.budget<=6
		for enemy in get_nodes_in_group("all_enemies"):
			var kind: int=enemy.kind
			if not first_seen.has(kind): first_seen[kind]=game.elapsed
			elif kind!=0 and game.elapsed-float(first_seen[kind])<10: embargo_ok=false
		clean()
	var timing_ok:=first_seen.size()==10
	for kind in unlocked_at:
		timing_ok=timing_ok and first_seen.has(kind) and first_seen.get(kind,-100)>=unlocked_at[kind] and first_seen.get(kind,9999)<=unlocked_at[kind]+10
	check(timing_ok,"Every new enemy is introduced within ten seconds of its fixed unlock, through minute seven")
	check(embargo_ok,"Each introduction has a ten-second same-species grace period")
	check(spending_ok,"Spawn costs never exceed accrued budget and idle budget is capped")
	game.elapsed=240
	game.director=Director.new()
	game.director.game=game
	game.director.introduced[1]=true
	game.director.introduced[2]=true
	game.director.budget=6
	game.spawn_cooldown=0
	game.director.tick(0,true)
	check(not game.director.introduced.has(7),"Miniboss fight defers a new enemy introduction")
	game.recovery_until=250
	game.elapsed=249
	game.director.tick(1,false)
	check(not game.director.introduced.has(7),"Post-boss rest also defers introductions")
	game.elapsed=250
	game.director.tick(1,false)
	check(game.director.introduced.has(7),"Deferred introduction resumes after recovery")
	clean()
	game.elapsed=500
	for i in range(5): game.spawn_enemy(4)
	check(get_nodes_in_group("all_enemies").size()==3,"Owl population cannot exceed three")
	for i in range(4): game.spawn_enemy(9)
	var deer_count:=0
	for enemy in get_nodes_in_group("all_enemies"):
		if enemy.kind==9: deer_count+=1
	check(deer_count==2,"Deer population cannot exceed two")
	for i in range(20): game.spawn_enemy(5)
	for i in range(20): game.spawn_enemy(8)
	check(get_nodes_in_group("all_enemies").size()==12,"Combined special enemy population cannot exceed twelve")
	game._start_final_boss()
	await process_frame
	check(get_nodes_in_group("all_enemies").size()==1 and get_nodes_in_group("enemy_clouds").is_empty() and get_nodes_in_group("regular_projectiles").is_empty(),"Final duel clears ordinary actors and hazards")
	print("WAVE TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
