extends SceneTree
var failures := 0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func enemy(kind: int, at: Vector3) -> Node3D:
	var e=game.create_enemy({"type":"normal","index":kind},at,0)
	e.set_physics_process(false)
	return e
func run() -> void:
	game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	game.settings.weapons={}; game.rebuild_player(); game.player.set_physics_process(false)
	game.player.invulnerability=999
	var turtle=enemy(3,Vector3(0,0,6))
	check(turtle.health==6,"Turtle base HP six")
	turtle._physics_process(4.0)
	check(turtle.shell_phase=="prepare","Turtle prepares at four seconds")
	turtle._physics_process(0.5)
	var hp: int=turtle.health
	turtle.take_damage(3)
	check(turtle.health==hp-2 and turtle.shell_phase=="guard","Shell halves damage rounding upward")
	var p: Vector3=turtle.position
	turtle._physics_process(0.5)
	check(turtle.position==p,"Shell stops movement")
	turtle.apply_control("freeze",1.0)
	check(turtle.shell_phase=="move","Control cancels shell")
	turtle.free()
	for tier in ["easy","normal","hard","expert"]:
		game.settings.difficulty=tier
		for speed in [1.65,2.9]:
			var boar=enemy(2,Vector3(0,0,5)); boar.speed=speed; boar.state_time=2
			boar._physics_process(0)
			var end: Vector3=boar.charge_end
			check(boar.charge_marker.global_position.distance_to((boar.global_position+end)*0.5+Vector3.UP*0.09)<0.01,"Boar marker midpoint matches locked segment")
			boar._physics_process(0.8); boar._physics_process(1.0)
			check(boar.position.distance_to(end)<0.01,"Low FPS charge ends at warning endpoint")
			boar.free()
	var ermine=enemy(12,Vector3(0,0,4)); ermine.cooldown=0
	ermine._physics_process(0); var locked: Vector3=ermine.action_end
	game.player.position=Vector3(3,0,0)
	ermine._physics_process(0.6); ermine._physics_process(0.35)
	check(ermine.position.distance_to(locked)<0.01 and is_equal_approx(ermine.rest,0.35),"Ermine fixed diagonal leap and recovery")
	ermine.free(); game.player.position=Vector3.ZERO
	var goat=enemy(13,Vector3(0,0,4)); goat.cooldown=0
	goat._physics_process(0); goat._physics_process(1); goat._physics_process(1)
	check(goat.position.length()<0.01 and is_equal_approx(goat.rest,1.2),"Goat four metre headbutt")
	goat.free()
	game.switch_terrain(true)
	var wall_boar=enemy(2,Vector3(5,0,0)); game.player.position=Vector3(10,0,0); wall_boar.state_time=2
	wall_boar._physics_process(0); var end: Vector3=wall_boar.charge_end
	wall_boar._physics_process(0.8); wall_boar._physics_process(1)
	check(wall_boar.position.distance_to(end)<0.02 and end.x<7,"Wall clips boar warning and charge")
	wall_boar.free(); game.player.position=Vector3.ZERO
	var silk: Node3D
	silk=load("res://scripts/castle_miniboss.gd").new(); silk.encounter=2; silk.target=game.player; silk.position=Vector3(0,0,6); game.actors.add_child(silk); silk.set_physics_process(false)
	silk.start_attack(); silk._physics_process(1.2)
	game.player.invulnerability=0; game.player.health=100; game.settings.invincible=false; game.player.training_invincible=false
	silk._physics_process(0.65)
	check(silk.dive_hit and game.player.health<100,"Silk swept dive hits once")
	var health: int=game.player.health; game.player.invulnerability=0; silk._physics_process(0.1)
	check(game.player.health==health and not silk.flash.visible,"Silk has no landing explosion")
	silk.free()

	game.clear_enemies(); game.player.training_invincible=true
	var expected := {"easy":20,"normal":24,"hard":28,"expert":32}
	for tier in expected:
		game.settings.difficulty=tier
		var shell=game.create_enemy({"type":"normal","index":3},Vector3(0,0,6),540)
		shell.set_physics_process(false)
		check(shell.max_health==expected[tier],"Late turtle HP curve, tier "+tier)
		shell._shell_step(5.61)
		check(shell.shell_phase=="release","Shell releases after 1.2 second defense")
		shell._shell_step(0.4)
		check(shell.shell_phase=="move","Shell resumes after two second sequence")
		shell._shell_step(6.0)
		check(shell.shell_phase=="prepare","Shell cycle is eight seconds")
		shell.free()
	game.settings.difficulty="normal"
	var moss=game.create_enemy({"type":"mid","index":1},Vector3(0,0,6),540)
	moss.set_physics_process(false); moss.guard_left=1; moss.take_damage(3)
	check(moss.max_health==180 and moss.health==178,"Mossback retains HP and single half-damage correction")
	moss.free()
	for index in [2,4]:
		var shooter=game.create_enemy({"type":"mid","index":index},Vector3(0,0,-6),0)
		shooter.set_physics_process(false)
		var marker: Node3D
		if index==2:
			shooter.special_cooldown=0; shooter._fox_attack(0); marker=shooter.aim_marker
		else: shooter.start_attack(); marker=shooter.warning
		var directions: Array=[]
		for d in marker.get_meta("shot_directions"): directions.append(marker.global_basis*d)
		if index==2: shooter._fox_attack(0.85)
		else: shooter.release()
		var bolts=get_nodes_in_group("hostile_projectiles")
		var aligned:=bolts.size()==directions.size()
		for i in range(mini(bolts.size(),directions.size())): aligned=aligned and bolts[i].direction.distance_to(directions[i])<0.01
		check(aligned,"Fan warning rays match all emitted shots: "+str(index))
		game.clear_enemies()
	game.free(); await process_frame
	print("ENEMY REFRESH TEST: %d failures" % failures); quit(1 if failures else 0)
