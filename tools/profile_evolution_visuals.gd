extends SceneTree
## Baseline scripts supplied with git show HEAD:scripts/fusion_attack.gd.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var results: Array=[]
	for revised in [false,true]:
		var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
		game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
		game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false)
		for i in range(24): game.create_enemy({"type":"normal","index":i%4},Vector3(cos(i)*8,0,sin(i)*8),0)
		var effects: Array=[]
		for i in range(12):
			var effect=load("res://scripts/fusion_attack.gd" if revised else "res://.godot/fusion_before.gd").new()
			effect.mode=["rainbow_heart","thunder_dome","pearl_chime","blizzard_fan"][i%4]
			effect.player=game.player; effect.stats=game.Catalog.stats(effect.mode,5); effect.direction=Vector3(cos(i),0,sin(i)); effect.position=effect.direction*3
			game.actors.add_child(effect); effects.append(effect)
		var before=load("res://.godot/evolution_before.gd")
		for id in game.Catalog.Evolution.ITEMS:
			for rank in range(2 if game.Catalog.Evolution.is_single(id) else 1,game.Catalog.max_rank(id)+1):
				assert(game.Catalog.Evolution.stats(id,rank)==before.stats(id,rank),"unchanged evolution stats")
		for i in range(12): await RenderingServer.frame_post_draw
		var start:=Time.get_ticks_usec(); var draws:=0
		for frame in range(120):
			for effect in effects:
				effect.age=fposmod(frame/60.0,1.5); effect.flash_left=0.2; effect.pulse_count=5 if effect.age>=1.2 else 1
				effect.update_visuals(0)
			await RenderingServer.frame_post_draw
			draws=maxi(draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		results.append({"updated":revised,"frame_ms":(Time.get_ticks_usec()-start)/120000.0,"draw_calls":draws,"effects":12,"enemies":24})
		if revised: root.get_texture().get_image().save_png("res://docs/screenshots/evolution-rich-stress.png")
		game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/evolution-visuals-2026-09-19.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	for row in results: print(JSON.stringify(row))
	quit()
