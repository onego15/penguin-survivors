extends Node3D

const Visuals = preload("res://scripts/visuals.gd")
const SPEED := 22.0
var direction := Vector3.FORWARD
var lifetime := 1.5
var damage := 1
var support_star := false


func _ready() -> void:
	preload("res://scripts/combat_visuals.gd").tail(self)
	rotation.y=atan2(direction.x,direction.z)
	if support_star:
		for index in range(5):
			var angle := index * TAU / 5
			Visuals.rod(self,Color("ffe782"),Vector3.ZERO,Vector3(cos(angle),sin(angle),0)*0.3,0.09,0)
		return
	# A faceted ice bolt with a tapered tail replaces the plain sphere.
	Visuals.rod(self, Color("b4faff"), Vector3(0, 0, -0.1), Vector3(0, 0, 0.32), 0.15, 0.0)
	Visuals.rod(self, Color("5cbfd6"), Vector3(0, 0, -0.65), Vector3(0, 0, -0.1), 0.015, 0.12)
	Visuals.ring(self, Color("f9f5da"), Vector3.ZERO, 0.14, 0.025, true)
	rotation.y = atan2(direction.x, direction.z)


func _physics_process(delta: float) -> void:
	var start := global_position
	var finish := start + direction * SPEED * delta
	# Sweep the whole movement segment to avoid skipping targets at low frame rates.
	var hit: Node3D = null
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead:
			continue
		var center: Vector3 = enemy.global_position + Vector3(0, 1.0, 0)
		var closest := Geometry3D.get_closest_point_to_segment(center, start, finish)
		if closest.distance_squared_to(center) <= pow(enemy.hit_radius + 0.15, 2):
			var distance := start.distance_squared_to(closest)
			if distance < nearest_distance:
				nearest_distance = distance
				hit = enemy
	if hit != null:
		hit.take_damage(damage)
		queue_free()
		return
	global_position = finish
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
