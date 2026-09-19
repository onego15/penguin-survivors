extends SceneTree
## Seeded spawns and automated steering; frame timing can vary. Records natural offers, no XP grants or invincibility.
const R=preload("res://scripts/character_roster.gd")
const S=preload("res://scripts/stage_catalog.gd")
const T=preload("res://scripts/difficulty_tiers.gd")
var records: Array=[]
var game: Node3D
func _initialize() -> void:
	Engine.time_scale=20; Engine.physics_ticks_per_second=1200; Engine.max_physics_steps_per_frame=64
	call_deferred("run")
func run() -> void:
	for tier in T.IDS:
		for seed_value in [17,73]:
			for stage in ["snowfield","castle"]:
				for character in ["classic","pink"]:
					T.selected_id=tier; R.selected_id=character; S.selected_id=stage
					game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game; game.rng.seed=seed_value; seed(seed_value)
					var first:=-1.0; var choices:=0; var received: Array[int]=[0]
					game.player.damage_received.connect(func(value): received[0]+=value)
					var starter: String=R.CHARACTERS[character].weapon
					var start:=Time.get_ticks_msec()
					while not game.game_over and not game.victory and game.elapsed<180 and Time.get_ticks_msec()-start<120000:
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
					var record={"tier":tier,"seed":seed_value,"stage":stage,"character":character,"seconds":snappedf(game.elapsed,0.1),"choices":choices,"kills":game.kills,"damage":received[0],"died":game.game_over}
					records.append(record); print("DIFFICULTY_AUDIT "+JSON.stringify(record))
					for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
					paused=false; game.free(); await process_frame
	FileAccess.open("res://docs/benchmarks/difficulty-2026-09-19.json",FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	Engine.time_scale=1; Engine.physics_ticks_per_second=60; S.selected_id="snowfield"; R.selected_id="classic"; quit()
