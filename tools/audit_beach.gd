extends SceneTree
var records: Array=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for character in ["classic","pink"]:
		for build in ["front","rear","auto"]:
			preload("res://scripts/character_roster.gd").selected_id=character
			var game=load("res://scenes/main.tscn").instantiate(); game.stage_id="beach"; root.add_child(game); current_scene=game
			game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
			game.player.character_id=character; game.rng.seed=73; game.elapsed=600; game._tick_director(0); await process_frame
			game._finish_presentation(); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
			game.active_boss.initialize_training_phase(true); game.final_director.begin_phase(2)
			game.active_boss.health=100000; game.active_boss.max_health=100000
			game.armory.free(); game.armory=preload("res://scripts/weapon_system.gd").new(); game.armory.game=game; game.add_child(game.armory)
			var loadout: Array={"front":["shell_wave","crab_claw","fan"],"rear":["rear_bomb","bubble","orbit"],"auto":["beam","heart","boomerang"]}[build]
			for id in loadout: game.armory.acquire(id); game.armory.levels[id]=3
			game.experience=-100000; var received:=0; var damage:=0
			game.player.position=Vector3(0,0,3); game.active_boss.position=Vector3(0,0,-4)
			for frame in range(1800):
				var dt:=1.0/30
				var elapsed:=frame*dt
				var destination:=Vector3(cos(elapsed*0.25),0,sin(elapsed*0.25))*9
				var movement: Vector3=(destination-game.player.position).normalized()*game.player.SPEED*game.player.statuses.move_rate()*dt
				game.player.position+=movement
				game.player.body.rotation.y=atan2(movement.x,movement.z)
				game.player.invulnerability=maxf(0,game.player.invulnerability-dt); game.player.statuses.tick(dt)
				game.beach.tick(dt); game.final_director.tick(dt); game.armory.tick(dt)
				var before: int=game.player.health; var boss_hp: int=game.active_boss.health
				for actor in game.actors.get_children():
					if actor==game.player or actor.is_queued_for_deletion(): continue
					if actor.has_method("_physics_process"): actor._physics_process(dt)
				received+=before-game.player.health; damage+=boss_hp-game.active_boss.health
				game.player.health=100
				await process_frame
			records.append({"character":character,"build":build,"seconds":60,"damage_received":received,"boss_damage":damage,"kills":game.kills,"minions_spawned":game.final_director.total_spawned})
			print(JSON.stringify(records[-1])); game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/beach-combat.json",FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	quit()
