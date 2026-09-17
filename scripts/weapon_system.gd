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


func acquire(id: String) -> void:
	if not Catalog.ITEMS.has(id) or int(levels.get(id,0))>=Catalog.MAX_RANK:
		return
	levels[id] = int(levels.get(id, 0)) + 1
	if id=="frost": game.player.equip_frost()
	if id == "frost" or mounts.has(id) or (id=="heart" and game.player.character_id=="pink"):
		return
	cooldowns[id] = Catalog.cooldown(id,1) if id=="starfall" else 0.0
	var mount := V.pivot(game.player.body if id=="udon" else game.player, "Weapon_" + id)
	var tint: Color = Catalog.ITEMS[id].color
	if id in ["spear","boomerang"]: V.rod(mount, Color("947044"), Vector3(0, -0.25, 0), Vector3(0, 0.15, 0), 0.04)
	match id:
		"ember","lightning","nova","mine","storm","whip","trail","bounce","turret","seeker","fan":
			var motif:=Motifs.build(mount,id)
			if id=="turret": motif.scale=Vector3.ONE*0.48
			if id=="fan": motif.rotation.x=PI/2
		"starfall": preload("res://scripts/starfall_attack.gd").star(mount,0.3)
		"gust", "popsicle": preload("res://scripts/control_attack.gd").build_model(mount,id)
		"udon": preload("res://scripts/udon_attack.gd").bowl(mount)
		"heart": preload("res://scripts/character_models.gd").heart_wand(mount)
		"beam": preload("res://scripts/prism_visual.gd").build_crystal(mount)
		"rear_fan":
			V.rod(mount,Color("b695d7"),Vector3(0,0,-0.15),Vector3(0,0,0.35),0.06,0.2)
			var seal:=Motifs.build(mount,"rear_fan")
			seal.scale=Vector3.ONE*0.45; seal.position=Vector3(0,0.13,0.15)
		"rear_bomb":
			V.ellipsoid(mount,Color("bc8fd7"),Vector3.ZERO,Vector3.ONE*0.23)
			V.rod(mount,Color("ffe4bd"),Vector3(0,0.2,0),Vector3(0.1,0.43,0),0.025)
		"orbit":
			for i in range(3): V.ellipsoid(mount,Color("c5ddf8"),Vector3((i-1)*0.17,0,0),Vector3.ONE*0.085)
		"spear": V.rod(mount, tint, Vector3(0, 0.1, 0), Vector3(0, 0.65, 0), 0.14, 0)
		"boomerang":
			V.ellipsoid(mount, tint, Vector3(0, 0.2, 0), Vector3(0.3, 0.12, 0.1))
			V.rod(mount, tint, Vector3(-0.25, 0.2, 0), Vector3(-0.45, 0.2, 0), 0.02, 0.13)
	mounts[id] = mount


func tick(delta: float) -> void:
	time += delta
	var index := 0
	for id in mounts:
		if id=="udon":
			mounts[id].position=Vector3(-0.75,1,0.35)
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
		if mounts[id].has_node("Motif"):
			var elapsed_cast: float=time-float(cast_times.get(id,-100))
			var pulse:=maxf(0,1-elapsed_cast/0.55)
			if id=="lightning": pulse=maxf(0,1-absf(elapsed_cast-0.37)/0.35)
			Motifs.animate(mounts[id].get_node("Motif"),id,time,pulse)
		index += 1
	for id in levels:
		if id == "frost":
			continue
		if id in ["gust","orbit"]:
			fire(id)
			continue
		cooldowns[id] = float(cooldowns.get(id, 0.0)) - delta
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


func fire(id: String) -> bool:
	if not levels.has(id) or id == "frost":
		return false
	var stats:=Catalog.stats(id,levels[id])
	if id=="orbit":
		if not is_instance_valid(orbit_attack) or orbit_attack.is_queued_for_deletion():
			orbit_attack=preload("res://scripts/pearl_orbit.gd").new()
			orbit_attack.player=game.player
			orbit_attack.stats=stats
			game.actors.add_child(orbit_attack)
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
		game.actors.add_child(star_attack)
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
		game.actors.add_child(attack)
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
		game.actors.add_child(attack)
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
		game.actors.add_child(heart)
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
			game.actors.add_child(special)
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
			game.actors.add_child(strike)
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
		game.actors.add_child(attack)
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
