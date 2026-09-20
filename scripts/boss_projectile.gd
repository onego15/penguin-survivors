extends Node3D

const V = preload("res://scripts/visuals.gd")
var target: Node3D
var direction := Vector3.FORWARD
var speed := 5.5
var lifetime := 5.0
var damage := 16
var regular := false
var pass_gates:=false
var status_effect:=""
var tint := Color("b881f4")


func _ready() -> void:
	add_to_group("hostile_projectiles")
	if regular:
		add_to_group("regular_projectiles")
	var c=preload("res://scripts/combat_visuals.gd")
	c.ink(V.ellipsoid(self,Color("ff573c"),Vector3.ZERO,Vector3(0.22,0.22,0.34)))
	c.ink(V.ring(self,Color("3a2033"),Vector3.ZERO,0.28,0.075,true))
	c.ink(V.rod(self,Color("ff573c"),Vector3(0,0,-0.9),Vector3.ZERO,0.01,0.16))
	if pass_gates:
		for side in [-1,1]: c.ink(V.rod(self,Color("ffd2d9"),Vector3(0,0,-0.3),Vector3(side*0.42,0,-0.65),0.055,0))
	if status_effect!="":
		V.ellipsoid(self,Color("4d365d") if status_effect=="ink" else Color("d5bb7e"),Vector3.ZERO,Vector3.ONE*0.17)
	rotation.y = atan2(direction.x, direction.z)


func _physics_process(delta: float) -> void:
	var start := global_position
	var finish:=start+direction*speed*delta
	var obstacle=preload("res://scripts/castle_obstacles.gd").world(self)
	var blocked:=false
	if obstacle!=null:
		var wall: Dictionary=obstacle.sweep(start,finish,0.22,pass_gates)
		blocked=wall.t<1
		finish=wall.point
	global_position=finish
	if is_instance_valid(target):
		var closest := Geometry3D.get_closest_point_to_segment(target.global_position + Vector3.UP, start, global_position)
		if closest.distance_to(target.global_position + Vector3.UP) < 0.65:
			if target.take_damage(damage,preload("res://scripts/difficulty_tiers.gd").source(self)) and target.health>0 and status_effect!="":
				target.statuses.apply(status_effect)
			queue_free()
			return
	if blocked: queue_free(); return
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
