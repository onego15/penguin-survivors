extends "res://scripts/weapon_attack.gd"

const Shot = preload("res://scripts/weapon_attack.gd")
var pulse := 0.0
var target_reach:=12.0
var whip_reach:=3.8
var beam_length := 12.0
var prism: Node3D

func _ready() -> void:
	var stats:=preload("res://scripts/weapon_catalog.gd").stats(mode,weapon_rank)
	target_reach=stats.get("reach",12.0)
	add_to_group("weapon_attacks")
	visual = V.pivot(self, "SpecialVisual")
	piercing = true
	match mode:
		"whip":
			lifetime = 0.35
			whip_reach=stats.radius
			add_flourish()
			flourish.scale=Vector3(whip_reach/3.8,1,whip_reach/3.8)
		"trail":
			lifetime = stats.duration
			area_radius = stats.radius
			position.y = 0
			preload("res://scripts/combat_visuals.gd").friendly(visual, area_radius)
			add_flourish()
			flourish.scale=Vector3(area_radius/1.25,1,area_radius/1.25)
		"bounce":
			lifetime = stats.duration
			speed = 16
			radius = 0.45
			V.ellipsoid(visual, tint, Vector3.ZERO, Vector3.ONE * radius)
			V.ring(visual, Color.WHITE, Vector3.ZERO, radius, 0.04, true)
		"turret":
			lifetime = stats.duration
			V.ellipsoid(visual, tint, Vector3(0, -0.5, 0), Vector3.ONE * 0.5)
			V.ellipsoid(visual, tint, Vector3(0, 0.15, 0), Vector3.ONE * 0.35)
			V.rod(visual, Color("ffb767"), Vector3(0, 0.15, 0), Vector3(0, 0.15, 0.65), 0.13, 0.06)
		"seeker":
			piercing = false
			lifetime = stats.duration
			speed = 11
			radius = 0.25
			V.ellipsoid(visual, tint, Vector3.ZERO, Vector3(0.2, 0.2, 0.4))
			for side in [-1, 1]:
				V.ellipsoid(visual, Color.WHITE, Vector3(side * 0.25, 0.12, 0), Vector3(0.3, 0.07, 0.2))
		"beam":
			lifetime = stats.duration
			beam_length=stats.reach
			radius = 0.45
			prism = preload("res://scripts/prism_visual.gd").new()
			prism.direction = Vector3.BACK
			prism.rotation.y=atan2(direction.x,direction.z)
			prism.length = beam_length
			visual.add_child(prism)

	if mode in ["bounce","seeker"]:
		preload("res://scripts/combat_visuals.gd").tail(visual)

func _physics_process(delta: float) -> void:
	age += delta
	if is_instance_valid(flourish): flourish.animate(age,lifetime)
	if mode in ["bounce","seeker"]: visual.rotation.y=atan2(direction.x,direction.z)
	match mode:
		"whip":
			global_position = player.global_position + Vector3.UP
			for enemy in get_tree().get_nodes_in_group("enemies"):
				var offset: Vector3 = enemy.global_position - player.global_position
				offset.y = 0
				if not enemy.dead and _can_hit(enemy, false) and offset.length() <= whip_reach + enemy.hit_radius and (offset.length() < 0.1 or direction.dot(offset.normalized()) >= 0.5):
					_damage(enemy)
		"trail":
			_area_hit(area_radius, true)
			visual.scale.y = 0.8 + sin(age * 12) * 0.2
		"bounce":
			# Substeps preserve the reflected collision path even at a low frame rate.
			var steps := maxi(1, ceili(speed * delta / 0.4))
			for step in range(steps):
				var start := global_position
				var finish := start + direction * speed * delta / steps
				if absf(finish.x) > 23:
					finish.x = signf(finish.x) * (46 - absf(finish.x))
					direction.x *= -1
				if absf(finish.z) > 23:
					finish.z = signf(finish.z) * (46 - absf(finish.z))
					direction.z *= -1
				var obstacle=O.world(self)
				if obstacle!=null:
					var wall: Dictionary=obstacle.sweep(start,finish,radius)
					if wall.t<1:
						finish=wall.point
						direction=direction.bounce(wall.normal)
				_segment_hit(start, finish, true)
				global_position = finish
		"turret":
			pulse -= delta
			if pulse <= 0:
				var enemy := closest_enemy()
				if enemy != null:
					var bullet := Shot.new()
					bullet.position = position
					bullet.direction = (enemy.global_position + Vector3.UP - global_position).normalized()
					bullet.damage = damage
					bullet.tint = tint
					bullet.lifetime = maxf(0.8,target_reach/16.0)
					get_parent().add_child(bullet)
					visual.rotation.y = atan2(bullet.direction.x, bullet.direction.z)
				pulse = 0.55
		"seeker":
			var enemy := closest_enemy()
			if enemy != null:
				var desired := (enemy.global_position + Vector3.UP - global_position).normalized()
				direction = direction.lerp(desired, minf(1, delta * 7)).normalized()
			var start := global_position
			var finish := start + direction * speed * delta
			_segment_hit(start, finish, false)
			global_position = finish
			visual.rotation.y = atan2(direction.x, direction.z)
			if not hit_times.is_empty():
				queue_free()
		"beam":
			var obstacle=O.world(self)
			var visible_length:=beam_length
			if obstacle!=null: visible_length*=float(obstacle.sweep(global_position,global_position+direction*beam_length,0).t)
			prism.scale.z=maxf(0.001,visible_length/beam_length)
			prism.animate(age, lifetime)
			_segment_hit(global_position, global_position + direction * beam_length, true)
	if age >= lifetime:
		queue_free()

func closest_enemy() -> Node3D:
	var best: Node3D
	var distance := target_reach*target_reach
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_squared_to(enemy.global_position + Vector3.UP)
		if not enemy.dead and d < distance:
			best = enemy
			distance = d
	return best
