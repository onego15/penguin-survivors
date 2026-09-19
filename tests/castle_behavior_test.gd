extends SceneTree
var failures:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run() -> void:
	preload("res://scripts/stage_catalog.gd").selected_id="castle"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.invulnerability=999
	var raccoon=game.spawn_enemy(11)
	raccoon.set_physics_process(false)
	raccoon.position=Vector3(0,0,-5)
	raccoon.cooldown=0
	raccoon._physics_process(0)
	var bomb=get_nodes_in_group("castle_bombs")[0]
	bomb.set_physics_process(false)
	check(is_equal_approx(raccoon.cooldown,6) and bomb.position==Vector3.ZERO,"Raccoon locks landing point and six-second cooldown")
	game.player.position=Vector3(0,0,4)
	bomb._physics_process(1.49)
	check(bomb.warning.visible and not bomb.active.visible and bomb.position==Vector3.ZERO,"Bomb telegraphs for 1.5 seconds without following")
	game.player.position=Vector3.ZERO
	game.player.invulnerability=0
	bomb._physics_process(0.02)
	check(game.player.health==100-roundi(12*raccoon.damage_multiplier) and bomb.active.visible,"Ice bomb applies time-scaled twelve base damage")
	game.player.invulnerability=0
	bomb._physics_process(0.1)
	check(game.player.health==100-roundi(12*raccoon.damage_multiplier),"Ice bomb does not repeat damage")
	bomb.free()
	raccoon.free()
	var blocked=load("res://scripts/castle_bomb.gd").new()
	blocked.position=Vector3(10,0,0)
	blocked.origin=Vector3(5,0,0)
	blocked.target=game.player
	game.actors.add_child(blocked)
	blocked._physics_process(2)
	check(blocked.is_queued_for_deletion() and not blocked.visible,"Wall fizzles bomb even across a low-FPS impact step")
	blocked.free()
	game.player.invulnerability=999
	var ermine=game.spawn_enemy(12)
	ermine.set_physics_process(false)
	ermine.position=Vector3(0,0,-4)
	ermine.cooldown=0
	ermine._physics_process(0)
	var start: Vector3=ermine.position
	check(is_equal_approx(ermine.warning_left,0.6),"Ermine warns before lateral leap")
	ermine._physics_process(0.6)
	ermine._physics_process(0.35)
	check(absf(ermine.position.x-start.x)>1.49 and absf(ermine.position.z-start.z)<0.01,"Ermine leaps 1.5 metres sideways")
	check(ermine.contact_damage==roundi(10*ermine.damage_multiplier) and is_equal_approx(ermine.cooldown,4),"Ermine has no extra leap damage")
	ermine.free()
	game.player.position=Vector3(11,0,0)
	var goat=game.spawn_enemy(13)
	goat.set_physics_process(false)
	goat.position=Vector3(5,0,0)
	goat.cooldown=0
	goat._physics_process(0)
	var locked: Vector3=goat.locked
	game.player.position=Vector3(11,0,3)
	goat._physics_process(1)
	goat._physics_process(1)
	check(goat.locked==locked and goat.position.x<6.71,"Goat locks charge direction and stops at wall")
	check(goat.dash_left==0 and is_equal_approx(goat.rest,1.2) and goat.cooldown==4,"Goat rests after collision")
	goat.free()
	# Sample every boundary and both gate diagonals for reachable escape routes.
	game.elapsed=600
	game._start_final_boss()
	game._finish_presentation()
	var boss=game.active_boss
	boss.set_physics_process(false)
	boss.enraged=true
	var escapable:=true
	for p in [Vector3.ZERO,Vector3(21,0,21),Vector3(-21,0,21),Vector3(0,0,-21),Vector3(6,0,7),Vector3(-10,0,-7)]:
		game.player.position=p
		boss.position=Vector3(0,0,-6)
		boss.attack_index=3
		boss.warning_left=0
		var started: bool=boss.begin_attack()
		if started and not boss.safe_escape(): escapable=false
	check(escapable,"Ice-ring patterns have an escape or postpone at corners and gates")
	boss.cancel_attacks()
	game.player.position=Vector3.ZERO
	boss.position=Vector3(0,0,-6)
	boss.attack_index=2
	boss.begin_attack()
	boss.release()
	check(get_nodes_in_group("hostile_projectiles").size()==7,"Second form emits seven ice feathers")
	game.sound.set_track("noctis")
	game.sound.set_track("noctis_phase2")
	check(game.sound.fade_left==0.8 and game.sound.clips.noctis.get_length()==48 and game.sound.clips.noctis_phase2.get_length()==48,"Noctis arrangements crossfade with aligned loops")
	game.free()
	await process_frame
	# Selection persists, but run progression does not.
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	check(title.stage_buttons[1].button_pressed,"Title retains castle selection")
	title.select_character("pink")
	title.free()
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	check(game.stage_id=="castle" and game.level==1 and game.kills==0 and game.armory.levels=={"heart":1},"New castle run resets progression and uses selected starter")
	game.free()
	await process_frame
	print("CASTLE BEHAVIOR TEST: %d failure(s)"%failures)
	quit(1 if failures else 0)
