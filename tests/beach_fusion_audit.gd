extends SceneTree
const C=preload("res://scripts/weapon_catalog.gd")
var rows: Array=[]
func _initialize() -> void:
	Engine.time_scale=20; Engine.physics_ticks_per_second=1200; Engine.max_physics_steps_per_frame=64
	call_deferred("run")
func run() -> void:
	var selected: String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--weapon="): selected=arg.trim_prefix("--weapon=")
	if selected!="":
		for row in JSON.parse_string(FileAccess.get_file_as_string("res://docs/benchmarks/beach-fusion-balance.json")):
			if row.weapon!=selected: rows.append(row)
	var Sandbox=load("res://scripts/sandbox.gd")
	for character in ["classic","pink"]:
		for seed_value in [17,73,211]:
			for rank in [1,5,9]:
				for id in ["pearl_wave","bubble_aquarium","crab_udon"]:
					if selected!="" and id!=selected: continue
					for scenario in ["cluster","scattered","boss"]:
						for fused in [false,true]:
							Sandbox.saved={}
							var game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game; game.set_physics_process(false)
							game.switch_terrain(false,true); game.settings.character=character; game.settings.invincible=false
							var starter: String="frost" if character=="classic" else "heart"
							game.settings.weapons={}; game.settings.weapons[starter]=1
							if fused: game.settings.weapons[id]=rank
							else:
								var sources: Array=C.Evolution.RECIPES[id].sources
								game.settings.weapons[sources[0]]=mini(5,ceili((rank+2)/2.0)); game.settings.weapons[sources[1]]=mini(5,floori((rank+2)/2.0))
								if rank==9: game.settings.weapons[starter]=2
							game.rebuild_player(); game.player.position=Vector3.ZERO; game.settings.minute=5
							var rng:=RandomNumberGenerator.new(); rng.seed=seed_value; game.rng.seed=seed_value
							var boss: Node3D
							if scenario=="boss":
								boss=game.create_enemy({"type":"final","index":2,"phase":1},Vector3(0,0,7),300)
								if boss==null:
									boss=preload("res://scripts/octo.gd").new(); boss.target=game.player; boss.position=Vector3(0,0,7); game.actors.add_child(boss)
								boss.health=100000; boss.max_health=100000
							var emitted:=0
							for frame in range(720):
								if scenario!="boss" and frame%30==0:
									var a:=rng.randf_range(-0.4,0.4) if scenario=="cluster" else rng.randf_range(-PI,PI)
									var e=game.create_enemy({"type":"normal","index":15+emitted%6},Vector3(sin(a)*10,0,cos(a)*10),300)
									e.movement_phase=rng.randf()*TAU; emitted+=1
								game.player.health=100
								# Reproducible short lateral retreat; no status-dependent manual teleporting.
								for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
								Input.action_press("move_right" if frame%360<180 else "move_left",0.35)
								game._physics_process(1.0/60)
								await physics_frame
							var row={"character":character,"seed":seed_value,"rank":rank,"weapon":id,"scenario":scenario,"fusion":fused,"seconds":12,"spawned":emitted,"kills":game.kills,"damage":game.dealt,"received":game.received}
							rows.append(row)
							for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
							game.free(); await process_frame
				print("SEA AUDIT ",character," seed ",seed_value," rank ",rank)
	FileAccess.open("res://docs/benchmarks/beach-fusion-balance.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
	Sandbox.saved={}; Engine.time_scale=1; print("SEA AUDIT DONE ",rows.size()); quit()
