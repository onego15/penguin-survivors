extends SceneTree
var game: Node3D
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+caption)
	if not ok: failures+=1
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.elapsed=420
	var deer=game.spawn_enemy(9)
	deer.set_physics_process(false)
	deer.position=Vector3.ZERO
	game.player.position=Vector3(0,0,3)
	deer.cooldown=0
	deer._physics_process(0)
	check(deer.special_state=="warn" and deer.timer==1.2 and deer.warning.visible,"Deer warns for 1.2 seconds within 12m")
	var start: Vector3=deer.position
	game.player.position=Vector3(3,0,0)
	deer._physics_process(0.5)
	check(deer.position==start and deer.locked==Vector3.BACK,"Deer stands still and locks its attack direction")
	check(deer.antlers_contain(Vector3(0,0,2.9)) and not deer.antlers_contain(Vector3(3,0,0)) and not deer.antlers_contain(Vector3(0,0,-2)),"Only the forward lane is dangerous; sides and rear are safe")
	check(not deer.antlers_contain(Vector3(0,0,14.5)),"Antler attack respects range including player radius")
	deer._physics_process(0.7)
	check(game.player.health==100 and deer.special_state=="recover" and deer.timer==1.2,"Side dodge avoids damage and opens a 1.2s recovery")
	deer._physics_process(1.2)
	check(deer.special_state=="move" and deer.cooldown==4,"Recovery is followed by a separate four-second cooldown")
	game.player.position=Vector3(0,0,2)
	game.player.invulnerability=0
	game.player.support_damage_multiplier=0.7
	deer.cooldown=0
	deer._physics_process(0)
	deer._physics_process(1.2)
	for shot in get_nodes_in_group("regular_projectiles"):
		shot.set_physics_process(false)
		shot._physics_process(0.5)
	var expected:=ceili(roundi(12*deer.damage_multiplier)*0.7)
	check(game.player.health==100-expected,"Antler hit uses time scaling and common bear reduction")
	game.player.invulnerability=0
	deer._physics_process(0.1)
	check(game.player.health==100-expected,"The shockwave damages only once")
	deer.free()
	var mole=game.spawn_enemy(8)
	mole.set_physics_process(false)
	var direct:=0
	var samples:=4000
	var radius_squared_sum:=0.0
	var valid:=true
	var quadrants: Array[int]=[0,0,0,0]
	for seed_value in range(20):
		game.rng.seed=seed_value
		for i in range(samples/20):
			var point: Vector3=mole.sample_landing(Vector3.ZERO)
			if point==Vector3.ZERO: direct+=1
			else:
				valid=valid and point.length()>=1.5 and point.length()<=4
				radius_squared_sum+=point.length_squared()
				quadrants[(1 if point.x>0 else 0)+(2 if point.z>0 else 0)]+=1
	check(valid and direct>samples*0.17 and direct<samples*0.23,"Twenty seeds yield approximately 20% direct and 80% annulus landings")
	check(absf(radius_squared_sum/(samples-direct)-9.125)<0.5 and quadrants.min()>650,"Annulus sampling is uniform in area and covers all directions")
	for center in [Vector3(23,0,23),Vector3(-23,0,-23),Vector3(23,0,0)]:
		for i in range(200):
			var point: Vector3=mole.sample_landing(center)
			valid=valid and absf(point.x)<=23 and absf(point.z)<=23
	check(valid,"Boundary samples remain inside the arena")
	game.rng.seed=321
	var replay: Vector3=mole.sample_landing(Vector3.ZERO)
	game.rng.seed=321
	check(replay==mole.sample_landing(Vector3.ZERO),"Landing selection is reproducible through the game's RNG")
	game.player.position=Vector3.ZERO
	mole.cooldown=0
	mole._physics_process(0)
	mole._physics_process(0.4)
	var locked: Vector3=mole.landing
	game.player.position=Vector3(15,0,15)
	mole._physics_process(0.6)
	check(mole.landing==locked,"A marked landing never follows subsequent player movement")
	for pair in [[1,12],[2,22],[5,65],[8,132],[10,190]]:
		check(game.Difficulty.xp_for_level(pair[0])==pair[1],"XP threshold level %d = %d" % pair)
	var old_level:=1
	var new_level:=1
	var old_xp:=0
	var new_xp:=0
	for reward in range(900):
		old_xp+=1
		new_xp+=1
		var n:=old_level-1
		if old_xp>=12+8*n+2*n*n:
			old_xp-=12+8*n+2*n*n
			old_level+=1
		if new_xp>=game.Difficulty.xp_for_level(new_level):
			new_xp-=game.Difficulty.xp_for_level(new_level)
			new_level+=1
	check(new_level>old_level,"The same 900 XP reward stream yields more weapon choices")
	print("XP COMPARISON: old choices=%d new choices=%d" % [old_level-1,new_level-1])
	var friend=game.support.spawn_friend(1,Vector3(7,0,0))
	game.support.notice.refresh(0)
	var rect: Rect2=game.support.notice.card_rect
	check(rect.position==Vector2(920,16) and rect.size==Vector2(344,112),"Support occupies only the top-right 344x112 card")
	check(game.boss_bar.position.x+game.boss_bar.size.x<rect.position.x,"Boss HUD ends before the support card")
	game.support.notice.refresh(4.1)
	check(game.support.notice.banner.visible and friend.state=="waiting","Support details persist after the arrival highlight ends")
	game.queue_free()
	await create_timer(0.3).timeout
	print("DEER/GROWTH TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
