extends SceneTree
const Catalog=preload("res://scripts/weapon_catalog.gd")
const Stages=preload("res://scripts/stage_catalog.gd")
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func enemy(point: Vector3) -> Node3D:
	var e=game.create_enemy({"type":"normal","index":0},point,0)
	e.health=1000; e.max_health=1000; e.set_physics_process(false)
	return e
func run() -> void:
	check(Catalog.ITEMS.size()==26,"26 catalog entries")
	var union: Dictionary={}
	for stage in ["snowfield","castle","beach"]:
		var pool=Stages.weapon_pool(stage)
		check(pool.size()==16,"16 weapons")
		for id in ["frost","heart","beam"]: check(pool.has(id),"shared "+id)
		for id in pool: union[id]=true; check(Catalog.ITEMS.has(id),"valid pool id")
		Stages.selected_id=stage
		var campaign=load("res://scenes/main.tscn").instantiate()
		root.add_child(campaign); current_scene=campaign
		campaign.set_physics_process(false); campaign.player.set_physics_process(false)
		for seed_value in range(12):
			campaign.rng.seed=seed_value
			for draw in range(15):
				campaign.experience=campaign.xp_needed
				campaign.open_weapon_choice()
				check(campaign.offered_weapons.size()==3,"three choices")
				for id in campaign.offered_weapons: check(pool.has(id),"stage-only draws")
				campaign.choice_ui.close(); campaign.choice_open=false; paused=false
		for id in pool: campaign.armory.levels[id]=5
		campaign.armory.levels.pop_cannon=5; campaign.armory.levels.big_heart=5 # Evolution slots and growth also exhausted.
		campaign.player.health=50; campaign.experience=campaign.xp_needed
		campaign.open_weapon_choice()
		check(campaign.player.health==70 and not campaign.choice_open,"stage max heals without other stage weapons")
		campaign.free(); await process_frame
	check(union.size()==26,"all weapons belong to stage")
	game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	game.settings.weapons={"orbit":1}; game.rebuild_player()
	game.armory.fire("orbit")
	var orbit=game.armory.orbit_attack; orbit.set_physics_process(false)
	var e=enemy(Vector3(2.2,0,0))
	orbit._physics_process(0.01)
	check(e.health==998,"pearl contact")
	var before: int=e.health
	orbit._physics_process(0.1)
	check(e.health==before,"shared hit limit")
	var previous_age: float=orbit.age
	var previous_hits: Dictionary=orbit.hit_times.duplicate()
	game.armory.levels.orbit=5; game.armory.fire("orbit")
	check(game.armory.orbit_attack==orbit and orbit.pearls.size()==6 and orbit.age==previous_age and orbit.hit_times==previous_hits,"upgrade retains persistent orbit and hit clocks")
	check(orbit.stats.damage==3 and orbit.stats.radius==2.6,"pearl max stats")
	e.position=Vector3(0,0,2.6); before=e.health
	orbit._physics_process(0.5)
	check(e.health<before,"low FPS arc hits")
	game.switch_terrain(true)
	game.player.position=Vector3(6.5,0,0)
	game.armory.fire("orbit"); orbit=game.armory.orbit_attack; orbit.set_physics_process(false)
	e=enemy(Vector3(9,0,0)); before=e.health
	orbit._physics_process(0.2)
	check(e.health==before and not orbit.pearls[0].visible,"pearl wall occlusion")
	game.clear_enemies(); game.switch_terrain(false); game.player.position=Vector3.ZERO
	game.settings.weapons={"starfall":1}; game.rebuild_player()
	game.player.set_physics_process(false)
	e=enemy(Vector3(0,0,8))
	check(not game.armory.fire("starfall"),"initial full cooldown")
	game.armory.tick(23.9)
	check(get_nodes_in_group("weapon_attacks").is_empty(),"no early meteor")
	game.armory.acquire("starfall")
	check(game.armory.cooldowns.starfall>0,"upgrade keeps remaining delay")
	game.armory.tick(0.2)
	var meteor=get_nodes_in_group("weapon_attacks")[0]; meteor.set_physics_process(false)
	check(meteor.position==Vector3(0,0,8) and meteor.damage==36,"meteor locks target and rank")
	e.position=Vector3(0,0,9)
	var far=enemy(Vector3(0,0,-8))
	var hidden=enemy(Vector3(1,0,8)); hidden.targetable=false
	meteor._physics_process(1.19); check(e.health==1000,"full warning")
	meteor._physics_process(0.02)
	check(e.health==964 and far.health==1000 and hidden.health==1000,"single area hit, range and targetability")
	meteor._physics_process(0.4); check(e.health==964,"no residual damage")
	check(game.armory.cooldowns.starfall==23,"next delay starts at launch")
	game.clear_enemies(); game.switch_terrain(true)
	var burst=preload("res://scripts/starfall_attack.gd").new(); burst.position=Vector3(6,0,0)
	game.actors.add_child(burst); burst.set_physics_process(false)
	var near=enemy(Vector3(5,0,0)); var behind=enemy(Vector3(10,0,0))
	burst._physics_process(1.2)
	check(near.health==970 and behind.health==1000,"meteor explosion wall blocked")
	game.menu.open_menu()
	var clock: float=burst.age
	burst.set_physics_process(true)
	await create_timer(0.05,true).timeout
	check(burst.age==clock,"paused visuals")
	game.menu.close_menu()
	game.settings.weapons={}; game.rebuild_player()
	check(get_nodes_in_group("weapon_attacks").is_empty(),"unequip clears attacks")
	check(game.sound.clips.has("star_fall") and game.sound.clips.has("star_impact"),"dedicated audio")
	game.free(); await process_frame
	print("STARFALL / POOL TEST: ",failures," failures")
	quit(1 if failures else 0)
