extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=540
	game.rng.seed=12
	game.director.advance()
	game._update_hud()
	var revised:=OS.get_cmdline_user_args().has("--new-weapons")
	var effects: Array[Node3D]=[]
	for i in range(48):
		var enemy=game.spawn_enemy(0)
		if enemy!=null:
			enemy.position=Vector3(cos(i*2.4),0,sin(i*2.4))*(4+i%10)
			enemy.set_physics_process(false)
	var deer=game.spawn_enemy(9)
	deer.set_physics_process(false)
	deer.position=Vector3(-5,0,-5)
	deer.cooldown=0
	deer._physics_process(0)
	for i in range(40):
		var effect=load("res://scripts/weapon_detail.gd" if revised and i%6!=3 else "res://scripts/weapon_flourish.gd").new()
		effect.mode=["lance","fireball","lightning","whip","firework","boomerang"][i%6] if revised else ["trail","trail","storm","whip","nova"][i%5]
		effect.position=Vector3(cos(i*2.4),0,sin(i*2.4))*(2+i%8)
		game.actors.add_child(effect)
		effects.append(effect)
	for i in range(10): await RenderingServer.frame_post_draw
	var start:=Time.get_ticks_usec()
	var maximum_draws:=0
	for frame in range(120):
		for i in range(effects.size()): effects[i].animate(fposmod(frame/60.0+i*0.2,3),3)
		await RenderingServer.frame_post_draw
		maximum_draws=maxi(maximum_draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	var average_ms:=(Time.get_ticks_usec()-start)/120000.0
	root.get_texture().get_image().save_png("res://docs/screenshots/weapon-stress-revised.png" if revised else "res://docs/screenshots/weapon-stress.png")
	print("VISUAL PROFILE: 40 effects + 49 enemies, average frame %.2f ms, max draw calls %d" % [average_ms,maximum_draws])
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
