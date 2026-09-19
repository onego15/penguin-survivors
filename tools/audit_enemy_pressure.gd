extends SceneTree
var rows: Array=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for revised in [false,true]:
		var game=load("res://scenes/sandbox.tscn" if revised else "res://.godot/enemy-baseline/scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
		game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
		game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false); game.player.training_invincible=false
		for kind in range(15):
			game.clear_enemies(); game.player.position=Vector3.ZERO; game.player.health=10000; game.player.invulnerability=0; game.rng.seed=73
			game.switch_terrain(kind>=10)
			for i in range(3):
				var angle:=i*TAU/3
				game.create_enemy({"type":"normal","index":kind},Vector3(cos(angle),0,sin(angle))*6,420)
			var hits:=0
			for i in range(300):
				var t:=i*0.1
				var goal:=Vector3(cos(t*0.35),0,sin(t*0.35))*4
				var move: Vector3=(goal-game.player.position).limit_length(game.player.SPEED*0.1)
				game.player.position=game.obstacles.move_actor(game.player,game.player.position+move,0.45) if game.obstacles!=null else game.player.position+move
				game.player.invulnerability=maxf(0,game.player.invulnerability-0.1)
				for actor in game.actors.get_children():
					if actor==game.player or not actor.has_method("_physics_process") or actor.is_queued_for_deletion(): continue
					var hp: int=game.player.health
					actor._physics_process(0.1)
					if hp>game.player.health: hits+=1
				if i%10==0: await process_frame
			rows.append({"mode":"species","updated":revised,"kind":kind,"hits":hits,"damage":10000-game.player.health})
		game.free(); await process_frame
	for castle in [false,true]:
		for tier in ["easy","normal","expert"]:
			for phase in [1,2]:
				var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
				game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.settings.weapons={}; game.settings.difficulty=tier; game.difficulty_id=tier
				game.rebuild_player(); game.player.set_physics_process(false); game.player.training_invincible=false; game.player.health=10000
				game.switch_terrain(castle); game.final_boss_spawned=true; game.rng.seed=73
				var boss=game.create_enemy({"type":"final","index":1 if castle else 0,"phase":phase},Vector3(0,0,-7),0)
				game.final_director.begin_phase(phase)
				var attacks: Array=[]; var previous:=""; var was_warning:=false; var blocked:=0.0; var recovery:=0.0
				for i in range(1200):
					var t:=i*0.1; game.elapsed=600+t
					var goal:=Vector3(cos(t*0.24),0,sin(t*0.24))*12
					if castle and boss.wall_busy: goal=Vector3(game.player.position.x,0,boss.ice_walls.gap)
					var move: Vector3=(goal-game.player.position).limit_length(game.player.SPEED*0.1)
					if castle:
						move=game.obstacles.steer(game.player,goal,0.45)*game.player.SPEED*0.1
						game.player.position=game.obstacles.move_actor(game.player,game.player.position+move,0.45); game.obstacles.tick(0.1)
					else: game.player.position+=move
					game.player.invulnerability=maxf(0,game.player.invulnerability-0.1)
					if game.final_director.clock>=game.final_director.next_minions and game.final_director.busy(): blocked+=0.1
					game.final_director.tick(0.1); game.support.tick(0.1)
					for actor in game.actors.get_children():
						if actor!=game.player and actor.has_method("_physics_process") and not actor.is_queued_for_deletion(): actor._physics_process(0.1)
					var attack: String=str(boss.get("attack_kind"))
					var warning_now: bool=boss.warning_left>0
					if warning_now and (not was_warning or attack!=previous): attacks.append({"at":snappedf(t,0.1),"attack":attack})
					previous=attack; was_warning=warning_now
					if boss.recovery_left>0 and boss.warning_left<=0 and boss.dash_left<=0 and not (castle and boss.wall_busy): recovery+=0.1
					if i%10==0: await process_frame
				rows.append({"mode":"cadence","castle":castle,"tier":tier,"phase":phase,"attacks":attacks,"reinforcement_delay":snappedf(blocked,0.1),"recovery":snappedf(recovery,0.1),"minions":game.final_director.total_spawned,"hp_left":game.player.health})
				game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/enemy-pressure-2026-09-20.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t")); quit()
