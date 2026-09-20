extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rows: Array=[]
	for fused in [false,true]:
		load("res://scripts/sandbox.gd").saved={}
		var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
		game.rng.seed=73; game.switch_terrain(false,true); game.final_boss_spawned=false; game.settings.minute=5
		game.settings.weapons={"frost":3}
		for id in (["pearl_wave","bubble_aquarium","crab_udon"] if fused else ["shell_wave","bubble","crab_claw"]): game.settings.weapons[id]=3
		game.rebuild_player(); var placed:=0
		for kind in range(15,21): placed+=game.place_random(16,{"type":"normal","index":kind,"refill":false},false)
		game.settings.invincible=true
		for i in range(60): await RenderingServer.frame_post_draw
		var times: Array[float]=[]; var previous:=Time.get_ticks_usec()
		for i in range(360):
			await RenderingServer.frame_post_draw
			var now:=Time.get_ticks_usec(); times.append((now-previous)/1000.0); previous=now
		var total:=0.0
		for value in times: total+=value
		times.sort()
		var row={"fusion":fused,"frames":360,"spawned":placed,"mean_ms":total/times.size(),"p95_ms":times[int(times.size()*0.95)]}
		rows.append(row); print("SEA PROFILE ",JSON.stringify(row))
		game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/beach-fusion-performance.json",FileAccess.WRITE).store_string(JSON.stringify({"renderer":"Compatibility","gpu":"RTX 4060 Laptop","condition":"seed73, 96 sea enemies, stationary invincible, 4 weapons Lv3, 60 warmup frames; base vs fusion workload, not equal-power builds","rows":rows},"\t"))
	var gallery=load("res://scenes/weapon_gallery.tscn").instantiate(); root.add_child(gallery); current_scene=gallery
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/weapon-models-37.png")
	gallery.free(); await process_frame; quit()
