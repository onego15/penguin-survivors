extends SceneTree
var game: Node3D
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, caption: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + caption)
	if not ok:
		failures += 1
func enemy_at(point: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(0)
	enemy.set_physics_process(false)
	enemy.position = point
	enemy.health = 100
	return enemy
func clear() -> void:
	for child in game.actors.get_children():
		if child != game.player:
			child.free()
func cast(id: String) -> Node3D:
	game.armory.acquire(id)
	game.armory.fire(id)
	var attacks := get_nodes_in_group("weapon_attacks")
	for attack in attacks:
		attack.set_physics_process(false)
	return attacks.back() if not attacks.is_empty() else null
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var forward: Vector3 = game.player.facing_direction()
	var a := enemy_at(forward * 3)
	var b := enemy_at(-forward * 3)
	var attack := cast("whip")
	attack._physics_process(0.01)
	attack._physics_process(0.1)
	check(a.health == 93 and b.health == 100, "Whip hits only the forward sector once")
	clear()
	game.armory.acquire("trail")
	check(not game.armory.fire("trail"), "Standing still produces no flame trail")
	game.player.velocity = forward * 5
	game.armory.fire("trail")
	attack = get_nodes_in_group("weapon_attacks")[0]
	attack.set_physics_process(false)
	a = enemy_at(Vector3.ZERO)
	attack._physics_process(0.01)
	attack._physics_process(0.61)
	check(a.health == 96, "Flames repeatedly damage pursuing enemies")
	game.player.position = forward * 3
	check(attack.position == Vector3.ZERO and game.armory.fire("trail"), "Moving leaves separate stationary flame patches")
	clear()
	game.player.position = Vector3.ZERO
	game.player.velocity = Vector3.ZERO
	a = enemy_at(Vector3(4, 0, 0))
	attack = cast("bounce")
	a.position = Vector3(22, 0, 0)
	attack.position = Vector3(22.9, 1, 0)
	attack.direction = Vector3.RIGHT
	attack._physics_process(0.1)
	check(attack.direction.x < 0 and attack.position.x <= 23 and a.health == 97, "Ice ball reflects at the wall and damages on the returning path")
	clear()
	attack = cast("turret")
	a = enemy_at(Vector3(0, 0, 4))
	attack._physics_process(0.01)
	var bullet: Node3D = get_nodes_in_group("weapon_attacks").back()
	bullet.set_physics_process(false)
	bullet._physics_process(0.3)
	check(a.health == 98 and attack.position == Vector3.UP, "Stationary turret automatically fires damaging shots")
	clear()
	a = enemy_at(forward * 5)
	attack = cast("seeker")
	check(get_nodes_in_group("weapon_attacks").size() == 3, "Bee weapon launches three seekers")
	a.dead = true
	b = enemy_at(Vector3(4, 0, 0))
	check(attack.closest_enemy() == b, "Seekers reacquire living targets")
	attack.position = Vector3(3.5, 1, 0)
	attack.direction = Vector3.RIGHT
	attack._physics_process(0.08)
	check(b.health == 98 and attack.is_queued_for_deletion(), "Seeker deals damage and expires on impact")
	clear()
	a = enemy_at(forward * 3)
	b = enemy_at(forward * 6)
	attack = cast("beam")
	attack._physics_process(0.01)
	attack._physics_process(0.61)
	check(a.health == 94 and b.health == 94, "Fixed beam pierces multiple enemies with timed repeat hits")
	var origin := attack.position
	game.player.position = Vector3(7, 0, 0)
	check(attack.position == origin, "Beam remains fixed when the player moves")
	clear()
	game.player.position = Vector3.ZERO
	game.player.body.rotation.y = 0
	forward = game.player.facing_direction()
	a = enemy_at(-forward * 3)
	b = enemy_at(forward * 3)
	attack = cast("rear_fan")
	check(get_nodes_in_group("weapon_attacks").size() == 5, "Rear scatter launches five shots")
	for shot in get_nodes_in_group("weapon_attacks"):
		shot._physics_process(0.2)
	check(a.health < 100 and b.health == 100, "Rear scatter hits pursuers, not enemies ahead")
	clear()
	a = enemy_at(-forward * 4.5)
	b = enemy_at(forward * 4.5)
	attack = cast("rear_bomb")
	var landing := attack.position
	attack._physics_process(0.3)
	check(a.health == 100 and landing.distance_to(-forward * 4.5) < 0.01 and attack.falling_ball.global_position.y > 2, "Rear firework arcs toward its warned point without early damage")
	game.player.position = Vector3(8, 0, 0)
	game.player.body.rotation.y = PI
	attack._physics_process(0.36)
	check(a.health == 92 and b.health == 100 and attack.position == landing, "Firework keeps its landing point despite movement and turning, then deals eight damage")
	clear()
	print("VARIETY TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
