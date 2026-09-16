extends SceneTree

const Catalog = preload("res://scripts/weapon_catalog.gd")
const Attack = preload("res://scripts/weapon_attack.gd")
var game: Node3D
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


func enemy_at(point: Vector3, hp := 100) -> Node3D:
	var enemy = game.spawn_enemy(0)
	enemy.position = point
	enemy.health = hp
	enemy.max_health = hp
	enemy.set_physics_process(false)
	return enemy


func clear_actors() -> void:
	for actor in game.actors.get_children():
		if actor != game.player:
			actor.free()


func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.rng.seed = 401
	game.spawn_cooldown = 9999
	game.fire_cooldown = 9999
	await frames(2)
	check(Catalog.ITEMS.size() == 20 and game.armory.levels.size() == 1, "Twenty weapon types exist, with one starter equipped")
	for index in range(11):
		enemy_at(Vector3(5, 0, 0), 2).take_damage(2)
	await frames(2)
	check(game.experience == 11 and not game.choice_open, "Eleven defeats are below the first threshold")
	enemy_at(Vector3(5, 0, 0), 2).take_damage(2)
	await frames(2)
	check(game.choice_open and paused and game.experience == 12, "Twelfth defeat opens the weapon menu and pauses the tree")
	var options: Array = game.offered_weapons.duplicate()
	check(options.size() == 3 and options[0] != options[1] and options[1] != options[2] and options[0] != options[2], "Three distinct weapons are offered from the mixed pool")
	var frozen_enemy = enemy_at(Vector3(1, 0, 0))
	frozen_enemy.set_physics_process(true)
	var frozen_attack := Attack.new()
	frozen_attack.position = Vector3(0, 1, 5)
	game.actors.add_child(frozen_attack)
	var time_before: float = game.elapsed
	var health_before: int = game.player.health
	var player_before: Vector3 = game.player.position
	var enemy_before: Vector3 = frozen_enemy.position
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check(game.elapsed == time_before and game.player.position == player_before and frozen_enemy.position == enemy_before and frozen_attack.age == 0 and game.player.health == health_before, "Time, movement, damage, enemies and projectiles freeze during selection")
	game.choose_weapon(-1)
	check(game.choice_open and game.armory.levels.size() == 1, "Invalid selection cannot consume a reward")
	clear_actors()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_3
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	check(not paused and not game.choice_open and game.armory.levels.has(options[2]) and game.armory.levels.has("frost"), "Key 3 adds the selected weapon, preserves starter, and resumes play")
	check(game.level == 2 and game.experience == 0 and game.xp_needed == 22, "Level increases and the next threshold becomes twenty-two")
	game.choose_weapon(2)
	check(game.armory.levels[options[2]] == (2 if options[2] == "frost" else 1), "Repeated selection does not grant a second reward")
	# Build the collection through actual menus, preserving every earlier acquisition.
	game.set_physics_process(false)
	var all_options_unique := true
	var all_prior_retained := true
	var draws := 0
	while game.armory.levels.size() < Catalog.ITEMS.size() and draws < 200:
		draws += 1
		game.experience = game.xp_needed + 2
		game.open_weapon_choice()
		var before: Dictionary = game.armory.levels.duplicate()
		var candidates: Array = game.offered_weapons.duplicate()
		all_options_unique = all_options_unique and candidates.size() == 3 and candidates[0] != candidates[1] and candidates[1] != candidates[2] and candidates[0] != candidates[2]
		var pick := 0
		for index in range(3):
			if not before.has(candidates[index]):
				pick = index
				break
		game.choice_ui.cards[pick].pressed.emit()
		for id in before:
			all_prior_retained = all_prior_retained and game.armory.levels.get(id) >= before[id]
		check(game.experience == 2, "Overflow XP survives a level-up")
	check(all_options_unique and all_prior_retained and game.armory.levels.size() == Catalog.ITEMS.size() and game.armory.mounts.size() == Catalog.ITEMS.size() - 1, "All catalog weapons accumulate without replacement; final menus still have three unique cards")
	game.experience = game.xp_needed
	game.open_weapon_choice()
	var upgrade: String = game.offered_weapons[0]
	var old_rank: int = game.armory.levels[upgrade]
	game.choice_ui.cards[0].pressed.emit()
	check(game.armory.levels.size() == Catalog.ITEMS.size() and game.armory.levels[upgrade] == old_rank + 1 and not paused, "Full collection offers upgrades and remains playable")
	check(Catalog.cooldown(upgrade, 2) < Catalog.cooldown(upgrade, 1) and Catalog.damage(upgrade, 3) > Catalog.damage(upgrade, 1), "Upgrades improve fire rate and eventually damage")
	for id in game.armory.levels:
		game.armory.levels[id] = 1
	clear_actors()
	# Isolate each weapon to prove its distinctive combat behavior.
	var a = enemy_at(Vector3(0, 0, 4))
	game.armory.fire("fan")
	check(get_nodes_in_group("weapon_attacks").size() == 5, "Feather shot creates five spreading projectiles")
	await frames(25)
	check(a.health < 100, "Feather projectiles damage enemies")
	clear_actors()
	a = enemy_at(Vector3(0, 0, 3))
	var b = enemy_at(Vector3(0, 0, 6))
	game.armory.fire("spear")
	await frames(25)
	check(a.health == 95 and b.health == 95, "Empowered lance pierces two lined-up enemies exactly once")
	clear_actors()
	a = enemy_at(Vector3(0, 0, 6))
	b = enemy_at(Vector3(1.6, 0, 6))
	game.armory.fire("ember")
	await frames(50)
	check(a.health == 94 and b.health == 94, "Empowered meteor hits its target and a neighbor without double damage")
	clear_actors()
	game.armory.fire("lightning")
	var strikes := get_nodes_in_group("weapon_attacks")
	check(strikes.size() == 3, "Lightning creates three random strikes without needing a target")
	a = enemy_at(strikes[0].position)
	await frames(50)
	check(a.health <= 95, "Random lightning damages enemies inside its landing area")
	clear_actors()
	a = enemy_at(Vector3(2.2, 0, 0))
	game.armory.fire("orbit")
	await frames(90)
	check(a.health <= 96, "Orbiting pearls repeatedly damage nearby enemies")
	clear_actors()
	a = enemy_at(Vector3(3, 0, 0))
	b = enemy_at(Vector3(-3, 0, 0))
	game.armory.fire("nova")
	await frames(45)
	check(a.health == 98 and b.health == 98, "Nova expands in all directions and hits each enemy once")
	clear_actors()
	a = enemy_at(Vector3(0.9, 0, 0))
	game.armory.fire("mine")
	await frames(20)
	check(a.health == 100, "Acorn mine does not explode before arming")
	await frames(30)
	check(a.health == 96, "Armed mine explodes when an enemy is nearby")
	clear_actors()
	a = enemy_at(Vector3(0, 0, 9.1))
	game.armory.fire("boomerang")
	await frames(90)
	check(a.health == 96, "Fish boomerang hits on both outbound and return paths")
	clear_actors()
	a = enemy_at(Vector3(0, 0, 4))
	game.armory.fire("storm")
	await frames(100)
	check(a.health <= 97, "Snow globe storm applies repeated area damage")
	clear_actors()
	# All acquired weapons are scheduled together, rather than replacing auto-fire.
	for index in range(8):
		enemy_at(Vector3(cos(index * TAU / 8), 0, sin(index * TAU / 8)) * 3, 1000)
	game.experience = 0
	game.fire_cooldown = 0
	game.set_physics_process(true)
	await frames(120)
	var scheduled: bool = game.armory.cooldowns.size() == Catalog.ITEMS.size() - 1
	for id in game.armory.cooldowns:
		if id == "trail": # Movement-only weapon intentionally waits while stationary.
			continue
		scheduled = scheduled and game.armory.cooldowns[id] > -0.1
	check(scheduled and get_nodes_in_group("weapon_attacks").size() > 0, "All additional weapons run beside the initial blaster")
	game.set_physics_process(false)
	await frames(510)
	check(get_nodes_in_group("weapon_attacks").is_empty(), "Projectiles, mines, storms, pearls and effects expire")
	game.player.health = 0
	game.experience = game.xp_needed
	game.set_physics_process(true)
	await frames(2)
	check(game.game_over and not game.choice_open and not paused, "Death takes priority over a simultaneous level-up")
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(2)
	check(current_scene.level == 1 and current_scene.experience == 0 and current_scene.armory.levels.size() == 1 and not paused, "Restart resets the collection, level, XP and pause state")
	print("WEAPONS TEST: %d failure(s)" % failures)
	current_scene.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
