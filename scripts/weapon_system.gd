extends Node

const Catalog = preload("res://scripts/weapon_catalog.gd")
const Attack = preload("res://scripts/weapon_attack.gd")
const Advanced = preload("res://scripts/advanced_attack.gd")
const V = preload("res://scripts/visuals.gd")
var game: Node3D
var levels: Dictionary = {}
var cooldowns: Dictionary = {}
var mounts: Dictionary = {}
var orbit_attack: Node3D
var gust_attack: Node3D
const Motifs=preload("res://scripts/weapon_models.gd")
var cast_times: Dictionary={}
var time := 0.0
var last_trail := Vector3.INF
var consumed: Dictionary={}
var evolution_bag: Array[String]=[]
var evolution_seen: Array[String]=[]
var fusion_nodes: Dictionary={}
const E=preload("res://scripts/evolution_catalog.gd")


func acquire(id: String) -> void:
	if not id in Catalog.all_ids() or consumed.has(id) or int(levels.get(id,0))>=Catalog.max_rank(id):
		return
	levels[id] = maxi(Catalog.min_rank(id),int(levels.get(id, 0)) + 1)
	game.contributions.add("weapon:"+id,"damage",0)
	if id=="frost": game.player.equip_frost()
	if id == "frost" or mounts.has(id) or (id=="heart" and game.player.character_id=="pink"):
		return
	cooldowns[id] = Catalog.cooldown(id,1) if id=="starfall" else 0.0
	var mount := V.pivot(game.player.body if id=="udon" else game.player, "Weapon_" + id)
	preload("res://scripts/equipment_models.gd").build(mount,id)
	mounts[id] = mount


func tick(delta: float) -> void:
	time += delta
	var index := 0
	for id in mounts:
		if id=="udon":
			mounts[id].position=Vector3(-0.75,1,0.35)
			continue
		if id=="blizzard_fan":
			mounts[id].position=game.player.facing_direction()*0.9+Vector3.UP*0.8
			var facing: Vector3=fusion_nodes[id].core.direction if is_instance_valid(fusion_nodes.get(id)) else game.player.facing_direction()
			mounts[id].rotation.y=atan2(facing.x,facing.z)
			mounts[id].get_node("EvolutionModel/ControlModel/Rotor").rotation.z=time*14
			continue
		if id=="gust":
			mounts[id].position=game.player.facing_direction()*0.9+Vector3.UP*0.8
			var facing: Vector3=gust_attack.direction if is_instance_valid(gust_attack) else game.player.facing_direction()
			mounts[id].rotation.y=atan2(facing.x,facing.z)
			mounts[id].get_node("ControlModel/Rotor").rotation.z=time*14
			continue
		var angle := (index % 8) * TAU / mini(8, mounts.size())
		var reach := 1.2 + 0.65 * floori(index / 8.0)
		mounts[id].position = Vector3(cos(angle) * reach, 1.35 + sin(time * 2 + index) * 0.08, sin(angle) * reach)
		mounts[id].rotation.y = -angle
		if id=="rear_fan":
			mounts[id].position=-game.player.facing_direction()*0.85+Vector3.UP*0.85
			mounts[id].rotation.y=atan2(-game.player.facing_direction().x,-game.player.facing_direction().z)
		if mounts[id].has_node("EvolutionModel"):
			preload("res://scripts/evolution_models.gd").animate(mounts[id].get_node("EvolutionModel"),id,time,maxf(0,1-(time-float(cast_times.get(id,-100)))/0.22))
		if mounts[id].has_node("Motif"):
			var elapsed_cast: float=time-float(cast_times.get(id,-100))
			var pulse:=maxf(0,1-elapsed_cast/0.55)
			if id=="lightning": pulse=maxf(0,1-absf(elapsed_cast-0.37)/0.35)
			Motifs.animate(mounts[id].get_node("Motif"),id,time,pulse)
		index += 1
	for id in levels:
		if id == "frost":
			continue
		if id in ["gust","orbit","blizzard_fan","pearl_chime"]:
			fire(id)
			continue
		cooldowns[id] = float(cooldowns.get(id, 0.0)) - delta*game.player.statuses.attack_rate()
		if cooldowns[id] <= 0 and fire(id):
			cooldowns[id] = Catalog.cooldown(id, levels[id])
			cast_times[id]=time


func nearest(origin: Vector3, reach: float, excluded: Array = []) -> Node3D:
	var result: Node3D
	var best := reach * reach
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead or not enemy.targetable or excluded.has(enemy):
			continue
		var distance := origin.distance_squared_to(enemy.global_position)
		if distance <= best:
			result = enemy
			best = distance
	return result


func attach(attack: Node3D, id: String) -> void:
	attack.set_meta("weapon_id",id)
	game.actors.add_child(attack)
func fire(id: String) -> bool:
	if E.ITEMS.has(id): return fire_evolved(id)
	if not levels.has(id) or id == "frost":
		return false
	var stats:=Catalog.stats(id,levels[id])
	if id in ["shell_wave","bubble","crab_claw"]:
		var attack:=preload("res://scripts/beach_attack.gd").new()
		attack.mode=id; attack.stats=stats
		attack.position=game.player.global_position
		attack.direction=game.player.facing_direction()
		attach(attack,id)
		game.sound.play_effect("sea_cast")
		return true
	if id=="orbit":
		if not is_instance_valid(orbit_attack) or orbit_attack.is_queued_for_deletion():
			orbit_attack=preload("res://scripts/pearl_orbit.gd").new()
			orbit_attack.player=game.player
			orbit_attack.stats=stats
			attach(orbit_attack,id)
		else: orbit_attack.configure(stats)
		return true
	if id=="starfall":
		if float(cooldowns.get(id,stats.cooldown))>0: return false
		var excluded: Array=[]
		var enemy:=nearest(game.player.global_position,18)
		while enemy!=null and not preload("res://scripts/castle_obstacles.gd").placement(game,enemy.global_position,0.1):
			excluded.append(enemy)
			enemy=nearest(game.player.global_position,18,excluded)
		if enemy==null: return false
		var center: Vector3=enemy.global_position
		center.y=0
		if not preload("res://scripts/castle_obstacles.gd").placement(game,center,0.1): return false
		var star_attack:=preload("res://scripts/starfall_attack.gd").new()
		star_attack.position=center
		star_attack.damage=stats.damage
		star_attack.radius=stats.radius
		attach(star_attack,id)
		cooldowns[id]=stats.cooldown
		return true
	if id=="gust" and is_instance_valid(gust_attack) and not gust_attack.is_queued_for_deletion():
		gust_attack.stats=stats
		return true
	if id in ["gust","popsicle"]:
		var enemy:=nearest(game.player.global_position,12) if id=="popsicle" else null
		if id=="popsicle" and enemy==null: return false
		var attack:=preload("res://scripts/control_attack.gd").new()
		attack.mode=id
		attack.stats=stats
		if id=="gust":
			attack.player=game.player
			gust_attack=attack
		attack.direction=game.player.facing_direction() if id=="gust" else (enemy.global_position-game.player.global_position).normalized()
		attack.position=game.player.global_position+(Vector3.UP if id=="popsicle" else Vector3.ZERO)
		attach(attack,id)
		game.sound.play_effect("gust" if id=="gust" else "ice_cast")
		return true
	if id=="udon":
		var enemy:=nearest(game.player.global_position,stats.reach)
		if enemy==null: return false
		var attack:=preload("res://scripts/udon_attack.gd").new()
		attack.player=game.player
		attack.position=game.player.global_position+Vector3.UP
		attack.direction=(enemy.global_position-game.player.global_position).normalized()
		attack.reach=minf(stats.reach,enemy.global_position.distance_to(game.player.global_position))
		attack.splash_radius=stats.radius
		attack.damage=stats.damage
		attach(attack,id)
		game.sound.play_effect("magic")
		return true
	if id=="heart":
		var enemy:=nearest(game.player.global_position,stats.reach)
		if enemy==null: return false
		var heart:=preload("res://scripts/heart_projectile.gd").new()
		heart.position=game.player.global_position+Vector3.UP
		heart.direction=(enemy.global_position-game.player.global_position).normalized()
		heart.damage=stats.damage
		heart.max_distance=stats.reach
		heart.max_hits=stats.pierce
		heart.player=game.player
		attach(heart,id)
		game.sound.play_effect("magic")
		return true
	var origin: Vector3 = game.player.global_position
	var aimed: bool = id in ["boomerang", "storm", "bounce", "seeker", "beam"]
	var target: Node3D = nearest(origin, stats.get("reach",12.0)) if aimed else null
	if target == null and aimed:
		return false
	var direction: Vector3 = game.player.facing_direction()
	if id in ["rear_fan", "rear_bomb"]:
		direction = -direction
	if aimed:
		direction = (target.global_position - origin).normalized()
	var damage := Catalog.damage(id, levels[id])
	if id in ["whip", "trail", "bounce", "turret", "seeker", "beam"]:
		if id == "trail":
			if game.player.velocity.length_squared() < 0.1 or origin.distance_to(last_trail) < 0.8:
				return false
			last_trail = origin
		for index in range(int(stats.count) if id == "seeker" else 1):
			var special := Advanced.new()
			special.mode = id
			special.weapon_rank=levels[id]
			special.player = game.player
			special.position = origin + Vector3.UP
			special.direction = direction.rotated(Vector3.UP, (index - (int(stats.count)-1)/2.0) * 0.6 if id == "seeker" else 0.0)
			special.damage = damage
			special.tint = Catalog.ITEMS[id].color
			attach(special,id)
		game.sound.play_effect("slash" if id == "whip" else "magic")
		return true
	if id == "lightning":
		for index in range(int(stats.count)):
			var strike := Attack.new()
			strike.mode = "lightning"
			strike.position = random_visible_ground()
			strike.tint = Catalog.ITEMS[id].color
			strike.damage = damage
			strike.area_radius = stats.radius
			strike.warning_duration = 0.25 + index * 0.12
			strike.lifetime = strike.warning_duration + 0.3
			attach(strike,id)
		return true
	for index in range(int(stats.count) if id in ["fan", "rear_fan"] else 1):
		var attack := Attack.new()
		attack.player = game.player
		attack.tint = Catalog.ITEMS[id].color
		attack.damage = damage
		attack.position = origin + Vector3.UP
		attack.direction = direction
		match id:
			"fan", "rear_fan":
				attack.visual_kind="feather" if id=="fan" else "confetti"
				attack.direction = direction.rotated(Vector3.UP, (index - (int(stats.count)-1)/2.0) * 0.18)
				attack.speed = 16.0
				attack.lifetime = stats.reach/16.0
			"rear_bomb":
				attack.mode = "rear_bomb"
				attack.position = origin + direction * 4.5
				attack.launch_origin = origin + Vector3.UP
				attack.lifetime = 0.65
				attack.area_radius = stats.radius
			"spear":
				attack.visual_kind="lance"
				attack.piercing = true
				attack.radius = 0.26
				attack.speed = 26.0
				attack.damage = damage
				attack.lifetime = stats.reach/26.0
			"ember":
				attack.mode = "meteor"
				attack.position = origin + direction * 8.0
				attack.lifetime = 0.7
				attack.area_radius = stats.radius
			"boomerang":
				attack.mode = "boomerang"
				attack.piercing = true
				attack.speed = 14.0
				attack.radius = 0.35
				attack.lifetime = stats.duration
				attack.ellipse_reach=stats.travel
			"orbit":
				attack.mode = "orbit"
				attack.position = origin
				attack.area_radius = stats.radius
				attack.orbit_count=stats.count
				attack.radius = 0.3
				attack.lifetime = Catalog.cooldown(id, levels[id])
			"nova":
				attack.mode = "nova"
				attack.visual_kind="chime"
				attack.position = origin
				attack.area_radius = stats.radius
				attack.lifetime = 0.65
			"mine":
				attack.mode = "mine"
				attack.position = origin
				attack.area_radius = stats.radius
				attack.lifetime = stats.duration
			"storm":
				attack.mode = "storm"
				attack.position = target.global_position
				attack.area_radius = stats.radius
				attack.lifetime = stats.duration
		if not preload("res://scripts/castle_obstacles.gd").placement(game,attack.position,0.1):
			attack.free()
			return false
		attach(attack,id)
	game.sound.play_effect("shot" if id in ["fan", "rear_fan", "spear"] else "magic")
	return true


func random_visible_ground() -> Vector3:
	# Sample screen space and intersect the actual camera ray with the arena floor.
	# Enemy positions never influence the sample. Rejection keeps strikes on land.
	var camera: Camera3D = game.camera
	var size := camera.get_viewport().get_visible_rect().size
	for attempt in range(128):
		var pixel := Vector2(game.rng.randf_range(32, size.x - 32), game.rng.randf_range(32, size.y - 32))
		var start := camera.project_ray_origin(pixel)
		var ray := camera.project_ray_normal(pixel)
		if absf(ray.y) < 0.0001:
			continue
		var distance := -start.y / ray.y
		var point := start + ray * distance
		if distance > 0 and absf(point.x) <= 23 and absf(point.z) <= 23 and preload("res://scripts/castle_obstacles.gd").placement(game,point,0.1):
			point.y = 0
			return point
	return game.player.global_position

func evolution_count() -> int:
	var count:=0
	for id in levels:
		if E.ITEMS.has(id): count+=1
	return count
func available_evolutions() -> Array[String]:
	return E.available(levels,consumed,game.Stages.weapon_pool(game.stage_id))
func next_evolution() -> String:
	var available:=available_evolutions()
	for id in evolution_bag.duplicate():
		if not id in available: evolution_bag.erase(id)
	var additions: Array[String]=[]
	for id in available:
		if not id in evolution_bag and not id in evolution_seen: additions.append(id)
	if evolution_bag.is_empty() and additions.is_empty() and not available.is_empty():
		evolution_seen.clear(); additions=available.duplicate()
	while not additions.is_empty():
		var index: int=game.rng.randi_range(0,additions.size()-1)
		evolution_bag.append(additions[index]); additions.remove_at(index)
	if evolution_bag.is_empty(): return ""
	var result: String=evolution_bag.pop_front(); evolution_seen.append(result); return result
func evolve(recipe: String, output: String) -> bool:
	if game.player.health<=0 or game.game_over or game.victory or game.run_state!="combat": return false
	if not recipe in available_evolutions() or not output in E.RECIPES[recipe].outputs: return false
	var rank:=E.inherited_level(recipe,levels)
	for source in E.RECIPES[recipe].sources: remove_source(source)
	acquire(output); levels[output]=rank
	if fire(output): cooldowns[output]=Catalog.cooldown(output,rank)
	game.sound.play_effect("evolve")
	return true
func remove_source(id: String) -> void:
	for attack in game.actors.get_children():
		if attack.get_meta("weapon_id","")==id: attack.free()
	if mounts.has(id):
		if is_instance_valid(mounts[id]): mounts[id].free()
		mounts.erase(id)
	levels.erase(id); cooldowns.erase(id); cast_times.erase(id); consumed[id]=true
	if id=="frost":
		game.player.has_frost=false
		if is_instance_valid(game.player.frost_weapon): game.player.frost_weapon.hide()
		if game.player.character_id=="classic": game.player.weapon.hide()
	if id=="heart" and game.player.character_id=="pink": game.player.weapon.hide()
func fire_evolved(id: String) -> bool:
	if not levels.has(id): return false
	var values:=Catalog.stats(id,levels[id])
	var origin: Vector3=game.player.global_position
	if id in ["blizzard_fan","pearl_chime"]:
		if is_instance_valid(fusion_nodes.get(id)):
			fusion_nodes[id].configure(values); return true
		var node:=preload("res://scripts/fusion_attack.gd").new()
		node.mode=id; node.stats=values; node.player=game.player; node.rng=game.rng
		fusion_nodes[id]=node; attach(node,id); return true
	var target:=nearest(origin,values.reach) if id!="heart_ring" else null
	if id!="heart_ring" and target==null: return false
	var aim: Vector3=game.player.facing_direction() if id=="heart_ring" else (target.global_position-origin).normalized()
	if E.is_single(id):
		for i in range(int(values.count)):
			var bullet:=preload("res://scripts/evolution_projectile.gd").new()
			bullet.evolution_id=id; bullet.damage=values.damage; bullet.reach=values.reach; bullet.max_hits=values.pierce
			bullet.player=game.player; bullet.position=origin+Vector3.UP
			bullet.direction=aim.rotated(Vector3.UP,i*TAU/6 if id=="heart_ring" else (deg_to_rad((i-1)*12) if id=="triple_cannon" else 0.0))
			attach(bullet,id)
		game.sound.play_effect("shot" if id in ["pop_cannon","triple_cannon"] else "magic")
	else:
		var attack:=preload("res://scripts/fusion_attack.gd").new()
		attack.mode=id; attack.player=game.player; attack.stats=values; attack.rng=game.rng; attack.direction=aim
		attack.position=target.global_position if id=="thunder_dome" else origin+Vector3.UP
		if id=="thunder_dome" and not preload("res://scripts/castle_obstacles.gd").placement(game,attack.position,0.1):
			attack.free(); return false
		attach(attack,id)
		game.sound.play_effect("magic")
	return true
