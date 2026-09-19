extends SceneTree
## Deterministic automated steering. Records natural offers, no XP grants or invincibility.
const R=preload("res://scripts/character_roster.gd")
const S=preload("res://scripts/stage_catalog.gd")
var game: Node3D
func _initialize() -> void:
	Engine.time_scale=20; Engine.physics_ticks_per_second=1200; Engine.max_physics_steps_per_frame=64
	call_deferred("run")
func run() -> void:
	for stage in ["snowfield","castle"]:
		for character in ["classic","pink"]:
			R.selected_id=character; S.selected_id=stage
			game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game; game.rng.seed=73
			var first:=-1.0; var choices:=0; var received: Array[int]=[0]
			game.player.damage_received.connect(func(value): received[0]+=value)
			var starter: String=R.CHARACTERS[character].weapon
			var start:=Time.get_ticks_msec()
			while not game.game_over and not game.victory and game.elapsed<720 and Time.get_ticks_msec()-start<120000:
				if game.choice_open:
					var pick:=0; var score:=-100
					for i in range(game.offered_weapons.size()):
						var id: String=game.offered_weapons[i]
						var value: int=100 if id.begins_with("@") else (80 if game.Catalog.Evolution.ITEMS.has(id) else (70 if id==starter else (50 if id in ["gust","popsicle","beam","heart"] else 10)))
						if value>score: score=value; pick=i
					game.choose_weapon(pick)
					if game.pending_recipe!="": game.choose_evolution(game.Catalog.Evolution.RECIPES[game.pending_recipe].outputs[0])
					choices+=1
					if first<0 and game.armory.evolution_count()>0: first=game.elapsed
				var destination:=Vector3(cos(game.elapsed*0.24),0,sin(game.elapsed*0.24))*12
				var direction: Vector3=(destination-game.player.position).normalized()
				for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
				Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
				Input.action_press("move_down" if direction.z>0 else "move_up",absf(direction.z))
				await process_frame
			print("EVO_CAMPAIGN stage=%s char=%s survived=%.1f first_evolution=%.1f choices=%d kills=%d damage=%d victory=%s"%[stage,character,game.elapsed,first,choices,game.kills,received[0],game.victory])
			for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
			paused=false; game.free(); await process_frame
	Engine.time_scale=1; Engine.physics_ticks_per_second=60; S.selected_id="snowfield"; R.selected_id="classic"; quit()
