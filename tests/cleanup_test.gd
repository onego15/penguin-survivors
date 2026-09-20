extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
func run() -> void:
	var rules=preload("res://scripts/cleanup_director.gd")
	check(rules.totals(40,10,0.25).bonus==13,"sum before rounding")
	check(rules.totals(40,40,1.0).bonus==50,"maximum bonus")
	check(rules.totals(0,0,0).bonus==0,"no targets")
	for stage in ["snowfield","castle"]:
		for tier in ["easy","normal","hard","expert"]:
			var game=load("res://scenes/main.tscn").instantiate()
			game.stage_id=stage; game.difficulty_id=tier
			root.add_child(game); current_scene=game; game.set_physics_process(false); game.set_process(false)
			game.actors.process_mode=Node.PROCESS_MODE_DISABLED
			game.elapsed=569
			var enemies: Array=[]
			for i in range(4): enemies.append(game.spawn_enemy(0))
			var mole=game.spawn_enemy(8); mole.targetable=false
			var boss=game.spawn_enemy(0,true); game.active_boss=boss
			boss.health=boss.max_health/4
			game.elapsed=570; game._tick_director(0)
			check(game.sweep.targets.size()==5,"snapshot includes underground mole")
			check(game.sweep.snapshot().bonus==35,"prior boss damage counted")
			var budget: float=game.director.budget
			game.director.tick(2,false)
			check(game.director.budget==budget and game.spawn_enemy(0)==null and game.spawn_enemy(0,true)==null,"no spawns or budget during sweep")
			if game.obstacles!=null:
				game.obstacles.command(8); game.obstacles.tick(1)
				for gate in game.obstacles.gates: check(gate.state=="open","cleanup gates stay open")
			for enemy in enemies: enemy.take_damage(99999)
			check(game.sweep.snapshot().bonus==11,"remaining fifth plus quarter boss")
			check(game.kills==4 and game.experience==4,"normal rewards preserved")
			mole.targetable=true; mole.take_damage(99999)
			check(game.sweep.snapshot().bonus==5 and game.sweep.guidance().contains("中ボス"),"boss remains after normal clear")
			boss.health=boss.max_health; check(game.sweep.snapshot().bonus==20,"full boss")
			boss.health=boss.max_health/2; check(game.sweep.snapshot().bonus==10,"half boss")
			boss.health=boss.max_health/4
			game.elapsed=600; game._tick_director(0)
			var base: int=game.Tiers.scaled(1400 if stage=="snowfield" else 1600,game.Tiers.data(tier).hp)
			var expected:=ceili(base*1.05)
			check(game.active_boss.max_health==expected,"difficulty then sweep applied")
			game.sweep.apply(game.active_boss); check(game.active_boss.health==expected,"apply once")
			check(game.sweep.snapshot().bonus==5,"snapshot survives enemy cleanup")
			game._physics_process(1); check(game.elapsed==600,"cinematic clock stopped")
			game._finish_presentation()
			game.active_boss.take_damage(game.active_boss.health-game.active_boss.max_health/2)
			check(game.active_boss.enraged,"phase threshold uses adjusted HP")
			game.free(); await process_frame
	var game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game; game.set_physics_process(false)
	check(not game.sweep.started and game.sweep.snapshot().bonus==0,"new run resets")
	game.elapsed=570; game._tick_director(0); check(game.sweep.snapshot().bonus==0,"empty cleanup")
	game.experience=game.xp_needed; game.open_weapon_choice(); game._physics_process(1)
	check(game.elapsed==570,"choice freezes cleanup clock")
	game.choose_weapon(0)
	root.get_node("Settings").open_menu(); await process_frame
	check(game.elapsed==570 and paused,"pause freezes cleanup")
	root.get_node("Settings").close_menu()
	game.elapsed=599; game.player.health=0; game._physics_process(2)
	check(game.game_over and not game.final_boss_spawned,"death precedes boss")
	game.free(); await process_frame
	print("CLEANUP TEST: %d failures"%failures); quit(1 if failures else 0)
