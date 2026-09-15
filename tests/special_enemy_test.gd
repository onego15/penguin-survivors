extends SceneTree
var game: Node3D
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+caption)
	if not ok: failures+=1
func enemy(kind: int, point := Vector3(0,0,-8)) -> Node3D:
	var node=game.spawn_enemy(kind)
	node.set_physics_process(false)
	node.position=point
	return node
func clean() -> void:
	for actor in game.actors.get_children():
		if actor!=game.player: actor.free()
	game.player.health=100
	game.player.invulnerability=0
	game.player.position=Vector3.ZERO
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=300
	var owl=enemy(4)
	owl.cooldown=0
	owl._physics_process(0.01)
	check(owl.special_state=="warn" and owl.timer==0.9,"Owl telegraphs a shot at eight metres")
	game.player.position.x=5
	owl._physics_process(1)
	var bolt=get_nodes_in_group("regular_projectiles")[0]
	check(absf(bolt.direction.x)<0.01 and bolt.damage==12,"Owl locks its aim and uses time-scaled damage")
	clean()
	var wolf=enemy(5,Vector3(0,0,-5))
	wolf._physics_process(0.1)
	check(absf(wolf.position.x)>0.05,"Wolf flanks rather than simply pursuing")
	wolf.cooldown=0
	wolf._physics_process(0.01)
	game.player.position.x=8
	wolf._physics_process(0.81)
	wolf._physics_process(0.51)
	check(wolf.special_state=="move" and game.player.health==100,"Wolf never charges even after its former attack cooldown")
	clean()
	var skunk=enemy(6,Vector3.ZERO)
	game.player.position.x=6
	for i in range(10):
		skunk.cooldown=0
		skunk._physics_process(0)
	check(get_nodes_in_group("enemy_clouds").size()==6,"Cloud count is bounded at six")
	var cloud=get_nodes_in_group("enemy_clouds")[0]
	game.player.position=Vector3.ZERO
	cloud._physics_process(0.01)
	var hp: int=game.player.health
	cloud._physics_process(0.01)
	check(hp<100 and game.player.health==hp,"Cloud damage obeys shared invulnerability")
	cloud._physics_process(3)
	check(cloud.is_queued_for_deletion(),"Cloud expires after three seconds")
	clean()
	var hedgehog=enemy(7)
	for i in range(5):
		hedgehog.cooldown=0
		hedgehog._physics_process(0)
		check(hedgehog.special_state=="warn","Hedgehog warns before its burst")
		hedgehog._physics_process(1.01)
	check(get_nodes_in_group("regular_projectiles").size()==32,"Eight-way needle bursts respect the global 32-shot limit")
	clean()
	var mole=enemy(8)
	mole.cooldown=0
	mole._physics_process(0.01)
	check(mole.special_state=="dig" and mole.targetable and mole.model.visible,"Mole visibly digs while still targetable")
	mole.take_damage(1)
	mole._physics_process(0.2)
	check(mole.model.position.y<0 and mole.targetable,"Mole sinks during its 0.4 second vulnerable transition")
	mole._physics_process(0.2)
	check(mole.special_state=="warn" and mole.timer==1.2,"Full burrowing starts a fresh 1.2 second warning")
	var hp_before: int=mole.health
	mole.take_damage(99)
	check(not mole.targetable and not mole.is_in_group("enemies") and mole.is_in_group("all_enemies") and mole.health==hp_before and game.armory.nearest(Vector3.ZERO,12)==null,"Buried mole remains counted but cannot be targeted or damaged")
	game.player.position=Vector3(15,0,15)
	mole._physics_process(1.21)
	check(mole.targetable and mole.timer==2 and game.player.health==100,"Mole emerges at its locked marker and is exposed for two seconds")
	mole.take_damage(1)
	check(mole.health==hp_before-1,"Emerging mole can be damaged again")
	clean()
	var deer1=enemy(9,Vector3(2,0,0))
	var deer2=enemy(9,Vector3(-2,0,0))
	var fox=enemy(0,Vector3.ZERO)
	check(not fox.has_method("aura_multiplier") and get_nodes_in_group("deer_aura").is_empty(),"Deer no longer applies any movement aura")
	var boss=game.spawn_enemy(-1,true)
	boss.position=Vector3.ZERO
	check(not boss.has_method("aura_multiplier"),"Boss movement has no deer multiplier")
	deer1.position.x=10
	deer2.position.x=-10
	check(not deer1.has_node("ActiveDanger"),"Deer has no surrounding area marker")
	clean()
	var special=enemy(4)
	check(special.max_health==roundi(4*sqrt(game.Difficulty.profile(300).hp)),"Special enemies use square-root HP scaling")
	var xp: int=game.experience
	special.take_damage(999)
	special.take_damage(999)
	check(game.experience==xp+2,"Special enemy reward is two XP exactly once")
	clean()
	var deer=enemy(9)
	xp=game.experience
	deer.take_damage(999)
	check(game.experience==xp+3,"Deer rewards three XP")
	clean()
	var wolves: Array=[]
	for i in range(4):
		var node=enemy(5,Vector3(i-1,0,-6))
		node.cooldown=0
		node._physics_process(0.01)
		wolves.append(node)
	var warning_count:=0
	for node in wolves:
		if node.special_state in ["warn","dig"]: warning_count+=1
	check(warning_count==0,"Wolves never enter a telegraphed charge")
	clean()
	for i in range(3):
		var node=enemy(8,Vector3(i,0,-6))
		node.cooldown=0
		node._physics_process(0.01)
	warning_count=0
	for node in get_nodes_in_group("all_enemies"):
		if node.special_state in ["warn","dig"]: warning_count+=1
	check(warning_count==1,"Only one mole can mark an emergence simultaneously")
	clean()
	wolf=enemy(5,Vector3(0,0,-4.5))
	var initial_distance: float=wolf.position.length()
	for i in range(120): wolf._physics_process(0.01)
	check(wolf.position.length()<initial_distance-0.5,"Circling wolf closes on a stationary player")
	wolf.position=Vector3(22.99,0,0)
	game.player.position=Vector3(22.99,0,4)
	wolf.flank_side=-1
	wolf._physics_process(0.1)
	check(wolf.flank_side==1,"Wolf reverses its flank at the arena edge")
	print("SPECIAL ENEMY TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
