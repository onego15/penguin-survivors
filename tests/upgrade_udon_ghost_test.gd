extends SceneTree
const Catalog=preload("res://scripts/weapon_catalog.gd")
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.invulnerability=999
	check(Catalog.ITEMS.size()==23,"Twenty-three weapons including udon")
	for id in Catalog.ITEMS:
		var previous:=Catalog.stats(id,1)
		var meaningful:=true
		for rank in range(2,6):
			var next:=Catalog.stats(id,rank)
			meaningful=meaningful and next.damage>=previous.damage and (next.count>previous.count if id=="orbit" else next.cooldown<previous.cooldown) and Catalog.upgrade_text(id,rank-1).contains("→")
			previous=next
		check(meaningful and Catalog.stats(id,99)==Catalog.stats(id,5),"Bounded upgrade curve: "+id)
		for i in range(8): game.armory.acquire(id)
		check(game.armory.levels[id]==5,"Acquisition cannot exceed level five: "+id)
	# Check live attack objects, not just the catalog's arithmetic.
	var target=game.spawn_enemy(0)
	target.position=Vector3(0,0,6)
	target.set_physics_process(false)
	for id in ["heart","fan","lightning","nova","turret","beam","boomerang"]:
		for attack in get_nodes_in_group("weapon_attacks"): attack.free()
		game.armory.fire(id)
		var attacks=get_nodes_in_group("weapon_attacks")
		var attack=attacks[0]
		match id:
			"heart": check(attack.max_hits==5 and is_equal_approx(attack.max_distance,16.8),"Upgraded heart has five hits and longer range")
			"fan": check(attacks.size()==7 and attack.damage==4,"Upgraded fan actually emits seven stronger feathers")
			"lightning": check(attacks.size()==5 and attack.area_radius>3.7,"Upgraded lightning creates five larger zones")
			"nova": check(attack.area_radius>5.2 and attack.damage==6,"Upgraded nova grows its real damage area")
			"turret": check(attack.lifetime>10 and attack.target_reach>16,"Upgraded turret duration and acquisition range")
			"beam": check(attack.lifetime>1.6,"Upgraded beam lasts longer")
			"boomerang": check(attack.ellipse_reach>12.7,"Upgraded boomerang extends its actual ellipse")
	for attack in get_nodes_in_group("weapon_attacks"): attack.free()
	target.free()
	# Exhaust evolution slots too: base weapons alone no longer exhaust choices.
	game.armory.evolve("pop_branch","pop_cannon")
	game.armory.evolve("heart_branch","big_heart")
	game.armory.levels.udon=4
	game.experience=game.xp_needed
	game.open_weapon_choice()
	check(game.offered_weapons==["udon"] and game.choice_ui.cards[0].visible and not game.choice_ui.cards[1].visible,"Only eligible weapon is shown when one remains")
	game.choose_weapon(0)
	check(game.armory.levels.udon==5 and not paused,"Final upgrade consumes one reward")
	game.player.health=60
	game.experience=game.xp_needed+7
	game.open_weapon_choice()
	check(not paused and not game.choice_open and game.player.health==80 and game.experience==7,"All-max fallback heals and preserves overflow without empty menu")
	game.armory.levels.udon=1
	game.armory.tick(0)
	for actor in game.actors.get_children():
		if actor!=game.player: actor.free()
	var enemy=game.spawn_enemy(0)
	enemy.position=Vector3(0,0,5)
	enemy.health=100
	enemy.max_health=100
	enemy.set_physics_process(false)
	game.player.body.rotation.y=0
	game.armory.fire("udon")
	var udon=get_nodes_in_group("weapon_attacks")[0]
	udon.set_physics_process(false)
	udon._physics_process(0.35)
	check(enemy.health==99,"Udon damages outbound once")
	udon._physics_process(0.9)
	check(enemy.health==98,"Udon damages return once, including low FPS")
	check(enemy.position.length()>=2.99 and enemy.position.length()<5,"Udon pulls ordinary enemies at most four metres and keeps distance")
	check(udon.noodles.size()==24,"Noodle visual reuses fixed segment count")
	game.free()
	await process_frame
	preload("res://scripts/stage_catalog.gd").selected_id="castle"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.invulnerability=999
	game.player.position=Vector3(4,0,8)
	var o=game.obstacles
	o.gates[3].state="closed"
	o.revision+=1
	var ghost=game.spawn_enemy(14)
	ghost.position=Vector3(12,0,8)
	ghost.set_physics_process(false)
	var ordinary=game.spawn_enemy(0)
	ordinary.position=Vector3(12,0,8)
	ordinary.set_physics_process(false)
	for i in range(180):
		ghost._physics_process(1.0/60)
		ordinary._physics_process(1.0/60)
	check(ghost.position.x<7.4 and ordinary.position.x>8.5,"Ghost crosses closed gate; ordinary pursuer detours")
	check(o.move_actor(ghost,Vector3(4,0,0),0.6)==Vector3(4,0,0),"Ghost phases through solid castle wall")
	ghost.position=Vector3(8,0,8)
	check(not o.occupied(o.gates[3].rect),"Ghost does not block gate closure")
	for i in range(10): game.spawn_enemy(14)
	var ghosts:=0
	for e in get_nodes_in_group("all_enemies"):
		if e.kind==14: ghosts+=1
	check(ghosts==3,"Ghost limit is three and uses ordinary special budget")
	check(game.director.waves[5].new.has(14),"Ghost debuts in wave six")
	game.free()
	await process_frame
	print("UPGRADE/UDON/GHOST TEST: %d failure(s)"%failures)
	quit(1 if failures else 0)
