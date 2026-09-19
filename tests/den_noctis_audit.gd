extends SceneTree
var rows: Array=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for upgraded in [false,true]:
		var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
		game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
		game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false)
		game.player.training_invincible=false; game.player.health=1000
		var den=game.support.spawn_friend(3,Vector3(-2,0,0)); den.recruit()
		for i in range(24):
			var e=game.create_enemy({"type":"normal","index":0},Vector3(cos(i*TAU/24),0,sin(i*TAU/24))*8,180); e.health=1000; e.max_health=1000
		var next:=0.6; var legacy_pushes:=0; var legacy_hits:=0
		for i in range(600):
			var t:=i*0.05
			game.player.position=Vector3(sin(t*0.35),0,1-cos(t*0.35))*7
			game.player.invulnerability=maxf(0,game.player.invulnerability-0.05)
			game.player.body.rotation.y=atan2(cos(t*0.35),sin(t*0.35))
			if upgraded: den.tick(0.05)
			else:
				var facing:=Vector3(cos(t*0.35),0,sin(t*0.35))
				den.position=den.position.lerp(game.player.position-facing*2.6+facing.rotated(Vector3.UP,PI/2)*1.7,1-exp(-0.3))
				if t+0.05>=next and next<30:
					next+=6
					for e in get_nodes_in_group("enemies"):
						if e.position.distance_to(den.position)<=5+e.hit_radius:
							legacy_hits+=1; e.take_damage(2)
							if e.apply_control("knockback",3,(e.position-den.position).normalized()): legacy_pushes+=1
			for e in get_nodes_in_group("all_enemies"): e._physics_process(0.05)
			if i%10==0: await process_frame
		var stats: Dictionary=game.contributions.entries.get("support:3",{})
		rows.append({"test":"den","updated":upgraded,"hits":int(stats.get("damage",0))/2 if upgraded else legacy_hits,"pushes":stats.get("knockback",0) if upgraded else legacy_pushes,"damage_received":1000-game.player.health})
		game.free(); await process_frame
	var builds={"melee":{"whip":3,"nova":3,"gust":3},"rear":{"rear_fan":3,"rear_bomb":3,"trail":3},"aim":{"heart":3,"beam":3,"boomerang":3}}
	for character in ["classic","pink"]:
		for build in builds:
			var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
			game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
			game.settings.character=character; game.settings.weapons=builds[build]; game.rebuild_player(); game.player.set_physics_process(false); game.player.training_invincible=false
			game.switch_terrain(true); game.rng.seed=73
			var boss=game.create_enemy({"type":"final","index":1,"phase":2},Vector3(0,0,-6),0)
			game.final_boss_spawned=true; game.final_director.begin_phase(2)
			var elapsed:=0.0; var walls:=0; var was_wall:=false
			for i in range(1200):
				if game.player.health<=0 or not is_instance_valid(boss) or boss.dead: break
				elapsed+=0.05; game.elapsed=600+elapsed
				var dest:=Vector3(cos(elapsed*0.24),0,sin(elapsed*0.24))*12
				if boss.wall_busy: dest=Vector3(game.player.position.x,0,boss.ice_walls.gap)
				var move: Vector3=game.obstacles.steer(game.player,dest,0.45)*game.player.SPEED*0.05
				if move.length()>0.001: game.player.body.rotation.y=lerp_angle(game.player.body.rotation.y,atan2(move.x,move.z),1-exp(-0.05*14))
				game.player.position=game.obstacles.move_actor(game.player,game.player.position+move,0.45)
				game.player.invulnerability=maxf(0,game.player.invulnerability-0.05)
				game.obstacles.tick(0.05); game.armory.tick(0.05); game.final_director.tick(0.05); game.support.tick(0.05)
				for actor in game.actors.get_children():
					if actor!=game.player and actor.has_method("_physics_process") and not actor.is_queued_for_deletion(): actor._physics_process(0.05)
				if boss.wall_busy and not was_wall: walls+=1
				was_wall=boss.wall_busy
				if i%10==0: await process_frame
			rows.append({"test":"noctis","character":character,"build":build,"seconds":snappedf(elapsed,0.1),"damage_received":game.received,"boss_hp":boss.health if is_instance_valid(boss) else 0,"walls":walls,"minions":game.final_director.total_spawned,"kills":game.kills})
			game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/den-noctis-2026-09-19.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
	for row in rows: print(JSON.stringify(row))
	quit()

