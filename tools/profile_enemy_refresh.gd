extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var results: Array=[]
	for revised in [false,true,true,false]:
		var game=load("res://scenes/sandbox.tscn" if revised else "res://.godot/enemy-baseline/scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
		game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.player.set_physics_process(false)
		game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false)
		var units: Array=[]
		for i in range(100):
			var e=game.create_enemy({"type":"normal","index":i%15},Vector3((i%10-4.5)*1.6,0,(floori(i/10.0)-4.5)*1.6),540)
			units.append(e)
		for i in range(90): await RenderingServer.frame_post_draw
		var times: Array[float]=[]; var calls:=0
		for frame in range(180):
			var start:=Time.get_ticks_usec()
			for e in units:
				e.age=frame/60.0; e._animate(2)
				if revised: preload("res://scripts/enemy_presentation.gd").motion(e,Vector3.BACK*2)
			await RenderingServer.frame_post_draw
			times.append((Time.get_ticks_usec()-start)/1000.0)
			calls=maxi(calls,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		var sum:=0.0
		for value in times: sum+=value
		times.sort()
		results.append({"updated":revised,"mean_ms":sum/times.size(),"p95_ms":times[int(times.size()*0.95)],"draw_calls":calls})
		game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/enemy-render-2026-09-20.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	for row in results: print(JSON.stringify(row))
	quit()
