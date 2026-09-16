extends SceneTree

var game: Node3D
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, caption: String) -> void:
	if ok:
		print("PASS: " + caption)
	else:
		push_error("FAIL: " + caption)
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
	game.player.set_physics_process(false)
	game.armory.acquire("lightning")
	game.rng.seed = 382
	var valid := true
	for location in [Vector3.ZERO, Vector3(23, 0, 23), Vector3(-23, 0, -23), Vector3(-23, 0, 23)]:
		for zoom in [12.0, 30.0]:
			game.player.position = location
			game.camera.size = zoom
			game._update_camera()
			for sample in range(40):
				var point: Vector3 = game.armory.random_visible_ground()
				var pixel: Vector2 = game.camera.unproject_position(point)
				valid = valid and get_root().get_visible_rect().has_point(pixel) and not game.camera.is_position_behind(point) and absf(point.x) <= 23 and absf(point.z) <= 23 and point.y == 0
	check(valid, "Random strike positions stay on visible ground at both zoom limits and arena corners")
	game.player.position = Vector3.ZERO
	game.camera.size = 20
	game._update_camera()
	game.rng.seed = 662
	var empty_sample: Vector3 = game.armory.random_visible_ground()
	var enemy = game.spawn_enemy(0)
	enemy.set_physics_process(false)
	enemy.position = Vector3(0, 0, 3)
	game.rng.seed = 662
	check(game.armory.random_visible_ground() == empty_sample, "Sampling is independent of enemy positions")
	enemy.free()
	await frames(3)
	check(game.armory.fire("lightning"), "Lightning fires even when no enemies exist")
	var strikes := get_nodes_in_group("weapon_attacks")
	check(strikes.size() == 3 and strikes[0].position != strikes[1].position and strikes[1].position != strikes[2].position, "Each cast schedules three distinct landing points")
	enemy = game.spawn_enemy(0)
	enemy.position = strikes[0].position
	enemy.health = 100
	enemy.max_health = 100
	enemy.set_physics_process(false)
	var expected := 0
	for strike in strikes:
		if strike.position.distance_to(enemy.position) <= 3.0 + enemy.hit_radius:
			expected += 5
	await frames(3)
	check(enemy.health == 100, "Warning circles appear before lightning deals damage")
	game.experience = game.xp_needed
	game.open_weapon_choice()
	var before: float = strikes[0].age
	await frames(5)
	check(strikes[0].age == before and enemy.health == 100, "Weapon selection pauses pending lightning strikes")
	game.choose_weapon(0)
	await frames(45)
	check(enemy.health == 100 - expected, "Each overlapping strike deals five damage exactly once")
	check(get_nodes_in_group("weapon_attacks").is_empty(), "Lightning visuals and warnings expire")
	for actor in game.actors.get_children():
		if actor != game.player:
			actor.free()
	game.director.introduced[2]=true
	game.director.introduced_at[2]=90.0
	var names := {}
	var kinds := {}
	game.player.health = 100
	for encounter in range(4):
		game.elapsed = (encounter + 1) * 120
		game.recovery_until = 0
		game._tick_director(0.01)
		var boss = game.active_boss
		boss.set_physics_process(false)
		names[boss.boss_name] = true
		kinds[boss.kind] = true
		check(boss.max_health == 100 + 80 * encounter, "Boss durability follows the established progression")
		if encounter == 1:
			boss.guard_left = 2.4
			boss.take_damage(6)
			check(boss.health == 177, "Turtle guard halves incoming damage")
			boss.guard_left = 0
			boss.take_damage(6)
			check(boss.health == 171, "Turtle takes full damage outside its guard window")
		if encounter == 2:
			boss.position = Vector3(0, 0, -5)
			game.player.position = Vector3.ZERO
			boss.special_cooldown = 0
			boss._physics_process(0.01)
			check(boss.special_warning > 0.8 and boss.aim_marker.visible, "Fox warns and locks aim before its ranged attack")
			game.player.position.x = 7
			boss._physics_process(0.9)
			var bolts := get_nodes_in_group("hostile_projectiles")
			check(bolts.size() == 3 and absf(bolts[1].direction.x) < 0.05, "Fox fires three bolts along the original aim after the player dodges")
			for bolt in bolts:
				bolt.free()
		if encounter == 3:
			boss.position = Vector3(0, 0, -6)
			game.player.position = Vector3.ZERO
			boss.special_cooldown = 0
			boss._physics_process(0.01)
			var landing: Vector3 = boss.jump_target
			check(boss.rabbit_state == "warn" and boss.stomp_ring.visible, "Rabbit marks its landing position before jumping")
			game.player.position = Vector3(7, 0, 0)
			boss._physics_process(1)
			boss._physics_process(0.35)
			check(boss.model.position.y > 2 and boss.jump_target == landing and boss.stomp_ring.global_position.distance_to(landing + Vector3(0, 0.05, 0)) < 0.01, "Rabbit leaps high while its landing marker stays fixed")
			boss._physics_process(0.35)
			check(boss.rabbit_state == "recover" and game.player.health == 100, "Dodging the landing avoids damage and leaves the rabbit recovering")
		boss.take_damage(9999)
		await frames(1)
		for enemy_node in get_nodes_in_group("enemies"):
			enemy_node.free()
	check(names.size() == 4 and kinds.size() == 4 and game.boss_encounters == 4, "All four scheduled minibosses have unique animals and names")
	game.elapsed = 599
	game.recovery_until = 0
	game.next_boss_at = 550
	game._tick_director(0.01)
	check(game.boss_encounters == 4 and game.spawn_enemy(-1, true) == null, "Exhausting the roster never repeats a miniboss")
	game.elapsed = 600
	game._tick_director(0.01)
	check(game.final_boss_spawned and game.active_boss.max_health == 1400, "Final boss still arrives after the unique roster")
	print("LIGHTNING/ROSTER TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
