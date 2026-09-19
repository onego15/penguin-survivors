extends SceneTree
const T=preload("res://scripts/difficulty_tiers.gd")
const D=preload("res://scripts/difficulty.gd")
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func run() -> void:
	check(T.scaled(50,1.1)==55 and T.scaled(90,1.1)==99,"exact percentage boundaries")
	check(T.selected_id=="normal" and T.valid("invalid")=="normal","default normal")
	for seconds in [0,30,90,150,300,540,600]:
		check(T.profile(seconds,"normal")==D.profile(seconds),"normal profile identical")
		for id in T.IDS:
			var p=T.profile(seconds,id); var base=D.profile(seconds)
			check(is_equal_approx(p.rate,base.rate*T.data(id).rate) and p.cap==mini(100,ceili(base.cap*T.data(id).cap)),"budget/cap")
			check(p.speed==base.speed and p.hp==base.hp and p.damage==base.damage,"time curves unchanged")
	for level in range(1,30):
		check(T.xp(level,"normal")==D.xp_for_level(level),"normal XP")
		check(T.xp(level,"easy")==ceili(D.xp_for_level(level)*0.8),"easy XP")
	T.selected_id="hard"
	var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_process(false); game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	check(game.settings.difficulty=="normal" and T.selected_id=="hard","sandbox selection independent")
	var specs: Array=[]
	for i in range(15): specs.append({"type":"normal","index":i})
	for i in range(8): specs.append({"type":"mid","index":i})
	for i in range(2):
		specs.append({"type":"minion","index":i})
		specs.append({"type":"final","index":i,"phase":1})
	for spec in specs:
		game.settings.difficulty="normal"
		var baseline=game.create_enemy(spec,Vector3(15,0,15),420)
		var hp: int=baseline.health; var speed: float=baseline.speed; var contact: int=baseline.contact_damage; baseline.free()
		for id in T.IDS:
			game.settings.difficulty=id
			var e=game.create_enemy(spec,Vector3(15,0,15),420)
			check(e.health==maxi(1,ceili(hp*T.data(id).hp)) and e.max_health==e.health,"HP "+id+str(spec))
			var scaled: int=e.health
			T.apply_hp(e); check(e.health==scaled and e.max_health==scaled,"HP applied once")
			check(e.speed==speed and e.contact_damage==contact,"speed and raw contact unchanged")
			check(T.source(e)==id,"actor capture")
			e.free()
	game.player.training_invincible=false
	for id in T.IDS:
		game.player.health=100; game.player.invulnerability=0; game.player.support_damage_multiplier=0.7
		game.contributions.entries.clear()
		game.player.take_damage(13,id)
		var adjusted:=ceili(13*T.data(id).damage); var received:=ceili(adjusted*0.7)
		check(game.player.health==100-received,"damage ceil before bear "+id)
		check(game.contributions.entries["support:1"].prevented==adjusted-received,"bear contribution excludes difficulty")
		game.player.take_damage(13,id); check(game.player.health==100-received,"immunity priority")
		for index in range(2):
			game.settings.difficulty=id
			var boss=game.create_enemy({"type":"final","index":index,"phase":2},Vector3(15,0,15),0)
			check(boss.health==boss.max_health/2 and boss.enraged,"second phase uses scaled max")
			boss.free()
	game.settings.difficulty="easy"
	var old=game.create_enemy({"type":"normal","index":4},Vector3(15,0,15),0)
	game.settings.difficulty="expert"
	var fresh=game.create_enemy({"type":"normal","index":4},Vector3(15,0,15),0)
	for script in ["boss_projectile","enemy_cloud","castle_bomb","deer_shockwave"]:
		var hazard=load("res://scripts/"+script+".gd").new()
		T.inherit_attack(old,hazard); check(T.source(hazard)=="easy","later hazard retains old source")
		hazard.free()
	for id in T.IDS:
		for script in ["boss_projectile","enemy_cloud","castle_bomb","deer_shockwave"]:
			var hazard=load("res://scripts/"+script+".gd").new()
			hazard.target=game.player; hazard.damage=13; T.prepare(hazard,id)
			game.actors.add_child(hazard); hazard.position=game.player.position
			if script=="boss_projectile": hazard.position.y+=1
			game.player.health=100; game.player.invulnerability=0; game.player.support_damage_multiplier=0.7
			hazard._physics_process(1.5 if script=="castle_bomb" else 0)
			check(game.player.health==100-ceili(ceili(13*T.data(id).damage)*0.7),"hazard damage pipeline "+script+id)
			hazard.free()
	old._fire(Vector3.FORWARD)
	var fired=get_nodes_in_group("hostile_projectiles")[-1]
	check(T.source(fired)=="easy","actual delayed owl projectile capture")
	fired.free()
	var lingering:=Node.new(); T.inherit_attack(old,lingering); old.free()
	check(T.source(lingering)=="easy" and T.source(fresh)=="expert","source survives creator death")
	lingering.free(); fresh.free()
	for id in T.IDS:
		game.settings.difficulty=id
		for index in range(2):
			var boss=game.create_enemy({"type":"final","index":index,"phase":1},Vector3(15,0,15),0)
			game.player.health=100; game.player.invulnerability=0; game.player.support_damage_multiplier=1
			if index==0:
				boss.attack_kind="quake"; boss.quake_center=game.player.position; boss._release_attack()
			else:
				boss.attack_kind="rings"; boss.centers.assign([game.player.position]); boss.release()
			check(game.player.health==100-ceili((40 if index==0 else 24)*T.data(id).damage),"boss technique scaling")
			boss.free()
	game.settings.difficulty="easy"
	game.place_batch({"type":"normal","index":0},Vector3(0,0,10),2)
	game.settings.difficulty="expert"; game.reset_trial()
	for e in get_nodes_in_group("all_enemies"): check(T.source(e)=="expert","reset updates formations")
	game.free(); await process_frame
	for id in T.IDS:
		T.selected_id=id
		game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
		game.set_process(false); game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
		check(game.difficulty_id==id and game.xp_needed==T.xp(1,id),"run captures selection")
		T.selected_id="normal"; check(game.difficulty_id==id,"run immutable")
		game.elapsed=600; game._start_final_boss(); game._finish_presentation()
		for phase in [1,2]:
			game.final_director.begin_phase(phase)
			game.final_director.tick(6)
			check(get_nodes_in_group("final_minions").size()==(2 if phase==1 else 4),"initial minion batch")
			check(game.final_director.next_minions==6+T.data(id).intervals[phase-1],"minion interval")
			for n in range(5): game.final_director.tick(T.data(id).intervals[phase-1])
			check(get_nodes_in_group("final_minions").size()==T.data(id).minion_caps[phase-1],"minion cap")
		game.free(); await process_frame
	T.selected_id="normal"
	var title=load("res://scenes/title.tscn").instantiate(); root.add_child(title); current_scene=title
	check(title.difficulty_buttons.size()==4,"four title choices")
	for id in T.IDS:
		title.select_difficulty(id); check(T.selected_id==id,"title selection")
	title.starting=true; title.select_difficulty("easy"); check(T.selected_id=="expert","start prevents late change")
	title.free(); await process_frame
	T.selected_id="easy"
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
	T.selected_id="hard"; game.restart_run(); await process_frame; await process_frame
	check(current_scene.difficulty_id=="easy","retry uses captured run ID")
	current_scene.free(); await process_frame; T.selected_id="normal"
	print("DIFFICULTY TIERS TEST: %d failures"%failures); quit(failures)


