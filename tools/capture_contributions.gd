extends SceneTree
## Layout fixtures; these numbers are not a play/balance benchmark.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for won in [true,false]:
		var game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
		game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
		var index:=0
		for id in game.Catalog.all_ids():
			game.armory.levels[id]=game.Catalog.max_rank(id)
			game.contributions.add("weapon:"+id,"damage",(31-index)*137)
			game.contributions.add("weapon:"+id,"kills",31-index)
			index+=1
		game.armory.levels.erase("heart")
		game.contributions.add("weapon:popsicle","freeze",25); game.contributions.add("weapon:popsicle","freeze_seconds",27.3)
		game.contributions.add("weapon:gust","knockback",87)
		game.contributions.add("support:0","healing",20); game.contributions.add("support:1","prevented",47)
		game.contributions.add("support:2","damage",95); game.contributions.add("support:3","knockback",14)
		game.contributions.add("ultimate:blizzard","damage",2800)
		game.elapsed=647 if won else 493; game.level=22; game.kills=496
		game.player.health=100 if won else 0; game.final_boss_defeated=won
		game._physics_process(0)
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/contributions-"+("victory" if won else "defeat")+".png")
		if not won:
			var report=game.defeat_results.report
			report.order.select(2); report.refresh()
			await process_frame; await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/screenshots/contributions-control.png")
		game.free(); await process_frame
	quit()
