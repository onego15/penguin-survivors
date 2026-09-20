extends SceneTree
const Catalog=preload("res://scripts/weapon_catalog.gd")
const Attack=preload("res://scripts/control_attack.gd")
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func actor(kind: int, point: Vector3) -> Node3D:
	var enemy=game.spawn_enemy(kind)
	enemy.position=point
	enemy.health=100
	enemy.max_health=100
	enemy.set_physics_process(false)
	return enemy
func setup(stage: String) -> void:
	preload("res://scripts/stage_catalog.gd").selected_id=stage
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
func shot(mode: String, point: Vector3, direction: Vector3, rank:=1) -> Node3D:
	var attack:=Attack.new()
	attack.mode=mode
	attack.stats=Catalog.stats(mode,rank)
	attack.direction=direction
	attack.position=point
	game.actors.add_child(attack)
	attack.set_physics_process(false)
	return attack
func clear_actors() -> void:
	for enemy in get_nodes_in_group("all_enemies"): enemy.free()
	for attack in get_nodes_in_group("weapon_attacks"): attack.free()
func run() -> void:
	setup("snowfield")
	var sea_a=actor(15,Vector3(10,0,10))
	var sea_b=actor(15,Vector3(12,0,10))
	var sea_mesh=sea_a.model.get_node("SculptedSurface")
	var sea_original=sea_mesh.material_override
	sea_a.apply_control("freeze",1)
	check(not sea_mesh.material_override.vertex_color_use_as_albedo and sea_b.model.get_node("SculptedSurface").material_override==sea_original,"Baked sea model freezes without tinting cached sibling")
	sea_a.control.step(1.1)
	check(sea_mesh.material_override==sea_original and sea_original.vertex_color_use_as_albedo,"Thaw restores baked sea colors")
	clear_actors()
	check(Catalog.ITEMS.size()==26,"Both control weapons in mixed pool")
	for rank in range(1,6):
		check(is_equal_approx(Catalog.stats("gust",rank).cooldown,[3.0,2.85,2.7,2.55,2.4][rank-1]),"Fan hit interval rank %d"%rank)
	check(Catalog.ITEMS.gust.cooldown==Catalog.stats("gust",1).cooldown,"Fan catalog matches first rank")
	check(Catalog.stats("gust",5).damage==3 and Catalog.stats("gust",5).knockback==4.5 and Catalog.stats("popsicle",5).freeze==1.4,"Dedicated capped low damage curves")
	var front=actor(0,Vector3(0,0,3))
	var side=actor(0,Vector3(3,0,0))
	var far=actor(0,Vector3(0,0,8))
	var wind=shot("gust",Vector3.ZERO,Vector3.BACK)
	check(front.health==99 and side.health==100 and far.health==100,"Wind cone hits once, excludes side and far targets")
	game.player.position=Vector3(10,0,0)
	front._physics_process(0.6)
	check(front.position.is_equal_approx(Vector3(0,0,6)) and front.health==99,"Push travels exactly three metres without extra damage")
	check(not front.apply_control("knockback",3,Vector3.RIGHT),"Push reapplication blocked")
	front.control.step(0.61)
	check(front.apply_control("knockback",3,Vector3.RIGHT),"Push resistance expires")
	wind._physics_process(0.9)
	check(not wind.is_queued_for_deletion(),"Wind remains continuously active")
	clear_actors()
	game.player.position=Vector3.ZERO
	game.player.body.rotation.y=0
	game.armory.acquire("gust")
	game.armory.fire("gust")
	var continuous=game.armory.gust_attack
	continuous.set_physics_process(false)
	var first_id: int=continuous.get_instance_id()
	for i in range(20): game.armory.tick(0.1)
	check(game.armory.gust_attack.get_instance_id()==first_id,"One persistent fan, no repeated creation")
	continuous._physics_process(1.0)
	check(is_equal_approx(continuous.direction.x,sin(deg_to_rad(45))),"Fan swings to one side")
	continuous._physics_process(2.0)
	check(is_equal_approx(continuous.direction.x,-sin(deg_to_rad(45))),"Fan swings to opposite side")
	game.player.position=Vector3(2,0,1)
	continuous._physics_process(0)
	check(continuous.position==game.player.position,"Wind follows moving player")
	var target=actor(0,game.player.position+continuous.direction*3)
	continuous._physics_process(0)
	check(target.health==99,"Moving cone damages enemy")
	continuous._physics_process(0)
	check(target.health==99,"Persistent cone does not deal damage each frame")
	continuous.age+=2.6
	continuous.update_wind()
	target.position=game.player.position+continuous.direction*3
	continuous.update_wind()
	check(target.health==99,"Old 2.6 second interval cannot trigger another wind hit")
	continuous.age+=0.4
	continuous.update_wind()
	target.position=game.player.position+continuous.direction*3
	continuous.update_wind()
	check(target.health==98,"Per-enemy damage interval expires")
	game.armory.levels.gust=5
	game.armory.fire("gust"); continuous.update_wind()
	check(continuous.stats.reach==8 and continuous.wind_boundary.scale.x>1,"Upgrade expands live cone and boundary")
	continuous.set_physics_process(true)
	var frozen_age: float=continuous.age
	paused=true
	await create_timer(0.05,true).timeout
	check(continuous.age==frozen_age,"Pause freezes oscillation")
	paused=false
	clear_actors()
	game.player.position=Vector3.ZERO
	var victim=actor(0,Vector3(0,0,5))
	var nearby=actor(0,Vector3(1.2,0,5))
	var rear=actor(0,Vector3(0,0,-3))
	var original_mesh: MeshInstance3D
	for child in victim.model.get_children():
		if child is MeshInstance3D: original_mesh=child; break
	var original_material=original_mesh.material_override
	var ice=shot("popsicle",Vector3.UP,Vector3.BACK)
	ice._physics_process(1.0)
	check(ice.exploded and victim.health==99 and nearby.health==99 and rear.health==100,"Low FPS earliest hit bursts once and ignores enemies behind flight")
	check(victim.control.frozen==1 and nearby.control.frozen==1,"Burst freezes neighbours")
	check(original_mesh.material_override!=original_material and victim.control.body_iced,"Frozen body uses separate icy materials")
	var unfrozen=actor(0,Vector3(-5,0,-5))
	var shared_original_found:=false
	for child in unfrozen.model.get_children():
		if child is MeshInstance3D and child.material_override==original_material: shared_original_found=true
	check(shared_original_found,"Frozen palette does not mutate other enemies")
	victim.position=Vector3(0,0,0.3)
	var hp: int=game.player.health
	var old_age: float=victim.age
	victim._physics_process(0.4)
	check(victim.age==old_age and victim.position==Vector3(0,0,0.3) and game.player.health==hp,"Frozen actor movement, AI clock and contact stop")
	victim.take_damage(2)
	check(victim.health==97 and not victim.apply_control("freeze",1.4),"Damage does not thaw and repeated freeze cannot extend")
	victim.apply_control("knockback",2,Vector3.RIGHT)
	victim._physics_process(0.25)
	check(victim.position.x>0.8 and victim.control.frozen>0,"Frozen actor can still be pushed")
	victim.control.step(0.36)
	check(victim.control.frozen==0 and not victim.apply_control("freeze",1),"Thaw starts two second immunity")
	check(original_mesh.material_override==original_material,"Thaw restores exact original material")
	victim.control.step(2.0)
	check(victim.apply_control("freeze",1),"Freeze can apply after immunity expires")
	victim.set_physics_process(true)
	paused=true
	await create_timer(0.1,true).timeout
	check(victim.control.frozen==1,"Weapon menu pause stops status timer")
	paused=false
	game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	await create_timer(0.1).timeout
	check(victim.control.frozen==1,"Cinematic actor suspension stops status timer")
	game.actors.process_mode=Node.PROCESS_MODE_INHERIT
	victim.set_physics_process(false)
	clear_actors()
	var boar=actor(2,Vector3(0,0,4))
	boar.charge_state=boar.ChargeState.CHARGE
	boar.apply_control("freeze",1)
	check(boar.charge_state==boar.ChargeState.APPROACH and not boar.charge_marker.visible,"Freeze cancels boar charge and warning")
	var mole=actor(8,Vector3(3,0,4))
	mole.special_state="dig"
	mole.model.position.y=-0.5
	mole.apply_control("freeze",1)
	check(mole.special_state=="move" and mole.model.position.y==0 and mole.targetable,"Digging mole returns above ground")
	mole.targetable=false
	check(not mole.apply_control("knockback",2,Vector3.RIGHT),"Underground mole excludes control")
	var owl=actor(4,Vector3(-3,0,4))
	owl._begin_warning(0.9)
	owl.apply_control("knockback",2,Vector3.BACK)
	check(owl.special_state=="move" and not owl.warning.visible,"Pending ranged warning cancelled")
	boar.is_miniboss=true
	check(not boar.apply_control("freeze",1) and not boar.apply_control("knockback",2,Vector3.BACK),"Miniboss immunity")
	var boss=preload("res://scripts/final_boss.gd").new()
	boss.target=game.player
	game.actors.add_child(boss)
	boss.set_physics_process(false)
	check(not boss.apply_control("freeze",1),"Final boss immune")
	var minion=preload("res://scripts/boss_minion.gd").new()
	minion.target=game.player
	game.actors.add_child(minion)
	minion.set_physics_process(false)
	check(minion.apply_control("freeze",1),"Final minions remain vulnerable")
	clear_actors()
	var lethal=actor(0,Vector3(0,0,2))
	lethal.health=1
	var kills: int=game.kills
	shot("gust",Vector3.ZERO,Vector3.BACK)
	check(lethal.dead and game.kills==kills+1 and not is_instance_valid(lethal.control),"Lethal damage rewards once without applying status")
	game.free()
	await process_frame
	setup("castle")
	var gate=game.obstacles.gates[3]
	gate.state="closed"
	var normal=actor(0,Vector3(6,0,8))
	var ghost=actor(14,Vector3(6,0,8))
	normal.apply_control("knockback",3,Vector3.RIGHT)
	ghost.apply_control("knockback",3,Vector3.RIGHT)
	normal._physics_process(0.6)
	ghost._physics_process(0.6)
	check(normal.position.x<7 and ghost.position.x>8.9,"Closed gate blocks ordinary push but not ghost")
	ghost.control.step(0.61)
	ghost.position=Vector3(6,0,0)
	ghost.apply_control("knockback",3,Vector3.RIGHT)
	ghost._physics_process(0.6)
	check(ghost.position.x>8.9,"Ghost pushes through solid wall")
	clear_actors()
	var beyond=actor(0,Vector3(10,0,0))
	var blocked=shot("popsicle",Vector3(6,1,0),Vector3.RIGHT)
	blocked._physics_process(1)
	check(blocked.is_queued_for_deletion() and not blocked.exploded and beyond.health==100,"Wall destroys ice projectile without burst")
	var goat=actor(13,Vector3.ZERO)
	goat.warning_left=1
	goat.dash_left=0.5
	goat.apply_control("freeze",1)
	check(goat.warning_left==0 and goat.dash_left==0,"Castle dash and warning cancelled")
	var edge=actor(0,Vector3(22,0,20))
	edge.apply_control("knockback",3,Vector3.RIGHT)
	edge._physics_process(0.6)
	check(edge.position.x<=23-edge.hit_radius+0.00001,"Push respects arena boundary with actor radius")
	clear_actors()
	var empty=shot("popsicle",Vector3(0,1,-20),Vector3.BACK)
	empty._physics_process(2)
	check(empty.is_queued_for_deletion() and not empty.exploded and is_equal_approx(empty.position.z,-8),"Ice expires at exact range without bursting")
	var victim2=actor(0,Vector3(0,0,2))
	victim2.apply_control("freeze",1)
	game.player.health=0
	game._physics_process(0.01)
	check(game.game_over and not is_instance_valid(victim2.control),"Player death clears all control state and visuals")
	check(game.sound.clips.has("gust") and game.sound.clips.has("ice_cast") and game.sound.clips.has("ice_break"),"Dedicated SFX loaded through shared mute bus")
	game.free()
	await process_frame
	print("CONTROL WEAPONS TEST: %d failure(s)"%failures)
	quit(1 if failures else 0)
