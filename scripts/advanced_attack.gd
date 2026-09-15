extends "res://scripts/weapon_attack.gd"

const Shot = preload("res://scripts/weapon_attack.gd")
var pulse := 0.0
var beam_length := 12.0
var prism: Node3D

func _ready() -> void:
	add_to_group("weapon_attacks")
	visual = V.pivot(self, "SpecialVisual")
	piercing = true
	match mode:
		"whip":
			lifetime = 0.35
			for i in range(17):
				var d := direction.rotated(Vector3.UP, lerpf(-PI / 3, PI / 3, i / 16.0))
				V.ellipsoid(visual, tint, d * 3.5, Vector3.ONE * 0.18)
		"trail":
			lifetime = 4.0
			area_radius = 1.25
			position.y = 0
			V.ring(visual, tint, Vector3(0, 0.08, 0), area_radius, 0.07)
			for i in range(5):
				V.rod(visual, tint, Vector3((i - 2) * 0.35, 0, 0), Vector3((i - 2) * 0.35, 0.6, 0), 0.18, 0)
		"bounce":
			lifetime = 5.0
			speed = 16
			radius = 0.45
			V.ellipsoid(visual, tint, Vector3.ZERO, Vector3.ONE * radius)
			V.ring(visual, Color.WHITE, Vector3.ZERO, radius, 0.04, true)
		"turret":
			lifetime = 8
			V.ellipsoid(visual, tint, Vector3(0, -0.5, 0), Vector3.ONE * 0.5)
			V.ellipsoid(visual, tint, Vector3(0, 0.15, 0), Vector3.ONE * 0.35)
			V.rod(visual, Color("ffb767"), Vector3(0, 0.15, 0), Vector3(0, 0.15, 0.65), 0.13, 0.06)
		"seeker":
			piercing = false
			lifetime = 3
			speed = 11
			radius = 0.25
			V.ellipsoid(visual, tint, Vector3.ZERO, Vector3(0.2, 0.2, 0.4))
			for side in [-1, 1]:
				V.ellipsoid(visual, Color.WHITE, Vector3(side * 0.25, 0.12, 0), Vector3(0.3, 0.07, 0.2))
		"beam":
			lifetime = 1.3
			radius = 0.45
			prism = preload("res://scripts/prism_visual.gd").new()
			prism.direction = direction
			prism.length = beam_length
			visual.add_child(prism)

func _physics_process(delta: float) -> void:
	age += delta
	match mode:
		"whip":
			global_position = player.global_position + Vector3.UP
			for enemy in get_tree().get_nodes_in_group("enemies"):
				var offset: Vector3 = enemy.global_position - player.global_position
				offset.y = 0
				if not enemy.dead and _can_hit(enemy, false) and offset.length() <= 3.8 + enemy.hit_radius and (offset.length() < 0.1 or direction.dot(offset.normalized()) >= 0.5):
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
					bullet.lifetime = 0.8
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
			prism.animate(age, lifetime)
			_segment_hit(global_position, global_position + direction * beam_length, true)
	if age >= lifetime:
		queue_free()

func closest_enemy() -> Node3D:
	var best: Node3D
	var distance := 144.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_squared_to(enemy.global_position + Vector3.UP)
		if not enemy.dead and d < distance:
			best = enemy
			distance = d
	return best
