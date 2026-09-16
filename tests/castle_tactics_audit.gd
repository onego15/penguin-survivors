extends SceneTree
var game: Node3D
var failures:=0
func _initialize() -> void:
	Engine.time_scale=8
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	call_deferred("run")
func run() -> void:
	preload("res://scripts/stage_catalog.gd").selected_id="castle"
	var builds:={"melee":["whip","fan","orbit","nova"],"rear":["rear_fan","rear_bomb","trail","boomerang"],"auto":["seeker","beam","turret","storm"]}
	for character in ["classic","pink"]:
		preload("res://scripts/character_roster.gd").selected_id=character
		for section in ["road","boss"]:
			for build in builds:
				game=load("res://scenes/main.tscn").instantiate()
				root.add_child(game)
				current_scene=game
				game.rng.seed=73
				game.elapsed=420 if section=="road" else 600
				var start_time: float=game.elapsed
				game.next_boss_at=9999
				game.obstacles.clock=game.elapsed
				game.obstacles.next_cycle=game.elapsed
				for kind in [0,1,2,3,4,5,10,11,12]: game.director.introduced[kind]=true
				game.director.pending.clear()
				game.level=12
				game.xp_needed=game.Difficulty.xp_for_level(12)
				for id in game.armory.levels: game.armory.levels[id]=5
				for id in builds[build]:
					game.armory.acquire(id)
					game.armory.levels[id]=5
				if section=="boss":
					game._start_final_boss()
					game._finish_presentation()
					game.active_boss.take_damage(801)
					game._finish_presentation()
				var blocked:=0.0
				var longest:=0.0
				var peak:=0
				var violations:=0
				var last_time: float=game.elapsed
				while game.elapsed<start_time+60 and not game.game_over and not game.victory:
					if game.choice_open: game.choose_weapon(0)
					var p: Vector3=game.player.position
					var destination:=Vector3(cos(game.elapsed*0.18),0,sin(game.elapsed*0.18))*14
					if section=="boss" and is_instance_valid(game.active_boss):
						var boss=game.active_boss
						destination=boss.position+(p-boss.position).normalized().rotated(Vector3.UP,0.5)*(3.5 if build=="melee" else 7)
					if is_instance_valid(game.support.active) and game.support.active.state=="waiting": destination=game.support.active.position
					var preferred: Vector3=game.obstacles.steer(game.player,destination,0.45)
					var best:=Vector3.ZERO
					var best_score:=-INF
					var open_paths:=0
					for i in range(32):
						var direction:=Vector3(cos(i*TAU/32),0,sin(i*TAU/32))
						var near:=p+direction*1.4
						if not game.obstacles.clear(near,0.45) or game.obstacles.sweep(p,near,0.45).t<1: continue
						open_paths+=1
						var score:=direction.dot(preferred)*2
						for enemy in get_nodes_in_group("all_enemies"):
							if enemy.dead: continue
							if near.distance_to(enemy.position)<enemy.hit_radius+0.9: score-=8
							if enemy.has_method("danger_contains") and enemy.danger_contains(near): score-=12
						for bomb in get_nodes_in_group("castle_bombs"):
							if bomb.danger_contains(near): score-=12
						for bolt in get_nodes_in_group("hostile_projectiles"):
							if near.distance_to(bolt.position-Vector3.UP+bolt.direction*bolt.speed*0.2)<1: score-=6
						if score>best_score: best_score=score; best=direction
					var step: float=game.elapsed-last_time
					last_time=game.elapsed
					blocked=blocked+step if open_paths==0 else 0.0
					longest=maxf(longest,blocked)
					peak=maxi(peak,get_nodes_in_group("final_minions").size())
					if not game.obstacles.clear(p,0.44): violations+=1
					for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
					Input.action_press("move_right" if best.x>0 else "move_left",absf(best.x))
					Input.action_press("move_down" if best.z>0 else "move_up",absf(best.z))
					await process_frame
				print("CASTLE AUDIT character=%s section=%s build=%s time=%.1f hp=%d kills=%d minions=%d peak=%d support=%d blocked=%.2f wall_violations=%d"%[character,section,build,game.elapsed-start_time,game.player.health,game.kills,game.final_director.total_spawned,peak,game.final_director.support_count,longest,violations])
				if violations>0 or peak>8 or longest>3: failures+=1
				for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
				paused=false
				game.queue_free()
				await process_frame
	Engine.time_scale=1
	print("CASTLE AUDIT failures=",failures)
	quit(1 if failures else 0)
