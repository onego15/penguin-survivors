extends SceneTree
## Automated pacing audit, not a substitute for human playtesting.
## Six times real-time while retaining 1/60-second physics steps.

var game: Node3D
var acquisitions: Array[String] = []


func _initialize() -> void:
	Engine.time_scale = 6.0
	Engine.physics_ticks_per_second = 360
	Engine.max_physics_steps_per_frame = 16
	call_deferred("run")


func run() -> void:
	for character in ["classic","pink"]:
		preload("res://scripts/character_roster.gd").selected_id=character
		var moving:=true
		game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		game.rng.seed = 73
		acquisitions.clear()
		var checkpoint := 60.0
		while game.elapsed < 90 and not game.game_over:
			if game.choice_open:
				if "--starter-only" in OS.get_cmdline_user_args(): game.offered_weapons[0]=preload("res://scripts/character_roster.gd").CHARACTERS[character].weapon
				acquisitions.append("%.1fs:%s" % [game.elapsed, game.offered_weapons[0]])
				game.choose_weapon(0)
			if moving:
				var destination := Vector3(cos(game.elapsed * 0.24), 0, sin(game.elapsed * 0.24)) * 12.0
				var direction: Vector3 = (destination - game.player.position).normalized()
				for action in ["move_right", "move_left", "move_up", "move_down"]:
					Input.action_release(action)
				Input.action_press("move_right" if direction.x > 0 else "move_left", absf(direction.x))
				Input.action_press("move_down" if direction.z > 0 else "move_up", absf(direction.z))
			if game.elapsed >= checkpoint:
				print("PACE moving=%s time=%d hp=%d weapons=%d enemies=%d bosses=%d" % [moving, int(game.elapsed), game.player.health, game.armory.levels.size(), get_nodes_in_group("enemies").size(), game.boss_encounters])
				checkpoint += 60
			await process_frame
		print("RESULT character=%s moving=%s time=%.1f hp=%d kills=%d choices=%s" % [character,moving, game.elapsed, game.player.health, game.kills, str(acquisitions)])
		for action in ["move_right", "move_left", "move_up", "move_down"]:
			Input.action_release(action)
		paused = false
		game.queue_free()
		await process_frame
	Engine.time_scale = 1.0
	quit()
