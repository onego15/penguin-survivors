extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game._start_final_boss()
	game._finish_presentation()
	var boss = game.active_boss
	boss.set_physics_process(false)
	boss.position = Vector3.ZERO
	game.player.position = Vector3(0, 0, 8)
	boss.attack_index = 2
	boss.attack_cooldown = 0
	boss._physics_process(0.01)
	check(boss.attack_kind == "dash" and boss.dash_marker.visible and boss.warning_left == 1.0, "Every third attack warns with a visible dash lane")
	var start: Vector3 = boss.position
	game.player.position.x = 5
	boss._physics_process(0.5)
	check(boss.position == start and game.player.health == 100, "Boss stays still during its warning")
	boss._physics_process(0.51)
	boss._physics_process(0.8)
	check(absf(boss.position.x) < 0.01 and game.player.health == 100 and boss.recovery_left > 1, "Dash keeps original aim, can be dodged sideways and ends in recovery")
	var stop: Vector3 = boss.position
	boss._physics_process(0.8)
	check(boss.position == stop and not boss.dash_marker.visible, "Recovery prevents movement and follow-up attacks")
	boss.recovery_left = 0
	boss.position = Vector3.ZERO
	boss.locked_direction = Vector3.BACK
	boss.attack_kind = "dash"
	game.player.position = Vector3(0, 0, 5)
	boss._release_attack()
	boss._physics_process(0.7)
	check(game.player.health == 72, "Swept collision detects a player crossed between frames")
	boss._physics_process(0.1)
	check(game.player.health == 72, "One dash cannot deal repeated damage")
	boss.recovery_left = 0
	boss.position = Vector3(22, 0, 0)
	boss.locked_direction = Vector3.RIGHT
	boss._release_attack()
	boss._physics_process(0.7)
	check(boss.position.x == 23 and boss.dash_left == 0 and boss.recovery_left > 0, "Arena edge stops the dash and enters recovery")
	boss.recovery_left = 0
	boss.position = Vector3.ZERO
	boss.health = 700
	boss._enter_phase_two()
	game._finish_presentation()
	boss.phase_attack_index=2
	game.player.position = Vector3(0, 0, 8)
	boss.attack_index = 5
	boss.attack_cooldown = 0
	boss._physics_process(0.01)
	check(boss.warning_left == 0.8 and boss.dash_speed == 20 and boss.dash_distance == 13, "Second phase has a faster, longer dash with readable warning")
	game.experience = game.xp_needed
	game.open_weapon_choice()
	boss.set_physics_process(true)
	var before: float = boss.warning_left
	await create_timer(0.1).timeout
	check(boss.warning_left == before, "Weapon choice pauses the dash warning")
	boss.set_physics_process(false)
	game.choose_weapon(0)
	print("FINAL DASH TEST: %d failure(s)" % failures)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
