extends Node3D
## Temporary attacks share collision/lifetime handling, but retain distinct movement.

const V = preload("res://scripts/visuals.gd")
var flourish: Node3D
var visual_kind := ""
var detail: Node3D
var launch_direction:=Vector3.BACK
var mode := "bolt"
var tint := Color("b5f5ff")
var direction := Vector3.BACK
var player: Node3D
var damage := 1
var speed := 16.0
var lifetime := 1.2
var radius := 0.18
var area_radius := 3.0
var blast_radius := 0.0
var piercing := false
var age := 0.0
var returning := false
var hit_times: Dictionary = {}
var ring: MeshInstance3D
var orbiters: Array[MeshInstance3D] = []
var visual: Node3D
var falling_ball: MeshInstance3D
var warning_duration := 0.25
var struck := false
var lightning_visual: Node3D
var launch_origin := Vector3.ZERO


func _ready() -> void:
	add_to_group("weapon_attacks")
	visual = V.pivot(self, "AttackVisual")
	if mode in ["storm","nova"]: add_flourish()
	match mode:
		"lightning":
			ring = preload("res://scripts/combat_visuals.gd").friendly(visual, area_radius)
			detail=make_detail("lightning",visual)
			lightning_visual=detail
			lightning_visual.hide()
		"meteor", "rear_bomb":
			ring = preload("res://scripts/combat_visuals.gd").friendly(visual, area_radius)
			falling_ball = V.ellipsoid(visual, tint, Vector3(0, 6, 0), Vector3.ONE * 0.4)
			if mode == "rear_bomb":
				falling_ball.position = launch_origin - position
				V.ring(falling_ball, Color("fff4be"), Vector3.ZERO, 1.15, 0.08, true)
		"nova", "storm", "mine", "orbit":
			ring = preload("res://scripts/combat_visuals.gd").friendly(visual, 1.0)
			if mode == "mine":
				V.ellipsoid(visual, tint, Vector3(0, 0.2, 0), Vector3(0.28, 0.25, 0.28))
				V.ellipsoid(visual, Color("775340"), Vector3(0, 0.38, 0), Vector3(0.31, 0.1, 0.31))
				V.rod(visual, Color("ffe88b"), Vector3(0, 0.4, 0), Vector3(0.08, 0.65, 0), 0.035)
			if mode == "orbit" or mode == "storm":
				for index in range(2 if mode == "orbit" else 6):
					orbiters.append(V.ellipsoid(visual, tint, Vector3.ZERO, Vector3.ONE * (0.28 if mode == "orbit" else 0.12)))
		"boomerang":
			V.ellipsoid(visual, tint, Vector3.ZERO, Vector3(0.2, 0.12, 0.45))
			V.rod(visual, Color("ffe3b0"), Vector3(0, 0, -0.35), Vector3(0, 0, -0.7), 0.03, 0.23)
			for side in [-1, 1]:
				V.ellipsoid(visual, Color("20374c"), Vector3(side * 0.15, 0.08, 0.2), Vector3.ONE * 0.045)
		_:
			if blast_radius > 0:
				V.ellipsoid(visual, tint, Vector3.ZERO, Vector3.ONE * 0.28)
				V.ring(visual, Color("fff1a7"), Vector3.ZERO, 0.31, 0.04, true)
			else:
				V.rod(visual, tint, Vector3(0, 0, -0.45 if piercing else -0.2), Vector3(0, 0, 0.6), 0.16, 0)
				V.rod(visual, Color("fff0cf"), Vector3(0, 0, -0.7), Vector3(0, 0, 0), 0.045)
	if visual_kind=="lance":
		for part in visual.get_children(): part.free()
		detail=make_detail("lance",visual)
	elif mode=="meteor":
		falling_ball.hide()
		detail=make_detail("fireball",visual)
	elif mode=="rear_bomb": detail=make_detail("fuse",visual)
	elif mode=="boomerang":
		launch_origin=global_position
		launch_direction=direction
		detail=make_detail("boomerang",visual)
	if mode == "bolt" or mode == "boomerang":
		preload("res://scripts/combat_visuals.gd").tail(visual)
		visual.rotation.y = atan2(direction.x, direction.z)


func _physics_process(delta: float) -> void:
	age += delta
	if is_instance_valid(flourish): flourish.animate(age,lifetime)
	if is_instance_valid(detail) and mode!="lightning": detail.animate(age,lifetime)
	if mode == "bolt" or mode == "boomerang":
		_move_projectile(delta)
	elif mode == "lightning":
		if age >= warning_duration and not struck:
			struck = true
			get_tree().call_group("game_audio", "play_effect", "thunder")
			lightning_visual.show()
			_area_hit(area_radius, false)
		if struck: detail.animate(age-warning_duration,0.3)
	elif mode in ["meteor", "rear_bomb"]:
		var progress := minf(age / lifetime, 1.0)
		if mode == "rear_bomb":
			falling_ball.position = (launch_origin - global_position) * (1.0 - progress) + Vector3.UP * sin(progress * PI) * 2.5
			falling_ball.rotation.y += delta * 9
		else:
			falling_ball.position.y = 6.0 * (1.0 - progress)
		detail.position=falling_ball.position
		if mode=="rear_bomb": detail.update_trail()
		if age >= lifetime:
			_explode()
			return
	elif mode == "nova":
		var expansion := area_radius * minf(age / lifetime, 1.0)
		ring.scale = Vector3(expansion, 1, expansion)
		_area_hit(expansion, false)
	elif mode == "mine":
		ring.scale = Vector3.ONE * (0.35 + 0.12 * sin(age * 9.0))
		if age > 0.65:
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not enemy.dead and _flat_distance(enemy.global_position, global_position) <= 1.3 + enemy.hit_radius:
					_explode()
					return
	elif mode == "storm":
		ring.scale = Vector3(area_radius, 1, area_radius)
		for index in range(orbiters.size()):
			var angle := age * 2.5 + index * TAU / orbiters.size()
			orbiters[index].position = Vector3(cos(angle) * area_radius * 0.65, 0.2 + fmod(index * 0.7 + age * 3.0, 2.5), sin(angle) * area_radius * 0.65)
		if age >= 0.4:
			_area_hit(area_radius, true)
	elif mode == "orbit":
		if not is_instance_valid(player):
			queue_free()
			return
		global_position = player.global_position
		ring.scale = Vector3(area_radius, 1, area_radius)
		for index in range(orbiters.size()):
			var angle := age * 3.0 + index * PI
			var old: Vector3 = global_position + Vector3(cos(angle - delta * 3) * area_radius, 1, sin(angle - delta * 3) * area_radius)
			orbiters[index].position = Vector3(cos(angle) * area_radius, 1, sin(angle) * area_radius)
			_segment_hit(old, orbiters[index].global_position, true)
	if is_queued_for_deletion():
		return
	if age >= lifetime:
		if mode == "bolt" and blast_radius > 0:
			_explode()
		else:
			queue_free()


func _move_projectile(delta: float) -> void:
	var start := global_position
	if mode == "boomerang":
		_move_ellipse(delta)
		return
	var finish := start + direction * speed * delta
	_segment_hit(start, finish, false)
	if not is_queued_for_deletion():
		global_position = finish
	if is_instance_valid(detail): detail.update_trail()


func _segment_hit(start: Vector3, finish: Vector3, repeat: bool) -> void:
	var hits: Array[Dictionary] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead or not _can_hit(enemy, repeat):
			continue
		var center: Vector3 = enemy.global_position + Vector3.UP
		var closest := Geometry3D.get_closest_point_to_segment(center, start, finish)
		if closest.distance_to(center) <= enemy.hit_radius + radius:
			hits.append({"enemy": enemy, "distance": start.distance_squared_to(closest), "point": closest})
	hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	for hit in hits:
		if hit.enemy.dead:
			continue
		if blast_radius > 0:
			global_position = hit.point
			_explode()
			return
		_damage(hit.enemy)
		if not piercing and mode in ["bolt", "seeker"]:
			queue_free()
			return


func _can_hit(enemy: Node3D, repeat: bool) -> bool:
	var id := enemy.get_instance_id()
	return not hit_times.has(id) or (repeat and age - float(hit_times[id]) >= 0.6)


func _damage(enemy: Node3D) -> void:
	hit_times[enemy.get_instance_id()] = age
	if visual_kind=="lance": spawn_detail("lance_hit",enemy.global_position+Vector3.UP,0.25,0.5)
	enemy.take_damage(damage)


func _area_hit(reach: float, repeat: bool) -> void:
	if damage <= 0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.dead and _can_hit(enemy, repeat) and _flat_distance(enemy.global_position, global_position) <= reach + enemy.hit_radius:
			_damage(enemy)


func _explode() -> void:
	if mode=="rear_bomb": spawn_detail("firework",position,0.8,area_radius)
	elif mode=="meteor": spawn_detail("fire_impact",position,0.45,area_radius)
	get_tree().call_group("game_audio", "play_effect", "blast")
	_area_hit(blast_radius if blast_radius > 0 else area_radius, false)
	var effect: Node3D = get_script().new()
	effect.mode = "nova"
	effect.tint = tint
	effect.area_radius = blast_radius if blast_radius > 0 else area_radius
	effect.damage = 0
	effect.lifetime = 0.3
	effect.position = Vector3(position.x, 0, position.z)
	get_parent().add_child(effect)
	queue_free()


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func add_flourish() -> void:
	flourish=preload("res://scripts/weapon_flourish.gd").new()
	flourish.mode=mode
	flourish.radius=area_radius
	flourish.direction=direction
	visual.add_child(flourish)

func make_detail(style: String, parent: Node3D) -> Node3D:
	var result:=preload("res://scripts/weapon_detail.gd").new()
	result.mode=style
	parent.add_child(result)
	return result
func spawn_detail(style: String, point: Vector3, duration: float, reach: float) -> void:
	if get_tree().get_nodes_in_group("weapon_impact_details").size()>=16: return
	var result:=preload("res://scripts/weapon_detail.gd").new()
	result.mode=style
	result.position=point
	result.direction=direction
	result.radius=reach
	result.auto_lifetime=duration
	result.add_to_group("weapon_impact_details")
	get_parent().add_child(result)
func ellipse_point(time: float) -> Vector3:
	var theta:=clampf(time/1.3,0,1)*TAU
	var side:=Vector3(-launch_direction.z,0,launch_direction.x)
	return launch_origin+launch_direction*(4.55*(1-cos(theta)))+side*(1.6*sin(theta))
func _move_ellipse(delta: float) -> void:
	var cursor:=maxf(0,age-delta)
	var end:=minf(age,lifetime)
	while cursor<end-0.000001:
		if cursor>=0.65-0.000001 and not returning:
			returning=true
			hit_times.clear()
		var next:=minf(end,cursor+1.0/120.0)
		if cursor<0.65: next=minf(next,0.65)
		elif cursor<1.3: next=minf(next,1.3)
		var start:=global_position
		var finish:=ellipse_point(next)
		var caught:=false
		if cursor>=1.3-0.000001:
			if not is_instance_valid(player): queue_free(); return
			var destination: Vector3=player.global_position+Vector3.UP
			finish=start.move_toward(destination,speed*(next-cursor))
			caught=finish.distance_to(destination)<=0.3
		_segment_hit(start,finish,false)
		global_position=finish
		var tangent:=finish-start
		if tangent.length_squared()>0.000001:
			direction=tangent.normalized()
			visual.rotation.y=atan2(direction.x,direction.z)
		cursor=next
		if caught: queue_free(); return
	if is_instance_valid(detail): detail.update_trail()
