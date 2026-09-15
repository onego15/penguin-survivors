extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+caption)
	if not ok: failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=420
	var a=game.spawn_enemy(9)
	var b=game.spawn_enemy(9)
	for deer in [a,b]:
		deer.set_physics_process(false)
		deer.position=Vector3(0,0,-8)
		deer.cooldown=0
	a._physics_process(0)
	b._physics_process(0)
	check(a.special_state=="warn" and b.special_state=="move","Only one deer can commit a warning")
	for i in range(32):
		var bolt=preload("res://scripts/boss_projectile.gd").new()
		bolt.target=game.player
		bolt.regular=true
		game.actors.add_child(bolt)
		bolt.set_physics_process(false)
	a._physics_process(1.2)
	b._physics_process(0)
	check(get_nodes_in_group("regular_projectiles").size()==32 and b.special_state=="move","Projectile cap blocks warning and also prevents overflow at release")
	for bolt in get_nodes_in_group("regular_projectiles"): bolt.free()
	var wave=preload("res://scripts/deer_shockwave.gd").new()
	wave.target=game.player
	wave.direction=Vector3.BACK
	game.actors.add_child(wave)
	wave.set_physics_process(false)
	game.player.position=Vector3(1.7,0,5)
	wave._physics_process(1)
	check(game.player.health==100,"Moving outside the 2.4m wave width avoids a swept hit")
	wave._physics_process(10)
	check(is_equal_approx(wave.position.z,14) and wave.spent,"Large timesteps cannot extend the wave beyond fourteen metres")
	wave.free()
	wave=preload("res://scripts/deer_shockwave.gd").new()
	wave.target=game.player
	game.actors.add_child(wave)
	wave.set_physics_process(false)
	game.player.position=Vector3(1.5,0,5)
	wave._physics_process(1)
	check(game.player.health==88 and wave.spent,"Wave includes player radius and hits exactly once")
	game.player.invulnerability=0
	wave._physics_process(1)
	check(game.player.health==88,"Spent projectile cannot inflict a second hit")
	for mode in ["storm","whip","trail","nova","firework"]:
		var effect=preload("res://scripts/weapon_flourish.gd").new()
		effect.mode=mode
		game.actors.add_child(effect)
		var count: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		for i in range(120): effect.animate(i/60.0,3)
		check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))==count,"Bounded geometry: "+mode+" creates no animation-time nodes")
		if mode=="trail":
			check(effect.bands[0].scale.x<0.035,"Fading embers retain their small particle scale")
		effect.free()
	game.queue_free()
	await create_timer(0.3).timeout
	print("SHOCKWAVE/VISUAL TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
