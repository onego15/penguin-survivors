extends SceneTree
## Controlled 60-second comparisons at Wave 4; no claim of natural acquisition pacing.
const R=preload("res://scripts/character_roster.gd")
const S=preload("res://scripts/stage_catalog.gd")
var game: Node3D
func _initialize() -> void:
	Engine.time_scale=20; Engine.physics_ticks_per_second=1200; Engine.max_physics_steps_per_frame=64
	call_deferred("run")
func drive() -> void:
	var destination:=Vector3(cos(game.elapsed*0.24),0,sin(game.elapsed*0.24))*12
	var direction: Vector3=(destination-game.player.position).normalized()
	for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
	Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
	Input.action_press("move_down" if direction.z>0 else "move_up",absf(direction.z))
func run() -> void:
	for stage in ["snowfield","castle"]:
		for character in ["classic","pink"]:
			for evolved in [false,true]:
				R.selected_id=character; S.selected_id=stage
				game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
				game.rng.seed=73; game.elapsed=180; game.boss_encounters=1; game.experience=-1000000
				var starter: String=R.CHARACTERS[character].weapon
				var source: String="nova" if stage=="snowfield" else "lightning"
				var second: String="orbit" if stage=="snowfield" else "storm"
				# Four choices: both materials + one material upgrade + fusion/another upgrade.
				game.armory.acquire(source); game.armory.acquire(second); game.armory.acquire(second)
				if evolved: game.armory.evolve("pearl_chime" if stage=="snowfield" else "thunder_dome","pearl_chime" if stage=="snowfield" else "thunder_dome")
				else: game.armory.acquire(source)
				var received: Array[int]=[0]
				game.player.damage_received.connect(func(value): received[0]+=value)
				while game.elapsed<240 and not game.game_over:
					drive(); await process_frame
				print("EVO_BALANCE stage=%s character=%s evolved=%s seconds=%.1f hp=%d damage=%d kills=%d choices=4"%[stage,character,evolved,game.elapsed-180,game.player.health,received[0],game.kills])
				for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
				paused=false; game.free(); await process_frame
	Engine.time_scale=1; Engine.physics_ticks_per_second=60; S.selected_id="snowfield"; R.selected_id="classic"; quit()
