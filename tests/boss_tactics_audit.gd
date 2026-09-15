extends SceneTree
var game: Node3D
var failures:=0
func _initialize() -> void:
	Engine.time_scale=8
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	call_deferred("run")
func run() -> void:
	var builds:={"melee":["whip","fan","orbit","nova"],"rear":["rear_fan","rear_bomb","trail","boomerang"],"auto":["seeker","beam","turret","storm"]}
	for phase in [1,2]:
		for build in builds:
			game=load("res://scenes/main.tscn").instantiate()
			root.add_child(game)
			current_scene=game
			game.rng.seed=73
			if "--ultimate" in OS.get_cmdline_user_args(): game.ultimate.reward(200)
			game.elapsed=600
			game.level=12
			game.xp_needed=game.Difficulty.xp_for_level(12)
			game.armory.levels.frost=5
			for id in builds[build]:
				game.armory.acquire(id)
				game.armory.levels[id]=5
			game._start_final_boss()
			game._finish_presentation()
			var boss=game.active_boss
			if phase==2:
				boss.take_damage(701)
				game._finish_presentation()
			var max_minions:=0
			var blocked_streak:=0.0
			var max_blocked:=0.0
			var last_time:=600.0
			while game.elapsed<660 and not game.game_over and not game.victory:
				if game.choice_open: game.choose_weapon(0)
				if not is_instance_valid(boss):
					await process_frame
					continue
				if "--ultimate" in OS.get_cmdline_user_args(): game.ultimate.activate()
				var p: Vector3=game.player.position
				var offset: Vector3=p-boss.position
				var radial:=offset.normalized()
				var desired: Vector3=boss.position+radial.rotated(Vector3.UP,0.4)*(3.2 if build=="melee" else 7.0)
				if is_instance_valid(game.support.active) and game.support.active.state=="waiting": desired=game.support.active.position
				var preferred: Vector3=(desired-p).normalized()
				var best:=Vector3.ZERO
				var best_score:=-INF
				var open_paths:=0
				for i in range(48):
					var direction:=Vector3(cos(i*TAU/48),0,sin(i*TAU/48))
					var near: Vector3=p+direction*2
					if absf(near.x)>22.5 or absf(near.z)>22.5: continue
					var score:=direction.dot(preferred)
					var clear:=true
					for enemy in get_nodes_in_group("final_minions"):
						if Geometry3D.get_closest_point_to_segment(enemy.position,p,near).distance_to(enemy.position)<1.3:
							clear=false
							score-=8
					if clear: open_paths+=1
					if boss.warning_left>0 and boss.attack_kind=="quake": score+=near.distance_to(boss.quake_center)*3
					elif boss.danger_contains(near): score-=12
					if near.distance_to(boss.position)<2.4: score-=8
					for bolt in get_nodes_in_group("hostile_projectiles"):
						var future: Vector3=bolt.position+bolt.direction*bolt.speed*0.25
						if near.distance_to(future-Vector3.UP)<1.2: score-=5
					if score>best_score: best_score=score; best=direction
				var step: float=game.elapsed-last_time
				last_time=game.elapsed
				blocked_streak=blocked_streak+step if open_paths==0 else 0.0
				max_blocked=maxf(max_blocked,blocked_streak)
				max_minions=maxi(max_minions,get_nodes_in_group("final_minions").size())
				for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
				Input.action_press("move_right" if best.x>0 else "move_left",absf(best.x))
				Input.action_press("move_down" if best.z>0 else "move_up",absf(best.z))
				await process_frame
			print("BOSS AUDIT phase=%d build=%s time=%.1f hp=%d boss_hp=%d kills=%d spawned=%d max_minions=%d longest_all_paths_blocked=%.2fs uses=%d" % [phase,build,game.elapsed-600,game.player.health,boss.health if is_instance_valid(boss) else 0,game.kills,game.final_director.total_spawned,max_minions,max_blocked,game.ultimate.uses])
			if max_minions>8 or max_blocked>3: failures+=1
			for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
			paused=false
			game.queue_free()
			await process_frame
	Engine.time_scale=1
	Engine.physics_ticks_per_second=60
	await create_timer(0.3).timeout
	print("BOSS TACTICS AUDIT: %d limit/path violation(s)" % failures)
	quit(1 if failures else 0)
