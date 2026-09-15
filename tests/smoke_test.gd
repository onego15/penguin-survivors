extends SceneTree

var failures := 0


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
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.spawn_cooldown = 9999.0
	game.fire_cooldown = 9999.0
	await frames(2)
	var origin: Vector3 = game.player.position
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	var straight_distance: float = game.player.position.distance_to(origin)
	check(straight_distance > 3.0, "D moves player along +X")
	game.player.position = origin
	Input.action_press("move_up")
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_up")
	Input.action_release("move_right")
	check(absf(game.player.position.distance_to(origin) - straight_distance) < 0.3, "Diagonal speed is normalized")
	Input.action_press("move_left")
	Input.action_press("move_down")
	await frames(30)
	Input.action_release("move_left")
	Input.action_release("move_down")
	check(game.player.position.distance_to(origin) < 0.3, "A and S move in opposite directions")
	game.player.position = Vector3(23, 0, 23)
	Input.action_press("move_right")
	Input.action_press("move_down")
	await frames(10)
	Input.action_release("move_right")
	Input.action_release("move_down")
	check(game.player.position.x <= 23.0 and game.player.position.z <= 23.0, "Player stays within arena")
	var edge_enemy = game.spawn_enemy()
	check(edge_enemy != null and edge_enemy.position.distance_to(game.player.position) >= 13.9, "Edge spawn keeps safe distance")
	edge_enemy.free()
	game.player.position = origin
	var quadrants := {}
	for index in range(40):
		var sample = game.spawn_enemy()
		if sample != null:
			quadrants[Vector2(signf(sample.position.x), signf(sample.position.z))] = true
			sample.free()
	check(quadrants.size() == 4, "Enemies spawn around all sides")
	var enemy = game.spawn_enemy(0)
	var before: float = enemy.position.distance_to(game.player.position)
	await frames(30)
	check(enemy.position.distance_to(game.player.position) < before - 0.5, "Enemy pursues player")
	enemy.position = Vector3(4, 0, 0)
	enemy.speed = 0.0
	var farther = game.spawn_enemy(0)
	farther.position = Vector3(0, 0, -8)
	farther.speed = 0.0
	game.fire_cooldown = 0.0
	await frames(45)
	check(not is_instance_valid(enemy), "Auto-fire kills nearest enemy with two hits")
	check(game.kills >= 1, "Defeat increments kill count")
	game.fire_cooldown = 9999.0
	farther.free()
	await frames(100)
	var bullets := 0
	for actor in game.actors.get_children():
		if actor.get_script() == load("res://scripts/projectile.gd"):
			bullets += 1
	check(bullets == 0, "Missed projectiles expire")
	var attacker = game.spawn_enemy(0)
	attacker.position = game.player.position
	await frames(2)
	check(game.player.health == 90, "Enemy contact deals damage")
	await frames(10)
	check(game.player.health == 90, "Damage immunity prevents per-frame damage")
	game.player.invulnerability = 0.0
	game.player.take_damage(100)
	await frames(2)
	check(game.game_over and game.actors.process_mode == Node.PROCESS_MODE_DISABLED, "Death ends gameplay")
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(2)
	check(current_scene != game and current_scene.player.health == 100 and current_scene.kills == 0, "R restarts with fresh state")
	print("SMOKE TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
