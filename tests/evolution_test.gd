extends SceneTree
const C=preload("res://scripts/weapon_catalog.gd")
const E=preload("res://scripts/evolution_catalog.gd")
const S=preload("res://scripts/stage_catalog.gd")
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, caption: String) -> void:
	if not ok: failures+=1; push_error(caption)
func new_game(stage: String="snowfield") -> void:
	if is_instance_valid(game): game.free()
	paused=false; S.selected_id=stage
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
func enemy(point: Vector3):
	var unit=game.spawn_enemy(0); unit.position=point; unit.health=1000; unit.max_health=1000; return unit
func run() -> void:
	check(C.ITEMS.size()==23 and C.all_ids().size()==31,"23 base + 8 evolved")
	check(S.weapon_pool("snowfield").size()==16 and S.weapon_pool("castle").size()==16,"unchanged pools")
	for a in range(1,6):
		for b in range(1,6): check(E.inherited_level("blizzard_fan",{"gust":a,"popsicle":b})==a+b-1,"all 25 fusion levels")
	for stage in ["snowfield","castle"]:
		var levels: Dictionary={}
		for id in S.weapon_pool(stage): levels[id]=5
		var candidates:=E.available(levels,{},S.weapon_pool(stage))
		check(("pearl_chime" in candidates)==(stage=="snowfield"),"snow recipe")
		check(("thunder_dome" in candidates)==(stage=="castle"),"castle recipe")
	for rank in range(2,6):
		for recipe in ["pop_branch","heart_branch"]:
			for output in E.RECIPES[recipe].outputs:
				new_game(); game.armory.acquire("heart")
				var source: String=E.RECIPES[recipe].sources[0]; game.armory.levels[source]=rank
				check(game.armory.evolve(recipe,output),"single evolves")
				check(game.armory.levels[output]==rank and not game.armory.levels.has(source),"single inheritance")
				for n in range(10): game.armory.acquire(output)
				check(game.armory.levels[output]==5,"single cap")
	new_game(); check(not "pop_branch" in game.armory.available_evolutions(),"Lv1 single unavailable")
	game.armory.acquire("frost"); game.experience=game.xp_needed+17; game.open_weapon_choice()
	check(game.offered_weapons[0]=="@pop_branch" and paused,"single at Lv2 prioritised")
	var xp: int=game.experience; var level: int=game.level
	game.choice_ui._select(0)
	check(game.pending_recipe=="pop_branch" and game.choice_open and game.experience==xp and game.level==level,"branch pending does not spend")
	game.return_to_choices(); check(game.pending_recipe=="" and paused,"back preserves pause")
	game.choice_ui._select(0); game.choice_ui._select(0)
	check(game.armory.levels.get("pop_cannon")==2 and not game.choice_open and not paused and game.experience==17,"branch confirm once and XP carry")
	game.choose_evolution("triple_cannon"); check(not game.armory.levels.has("triple_cannon"),"double confirmation rejected")
	game.armory.acquire("frost"); check(not game.armory.levels.has("frost"),"consumed cannot reacquire")
	new_game(); game.armory.acquire("gust"); game.armory.acquire("popsicle")
	var other=enemy(Vector3(0,0,5)); game.armory.acquire("heart"); game.armory.fire("heart"); game.armory.fire("gust")
	var old_wind=weakref(game.armory.gust_attack)
	var unrelated: Node
	for node in game.actors.get_children():
		if node.get_meta("weapon_id","")=="heart": unrelated=node
	game.armory.cooldowns.heart=0.4
	check(game.armory.evolve("blizzard_fan","blizzard_fan"),"Lv1 fusion")
	check(game.armory.levels.blizzard_fan==1 and old_wind.get_ref()==null,"material attacks removed")
	check(is_instance_valid(unrelated) and is_equal_approx(game.armory.cooldowns.heart,0.4),"unrelated attack/timer preserved")
	game.armory.acquire("frost"); check(game.armory.evolve("pop_branch","triple_cannon"),"second slot")
	check(game.armory.available_evolutions().is_empty(),"two slot cap")
	for i in range(20): game.armory.acquire("blizzard_fan")
	check(game.armory.levels.blizzard_fan==9,"fusion cap")
	# Stable eligible set is offered exactly once per cycle.
	new_game(); game.armory.acquire("frost"); game.armory.acquire("heart"); game.armory.acquire("heart"); game.armory.acquire("beam"); game.armory.acquire("gust"); game.armory.acquire("popsicle")
	var seen:=[]
	for i in range(4): seen.append(game.armory.next_evolution())
	var unique: Dictionary={}
	for id in seen: unique[id]=true
	check(unique.size()==4,"nonrepeating recipe bag")
	# Low-FPS projectile crossings still honour per-projectile hit limits.
	for id in ["pop_cannon","triple_cannon","big_heart","heart_ring"]:
		new_game(); var enemies:=[]
		for i in range(9): enemies.append(enemy(Vector3(0,0,2+i*1.25)))
		var bullet=load("res://scripts/evolution_projectile.gd").new(); var values:=C.stats(id,2)
		bullet.evolution_id=id; bullet.damage=values.damage; bullet.max_hits=values.pierce; bullet.reach=values.reach; bullet.direction=Vector3.BACK; bullet.position=Vector3.UP
		game.armory.attach(bullet,id); bullet._physics_process(0.6)
		var hit:=0
		for unit in enemies:
			if unit.health<1000: hit+=1
		check(hit==int(values.pierce),"low FPS piercing "+id)
	# Beam processes all five timestamps exactly once, even in a long frame.
	new_game(); var victim=enemy(Vector3(0,0,4)); var under=enemy(Vector3(0,0,7)); under.targetable=false
	var beam=load("res://scripts/fusion_attack.gd").new(); beam.mode="rainbow_heart"; beam.stats=C.stats("rainbow_heart",1); beam.player=game.player; beam.position=Vector3.UP; beam.direction=Vector3.BACK
	game.armory.attach(beam,"rainbow_heart"); beam._physics_process(1.21)
	check(victim.health==980 and under.health==1000 and beam.pulse_count==5,"beam five hits and underground exclusion")
	beam._physics_process(0.01); check(victim.health==980,"no sixth hit")
	# Overlapping pearl waves share one hit per activation.
	new_game(); var target=enemy(Vector3.ZERO); target.hit_radius=4
	var pearl=load("res://scripts/fusion_attack.gd").new(); pearl.mode="pearl_chime"; pearl.stats=C.stats("pearl_chime",1); pearl.player=game.player
	game.armory.attach(pearl,"pearl_chime"); pearl.pulse()
	check(target.health==998,"pearl wave overlap is not multiplied")
	# Frozen enemies can still be pushed, without extending freeze.
	new_game(); var frozen=enemy(Vector3(0,0,3)); game.player.body.rotation.y=0
	var fan=load("res://scripts/fusion_attack.gd").new(); fan.mode="blizzard_fan"; fan.stats=C.stats("blizzard_fan",1); fan.player=game.player
	game.armory.attach(fan,"blizzard_fan"); fan.pulse()
	check(frozen.health<1000 and is_instance_valid(frozen.control) and is_equal_approx(frozen.control.frozen,C.stats("blizzard_fan",1).freeze),"fan damage and freeze")
	frozen.control_step(0.3); var remaining: float=frozen.control.frozen
	fan.pulse(); check(is_equal_approx(frozen.control.frozen,remaining),"freeze cannot extend")
	var boss=enemy(Vector3(1,0,3)); boss.is_miniboss=true
	fan.pulse(); check(boss.health<1000 and not is_instance_valid(boss.control),"boss takes damage without control")
	# Temporal progression stays suspended in a real tree pause.
	game.actors.process_mode=Node.PROCESS_MODE_INHERIT
	game.player.set_physics_process(false); frozen.set_physics_process(false); boss.set_physics_process(false)
	var clock: float=fan.age
	paused=true
	for i in range(5): await process_frame
	check(fan.age==clock,"fusion pause")
	paused=false
	# Six cloud strikes, no residual area damage, and walls block each burst.
	new_game(); var cloud_target=enemy(Vector3(0,0,4))
	var cloud=load("res://scripts/fusion_attack.gd").new(); cloud.mode="thunder_dome"; cloud.player=game.player; cloud.stats=C.stats("thunder_dome",1); cloud.position=Vector3(0,0,4)
	game.armory.attach(cloud,"thunder_dome")
	for i in range(6): cloud.cloud_points[i]=Vector3.ZERO
	cloud._physics_process(0.49); check(cloud_target.health==1000,"first cloud strike waits half a second")
	cloud._physics_process(2.51); check(cloud_target.health==970 and cloud.pulse_count==6,"six strikes with low FPS")
	cloud._physics_process(0.01); check(cloud_target.health==970,"cloud has no residual damage")
	# Low-rank usability adjustment: larger strike reaches the new edge, still once.
	new_game(); var edge=enemy(Vector3(1.95,0,4)); var outside=enemy(Vector3(2.2,0,4))
	var adjusted_cloud=load("res://scripts/fusion_attack.gd").new(); adjusted_cloud.mode="thunder_dome"; adjusted_cloud.player=game.player; adjusted_cloud.stats=C.stats("thunder_dome",1); adjusted_cloud.position=Vector3(0,0,4)
	game.armory.attach(adjusted_cloud,"thunder_dome"); adjusted_cloud.cloud_points[0]=Vector3.ZERO; adjusted_cloud._physics_process(0.5)
	check(edge.health==995 and outside.health==1000,"new cloud boundary matches hit radius")
	adjusted_cloud._physics_process(0.1); check(edge.health==995,"enlarged strike remains single hit")
	check(C.stats("thunder_dome",9).pulse_radius==1.6 and C.stats("rainbow_heart",9).width==0.65 and C.stats("rainbow_heart",9).cooldown==2.35,"max rank cloud and beam unchanged")
	check(C.stats("blizzard_fan",9).reach==9 and C.stats("blizzard_fan",9).freeze==1.4 and C.stats("blizzard_fan",9).pulse_interval==4,"max rank control unchanged")
	for rank in range(1,9):
		for id in ["rainbow_heart","blizzard_fan","thunder_dome"]:
			var before:=C.stats(id,rank); var after:=C.stats(id,rank+1)
			for key in before:
				check(after[key]<=before[key] if key in ["cooldown","pulse_interval"] else after[key]>=before[key],"adjusted growth never regresses")
	# Material investment is preserved in actual armory transitions.
	for a in range(1,6):
		for b in range(1,6):
			new_game(); game.armory.acquire("gust"); game.armory.acquire("popsicle"); game.armory.levels.gust=a; game.armory.levels.popsicle=b
			check(game.armory.evolve("blizzard_fan","blizzard_fan") and game.armory.levels.blizzard_fan==a+b-1,"actual inheritance across 25 combinations")
			for i in range(9-(a+b-1)): game.armory.acquire("blizzard_fan")
			check(C.stats("blizzard_fan",game.armory.levels.blizzard_fan)==C.stats("blizzard_fan",9),"upgrade order has same final stats")

	# All new entries construct/fire safely at their min and max ranks.
	for id in E.ITEMS:
		for rank in [C.min_rank(id),C.max_rank(id)]:
			new_game(); enemy(Vector3(0,0,4)); game.armory.acquire(id); game.armory.levels[id]=rank
			check(game.armory.fire(id),"fire "+id)
			for node in game.actors.get_children():
				if node.get_meta("weapon_id","")==id and node.has_method("_physics_process"): node._physics_process(0.1)
	# Castle beam must stop at x=8 wall (z=0).
	new_game("castle"); game.player.position=Vector3(4,0,0); var behind=enemy(Vector3(10,0,0))
	var wall_beam=load("res://scripts/fusion_attack.gd").new(); wall_beam.mode="rainbow_heart"; wall_beam.stats=C.stats("rainbow_heart",9); wall_beam.player=game.player; wall_beam.position=Vector3(4,1,0); wall_beam.direction=Vector3.RIGHT
	game.armory.attach(wall_beam,"rainbow_heart"); wall_beam._physics_process(1.2)
	check(behind.health==1000 and wall_beam.beam_length<4.1,"castle beam obstruction")
	# Area pulses cannot cross castle walls either.
	wall_beam.area(Vector3(6,0,0),6,20,{})
	check(behind.health==1000,"fusion area wall obstruction")
	# A dying player cannot confirm an already-open evolution menu.
	new_game(); game.armory.acquire("frost"); game.experience=game.xp_needed; game.open_weapon_choice(); game.choose_weapon(0); game.player.health=0
	game.choose_evolution("pop_cannon"); check(not game.armory.levels.has("pop_cannon"),"death wins over pending evolution")
	# Evolved hits trigger the real phase transition; clocks suspend until it ends.
	new_game(); game.elapsed=600; game._start_final_boss(); game._process(2)
	var final=game.active_boss; final.set_physics_process(false); game.player.set_physics_process(false)
	final.position=Vector3(0,0,4); final.health=final.max_health/2+1
	var phase_beam=load("res://scripts/fusion_attack.gd").new(); phase_beam.mode="rainbow_heart"; phase_beam.stats=C.stats("rainbow_heart",1); phase_beam.player=game.player; phase_beam.position=Vector3.UP; phase_beam.direction=Vector3.BACK
	game.armory.attach(phase_beam,"rainbow_heart"); phase_beam._physics_process(0)
	check(game.run_state=="phase_transition" and final.enraged,"evolved attack enters boss phase")
	var paused_age: float=phase_beam.age
	for i in range(4): await process_frame
	check(phase_beam.age==paused_age,"boss presentation suspends evolved attacks")
	game._process(2); final.health=1; phase_beam._physics_process(0.3); game._physics_process(0)
	check(game.victory,"evolved attack can defeat boss")
	new_game(); check(game.armory.evolution_count()==0 and game.armory.consumed.is_empty(),"fresh run clears evolution state")
	game.armory.acquire("pop_cannon"); game.armory.cooldowns.pop_cannon=0.13; game.armory.acquire("pop_cannon")
	check(is_equal_approx(game.armory.cooldowns.pop_cannon,0.13),"upgrade preserves remaining cooldown")
	game.armory.acquire("pearl_chime"); game.armory.fire("pearl_chime")
	var continuous=game.armory.fusion_nodes.pearl_chime; continuous._physics_process(0.2)
	var next_wave: float=continuous.next_pulse
	game.armory.acquire("pearl_chime"); game.armory.fire("pearl_chime")
	check(continuous.age==0.2 and continuous.next_pulse==next_wave,"persistent upgrade preserves pulse clock")
	# Sandbox accepts all evolved ranks while isolating campaign state.
	new_game(); game.free()
	game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game; game.set_physics_process(false)
	for id in E.ITEMS:
		game.set_weapon(id,C.max_rank(id)); check(game.armory.levels[id]==C.max_rank(id),"sandbox max rank "+id)
	game.set_weapon("pop_cannon",1); check(game.armory.levels.pop_cannon==2,"sandbox single minimum")
	game.set_weapon("blizzard_fan",0); check(not game.armory.levels.has("blizzard_fan"),"sandbox remove")
	game.menu.open_menu(); game.set_weapon("pearl_chime",4); check(paused and game.armory.levels.pearl_chime==4,"sandbox configuration paused")
	# Exhausted growth still heals; capped evolutions remain in HUD/results catalog.
	new_game(); game.armory.levels.clear(); game.armory.levels.pop_cannon=5; game.armory.levels.big_heart=5
	for id in S.weapon_pool("snowfield"): game.armory.consumed[id]=true
	game.player.health=50; game.experience=game.xp_needed; game.open_weapon_choice()
	check(game.player.health==70 and not game.choice_open,"exhaustion healing")
	game.free(); S.selected_id="snowfield"; paused=false; await process_frame
	print("EVOLUTION TEST: %d failures"%failures); quit(1 if failures else 0)
