extends SceneTree
## Fixed late-game fixtures and automatic movement, not a full human playthrough.
var records: Array=[]
func _initialize() -> void:
	Engine.time_scale=12; Engine.physics_ticks_per_second=720; Engine.max_physics_steps_per_frame=64
	call_deferred("run")
func run() -> void:
	for stage in ["snowfield","castle"]:
		for character in ["classic","pink"]:
			for strategy in ["escape","cleanup"]:
				preload("res://scripts/character_roster.gd").selected_id=character
				var game=load("res://scenes/main.tscn").instantiate(); game.stage_id=stage; game.difficulty_id="normal"
				root.add_child(game); current_scene=game; game.rng.seed=73; seed(73)
				game.elapsed=569; game.level=10; game.xp_needed=game.Tiers.xp(10,"normal"); game.next_boss_at=9999; game.support.next_at=9999
				for id in ["beam","nova","heart","frost"]:
					while game.armory.levels.get(id,0)<3: game.armory.acquire(id)
				var xp: Array[int]=[0]
				for i in range(24):
					var enemy=game.spawn_enemy(0); enemy.position=Vector3(cos(i*TAU/24),0,sin(i*TAU/24))*10
					enemy.rewarded.connect(func(value): xp[0]+=value)
				var mid=game.spawn_enemy(0,true); game.active_boss=mid; mid.health=mid.max_health/2
				game.elapsed=570; game._tick_director(0)
				var choices:=0; var summary: Dictionary={}; var boss_hp:=0; var start:=Time.get_ticks_msec()
				while not game.game_over and not game.victory and game.elapsed<690 and Time.get_ticks_msec()-start<60000:
					if game.choice_open: game.choose_weapon(0); choices+=1
					if game.pending_recipe!="": game.choose_evolution(game.Catalog.Evolution.RECIPES[game.pending_recipe].outputs[0])
					if game.final_boss_spawned and summary.is_empty(): summary=game.sweep.snapshot(); boss_hp=game.active_boss.max_health
					var destination:=Vector3(cos(game.elapsed*0.25),0,sin(game.elapsed*0.25))*18
					if strategy=="cleanup" and not game.final_boss_spawned:
						var target=game.armory.nearest(game.player.position,100)
						if is_instance_valid(target): destination=target.position+(game.player.position-target.position).normalized()*3
					if game.final_boss_spawned and is_instance_valid(game.active_boss): destination=game.active_boss.position+Vector3(cos(game.elapsed*0.7),0,sin(game.elapsed*0.7))*7
					var direction: Vector3=(destination-game.player.position).normalized()
					if game.obstacles!=null: direction=game.obstacles.steer(game.player,destination,0.45)
					for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
					Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x)); Input.action_press("move_down" if direction.z>0 else "move_up",absf(direction.z))
					await process_frame
				var record={"stage":stage,"character":character,"strategy":strategy,"cleanup":summary,"normal_xp":xp[0],"choices":choices,"kills":game.kills,"seconds":game.elapsed,"won":game.victory,"died":game.game_over,"boss_hp":boss_hp,"boss_seconds":game.elapsed-600 if game.final_boss_spawned else 0}
				records.append(record); print(JSON.stringify(record))
				for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
				paused=false; game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/cleanup.json",FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	quit()
