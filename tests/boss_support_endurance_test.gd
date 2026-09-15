extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.rng.seed=81
	game.elapsed=600
	game._start_final_boss()
	game._finish_presentation()
	game.active_boss.set_physics_process(false)
	game.active_boss.take_damage(701)
	game._finish_presentation()
	var visits: Array[float]=[]
	var previous:=0
	var max_minions:=0
	for step in range(900):
		game.elapsed+=0.1
		game.support.tick(0.1)
		game.final_director.tick(0.1)
		if game.final_director.support_count>previous:
			previous=game.final_director.support_count
			visits.append(game.final_director.clock)
		if is_instance_valid(game.support.active) and game.support.active.state=="waiting":
			game.player.position=game.support.active.position
			game._update_camera()
		for minion in get_nodes_in_group("final_minions"): minion.set_physics_process(false)
		max_minions=maxi(max_minions,get_nodes_in_group("final_minions").size())
	var ok:=visits.size()==2 and visits[0]>=8 and visits[1]-visits[0]>=33 and max_minions==6
	print("SUPPORT ENDURANCE: visits=",visits," max_minions=",max_minions," passed=",ok)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(0 if ok else 1)
