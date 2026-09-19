extends SceneTree
## Equal four selections, fixed spawn schedule isolated from weapon RNG.
## HP restored for equal exposure; damage received still uses normal invulnerability.
const C=preload("res://scripts/weapon_catalog.gd")
var Sandbox: Script
const O=preload("res://scripts/castle_obstacles.gd")
var game: Node3D
var results: Array=[]
var adjusted:=false
var frontal:=false
func _initialize() -> void:
	Engine.time_scale=20; Engine.physics_ticks_per_second=1200; Engine.max_physics_steps_per_frame=64
	call_deferred("run")
func setup() -> void:
	Sandbox.saved={}
	game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.settings.invincible=false; game.player.training_invincible=false
func run() -> void:
	Sandbox=load("res://scripts/sandbox.gd")
	adjusted="--adjusted" in OS.get_cmdline_user_args()
	frontal="--frontal" in OS.get_cmdline_user_args()
	for recipe in ["rainbow_heart","blizzard_fan","pearl_chime","thunder_dome"]:
		if adjusted and recipe=="pearl_chime": continue
		if frontal and recipe not in ["rainbow_heart","blizzard_fan"]: continue
		for seed_value in [17,73,211]:
			for variant in (["normal","legacy","adjusted"] if frontal else ["adjusted"] if adjusted else (["normal","old","candidate"] if recipe=="thunder_dome" else ["normal","fusion"])):
				setup(); game.rng.seed=seed_value
				var random:=RandomNumberGenerator.new(); random.seed=seed_value
				var sources: Array=C.Evolution.RECIPES[recipe].sources
				game.settings.weapons={"frost":1}
				if variant=="normal":
					for source in sources: game.settings.weapons[source]=2
				else: game.settings.weapons[recipe]=2
				game.rebuild_player(); game.player.training_invincible=false
				if recipe in ["rainbow_heart","thunder_dome"]: game.switch_terrain(true)
				var hits: Array[int]=[0]; var close_seconds:=0.0; var crowded_seconds:=0.0; var controlled_seconds:=0.0
				var emitted:=0
				for frame in range(2400):
					var t:=float(frame)/60
					# Same spawn positions/kinds regardless of attack RNG consumption.
					if frame%30==0:
						var point:=Vector3.ZERO
						for attempt in range(32):
							var a:=random.randf()*TAU; point=Vector3(cos(a)*12,0,sin(a)*12)
							if frontal: point=Vector3(sin(a/6-PI/6)*12,0,cos(a/6-PI/6)*12)
							if O.placement(game,point,0.9): break
						var kind: int=[0,1,2,5][random.randi_range(0,3)]
						var e=game.create_enemy({"type":"normal","index":kind},point,240)
						e.movement_phase=random.randf()*TAU; e.damage_received.connect(func(_value): hits[0]+=1); emitted+=1
					game.player.health=100
					var destination:=Vector3(cos(t*0.35),0,sin(t*0.35))*6
					var direction: Vector3=(destination-game.player.position).normalized()
					if frontal: direction=Vector3.ZERO; game.player.body.rotation.y=0
					for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
					Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
					Input.action_press("move_down" if direction.z>0 else "move_up",absf(direction.z))
					game._physics_process(1.0/60)
					for actor in game.actors.get_children():
						if variant!="adjusted" and actor.get_meta("weapon_id","")==recipe:
							var values:=original_stats(recipe,2)
							if variant=="candidate": values.pulse_radius=lerpf(1.5,1.6,1.0/8)
							actor.configure(values)
					if variant not in ["normal","adjusted"] and game.armory.cast_times.get(recipe,-1)==game.armory.time:
						game.armory.cooldowns[recipe]=original_stats(recipe,2).cooldown
					var close_count:=0
					for e in get_nodes_in_group("enemies"):
						var controlled: bool=is_instance_valid(e.control) and (e.control.frozen>0 or e.control.knock_left>0)
						if controlled: controlled_seconds+=1.0/60
						if not controlled and e.position.distance_to(game.player.position)<3: close_count+=1
					close_seconds+=close_count/60.0
					if close_count>=3: crowded_seconds+=1.0/60
					await physics_frame
				var row:={"scenario":"frontal" if frontal else "circle","recipe":recipe,"seed":seed_value,"variant":variant,"spawned":emitted,"kills":game.kills,"hits":hits[0],"damage":game.dealt,"received":game.received,"close_enemy_seconds":snappedf(close_seconds,0.01),"crowded_seconds":snappedf(crowded_seconds,0.01),"controlled_enemy_seconds":snappedf(controlled_seconds,0.01)}
				results.append(row); print("LOW_RANK ",JSON.stringify(row))
				for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
				game.free(); await process_frame
	if not frontal: await cloud_accuracy()
	var file:=FileAccess.open("res://.godot/evolution-low-rank-frontal.json" if frontal else "res://.godot/evolution-low-rank-adjusted.json" if adjusted else "res://.godot/evolution-low-rank.json",FileAccess.WRITE); file.store_string(JSON.stringify(results,"  ")); file.close()
	Engine.time_scale=1; Sandbox.saved={}; quit()
func cloud_accuracy() -> void:
	setup(); game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.player.set_physics_process(false)
	var e=game.create_enemy({"type":"normal","index":0},Vector3(0,0,10),0)
	e.health=100000; e.max_health=100000
	for radius in [1.2,1.5]:
		var hit_count:=0
		for seed_value in range(128):
			var cloud=load("res://scripts/fusion_attack.gd").new(); cloud.mode="thunder_dome"; cloud.player=game.player; cloud.stats=C.stats("thunder_dome",1).duplicate(); cloud.stats.pulse_radius=radius
			cloud.rng=RandomNumberGenerator.new(); cloud.rng.seed=seed_value; cloud.position=Vector3(0,0,10); game.armory.attach(cloud,"thunder_dome")
			for i in range(6):
				# Lone target walks toward player at 2 m/s from locked cloud center.
				e.position=Vector3(0,0,10-(i+1)*1.0)
				var health: int=e.health; cloud.pulse()
				if e.health<health: hit_count+=1
			cloud.free()
		var row:={"test":"cloud_accuracy","radius":radius,"strikes":768,"hits":hit_count}; results.append(row); print("LOW_RANK ",JSON.stringify(row))
	game.free(); await process_frame

func original_stats(recipe: String, rank: int) -> Dictionary:
	var values:=C.stats(recipe,rank).duplicate(); var t:=float(rank-1)/8
	match recipe:
		"rainbow_heart": values.cooldown=lerpf(2.8,2.35,t); values.width=lerpf(0.45,0.65,t)
		"blizzard_fan": values.cooldown=lerpf(3,2.4,t); values.reach=lerpf(6,9,t); values.pulse_interval=lerpf(4.8,4,t); values.freeze=lerpf(1,1.4,t)
		"thunder_dome": values.pulse_radius=lerpf(1.2,1.6,t)
	return values
