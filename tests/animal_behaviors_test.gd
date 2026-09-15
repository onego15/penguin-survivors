extends SceneTree

var failures := 0
var game: Node3D


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		push_error("FAIL: " + description)
		failures += 1


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.rng.seed = 4567
	await frames(2)
	var seen := {}
	for index in range(4):
		var sample = game.spawn_enemy()
		seen[sample.kind] = true
		sample.free()
	check(seen.size() == 4, "Spawn cycle includes all four animals")
	var fox = game.spawn_enemy(0)
	fox.position = Vector3(0, 0, -12)
	fox.movement_phase = 0.0
	fox.speed = 2.3
	var left := false
	var right := false
	var previous: Vector3 = fox.position
	for index in range(100):
		await frames(1)
		var shift: float = fox.position.x - previous.x
		left = left or shift < -0.005
		right = right or shift > 0.005
		previous = fox.position
	check(left and right and fox.position.z > -10, "Fox alternates lateral movement while closing in")
	fox.free()
	var rabbit = game.spawn_enemy(1)
	rabbit.position = Vector3(0, 0, -12)
	rabbit.speed = 2.3
	await frames(18)
	check(rabbit.position.z > -11 and rabbit.model.position.y > 0.5, "Rabbit advances and lifts its body during a hop")
	rabbit.hop_phase = 0.72
	var rest_position: Vector3 = rabbit.position
	await frames(10)
	check(rabbit.position.distance_to(rest_position) < 0.01 and rabbit.model.position.y < 0.01, "Rabbit pauses on the ground between hops")
	rabbit.free()
	var boar = game.spawn_enemy(2)
	boar.position = Vector3(0, 0, -7)
	boar.speed = 2.3
	boar.state_time = 1.3
	await frames(2)
	check(boar.charge_state == 1 and boar.charge_marker.visible, "Boar telegraphs its charge before moving")
	var windup_position: Vector3 = boar.position
	game.player.position.x = 6.0
	await frames(25)
	check(boar.position.distance_to(windup_position) < 0.01, "Boar remains still during the warning")
	await frames(35)
	check(boar.charge_state == 2 and not boar.charge_marker.visible and boar.position.z > -5.5, "Boar transitions from warning to a fast charge")
	check(absf(boar.position.x) < 0.01, "Charge direction stays locked when player dodges sideways")
	await frames(47)
	check(boar.charge_state == 3, "Boar recovers after charging")
	var recovery_position: Vector3 = boar.position
	await frames(15)
	check(boar.position.distance_to(recovery_position) < 0.01, "Recovery creates a stationary opening")
	await frames(60)
	check(boar.charge_state == 0, "Boar resumes pursuit after recovery")
	boar.free()
	game.player.position = Vector3.ZERO
	var turtle = game.spawn_enemy(3)
	turtle.position = Vector3(0, 0, -12)
	turtle.speed = 2.3
	await frames(30)
	var turtle_distance: float = turtle.position.z + 12.0
	check(turtle_distance > 0.4 and turtle_distance < 0.7 and turtle.health == 8, "Turtle is slow and has eight-hit durability")
	turtle.set_physics_process(false)
	turtle.position = Vector3(0, 0, -3)
	var bullet = load("res://scripts/projectile.gd").new()
	bullet.position = Vector3(0.93, 1.0, -5)
	bullet.direction = Vector3.BACK
	game.actors.add_child(bullet)
	await frames(15)
	check(turtle.health == 7, "Projectile respects the turtle's larger hit radius")
	turtle.take_damage(5)
	check(not turtle.dead and turtle.health == 2 and turtle.health_bar.visible, "Shell survives repeated hits and displays remaining health")
	var old_kills: int = game.kills
	turtle.take_damage(2)
	turtle.take_damage(2)
	check(turtle.dead and game.kills == old_kills + 1, "Lethal hit counts each animal only once")
	await frames(40)
	var effect_count := 0
	for actor in game.actors.get_children():
		if actor.get_script() == load("res://scripts/hit_effect.gd"):
			effect_count += 1
	check(effect_count == 0, "Hit and defeat effects clean themselves up")
	# Assert the shot really originates at the weapon and still hits its selected target.
	var target = game.spawn_enemy(0)
	target.position = Vector3(-4, 0, 0)
	target.set_physics_process(false)
	check(game.fire_at_nearest(), "Weapon can acquire a target on the left")
	var shot: Node3D
	for actor in game.actors.get_children():
		if actor.get_script() == load("res://scripts/projectile.gd"):
			shot = actor
	check(shot != null and shot.position.distance_to(game.player.muzzle_position()) < 0.01 and game.player.recoil > 0.9, "Shot starts at muzzle and triggers recoil")
	await frames(20)
	check(target.health == 1, "Aimed ice bolt reaches the selected target")
	target.free()
	print("ANIMAL BEHAVIORS: %d failure(s)" % failures)
	quit(1 if failures else 0)
