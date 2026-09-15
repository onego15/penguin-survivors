extends SceneTree
var game: Node3D
var failures:=0
func _initialize() -> void:
	Engine.time_scale=8
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	call_deferred("run")
func run() -> void:
	var builds := {"melee":["whip","fan","orbit","nova"],"rear":["rear_fan","rear_bomb","trail","boomerang"],"auto":["seeker","beam","turret","storm"]}
	for start_time in [540]:
		for build in builds:
			seed(73)
			game=load("res://scenes/main.tscn").instantiate()
			root.add_child(game)
			current_scene=game
			game.elapsed=start_time
			game.level=8
			game.experience=100
			game.xp_needed=game.Difficulty.xp_for_level(8)
			var choices:=0
			game.rng.seed=73
			game.next_boss_at=9999
			game.support.next_at=9999
			game.director.introduced={0:true,1:true,2:true,3:true,4:true,5:true,6:true,7:true,8:true,9:true}
			game.director.advance()
			game.armory.levels.frost=3
			for id in builds[build]:
				game.armory.acquire(id)
				game.armory.levels[id]=3
			var max_special:=0
			var max_shots:=0
			var max_clouds:=0
			for i in range(16):
				var enemy=game.spawn_enemy(game.director.choose_kind())
				if enemy!=null:
					enemy.position=Vector3(cos(i*TAU/16),0,sin(i*TAU/16))*11
			while game.elapsed<start_time+22 and not game.game_over:
				if game.choice_open:
					game.choose_weapon(0)
					choices+=1
				var desired := Vector3(cos(game.elapsed*0.22),0,sin(game.elapsed*0.22))*9
				var direction: Vector3=(desired-game.player.position).normalized()
				# Local steering moves away from imminent warning markers and clouds.
				var candidate: Vector3=game.player.position+direction*2
				for enemy in get_nodes_in_group("all_enemies"):
					if enemy.has_method("danger_contains") and enemy.danger_contains(candidate): direction=direction.rotated(Vector3.UP,PI/2)
				for cloud in get_nodes_in_group("enemy_clouds"):
					if cloud.danger_contains(candidate): direction=direction.rotated(Vector3.UP,PI/2)
				for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
				Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
				Input.action_press("move_down" if direction.z>0 else "move_up",absf(direction.z))
				var special:=0
				for enemy in get_nodes_in_group("all_enemies"):
					if enemy.kind>=4: special+=1
				max_special=maxi(max_special,special)
				max_shots=maxi(max_shots,get_nodes_in_group("regular_projectiles").size())
				max_clouds=maxi(max_clouds,get_nodes_in_group("enemy_clouds").size())
				await physics_frame
			print("TACTICS wave=%d build=%s time=%.1f hp=%d kills=%d special=%d shots=%d clouds=%d choices=%d" % [start_time/60+1,build,game.elapsed-start_time,game.player.health,game.kills,max_special,max_shots,max_clouds,choices])
			if max_special>12 or max_shots>32 or max_clouds>6: failures+=1
			for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
			paused=false
			game.queue_free()
			await process_frame
	Engine.time_scale=1
	Engine.physics_ticks_per_second=60
	await create_timer(0.3).timeout
	print("TACTICS AUDIT: %d limit violation(s)" % failures)
	quit(1 if failures else 0)
