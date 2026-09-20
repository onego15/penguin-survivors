extends "res://scripts/main.gd"
# Session-only state, independent of the title's character/stage selections.
static var saved: Dictionary={}
const Roster=preload("res://scripts/character_roster.gd")
var settings: Dictionary={}
var menu: CanvasLayer
var stopped:=false
var dealt:=0
var received:=0
var pending: Array[Dictionary]=[]
var formations: Array[Dictionary]=[]
var training_time:=0.0
var terrain_castle:=false
var suppress_rewards:=false
var formation_sequence:=0

func _ready() -> void:
	difficulty_id="normal"
	stage_id="snowfield"
	super._ready()
	add_to_group("sandbox")
	hud_layer.hide()
	settings=saved.duplicate(true) if not saved.is_empty() else {"character":Roster.selected(),"weapons":{Roster.CHARACTERS[Roster.selected()].weapon:1},"invincible":true,"stopped":false,"minute":0}
	settings["difficulty"]=Tiers.valid(settings.get("difficulty","normal"))
	rebuild_player(true)
	menu=preload("res://scripts/sandbox_ui.gd").new()
	menu.game=self
	add_child(menu)
	stopped=settings.stopped

func _setup_arena() -> void:
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("283c50")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("d1e6ff")
	env.ambient_light_energy=0.8
	environment.environment=env
	add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	add_child(light)
	var floor_mesh:=BoxMesh.new()
	floor_mesh.size=Vector3(48,0.2,48)
	Visuals.mesh(self,floor_mesh,Color("9cafba"),Vector3(0,-0.15,0))
	for i in range(-24,25,2):
		for axis in range(2):
			var line:=BoxMesh.new()
			line.size=Vector3(0.018,0.008,48) if axis==0 else Vector3(48,0.008,0.018)
			Visuals.mesh(self,line,Color("899fae"),Vector3(i,-0.043,0) if axis==0 else Vector3(0,-0.043,i))

func _update_hud() -> void: pass
func _process(_delta: float) -> void: pass
func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused: return
	if event.is_action_pressed("ultimate") and not event.is_echo() and Settings.allows_action("ultimate"):
		ultimate.activate()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: camera.size=maxf(12,camera.size-1.5)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: camera.size=minf(30,camera.size+1.5)

func _physics_process(delta: float) -> void:
	if player.health<=0:
		game_over=true
		run_state="dead"
		player.statuses.clear()
		if beach!=null: beach.stop_flow()
		_clear_evolution_visuals()
		if is_instance_valid(active_boss) and active_boss.has_method("cancel_attacks"): active_boss.cancel_attacks()
		ultimate.clear_visuals()
		menu.open_menu()
		return
	training_time+=delta
	elapsed=float(settings.minute)*60
	player.training_invincible=settings.invincible
	if obstacles!=null: obstacles.tick(delta)
	if beach!=null: beach.tick(delta)
	if stopped:
		for enemy in get_tree().get_nodes_in_group("all_enemies"):
			enemy.control_step(delta)
	for i in range(pending.size()-1,-1,-1):
		pending[i].left-=delta
		if pending[i].left<=0:
			var item: Dictionary=pending[i]
			if place_batch(item.spec,item.center,1,false)>0: pending.remove_at(i)
			else: pending[i].left=1.0
	fire_cooldown-=delta*player.statuses.attack_rate()
	if fire_cooldown<=0 and armory.levels.has("frost") and fire_at_nearest():
		fire_cooldown=Catalog.cooldown("frost",armory.levels.frost)
	armory.tick(delta)
	_update_camera()

func save_settings() -> void: saved=settings.duplicate(true)
func rebuild_player(reset_health: bool=false) -> void:
	clear_attacks(false)
	var old_position: Vector3=player.position
	var old_health: int=player.health
	var old_invulnerability: float=player.invulnerability
	var old_rotation: float=player.body.rotation.y
	ultimate.clear_visuals()
	armory.free()
	player.free()
	player=Player.new()
	player.character_id=settings.character
	actors.add_child(player)
	player.position=old_position
	player.body.rotation.y=old_rotation
	player.health=100 if reset_health else old_health
	player.invulnerability=0 if reset_health else old_invulnerability
	player.training_invincible=settings.invincible
	player.damage_received.connect(func(value): received+=value)
	player.has_frost=false
	player.weapon.hide()
	armory=WeaponSystem.new()
	armory.game=self
	add_child(armory)
	for id in settings.weapons:
		armory.acquire(id)
		armory.levels[id]=clampi(int(settings.weapons[id]),Catalog.min_rank(id),Catalog.max_rank(id))
	if armory.levels.has("starfall"): armory.cooldowns.starfall=Catalog.cooldown("starfall",armory.levels.starfall)
	player.weapon.visible=armory.levels.has("frost" if settings.character=="classic" else "heart")
	if is_instance_valid(player.frost_weapon): player.frost_weapon.visible=armory.levels.has("frost")
	for enemy in get_tree().get_nodes_in_group("all_enemies"): enemy.target=player
	for group in ["hostile_projectiles","enemy_clouds","beach_hazards"]:
		for hazard in get_tree().get_nodes_in_group(group): hazard.target=player
	ultimate.definition=Roster.ULTIMATES[Roster.CHARACTERS[player.character_id].ultimate]
	if reset_health:
		ultimate.charge=0
		ultimate.uses=0
	ultimate.refresh()
	fire_cooldown=0
	save_settings()

func set_weapon(id: String, rank: int) -> void:
	if rank==0: settings.weapons.erase(id)
	else: settings.weapons[id]=clampi(rank,Catalog.min_rank(id),Catalog.max_rank(id))
	rebuild_player()

func clear_attacks(hostile_only: bool) -> void:
	for actor in actors.get_children():
		if actor==player or actor.is_in_group("all_enemies"): continue
		var hostile: bool=actor.is_in_group("hostile_projectiles") or actor.is_in_group("enemy_clouds") or actor.is_in_group("beach_hazards")
		if hostile_only!=hostile: continue
		actor.free()

func clear_enemies() -> void:
	suppress_rewards=true
	pending.clear()
	formations.clear()
	for enemy in get_tree().get_nodes_in_group("all_enemies"): enemy.free()
	clear_attacks(false)
	clear_attacks(true)
	active_boss=null
	if obstacles!=null: obstacles.open_all()
	if beach!=null: beach.stop_flow()
	suppress_rewards=false

func switch_terrain(castle: bool, shore: bool=false) -> void:
	if terrain_castle==castle and is_instance_valid(beach)==shore: return
	clear_enemies()
	player.position=Vector3.ZERO
	if obstacles!=null: obstacles.free(); obstacles=null
	if beach!=null: beach.free(); beach=null
	player.statuses.clear()
	if shore:
		beach=preload("res://scripts/beach_field.gd").new(); beach.game=self; add_child(beach)
	terrain_castle=castle
	final_boss_spawned=castle or shore
	if castle:
		obstacles=O.new()
		obstacles.game=self
		add_child(obstacles)

func set_stopped(value: bool) -> void:
	stopped=value
	settings.stopped=value
	# Remove independent hazards, including projectiles that have not landed yet.
	clear_attacks(true)
	for enemy in get_tree().get_nodes_in_group("all_enemies"):
		if value:
			if enemy.has_method("cancel_attacks"): enemy.cancel_attacks()
			elif enemy.has_method("cancel_control_action"): enemy.cancel_control_action()
		enemy.set_physics_process(not value)
	save_settings()

func valid_position(point: Vector3, radius: float) -> bool:
	if absf(point.x)>23-radius or absf(point.z)>23-radius or not O.placement(self,point,radius): return false
	if point.distance_to(player.position)<radius+0.6: return false
	for enemy in get_tree().get_nodes_in_group("all_enemies"):
		if point.distance_to(enemy.position)<radius+enemy.hit_radius+0.15: return false
	return true

func radius_for(spec: Dictionary) -> float:
	return 2.0 if spec.type in ["mid","final"] else (0.65 if spec.type=="minion" else Enemy.STATS[spec.index].radius)

func place_batch(spec: Dictionary, center: Vector3, count: int, remember:=true) -> int:
	var placed:=0
	if remember:
		formation_sequence+=1
		spec=spec.duplicate()
		spec.formation_id=formation_sequence
	if spec.type in ["mid","final"] and is_instance_valid(active_boss) and not active_boss.dead: return 0
	for i in range(mini(count,100-get_tree().get_nodes_in_group("all_enemies").size())):
		var point:=center
		var found:=false
		for attempt in range(96):
			if attempt>0:
				var angle:=attempt*2.399963
				var distance:=sqrt(float(attempt))*0.7
				point=center+Vector3(cos(angle),0,sin(angle))*distance
			if valid_position(point,radius_for(spec)): found=true; break
		if not found: break
		var enemy=create_enemy(spec,point,float(settings.minute)*60)
		if enemy==null: break
		placed+=1
		if spec.type in ["normal","minion"]:
			enemy.defeated.connect(func():
				if not suppress_rewards and spec.get("refill",false): pending.append({"spec":spec,"center":center,"left":3.0}))
		if spec.type in ["mid","final"]: break
	if remember and placed>0: formations.append({"spec":spec,"center":center,"count":placed})
	return placed

func create_enemy(spec: Dictionary, point: Vector3, strength: float) -> Node3D:
	var enemy: Node3D
	match spec.type:
		"normal":
			enemy=load("res://scripts/beach_enemy.gd" if spec.index>=15 else "res://scripts/castle_enemy.gd" if spec.index>=10 else ("res://scripts/special_enemy.gd" if spec.index>=4 else "res://scripts/enemy.gd")).new()
			enemy.kind=spec.index
			var profile: Dictionary=Difficulty.profile(strength)
			enemy.health_multiplier=profile.hp
			enemy.damage_multiplier=profile.damage
			enemy.speed=Enemy.STATS[spec.index].speed*profile.speed/1.65 if spec.index>=10 else profile.speed
		"minion":
			enemy=preload("res://scripts/boss_minion.gd").new()
			enemy.second_phase=spec.index==1
		"mid":
			enemy=load("res://scripts/beach_miniboss.gd" if spec.index>=8 else "res://scripts/castle_miniboss.gd" if spec.index>=4 else "res://scripts/miniboss.gd").new()
			enemy.encounter=spec.index%4
			if spec.index<4: enemy.speed=Miniboss.ROSTER[spec.index].speed
		"final":
			enemy=load("res://scripts/octo.gd" if spec.index==2 else "res://scripts/noctis.gd" if spec.index==1 else "res://scripts/final_boss.gd").new()
			enemy.set_meta("phase_locked",true)
		_: return null
	enemy.target=player
	enemy.movement_phase=rng.randf_range(0,TAU)
	enemy.position=point
	Tiers.prepare(enemy,settings.get("difficulty","normal"))
	actors.add_child(enemy)
	Tiers.apply_hp(enemy)
	enemy.damage_received.connect(func(amount): dealt+=amount)
	enemy.rewarded.connect(_on_enemy_defeated)
	if spec.type=="mid": enemy.reward_value=8
	if spec.type in ["mid","final"]: active_boss=enemy
	if spec.type=="final": enemy.initialize_training_phase(spec.get("phase",1)==2)
	enemy.set_physics_process(not stopped)
	return enemy

func _on_enemy_defeated(amount:=1) -> void:
	if suppress_rewards: return
	kills+=1
	ultimate.reward(amount)

func reset_trial() -> void:
	var previous:=formations.duplicate(true)
	clear_enemies()
	game_over=false
	run_state="combat"
	player.position=Vector3.ZERO
	rebuild_player(true)
	kills=0; dealt=0; received=0; training_time=0
	for formation in previous: place_batch(formation.spec,formation.center,formation.count)

func return_title() -> void:
	save_settings()
	get_tree().paused=false
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func set_formation_refill(index: int, enabled: bool) -> void:
	var spec: Dictionary=formations[index].spec
	spec.refill=enabled
	if not enabled:
		for i in range(pending.size()-1,-1,-1):
			if pending[i].spec.get("formation_id",-1)==spec.formation_id: pending.remove_at(i)

# Scatter on valid floor; reuse the usual formation/reward/refill path.
func place_random(count: int, selected: Dictionary, mixed: bool=true) -> int:
	if game_over: return 0
	var placed:=0
	var available:=maxi(0,100-get_tree().get_nodes_in_group("all_enemies").size())
	for i in range(mini(clampi(count,1,100),available)):
		var spec: Dictionary=selected.duplicate()
		if mixed: spec={"type":"normal","index":rng.randi_range(0,20),"refill":selected.get("refill",false)}
		if spec.type not in ["normal","minion"]: break
		var found:=false
		for attempt in range(128):
			var point:=Vector3(rng.randf_range(-22,22),0,rng.randf_range(-22,22))
			if point.distance_to(player.position)<5 or not valid_position(point,radius_for(spec)): continue
			placed+=place_batch(spec,point,1)
			found=true
			break
		if not found: break
	return placed
