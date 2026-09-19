extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for scenario in ["snowfield","castle","defeat"]:
		var stage: String="castle" if scenario=="defeat" else scenario
		var view=preload("res://scripts/victory_screen.gd").new()
		var weapons: Dictionary={"frost":3,"rainbow_heart":3,"udon":2,"orbit":3,"ember":2}
		var ledger=preload("res://scripts/contributions.gd").new()
		ledger.add("support:3","knockback",18)
		ledger.add("support:0","healing",20)
		ledger.add("weapon:heart","damage",140)
		var definition: Dictionary=preload("res://scripts/stage_catalog.gd").STAGES[stage]
		view.results={"won":scenario!="defeat","stage_id":stage,"stage_name":definition.name,"boss_name":definition.boss_name,"character_id":"pink" if stage=="castle" else "classic","elapsed":648,"kills":538,"level":19,"weapons":weapons,"contributions":ledger.snapshot(weapons)}
		root.add_child(view)
		view.set_process(false); view._process(0.3)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/result-"+scenario+".png")
		view.free()
	quit()

