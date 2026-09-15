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


func clear_actors() -> void:
	for actor in game.actors.get_children():
		if actor != game.player:
			actor.free()


func enemy_at(point: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(0)
	enemy.position = point
	enemy.health = 100
	enemy.max_health = 100
	enemy.set_physics_process(false)
	return enemy


func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.rng.seed = 851
	var mixed_seen := false
	var upgrade_worked := false
	for index in range(25):
		game.armory.levels = {"frost": 1}
		game.experience = game.xp_needed
		game.open_weapon_choice()
		if game.offered_weapons.has("frost"):
			mixed_seen = true
			game.choose_weapon(game.offered_weapons.find("frost"))
			upgrade_worked = game.armory.levels.size() == 1 and game.armory.levels.frost == 2
		else:
			game.choose_weapon(0)
	check(mixed_seen and upgrade_worked, "Starter upgrades appear alongside new weapons before collecting anything else")
	game.armory.acquire("fan")
	game.armory.acquire("spear")
	game.armory.acquire("ember")
	game.armory.acquire("storm")
	game.armory.acquire("boomerang")
	for id in game.armory.levels:
		game.armory.levels[id] = 1
	clear_actors()
	game.player.body.rotation.y = PI / 2
	var front = enemy_at(Vector3(4, 0, 0))
	var behind = enemy_at(Vector3(-2, 0, 0))
	game.armory.fire("fan")
	await frames(25)
	check(front.health < 100 and behind.health == 100, "Feather shot follows facing direction instead of the closer enemy behind")
	clear_actors()
	front = enemy_at(Vector3(4, 0, 0))
	var second = enemy_at(Vector3(7, 0, 0))
	behind = enemy_at(Vector3(-2, 0, 0))
	game.armory.fire("spear")
	await frames(25)
	check(front.health == 95 and second.health == 95 and behind.health == 100, "Empowered forward lance pierces the lane being faced")
	clear_actors()
	check(game.armory.fire("ember"), "Fixed-position meteor casts without an enemy")
	var meteor: Node3D = get_nodes_in_group("weapon_attacks")[0]
	check(meteor.position.distance_to(Vector3(6, 0, 0)) < 0.01, "Meteor locks a point six metres ahead")
	front = enemy_at(Vector3(6, 0, 0))
	game.player.position = Vector3(0, 0, 6)
	game.player.body.rotation.y = PI
	await frames(20)
	check(front.health == 100 and meteor.position.distance_to(Vector3(6, 0, 0)) < 0.01, "Meteor warns without damage and does not follow player movement")
	await frames(30)
	check(front.health == 94, "Empowered meteor damages the originally marked location after the delay")
	clear_actors()
	game.player.position = Vector3.ZERO
	game.player.body.rotation.y = PI / 2
	front = enemy_at(Vector3(-4, 0, 0))
	game.armory.fire("storm")
	var storm: Node3D = get_nodes_in_group("weapon_attacks")[0]
	game.player.position.z = 5
	await frames(2)
	check(storm.position.distance_to(Vector3(-4, 0, 0)) < 0.01, "Storm auto-targets an enemy behind and then remains stationary")
	clear_actors()
	game.player.position = Vector3.ZERO
	front = enemy_at(Vector3(-4, 0, 0))
	check(game.armory.fire("boomerang"), "Boomerang retains automatic target acquisition")
	var fish: Node3D = get_nodes_in_group("weapon_attacks")[0]
	check(fish.direction.distance_to(Vector3.LEFT) < 0.01, "Boomerang aims at the enemy even while facing away")
	clear_actors()
	game.elapsed = 480
	game.active_boss = game.spawn_enemy(-1, true)
	game.recovery_until = 1000
	game.elapsed = 599.9
	game._tick_director(0.01)
	check(not game.final_boss_spawned, "Final boss does not arrive before ten minutes")
	var xp_before: int = game.experience
	var kills_before: int = game.kills
	game.elapsed = 600
	game._tick_director(0.01)
	game._finish_presentation()
	var boss = game.active_boss
	boss.set_physics_process(false)
	check(game.final_boss_spawned and boss.max_health == 1400 and get_nodes_in_group("enemies").size() == 1, "Final duel overrides an overdue miniboss and clears ordinary enemies")
	check(game.experience == xp_before and game.kills == kills_before, "Final transition does not award fake defeat rewards")
	game._tick_director(10)
	check(game.active_boss == boss and game.spawn_enemy() == null, "Final boss spawns once and stops regular reinforcements")
	boss.position = Vector3.ZERO
	game.player.position = Vector3(3, 0, 0)
	boss.attack_cooldown = 0
	boss._physics_process(0.01)
	check(boss.warning_left > 1.2 and boss.warning_ring.visible, "Final boss warns before its slam")
	game.player.position = Vector3(8, 0, 0)
	boss._physics_process(1.4)
	check(game.player.health == 100, "Leaving the slam radius avoids damage")
	boss.attack_kind = "shards"
	boss._release_attack()
	check(get_nodes_in_group("hostile_projectiles").size() == 7, "First phase fires a seven-shot fan")
	for bolt in get_nodes_in_group("hostile_projectiles"):
		bolt.free()
	boss.health = 700
	boss._enter_phase_two()
	game._finish_presentation()
	boss.phase_attack_index=1
	boss._physics_process(0.01)
	boss._release_attack()
	check(boss.enraged and get_nodes_in_group("hostile_projectiles").size() == 12, "Half health triggers the faster twelve-shot second phase")
	for bolt in get_nodes_in_group("hostile_projectiles"):
		bolt.free()
	game.experience = game.xp_needed
	boss.take_damage(9999)
	game._physics_process(0.01)
	check(game.victory and not game.game_over and not game.choice_open and game.actors.process_mode == Node.PROCESS_MODE_DISABLED, "Final defeat ends the run with victory before any pending weapon menu")
	var end_time: float = game.elapsed
	game._physics_process(1)
	check(game.elapsed == end_time and is_instance_valid(game.victory_screen), "Victory freezes gameplay and displays the result screen")
	Input.action_press("restart")
	game._physics_process(0.01)
	await frames(3)
	Input.action_release("restart")
	game = current_scene
	check(not game.victory and not game.final_boss_spawned and game.armory.levels.size() == 1, "R restarts after victory with fresh run state")
	game.set_physics_process(false)
	game.elapsed = 600
	game._tick_director(0.01)
	game._finish_presentation()
	game.active_boss.take_damage(9999)
	game.player.health = 0
	game._physics_process(0.01)
	check(game.game_over and not game.victory, "Simultaneous player death takes precedence over victory")
	print("FINALE/DIRECTION TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout # Let the audio mixer release its playback references.
	quit(1 if failures else 0)
