extends Node

const Catalog = preload("res://scripts/weapon_catalog.gd")
const Attack = preload("res://scripts/weapon_attack.gd")
const V = preload("res://scripts/visuals.gd")
var game: Node3D
var levels: Dictionary = {"frost": 1}
var cooldowns: Dictionary = {}
var mounts: Dictionary = {}
var time := 0.0


func acquire(id: String) -> void:
	if not Catalog.ITEMS.has(id):
		return
	levels[id] = int(levels.get(id, 0)) + 1
	if id == "frost" or mounts.has(id):
		return
	cooldowns[id] = 0.0
	var mount := V.pivot(game.player, "Weapon_" + id)
	var tint: Color = Catalog.ITEMS[id].color
	V.rod(mount, Color("947044"), Vector3(0, -0.25, 0), Vector3(0, 0.15, 0), 0.04)
	match id:
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
		var angle := time * 0.35 + index * TAU / mounts.size()
		mounts[id].position = Vector3(cos(angle) * 1.2, 1.35 + sin(time * 2 + index) * 0.08, sin(angle) * 1.2)
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
	var origin: Vector3 = game.player.global_position
	var target := nearest(origin, 12.0)
	if target == null and not id in ["orbit", "nova", "mine"]:
		return false
	var direction := Vector3.BACK
	if target != null:
		direction = (target.global_position - origin).normalized()
	var damage := Catalog.damage(id, levels[id])
	if id == "lightning":
		var used: Array = []
		var start := origin + Vector3.UP
		for index in range(3):
			if target == null:
				break
			var finish: Vector3 = target.global_position + Vector3.UP
			_trace(start, finish, Catalog.ITEMS[id].color)
			used.append(target)
			target.take_damage(damage)
			start = finish
			target = nearest(finish - Vector3.UP, 5.0, used)
		return true
	for index in range(5 if id == "fan" else 1):
		var attack := Attack.new()
		attack.player = game.player
		attack.tint = Catalog.ITEMS[id].color
		attack.damage = damage
		attack.position = origin + Vector3.UP
		attack.direction = direction
		match id:
			"fan":
				attack.direction = direction.rotated(Vector3.UP, (index - 2) * 0.18)
				attack.speed = 16.0
				attack.lifetime = 0.85
			"spear":
				attack.piercing = true
				attack.speed = 26.0
				attack.damage = damage
				attack.lifetime = 0.75
			"ember":
				attack.speed = 11.0
				attack.lifetime = 1.3
				attack.blast_radius = 2.7
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
	return true


func _trace(start: Vector3, finish: Vector3, tint: Color) -> void:
	var bolt := V.pivot(game.actors, "Lightning")
	var bend := (start + finish) * 0.5 + Vector3(0.25, 0.65, -0.2)
	V.rod(bolt, tint, start, bend, 0.055)
	V.rod(bolt, tint, bend, finish, 0.055)
	var tween := bolt.create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(bolt.queue_free)
