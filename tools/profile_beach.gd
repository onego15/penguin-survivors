extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.switch_terrain(false,true); game.final_boss_spawned=false; game.settings.minute=5
	game.settings.weapons={"shell_wave":3,"bubble":3,"crab_claw":3,"frost":3}; game.rebuild_player()
	var placed:=0
	for kind in range(15,21): placed+=game.place_random(16,{"type":"normal","index":kind,"refill":false},false)
	game.settings.invincible=true
	for i in range(60): await RenderingServer.frame_post_draw
	var times: Array[float]=[]; var previous:=Time.get_ticks_usec()
	for i in range(180):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec(); times.append((now-previous)/1000.0); previous=now
	var total:=0.0
	for value in times: total+=value
	times.sort()
	var result={"renderer":"Compatibility","gpu":"RTX 4060 Laptop","spawned":placed,"frames":180,"mean_ms":total/times.size(),"p95_ms":times[int(times.size()*0.95)],"mode":"sandbox, stationary invincible, 4 weapons Lv3, sea AI active"}
	print(JSON.stringify(result)); FileAccess.open("res://docs/benchmarks/beach-performance.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	root.get_texture().get_image().save_png("res://docs/screenshots/beach-stress.png")
	game.free(); await process_frame; quit()
