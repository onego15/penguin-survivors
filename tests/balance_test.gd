extends SceneTree

const D = preload("res://scripts/difficulty.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, caption: String) -> void:
	if condition:
		print("PASS: " + caption)
	else:
		push_error("FAIL: " + caption)
		failures += 1


func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 812
	var valid := true
	for seconds in [0, 29, 30, 59, 60, 119, 120]:
		for sample in range(200):
			var kind := D.pick_kind(seconds, rng)
			valid = valid and not (seconds < 30 and kind != 0) and not (seconds < 60 and kind == 3) and not (seconds < 120 and kind == 2)
	check(valid, "Rabbit, turtle and boar unlock at 30, 60 and 120 seconds")
	var monotonic := true
	for second in range(1, 900):
		var previous := D.profile(second - 1)
		var current := D.profile(second)
		for key in ["rate", "cap", "hp", "speed", "damage"]:
			monotonic = monotonic and current[key] >= previous[key]
	check(monotonic, "Enemy numbers, health and speed rise monotonically over fifteen minutes")
	check(D.profile(0).rate < 0.4 and D.profile(0).cap == 10 and D.profile(540).rate == 5 and D.profile(540).cap == 100, "Opening is sparse; late game has a bounded dense population")
	check(D.xp_for_level(1) == 12 and D.xp_for_level(2) == 22 and D.xp_for_level(3) == 36 and D.xp_for_level(4) == 54, "Weapon XP costs grow faster than the original 5/8/11 progression")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.rng.seed = 816
	for second in range(30):
		game.elapsed = second
		game._tick_director(1.0)
	check(get_nodes_in_group("enemies").size() <= 10 and game.boss_encounters == 0, "First thirty seconds stay under the opening population cap without a boss")
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	game.elapsed = 0
	var early = game.spawn_enemy(0)
	var early_health: int = early.health
	var early_speed: float = early.speed
	early.free()
	game.elapsed = 300
	var late = game.spawn_enemy(0)
	check(late.health > early_health * 2 and late.speed > early_speed, "Later spawned enemies actually receive stronger stats")
	late.free()
	game.elapsed = 119.9
	game.spawn_cooldown = 999
	game._tick_director(0.01)
	check(game.active_boss == null, "First boss never appears before two minutes")
	game.elapsed = 120
	game._tick_director(0.01)
	var boss = game.active_boss
	boss.set_physics_process(false)
	check(boss != null and boss.kind == 2 and boss.health == 100 and boss.visual_scale == 1.9, "Two minutes spawns the crowned boar miniboss")
	game.spawn_cooldown = 999
	game.director.budget = 0
	game._tick_director(0.5)
	check(is_equal_approx(game.director.budget, D.profile(120).rate * 0.5 * 0.5), "Reinforcement budget is halved during a miniboss fight")
	game.elapsed = 241
	game._tick_director(0.01)
	check(game.boss_encounters == 1 and game.active_boss == boss, "A living miniboss prevents overlapping boss encounters")
	for enemy in get_nodes_in_group("enemies"):
		if enemy != boss:
			enemy.free()
	boss.position = Vector3.ZERO
	game.player.position = Vector3(3, 0, 0)
	boss.stomp_cooldown = 0
	boss._physics_process(0.01)
	check(boss.stomp_warning > 1.2 and boss.stomp_ring.visible and game.player.health == 100, "Miniboss stomp warns for 1.25 seconds before damage")
	game.player.position = Vector3(7, 0, 0)
	boss._physics_process(1.3)
	check(game.player.health == 100, "Leaving the warned ring avoids the stomp")
	game.player.position = Vector3(3, 0, 0)
	boss.stomp_cooldown = 0
	boss._physics_process(0.01)
	boss._physics_process(1.3)
	check(game.player.health == 78, "Remaining inside the ring takes one stomp hit")
	game.player.health = 60
	game.experience = 0
	boss.take_damage(9999)
	boss.take_damage(9999)
	check(game.player.health == 85 and game.experience == 8 and game.kills == 1, "Miniboss defeat rewards heal and XP exactly once")
	var before: int = game.spawn_count
	game.elapsed = 248.9
	game._tick_director(2.0)
	check(game.spawn_count == before and game.boss_encounters == 1, "Eight-second recovery suppresses both reinforcements and an overdue boss")
	game.elapsed = 249.1
	game._tick_director(0.01)
	check(game.active_boss != boss and game.active_boss.kind == 3 and game.active_boss.max_health == 180, "Next encounter is a stronger turtle boss after recovery")
	game.experience = game.xp_needed
	game.open_weapon_choice()
	var time_before: float = game.elapsed
	var warning_before: float = game.active_boss.stomp_cooldown
	for frame in range(3):
		await physics_frame
		await process_frame
	check(game.elapsed == time_before and game.active_boss.stomp_cooldown == warning_before, "Weapon selection pauses the director and miniboss timers")
	game.choose_weapon(0)
	game.player.health = 0
	game.active_boss.take_damage(9999)
	check(game.player.health == 0, "Boss reward cannot resurrect a defeated player")
	print("BALANCE TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
