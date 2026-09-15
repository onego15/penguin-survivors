extends SceneTree
var failures:=0
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	var u=game.ultimate
	check(u.charge==0 and not u.activate(),"Empty start")
	u.reward(199)
	check(not u.activate(),"Requires 200 reward XP")
	u.reward(100)
	check(u.charge==200,"Full gauge discards overflow")
	var near=game.spawn_enemy(0)
	near.position=Vector3(4,0,0)
	var far=game.spawn_enemy(0)
	far.position=Vector3(15,0,0)
	var mole=game.spawn_enemy(8)
	mole.position=Vector3(3,0,0)
	mole.remove_from_group("enemies")
	var cloud=preload("res://scripts/enemy_cloud.gd").new()
	game.actors.add_child(cloud)
	var xp: int=game.experience
	check(u.activate(),"Ready activation")
	check(near.dead and not far.dead and not mole.dead,"Range and underground exclusion")
	check(game.experience==xp+1 and u.charge==1 and u.uses==1,"Kills grant XP and next gauge")
	check(cloud.is_queued_for_deletion() and not cloud.visible,"Cloud immediately disabled")
	check(game.player.invulnerability>=1,"One second immunity")
	var attack=preload("res://scripts/weapon_attack.gd").new()
	attack.mode="nova"
	attack.visual_kind="chime"
	attack.lifetime=0.65
	attack.damage=2
	attack.player=game.player
	game.actors.add_child(attack)
	var cold=attack.flourish
	check(cold.mist.size()==12 and cold.pieces.size()==16,"Chime fixed geometry")
	attack._physics_process(0.65)
	check(attack.is_queued_for_deletion() and cold.get_parent()==game.actors and cold.auto_lifetime==0.9,"Chime damage ends at 0.65, visual detaches until 0.9")
	cold._physics_process(0.25)
	check(cold.is_queued_for_deletion(),"Cosmetic tail expires without damage")
	u.reward(200)
	for state in ["dead","victory","boss_intro","phase_transition"]:
		game.run_state=state
		check(not u.activate(),"Blocked in "+state)
	game.run_state="combat"
	paused=true
	check(not u.activate(),"Paused activation blocked")
	paused=false
	game.player.health=0
	check(not u.activate(),"Death priority")
	game.player.health=100
	u.activate()
	u.reward(200)
	u.activate()
	u.reward(200)
	check(u.uses==3 and u.charge==0 and not u.activate(),"Three use ceiling")
	var wolf=preload("res://scripts/special_enemy.gd").new()
	wolf.kind=5
	wolf.target=game.player
	game.actors.add_child(wolf)
	check(wolf.health==4 and wolf.contact_damage==12,"Wolf HP unchanged and contact strengthened")
	wolf.position=Vector3(0,0,-4)
	wolf.speed=2
	wolf.flank_side=1
	var before: Vector3=wolf.position
	wolf._physics_process(0.01)
	var movement: Vector3=(wolf.position-before)/0.01
	check(absf(movement.length()-2.6)<0.01 and absf(movement.z/absf(movement.x)-0.75/0.85)<0.01,"Wolf speed and approach blend")
	for i in range(2): game.spawn_enemy(5)
	check(not game.director.below_cap(5),"Early wolf cap three")
	game.elapsed=360
	check(game.director.below_cap(5),"Late wolf cap expands")
	for i in range(2): game.spawn_enemy(5)
	check(not game.director.below_cap(5),"Late wolf cap five")
	game.elapsed=600
	game._start_final_boss()
	game._finish_presentation()
	var boss=game.active_boss
	boss.health=750
	u.uses=0
	u.charge=200
	boss.position=Vector3(5,0,0)
	check(u.activate() and game.run_state=="phase_transition" and boss.health==650,"Ultimate triggers phase transition after resolving targets")
	game._finish_presentation()
	boss.health=50
	u.reward(200)
	check(u.activate() and game.final_boss_defeated,"Ultimate can defeat final boss")
	game.queue_free()
	await process_frame
	print("ULTIMATE TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
