extends Node3D
const V=preload("res://scripts/visuals.gd")
const C=preload("res://scripts/combat_visuals.gd")
var target: Node3D
var direction:=Vector3.BACK
var speed:=6.0
var lifetime:=14.0/6.0
var damage:=12
var spent:=false
func _ready() -> void:
	add_to_group("regular_projectiles")
	add_to_group("hostile_projectiles")
	rotation.y=atan2(direction.x,direction.z)
	for i in range(12):
		var x: float=-1.2+i*0.2
		var a:=Vector3(x,0.35,0.3*(1-x*x/1.44))
		var nx:=x+0.2
		var b:=Vector3(nx,0.35,0.3*(1-nx*nx/1.44))
		C.ink(V.rod(self,Color("302635"),a,b,0.12))
		C.ink(V.rod(self,C.DANGER,a+Vector3.UP*0.07,b+Vector3.UP*0.07,0.065))
	for x in [-0.8,0,0.8]: C.ink(V.rod(self,C.DANGER,Vector3(x,0.3,-0.5),Vector3(x,0.3,0.1),0.025))
func _physics_process(delta: float) -> void:
	if spent: return
	var step:=speed*minf(delta,lifetime)
	var obstacle=preload("res://scripts/castle_obstacles.gd").world(self)
	if obstacle!=null:
		var wall: Dictionary=obstacle.sweep(global_position,global_position+direction*step,1.2)
		if wall.t<1: step*=wall.t; lifetime=0
	var offset: Vector3=target.global_position-global_position
	var along:=offset.dot(direction)
	var across:=absf(offset.dot(Vector3(-direction.z,0,direction.x)))
	if along>=-0.42 and along<=step+0.42 and across<=1.2+0.42:
		spent=true
		target.take_damage(damage,preload("res://scripts/difficulty_tiers.gd").source(self))
		queue_free()
	global_position+=direction*step
	lifetime=maxf(0,lifetime-delta)
	if lifetime<=0: spent=true; queue_free()
