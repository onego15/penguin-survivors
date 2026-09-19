extends SceneTree
const BUILDS={"melee":{"whip":3,"nova":3,"gust":3},"rear":{"rear_fan":3,"rear_bomb":3,"trail":3},"aim":{"heart":3,"beam":3,"boomerang":3}}
var results: Array=[]
var close_mid := "--close-mid" in OS.get_cmdline_user_args()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for revised in [false,true]:
		var path := "res://scenes/sandbox.tscn" if revised else "res://.godot/enemy-baseline/scenes/sandbox.tscn"
		for character in ["classic","pink"]:
			for build in BUILDS:
				for seed_value in [17,73,211]:
					var game=load(path).instantiate(); root.add_child(game); current_scene=game
					game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
					game.settings.character=character; game.settings.weapons=BUILDS[build]; game.rebuild_player(); game.player.set_physics_process(false)
					game.player.training_invincible=false
					for castle in [false,true]:
						game.switch_terrain(castle)
						for wave in ([] if close_mid else [3,5,8,10]):
							await trial(game,revised,character,build,seed_value,castle,"wave",wave,20.0)
						for mid in range(4): await trial(game,revised,character,build,seed_value,castle,"mid",mid,30.0)
						for phase in ([] if close_mid else [1,2]): await trial(game,revised,character,build,seed_value,castle,"final",phase,60.0)
					game.free(); await process_frame
					print("AUDIT completed ",revised," ",character," ",build," ",seed_value)
	FileAccess.open("res://docs/benchmarks/enemy-mid-close-2026-09-20.json" if close_mid else "res://docs/benchmarks/enemy-refresh-2026-09-20.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	quit()
func trial(game: Node3D, revised: bool, character: String, build: String, seed_value: int, castle: bool, mode: String, index: int, duration: float) -> void:
	game.clear_enemies(); game.game_over=false; game.run_state="combat"; game.player.health=100; game.player.invulnerability=0; game.player.position=Vector3.ZERO
	game.kills=0; game.dealt=0; game.received=0; game.rng.seed=seed_value; game.rebuild_player(); game.player.set_physics_process(false); game.player.training_invincible=false
	game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	if castle: game.obstacles.open_all()
	var pair: Array=[]; var boss: Node3D; var strength: float=(index-1)*60 if mode=="wave" else 0
	if mode=="wave":
		var waves: Array=preload("res://scripts/stage_catalog.gd").CASTLE_WAVES if castle else preload("res://scripts/wave_director.gd").WAVES
		pair=waves[index-1].pairs[seed_value%waves[index-1].pairs.size()]
	else:
		boss=game.create_enemy({"type":mode,"index":(index+4 if castle else index) if mode=="mid" else (1 if castle else 0),"phase":index},Vector3(0,0,-8),0)
	var elapsed:=0.0; var budget:=0.0; var turtle_peak:=0; var starts: Array=[]; var previous_attack:=""; var rest_seconds:=0.0
	for step in range(int(duration/0.1)):
		if game.player.health<=0 or (mode!="wave" and (not is_instance_valid(boss) or boss.dead)): break
		elapsed+=0.1
		var goal:=Vector3(cos(elapsed*0.28),0,sin(elapsed*0.28))*(4 if close_mid else 10)
		if is_instance_valid(boss) and boss.get("wall_busy")==true: goal=Vector3(game.player.position.x,0,boss.ice_walls.gap)
		var move: Vector3=(goal-game.player.position).normalized()*game.player.SPEED*0.1
		if castle:
			move=game.obstacles.steer(game.player,goal,0.45)*game.player.SPEED*0.1
			game.player.position=game.obstacles.move_actor(game.player,game.player.position+move,0.45)
			game.obstacles.tick(0.1)
		else: game.player.position+=move
		game.player.body.rotation.y=atan2(move.x,move.z); game.player.invulnerability=maxf(0,game.player.invulnerability-0.1)
		if mode=="wave":
			budget+=game.Difficulty.profile(strength).rate*0.1
			if budget>=2 and get_nodes_in_group("enemies").size()<40:
				var kind: int=pair[step%2] if step%4>=2 else step%2
				var angle: float=game.rng.randf()*TAU
				var at: Vector3=game.player.position+Vector3(cos(angle),0,sin(angle))*12
				at.x=clampf(at.x,-21,21); at.z=clampf(at.z,-21,21)
				if not castle or game.obstacles.clear(at,0.85): game.create_enemy({"type":"normal","index":kind},at,strength); budget-=game.Enemy.cost(kind)
		game.armory.tick(0.1)
		for actor in game.actors.get_children():
			if actor!=game.player and actor.has_method("_physics_process") and not actor.is_queued_for_deletion(): actor._physics_process(0.1)
		var turtles:=0
		for actor in get_nodes_in_group("all_enemies"):
			if actor.kind==3 and not actor.dead: turtles+=1
		turtle_peak=maxi(turtle_peak,turtles)
		if is_instance_valid(boss):
			var attack: String=str(boss.get("attack_kind")) if mode=="final" else str(boss.get("warning_left"))
			if attack!="" and attack!="<null>" and attack!=previous_attack and mode=="final": starts.append({"time":snappedf(elapsed,0.1),"attack":attack})
			previous_attack=attack
			if float(boss.get("recovery_left") if boss.get("recovery_left")!=null else 0)>0: rest_seconds+=0.1
		if step%10==0: await process_frame
	results.append({"updated":revised,"character":character,"build":build,"seed":seed_value,"castle":castle,"mode":mode,"index":index,"seconds":snappedf(elapsed,0.1),"kills":game.kills,"damage":game.dealt,"received":game.received,"turtle_peak":turtle_peak,"boss_hp":boss.health if is_instance_valid(boss) else 0,"attacks":starts,"recovery_seconds":snappedf(rest_seconds,0.1)})
	game.clear_enemies(); await process_frame
