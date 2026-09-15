extends "res://scripts/enemy.gd"

const Bolt = preload("res://scripts/boss_projectile.gd")
var boss_name := "冬の王・グレイシャー"
var enraged := false
var attack_cooldown := 2.5
var warning_left := 0.0
var attack_index := 0
var attack_kind := ""
var locked_direction := Vector3.FORWARD
var warning_ring: MeshInstance3D
var aim_line: MeshInstance3D
var flash_left := 0.0
var dash_left := 0.0
var dash_speed := 16.0
var dash_distance := 11.0
var dash_recovery := 1.2
var recovery_left := 0.0
var dash_hit := false
var dash_marker: MeshInstance3D
const SLAM_RADIUS := 5.2


func _ready() -> void:
	kind = Kind.TURTLE
	visual_scale = 2.4
	super._ready()
	model.free()
	model = Visuals.pivot(self, "PolarKing")
	_build_polar_bear()
	model.scale = Vector3.ONE * visual_scale
	health = 1400
	max_health = health
	hit_radius = 1.55
	contact_damage = 24
	health_bar.position.y = 5.8
	warning_ring = Visuals.ring(self, Color("ec8fe9"), Vector3(0, 0.06, 0), SLAM_RADIUS, 0.085)
	var line := BoxMesh.new()
	line.size = Vector3(0.18, 0.035, 8)
	aim_line = Visuals.mesh(self, line, Color("bf80ed"))
	warning_ring.hide()
	aim_line.hide()
	var lane := BoxMesh.new()
	lane.size = Vector3((hit_radius + 0.42) * 2, 0.025, 11)
	dash_marker = Visuals.mesh(self, lane, Color("f0a568"))
	dash_marker.hide()
	add_to_group("final_bosses")


func _build_polar_bear() -> void:
	var fur := Color("e4edf5")
	Visuals.ellipsoid(model, fur, Vector3(0, 0.8, -0.05), Vector3(0.75, 0.85, 0.63))
	Visuals.ellipsoid(model, Color("bed5e5"), Vector3(0, 0.75, 0.48), Vector3(0.48, 0.57, 0.16))
	var head := Visuals.pivot(model, "Head", Vector3(0, 1.75, 0.22))
	Visuals.ellipsoid(head, fur, Vector3.ZERO, Vector3(0.68, 0.56, 0.5))
	for side in [-1.0, 1.0]:
		Visuals.ellipsoid(head, fur, Vector3(side * 0.51, 0.4, -0.02), Vector3.ONE * 0.22)
		Visuals.ellipsoid(head, Color("8199b5"), Vector3(side * 0.51, 0.4, 0.16), Vector3(0.13, 0.13, 0.035))
		Visuals.ellipsoid(model, fur, Vector3(side * 0.64, 0.75, 0), Vector3(0.24, 0.61, 0.27))
		Visuals.rod(head, Color("395474"), Vector3(side * 0.15, 0.14, 0.46), Vector3(side * 0.41, 0.22, 0.38), 0.045)
	Visuals.ellipsoid(head, Color("f1f7f8"), Vector3(0, -0.15, 0.47), Vector3(0.32, 0.22, 0.21))
	Visuals.ellipsoid(head, Color("263d57"), Vector3(0, -0.08, 0.65), Vector3(0.14, 0.09, 0.065))
	Models.eyes(head, 0.27, 0.045, 0.459, 0.085)
	Models.paws(model, fur, 0.46, 0.28, 0.26)
	Visuals.ring(head, Color("b38de9"), Vector3(0, 0.45, 0), 0.47, 0.07)
	for index in range(7):
		var angle := index * TAU / 7
		var point := Vector3(cos(angle) * 0.44, 0.45, sin(angle) * 0.44)
		Visuals.rod(head, Color("a4e9fa"), point, point + Vector3(0, 0.5 if index % 2 == 0 else 0.3, 0), 0.12, 0)
	Visuals.ring(model, Color("8666b5"), Vector3(0, 1.25, 0), 0.68, 0.08)


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	age += delta
	hurt_time = maxf(0, hurt_time - delta)
	enraged = health <= max_health / 2
	if dash_left > 0:
		_tick_dash(delta)
		return
	if recovery_left > 0:
		recovery_left = maxf(0, recovery_left - delta)
		model.rotation.x = 0
		model.rotation.z = 0
		return
	if warning_left > 0:
		warning_left = maxf(0, warning_left - delta)
		model.rotation.z = sin(age * 30) * 0.03
		if warning_left <= 0:
			_release_attack()
		return
	flash_left = maxf(0, flash_left - delta)
	if flash_left <= 0:
		warning_ring.hide()
	var offset := target.global_position - global_position
	offset.y = 0
	var movement := offset.normalized() * (3.0 if enraged else 2.1) * delta
	if offset.length() > 1.8:
		global_position += movement
		model.rotation.y = lerp_angle(model.rotation.y, atan2(offset.x, offset.z), 1 - exp(-delta * 8))
	_animate(2.0)
	if global_position.distance_to(target.global_position) < hit_radius + 0.42:
		target.take_damage(contact_damage)
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		attack_kind = "slam" if attack_index % 2 == 0 and offset.length() < 7 else "shards"
		if attack_index % 3 == 2:
			attack_kind = "dash"
		attack_index += 1
		warning_left = 1.3 if attack_kind == "slam" else 1.0
		locked_direction = offset.normalized() if offset.length() > 0.01 else Vector3.FORWARD
		if attack_kind == "dash":
			warning_left = 0.8 if enraged else 1.0
			dash_speed = 20.0 if enraged else 16.0
			dash_distance = 13.0 if enraged else 11.0
			dash_recovery = 1.0 if enraged else 1.2
			var lane: BoxMesh = dash_marker.mesh
			lane.size.z = dash_distance
			dash_marker.position = locked_direction * dash_distance * 0.5 + Vector3(0, 0.06, 0)
			dash_marker.rotation.y = atan2(locked_direction.x, locked_direction.z)
			model.rotation.y = dash_marker.rotation.y
			dash_marker.show()
			get_tree().call_group("game_audio", "play_effect", "warning")
		elif attack_kind == "slam":
			warning_ring.show()
		else:
			aim_line.position = locked_direction * 4 + Vector3(0, 0.05, 0)
			aim_line.rotation.y = atan2(locked_direction.x, locked_direction.z)
			aim_line.show()


func _release_attack() -> void:
	aim_line.hide()
	if attack_kind == "dash":
		dash_marker.hide()
		dash_left = dash_distance
		dash_hit = false
		get_tree().call_group("game_audio", "play_effect", "slash")
	elif attack_kind == "slam":
		if global_position.distance_to(target.global_position) < SLAM_RADIUS + 0.42:
			target.take_damage(28)
		flash_left = 0.3
	else:
		for index in range(12 if enraged else 7):
			var bolt := Bolt.new()
			bolt.target = target
			var angle := index * TAU / 12 if enraged else (index - 3) * 0.2
			bolt.direction = locked_direction.rotated(Vector3.UP, angle)
			bolt.position = position + Vector3.UP + bolt.direction * 1.7
			bolt.speed = 6.0 if enraged else 5.0
			get_parent().add_child(bolt)
	attack_cooldown = 2.0 if enraged else 3.0


func _tick_dash(delta: float) -> void:
	var start := global_position
	var step := minf(dash_left, dash_speed * delta)
	var finish := start + locked_direction * step
	finish.x = clampf(finish.x, -23, 23)
	finish.z = clampf(finish.z, -23, 23)
	# Sweep the whole movement segment so a fast dash cannot skip the player.
	var player_ground: Vector3 = target.global_position
	player_ground.y = start.y
	var closest := Geometry3D.get_closest_point_to_segment(player_ground, start, finish)
	if not dash_hit and closest.distance_to(player_ground) <= hit_radius + 0.42:
		target.take_damage(28)
		dash_hit = true
	global_position = finish
	dash_left = maxf(0, dash_left - step)
	model.rotation.x = 0.16
	model.rotation.z = sin(age * 45) * 0.025
	if absf(finish.x) >= 23 or absf(finish.z) >= 23:
		dash_left = 0
	if dash_left <= 0:
		recovery_left = dash_recovery
		model.rotation.x = 0
		model.rotation.z = 0
