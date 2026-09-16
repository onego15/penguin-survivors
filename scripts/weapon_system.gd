extends Node

const Catalog = preload("res://scripts/weapon_catalog.gd")
const Attack = preload("res://scripts/weapon_attack.gd")
const Advanced = preload("res://scripts/advanced_attack.gd")
const V = preload("res://scripts/visuals.gd")
var game: Node3D
var levels: Dictionary = {}
var cooldowns: Dictionary = {}
var mounts: Dictionary = {}
var time := 0.0
var last_trail := Vector3.INF


func acquire(id: String) -> void:
	if not Catalog.ITEMS.has(id):
		return
	levels[id] = int(levels.get(id, 0)) + 1
	if id=="frost": game.player.equip_frost()
	if id == "frost" or mounts.has(id) or (id=="heart" and game.player.character_id=="pink"):
		return
	cooldowns[id] = 0.0
	var mount := V.pivot(game.player, "Weapon_" + id)
	var tint: Color = Catalog.ITEMS[id].color
	V.rod(mount, Color("947044"), Vector3(0, -0.25, 0), Vector3(0, 0.15, 0), 0.04)
	match id:
		"heart": preload("res://scripts/character_models.gd").heart_wand(mount)
		"beam":
			preload("res://scripts/prism_visual.gd").build_crystal(mount)
		"rear_fan":
			for index in range(3):
				V.rod(mount, tint, Vector3((index - 1) * 0.14, 0, 0), Vector3((index - 1) * 0.2, 0.4, 0), 0.07)
		"rear_bomb":
			V.rod(mount, tint, Vector3.ZERO, Vector3(0, 0.35, 0), 0.18)
			V.rod(mount, Color("fff4be"), Vector3(0, 0.35, 0), Vector3(0, 0.6, 0), 0.18, 0)
		"whip":
			V.ring(mount, tint, Vector3(0, 0.25, 0), 0.28, 0.045, true)
			V.rod(mount, tint, Vector3.ZERO, Vector3(0, 0.55, 0), 0.1, 0)
		"turret":
			V.ellipsoid(mount, tint, Vector3.ZERO, Vector3.ONE * 0.23)
			V.ellipsoid(mount, tint, Vector3(0, 0.3, 0), Vector3.ONE * 0.16)
		"trail":
			for index in range(3):
				V.rod(mount, tint, Vector3((index - 1) * 0.15, 0, 0), Vector3((index - 1) * 0.15, 0.4, 0), 0.1, 0)
		"seeker":
			V.ellipsoid(mount, tint, Vector3(0, 0.2, 0), Vector3(0.14, 0.14, 0.28))
			V.ellipsoid(mount, Color.WHITE, Vector3(0, 0.3, 0), Vector3(0.4, 0.04, 0.12))
		"fan":
			for index in range(3):
				V.rod(mount, tint, Vector3.ZERO, Vector3((index - 1) * 0.19, 0.4, 0), 0.1, 0)
		"spear": V.rod(mount, tint, Vector3(0, 0.1, 0), Vector3(0, 0.65, 0), 0.14, 0)
		"lightning", "nova":
			V.rod(mount, tint, Vector3(0, 0.05, 0), Vector3(0, 0.4, 0), 0.24, 0.06)
			V.ring(mount, Color("ffe0a0"), Vector3(0, 0.05, 0), 0.23, 0.025)
		"boomerang":
			V.ellipsoid(mount, tint, Vector3(0, 0.2, 0), Vector3(0.3, 0.12, 0.1))
			V.rod(mount, tint, Vector3(-0.25, 0.2, 0), Vector3(-0.45, 0.2, 0), 0.02, 0.13)
		_:
			V.ellipsoid(mount, tint, Vector3(0, 0.23, 0), Vector3.ONE * 0.2)
			V.ring(mount, Color("ffe0a0"), Vector3(0, 0.1, 0), 0.21, 0.025)
	mounts[id] = mount


func tick(delta: float) -> void:
	time += delta
	var index := 0
	for id in mounts:
		var angle := time * 0.35 + (index % 8) * TAU / mini(8, mounts.size())
		var reach := 1.2 + 0.65 * floori(index / 8.0)
		mounts[id].position = Vector3(cos(angle) * reach, 1.35 + sin(time * 2 + index) * 0.08, sin(angle) * reach)
		mounts[id].rotation.y = -angle
		index += 1
	for id in levels:
		if id == "frost":
			continue
		cooldowns[id] = float(cooldowns.get(id, 0.0)) - delta
		if cooldowns[id] <= 0 and fire(id):
			cooldowns[id] = Catalog.cooldown(id, levels[id])


func nearest(origin: Vector3, reach: float, excluded: Array = []) -> Node3D:
	var result: Node3D
	var best := reach * reach
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead or excluded.has(enemy):
			continue
		var distance := origin.distance_squared_to(enemy.global_position)
		if distance <= best:
			result = enemy
			best = distance
	return result


func fire(id: String) -> bool:
	if not levels.has(id) or id == "frost":
		return false
	if id=="heart":
		var enemy:=nearest(game.player.global_position,12)
		if enemy==null: return false
		var heart:=preload("res://scripts/heart_projectile.gd").new()
		heart.position=game.player.global_position+Vector3.UP
		heart.direction=(enemy.global_position-game.player.global_position).normalized()
		heart.damage=Catalog.damage(id,levels[id])
		heart.player=game.player
		game.actors.add_child(heart)
		game.sound.play_effect("magic")
		return true
	var origin: Vector3 = game.player.global_position
	var aimed: bool = id in ["boomerang", "storm", "bounce", "seeker", "beam"]
	var target: Node3D = nearest(origin, 12.0) if aimed else null
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
		for index in range(3 if id == "seeker" else 1):
			var special := Advanced.new()
			special.mode = id
			special.player = game.player
			special.position = origin + Vector3.UP
			special.direction = direction.rotated(Vector3.UP, (index - 1) * 0.6 if id == "seeker" else 0.0)
			special.damage = damage
			special.tint = Catalog.ITEMS[id].color
			game.actors.add_child(special)
		game.sound.play_effect("slash" if id == "whip" else "magic")
		return true
	if id == "lightning":
		for index in range(3):
			var strike := Attack.new()
			strike.mode = "lightning"
			strike.position = random_visible_ground()
			strike.tint = Catalog.ITEMS[id].color
			strike.damage = damage
			strike.area_radius = 3.0
			strike.warning_duration = 0.25 + index * 0.12
			strike.lifetime = strike.warning_duration + 0.3
			game.actors.add_child(strike)
		return true
	for index in range(5 if id in ["fan", "rear_fan"] else 1):
		var attack := Attack.new()
		attack.player = game.player
		attack.tint = Catalog.ITEMS[id].color
		attack.damage = damage
		attack.position = origin + Vector3.UP
		attack.direction = direction
		match id:
			"fan", "rear_fan":
				attack.direction = direction.rotated(Vector3.UP, (index - 2) * 0.18)
				attack.speed = 16.0
				attack.lifetime = 0.85
			"rear_bomb":
				attack.mode = "rear_bomb"
				attack.position = origin + direction * 4.5
				attack.launch_origin = origin + Vector3.UP
				attack.lifetime = 0.65
				attack.area_radius = 3.0
			"spear":
				attack.visual_kind="lance"
				attack.piercing = true
				attack.radius = 0.26
				attack.speed = 26.0
				attack.damage = damage
				attack.lifetime = 0.75
			"ember":
				attack.mode = "meteor"
				attack.position = origin + direction * 8.0
				attack.lifetime = 0.7
				attack.area_radius = 3.2
			"boomerang":
				attack.mode = "boomerang"
				attack.piercing = true
				attack.speed = 14.0
				attack.radius = 0.35
				attack.lifetime = 2.4
			"orbit":
				attack.mode = "orbit"
				attack.position = origin
				attack.area_radius = 2.2
				attack.radius = 0.3
				attack.lifetime = Catalog.cooldown(id, levels[id])
			"nova":
				attack.mode = "nova"
				attack.visual_kind="chime"
				attack.position = origin
				attack.area_radius = 4.2
				attack.lifetime = 0.65
			"mine":
				attack.mode = "mine"
				attack.position = origin
				attack.area_radius = 3.0
				attack.lifetime = 8.0
			"storm":
				attack.mode = "storm"
				attack.position = target.global_position
				attack.area_radius = 2.6
				attack.lifetime = 3.2
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
		if distance > 0 and absf(point.x) <= 23 and absf(point.z) <= 23:
			point.y = 0
			return point
	return game.player.global_position
