extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for castle in [false,true]:
		for weapon in ["orbit","whip","starfall","nova"]:
			var game=load("res://scenes/sandbox.tscn").instantiate()
			root.add_child(game); current_scene=game
			game.set_physics_process(false); game.player.set_physics_process(false)
			game.switch_terrain(castle)
			game.rng.seed=17
			game.settings.weapons={"frost":3,weapon:3}; game.rebuild_player()
			game.player.set_physics_process(false)
			game.settings.invincible=false
			game.player.training_invincible=false
			game.player.position=Vector3(0,0,0)
			var spawned:=0
			for frame in range(3600):
				var t:=frame/60.0
				if frame%30==0:
					var angle:=float(spawned)*2.39996
					var point:=Vector3(cos(angle),0,sin(angle))*12
					if game.valid_position(point,0.6):
						var enemy=game.create_enemy({"type":"normal","index":0 if spawned%2==0 else 5},point,360)
						enemy.set_physics_process(false); spawned+=1
				game.player.body.rotation.y=t*1.0
				game.player.invulnerability=maxf(0,game.player.invulnerability-1.0/60)
				game._physics_process(1.0/60)
				for enemy in get_nodes_in_group("all_enemies"): enemy._physics_process(1.0/60)
				for attack in game.actors.get_children():
					if attack!=game.player and not attack.is_in_group("all_enemies") and not attack.is_queued_for_deletion() and attack.has_method("_physics_process"):
						attack.set_physics_process(false); attack._physics_process(1.0/60)
				game.player.health=100 # Sustained measurement: restore HP after every step.
				# Flush deferred deletions, with automatic world processing disabled.
				if frame%60==0:
					for node in game.actors.get_children(): node.set_physics_process(false)
					await process_frame
			print("BALANCE stage=",("castle" if castle else "snow")," build=",weapon," time=",snappedf(game.training_time,0.1)," kills=",game.kills," damage_taken=",game.received," damage_dealt=",game.dealt," spawned=",spawned)
			paused=false; game.free(); await process_frame
	quit()
