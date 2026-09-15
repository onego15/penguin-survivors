extends Node3D

const V = preload("res://scripts/visuals.gd")
var target: Node3D
var direction := Vector3.FORWARD
var speed := 5.5
var lifetime := 5.0
var damage := 16
var regular := false
var tint := Color("b881f4")


func _ready() -> void:
	add_to_group("hostile_projectiles")
	if regular:
		add_to_group("regular_projectiles")
	V.ellipsoid(self, tint, Vector3.ZERO, Vector3(0.22, 0.22, 0.34))
	V.ring(self, Color("f6d3ff"), Vector3.ZERO, 0.26, 0.035, true)
	rotation.y = atan2(direction.x, direction.z)


func _physics_process(delta: float) -> void:
	var start := global_position
	global_position += direction * speed * delta
	if is_instance_valid(target):
		var closest := Geometry3D.get_closest_point_to_segment(target.global_position + Vector3.UP, start, global_position)
		if closest.distance_to(target.global_position + Vector3.UP) < 0.65:
			target.take_damage(damage)
			queue_free()
			return
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
